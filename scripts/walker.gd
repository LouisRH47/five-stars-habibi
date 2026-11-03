class_name Walker
extends CharacterBody3D
## The rider on foot (Session 19). F gets you off the bike (scripts/on_foot.gd); then
## W / S walk forward and back, A / D turn, Shift jogs. Picking up and dropping off only
## work on foot. The model is an animated Person (Session 29) that walks, jogs and
## stands, dressed by scripts/rider_look.gd like the rider on the bike.
## The front is -Z, like the bike. Speeds are in game_config.gd.

## Current speed in metres per second (forwards is positive).
var speed := 0.0
## True while you're on foot and this is the one being controlled.
var active := false

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
	collision_layer = 1 if on else 0
	collision_mask = 1 if on else 0
	speed = 0.0
	velocity = Vector3.ZERO
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
	move_and_slide()
	# Walk, jog or stand, with the animation running as fast as you move.
	var person := _model as Person
	var fast := absf(speed)
	if fast < 0.1:
		person.play("idle")
	elif Input.is_action_pressed("sprint") and fast > GameConfig.WALK_SPEED_KMH / 3.6:
		person.play("jog", fast / GameConfig.PERSON_JOG_ANIM_MPS)
	else:
		person.play("walk", signf(speed) * fast / GameConfig.PERSON_WALK_ANIM_MPS)


## Builds the rider on foot: an animated Person with the Snackaroo helmet (Session 29).
## Also used for the start screen look cards and the clinic bed.
static func build_model() -> Node3D:
	return RiderLook.make_rider()
