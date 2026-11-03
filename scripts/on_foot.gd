class_name OnFoot
extends Node
## Getting off the bike and back on (Session 19, PRD "Delivery loop" and "Controls").
## F gets off when the bike is nearly stopped: the bike stays parked on its stand and you
## walk as the rider (scripts/walker.gd). Walk back to the bike and press F to ride again.
## Picking up and dropping off only work on foot, so parking near the door matters: the
## meters and the shift clock keep running while you walk. R on foot puts you back on the
## bike at the start. This node swaps who the camera, the mini-map and the DeliveryManager
## follow.

## Sent when you get off (true) or back on (false).
signal changed(on_foot: bool)

@export var bike: Node3D
@export var walker: Walker
@export var camera: Camera3D
@export var delivery_manager: DeliveryManager
@export var minimap: Node

## True while you're walking.
var on_foot := false


func _physics_process(_delta: float) -> void:
	# Polled (not an input event) so the smoke test and the bot can press F too.
	if Input.is_action_just_pressed("toggle_bike"):
		toggle()
	elif on_foot and Input.is_action_just_pressed("reset_bike"):
		get_on(true)
		bike.reset_to_start()


## F: off the bike if it's slow enough, back on if you're next to it.
func toggle() -> bool:
	if on_foot:
		return get_on()
	return get_off()


func can_get_off() -> bool:
	return not on_foot and absf(bike.speed) * 3.6 < GameConfig.GET_OFF_MAX_KMH \
			and bike.fallen_left <= 0.0 and not bike.wrecked


func near_bike() -> bool:
	return on_foot and _flat_gap(walker.global_position, bike.global_position) <= GameConfig.GET_ON_DISTANCE


## How far the walker is from the parked bike (0 when riding).
func distance_to_bike() -> float:
	return _flat_gap(walker.global_position, bike.global_position) if on_foot else 0.0


func get_off() -> bool:
	if not can_get_off():
		return false
	on_foot = true
	bike.set_parked(true)
	# Step off to the bike's right-hand side, facing the same way.
	var side := bike.global_basis.x
	side.y = 0.0
	walker.global_transform = Transform3D(bike.global_basis.orthonormalized(),
			bike.global_position + side.normalized() * 0.9 + Vector3.UP * 0.05)
	walker.set_active(true)
	_follow(walker)
	changed.emit(true)
	return true


## anywhere: get on even if you're not next to the bike (R puts you back on).
func get_on(anywhere := false) -> bool:
	if not on_foot or (not anywhere and not near_bike()):
		return false
	on_foot = false
	walker.set_active(false)
	bike.set_parked(false)
	_follow(bike)
	changed.emit(false)
	return true


func _follow(body: Node3D) -> void:
	if camera != null:
		camera.target = body
	if delivery_manager != null:
		delivery_manager.actor = body
		delivery_manager.on_foot = on_foot
	if minimap != null:
		minimap.bike = body
		minimap.parked_bike = bike if on_foot else null


func _flat_gap(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
