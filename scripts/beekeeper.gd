class_name Beekeeper
extends Node3D
## Session 63: a person who walks between work spots and does a small job at each one.
##   job "beekeeper": a white bee suit and a veiled hat, with a smoker. Walks the aisle
##     between the hives, stops at a hive, lifts its lid (the "hive_lid" nodes BeeYard made),
##     puffs a little smoke, puts the lid back and goes on to another hive.
##   job "farmer": a straw hat and a watering can. Walks the paths between the raised beds
##     and waters the plants (a few drops fall from the can).
## Just to look at: not solid (the beekeeper is inside the bee fence; the farmer stays on the
## bark paths). LifeBuilder makes them. Far from the camera they stand still (cheaper).

## Each stop: {"at": Vector3 where to stand, "lane": the path's z, "face": Vector3 what to look at,
## "lid": the hive lid Node3D or null}.
var stops: Array = []
var job := "beekeeper"
var speed := 1.0
var person: Person
## Where the path can be left to reach another lane (the ends of the beds), x values.
var lane_ends: Array = []
## How far it has walked in total (the tests check it moves).
var walked := 0.0
## How many jobs it has done (lids lifted or plants watered).
var jobs_done := 0

var _route: Array[Vector3] = []
var _stop := 0
var _work_left := 0.0
var _lid: Node3D
var _lid_rest := Vector3.ZERO
var _puffs: CPUParticles3D
var _tool: Node3D
var _rng := RandomNumberGenerator.new()
var _near := true
var _check_left := 0.0


## Makes the person and starts at the first stop.
func setup(what: String, spots: Array, ends: Array = []) -> void:
	job = what
	stops = spots
	lane_ends = ends
	_rng.seed = hash(name)
	speed = GameConfig.BEEKEEPER_SPEED if job == "beekeeper" else GameConfig.FIELD_FARMER_SPEED
	person = _beekeeper() if job == "beekeeper" else _farmer()
	add_child(person)
	position = stops[0]["at"]
	_stop = 0
	_start_work()


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		var camera := get_viewport().get_camera_3d()
		_near = camera == null or camera.global_position.distance_to(global_position) < 140.0
		person.visible = _near
	if not _near:
		return
	step(delta)


## Moves on by `delta` seconds (the tests call this directly).
func step(delta: float) -> void:
	if _work_left > 0.0:
		_work_left -= delta
		_animate_work()
		if _work_left <= 0.0:
			_finish_work()
		return
	if _route.is_empty():
		_start_work()
		return
	var target := _route[0]
	var way := target - position
	way.y = 0.0
	var move := speed * delta
	if way.length() <= move:
		position = target
		walked += way.length()
		_route.pop_front()
		if _route.is_empty():
			_start_work()
		return
	position += way.normalized() * move
	walked += move
	rotation.y = atan2(-way.x, -way.z)   # the person faces -Z
	if person.action != "walk":
		person.play("walk", speed / 1.3)


## Arrived at a stop: face the job and start it.
func _start_work() -> void:
	var stop: Dictionary = stops[_stop]
	var face: Vector3 = stop["face"] - position
	rotation.y = atan2(-face.x, -face.z)
	person.play("idle")
	_work_left = GameConfig.BEEKEEPER_LID_TIME if job == "beekeeper" else GameConfig.FIELD_FARMER_WATER_TIME
	_lid = stop.get("lid")
	if _lid != null:
		_lid_rest = _lid.position
	if _puffs != null:
		_puffs.emitting = true


func _animate_work() -> void:
	var total := GameConfig.BEEKEEPER_LID_TIME if job == "beekeeper" else GameConfig.FIELD_FARMER_WATER_TIME
	var up := sin(clampf(1.0 - _work_left / total, 0.0, 1.0) * PI)   # 0 -> 1 -> 0
	if _lid != null:
		_lid.position = _lid_rest + Vector3(0, 0.35 * up, 0)
		_lid.rotation.x = -0.6 * up
	if _tool != null and job == "farmer":
		_tool.rotation.x = -0.7 * up   # tip the can


## Job done: put the lid back and walk to another stop.
func _finish_work() -> void:
	jobs_done += 1
	if _lid != null:
		_lid.position = _lid_rest
		_lid.rotation.x = 0.0
	if _puffs != null:
		_puffs.emitting = false
	var next := _stop
	while next == _stop and stops.size() > 1:
		next = _rng.randi() % stops.size()
	_route = _path(stops[_stop], stops[next])
	_stop = next


## The way from one stop to another: along the lane, or round the end of the beds.
func _path(from: Dictionary, to: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a: Vector3 = from["at"]
	var b: Vector3 = to["at"]
	if not is_equal_approx(float(from["lane"]), float(to["lane"])) and not lane_ends.is_empty():
		# Go to whichever end of the beds is nearer, cross over, and come back.
		var end: float = lane_ends[0]
		if absf(lane_ends[1] - a.x) + absf(lane_ends[1] - b.x) < absf(end - a.x) + absf(end - b.x):
			end = lane_ends[1]
		out.append(Vector3(end, 0, a.z))
		out.append(Vector3(end, 0, b.z))
	out.append(b)
	return out


## A beekeeper: white suit and gloves, a round hat with a dark mesh veil, a smoker.
func _beekeeper() -> Person:
	var who := Person.new()
	who.name = "Beekeeper"
	who.paint({"skin": PeopleLooks.SKINS[2], "shirt": Color(0.96, 0.96, 0.93), "pants": Color(0.94, 0.94, 0.9)})
	PeopleLooks.boots(who, Color(0.95, 0.95, 0.92))
	var hat := who.follow("Head")
	var head := who.head_spot()
	var r := PeopleLooks.head_size(who) * 0.62
	LowPoly.cylinder(hat, r * 2.1, r * 2.1, 0.02, Color(0.93, 0.9, 0.82), head + Vector3(0, r * 0.95, 0))
	LowPoly.sphere(hat, r * 1.05, r * 1.1, Color(0.93, 0.9, 0.82), head + Vector3(0, r * 1.05, 0))
	var veil := LowPoly.cylinder(hat, r * 1.35, r * 1.9, r * 2.0, Color(0.15, 0.15, 0.15), head + Vector3(0, -r * 0.05, 0))
	(veil.mesh as CylinderMesh).cap_top = false
	(veil.mesh as CylinderMesh).cap_bottom = false
	var mesh := StandardMaterial3D.new()   # see-through dark netting
	mesh.albedo_color = Color(0.1, 0.1, 0.1, 0.55)
	mesh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil.material_override = mesh
	for side in ["Left", "Right"]:
		var glove := who.follow(side + "Hand")
		LowPoly.sphere(glove, 0.06, 0.12, Color(0.92, 0.88, 0.7), who.spot(side + "Hand"))
	# The smoker in the right hand: a metal can with a spout and bellows.
	_tool = who.follow("RightHand")
	var hand := who.spot("RightHand")
	LowPoly.cylinder(_tool, 0.06, 0.06, 0.2, Color(0.7, 0.7, 0.72), hand + Vector3(0, -0.12, -0.05))
	LowPoly.cylinder(_tool, 0.02, 0.05, 0.06, Color(0.6, 0.6, 0.62), hand + Vector3(0, -0.0, -0.05))
	LowPoly.box(_tool, Vector3(0.1, 0.12, 0.04), Color(0.55, 0.35, 0.2), hand + Vector3(0, -0.12, 0.04))
	_puffs = _smoke(Color(0.9, 0.9, 0.9, 0.6))
	_puffs.position = hand + Vector3(0, 0.05, -0.05)
	_tool.add_child(_puffs)
	return who


## A farmer: work shirt, straw hat and a watering can.
func _farmer() -> Person:
	var who := Person.new()
	who.name = "FieldFarmer"
	who.paint({"skin": PeopleLooks.SKINS[4 % PeopleLooks.SKINS.size()], "shirt": Color(0.35, 0.5, 0.7), "pants": Color(0.4, 0.33, 0.25)})
	PeopleLooks.boots(who, Color(0.25, 0.3, 0.2))
	var hat := who.follow("Head")
	var head := who.head_spot()
	var r := PeopleLooks.head_size(who) * 0.62
	LowPoly.cylinder(hat, r * 2.3, r * 2.3, 0.02, Color(0.92, 0.82, 0.5), head + Vector3(0, r * 0.9, 0))
	LowPoly.cylinder(hat, r * 0.9, r * 1.0, r * 0.7, Color(0.92, 0.82, 0.5), head + Vector3(0, r * 1.25, 0))
	_tool = who.follow("RightHand")
	var can := FarmBeds.watering_can_mesh()
	can.position = who.spot("RightHand") + Vector3(0, -0.42, -0.05)
	_tool.add_child(can)
	_puffs = _smoke(Color(0.6, 0.8, 1.0, 0.8))
	_puffs.gravity = Vector3(0, -6, 0)
	_puffs.position = who.spot("RightHand") + Vector3(0, -0.05, -0.5)
	_tool.add_child(_puffs)
	return who


## Little puffs (smoke, or water drops for the farmer).
func _smoke(colour: Color) -> CPUParticles3D:
	var puffs := CPUParticles3D.new()
	puffs.name = "Puffs"
	puffs.emitting = false
	puffs.amount = 12
	puffs.lifetime = 1.2
	puffs.direction = Vector3(0, 0.3, -1)
	puffs.spread = 20.0
	puffs.gravity = Vector3(0, 0.6, 0)
	puffs.initial_velocity_min = 0.3
	puffs.initial_velocity_max = 0.7
	var ball := SphereMesh.new()
	ball.radius = 0.05
	ball.height = 0.1
	ball.radial_segments = 6
	ball.rings = 3
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ball.material = paint
	puffs.mesh = ball
	return puffs
