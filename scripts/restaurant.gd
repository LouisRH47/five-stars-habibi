extends StaticBody3D
## One restaurant in the strip: a stone shop unit with a big glass window, a glass door,
## a brand-colour awning, a big bilingual sign board above the awning and a blade sign
## sticking out from the corner (so you can read it while riding along the road).
## The front is the +Z side. PlaceBuilder places one of these (scenes/restaurant.tscn)
## for every restaurant in the data list and calls setup().

const STONE_COLOUR := Color(0.93, 0.89, 0.8, 1)       # light stone walls
const GLASS_COLOUR := Color(0.55, 0.75, 0.85, 1)      # shop window
const FRAME_COLOUR := Color(0.25, 0.25, 0.27, 1)      # dark metal frames and brackets
const TEXT_COLOUR := Color(1, 1, 1, 1)

const DOOR_SIZE := Vector3(1.6, 2.4, 0.15)
const WINDOW_HEIGHT := 2.0
const WINDOW_BOTTOM := 0.5
const AWNING_HEIGHT := 3.0       # metres up the front wall
const AWNING_DEPTH := 1.4        # how far it sticks out over the pavement
const AWNING_FLAP := 0.35        # the hanging strip at the front of the awning
const BOARD_HEIGHT := 1.4        # the big sign board above the awning
const BOARD_THICKNESS := 0.15
const BOARD_FONT_SIZE := 88      # English line; Arabic is a bit bigger
const BLADE_SIZE := Vector3(0.1, 1.4, 1.8)  # thin, tall, sticking out 1.8 m from the wall
const BLADE_FONT_SIZE := 40
const ROOF_EDGE_HEIGHT := 0.3


## Builds the restaurant. size: width, height, depth in metres. colour: the brand colour.
func setup(english: String, arabic: String, colour: Color, size: Vector3) -> void:
	var front := size.z * 0.5
	var half_width := size.x * 0.5

	# Solid walls, so the bike bumps into the shop.
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = size.y * 0.5
	add_child(shape)

	_add_box(size, STONE_COLOUR, Vector3(0, size.y * 0.5, 0))
	var edge := Vector3(size.x + 0.2, ROOF_EDGE_HEIGHT, size.z + 0.2)
	_add_box(edge, colour, Vector3(0, size.y + ROOF_EDGE_HEIGHT * 0.5, 0))

	# Glass door in the middle (the delivery spot is straight out from here),
	# and a big shop window on each side of it.
	_add_box(DOOR_SIZE, FRAME_COLOUR, Vector3(0, DOOR_SIZE.y * 0.5, front + DOOR_SIZE.z * 0.5))
	var pane := Vector3(DOOR_SIZE.x - 0.3, DOOR_SIZE.y - 0.3, 0.05)
	_add_box(pane, GLASS_COLOUR, Vector3(0, DOOR_SIZE.y * 0.5, front + DOOR_SIZE.z + 0.025))
	var window_width := half_width - 1.8
	var window := Vector3(window_width, WINDOW_HEIGHT, 0.1)
	var window_x := 1.2 + window_width * 0.5
	var window_y := WINDOW_BOTTOM + WINDOW_HEIGHT * 0.5
	_add_box(window, GLASS_COLOUR, Vector3(-window_x, window_y, front + 0.05))
	_add_box(window, GLASS_COLOUR, Vector3(window_x, window_y, front + 0.05))

	# Brand-colour awning over the door and windows, with a hanging strip at the front.
	_add_box(Vector3(size.x, 0.15, AWNING_DEPTH), colour,
			Vector3(0, AWNING_HEIGHT, front + AWNING_DEPTH * 0.5))
	_add_box(Vector3(size.x, AWNING_FLAP, 0.05), colour,
			Vector3(0, AWNING_HEIGHT - AWNING_FLAP * 0.5, front + AWNING_DEPTH))

	# The big sign board: brand colour, white text, Arabic above English.
	var board_width := size.x - 1.0
	var board_y := AWNING_HEIGHT + 0.4 + BOARD_HEIGHT * 0.5
	_add_box(Vector3(board_width, BOARD_HEIGHT, BOARD_THICKNESS), colour,
			Vector3(0, board_y, front + BOARD_THICKNESS * 0.5))
	var board_font := SignText.fit_size(arabic, english, BOARD_FONT_SIZE, board_width - 0.8)
	var face := SignText.make_face(arabic, english, board_font, TEXT_COLOUR)
	face.position = Vector3(0, board_y, front + BOARD_THICKNESS + 0.01)
	add_child(face)

	# Blade sign: sticks straight out from the corner, readable from both sides.
	var blade_x := half_width - 0.2
	var blade_z := front + 0.2 + BLADE_SIZE.z * 0.5
	_add_box(Vector3(0.06, 0.06, BLADE_SIZE.z + 0.2), FRAME_COLOUR,
			Vector3(blade_x, board_y + BLADE_SIZE.y * 0.5 + 0.03, front + (BLADE_SIZE.z + 0.2) * 0.5))
	_add_box(BLADE_SIZE, colour, Vector3(blade_x, board_y, blade_z))
	var blade_font := SignText.fit_size(arabic, english, BLADE_FONT_SIZE, BLADE_SIZE.z - 0.2)
	var blade := SignText.make_two_faces(arabic, english, blade_font, TEXT_COLOUR, BLADE_SIZE.x)
	blade.name = "BladeSign"
	# Turned a quarter so the faces point along the wall, not out from it.
	blade.rotation.y = PI * 0.5
	blade.position = Vector3(blade_x, board_y, blade_z)
	add_child(blade)


func _add_box(size: Vector3, colour: Color, spot: Vector3) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = spot
	add_child(part)
