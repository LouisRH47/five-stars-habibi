extends StaticBody3D
## The mini market: a single-storey shop with a big glass front, glass doors in the
## middle, a striped awning and a big bilingual sign board on the roof edge.
## The front is the +Z side. DecorBuilder places scenes/supermarket.tscn and calls setup().

const WALL_COLOUR := Color(0.95, 0.93, 0.88, 1)    # off-white
const TRIM_COLOUR := Color(0.2, 0.55, 0.3, 1)      # grocery green
const GLASS_COLOUR := Color(0.55, 0.75, 0.85, 1)
const FRAME_COLOUR := Color(0.25, 0.25, 0.27, 1)
const AWNING_COLOURS := [Color(0.2, 0.55, 0.3, 1), Color(0.97, 0.97, 0.95, 1)]  # green and white
const BOARD_COLOUR := Color(0.2, 0.55, 0.3, 1)
const TEXT_COLOUR := Color(1, 1, 1, 1)

const WINDOW_BOTTOM := 0.4
const WINDOW_HEIGHT := 2.6
const DOOR_SIZE := Vector3(2.4, 2.5, 0.15)
const AWNING_HEIGHT := 3.2      # metres up the front wall
const AWNING_DEPTH := 1.6       # how far it sticks out
const AWNING_STRIPES := 8
const BOARD_HEIGHT := 1.5
const BOARD_THICKNESS := 0.15
const BOARD_FONT_SIZE := 96


## Builds the shop. size: width (along the front), height, depth.
func setup(english: String, arabic: String, size: Vector3) -> void:
	var front := size.z * 0.5
	LowPoly.solid_box(self, size, Vector3(0, size.y * 0.5, 0))
	LowPoly.box(self, size, WALL_COLOUR, Vector3(0, size.y * 0.5, 0))
	LowPoly.box(self, Vector3(size.x + 0.2, 0.3, size.z + 0.2), TRIM_COLOUR,
			Vector3(0, size.y + 0.15, 0))

	# One long glass front with dark frame posts, and the glass doors in the middle.
	var glass := Vector3(size.x - 1.0, WINDOW_HEIGHT, 0.1)
	LowPoly.box(self, glass, GLASS_COLOUR, Vector3(0, WINDOW_BOTTOM + WINDOW_HEIGHT * 0.5, front + 0.05))
	var posts := 6
	for i in posts + 1:
		var x := -glass.x * 0.5 + glass.x * float(i) / posts
		LowPoly.box(self, Vector3(0.12, WINDOW_HEIGHT, 0.14), FRAME_COLOUR,
				Vector3(x, WINDOW_BOTTOM + WINDOW_HEIGHT * 0.5, front + 0.07))
	LowPoly.box(self, DOOR_SIZE, FRAME_COLOUR, Vector3(0, DOOR_SIZE.y * 0.5, front + 0.12))
	LowPoly.box(self, Vector3(DOOR_SIZE.x - 0.3, DOOR_SIZE.y - 0.2, 0.05), GLASS_COLOUR,
			Vector3(0, DOOR_SIZE.y * 0.5, front + 0.22))

	# A green and white striped awning over the whole front.
	var stripe := size.x / AWNING_STRIPES
	for i in AWNING_STRIPES:
		var colour: Color = AWNING_COLOURS[i % 2]
		var x := -size.x * 0.5 + stripe * (float(i) + 0.5)
		LowPoly.box(self, Vector3(stripe, 0.15, AWNING_DEPTH), colour,
				Vector3(x, AWNING_HEIGHT, front + AWNING_DEPTH * 0.5))
		LowPoly.box(self, Vector3(stripe, 0.35, 0.05), colour,
				Vector3(x, AWNING_HEIGHT - 0.175, front + AWNING_DEPTH))

	# The big sign board above the awning: Arabic on top, English below.
	var board_width := size.x - 2.0
	var board_y := AWNING_HEIGHT + 0.3 + BOARD_HEIGHT * 0.5
	LowPoly.box(self, Vector3(board_width, BOARD_HEIGHT, BOARD_THICKNESS), BOARD_COLOUR,
			Vector3(0, board_y, front + BOARD_THICKNESS * 0.5))
	var font_size := SignText.fit_size(arabic, english, BOARD_FONT_SIZE, board_width - 0.8)
	var face := SignText.make_face(arabic, english, font_size, TEXT_COLOUR)
	face.name = "Sign"
	face.position = Vector3(0, board_y, front + BOARD_THICKNESS + 0.01)
	add_child(face)
