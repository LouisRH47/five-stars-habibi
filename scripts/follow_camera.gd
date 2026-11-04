extends Camera3D
## Follows the bike from behind and a little above, smoothly.
## Shakes a bit when the bike bumps into something or rides over a speed bump.
## While you sprint the view widens a little and speed lines show at the edges (Session 31).
## Distance, height, shake and the sprint numbers are in scripts/game_config.gd.

## The thing to follow (the bike).
@export var target: Node3D

var _shake := 0.0
var _rest_position := Vector3.ZERO
var _ideal_position := Vector3.ZERO
var _camera_shape := SphereShape3D.new()
var _camera_query := PhysicsShapeQueryParameters3D.new()
## True when a wall has shortened the camera arm (also useful to the visual checks).
var obstructed := false
## The normal field of view (set in the scene); sprinting widens it a little.
var base_fov := 70.0
## The speed lines at the screen edges (scripts/speed_lines.gd).
var speed_lines: CanvasLayer


func _ready() -> void:
	# The camera moves every frame in _process, so it shouldn't be smoothed again by physics.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	base_fov = fov
	near = GameConfig.CAMERA_NEAR
	far = GameConfig.CAMERA_FAR
	_camera_shape.radius = GameConfig.CAMERA_COLLISION_RADIUS
	_camera_query.shape = _camera_shape
	_camera_query.margin = GameConfig.CAMERA_COLLISION_MARGIN
	_camera_query.collide_with_areas = false
	speed_lines = preload("res://scripts/speed_lines.gd").new()
	add_child(speed_lines)
	if target == null:
		return
	if target.has_signal("bumped"):
		target.bumped.connect(_on_bumped)
	if target.has_signal("went_over_bump"):
		target.went_over_bump.connect(_on_speed_bump)
	_ideal_position = _wanted_position()
	_rest_position = collision_safe_position(_look_position(), _ideal_position)
	global_position = _rest_position
	_aim()


func _process(delta: float) -> void:
	if target == null:
		return
	var catch_up := 1.0 - exp(-GameConfig.CAMERA_FOLLOW_SMOOTHING * delta)
	var wanted := _wanted_position()
	var previous_height := _ideal_position.y
	_ideal_position = _ideal_position.lerp(wanted, catch_up)
	# Comfy tyres isolate the view from vertical terrain heave, without changing the
	# collision body or letting the camera bypass the final wall sweep.
	if _comfy_tyres():
		var vertical := 1.0 - exp(-GameConfig.CAMERA_FOLLOW_SMOOTHING * GameConfig.COMFY_TYRES_CAMERA_VERTICAL_SHARE * delta)
		_ideal_position.y = lerpf(previous_height, wanted.y, vertical)
	var look := _look_position()
	var safe := collision_safe_position(look, _ideal_position)
	obstructed = safe.distance_squared_to(_ideal_position) > 0.0001
	# Ease away from a wall once it clears. Check the smoothed position again: a turn
	# can otherwise interpolate the camera through a building corner.
	_rest_position = collision_safe_position(look, _rest_position.lerp(safe, catch_up))

	var jolt := Vector3.ZERO
	if _shake > 0.001:
		var size := GameConfig.CAMERA_SHAKE_AMOUNT * _shake
		jolt = Vector3(randf_range(-size, size), randf_range(-size, size), 0.0)
		_shake = lerpf(_shake, 0.0, 1.0 - exp(-GameConfig.CAMERA_SHAKE_FADE * delta))
	# A collision shake must never push the camera back through the wall it just found.
	global_position = collision_safe_position(look, _rest_position + jolt)
	_aim()
	_sprint_feel(delta)


## Sprinting: widen the view a little and show the speed lines; ease back afterwards.
func _sprint_feel(delta: float) -> void:
	var sprint := 1.0 if target.get("sprinting") == true else 0.0
	var follow := 1.0 - exp(-GameConfig.SPRINT_FOV_SPEED * delta)
	fov = lerpf(fov, base_fov + GameConfig.SPRINT_FOV_EXTRA * sprint, follow)
	speed_lines.strength = lerpf(speed_lines.strength, sprint, follow)


func _on_bumped(strength: float) -> void:
	_shake = maxf(_shake, strength)


## strength: 0 (crawling over the bump) to 1 (full speed).
func _on_speed_bump(strength: float) -> void:
	var motion := lerpf(GameConfig.SPEED_BUMP_SHAKE_MIN, GameConfig.SPEED_BUMP_SHAKE_MAX, strength)
	if _comfy_tyres():
		motion *= GameConfig.COMFY_TYRES_SHAKE_SHARE
	_shake = maxf(_shake, motion)


func _comfy_tyres() -> bool:
	if target == null or not target.has_method("configure_upgrades"):
		return false
	var levels: Dictionary = target.get("upgrade_levels")
	return int(levels.get("tyres", 0)) > 0


func _target_transform() -> Transform3D:
	# The smoothed position of the bike between physics steps, so nothing shakes by accident.
	return target.get_global_transform_interpolated()


func _wanted_position() -> Vector3:
	var t := _target_transform()
	var behind := t.basis.z  # +Z points out the back of the bike
	behind.y = 0.0
	behind = behind.normalized()
	return t.origin + behind * GameConfig.CAMERA_DISTANCE + Vector3.UP * GameConfig.CAMERA_HEIGHT


## Sweep a sphere rather than only a ray, so the near plane also clears corners.
## The bike/walker are excluded; buildings and parked/moving world obstacles remain solid.
func collision_safe_position(from: Vector3, wanted: Vector3) -> Vector3:
	if not is_inside_tree() or from.distance_squared_to(wanted) < 0.000001:
		return wanted
	var exclude: Array[RID] = []
	if target is CollisionObject3D:
		exclude.append((target as CollisionObject3D).get_rid())
	for bike in get_tree().get_nodes_in_group("bike"):
		if bike is CollisionObject3D and not (bike as CollisionObject3D).get_rid() in exclude:
			exclude.append((bike as CollisionObject3D).get_rid())
	_camera_query.exclude = exclude
	_camera_query.transform = Transform3D(Basis(), from)
	_camera_query.motion = wanted - from
	var fractions := get_world_3d().direct_space_state.cast_motion(_camera_query)
	var fraction := fractions[0] if fractions.size() >= 2 else 1.0
	# A swept shape may ignore an obstacle it already overlaps. The player can stand
	# closer to a wall than the camera sphere's margin, so retain a centre-line check.
	var ray := PhysicsRayQueryParameters3D.create(from, wanted)
	ray.exclude = exclude
	ray.hit_from_inside = true
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var length := _camera_query.motion.length()
		var clear := maxf(0.0, from.distance_to(hit["position"]) - _camera_shape.radius - _camera_query.margin)
		fraction = minf(fraction, clear / length)
	return from + _camera_query.motion * fraction


func _look_position() -> Vector3:
	return _target_transform().origin + Vector3.UP * GameConfig.CAMERA_LOOK_HEIGHT


func _aim() -> void:
	var look := _look_position()
	if global_position.distance_squared_to(look) > 0.000001:
		look_at(look, Vector3.UP)
