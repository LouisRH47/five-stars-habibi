class_name BikeTumble
extends RigidBody3D
## Session 87: after a crash the bike slides along the ground and tips over onto its side,
## for real (physics), instead of a made-up animation.
## How to use it:
##   var tumble := BikeTumble.start(model, velocity, side)   # side: -1 left, +1 right
##   ... wait until tumble.resting() ...
##   tumble.put_back(home_parent, home_transform)            # the bike's look goes home
## While it tumbles, the bike's look (`model`, from BikeModel.build()) is moved into
## this body; put_back() returns it and removes the body.

const LAYER := 1 << 7        # the same layer as the ragdoll (128): doesn't block the rider
const MASK := 1              # only bumps into the world (layer 1)
const MASS := 15.0           # kg
## The frame and wheels as one thin box (metres), from the ground up.
const FRAME_SIZE := Vector3(0.12, 1.0, 1.65)
## The handlebars and the delivery box stick out sideways, so the bike lies a little
## tilted on them, not flat with the box poking into the ground.
const BAR_SIZE := Vector3(0.56, 0.06, 0.06)
const BAR_SPOT := Vector3(0, 1.03, -0.47)
const BOX_SIZE := Vector3(0.45, 0.42, 0.45)
const BOX_SPOT := Vector3(0, 1.0, 0.55)
const TIP_SPIN := 3.0        # radians per second that tip it over onto its side
const TIP_START := 0.12      # radians it already leans over at the start
const FRICTION := 0.55
const REST_SPEED := 0.15     # m/s: slower than this counts as lying still
const REST_TIME := 0.4       # seconds it must be still to count as resting
const REST_TIMEOUT := 4.0    # seconds: after this it counts as resting anyway
const MAX_SPEED := 20.0      # m/s: never faster than this (no explosions)

## The bike's look while it tumbles.
var model: Node3D
var _still := 0.0
var _clock := 0.0


## Moves `model` (the bike's look) into a new tumbling body and sets it going at
## `velocity` (m/s), tipping over to `side` (-1 left, +1 right).
## world: where the body goes; by default the bike's parent (model's grandparent).
## If the model sits in a physics body (the bike itself), the tumble never bumps into it.
static func start(model: Node3D, velocity: Vector3, side: float, world: Node = null) -> BikeTumble:
	var bike := model.get_parent()
	if world == null:
		world = bike.get_parent() if bike.get_parent() != null else bike
	var tumble := BikeTumble.new()
	tumble.name = "BikeTumble"
	tumble.model = model
	world.add_child(tumble)
	var at := model.global_transform.orthonormalized()
	tumble.global_transform = at
	model.reparent(tumble, true)  # keeps it exactly where it was
	# Already leaning a little, so it never balances upright.
	tumble.global_basis = at.basis.rotated(at.basis.z.normalized(), -signf(side) * TIP_START)
	tumble.reset_physics_interpolation()
	if bike is PhysicsBody3D:
		tumble.add_collision_exception_with(bike)
	tumble.linear_velocity = velocity.limit_length(MAX_SPEED)
	# Turning around the bike's length (its Z axis) by - tips the top towards +X (right).
	tumble.angular_velocity = at.basis.z.normalized() * (-signf(side) * TIP_SPIN)
	return tumble


func _init() -> void:
	collision_layer = LAYER
	collision_mask = MASK
	mass = MASS
	continuous_cd = true
	angular_damp = 0.5
	var material := PhysicsMaterial.new()
	material.friction = FRICTION
	material.bounce = 0.05
	physics_material_override = material
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.55, 0)
	_add_box(FRAME_SIZE, Vector3(0, FRAME_SIZE.y * 0.5, 0))
	_add_box(BAR_SIZE, BAR_SPOT)
	_add_box(BOX_SIZE, BOX_SPOT)


## True once the bike lies still (or after REST_TIMEOUT seconds).
func resting() -> bool:
	return _clock >= REST_TIMEOUT or _still >= REST_TIME


## Puts the bike's look back under `home_parent` at `home_transform` (its own local
## transform there) and removes this tumbling body.
func put_back(home_parent: Node3D, home_transform: Transform3D) -> void:
	if is_instance_valid(model) and model.get_parent() == self:
		remove_child(model)
		home_parent.add_child(model)
		model.transform = home_transform
		model.reset_physics_interpolation()
	model = null
	queue_free()


func _physics_process(delta: float) -> void:
	_clock += delta
	linear_velocity = linear_velocity.limit_length(MAX_SPEED)
	var moving := linear_velocity.length() > REST_SPEED or angular_velocity.length() > REST_SPEED * 2.0
	_still = 0.0 if moving else _still + delta


func _add_box(size: Vector3, spot: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = spot
	add_child(shape)
