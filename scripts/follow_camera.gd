extends Camera3D
## Follows the bike from behind and a little above, smoothly.
## Distance and height are in scripts/game_config.gd.

## The thing to follow (the bike).
@export var target: Node3D


func _ready() -> void:
	# The camera moves every frame in _process, so it shouldn't be smoothed again by physics.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target:
		global_position = _wanted_position()
		_aim()


func _process(delta: float) -> void:
	if target == null:
		return
	var catch_up := 1.0 - exp(-GameConfig.CAMERA_FOLLOW_SMOOTHING * delta)
	global_position = global_position.lerp(_wanted_position(), catch_up)
	_aim()


func _target_transform() -> Transform3D:
	# The smoothed position of the bike between physics steps, so nothing shakes.
	return target.get_global_transform_interpolated()


func _wanted_position() -> Vector3:
	var t := _target_transform()
	var behind := t.basis.z  # +Z points out the back of the bike
	behind.y = 0.0
	behind = behind.normalized()
	return t.origin + behind * GameConfig.CAMERA_DISTANCE + Vector3.UP * GameConfig.CAMERA_HEIGHT


func _aim() -> void:
	look_at(_target_transform().origin + Vector3.UP * GameConfig.CAMERA_LOOK_HEIGHT, Vector3.UP)
