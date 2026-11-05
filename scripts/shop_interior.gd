class_name ShopInterior
extends RefCounted
## Walk-in rooms for Pedal Point and Dune Drip. Front entrance is local +Z.
## Looks pass Session 57: a glass front with sliding doors, a 5 m ceiling with hanging
## lamps, a tiled floor, plants and a bin, like the restaurants. Each shop's own things
## (hanging bikes, pegboard, tyre rack, repair stand / caps wall, rails, hoodies, mirror)
## are in scripts/shop_recipes.gd. COUNTER and PREVIEW stay where the shop screens
## (scripts/shop_controller.gd) expect them. Session 78: the outside (arcade, stepped roof,
## wind tower, window bays, bike rack or planters) is in scripts/shop_exterior.gd.

const COUNTER := Vector3(5, 0, -4)
const PREVIEW := Vector3(-1, 0, -1)
const CREAM := Color(0.9, 0.86, 0.76)
const WOOD := Color(0.43, 0.3, 0.18)
const TEAL := Color(0.1, 0.34, 0.39)
const SAND := Color(0.85, 0.55, 0.3)
const CEILING := 5.0
const GLASS_TOP := 3.6
const DOOR_HALF := 1.3


static func build(place: Dictionary) -> StaticBody3D:
	var room := StaticBody3D.new()
	room.name = "Shop_" + str(place["id"])
	room.position = place["position"]
	room.rotation_degrees.y = place["facing"]
	room.add_to_group("venue_shop")
	room.add_to_group("venue_room")  # the indoor camera comes closer in here
	room.set_meta("shop_id", place["id"])
	room.set_meta("counter", COUNTER)
	room.set_meta("walk_in", true)
	var bikes: bool = place["id"] == "bikes"
	var tint := TEAL if bikes else SAND
	var size: Vector3 = place.get("size", Vector3(20, 8, 18))
	var half := size * 0.5
	room.set_meta("room_rect", Rect2(-half.x, -half.z, size.x, size.z))
	room.set_meta("ceiling", CEILING)
	var motion := VenueMotion.new()  # the sliding doors
	motion.name = "Motion"
	room.add_child(motion)
	_solid(room, Vector3(size.x, 0.15, size.z), Vector3(0, -0.075, 0), Color(0.65, 0.58, 0.46))
	_solid(room, Vector3(size.x, size.y, 0.3), Vector3(0, half.y, -half.z), CREAM)
	for side in [-1, 1]:
		_solid(room, Vector3(0.3, size.y, size.z), Vector3(side * half.x, half.y, 0), CREAM)
		VenueParts.glass_run(room, Vector3(side * DOOR_HALF, 0, half.z), Vector3(side * half.x, 0, half.z), GLASS_TOP, 3.0)
	_solid(room, Vector3(size.x, size.y - GLASS_TOP, 0.3), Vector3(0, GLASS_TOP + (size.y - GLASS_TOP) * 0.5, half.z), tint)
	RoomProps.pane(room, Vector3(DOOR_HALF * 2, GLASS_TOP - RestaurantRoom.GLASS_TOP, 0.06),
			Vector3(0, (GLASS_TOP + RestaurantRoom.GLASS_TOP) * 0.5, half.z))
	LowPoly.box(room, Vector3(DOOR_HALF * 2 + 0.2, 0.1, 0.16), VenueParts.POST, Vector3(0, RestaurantRoom.GLASS_TOP, half.z + 0.01))
	RestaurantRoom.sliding_doors(room, half.z)
	# A real ceiling also tests the walking camera in enclosed spaces.
	_solid(room, Vector3(size.x, 0.2, size.z), Vector3(0, size.y + 0.1, 0), CREAM)
	LowPoly.box(room, Vector3(size.x - 0.4, 0.12, size.z - 0.4), Color(0.96, 0.95, 0.92), Vector3(0, CEILING + 0.06, 0))
	var floor_view := LowPoly.box(room, Vector3(size.x - 0.4, 0.06, size.z - 0.4), Color.WHITE, Vector3(0, 0.03, 0))
	floor_view.name = "TiledFloor"
	floor_view.material_override = RoomProps.floor_material(Color(0.6, 0.61, 0.62), Color(0.5, 0.51, 0.52), "plain", 1.0, Vector2(size.x, size.z)) if bikes \
			else RoomProps.floor_material(Color(0.72, 0.52, 0.33), Color(0.6, 0.42, 0.26), "planks", 0.8, Vector2(size.x, size.z))
	var board_y := GLASS_TOP + (size.y - GLASS_TOP) * 0.45
	LowPoly.box(room, Vector3(12, 1.6, 0.1), tint.darkened(0.3), Vector3(0, board_y, half.z + 0.2))
	var sign := SignText.make_face(place["arabic"], place["name"], 65, Color(1, 0.9, 0.65))
	sign.name = "BilingualSign"
	sign.position = Vector3(0, board_y, half.z + 0.27)
	room.add_child(sign)
	_solid(room, Vector3(4, 1.05, 1.2), COUNTER + Vector3(0, 0.525, -0.1), WOOD)
	LowPoly.box(room, Vector3(4.2, 0.06, 1.35), Color(0.85, 0.83, 0.8), COUNTER + Vector3(0, 1.08, -0.1))
	LowPoly.box(room, Vector3(0.5, 0.4, 0.35), Color(0.12, 0.14, 0.15), COUNTER + Vector3(-1, 1.31, 0))
	LowPoly.box(room, Vector3(0.36, 0.24, 0.04), Color(0.3, 0.8, 0.9), COUNTER + Vector3(-1, 1.45, 0.18))
	var staff := PeopleLooks.groom() if bikes else PeopleLooks.resident(2)
	if bikes:  # a mechanic's overalls
		staff.paint({"shirt": Color(0.2, 0.3, 0.45), "pants": Color(0.2, 0.3, 0.45)})
	staff.name = "Mechanic" if bikes else "Cashier"
	staff.position = COUNTER + Vector3(0, 0, -1.25)
	staff.rotation.y = PI
	room.add_child(staff)
	if bikes:
		ShopRecipes.bike_shop(room, half)
	else:
		ShopRecipes.clothes_shop(room, half)
	RoomProps.big_plant(room, Vector3(-half.x + 0.7, 0, half.z - 0.8))
	RoomProps.big_plant(room, Vector3(half.x - 0.7, 0, half.z - 0.8))
	RoomProps.bin(room, Vector3(COUNTER.x + 2.4, 0, COUNTER.z + 0.3))
	for spot in [Vector3(-5, 0, -4), Vector3(0, 0, -4), Vector3(5, 0, -1.5), Vector3(-5, 0, 3), Vector3(0, 0, 3), Vector3(5, 0, 4)]:
		RoomProps.pendant_lamp(room, spot, tint.darkened(0.2), CEILING)
	VenueParts.room_light(room, "InteriorLight", Vector3(0, CEILING - 0.7, 1.0), 1.6, 16.0, true)
	var hint := SignText.make_label("Hold E to shop", 32, Color(1, 0.85, 0.5), Color(0, 0, 0, 0), 0)
	hint.position = COUNTER + Vector3(0, 2.4, 0.1)
	room.add_child(hint)
	ShopExterior.dress(room, place, size, tint)  # Session 78: arcade, stepped roof, wind tower...
	Props.bake_kits(room)
	RestaurantRoom.draw_people_near(room)
	return room


static func _solid(room: StaticBody3D, size: Vector3, spot: Vector3, colour: Color) -> void:
	LowPoly.box(room, size, colour, spot)
	LowPoly.solid_box(room, size, spot)
