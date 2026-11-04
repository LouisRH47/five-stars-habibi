class_name ShopInterior
extends RefCounted
## Walk-in rooms for Pedal Point and Dune Drip. Front entrance is local +Z.

## Session 57: moved for the smaller 12 x 10 m room in the shop rows (was (5, 0, -4)).
const COUNTER := Vector3(3, 0, -2.6)
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
	# Session 57: in the Plaza's shop rows (a "row" in the data) the shop gets the same
	# low glass front, logo sign band and awning as the restaurants (ShopFront).
	var plaza_front: bool = GameConfig.PLAZA_LOOKS_PASS and place.has("row")
	var shared := InteriorRoom.shared_sides(place, size) if GameConfig.INTERIOR_REVIEW_FIXES and plaza_front else []
	for side in [-1, 1]:
		if float(side) in shared:
			# Review fix: Pedal Point's left wall filled the same space as Bread & Zaatar's right
			# wall next door; now it stops at the edge (inner face where it was).
			_solid(room, Vector3(0.15, size.y, size.z), Vector3(side * (half.x - 0.075), half.y, 0), CREAM)
		else:
			_solid(room, Vector3(0.3, size.y, size.z), Vector3(side * half.x, half.y, 0), CREAM)
		if plaza_front:
			continue
		var wide := half.x - 1.6
		_solid(room, Vector3(wide, size.y, 0.3), Vector3(side * (1.6 + wide * 0.5), half.y, half.z), TEAL)
	if not plaza_front:
		_solid(room, Vector3(3.2, size.y - 3.2, 0.3), Vector3(0, 3.2 + (size.y - 3.2) * 0.5, half.z), TEAL)
	# A real ceiling also tests the walking camera in enclosed spaces.
	_solid(room, Vector3(size.x, 0.2, size.z), Vector3(0, size.y + 0.1, 0), CREAM)
	if plaza_front:
		ShopFront.build(room, place, size)
	if plaza_front and not GameConfig.INTERIORS_LOOKS_PASS:
		var lamp := OmniLight3D.new()
		lamp.name = "InteriorLight"
		lamp.position = Vector3(0, size.y - 0.6, 0)
		lamp.light_color = Color(1.0, 0.9, 0.75)
		lamp.light_energy = 1.6
		lamp.omni_range = 10.0
		room.add_child(lamp)
	else:
		var sign := SignText.make_face(place["arabic"], place["name"], 65, Color(1, 0.9, 0.65))
		sign.position = Vector3(0, 4.4, half.z + 0.18)
		room.add_child(sign)
	_solid(room, Vector3(4, 1.05, 1.2), COUNTER + Vector3(0, 0.525, -0.1), WOOD)
	var looks := plaza_front and GameConfig.INTERIORS_LOOKS_PASS
	if not looks:   # Session 59: the new rooms have a real till (ShopRooms) instead of this box
		LowPoly.box(room, Vector3(0.5, 0.4, 0.35), Color(0.12, 0.14, 0.15), COUNTER + Vector3(-1, 1.25, 0))
	var staff := PeopleLooks.groom() if place["id"] == "bikes" else PeopleLooks.resident(2)
	staff.name = "Mechanic" if place["id"] == "bikes" else "Cashier"
	staff.position = COUNTER + Vector3(0, 0, -1.25)
	staff.rotation.y = PI
	room.add_child(staff)
	if looks:
		# Session 59: the insides rebuilt for the 12 x 10 m room (ShopRooms); the old
		# _bikes() and _clothes() below are kept for the old layout and the test area.
		room.set_meta("interior_looks", true)
		room.set_meta("room_size", size)
		room.set_meta("pickup", COUNTER + Vector3(0, 0, 1.0))
		var parts := InteriorParts.new(room, place.merged({"colour": place.get("colour", TEAL)}), size)
		if place["id"] == "bikes":
			ShopRooms.bikes(parts)
		else:
			ShopRooms.clothes(parts)
		parts.finish()
	elif place["id"] == "bikes":
		_bikes(room, half)
	else:
		_clothes(room, half)
	var hint := SignText.make_label("Hold E to shop", 32, Color(1, 0.85, 0.5), Color(0, 0, 0, 0), 0)
	hint.position = COUNTER + Vector3(0, 2.4, 0.1)
	room.add_child(hint)
	return room


static func _bikes(room: StaticBody3D, half: Vector3) -> void:
	# Session 57: the pegboard and hanging bikes fit the room (it was 20 x 18 m, now 12 x 10 m).
	var board_width := minf(7.0, half.x - 0.6)
	var board_x := half.x - 0.4 - board_width * 0.5
	LowPoly.box(room, Vector3(board_width, 2.5, 0.12), Color(0.56, 0.57, 0.54), Vector3(board_x, 2.9, -half.z + 0.25))
	for k in int(board_width):
		var x := board_x - board_width * 0.5 + 0.6 + k
		LowPoly.box(room, Vector3(0.06, 0.75, 0.08), Color(0.21, 0.24, 0.24), Vector3(x, 3.2, -half.z + 0.4))
		LowPoly.box(room, Vector3(0.3, 0.12, 0.08), Color(0.32, 0.35, 0.36), Vector3(x, 3.6, -half.z + 0.4))
	for z in [-half.z * 0.6, 0.0, half.z * 0.6]:
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
	# Session 57: racks and shelves sized for the 12 x 10 m room (the old room was 20 x 18 m).
	var rack := minf(5.5, half.x - 3.0)   # keeps clear of the shop camera at x = 1
	var rack_x := half.x - 0.8 - rack * 0.5
	for z in ([-7.0, 4.0] if half.z > 7.0 else [1.0, 3.2]):
		_solid(room, Vector3(rack, 0.15, 1.2), Vector3(rack_x, 0.1, z), WOOD)
		for x in [rack_x - rack * 0.5 + 0.3, rack_x + rack * 0.5 - 0.3]:
			LowPoly.cylinder(room, 0.06, 0.06, 2.6, WOOD, Vector3(x, 1.3, z))
		LowPoly.box(room, Vector3(rack, 0.08, 0.08), WOOD, Vector3(rack_x, 2.6, z))
		for i in int(rack / 0.85):
			var colour: Color = GearCatalog.COLOURS[i % 3]["colour"]
			LowPoly.box(room, Vector3(0.6, 1.0, 0.18), colour, Vector3(rack_x - rack * 0.5 + 0.55 + i * 0.85, 1.85, z))
	var shelf_x := 2.3 if half.x > 7.0 else -2.4
	for y in [1.1, 2.1, 3.1]:
		LowPoly.box(room, Vector3(minf(5.0, half.x - 2.5), 0.12, 0.8), WOOD, Vector3(shelf_x, y, -half.z + 0.6))
		for i in 4:
			LowPoly.sphere(room, 0.22, 0.2, GearCatalog.COLOURS[i % 3]["colour"], Vector3(shelf_x - 1.3 + i * 0.85, y + 0.2, -half.z + 0.6))
	room.set_meta("interior_style", "clothes_mirror")


static func _solid(room: StaticBody3D, size: Vector3, spot: Vector3, colour: Color) -> void:
	LowPoly.box(room, size, colour, spot)
	LowPoly.solid_box(room, size, spot)
