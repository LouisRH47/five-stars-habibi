class_name Swimmer
extends Node3D
## Session 60: someone in or round a pool, moving for real (before, swimmers lay on their side
## and slid about, which looked like they were dead). Three kinds:
##   "lap":  swims lengths of a lane doing the front crawl, slows down and turns round at the
##           wall, and sometimes rests at the wall for a few seconds (standing up in the water).
##   "kid":  a kid in the kids' pool, standing in the water, bobbing and splashing.
##   "deck": someone strolling round the pool deck, round and round a loop.
## The pool (scripts/pool.gd) makes these and DistrictDetail calls step() every frame.
## This node is the swimmer's spot on the water (or the deck) and faces where they're going.

## "lap", "kid" or "deck".
var kind := "lap"
## The person (a child of this node).
var person: Person
## For "lap": the two ends of the lane (x, z on the water; this node moves between them).
var lane_start := Vector3.ZERO
var lane_end := Vector3.ZERO
## For "deck": the corners of the loop round the pool.
var loop: Array[Vector3] = []
## Where the water's surface is (y).
var water_y := 0.1
## Metres moved so far (the test checks swimmers really move).
var travelled := 0.0
## "swim", "turn" or "rest" (lap swimmers), "bob" (kids), "walk" (deck).
var state := ""

var _going_to_end := true
var _turn_left := 0.0
var _rest_left := 0.0
var _clock := 0.0
var _next := 1
var _rng := RandomNumberGenerator.new()
var _drops: Array[MeshInstance3D] = []


## Makes a lap swimmer swimming from `from` to `to` (both on the water surface).
static func lap(who: Person, from: Vector3, to: Vector3, start_at: float, seed_number: int) -> Swimmer:
	var swimmer := Swimmer.new()
	swimmer.name = "Swimmer"
	swimmer.kind = "lap"
	swimmer.lane_start = from
	swimmer.lane_end = to
	swimmer.water_y = from.y
	swimmer._rng.seed = seed_number
	swimmer.person = who
	swimmer.add_child(who, true)
	swimmer.position = from.lerp(to, clampf(start_at, 0.05, 0.95))
	swimmer._going_to_end = seed_number % 2 == 0
	swimmer._lie_flat()
	swimmer._face(to if swimmer._going_to_end else from)
	who.pose.stroke_offset = float(seed_number) * 0.37
	swimmer.state = "swim"
	return swimmer


## Makes a kid standing in shallow water at `spot` (on the water surface).
static func kid(who: Person, spot: Vector3, seed_number: int) -> Swimmer:
	var swimmer := Swimmer.new()
	swimmer.name = "Swimmer"
	swimmer.kind = "kid"
	swimmer.water_y = spot.y
	swimmer._rng.seed = seed_number
	swimmer._clock = float(seed_number) * 1.3
	swimmer.person = who
	swimmer.add_child(who, true)
	swimmer.position = spot
	swimmer.rotation.y = swimmer._rng.randf() * TAU
	who.position = Vector3(0, -who.spot("Spine2").y + 0.05, 0)   # in the water up to the chest
	who.play("splash")
	swimmer.state = "bob"
	for i in GameConfig.SPLASH_DROPS:
		var drop := LowPoly.sphere(swimmer, 0.05, 0.1, Color(0.85, 0.95, 1.0), Vector3.ZERO)
		drop.name = "SplashDrop"
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		swimmer._drops.append(drop)
	return swimmer


## Makes someone walking round the loop of corners (on the deck).
static func deck_walker(who: Person, corners: Array[Vector3], start_corner: int) -> Swimmer:
	var swimmer := Swimmer.new()
	swimmer.name = "Swimmer"
	swimmer.kind = "deck"
	swimmer.loop = corners
	swimmer.person = who
	swimmer.add_child(who, true)
	swimmer.position = corners[start_corner % corners.size()]
	swimmer._next = (start_corner + 1) % corners.size()
	swimmer._face(corners[swimmer._next])
	who.play("walk")
	swimmer.state = "walk"
	return swimmer


## Moves them on by `delta` seconds.
func _init() -> void:
	set_meta("static_batch_dynamic", true)   # it moves: never merge it into the still scenery


func step(delta: float) -> void:
	_clock += delta
	match kind:
		"lap":
			_step_lap(delta)
		"kid":
			_step_kid()
		"deck":
			_step_deck(delta)


func _step_lap(delta: float) -> void:
	var target := lane_end if _going_to_end else lane_start
	if state == "swim":
		var gap := Vector2(target.x - position.x, target.z - position.z)
		var move := minf(GameConfig.SWIM_SPEED * delta, gap.length())
		position += Vector3(gap.x, 0, gap.y).normalized() * move
		travelled += move
		if gap.length() - move < 0.05:
			if _rng.randf() < GameConfig.SWIM_REST_CHANCE:
				state = "rest"
				_rest_left = _rng.randf_range(GameConfig.SWIM_REST_TIME.x, GameConfig.SWIM_REST_TIME.y)
				_stand_up()
			else:
				_start_turn()
	elif state == "rest":
		_rest_left -= delta
		if _rest_left <= 0.0:
			_lie_flat()
			_start_turn()
	elif state == "turn":
		# A tumble-free open turn: swing round on the spot while drifting a little.
		_turn_left -= delta
		var share := clampf(delta / GameConfig.SWIM_TURN_TIME, 0.0, 1.0)
		rotation.y += PI * share
		var away := (lane_end - lane_start).normalized() * (1.0 if _going_to_end else -1.0)
		var drift := away * GameConfig.SWIM_SPEED * 0.25 * delta
		position += drift
		travelled += drift.length()
		if _turn_left <= 0.0:
			_face(lane_end if _going_to_end else lane_start)
			state = "swim"


func _start_turn() -> void:
	_going_to_end = not _going_to_end
	_turn_left = GameConfig.SWIM_TURN_TIME
	state = "turn"


## Lies the person flat on the water, face down, head the way this node faces.
func _lie_flat() -> void:
	person.rotation = Vector3(-PI * 0.5, 0, 0)
	var hips := person.spot("Hips")
	# After turning, the person's "up" points forward: put the hips on this node's spot,
	# a little under the surface so the back and the arms show above the water.
	person.position = Vector3(0, -0.06, hips.y)
	person.play("swim")


## Stands the person up at the wall, resting, with the water up to the shoulders.
func _stand_up() -> void:
	person.rotation = Vector3.ZERO
	person.position = Vector3(0, -person.spot("Spine2").y - 0.05, 0)
	person.play("idle")


func _face(spot: Vector3) -> void:
	var way := Vector2(spot.x - position.x, spot.z - position.z)
	if way.length() > 0.001:
		rotation.y = atan2(-way.x, -way.y)   # -Z points along `way`


func _step_kid() -> void:
	person.position.y = -person.spot("Spine2").y + 0.05 + sin(_clock * 3.1) * 0.06
	var before := position
	position.x += sin(_clock * 0.7) * 0.004
	position.z += cos(_clock * 0.5) * 0.004
	travelled += before.distance_to(position)
	for i in _drops.size():
		var t := fmod(_clock * 1.6 + float(i) / _drops.size(), 1.0)
		var angle := float(i) / _drops.size() * TAU + _clock * 0.3
		var out := 0.25 + t * 0.45
		_drops[i].position = Vector3(cos(angle) * out, 0.05 + sin(t * PI) * 0.6, sin(angle) * out)
		_drops[i].visible = t < 0.9


func _step_deck(delta: float) -> void:
	var target: Vector3 = loop[_next]
	var gap := target - position
	gap.y = 0.0
	var move := minf(GameConfig.POOL_WALK_SPEED * delta, gap.length())
	if gap.length() > 0.001:
		position += gap.normalized() * move
		travelled += move
	if gap.length() - move < 0.05:
		_next = (_next + 1) % loop.size()
		_face(loop[_next])
