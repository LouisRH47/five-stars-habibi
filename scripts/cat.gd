extends Critter
## A cat that strolls slowly around its own patch (a gap between two villas), sits for a
## bit, then strolls somewhere else. Bump into it and it dashes away for a moment, then
## calms down and wanders back. ObstacleBuilder makes one per line in CATS
## (data/palm_grove.gd) and calls setup(). Speeds are in game_config.gd.

const BODY_SIZE := Vector3(0.3, 0.35, 0.6)

var _area := Rect2()
var _target := Vector3.ZERO
var _pause_left := 0.0
var _run_direction := Vector3.ZERO


## area: where it wanders (x, z). colour: its fur.
func setup(area: Rect2, colour: Color) -> void:
	_area = area
	var middle := area.get_center()
	position = Vector3(middle.x, 0.0, middle.y)
	_build_model(colour)
	make_body(BODY_SIZE)
	_pick_target()


## The patch this cat lives on.
func area() -> Rect2:
	return _area


func _physics_process(delta: float) -> void:
	if scared_left > 0.0:
		scared_left -= delta
		_step(_run_direction, GameConfig.CAT_RUN_SPEED, delta)
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		return
	var to_target := _target - position
	to_target.y = 0.0
	if to_target.length() < 0.1:
		_pause_left = randf_range(GameConfig.CAT_PAUSE_MIN, GameConfig.CAT_PAUSE_MAX)
		_pick_target()
		return
	_step(to_target.normalized(), minf(GameConfig.CAT_WALK_SPEED, to_target.length() / delta), delta)


func _step(direction: Vector3, speed: float, delta: float) -> void:
	face(direction)
	position += direction * speed * delta


## A new spot to stroll to, somewhere on its own patch.
func _pick_target() -> void:
	_target = Vector3(randf_range(_area.position.x, _area.end.x), 0.0,
			randf_range(_area.position.y, _area.end.y))


func _on_scared(bike: Node3D) -> void:
	_run_direction = position - bike.global_position
	_run_direction.y = 0.0
	_run_direction = _run_direction.normalized() if _run_direction.length() > 0.01 else Vector3.FORWARD
	_pause_left = 0.0
	# Afterwards it strolls back to its own patch.
	_pick_target()


func _build_model(fur: Color) -> void:
	var dark := fur.darkened(0.35)
	LowPoly.box(self, Vector3(0.26, 0.22, 0.5), fur, Vector3(0, 0.27, 0.02))      # body
	LowPoly.box(self, Vector3(0.22, 0.2, 0.2), fur, Vector3(0, 0.4, -0.3))        # head
	LowPoly.box(self, Vector3(0.06, 0.08, 0.04), dark, Vector3(-0.07, 0.53, -0.3)) # ears
	LowPoly.box(self, Vector3(0.06, 0.08, 0.04), dark, Vector3(0.07, 0.53, -0.3))
	LowPoly.box(self, Vector3(0.05, 0.05, 0.02), Color(0.5, 0.85, 0.3, 1), Vector3(-0.05, 0.43, -0.41))  # eyes
	LowPoly.box(self, Vector3(0.05, 0.05, 0.02), Color(0.5, 0.85, 0.3, 1), Vector3(0.05, 0.43, -0.41))
	for x in [-0.08, 0.08]:
		for z in [-0.15, 0.2]:
			LowPoly.box(self, Vector3(0.06, 0.16, 0.06), fur, Vector3(x, 0.08, z))  # legs
	var tail := LowPoly.box(self, Vector3(0.05, 0.05, 0.35), dark, Vector3(0, 0.42, 0.38))
	tail.rotation.x = deg_to_rad(40.0)
