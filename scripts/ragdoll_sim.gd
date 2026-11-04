class_name RagdollSim
extends RefCounted
## Session 54: a floppy rag-doll for the rider's falls ("not a stiff stick man").
## Godot's own physical bones don't suit this character model (it's imported at 23x scale
## with a turned head rest pose), so this is a small hand-made one: the joints (head, chest,
## hips, shoulders, elbows, hands, hips, knees, feet) are points joined by sticks. Each step,
## gravity pulls the points, they bounce and slide on the ground, the sticks pull them back to
## the right lengths, and nothing goes through the thing you hit. PersonPose ("ragdoll" mode)
## then bends the skeleton's bones to point along the sticks, and the bike sets the rider's
## position and turn from the chest and hips. Cheap and steady, so it also runs on iPads.
## Positions are in world space.

## Point name -> bone name.
const JOINTS := {
	"hips": "Hips", "chest": "Spine2", "neck": "Neck", "head": "HeadTop_End",
	"l_sh": "LeftArm", "l_el": "LeftForeArm", "l_ha": "LeftHand",
	"r_sh": "RightArm", "r_el": "RightForeArm", "r_ha": "RightHand",
	"l_hip": "LeftUpLeg", "l_kn": "LeftLeg", "l_ft": "LeftFoot",
	"r_hip": "RightUpLeg", "r_kn": "RightLeg", "r_ft": "RightFoot",
}
## The bones (the sticks that keep their length exactly).
const BONES := [
	["hips", "chest"], ["chest", "neck"], ["neck", "head"],
	["chest", "l_sh"], ["chest", "r_sh"], ["l_sh", "r_sh"],
	["l_sh", "l_el"], ["l_el", "l_ha"], ["r_sh", "r_el"], ["r_el", "r_ha"],
	["hips", "l_hip"], ["hips", "r_hip"], ["l_hip", "r_hip"],
	["l_hip", "l_kn"], ["l_kn", "l_ft"], ["r_hip", "r_kn"], ["r_kn", "r_ft"],
]
## Braces that keep the chest and pelvis in one piece (they bend a little).
const BRACES := [
	["l_sh", "l_hip"], ["r_sh", "r_hip"], ["l_sh", "r_hip"], ["r_sh", "l_hip"],
	["neck", "l_sh"], ["neck", "r_sh"], ["head", "chest"], ["neck", "hips"],
]
## Limbs that can't fold flat: [top, end, shortest share of their full length].
const NO_FOLD := [["l_hip", "l_ft", 0.45], ["r_hip", "r_ft", 0.45], ["l_sh", "l_ha", 0.3], ["r_sh", "r_ha", 0.3]]
## How big each point is (it can't sink into the ground further than this).
const RADIUS := {"head": 0.11, "chest": 0.13, "hips": 0.12, "neck": 0.08}

var points := {}       # name -> Vector3 (now)
var home := {}         # name -> Vector3 (where it started: on the bike)
var _last := {}        # name -> Vector3 (one step ago); the gap is the speed
var _rest := {}        # [a, b] key -> length
var _ground := 0.0
var _wall_point := Vector3.ZERO
var _wall_normal := Vector3.ZERO
var _left := 0.0       # time left over between fixed steps
var _quiet := 0.0      # how long everything has been nearly still
var time := 0.0


## Starts from the rider's current pose. velocity: how fast they were going. kick: the extra
## push from the hit (outwards from the wall plus up). spin: a turn speed (radians/s) round
## an axis, so a hard hit throws the head over the feet.
## wall_normal: which way is "away" from the thing that was hit (flat, or zero for none).
func start(person: Person, velocity: Vector3, kick: Vector3, spin: Vector3, ground_y: float,
		wall_normal: Vector3) -> void:
	_ground = ground_y
	var skeleton := person.skeleton
	for name: String in JOINTS:
		var bone_name: String = JOINTS[name]
		if person.remembered.has(bone_name):   # the real pose (e.g. sitting on the bike)
			points[name] = person.remembered[bone_name]
		else:
			points[name] = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin
		home[name] = points[name]
	wall_normal.y = 0.0
	_wall_normal = wall_normal.normalized() if wall_normal.length() > 0.01 else Vector3.ZERO
	if _wall_normal != Vector3.ZERO:
		# The wall is just in front of the body part that's furthest towards it.
		var nearest := INF
		for name: String in points:
			nearest = minf(nearest, (points[name] as Vector3).dot(_wall_normal) - _radius(name))
		_wall_point = _wall_normal * (nearest - 0.02)
	var centre: Vector3 = points["hips"]
	var dt := 1.0 / GameConfig.RAGDOLL_STEPS_PER_SECOND
	for name: String in points:
		var p: Vector3 = points[name]
		var turning := spin.cross(p - centre)   # points further from the hips move faster
		_last[name] = p - (velocity + kick + turning) * dt
		_keep_outside(name)
	for pair in BONES + BRACES:
		_rest[pair] = (points[pair[0]] as Vector3).distance_to(points[pair[1]])


## Moves everything on by delta seconds (in small fixed steps, so a big delta is fine).
func step(delta: float) -> void:
	var dt := 1.0 / GameConfig.RAGDOLL_STEPS_PER_SECOND
	_left += delta
	var steps := 0
	while _left >= dt and steps < GameConfig.RAGDOLL_MAX_STEPS:
		_left -= dt
		steps += 1
		_one_step(dt)
	if steps == GameConfig.RAGDOLL_MAX_STEPS:
		_left = 0.0


## Getting back up: moves every joint `amount` (0..1) of the way back to where it started,
## and calms it down, so the rider can blend smoothly back onto the bike.
func pull_home(amount: float) -> void:
	for name: String in points:
		var p: Vector3 = (points[name] as Vector3).lerp(home[name], clampf(amount, 0.0, 1.0))
		points[name] = p
		_last[name] = p
	_left = 0.0


## The fastest any point is moving (metres per second).
func top_speed() -> float:
	var fastest := 0.0
	var dt := 1.0 / GameConfig.RAGDOLL_STEPS_PER_SECOND
	for name: String in points:
		fastest = maxf(fastest, (points[name] as Vector3).distance_to(_last[name]) / dt)
	return fastest


## True once the body has lain still for a moment.
func settled() -> bool:
	return _quiet >= GameConfig.RAGDOLL_SETTLE_TIME


## The body's turn from the chest and hips: x to the rider's right, y up the back, z behind.
func torso_basis() -> Basis:
	var up: Vector3 = (points["chest"] - points["hips"]).normalized()
	var right: Vector3 = (points["r_sh"] - points["l_sh"]) + (points["r_hip"] - points["l_hip"])
	right = (right - up * right.dot(up)).normalized()
	if right.length() < 0.5:
		right = Vector3.RIGHT
	return Basis(right, up, right.cross(up)).orthonormalized()


func _one_step(dt: float) -> void:
	time += dt
	var gravity := Vector3.DOWN * GameConfig.RAGDOLL_GRAVITY * dt * dt
	for name: String in points:
		var now: Vector3 = points[name]
		var moved: Vector3 = (now - _last[name]) * GameConfig.RAGDOLL_AIR_DAMPING
		if now.y <= _ground + _radius(name) + 0.01:
			moved.x *= GameConfig.RAGDOLL_GROUND_FRICTION   # sliding on the ground slows it down
			moved.z *= GameConfig.RAGDOLL_GROUND_FRICTION
		_last[name] = now
		points[name] = now + moved + gravity
	for i in GameConfig.RAGDOLL_ITERATIONS:
		for pair in BONES:
			_stick(pair, 1.0)
		for pair in BRACES:
			_stick(pair, GameConfig.RAGDOLL_BRACE_STIFFNESS)
		for rule in NO_FOLD:
			_no_fold(rule)
		for name: String in points:
			_keep_outside(name)
	_quiet = _quiet + dt if top_speed() < GameConfig.RAGDOLL_STILL_SPEED else 0.0


## Pulls two points back to their rest distance (stiffness 1 = exactly).
func _stick(pair: Array, stiffness: float) -> void:
	var a: Vector3 = points[pair[0]]
	var b: Vector3 = points[pair[1]]
	var gap := b - a
	var length := gap.length()
	if length < 0.0001:
		return
	var fix := gap * ((length - float(_rest[pair])) / length) * 0.5 * stiffness
	points[pair[0]] = a + fix
	points[pair[1]] = b - fix


## A knee or elbow may bend but not fold flat: keep the ends a little apart.
func _no_fold(rule: Array) -> void:
	var top: Vector3 = points[rule[0]]
	var end: Vector3 = points[rule[1]]
	var middle := "l_kn" if rule[0] == "l_hip" else "r_kn" if rule[0] == "r_hip" else "l_el" if rule[0] == "l_sh" else "r_el"
	var full := float(_rest.get([rule[0], middle], 0.4)) + float(_rest.get([middle, rule[1]], 0.4))
	var shortest := full * float(rule[2])
	var gap := end - top
	if gap.length() < shortest and gap.length() > 0.0001:
		points[rule[1]] = top + gap.normalized() * shortest


## Nothing below the ground or behind the thing that was hit.
func _keep_outside(name: String) -> void:
	var p: Vector3 = points[name]
	var r := _radius(name)
	if p.y < _ground + r:
		p.y = _ground + r
		var last: Vector3 = _last[name]
		if last.y < p.y:   # bounce a little, rather than stopping dead
			last.y = p.y + (p.y - last.y) * GameConfig.RAGDOLL_BOUNCE
			_last[name] = last
	if _wall_normal != Vector3.ZERO:
		var depth := (p - _wall_point).dot(_wall_normal)
		if depth < r:
			p += _wall_normal * (r - depth)
	points[name] = p


func _radius(name: String) -> float:
	return RADIUS.get(name, 0.06)
