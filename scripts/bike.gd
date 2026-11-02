extends CharacterBody3D
## The player's bicycle.
## W / Up arrow = pedal, S / Down arrow = brake (then roll backwards),
## A / D or Left / Right = steer, Space = handbrake, Shift = sprint, R = back to start.
## Tuning numbers are in scripts/game_config.gd.

## Sent when the bike hits something. strength is 0 (tiny tap) to 1 (full-speed, head-on).
signal bumped(strength: float)
## Sent when the bike rides over a speed bump. strength is 0 (crawling) to 1 (full speed
## or faster). The camera shakes on it. Session 8's damage meter can listen to it too
## ("bubble tea hates speed bumps").
signal went_over_bump(strength: float)

## Current speed in metres per second. Positive = forwards.
var speed := 0.0
## Sprint energy, 0 to STAMINA_MAX.
var stamina := GameConfig.STAMINA_MAX
## True after stamina runs out, until it refills to STAMINA_TIRED_UNTIL.
var tired := false
## True while actually sprinting this frame.
var sprinting := false
## How many speed bumps you've ridden over since the game started.
var bumps_taken := 0

var _steer := 0.0
var _bump_cooldown := 0.0
var _start_transform: Transform3D
var _hop_left := 0.0     # seconds left of the speed-bump bounce
var _hop_height := 0.0   # metres, how high this bounce goes

@onready var _model: Node3D = $Model
@onready var _front_wheel: Node3D = $Model/FrontWheel
@onready var _rear_wheel: Node3D = $Model/RearWheel


func _ready() -> void:
	# Remember where the bike started so R can put it back there.
	_start_transform = global_transform
	# Speed bumps (scripts/speed_bump.gd) look for this group.
	add_to_group("bike")


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_bike"):
		reset_to_start()
		return
	_update_stamina_and_speed(delta)
	_update_steering(delta)
	_move(delta)
	_update_lean(delta)
	_update_hop(delta)
	_spin_wheels(delta)
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)


## Puts the bike back where it started, standing still. Used by the R key
## and when the bike falls off the world.
func reset_to_start() -> void:
	global_transform = _start_transform
	velocity = Vector3.ZERO
	speed = 0.0
	_model.rotation.z = 0.0
	_hop_left = 0.0
	_model.position.y = 0.0
	_model.rotation.x = 0.0


## A speed bump calls this when the bike rides onto it (scripts/speed_bump.gd).
## The bike hops (only the model, not the physics body), and loses speed if it was fast.
func hit_speed_bump() -> void:
	var kmh := absf(speed) * 3.6
	var strength := clampf(kmh / GameConfig.BIKE_MAX_SPEED_KMH, 0.0, 1.0)
	# Nothing lost at or under the safe speed, the most lost at full speed (rewards slowing down).
	var too_fast := clampf((kmh - GameConfig.SPEED_BUMP_SAFE_KMH)
			/ (GameConfig.BIKE_MAX_SPEED_KMH - GameConfig.SPEED_BUMP_SAFE_KMH), 0.0, 1.0)
	speed *= lerpf(1.0, GameConfig.SPEED_BUMP_SPEED_KEEP, too_fast)
	_hop_height = lerpf(GameConfig.SPEED_BUMP_HOP_MIN, GameConfig.SPEED_BUMP_HOP_MAX, strength)
	_hop_left = GameConfig.SPEED_BUMP_HOP_TIME
	bumps_taken += 1
	went_over_bump.emit(strength)


func _update_stamina_and_speed(delta: float) -> void:
	var pedal := Input.get_action_strength("move_forward")
	var brake := Input.get_action_strength("move_back")

	sprinting = pedal > 0.0 and Input.is_action_pressed("sprint") and not tired and stamina > 0.0
	if sprinting:
		stamina = maxf(stamina - GameConfig.STAMINA_DRAIN_PER_SEC * delta, 0.0)
		if stamina <= 0.0:
			tired = true
	else:
		var refill := GameConfig.STAMINA_REFILL_PEDALLING if pedal > 0.0 else GameConfig.STAMINA_REFILL_COASTING
		stamina = minf(stamina + refill * delta, GameConfig.STAMINA_MAX)
		if tired and stamina >= GameConfig.STAMINA_TIRED_UNTIL:
			tired = false

	var max_kmh := GameConfig.BIKE_SPRINT_MAX_SPEED_KMH if sprinting else GameConfig.BIKE_MAX_SPEED_KMH
	var accel := GameConfig.BIKE_SPRINT_ACCELERATION if sprinting else GameConfig.BIKE_ACCELERATION
	var max_speed := max_kmh / 3.6

	if pedal > 0.0:
		if speed > max_speed:
			# Just stopped sprinting: ease back down to normal top speed.
			speed = move_toward(speed, max_speed, GameConfig.BIKE_COAST_DRAG * delta)
		else:
			# Gentle start: you gain speed fastest from a standstill and slower near the top.
			var ease_off := 1.0 - 0.6 * clampf(speed / max_speed, 0.0, 1.0)
			speed = move_toward(speed, max_speed, accel * pedal * ease_off * delta)
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
	_steer = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	if _steer == 0.0:
		return
	var speed_ratio := clampf(absf(speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
	# You can't turn while standing still, and turning is a bit gentler at top speed.
	var grip := clampf(speed_ratio * 3.0, 0.0, 1.0) * lerpf(1.0, 0.6, speed_ratio)
	var turn := deg_to_rad(GameConfig.BIKE_STEER_DEG_PER_SEC) * _steer * grip * delta
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

	# Safety net: if the bike somehow falls off the world, put it back.
	if global_position.y < GameConfig.WORLD_FALL_RESET_Y:
		reset_to_start()
		return

	# Riding into a wall or box slows you down. Head-on hits slow you the most.
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.5:
			var head_on := absf(forward.dot(normal))
			var strength := head_on * clampf(absf(speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
			speed *= lerpf(1.0, GameConfig.BIKE_BUMP_SPEED_KEEP, head_on)
			if strength >= GameConfig.BUMP_MIN_STRENGTH and _bump_cooldown <= 0.0:
				_bump_cooldown = GameConfig.BUMP_COOLDOWN
				bumped.emit(strength)
			break


func _update_lean(delta: float) -> void:
	# Lean into turns: more lean when going faster. Only the model leans, not the physics body.
	var speed_ratio := clampf(absf(speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
	var target_lean := deg_to_rad(GameConfig.BIKE_LEAN_MAX_DEG) * _steer * speed_ratio
	var follow := 1.0 - exp(-GameConfig.BIKE_LEAN_SMOOTHING * delta)
	_model.rotation.z = lerpf(_model.rotation.z, target_lean, follow)


func _update_hop(delta: float) -> void:
	# The speed-bump bounce: a big hop, then a smaller one, like a spring settling.
	# Only the model moves; the physics body stays on the ground, so is_on_floor() and
	# the camera don't notice.
	if _hop_left <= 0.0:
		return
	_hop_left = maxf(_hop_left - delta, 0.0)
	var done := 1.0 - _hop_left / GameConfig.SPEED_BUMP_HOP_TIME  # 0 at the start, 1 at the end
	var wave := sin(done * TAU) * (1.0 - done)  # up, then down, dying away
	_model.position.y = _hop_height * absf(wave)
	# Nose up while the front wheel goes over, nose down when the back wheel does.
	var size := _hop_height / GameConfig.SPEED_BUMP_HOP_MAX
	_model.rotation.x = deg_to_rad(GameConfig.SPEED_BUMP_TILT_DEG) * size * wave


func _spin_wheels(delta: float) -> void:
	# Wheels turn with the ground speed. The wheel meshes are tipped on their side,
	# so spinning around their local Y axis rolls them forwards.
	var turn := speed / GameConfig.WHEEL_RADIUS * delta
	_front_wheel.rotate_object_local(Vector3.UP, -turn)
	_rear_wheel.rotate_object_local(Vector3.UP, -turn)
