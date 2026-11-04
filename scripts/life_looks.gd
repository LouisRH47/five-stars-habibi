class_name LifeLooks
## How the moving life on the map looks and moves (Session 30): a golf buggy with a driver,
## a horse with a rider, a duck, a gardener with a hose, and kids. All built from simple
## shapes in code (and the animated CC0 people from Session 29). Everything faces -Z.
## animate() makes them look alive each frame: legs walking, horses trotting, ducks bobbing.

const DARK := Color(0.15, 0.15, 0.16)
const SEAT := Color(0.76, 0.62, 0.45)
const SADDLE := Color(0.35, 0.2, 0.1)
const HOSE := Color(0.2, 0.6, 0.25)
const SPRAY := Color(0.7, 0.88, 1.0)
const FLOWERS := [Color(0.9, 0.3, 0.55), Color(0.98, 0.8, 0.25), Color(0.95, 0.45, 0.2)]
const KID_SHIRTS := [Color(0.95, 0.4, 0.35), Color(0.3, 0.6, 0.95), Color(0.98, 0.8, 0.25), Color(0.45, 0.8, 0.45)]


## A golf buggy (one merged mesh) with a resident driving it. Returns [model, driver].
static func buggy(colour: Color) -> Array:
	var kit := MeshKit.new()
	kit.box(Vector3(1.2, 0.45, 2.3), colour, Vector3(0, 0.5, 0))           # the body
	kit.box(Vector3(1.1, 0.15, 0.55), SEAT, Vector3(0, 0.8, 0.3))          # the seat
	kit.box(Vector3(1.1, 0.6, 0.12), SEAT, Vector3(0, 1.15, 0.6))          # the backrest
	kit.box(Vector3(1.15, 0.35, 0.3), colour, Vector3(0, 0.85, -0.8))      # the dashboard
	kit.box(Vector3(1.3, 0.06, 1.9), colour, Vector3(0, 1.95, 0.05))       # the roof
	for corner in [Vector3(-0.55, 0, -0.85), Vector3(0.55, 0, -0.85), Vector3(-0.55, 0, 0.7), Vector3(0.55, 0, 0.7)]:
		kit.box(Vector3(0.05, 1.2, 0.05), DARK, corner + Vector3(0, 1.35, 0))
	kit.cylinder(0.03, 0.03, 0.5, DARK, Vector3(-0.28, 0.95, -0.55), Basis(Vector3.RIGHT, 0.6))  # steering column
	kit.cylinder(0.18, 0.18, 0.04, DARK, Vector3(-0.28, 1.15, -0.42), Basis(Vector3.RIGHT, 0.9))  # steering wheel
	var wheel := Basis(Vector3.BACK, PI * 0.5)
	for corner in [Vector3(-0.62, 0.25, -0.8), Vector3(0.62, 0.25, -0.8), Vector3(-0.62, 0.25, 0.8), Vector3(0.62, 0.25, 0.8)]:
		kit.cylinder(0.25, 0.25, 0.18, DARK, corner, wheel)
	var model := Node3D.new()
	model.add_child(kit.finish())
	var driver := PeopleLooks.resident(randi() % PeopleLooks.RESIDENT_OUTFITS)
	_sit(driver, model, Vector3(-0.28, 0.9, 0.3), [Vector3(-0.38, 0.75, -0.45), Vector3(-0.18, 0.75, -0.45)],
			[Vector3(-0.42, 1.18, -0.45), Vector3(-0.14, 1.18, -0.45)], 5.0)
	return [model, driver]


## A horse with a rider in a riding helmet. Returns [model, rider]. The legs are kept
## (model meta "legs") so animate() can swing them.
static func horse(colour: Color) -> Array:
	if GameConfig.HORSE_LOOK_V2:
		return HorseLook.build(colour)   # Session 63: rounder horse, coat texture, mane, tack
	var dark := colour.darkened(0.35)
	var kit := MeshKit.new()
	kit.box(Vector3(0.6, 0.7, 1.7), colour, Vector3(0, 1.35, 0))                         # body
	kit.box(Vector3(0.3, 0.9, 0.35), colour, Vector3(0, 1.9, -0.85), Basis(Vector3.RIGHT, -0.5))  # neck
	kit.box(Vector3(0.3, 0.3, 0.7), colour, Vector3(0, 2.25, -1.3))                      # head
	kit.box(Vector3(0.08, 0.5, 0.5), dark, Vector3(0, 2.05, -0.75), Basis(Vector3.RIGHT, -0.5))   # mane
	for x in [-0.1, 0.1]:
		kit.box(Vector3(0.06, 0.18, 0.06), dark, Vector3(x, 2.5, -1.05))                 # ears
	kit.box(Vector3(0.1, 0.8, 0.1), dark, Vector3(0, 1.2, 0.9), Basis(Vector3.RIGHT, 0.35))      # tail
	kit.box(Vector3(0.64, 0.1, 0.6), SADDLE, Vector3(0, 1.73, 0.0))                      # saddle
	kit.box(Vector3(0.66, 0.3, 0.7), Color(0.9, 0.9, 0.85), Vector3(0, 1.6, 0.02))       # saddle cloth
	var model := Node3D.new()
	model.add_child(kit.finish())
	var legs: Array[Node3D] = []
	for z in [-0.65, 0.65]:
		for x in [-0.22, 0.22]:
			var hip := Node3D.new()
			hip.position = Vector3(x, 1.05, z)
			model.add_child(hip)
			LowPoly.box(hip, Vector3(0.14, 1.05, 0.14), colour, Vector3(0, -0.52, 0))
			LowPoly.box(hip, Vector3(0.15, 0.12, 0.16), dark, Vector3(0, -0.99, 0))      # hoof
			legs.append(hip)
	model.set_meta("legs", legs)
	var rider := PeopleLooks.horse_rider()
	_sit(rider, model, Vector3(0, 1.8, 0.05), [Vector3(-0.36, 1.05, -0.1), Vector3(0.36, 1.05, -0.1)],
			[Vector3(-0.12, 1.95, -0.5), Vector3(0.12, 1.95, -0.5)], 8.0)
	return [model, rider]


## A little duck floating on the water.
static func duck(brown: bool) -> Node3D:
	var body := Color(0.55, 0.42, 0.3) if brown else Color(0.95, 0.95, 0.92)
	var kit := MeshKit.new()
	kit.ball(0.17, body, Vector3(0, 0.12, 0.02), 0.7)
	kit.ball(0.09, Color(0.15, 0.45, 0.25) if brown else body, Vector3(0, 0.3, -0.15))
	kit.box(Vector3(0.07, 0.04, 0.1), Color(0.98, 0.6, 0.15), Vector3(0, 0.29, -0.27))
	kit.box(Vector3(0.1, 0.06, 0.12), body.darkened(0.2), Vector3(0, 0.2, 0.2), Basis(Vector3.RIGHT, -0.5))
	var model := Node3D.new()
	model.add_child(kit.finish())
	return model


## A gardener with a cap and a green hose, and a small flower bed `bed` metres in front.
## Returns [model, person].
static func gardener(bed: float) -> Array:
	var model := Node3D.new()
	var person := Person.new()
	person.paint({"skin": PeopleLooks.SKINS.pick_random(), "shirt": Color(0.3, 0.5, 0.3), "pants": Color(0.35, 0.3, 0.25)})
	PeopleLooks.cap(person, Color(0.9, 0.85, 0.7), person)
	PeopleLooks.shoes(person, Color(0.3, 0.22, 0.15))
	model.add_child(person)
	# Standing, both hands out in front holding the hose (the sitting pose with straight legs).
	var hand := Vector3(0.18, 1.0, -0.38)
	var nozzle := Vector3(0.22, 0.88, -0.85)
	person.play("pedal")
	var feet: Array[Vector3] = [person.spot("LeftFoot"), person.spot("RightFoot")]
	var hands: Array[Vector3] = [Vector3(0.02, 1.02, -0.4), hand]
	person.pose.feet = feet
	person.pose.hands = hands
	_tube(person, hand, nozzle, 0.025, HOSE)
	_tube(person, Vector3(0.05, 1.0, -0.38), Vector3(0.5, 0.03, 0.05), 0.025, HOSE)  # down to the tap
	for i in 7:  # the flower bed
		var spot := Vector3(-0.9 + i * 0.3, 0.15, -bed + (i % 2) * 0.35 - 0.2)
		LowPoly.sphere(model, 0.2, 0.3, Color(0.3, 0.55, 0.25), spot)
		LowPoly.sphere(model, 0.07, 0.1, FLOWERS[i % FLOWERS.size()], spot + Vector3(0.05, 0.15, 0))
	# The water spray: little drops flying out of the hose.
	var drops := CPUParticles3D.new()
	drops.name = "Spray"
	drops.position = nozzle
	drops.local_coords = false
	drops.amount = 24
	drops.lifetime = 0.6
	drops.direction = Vector3(0, 0.35, -1)
	drops.spread = 10.0
	drops.initial_velocity_min = 3.3
	drops.initial_velocity_max = 3.8
	drops.scale_amount_min = 0.6
	var drop := SphereMesh.new()
	drop.radius = 0.04
	drop.height = 0.08
	drop.radial_segments = 4
	drop.rings = 2
	drop.material = LowPoly.material(SPRAY)
	drops.mesh = drop
	person.add_child(drops)
	return [model, person]


## A kid in play clothes (smaller than a grown-up).
static func kid() -> Person:
	var person := Person.new(GameConfig.KID_HEIGHT)
	person.paint({"skin": PeopleLooks.SKINS.pick_random(), "shirt": KID_SHIRTS.pick_random(),
			"pants": Color(0.25, 0.3, 0.45)})
	PeopleLooks.shoes(person, Color(0.95, 0.95, 0.95))
	return person


## A thin tube (a hose) from one spot to another.
static func _tube(parent: Node3D, from: Vector3, to: Vector3, radius: float, colour: Color) -> void:
	var tube := LowPoly.cylinder(parent, radius, radius, from.distance_to(to), colour, (from + to) * 0.5)
	tube.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized()))


## Makes them look alive. Called every frame while you can see them.
static func animate(mover: RouteMover, delta: float, clock: float) -> void:
	match mover.kind:
		"person":
			if not mover.moving:
				mover.person.play("idle")
			elif mover.speed > 2.0:
				mover.person.play("jog", mover.speed / GameConfig.PERSON_JOG_ANIM_MPS)
			else:
				mover.person.play("walk", mover.speed / GameConfig.PERSON_WALK_ANIM_MPS)
		"horse":
			_horse(mover, delta, clock)
		"duck":
			mover.model.position.y = 0.03 + sin(clock * 2.2) * 0.02
			mover.model.rotation.z = sin(clock * 1.7) * 0.08
		"gardener":
			mover.person.rotation.y = sin(clock * 0.5) * 0.35  # sweeping the hose over the bed
		"buggy":
			mover.model.position.y = sin(clock * 9.0) * 0.008 if mover.moving else 0.0


## Legs swing (faster when trotting), the body bobs, and now and then it changes gait.
static func _horse(mover: RouteMover, delta: float, clock: float) -> void:
	var gait_left: float = mover.get_meta("gait_left", 0.0) - delta
	if gait_left <= 0.0:
		var trot := mover.speed < GameConfig.HORSE_TROT_SPEED and randf() < 0.5
		mover.speed = GameConfig.HORSE_TROT_SPEED if trot else GameConfig.HORSE_WALK_SPEED
		gait_left = randf_range(GameConfig.HORSE_GAIT_TIME.x, GameConfig.HORSE_GAIT_TIME.y)
	mover.set_meta("gait_left", gait_left)
	var trotting := mover.speed >= GameConfig.HORSE_TROT_SPEED
	var pace := (5.5 if trotting else 3.2) if mover.moving else 0.0
	var phase := clock * pace
	var legs: Array = mover.model.get_meta("legs")
	for i in legs.size():
		var opposite := 0.0 if i == 0 or i == 3 else PI  # diagonal pairs move together
		(legs[i] as Node3D).rotation.x = sin(phase + opposite) * (0.45 if trotting else 0.3) if mover.moving else 0.0
	mover.model.position.y = absf(sin(phase)) * (0.08 if trotting else 0.03)


## Sits a person on a seat. hips: where their hips go on the model. feet, hands: where
## they reach to (on the model). lean: degrees forward.
static func _sit(person: Person, model: Node3D, hips: Vector3, feet: Array, hands: Array, lean: float) -> void:
	person.position = hips - person.spot("Hips")
	model.add_child(person)
	person.play("pedal")  # the sitting pose (see scripts/person_pose.gd)
	person.pose.lean = lean
	var reach_feet: Array[Vector3] = [feet[0] - person.position, feet[1] - person.position]
	var reach_hands: Array[Vector3] = [hands[0] - person.position, hands[1] - person.position]
	person.pose.feet = reach_feet
	person.pose.hands = reach_hands
