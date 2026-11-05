class_name StableLife
extends Node3D
## Session 73: more life at the stables. In the jumping arena (JUMPING_ARENA): the sand
## (horse_sand.png), six jumps of different kinds round the course, and five riders on the
## new horses taking turns. Each rider waits at its own spot by the gate (south side), rides
## one round over the jumps, comes back and waits again. At most ARENA_RIDERS_OUT are on the
## course at once, the next one setting off once the one before is well ahead.
## By the stable block, grooms walk horses up and down the yard on a lead rope.
## DistrictTraffic makes this from _build_arena().

const RIDER_COATS := [Color(0.65, 0.38, 0.2), Color(0.85, 0.82, 0.78), Color(0.2, 0.15, 0.12),
		Color(0.85, 0.68, 0.42), Color(0.45, 0.28, 0.15)]
const POLE_COLOURS := [Color(0.76, 0.23, 0.22), Color(0.2, 0.42, 0.75), Color(0.25, 0.6, 0.35),
		Color(0.95, 0.7, 0.15), Color(0.76, 0.23, 0.22), Color(0.2, 0.42, 0.75)]
const WHITE := Color(0.96, 0.96, 0.91)
const ROPE := Color(0.75, 0.15, 0.15)
const RIDERS := 5
## The two yard walks for the grooms (x from, x to, z), south of the stable block.
const GROOM_WALKS := [Vector3(-270, -250, 189.5), Vector3(-214, -184, 190.5)]

var riders: Array[ArenaHorse] = []
var grooms: Array[RouteMover] = []
var jumps: Array[Vector3] = []
## The order the waiting riders go in.
var queue: Array[ArenaHorse] = []

var _last_sent: ArenaHorse
var _check_left := 0.0
var _clock := 0.0


func build(area: Rect2, _map: Dictionary) -> void:
	SurfaceTextures.slab(self, "horse_sand", area.size, Vector3(area.get_center().x, 0.055, area.get_center().y), 0.03)
	var course := area.grow(-12.0)
	var x0 := course.position.x
	var x1 := course.end.x
	var z0 := course.position.y
	var z1 := course.end.y
	# Six jumps: one on each side, two on each long side. along_x: the horses go along x there.
	var spots := [[Vector3(x0, 0, lerpf(z0, z1, 0.6)), false], [Vector3(lerpf(x0, x1, 0.28), 0, z0), true],
			[Vector3(lerpf(x0, x1, 0.72), 0, z0), true], [Vector3(x1, 0, lerpf(z0, z1, 0.5)), false],
			[Vector3(lerpf(x0, x1, 0.72), 0, z1), true], [Vector3(lerpf(x0, x1, 0.28), 0, z1), true]]
	for i in spots.size():
		_build_jump(spots[i][0], spots[i][1], i)
		jumps.append(spots[i][0])
	# The riders: each waits at its spot by the gate, then goes round:
	# out to the course, west to the corner, north, east over the top, south, and back west
	# along the bottom over the last two jumps to its own spot.
	for i in RIDERS:
		var wait := Vector3(x0 + 1.0 + i * 5.0, 0, z1 + 6.0)
		var entry := Vector3(wait.x, 0, z1)
		var points: Array[Vector3] = [wait, entry, Vector3(x0, 0, z1), Vector3(x0, 0, z0), Vector3(x1, 0, z0),
				Vector3(x1, 0, z1), entry]
		var look := LifeLooks.horse(RIDER_COATS[i % RIDER_COATS.size()])
		var rider := ArenaHorse.new()
		rider.name = "HorseArena_%d" % i
		add_child(rider)
		rider.setup("horse", points, true, GameConfig.HORSE_TROT_SPEED, Vector3(0.9, 2.4, 3.0), look[0], look[1])
		rider.jumps = jumps
		rider.takes_turns = true
		rider.set_meta("gait_left", 999999.0)  # they keep trotting round the course
		riders.append(rider)
		if i == 0:
			rider.start_at(3, 0.3, true)  # the first one is already going round
			_last_sent = rider
		else:
			rider.start_at(0, 0.0, true)
			rider.holding = true
			rider.rotation.y = 0.0
			queue.append(rider)
	_build_grooms()


func _physics_process(delta: float) -> void:
	_clock += delta
	# Riders back at their spot join the end of the queue.
	for rider in riders:
		if rider.holding and not queue.has(rider):
			queue.append(rider)
	if not queue.is_empty() and _out() < GameConfig.ARENA_RIDERS_OUT and _well_ahead(_last_sent):
		_last_sent = queue.pop_front()
		_last_sent.go()
	for groom in grooms:
		if groom.model.visible:
			_walk_groom(groom)


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 0.5
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
	for mover: RouteMover in riders + grooms:
		mover.set_near(mover.global_position.distance_to(camera.global_position) < far)


## How many riders are on the course now.
func _out() -> int:
	var count := 0
	for rider in riders:
		count += 0 if rider.holding else 1
	return count


## True once the rider sent last is on the top straight or further round (or done).
func _well_ahead(rider: ArenaHorse) -> bool:
	return rider == null or rider.holding or rider._next >= 4 or rider._next == 0


## One jump across the course at `spot`. The poles cross the way the horses go.
func _build_jump(spot: Vector3, along_x: bool, style: int) -> void:
	var kit := MeshKit.new()
	var turn := Basis() if along_x else Basis(Vector3.UP, PI * 0.5)
	var pole: Color = POLE_COLOURS[style % POLE_COLOURS.size()]
	var depths := [0.0] if style % 3 != 1 else [-0.45, 0.45]  # every third one is a wide double (an oxer)
	for depth: float in depths:
		for side in [-1.0, 1.0]:  # the wings at each end
			kit.box(Vector3(0.7, 1.5, 0.15), WHITE, spot + turn * Vector3(depth, 0.75, side * 2.3), turn)
			kit.box(Vector3(1.3, 0.12, 0.7), WHITE, spot + turn * Vector3(depth, 0.06, side * 2.3), turn)
			kit.box(Vector3(0.18, 0.18, 0.2), pole, spot + turn * Vector3(depth, 1.5, side * 2.3), turn)
		var heights := [0.5, 0.95] if style % 3 != 2 else [0.9]
		for height: float in heights:
			for part in 4:  # striped poles: colour and white in turn
				kit.box(Vector3(0.13, 0.13, 1.15), pole if part % 2 == 0 else WHITE,
						spot + turn * Vector3(depth, height, -1.725 + part * 1.15), turn)
	if style % 3 == 2:  # a low painted wall under a single pole
		kit.box(Vector3(0.4, 0.6, 4.4), Color(0.85, 0.82, 0.75), spot + turn * Vector3(0, 0.3, 0), turn)
		kit.box(Vector3(0.42, 0.12, 4.42), pole, spot + turn * Vector3(0, 0.62, 0), turn)
	for side in [-1.0, 1.0]:  # flower boxes in front of the wings
		kit.box(Vector3(0.4, 0.3, 1.0), Color(0.45, 0.32, 0.2), spot + turn * Vector3(-0.9, 0.15, side * 1.6), turn)
		kit.ball(0.28, Color(0.9, 0.35, 0.5), spot + turn * Vector3(-0.9, 0.38, side * 1.6), 0.6)
	add_child(kit.finish("HorseJump"))


## Grooms leading a horse on a rope, walking up and down the stable yard.
func _build_grooms() -> void:
	for i in GROOM_WALKS.size():
		var walk: Vector3 = GROOM_WALKS[i]
		var holder := Node3D.new()
		var groom := PlaceLooks.groom()
		groom.position = Vector3(-0.6, 0, -1.5)
		holder.add_child(groom)
		var horse := HorseModels.horse(RIDER_COATS[(i + 2) % RIDER_COATS.size()], false)
		horse.position = Vector3(0, 0, 0.4)
		horse.name = "Horse"
		holder.add_child(horse)
		_rope(holder, Vector3(-0.38, 1.0, -1.45), Vector3(-0.08, 1.95, -1.32))
		var mover := RouteMover.new()
		mover.name = "HorseLead_%d" % i
		add_child(mover)
		var route: Array[Vector3] = [Vector3(walk.x, 0, walk.z), Vector3(walk.y, 0, walk.z)]
		mover.setup("groom", route, false, GameConfig.GROOM_WALK_SPEED, Vector3(1.2, 2.4, 3.6), holder, groom)
		grooms.append(mover)


## The groom walks (or stands) and the horse's legs step in diagonal pairs.
func _walk_groom(mover: RouteMover) -> void:
	if mover.moving:
		mover.person.play("walk", mover.speed / GameConfig.PERSON_WALK_ANIM_MPS)
	else:
		mover.person.play("idle")
	var horse := mover.model.get_node_or_null("Horse") as Node3D
	var legs: Array = horse.get_meta("legs", []) if horse != null else []
	var swing := sin(_clock * 3.2) * 0.3 if mover.moving else 0.0
	for i in legs.size():
		(legs[i] as Node3D).rotation.x = swing * (1.0 if i == 0 or i == 3 else -1.0)


func _rope(parent: Node3D, from: Vector3, to: Vector3) -> void:
	var rope := LowPoly.cylinder(parent, 0.015, 0.015, from.distance_to(to), ROPE, (from + to) * 0.5)
	rope.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized()))
