extends StaticBody3D
## One villa: a house with a flat roof edge, two windows, an orange front door and a
## big house-number plate on the front wall. The front is the +Z side.
## PlaceBuilder places one of these (scenes/villa.tscn) for every villa in the data list
## and calls setup(). Later this can be swapped for a nicer CC0 model.

## A few wall colours, picked by house number so neighbours don't all look the same.
const WALL_COLOURS := [
	Color(1, 0.9529412, 0.87058824, 1),  # cream
	Color(0.9098039, 0.827451, 0.6509804, 1),  # sand
	Color(0.95, 0.85, 0.78, 1),  # light terracotta
	Color(0.97, 0.97, 0.95, 1),  # white
]
const ROOF_EDGE_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)  # teal
const DOOR_COLOUR := Color(0.9490196, 0.54901963, 0.15686275, 1)  # orange
const WINDOW_COLOUR := Color(0.11764706, 0.25, 0.3, 1)  # dark glass
const PLATE_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)  # teal plate
const NUMBER_COLOUR := Color(1, 1, 1, 1)

const DOOR_SIZE := Vector3(1.6, 2.4, 0.2)
const WINDOW_SIZE := Vector3(2.0, 1.4, 0.15)
const PLATE_SIZE := Vector3(2.4, 1.6, 0.15)
const PLATE_HEIGHT := 3.4        # metres up the front wall, above the door
const NUMBER_FONT_SIZE := 160    # big enough to read from about 25 m away
const ROOF_EDGE_HEIGHT := 0.5

## The house number shown on the plate.
var number := 0


## Builds the villa. size: width, height, depth in metres.
func setup(house_number: int, size: Vector3) -> void:
	number = house_number
	name = "Villa%d" % number
	var front := size.z * 0.5

	# Solid walls, so the bike bumps into the house.
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = size.y * 0.5
	add_child(shape)

	var wall_colour: Color = WALL_COLOURS[number % WALL_COLOURS.size()]
	_add_box(size, wall_colour, Vector3(0, size.y * 0.5, 0))
	# A teal band around the top, like a flat-roof parapet.
	var edge := Vector3(size.x + 0.3, ROOF_EDGE_HEIGHT, size.z + 0.3)
	_add_box(edge, ROOF_EDGE_COLOUR, Vector3(0, size.y + ROOF_EDGE_HEIGHT * 0.5, 0))
	# Front door in the middle, a window on each side.
	_add_box(DOOR_SIZE, DOOR_COLOUR, Vector3(0, DOOR_SIZE.y * 0.5, front + DOOR_SIZE.z * 0.5))
	var window_x := size.x * 0.3
	var window_y := 1.8
	_add_box(WINDOW_SIZE, WINDOW_COLOUR, Vector3(-window_x, window_y, front + WINDOW_SIZE.z * 0.5))
	_add_box(WINDOW_SIZE, WINDOW_COLOUR, Vector3(window_x, window_y, front + WINDOW_SIZE.z * 0.5))

	# House-number plate above the door, facing the street.
	_add_box(PLATE_SIZE, PLATE_COLOUR, Vector3(0, PLATE_HEIGHT, front + PLATE_SIZE.z * 0.5))
	var label := Label3D.new()
	label.text = str(number)
	label.font_size = NUMBER_FONT_SIZE
	label.modulate = NUMBER_COLOUR
	label.outline_size = 0
	label.position = Vector3(0, PLATE_HEIGHT, front + PLATE_SIZE.z + 0.02)
	add_child(label)


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
