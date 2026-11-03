class_name BikeModel
## Builds the low-poly bicycle the rider sits on (Session 29), out of simple shapes.
## Only the look: the bike's collision box and riding stay in scripts/bike.gd.
## The parts that move have their own nodes, which scripts/bike.gd turns each frame:
##   FrontWheel, RearWheel  roll with the speed
##   Fork                   turns with the handlebars when you steer (front wheel in it)
##   Crank                  the pedals go round with the speed (PedalLeft, PedalRight)
##   Kickstand              drops down when you get off, folds up when you ride
## The front of the bike is -Z. The wheels are 1.1 m apart, 0.34 m round (as before).

const FRAME := Color(0.16470589, 0.5568628, 0.6117647, 1)   # Snackaroo teal
const DARK := Color(0.11764706, 0.12156863, 0.13725491, 1)
const METAL := Color(0.7, 0.72, 0.75, 1)
const BOX := Color(0.9098039, 0.4627451, 0.101960786, 1)    # the orange delivery box
const CRANK_SPOT := Vector3(0, 0.3, -0.02)
const FORK_SPOT := Vector3(0, 0, -0.47)
const CRANK_LENGTH := 0.17
const SADDLE_TOP := 0.99
const SADDLE_Z := 0.16


## Adds every part of the bike, and the rider sitting on it, to `model`.
static func build(model: Node3D) -> void:
	var rear := Vector3(0, 0.34, 0.55)
	var seat := Vector3(0, 0.86, 0.12)
	_wheel(model, "RearWheel", rear)
	# The frame: seat tube, top tube, down tube, and the stays to the back wheel.
	tube(model, CRANK_SPOT, seat, 0.03, FRAME)
	tube(model, Vector3(0, 0.84, 0.1), Vector3(0, 0.9, -0.44), 0.028, FRAME)
	tube(model, CRANK_SPOT, Vector3(0, 0.72, -0.46), 0.032, FRAME)
	for x in [-0.05, 0.05]:
		tube(model, CRANK_SPOT + Vector3(x, 0, 0), rear + Vector3(x, 0, 0), 0.016, FRAME)
		tube(model, Vector3(x, 0.83, 0.11), rear + Vector3(x, 0, 0), 0.016, FRAME)
	# Seat post and saddle.
	tube(model, seat, Vector3(0, SADDLE_TOP - 0.04, SADDLE_Z - 0.01), 0.018, METAL)
	LowPoly.box(model, Vector3(0.15, 0.05, 0.26), DARK, Vector3(0, SADDLE_TOP - 0.025, SADDLE_Z))
	# Chain from the front cog to the back wheel.
	for y in [[0.39, 0.38], [0.21, 0.3]]:
		tube(model, CRANK_SPOT + Vector3(0.07, y[0] - CRANK_SPOT.y, 0), rear + Vector3(0.07, y[1] - rear.y, 0), 0.008, DARK)
	# Rack over the back wheel, and the orange delivery box on it.
	LowPoly.box(model, Vector3(0.2, 0.03, 0.42), METAL, Vector3(0, 0.76, 0.55))
	for x in [-0.09, 0.09]:
		tube(model, Vector3(x, 0.76, 0.7), rear + Vector3(x, 0, 0), 0.01, METAL)
	var box := LowPoly.box(model, Vector3(0.45, 0.42, 0.45), BOX, Vector3(0, 1.0, 0.55))
	box.name = "DeliveryBox"
	_fork(model)
	_crank(model)
	_kickstand(model)
	var rider := RiderLook.make_rider()
	rider.name = "Rider"
	var hips := rider.spot("Hips")
	rider.position = Vector3(0, SADDLE_TOP + 0.03 - hips.y, SADDLE_Z + 0.03 - hips.z)
	model.add_child(rider)


## A round tube from a to b.
static func tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, colour: Color) -> MeshInstance3D:
	var part := LowPoly.cylinder(parent, radius, radius, a.distance_to(b), colour, (a + b) * 0.5)
	part.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	return part


## A wheel: tyre, rim, hub and spokes. It lies on its side, so it rolls round its own Y.
static func _wheel(parent: Node3D, wheel_name: String, spot: Vector3) -> Node3D:
	var wheel := Node3D.new()
	wheel.name = wheel_name
	wheel.position = spot
	wheel.rotation.z = PI * 0.5
	parent.add_child(wheel)
	_ring(wheel, 0.285, GameConfig.WHEEL_RADIUS, DARK)  # tyre
	_ring(wheel, 0.27, 0.29, METAL)                     # rim
	LowPoly.cylinder(wheel, 0.035, 0.035, 0.1, METAL, Vector3.ZERO)  # hub
	for i in 6:
		var spoke := LowPoly.box(wheel, Vector3(0.008, 0.008, 0.55), METAL, Vector3.ZERO)
		spoke.rotation.y = i * PI / 6.0
	return wheel


static func _ring(parent: Node3D, inner: float, outer: float, colour: Color) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 24
	torus.ring_segments = 6
	torus.material = LowPoly.material(colour)
	ring.mesh = torus
	parent.add_child(ring)


## The fork, head tube, stem and handlebars: they all turn together when you steer.
static func _fork(model: Node3D) -> void:
	var fork := Node3D.new()
	fork.name = "Fork"
	fork.position = FORK_SPOT
	model.add_child(fork)
	var axle := Vector3(0, 0.34, -0.08)
	_wheel(fork, "FrontWheel", axle)
	tube(fork, Vector3(0, 0.7, 0), Vector3(0, 0.96, 0.04), 0.035, FRAME)  # head tube
	for x in [-0.05, 0.05]:
		tube(fork, Vector3(x * 0.6, 0.72, 0), axle + Vector3(x, 0, 0), 0.017, METAL)
	tube(fork, Vector3(0, 0.95, 0.03), Vector3(0, 1.02, -0.02), 0.02, METAL)  # stem
	var bar := LowPoly.box(fork, Vector3(0.56, 0.028, 0.028), DARK, Vector3(0, 1.03, -0.02))
	bar.name = "Handlebar"
	for x in [-0.25, 0.25]:
		var grip := LowPoly.cylinder(fork, 0.022, 0.022, 0.1, Color(0.2, 0.2, 0.22), Vector3(x, 1.03, -0.02))
		grip.rotation.z = PI * 0.5
	LowPoly.cylinder(fork, 0.03, 0.03, 0.02, Color(0.95, 0.8, 0.2), Vector3(-0.17, 1.06, -0.02))  # the bell


## Where the left (-1) or right (+1) grip is, on the fork.
static func grip_spot(side: float) -> Vector3:
	return Vector3(0.24 * side, 1.03, -0.02)


## The front cog, the two crank arms and the pedals. It turns round its own X.
static func _crank(model: Node3D) -> void:
	var crank := Node3D.new()
	crank.name = "Crank"
	crank.position = CRANK_SPOT
	model.add_child(crank)
	var cog := LowPoly.cylinder(crank, 0.1, 0.1, 0.015, METAL, Vector3(0.07, 0, 0))
	cog.rotation.z = PI * 0.5
	for side in [-1.0, 1.0]:  # right arm points down, left arm up (they're opposite)
		var down: float = -side
		LowPoly.box(crank, Vector3(0.025, CRANK_LENGTH, 0.035), METAL, Vector3(0.09 * side, CRANK_LENGTH * 0.5 * down, 0))
		var pedal := Node3D.new()
		pedal.name = "PedalRight" if side > 0.0 else "PedalLeft"
		pedal.position = Vector3(0.14 * side, CRANK_LENGTH * down, 0)
		crank.add_child(pedal)
		LowPoly.box(pedal, Vector3(0.1, 0.025, 0.07), DARK, Vector3.ZERO)


## The kickstand, on the left (the parked bike leans that way). Its pivot is at the top.
static func _kickstand(model: Node3D) -> void:
	var stand := Node3D.new()
	stand.name = "Kickstand"
	stand.position = Vector3(-0.07, 0.3, 0.14)
	model.add_child(stand)
	LowPoly.box(stand, Vector3(0.025, 0.33, 0.025), METAL, Vector3(0, -0.165, 0))
