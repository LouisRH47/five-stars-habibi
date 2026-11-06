class_name VenueMotion
extends Node
## The little movements inside a walk-in place (no physics bodies needed):
## spinning shawarma grills, sushi plates going round the belt, flickering flames, cooks
## turning while they cook, diners eating, and the sliding glass doors that open when the
## rider (or a queue customer) walks up. It only works when someone is close.

const DOOR_OPEN_DISTANCE := 3.2   # metres from the doorway
const DOOR_SPEED := 2.6           # metres per second the panels slide
const ACTIVE_DISTANCE := 40.0     # further away nothing moves (cheaper)

var spit: Node3D
var spits: Array[Node3D] = []
var plates: Array[Node3D] = []
## The sushi belt: a closed loop (x, z) round which plates travel, and its length.
var belt_path: PackedVector2Array = PackedVector2Array()
var belt_speed := 0.35
var flames: Array[Node3D] = []
var cooks: Array[Node3D] = []
var diners: Array[Node3D] = []
var doors: Node3D
## Extra things that turn (lanterns swinging, fans): [node, axis, speed].
var spinners: Array = []
## People walking up and down (a shopper with a trolley): [node, from, to, metres per second].
var pacers: Array = []
## True while the doors are open (tests read this).
var doors_open := false
## How far each plate is along the belt (metres).
var _belt_progress: Array[float] = []
var _time := 0.0
var _door_amount := 0.0


func _process(delta: float) -> void:
	var room := get_parent() as Node3D
	if room == null or not room.is_inside_tree():
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_to(room.global_position) > ACTIVE_DISTANCE:
		return
	_time += delta
	if spit != null:
		spit.rotate_y(delta * 0.7)
	for each in spits:
		each.rotate_y(delta * 0.7)
	_move_plates(delta)
	for i in flames.size():
		var flicker := 1.0 + sin(_time * 13.0 + i * 1.7) * 0.18 + sin(_time * 29.0 + i) * 0.08
		flames[i].scale = Vector3(1.0, flicker, 1.0)
	for i in cooks.size():
		var cook := cooks[i]
		if not cook.has_meta("base_turn"):
			cook.set_meta("base_turn", cook.rotation.y)
		cook.rotation.y = cook.get_meta("base_turn") + sin(_time * 0.9 + i * 2.0) * 0.45
	for i in diners.size():
		# Lean in for a bite now and then.
		diners[i].rotation.x = maxf(0.0, sin(_time * 1.3 + i * 1.9)) * 0.08
	for spinner: Array in spinners:
		(spinner[0] as Node3D).rotation[spinner[1]] = sin(_time * spinner[2]) * 0.12
	for pacer: Array in pacers:
		_pace(pacer, delta)
	_slide_doors(delta, room)


func _pace(pacer: Array, delta: float) -> void:
	var node := pacer[0] as Node3D
	var going := node.get_meta("pace_dir", 1.0) as float
	var goal: Vector3 = pacer[2] if going > 0.0 else pacer[1]
	var way := goal - node.position
	if way.length() < 0.02:
		node.set_meta("pace_dir", -going)
		return
	node.position = node.position.move_toward(goal, pacer[3] * delta)
	node.rotation.y = atan2(-way.x, -way.z)  # people face -Z


## Puts plates evenly round the belt loop.
func set_belt(path: PackedVector2Array, plate_nodes: Array[Node3D]) -> void:
	belt_path = path
	plates = plate_nodes
	_belt_progress.clear()
	var length := belt_length()
	for i in plates.size():
		_belt_progress.append(length * i / maxf(1.0, plates.size()))
	_move_plates(0.0)


func belt_length() -> float:
	var total := 0.0
	for i in belt_path.size():
		total += belt_path[i].distance_to(belt_path[(i + 1) % belt_path.size()])
	return total


func _move_plates(delta: float) -> void:
	if plates.is_empty():
		return
	if belt_path.size() < 2:
		for plate in plates:  # the old straight belt
			plate.position.x += delta * 0.45
			if plate.position.x > 3.7:
				plate.position.x = -0.6
		return
	var length := belt_length()
	for i in plates.size():
		_belt_progress[i] = fmod(_belt_progress[i] + delta * belt_speed, length)
		var spot := _belt_point(_belt_progress[i])
		plates[i].position.x = spot.x
		plates[i].position.z = spot.y


func _belt_point(distance: float) -> Vector2:
	var left := distance
	for i in belt_path.size():
		var a := belt_path[i]
		var b := belt_path[(i + 1) % belt_path.size()]
		var piece := a.distance_to(b)
		if left <= piece:
			return a.lerp(b, left / maxf(piece, 0.001))
		left -= piece
	return belt_path[0]


func _slide_doors(delta: float, room: Node3D) -> void:
	if doors == null:
		return
	var near := false
	var doorway := doors.global_position
	for who in get_tree().get_nodes_in_group("opens_doors"):
		if who is Node3D and (who as Node3D).is_visible_in_tree():
			var gap := (who as Node3D).global_position - doorway
			gap.y = 0.0
			if gap.length() < DOOR_OPEN_DISTANCE:
				near = true
				break
	if not near:
		for i in range(1, 3):
			var person := room.get_node_or_null("QueuePerson%d" % i) as Node3D
			if person != null and person.visible and person.global_position.distance_to(doorway) < DOOR_OPEN_DISTANCE:
				near = true
	doors_open = near
	_door_amount = move_toward(_door_amount, 1.0 if near else 0.0, delta * DOOR_SPEED / 1.3)
	for panel: Node3D in doors.get_children():
		panel.position.x = lerpf(panel.get_meta("closed_x"), panel.get_meta("open_x"), _door_amount)
