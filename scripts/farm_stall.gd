extends StaticBody3D
## The Wahat Farm Stall (Session 27): a little wooden market stall by the greenhouse domes,
## with a counter, crates of fruit and veg, juice bottles, a green and white striped roof
## and a bilingual sign board. The front is the +Z side. PlaceBuilder makes one for a shop
## with "style": "stall" and calls setup(). The whole stall is solid.

const WOOD := Color(0.62, 0.43, 0.26, 1)
const DARK_WOOD := Color(0.45, 0.3, 0.18, 1)
const WHITE := Color(0.97, 0.96, 0.92, 1)
const TEXT_COLOUR := Color(1, 1, 1, 1)
const FRUIT := [Color(0.95, 0.55, 0.1, 1), Color(0.85, 0.15, 0.15, 1), Color(0.45, 0.7, 0.2, 1),
		Color(0.98, 0.85, 0.2, 1)]
const ROOF_STRIPES := 6
const BOARD_HEIGHT := 0.9
const BOARD_FONT_SIZE := 64


## Builds the stall. size: width, height, depth. colour: the farm green.
func setup(english: String, arabic: String, colour: Color, size: Vector3) -> void:
	var front := size.z * 0.5
	LowPoly.solid_box(self, Vector3(size.x, 1.6, size.z), Vector3(0, 0.8, 0))
	# The back wall and the counter at the front.
	LowPoly.box(self, Vector3(size.x, 2.6, 0.2), WOOD, Vector3(0, 1.3, -front + 0.1))
	LowPoly.box(self, Vector3(size.x, 1.0, 0.8), WOOD, Vector3(0, 0.5, front - 0.4))
	LowPoly.box(self, Vector3(size.x + 0.2, 0.08, 1.0), DARK_WOOD, Vector3(0, 1.04, front - 0.4))
	# Corner posts holding up the roof.
	for x in [-size.x * 0.5 + 0.15, size.x * 0.5 - 0.15]:
		for z in [-front + 0.15, front - 0.15]:
			LowPoly.box(self, Vector3(0.15, size.y - 0.3, 0.15), DARK_WOOD, Vector3(x, (size.y - 0.3) * 0.5, z))
	# Crates of fruit and veg on the counter, and juice bottles.
	for i in 4:
		var x := -size.x * 0.5 + 0.8 + i * (size.x - 1.6) / 3.0
		LowPoly.box(self, Vector3(0.9, 0.3, 0.6), DARK_WOOD, Vector3(x, 1.23, front - 0.4))
		for j in 3:
			LowPoly.sphere(self, 0.13, 0.26, FRUIT[i], Vector3(x - 0.25 + j * 0.25, 1.45, front - 0.4))
	for i in 5:
		LowPoly.cylinder(self, 0.06, 0.07, 0.3, Color(0.98, 0.6, 0.15, 1),
				Vector3(-0.6 + i * 0.3, 1.2, front - 0.15))
	# A striped roof, tilted down to the front.
	var stripe := size.x / ROOF_STRIPES
	for i in ROOF_STRIPES:
		var part := LowPoly.box(self, Vector3(stripe, 0.1, size.z + 0.8), colour if i % 2 == 0 else WHITE,
				Vector3(-size.x * 0.5 + stripe * (i + 0.5), size.y - 0.15, 0.2))
		part.rotation.x = deg_to_rad(8.0)
	# The sign board on top of the roof, facing the path.
	var board_y := size.y + BOARD_HEIGHT * 0.5 + 0.05
	LowPoly.box(self, Vector3(size.x - 0.6, BOARD_HEIGHT, 0.12), colour, Vector3(0, board_y, -0.4))
	var font_size := SignText.fit_size(arabic, english, BOARD_FONT_SIZE, size.x - 1.2)
	var face := SignText.make_face(arabic, english, font_size, TEXT_COLOUR)
	face.name = "Sign"
	face.position = Vector3(0, board_y, -0.4 + 0.07)
	add_child(face)
	if GameConfig.FARMER_ON:
		_dress(size)


## Session 61: the farmer behind the counter, a juice press and a cooler at the back, crates
## of fruit and veg in front and a chalkboard menu. The farmer hands you the order with the
## side panel, like the staff in a restaurant ("counter_handoff").
func _dress(size: Vector3) -> void:
	var front := size.z * 0.5
	set_meta("counter_handoff", true)
	var farmer := Farmer.new()
	farmer.name = "CounterStaff"
	farmer.position = Vector3(0.6, 0, front - 1.45)
	farmer.rotation.y = PI          # people face -z; he looks out over the counter (+z)
	farmer.rest_facing = PI
	add_child(farmer)
	# The juice press on a work table at the back, with a jug of juice and oranges.
	var table := Vector3(-size.x * 0.5 + 1.4, 0, -front + 0.75)
	LowPoly.box(self, Vector3(1.8, 0.9, 0.7), DARK_WOOD, table + Vector3(0, 0.45, 0))
	LowPoly.cylinder(self, 0.18, 0.22, 0.45, Color(0.75, 0.77, 0.8), table + Vector3(-0.4, 1.12, 0))   # the press
	LowPoly.box(self, Vector3(0.05, 0.05, 0.5), Color(0.3, 0.3, 0.32), table + Vector3(-0.4, 1.45, 0.2))  # its handle
	LowPoly.cylinder(self, 0.1, 0.12, 0.28, Color(0.98, 0.6, 0.15), table + Vector3(0.2, 1.04, 0.05))     # a jug of juice
	for i in 5:
		LowPoly.sphere(self, 0.07, 0.14, FRUIT[0], table + Vector3(0.45 + (i % 3) * 0.13, 0.97, -0.12 + (i / 3) * 0.14))
	# A glass-door cooler of juice bottles.
	var cooler := Vector3(size.x * 0.5 - 0.8, 0, -front + 0.6)
	LowPoly.box(self, Vector3(0.8, 1.8, 0.6), WHITE, cooler + Vector3(0, 0.9, 0))
	LowPoly.box(self, Vector3(0.66, 1.4, 0.03), Color(0.75, 0.9, 0.95), cooler + Vector3(0, 1.0, 0.31))
	for row in 3:
		for i in 4:
			LowPoly.cylinder(self, 0.04, 0.04, 0.2, [FRUIT[0], FRUIT[2], FRUIT[1]][row], cooler + Vector3(-0.22 + i * 0.15, 0.55 + row * 0.42, 0.18))
	# Crates of fruit and veg stacked on the ground in front of the counter.
	var produce := [[Color(0.25, 0.5, 0.2), 0.16], [Color(0.95, 0.5, 0.1), 0.14], [Color(0.85, 0.15, 0.12), 0.08],
			[Color(0.98, 0.85, 0.2), 0.07], [Color(0.45, 0.28, 0.12), 0.04]]
	for i in produce.size():
		var x := -size.x * 0.5 + 0.8 + i * (size.x - 1.6) / (produce.size() - 1)
		if absf(x - 0.6) < 0.9:
			continue   # the gap in front of the farmer, where you stand
		var crate := Vector3(x, 0, front + 0.4)
		LowPoly.box(self, Vector3(0.75, 0.35, 0.5), WOOD, crate + Vector3(0, 0.25, 0))
		LowPoly.box(self, Vector3(0.75, 0.05, 0.55), DARK_WOOD, crate + Vector3(0, 0.08, 0))
		var colour: Color = produce[i][0]
		var radius: float = produce[i][1]
		var across := maxi(1, int(0.6 / (radius * 2.2)))
		for j in across * 2:
			LowPoly.sphere(self, radius, radius * (1.6 if i == 1 else 2.0), colour,
					crate + Vector3(-0.3 + radius + (j % across) * 0.62 / across, 0.43 + radius * 0.6, -0.12 + (j / across) * 0.24))
	LowPoly.solid_box(self, Vector3(size.x, 0.6, 0.6), Vector3(0, 0.3, front + 0.4))
	_chalkboard(Vector3(size.x * 0.5 + 0.9, 0, front + 0.3))


## An A-frame chalkboard with the menu (Dh): Farm juice, Salad box and Dates.
func _chalkboard(spot: Vector3) -> void:
	var board := Node3D.new()
	board.name = "ChalkboardMenu"
	board.position = spot
	add_child(board)
	for tilt in [-1.0, 1.0]:
		var leaf := LowPoly.box(board, Vector3(0.75, 1.1, 0.04), DARK_WOOD, Vector3(0, 0.55, tilt * 0.17))
		leaf.rotation.x = -tilt * 0.3   # the two boards lean together at the top
	var slate := LowPoly.box(board, Vector3(0.62, 0.9, 0.02), Color(0.12, 0.17, 0.15), Vector3(0, 0.6, 0.2))
	slate.rotation.x = -0.3
	var text := Node3D.new()
	text.position = Vector3(0, 0.6, 0.215)
	text.rotation.x = -0.3
	board.add_child(text)
	var title := SignText.make_face("القائمة", "Menu", 20, Color.WHITE)
	title.position = Vector3(0, 0.27, 0)
	text.add_child(title)
	var items := SignText.make_label("Farm juice  12\nSalad box  22\nDates  15", 15, Color(1, 0.97, 0.85), Color(0, 0, 0, 0), 0)
	items.position = Vector3(0, -0.12, 0)
	text.add_child(items)
	LowPoly.solid_box(board, Vector3(0.75, 1.1, 0.4), Vector3(0, 0.55, 0))
