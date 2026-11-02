class_name PlaceBuilder
extends Node3D
## Builds the restaurants and villas from the list in data/test_area_places.gd
## when the game starts, and tells other scripts where each front door is.
## Each building is a solid coloured box with an orange door and a big sign.
## Signs are English only for now: bilingual Arabic + English signs come in Session 5.

const RESTAURANT_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)  # teal
const VILLA_COLOUR := Color(1, 0.9529412, 0.87058824, 1)              # cream
const DOOR_COLOUR := Color(0.9490196, 0.54901963, 0.15686275, 1)      # orange
const SIGN_TEXT_COLOUR := Color(1, 0.9529412, 0.87058824, 1)          # cream
const SIGN_OUTLINE_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 1)  # dark teal
const DOOR_SIZE := Vector3(1.6, 2.4, 0.2)   # the orange door on the front of each building
const SIGN_LIFT := 1.2                      # metres above the roof
const RESTAURANT_SIGN_FONT_SIZE := 128
const VILLA_SIGN_FONT_SIZE := 320           # villa numbers are extra big, easy to read while riding
const SIGN_OUTLINE_SIZE := 32


func _ready() -> void:
	for place in TestAreaPlaces.RESTAURANTS:
		_build(place["position"], place["facing"], TestAreaPlaces.RESTAURANT_SIZE,
				RESTAURANT_COLOUR, place["name"], RESTAURANT_SIGN_FONT_SIZE)
	for place in TestAreaPlaces.VILLAS:
		_build(place["position"], place["facing"], TestAreaPlaces.VILLA_SIZE,
				VILLA_COLOUR, str(place["number"]), VILLA_SIGN_FONT_SIZE)


## The spot on the ground in front of a restaurant's door.
func restaurant_door(id: String) -> Vector3:
	for place in TestAreaPlaces.RESTAURANTS:
		if place["id"] == id:
			return door_point(place["position"], place["facing"], TestAreaPlaces.RESTAURANT_SIZE)
	push_error("No restaurant with id " + id)
	return Vector3.ZERO


## The spot on the ground in front of a villa's door.
func villa_door(number: int) -> Vector3:
	for place in TestAreaPlaces.VILLAS:
		if place["number"] == number:
			return door_point(place["position"], place["facing"], TestAreaPlaces.VILLA_SIZE)
	push_error("No villa number %d" % number)
	return Vector3.ZERO


## Works out the door spot: DOOR_DISTANCE metres in front of the building's front wall.
static func door_point(spot: Vector3, facing_deg: float, size: Vector3) -> Vector3:
	var angle := deg_to_rad(facing_deg)
	var front := Vector3(sin(angle), 0.0, cos(angle))
	return spot + front * (size.z * 0.5 + GameConfig.DOOR_DISTANCE)


func _build(spot: Vector3, facing_deg: float, size: Vector3, colour: Color,
		sign_text: String, font_size: int) -> void:
	var body := StaticBody3D.new()
	body.position = spot
	body.rotation_degrees.y = facing_deg
	add_child(body)

	# Solid walls, so the bike bumps into the building like into the boxes.
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = size.y * 0.5
	body.add_child(shape)

	body.add_child(_box_mesh(size, colour, Vector3(0.0, size.y * 0.5, 0.0)))
	# An orange door on the front (+Z side), so you can see where to ride up to.
	var door_spot := Vector3(0.0, DOOR_SIZE.y * 0.5, (size.z + DOOR_SIZE.z) * 0.5)
	body.add_child(_box_mesh(DOOR_SIZE, DOOR_COLOUR, door_spot))

	# Big sign above the front. It always turns to face the camera.
	var label := Label3D.new()
	label.text = sign_text
	label.font_size = font_size
	label.outline_size = SIGN_OUTLINE_SIZE
	label.modulate = SIGN_TEXT_COLOUR
	label.outline_modulate = SIGN_OUTLINE_COLOUR
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.double_sided = true
	label.position = Vector3(0.0, size.y + SIGN_LIFT, size.z * 0.5)
	body.add_child(label)


func _box_mesh(size: Vector3, colour: Color, offset: Vector3) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = offset
	return mesh_instance
