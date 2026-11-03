class_name Walker
extends CharacterBody3D
## The rider on foot (Session 19). F gets you off the bike (scripts/on_foot.gd); then
## W / S walk forward and back, A / D turn, Shift jogs. Picking up and dropping off only
## work on foot. The model uses the same part names as the rider on the bike
## (RiderBody, Helmet, LegLeft, LegRight), so scripts/rider_look.gd dresses both the same.
## The front is -Z, like the bike. Speeds are in game_config.gd.

## Current speed in metres per second (forwards is positive).
var speed := 0.0
## True while you're on foot and this is the one being controlled.
var active := false

var _step := 0.0  # for swinging the legs
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
	# Swing the legs a little while walking.
	_step += absf(speed) * delta * 6.0
	var swing := sin(_step) * clampf(absf(speed) / 1.5, 0.0, 1.0) * 0.5
	_model.get_node("LegLeft").rotation.x = swing
	_model.get_node("LegRight").rotation.x = -swing


## Builds the person: legs, body, arms and a head, in the bike rider's colours.
static func build_model() -> Node3D:
	var model := Node3D.new()
	model.name = "Model"
	var legs := Color(0.23137255, 0.30588236, 0.47843137, 1)
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		leg.name = "LegLeft" if side < 0.0 else "LegRight"
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.09
		mesh.height = 0.85
		mesh.material = LowPoly.material(legs)
		leg.mesh = mesh
		leg.position = Vector3(0.11 * side, 0.45, 0)
		model.add_child(leg)
	var body := MeshInstance3D.new()
	body.name = "RiderBody"
	var torso := CapsuleMesh.new()
	torso.radius = 0.2
	torso.height = 0.75
	torso.material = LowPoly.material(Color(0.9490196, 0.54901963, 0.15686275, 1))
	body.mesh = torso
	body.position = Vector3(0, 1.15, 0)
	model.add_child(body)
	for side in [-1.0, 1.0]:
		LowPoly.box(model, Vector3(0.09, 0.55, 0.1), Color(0.78, 0.58, 0.42, 1), Vector3(0.27 * side, 1.12, 0))
	var head := MeshInstance3D.new()
	head.name = "Helmet"
	var ball := SphereMesh.new()
	ball.radius = 0.16
	ball.height = 0.3
	ball.material = LowPoly.material(Color(0.16470589, 0.5568628, 0.6117647, 1))
	head.mesh = ball
	head.position = Vector3(0, 1.66, 0)
	model.add_child(head)
	return model
