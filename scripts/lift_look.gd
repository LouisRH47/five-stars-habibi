class_name LiftLook
extends RefCounted
## Session 91: what the C Institute's glass lift looks like (scripts/institute_lift.gd
## makes it work): a glass shaft with slim white frames, a steel car with a glowing
## ceiling, sliding steel doors at each floor, a glowing call button and a bilingual sign.
## All in the lift's own metres: its middle on the ground, +Z is the lobby side.

const WHITE := Color(0.97, 0.97, 0.96)
const STEEL := Color(0.72, 0.74, 0.76)
const DARK := Color(0.2, 0.21, 0.23)
const DOOR_HIGH := 2.3


## The glass shaft from the ground up to `top`, with a door hole at each floor.
static func shaft(lift: Node3D, half: float, top: float, floor2: float) -> void:
	var gap := InstituteLift.DOOR_GAP
	for side: float in [-1.0, 1.0]:
		# The two side walls (no doors): one pane each.
		RoomProps.pane(lift, Vector3(0.05, top, half * 2.0), Vector3(side * half, top * 0.5, 0))
		# Front and back: glass either side of the door, and above / below it.
		var z := side * half
		var door_y := 0.0 if side > 0.0 else floor2
		for x: float in [-1.0, 1.0]:
			var wide := half - gap
			RoomProps.pane(lift, Vector3(wide, top, 0.05), Vector3(x * (gap + wide * 0.5), top * 0.5, z))
		var above := door_y + DOOR_HIGH
		RoomProps.pane(lift, Vector3(gap * 2.0, top - above, 0.05), Vector3(0, (top + above) * 0.5, z))
		if door_y > 0.0:
			RoomProps.pane(lift, Vector3(gap * 2.0, door_y, 0.05), Vector3(0, door_y * 0.5, z))
		# A white door frame.
		for x: float in [-gap - 0.05, gap + 0.05]:
			LowPoly.box(lift, Vector3(0.1, DOOR_HIGH, 0.14), WHITE, Vector3(x, door_y + DOOR_HIGH * 0.5, z))
		LowPoly.box(lift, Vector3(gap * 2.0 + 0.2, 0.12, 0.14), WHITE, Vector3(0, above + 0.06, z))
	# Slim white corner posts, a band at the upstairs floor, and a white cap on top.
	for x: float in [-half, half]:
		for z: float in [-half, half]:
			LowPoly.box(lift, Vector3(0.12, top, 0.12), WHITE, Vector3(x, top * 0.5, z))
	LowPoly.box(lift, Vector3(half * 2.0 + 0.12, 0.3, half * 2.0 + 0.12), WHITE, Vector3(0, top + 0.1, 0))
	# A slim white ring round the shaft at the upstairs floor (the car rides through it).
	for side: float in [-1.0, 1.0]:
		LowPoly.box(lift, Vector3(half * 2.0 + 0.12, 0.32, 0.1), WHITE, Vector3(0, floor2 - 0.15, side * (half + 0.01)))
		LowPoly.box(lift, Vector3(0.1, 0.32, half * 2.0 - 0.1), WHITE, Vector3(side * (half + 0.01), floor2 - 0.15, 0))
	LowPoly.box(lift, Vector3(half * 2.0 + 0.12, 0.1, half * 2.0 + 0.12), DARK, Vector3(0, 0.05, 0))


## The car that rides up and down (open at the front and back, where the doors are).
static func car(lift: Node3D, half: float) -> Node3D:
	var car := Node3D.new()
	car.name = "Car"
	car.set_meta("static_batch_dynamic", true)
	lift.add_child(car)
	var inside := half * 2.0 - 0.3
	LowPoly.box(car, Vector3(inside, 0.12, inside), DARK, Vector3(0, 0.08, 0))  # its top: 0.14
	LowPoly.box(car, Vector3(inside, 0.1, inside), STEEL, Vector3(0, 2.62, 0))
	var light := LowPoly.box(car, Vector3(inside - 0.6, 0.03, inside - 0.6), Color(1, 0.97, 0.9), Vector3(0, 2.56, 0))
	light.material_override = VenueParts.glow(Color(1, 0.97, 0.9), 1.4)
	for side: float in [-1.0, 1.0]:
		LowPoly.box(car, Vector3(0.05, 2.5, inside), STEEL, Vector3(side * inside * 0.5, 1.31, 0))
		LowPoly.box(car, Vector3(0.05, 0.05, inside - 0.4), DARK, Vector3(side * (inside * 0.5 - 0.06), 0.95, 0))
	return car


## A pair of sliding doors at height `y` on the front (out = 1) or back (out = -1).
static func doors(lift: Node3D, half: float, y: float, out: float) -> Node3D:
	var pair := Node3D.new()
	pair.name = "Doors%d" % (0 if out > 0.0 else 1)
	pair.set_meta("static_batch_dynamic", true)
	pair.position = Vector3(0, y, out * (half + 0.06))
	lift.add_child(pair)
	var gap := InstituteLift.DOOR_GAP
	for side: float in [-1.0, 1.0]:
		var panel := Node3D.new()
		panel.name = "Left" if side < 0.0 else "Right"
		panel.set_meta("side", side)
		pair.add_child(panel)
		LowPoly.box(panel, Vector3(gap, DOOR_HIGH, 0.04), STEEL, Vector3(0, DOOR_HIGH * 0.5, 0))
		RoomProps.pane(panel, Vector3(gap * 0.3, DOOR_HIGH * 0.7, 0.05), Vector3(0, DOOR_HIGH * 0.5, 0))
	slide(pair, 0.0, gap)
	return pair


## Moves a pair of doors: amount 0 is shut, 1 is wide open.
static func slide(pair: Node3D, amount: float, gap: float) -> void:
	for panel: Node3D in pair.get_children():
		var side: float = panel.get_meta("side", 1.0)
		panel.position.x = side * (gap * 0.5 + amount * gap * 0.92)


## A glowing call button beside the door and a bilingual "Lift" sign above it.
static func call_panel(lift: Node3D, half: float, y: float, out: float, label: String) -> void:
	var gap := InstituteLift.DOOR_GAP
	var holder := Node3D.new()
	holder.name = "CallPanel%d" % (0 if out > 0.0 else 1)
	holder.position = Vector3(0, y, out * (half + 0.08))
	holder.rotation.y = 0.0 if out > 0.0 else PI
	lift.add_child(holder)
	LowPoly.box(holder, Vector3(0.14, 0.3, 0.03), DARK, Vector3(gap + 0.38, 1.15, 0))
	var button := LowPoly.box(holder, Vector3(0.07, 0.07, 0.02), Color(0.4, 0.9, 1.0), Vector3(gap + 0.38, 1.19, 0.02))
	button.material_override = VenueParts.glow(Color(0.4, 0.9, 1.0), 2.0)
	LowPoly.box(holder, Vector3(0.8, 0.4, 0.03), WHITE, Vector3(0, DOOR_HIGH + 0.38, -0.005))
	var sign := SignText.make_face("مصعد", "Lift", 18, Color(0.15, 0.17, 0.2))
	sign.name = "LiftSign"
	sign.position = Vector3(0, DOOR_HIGH + 0.38, 0.02)
	holder.add_child(sign)
	holder.set_meta("label", label)
