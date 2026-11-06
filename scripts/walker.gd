class_name Walker
extends CharacterBody3D
## The rider on foot (Session 19). F gets you off the bike (scripts/on_foot.gd); then
## W / S walk forward and back, A / D turn, Shift jogs, Space jumps (Session 75: on the
## bike Space is still the handbrake). Picking up and dropping off only
## work on foot. The model is an animated Person (Session 29) that walks, jogs and
## stands, dressed by scripts/rider_look.gd like the rider on the bike.
## The front is -Z, like the bike. Speeds are in game_config.gd.

## Current speed in metres per second (forwards is positive).
var speed := 0.0
## True while you're on foot and this is the one being controlled.
var active := false
## How many times you've jumped (the smoke test counts them).
var jumps := 0

var _jump_wait := 0.0  # seconds until you can jump again
var _land_left := 0.0  # seconds of the landing knee bend still to go
var _air_time := 0.0  # seconds since your feet left the ground

@onready var _model: Node3D = $Model


func _init() -> void:
	add_child(build_model())


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.7
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.position.y = 0.85
	add_child(holder)
	set_active(false)


## Turns the walker on (visible, solid, controlled) or off (hidden, out of the way).
func set_active(on: bool) -> void:
	active = on
	visible = on
	_model.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	collision_layer = 1 if on else 0
	collision_mask = 1 if on else 0
	speed = 0.0
	velocity = Vector3.ZERO
	_land_left = 0.0
	_air_time = 0.0
	var person := _model as Person
	person.pose.squat = 0.0
	person.pose.tuck = 0.0
	if on:
		RiderLook.apply(_model, GameState.rider_look)


func _physics_process(delta: float) -> void:
	if not active:
		return
	var turn := Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	rotate_y(deg_to_rad(GameConfig.WALK_TURN_DEG_PER_SEC) * turn * delta)
	var go := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var top := GameConfig.JOG_SPEED_KMH if Input.is_action_pressed("sprint") else GameConfig.WALK_SPEED_KMH
	speed = move_toward(speed, go * top / 3.6, GameConfig.WALK_ACCELERATION * delta)
	var forward := -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - GameConfig.GRAVITY * delta
	_jump_wait -= delta
	if Input.is_action_just_pressed("handbrake"):  # Space: jump (only on foot)
		jump()
	move_and_slide()
	_jump_look(delta)
	# Walk, jog or stand, with the animation running as fast as you move.
	var person := _model as Person
	var fast := absf(speed)
	if fast < 0.1:
		person.play("idle")
	elif Input.is_action_pressed("sprint") and fast > GameConfig.WALK_SPEED_KMH / 3.6:
		person.play("jog", fast / GameConfig.PERSON_JOG_ANIM_MPS)
	else:
		person.play("walk", signf(speed) * fast / GameConfig.PERSON_WALK_ANIM_MPS)


## Jumps about JUMP_HEIGHT metres if you're standing on something and the short wait is
## over. Returns true if you jumped.
func jump() -> bool:
	if not active or not is_on_floor() or _jump_wait > 0.0:
		return false
	# Speed needed to rise JUMP_HEIGHT against gravity: v = sqrt(2 * g * h).
	velocity.y = sqrt(2.0 * GameConfig.GRAVITY * GameConfig.JUMP_HEIGHT)
	_jump_wait = GameConfig.JUMP_COOLDOWN
	jumps += 1
	return true


## The jump look: knees pulled up in the air, then a quick knee bend when you land.
## (Short moments off the ground, like stepping off a kerb, don't count.)
func _jump_look(delta: float) -> void:
	var pose := (_model as Person).pose
	if is_on_floor():
		if _air_time > 0.2:
			_land_left = GameConfig.JUMP_LAND_TIME  # just landed
		_air_time = 0.0
	else:
		_air_time += delta
		_land_left = 0.0
	var tuck_to := GameConfig.JUMP_TUCK if _air_time > 0.1 else 0.0
	pose.tuck = move_toward(pose.tuck, tuck_to, delta * 1.5)
	_land_left = maxf(_land_left - delta, 0.0)
	# Down fast, then back up: a sine bump over the landing time.
	var bend := sin(PI * (1.0 - _land_left / GameConfig.JUMP_LAND_TIME)) if _land_left > 0.0 else 0.0
	pose.squat = GameConfig.JUMP_LAND_SQUAT * bend


## True for a moment after you land (the landing knee bend).
func landing() -> bool:
	return _land_left > 0.0


## Builds the rider on foot: an animated Person with the Snackaroo helmet (Session 29).
## Also used for the start screen look cards and the clinic bed.
static func build_model() -> Node3D:
	return RiderLook.make_rider()
