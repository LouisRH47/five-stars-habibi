extends Camera3D
## Follows the bike from behind and a little above, smoothly.
## Shakes a bit when the bike bumps into something.
## Distance, height and shake are in scripts/game_config.gd.

## The thing to follow (the bike).
@export var target: Node3D

var _shake := 0.0
var _rest_position := Vector3.ZERO


func _ready() -> void:
	# The camera moves every frame in _process, so it shouldn't be smoothed again by physics.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target == null:
		return
	if target.has_signal("bumped"):
		target.bumped.connect(_on_bumped)
	_rest_position = _wanted_position()
	global_position = _rest_position
	_aim()


func _process(delta: float) -> void:
	if target == null:
		return
	var catch_up := 1.0 - exp(-GameConfig.CAMERA_FOLLOW_SMOOTHING * delta)
	_rest_position = _rest_position.lerp(_wanted_position(), catch_up)

	var jolt := Vector3.ZERO
	if _shake > 0.001:
		var size := GameConfig.CAMERA_SHAKE_AMOUNT * _shake
		jolt = Vector3(randf_range(-size, size), randf_range(-size, size), 0.0)
		_shake = lerpf(_shake, 0.0, 1.0 - exp(-GameConfig.CAMERA_SHAKE_FADE * delta))
	global_position = _rest_position + jolt
	_aim()


func _on_bumped(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _target_transform() -> Transform3D:
	# The smoothed position of the bike between physics steps, so nothing shakes by accident.
	return target.get_global_transform_interpolated()


func _wanted_position() -> Vector3:
	var t := _target_transform()
	var behind := t.basis.z  # +Z points out the back of the bike
	behind.y = 0.0
	behind = behind.normalized()
	return t.origin + behind * GameConfig.CAMERA_DISTANCE + Vector3.UP * GameConfig.CAMERA_HEIGHT


func _aim() -> void:
	look_at(_target_transform().origin + Vector3.UP * GameConfig.CAMERA_LOOK_HEIGHT, Vector3.UP)
