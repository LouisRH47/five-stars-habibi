class_name VenueMotion
extends Node
## Small kitchen motions stop with ordinary gameplay and need no physics bodies.
## Session 58: the walk-in rooms' moving parts too: the pizza fire flickers and the pizza
## maker slides a pizza in with the peel, the gelato server scoops, the espresso machine
## steams, the shawarma spits turn while the cook slices, the baker slides flatbreads into
## the oven, shoppers push trolleys round the aisles, and (Session 59) the sushi belt runs.
## Only rooms near the camera are busy: further away the people, lamps and sound stop
## (Appendix I). All the speeds are in game_config.gd.
var spit: Node3D
var plates: Array[Node3D] = []

## Session 58: what moves in a looks-pass room (InteriorParts fills these in).
var inside: Node3D
var lamps: Array[OmniLight3D] = []
var spits: Array[Node3D] = []
var knives: Array[Node3D] = []       # slicing knives and gelato scoops: bob up and down
var fires: Array[OmniLight3D] = []   # flickering fire glow
var flames: Array[Node3D] = []       # flame shapes that wobble
var peels: Array[Dictionary] = []    # {"node", "from", "to", "every"}: slides in and back
var walkers: Array[Dictionary] = []  # {"person", "points", "speed", "index"}: shoppers
var belt: Array[Dictionary] = []     # {"node", "along"}: sushi plates on the loop
var belt_path: Curve3D
var eaters: Array[Person] = []
var sound: AudioStreamPlayer3D
var active := true
var _time := 0.0
var _check_left := 0.0


func add_eater(person: Person) -> void:
	eaters.append(person)


func _process(delta: float) -> void:
	if spit != null:
		spit.rotate_y(delta * 0.7)
	for plate in plates:
		plate.position.x += delta * 0.45
		if plate.position.x > 3.7:
			plate.position.x = -0.6
	if inside == null:
		return
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.3
		_check_camera()
	if not active:
		return
	_time += delta
	for turning in spits:
		turning.rotate_y(delta * GameConfig.SPIT_TURN_SPEED)
	for i in knives.size():
		knives[i].position.y = knives[i].get_meta("rest_y", knives[i].position.y) + absf(sin(_time * 3.0 + i)) * 0.12
	for i in fires.size():
		fires[i].light_energy = fires[i].get_meta("energy", 1.0) * (0.8 + 0.2 * sin(_time * 11.0 + i) * sin(_time * 4.3 + i * 2.0))
	for i in flames.size():
		var s := 1.0 + 0.18 * sin(_time * 9.0 + i * 1.7)
		flames[i].scale = Vector3(1.0 / sqrt(s), s, 1.0 / sqrt(s))
	for peel in peels:
		_move_peel(peel)
	for walker in walkers:
		_move_walker(walker, delta)
	if belt_path != null:
		var length := belt_path.get_baked_length()
		for plate in belt:
			plate["along"] = fmod(float(plate["along"]) + delta * GameConfig.SUSHI_BELT_SPEED, length)
			(plate["node"] as Node3D).position = belt_path.sample_baked(plate["along"])


## A peel (pizza or bread) rests on the prep side, then slides into the oven and back.
func _move_peel(peel: Dictionary) -> void:
	var every: float = peel["every"]
	var t := fmod(_time + float(peel.get("offset", 0.0)), every)
	var go := 0.0
	if t > every - 3.0:
		go = sin(clampf((t - (every - 3.0)) / 3.0, 0.0, 1.0) * PI)   # in and out over 3 seconds
	var node: Node3D = peel["node"]
	node.position = (peel["from"] as Vector3).lerp(peel["to"], go)


## Shoppers walk from point to point round the aisles, pushing their trolley.
func _move_walker(walker: Dictionary, delta: float) -> void:
	var person: Person = walker["person"]
	var points: Array = walker["points"]
	var target: Vector3 = points[walker["index"]]
	var gap := target - person.position
	gap.y = 0.0
	if gap.length() < 0.1:
		walker["index"] = (int(walker["index"]) + 1) % points.size()
		return
	var step := gap.normalized() * minf(gap.length(), float(walker["speed"]) * delta)
	person.position += step
	person.rotation.y = atan2(-gap.x, -gap.z)   # our people face -Z


## Busy only when the camera is close (people, lamps, sound); far rooms just stand still.
func _check_camera() -> void:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return
	var room := inside.get_parent() as Node3D
	var near := camera.global_position.distance_to(room.global_position) < GameConfig.INTERIOR_ACTIVE_DISTANCE
	if near == active:
		return
	active = near
	inside.visible = near
	inside.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
	var shadows := near and Settings.graphics > 0
	for lamp in lamps:
		lamp.shadow_enabled = shadows and lamp.get_meta("soft_shadow", false)
	if sound != null:
		if near and not sound.playing:
			sound.play()
		elif not near:
			sound.stop()
