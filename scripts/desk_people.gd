class_name DeskPeople
extends RefCounted
## Session 91: people sitting on office chairs at a desk or a meeting table, hands on the
## table (typing on a laptop, or resting them in a meeting). Used upstairs in the C Institute.
## They use the Person's "pedal" pose (like the gym's cyclists and rowers): the pose bends
## the legs so the feet rest on the floor and puts the hands where we say. TypingMotion
## (scripts/typing_motion.gd) makes the typists' fingers tap.
##
## Spots are in the parent's own metres. facing: degrees the person turns (0 = looks -Z).

const CHAIR := Color(0.18, 0.19, 0.21)
const CHAIR_SEAT := Color(0.12, 0.42, 0.47)
const STEEL := Color(0.7, 0.72, 0.74)
const LAPTOP := Color(0.75, 0.76, 0.78)
const SCREEN := Color(0.6, 0.8, 0.95)
const SEAT_HEIGHT := 0.48


## A swivel office chair at `spot` (on the floor) turned to `facing`.
static func chair(parent: Node3D, spot: Vector3, facing: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "OfficeChair"
	holder.position = spot
	holder.rotation_degrees.y = facing
	parent.add_child(holder, true)
	for i in 5:  # the five-star foot
		var leg := LowPoly.box(holder, Vector3(0.05, 0.04, 0.32), CHAIR, Vector3(0, 0.05, 0))
		leg.rotation.y = i * TAU / 5.0
		leg.position = Vector3(sin(leg.rotation.y), 0, cos(leg.rotation.y)) * 0.14 + Vector3(0, 0.05, 0)
	LowPoly.cylinder(holder, 0.03, 0.03, SEAT_HEIGHT - 0.12, STEEL, Vector3(0, SEAT_HEIGHT * 0.5, 0))
	LowPoly.box(holder, Vector3(0.48, 0.08, 0.46), CHAIR_SEAT, Vector3(0, SEAT_HEIGHT - 0.04, 0))
	LowPoly.box(holder, Vector3(0.44, 0.5, 0.06), CHAIR_SEAT, Vector3(0, SEAT_HEIGHT + 0.33, 0.24))
	return holder


## Sits a person on a chair at `seat` (the chair's floor spot), facing `facing`, with
## both hands on the table top at height `table_y`, `reach` metres in front of them.
## typing: a laptop goes on the table in front of them (glowing screen). Returns the person.
static func seat(parent: Node3D, person: Person, seat: Vector3, facing: float, table_y: float,
		reach := 0.42, typing := true) -> Person:
	chair(parent, seat, facing)
	person.rotation_degrees.y = facing
	var hips := person.spot("Hips")
	person.position = seat + Vector3(0, SEAT_HEIGHT + 0.06, 0) - person.basis * hips
	parent.add_child(person, true)
	person.play("pedal")
	person.pose.lean = 8.0
	var to_person := person.transform.affine_inverse()
	var ahead := person.basis * Vector3(0, 0, -1)
	var right := person.basis * Vector3(1, 0, 0)
	for side in 2:
		var x := -1.0 if side == 0 else 1.0
		var foot := seat + ahead * 0.42 + right * x * 0.13 + Vector3(0, GameConfig.SIT_ANKLE_HEIGHT, 0)
		person.pose.feet[side] = to_person * foot
		var hand := seat + ahead * reach + right * x * 0.16 + Vector3(0, table_y + 0.04, 0)
		person.pose.hands[side] = to_person * hand
	person.set_meta("hands_rest", person.pose.hands.duplicate())
	if typing:
		laptop(parent, seat + ahead * (reach + 0.12) + Vector3(0, table_y, 0), facing)
	return person


## A laptop on a table at `spot` (the table top), its screen facing the person at `facing`.
static func laptop(parent: Node3D, spot: Vector3, facing: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "DeskLaptop"
	holder.position = spot
	holder.rotation_degrees.y = facing
	parent.add_child(holder, true)
	LowPoly.box(holder, Vector3(0.34, 0.02, 0.24), LAPTOP, Vector3(0, 0.01, 0.04))
	var lid := LowPoly.box(holder, Vector3(0.34, 0.22, 0.015), LAPTOP, Vector3(0, 0.12, -0.09))
	lid.rotation.x = deg_to_rad(-12.0)
	var screen := LowPoly.box(holder, Vector3(0.3, 0.18, 0.005), SCREEN, Vector3(0, 0.12, -0.08))
	screen.rotation.x = deg_to_rad(-12.0)
	screen.material_override = VenueParts.glow(SCREEN, 0.8)
	return holder
