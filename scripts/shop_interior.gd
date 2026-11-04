class_name ShopInterior
extends RefCounted
## Walk-in rooms for Pedal Point and Dune Drip. Front entrance is local +Z.

const COUNTER := Vector3(5, 0, -4)
const PREVIEW := Vector3(-1, 0, -1)
const CREAM := Color(0.9, 0.86, 0.76)
const WOOD := Color(0.43, 0.3, 0.18)
const TEAL := Color(0.1, 0.34, 0.39)


static func build(place: Dictionary) -> StaticBody3D:
	var room := StaticBody3D.new()
	room.name = "Shop_" + str(place["id"])
	room.position = place["position"]
	room.rotation_degrees.y = place["facing"]
	room.add_to_group("venue_shop")
	room.set_meta("shop_id", place["id"])
	room.set_meta("counter", COUNTER)
	room.set_meta("walk_in", true)
	var size: Vector3 = place.get("size", Vector3(20, 8, 18))
	var half := size * 0.5
	_solid(room, Vector3(size.x, 0.15, size.z), Vector3(0, -0.075, 0), Color(0.65, 0.58, 0.46))
	_solid(room, Vector3(size.x, size.y, 0.3), Vector3(0, half.y, -half.z), CREAM)
	for side in [-1, 1]:
		_solid(room, Vector3(0.3, size.y, size.z), Vector3(side * half.x, half.y, 0), CREAM)
		var wide := half.x - 1.6
		_solid(room, Vector3(wide, size.y, 0.3), Vector3(side * (1.6 + wide * 0.5), half.y, half.z), TEAL)
	_solid(room, Vector3(3.2, size.y - 3.2, 0.3), Vector3(0, 3.2 + (size.y - 3.2) * 0.5, half.z), TEAL)
	# A real ceiling also tests the walking camera in enclosed spaces.
	_solid(room, Vector3(size.x, 0.2, size.z), Vector3(0, size.y + 0.1, 0), CREAM)
	var sign := SignText.make_face(place["arabic"], place["name"], 65, Color(1, 0.9, 0.65))
	sign.position = Vector3(0, 4.4, half.z + 0.18)
	room.add_child(sign)
	_solid(room, Vector3(4, 1.05, 1.2), COUNTER + Vector3(0, 0.525, -0.1), WOOD)
	LowPoly.box(room, Vector3(0.5, 0.4, 0.35), Color(0.12, 0.14, 0.15), COUNTER + Vector3(-1, 1.25, 0))
	var staff := PeopleLooks.groom() if place["id"] == "bikes" else PeopleLooks.resident(2)
	staff.name = "Mechanic" if place["id"] == "bikes" else "Cashier"
	staff.position = COUNTER + Vector3(0, 0, -1.25)
	staff.rotation.y = PI
	room.add_child(staff)
	if place["id"] == "bikes":
		_bikes(room, half)
	else:
		_clothes(room, half)
	var hint := SignText.make_label("Hold E to shop", 32, Color(1, 0.85, 0.5), Color(0, 0, 0, 0), 0)
	hint.position = COUNTER + Vector3(0, 2.4, 0.1)
	room.add_child(hint)
	return room


static func _bikes(room: StaticBody3D, half: Vector3) -> void:
	LowPoly.box(room, Vector3(7, 2.8, 0.12), Color(0.56, 0.57, 0.54), Vector3(4.8, 3.2, -half.z + 0.25))
	for x in range(1, 9):
		LowPoly.box(room, Vector3(0.06, 0.75, 0.08), Color(0.21, 0.24, 0.24), Vector3(x - 0.2, 3.5, -half.z + 0.4))
		LowPoly.box(room, Vector3(0.3, 0.12, 0.08), Color(0.32, 0.35, 0.36), Vector3(x - 0.2, 3.9, -half.z + 0.4))
	for z in [-5.5, 0.5, 5.5]:
		var bike := Node3D.new()
		BikeModel.build(bike)
		bike.get_node("Rider").free()
		bike.position = Vector3(-half.x + 0.6, 2.0, z)
		room.add_child(bike)
	# The rotating preview sits on an actual repair stand in the room.
	LowPoly.cylinder(room, 0.08, 0.08, 0.7, Color(0.3, 0.32, 0.32), PREVIEW + Vector3(0, 0.35, 0))
	LowPoly.box(room, Vector3(2.1, 0.08, 1.4), Color(0.3, 0.32, 0.32), PREVIEW + Vector3(0, 0.04, 0))
	room.set_meta("interior_style", "bike_workshop")


static func _clothes(room: StaticBody3D, half: Vector3) -> void:
	LowPoly.box(room, Vector3(4.2, 0.03, 4.2), Color(0.65, 0.25, 0.23), PREVIEW + Vector3(0, 0.025, 0))
	LowPoly.box(room, Vector3(0.16, 3.4, 4.2), WOOD, Vector3(-half.x + 0.4, 1.7, 0))
	LowPoly.box(room, Vector3(0.04, 3.1, 3.9), Color(0.63, 0.79, 0.81), Vector3(-half.x + 0.51, 1.7, 0))
	# Keep racks beside the rug; a rack across the camera-to-rider path obscures
	# the very clothes the player is trying on.
	for z in [-7.0, 4.0]:
		_solid(room, Vector3(5.5, 0.15, 1.2), Vector3(6.4, 0.1, z), WOOD)
		for x in [3.8, 9.0]:
			LowPoly.cylinder(room, 0.06, 0.06, 2.6, WOOD, Vector3(x, 1.3, z))
		LowPoly.box(room, Vector3(5.5, 0.08, 0.08), WOOD, Vector3(6.4, 2.6, z))
		for i in 6:
			var colour: Color = GearCatalog.COLOURS[i % 3]["colour"]
			LowPoly.box(room, Vector3(0.6, 1.0, 0.18), colour, Vector3(4.2 + i * 0.85, 1.85, z))
	for y in [1.1, 2.1, 3.1]:
		LowPoly.box(room, Vector3(5, 0.12, 0.8), WOOD, Vector3(2.3, y, -half.z + 0.6))
		for i in 5:
			LowPoly.sphere(room, 0.22, 0.2, GearCatalog.COLOURS[i % 3]["colour"], Vector3(0.5 + i * 0.85, y + 0.2, -half.z + 0.6))
	room.set_meta("interior_style", "clothes_mirror")


static func _solid(room: StaticBody3D, size: Vector3, spot: Vector3, colour: Color) -> void:
	LowPoly.box(room, size, colour, spot)
	LowPoly.solid_box(room, size, spot)
