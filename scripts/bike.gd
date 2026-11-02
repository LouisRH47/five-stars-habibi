extends CharacterBody3D
## The player's bicycle.
## W / Up arrow = pedal, S / Down arrow = brake (then roll backwards),
## A / D or Left / Right = steer, Space = handbrake.
## Tuning numbers are in scripts/game_config.gd.

## Current speed in metres per second. Positive = forwards.
var speed := 0.0


func _physics_process(delta: float) -> void:
	_update_speed(delta)
	_update_steering(delta)
	_move(delta)


func _update_speed(delta: float) -> void:
	var max_speed := GameConfig.BIKE_MAX_SPEED_KMH / 3.6
	var pedal := Input.get_action_strength("move_forward")
	var brake := Input.get_action_strength("move_back")

	if pedal > 0.0:
		speed = move_toward(speed, max_speed, GameConfig.BIKE_ACCELERATION * pedal * delta)
	elif brake > 0.0:
		if speed > 0.1:
			speed = move_toward(speed, 0.0, GameConfig.BIKE_BRAKE * brake * delta)
		else:
			var reverse_speed := -GameConfig.BIKE_REVERSE_SPEED_KMH / 3.6
			speed = move_toward(speed, reverse_speed, GameConfig.BIKE_ACCELERATION * delta)
	else:
		speed = move_toward(speed, 0.0, GameConfig.BIKE_COAST_DRAG * delta)

	if Input.is_action_pressed("handbrake"):
		speed = move_toward(speed, 0.0, GameConfig.BIKE_HANDBRAKE * delta)


func _update_steering(delta: float) -> void:
	var steer := Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	if steer == 0.0:
		return
	var max_speed := GameConfig.BIKE_MAX_SPEED_KMH / 3.6
	var speed_ratio := clampf(absf(speed) / max_speed, 0.0, 1.0)
	# You can't turn while standing still, and turning is a bit gentler at top speed.
	var grip := clampf(speed_ratio * 3.0, 0.0, 1.0) * lerpf(1.0, 0.6, speed_ratio)
	var turn := deg_to_rad(GameConfig.BIKE_STEER_DEG_PER_SEC) * steer * grip * delta
	if speed < 0.0:
		turn = -turn  # steering flips when rolling backwards, like a real bike
	rotate_y(turn)


func _move(delta: float) -> void:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GameConfig.GRAVITY * delta
	move_and_slide()

	# Riding into a wall or box slows you down. Head-on hits slow you the most.
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.5:
			var head_on := absf(forward.dot(normal))
			speed *= lerpf(1.0, GameConfig.BIKE_BUMP_SPEED_KEEP, head_on)
			break
