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
