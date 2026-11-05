class_name RestaurantRoom
extends RefCounted
## The restaurant room template (looks pass, Session 54). The building outside keeps its
## old size (18 x 16 x 8 m); inside, the shop is a cosy room about 12 x 10 m with a 4.5 m
## ceiling at the front, and the rest of the building is a storeroom you can't enter.
##   Back:   the kitchen with a cook, and the menu board on the back wall
##   Middle: the counter with the staff member (CounterStaff), and the queue spots
##   Front:  tables with people eating, a drinks fridge, a bin, plants
## Big glass front with sliding glass doors, warm hanging lamps, tiled floor in the shop's
## colours and its own background sound. Each shop's own things come from its recipe
## (scripts/restaurant_recipes.gd). The front is local +Z, like every place.

const CREAM := Color(0.95, 0.9, 0.8)
const WOOD := Color(0.53, 0.33, 0.19)
const DARK := Color(0.12, 0.13, 0.14)
const CEILING_COLOUR := Color(0.96, 0.95, 0.92)

const ROOM_WIDTH := 12.0
const ROOM_DEPTH := 10.0
const CEILING := 4.5
const GLASS_TOP := 3.2           # the glass front goes up to here, a colour band above
const DOOR_HALF := 1.3           # the doorway is 2.6 m wide
const COUNTER_Z := 1.0           # the counter's middle (metres from the building's middle)
const COUNTER_HALF := 3.2        # the counter is 6.4 m long
## Where you stand to collect (in front of the counter, middle of the room).
const COUNTER_SPOT := Vector3(0, 0, 2.3)
## Where the 1 or 2 people in the queue stand (just left of you, one behind the other).
const QUEUE_SPOTS := [Vector3(-1.1, 0, 2.0), Vector3(-1.1, 0, 2.9)]
## Table spots (x, z). A recipe can use its own.
const TABLES := [Vector2(-4.0, 4.3), Vector2(4.0, 4.3), Vector2(-4.0, 6.7), Vector2(4.0, 6.7)]


## The room's inside, as (x from, z from, width, depth) in local metres.
static func room_rect(size: Vector3) -> Rect2:
	var front := size.z * 0.5
	return Rect2(-ROOM_WIDTH * 0.5, front - ROOM_DEPTH, ROOM_WIDTH, ROOM_DEPTH)


static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var kind: String = place.get("venue_type", "")
	var style: Dictionary = RestaurantStyles.style(kind)
	var tint: Color = style.get("tint", place.get("colour", Color(0.6, 0.3, 0.3)))
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", kind)
	body.set_meta("interior_style", "restaurant_room")
	body.set_meta("room_rect", room_rect(size))
	body.set_meta("ceiling", CEILING)
	body.set_meta("queue_spots", QUEUE_SPOTS)
	body.set_meta("counter_spot", counter_spot(kind))
	body.set_meta("queue_exit", Vector3(0.6, 0, size.z * 0.5 + 1.5))
	body.add_to_group("venue_room")
	var motion := VenueMotion.new()
	motion.name = "Motion"
	body.add_child(motion)
	shell(body, size, tint, style)
	outside(body, place, size, tint)
	var back := size.z * 0.5 - ROOM_DEPTH
	if not style.get("own_counter", false):
		counter(body, tint, style.get("counter_top", WOOD))
	staff(body, Vector3(0, 0, COUNTER_Z - 0.75), style.get("uniform", tint))
	var menu := RoomProps.menu_board(body, Vector3(0, 3.25, back + 0.2), style.get("menu", []), tint)
	menu.name = "MenuBoard"
	if not style.get("own_tables", false):
		for spot: Vector2 in TABLES:
			table(body, spot, style)
	RoomProps.drinks_fridge(body, Vector3(-ROOM_WIDTH * 0.5 + 0.45, 0, 2.4), 90.0)
	RoomProps.bin(body, Vector3(ROOM_WIDTH * 0.5 - 0.5, 0, 2.3))
	RoomProps.big_plant(body, Vector3(-ROOM_WIDTH * 0.5 + 0.55, 0, size.z * 0.5 - 0.6))
	RoomProps.big_plant(body, Vector3(ROOM_WIDTH * 0.5 - 0.55, 0, size.z * 0.5 - 0.6))
	lamps(body, style, tint)
	RestaurantRecipes.build(kind, body, size, tint, motion)
	sound(body, style.get("sound", ""))
	queue_people(body)
	Props.bake_kits(body)
	return body


## Walls, floor, ceiling, glass front, sliding doors and the storeroom walls.
static func shell(body: StaticBody3D, size: Vector3, tint: Color, style: Dictionary) -> void:
	var front := size.z * 0.5
	var half_x := size.x * 0.5
	var rx := ROOM_WIDTH * 0.5
	var back := front - ROOM_DEPTH
	var wall: Color = style.get("wall", CREAM)
	# The outside shell (same size as before): back, sides and roof.
	block(body, Vector3(size.x, size.y, 0.25), CREAM, Vector3(0, size.y * 0.5, -front))
	for side in [-1.0, 1.0]:
		block(body, Vector3(0.25, size.y, size.z), CREAM, Vector3(side * half_x, size.y * 0.5, 0))
		# Front corners beside the shop (the storeroom behind them).
		var corner := half_x - rx
		block(body, Vector3(corner, size.y, 0.25), CREAM, Vector3(side * (rx + corner * 0.5), size.y * 0.5, front))
	block(body, Vector3(size.x + 0.2, 0.25, size.z + 0.2), CREAM, Vector3(0, size.y + 0.12, 0))
	# The front above the glass: a band in the shop colour, then plain wall up to the roof.
	block(body, Vector3(ROOM_WIDTH, CEILING - GLASS_TOP, 0.25), tint, Vector3(0, (GLASS_TOP + CEILING) * 0.5, front))
	block(body, Vector3(ROOM_WIDTH, size.y - CEILING, 0.25), CREAM, Vector3(0, (CEILING + size.y) * 0.5, front))
	# Big glass front, solid, either side of the doorway, with dark posts.
	var wing := rx - DOOR_HALF
	for side in [-1.0, 1.0]:
		var at := Vector3(side * (DOOR_HALF + wing * 0.5), GLASS_TOP * 0.5, front)
		RoomProps.pane(body, Vector3(wing, GLASS_TOP, 0.06), at)
		LowPoly.solid_box(body, Vector3(wing, GLASS_TOP, 0.2), at)
		for x in [DOOR_HALF, DOOR_HALF + wing * 0.5, rx - 0.05]:
			LowPoly.box(body, Vector3(0.1, GLASS_TOP, 0.14), DARK, Vector3(side * x, GLASS_TOP * 0.5, front))
	LowPoly.box(body, Vector3(ROOM_WIDTH, 0.12, 0.16), DARK, Vector3(0, GLASS_TOP - 0.06, front + 0.01))
	sliding_doors(body, front)
	# Inside: side walls, back wall (the kitchen wall) and the ceiling. Behind them: storeroom.
	for side in [-1.0, 1.0]:
		block(body, Vector3(0.2, CEILING, ROOM_DEPTH), wall, Vector3(side * (rx + 0.1), CEILING * 0.5, back + ROOM_DEPTH * 0.5))
	block(body, Vector3(ROOM_WIDTH, CEILING, 0.2), wall, Vector3(0, CEILING * 0.5, back - 0.1))
	block(body, Vector3(ROOM_WIDTH, 0.15, ROOM_DEPTH), CEILING_COLOUR, Vector3(0, CEILING + 0.075, back + ROOM_DEPTH * 0.5))
	# A skirting stripe in the accent colour round the walls.
	var accent: Color = style.get("accent", tint)
	for side in [-1.0, 1.0]:
		LowPoly.box(body, Vector3(0.04, 0.18, ROOM_DEPTH - 0.2), accent, Vector3(side * (rx - 0.02), 0.09, back + ROOM_DEPTH * 0.5))
	LowPoly.box(body, Vector3(ROOM_WIDTH, 0.18, 0.04), accent, Vector3(0, 0.09, back + 0.02))
	# The tiled floor in the shop's own colours.
	var floor_view := LowPoly.box(body, Vector3(ROOM_WIDTH, 0.06, ROOM_DEPTH), Color.WHITE, Vector3(0, 0.03, back + ROOM_DEPTH * 0.5))
	floor_view.name = "TiledFloor"
	floor_view.material_override = RoomProps.floor_material(style.get("floor_a", Color.WHITE),
			style.get("floor_b", Color(0.15, 0.15, 0.15)), style.get("floor", "checker"),
			style.get("tile", 0.5), Vector2(ROOM_WIDTH, ROOM_DEPTH))
	# The storeroom floor (you never see it, but nothing should look hollow through a gap).
	LowPoly.box(body, Vector3(size.x, 0.05, size.z - ROOM_DEPTH), Color(0.6, 0.58, 0.55), Vector3(0, 0.025, -front + (size.z - ROOM_DEPTH) * 0.5))


## Two glass door panels that slide apart when someone walks up (scripts/venue_motion.gd).
static func sliding_doors(body: StaticBody3D, front: float) -> void:
	var doors := Node3D.new()
	doors.name = "SlidingDoor"
	doors.set_meta("static_batch_dynamic", true)
	doors.position = Vector3(0, 0, front + 0.12)
	body.add_child(doors)
	for side in [-1.0, 1.0]:
		var panel := Node3D.new()
		panel.name = "DoorLeft" if side < 0 else "DoorRight"
		panel.position.x = side * DOOR_HALF * 0.5
		panel.set_meta("closed_x", panel.position.x)
		panel.set_meta("open_x", side * DOOR_HALF * 1.45)
		doors.add_child(panel)
		RoomProps.pane(panel, Vector3(DOOR_HALF, GLASS_TOP - 0.15, 0.04), Vector3(0, (GLASS_TOP - 0.15) * 0.5, 0))
		LowPoly.box(panel, Vector3(0.06, GLASS_TOP - 0.15, 0.06), DARK, Vector3(side * DOOR_HALF * 0.5, (GLASS_TOP - 0.15) * 0.5, 0))
		LowPoly.box(panel, Vector3(0.04, 0.5, 0.08), Color(0.8, 0.8, 0.82), Vector3(-side * DOOR_HALF * 0.4, 1.1, 0.03))
	(body.get_node("Motion") as VenueMotion).doors = doors


## The sign, awning and benches outside (as before the looks pass).
static func outside(body: StaticBody3D, place: Dictionary, size: Vector3, tint: Color) -> void:
	var front := size.z * 0.5
	var board_y := 5.9
	LowPoly.box(body, Vector3(minf(size.x - 1, 14), 1.6, 0.16), tint.darkened(0.15), Vector3(0, board_y, front + 0.2))
	var sign := SignText.make_face(place.get("arabic", ""), place.get("name", ""), 46, Color.WHITE)
	sign.name = "BilingualSign"
	sign.position = Vector3(0, board_y, front + 0.3)
	body.add_child(sign)
	var awning := LowPoly.box(body, Vector3(ROOM_WIDTH + 0.5, 0.18, 2.0), tint, Vector3(0, GLASS_TOP + 0.35, front + 1.0))
	awning.rotation.x = 0.12
	for side in [-1.0, 1.0]:
		Props.bench(body, Vector3(side * 5.0, 0, front + 2.2), 180)


## The service counter in the shop colour with a wooden top, a till, and low walls from
## its ends to the side walls so the kitchen stays behind it.
static func counter(body: StaticBody3D, tint: Color, top: Color) -> void:
	block(body, Vector3(COUNTER_HALF * 2, 1.0, 0.8), tint, Vector3(0, 0.5, COUNTER_Z))
	LowPoly.box(body, Vector3(COUNTER_HALF * 2 + 0.1, 0.06, 0.95), top, Vector3(0, 1.03, COUNTER_Z + 0.05))
	var side := ROOM_WIDTH * 0.5 - COUNTER_HALF
	for x in [-1.0, 1.0]:
		block(body, Vector3(side, 1.0, 0.15), tint.darkened(0.2), Vector3(x * (COUNTER_HALF + side * 0.5), 0.5, COUNTER_Z - 0.3))
	# The till and a stack of orange delivery bags waiting.
	LowPoly.box(body, Vector3(0.4, 0.25, 0.3), DARK, Vector3(0.9, 1.19, COUNTER_Z))
	LowPoly.box(body, Vector3(0.3, 0.2, 0.05), Color(0.3, 0.8, 0.9), Vector3(0.9, 1.4, COUNTER_Z - 0.05))
	for i in 2:
		LowPoly.box(body, Vector3(0.3, 0.32, 0.22), Color(0.94, 0.57, 0.2), Vector3(-0.4 + i * 0.36, 1.22, COUNTER_Z + 0.05))


static func staff(body: StaticBody3D, spot: Vector3, shirt: Color) -> Person:
	var person := PeopleLooks.resident(2, 1)
	person.paint({"shirt": shirt.lightened(0.1)})
	person.name = "CounterStaff"
	person.position = spot
	person.rotation.y = PI  # faces the customers (+Z)
	body.add_child(person)
	return person


## A cook at a spot, facing the back wall (or "facing" in degrees). Moves while cooking.
static func cook(body: StaticBody3D, spot: Vector3, facing := 0.0, name := "Cook") -> Person:
	var person := PeopleLooks.resident(2, randi() % 4)
	person.paint({"shirt": Color(0.97, 0.97, 0.95), "pants": Color(0.15, 0.15, 0.17)})
	PeopleLooks.cap(person, Color(0.97, 0.97, 0.95), person)
	person.name = name
	person.position = spot
	person.rotation_degrees.y = facing
	body.add_child(person, true)
	(body.get_node("Motion") as VenueMotion).cooks.append(person)
	return person


## A round table, two chairs and (sometimes) people eating.
static func table(body: StaticBody3D, spot: Vector2, style: Dictionary) -> void:
	var at := Vector3(spot.x, 0, spot.y)
	Props.kit(style.get("table", "restaurant/table_round_A_small"), body, at, 0.0, 0.72)
	LowPoly.solid_cylinder(body, 0.55, 0.75, at + Vector3(0, 0.375, 0))
	var chair: String = style.get("chair", "restaurant/chair_A")
	var seat := 0.4
	var eaters: int = 1 if absf(spot.y - 4.3) < 0.1 else (2 if spot.x > 0 else 0)
	for side in [-1.0, 1.0]:
		Props.kit(chair, body, at + Vector3(side * 0.85, 0, 0), -90.0 * side, 0.68)
		var plate_at := at + Vector3(side * 0.3, 0.73, 0)
		Props.kit("restaurant/plate_small", body, plate_at, 0.0, 0.4)
		if side < 0 or eaters == 2:
			RestaurantRecipes.dish(style.get("dish", ""), body, plate_at + Vector3(0, 0.02, 0), style.get("dish_size", 0.3))
		if (side < 0 and eaters >= 1) or (side > 0 and eaters == 2):
			var diner := PeopleLooks.resident((int(spot.x) + int(spot.y * 3) + int(side)) & 7, -1)
			diner.name = "SeatedCustomer"
			diner.position = at + Vector3(side * 0.85, seat - 0.88, 0)
			diner.rotation_degrees.y = 90.0 * side   # faces the table
			body.add_child(diner, true)
			if diner.can_do("sit"):
				diner.play("sit")
			(body.get_node("Motion") as VenueMotion).diners.append(diner)


## Warm hanging lamps over the counter and the tables, two lights (one with soft shadows).
static func lamps(body: StaticBody3D, style: Dictionary, tint: Color) -> void:
	var shade: Color = style.get("lamp", tint.darkened(0.3))
	var spots: Array = style.get("lamp_spots", [Vector3(-1.8, 0, COUNTER_Z), Vector3(1.8, 0, COUNTER_Z)] + TABLES.map(func(t): return Vector3(t.x, 0, t.y)))
	for spot: Vector3 in spots:
		RoomProps.pendant_lamp(body, spot, shade, CEILING)
	var room := OmniLight3D.new()
	room.name = "InteriorLight"
	room.position = Vector3(0, CEILING - 0.6, 5.0)
	room.light_color = Color(1.0, 0.84, 0.62)
	room.light_energy = 1.7
	room.omni_range = 9.0
	room.shadow_enabled = true
	room.shadow_blur = 2.0          # soft shadows
	room.distance_fade_enabled = true
	room.distance_fade_begin = 40.0
	room.distance_fade_shadow = 18.0
	room.distance_fade_length = 10.0
	body.add_child(room)
	var kitchen := OmniLight3D.new()
	kitchen.name = "KitchenLight"
	kitchen.position = Vector3(0, CEILING - 0.5, -0.6)
	kitchen.light_color = Color(1.0, 0.9, 0.75)
	kitchen.light_energy = 1.3
	kitchen.omni_range = 7.0
	kitchen.distance_fade_enabled = true
	kitchen.distance_fade_begin = 40.0
	kitchen.distance_fade_length = 10.0
	body.add_child(kitchen)


## The place's own background sound, only heard inside and just outside the door.
static func sound(body: StaticBody3D, file: String) -> void:
	if file == "" or not ResourceLoader.exists("res://assets/audio/" + file):
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "RoomSound"
	var stream := load("res://assets/audio/" + file) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.bus = "Ambience"
	player.position = Vector3(0, 2.0, 3.0)
	player.unit_size = GameConfig.ROOM_SOUND_UNIT_SIZE
	player.max_distance = GameConfig.ROOM_SOUND_MAX_DISTANCE
	player.volume_db = GameConfig.ROOM_SOUND_DB
	player.autoplay = true
	body.add_child(player)
	body.set_meta("room_sound", file)


## Two people who sometimes wait at the counter before you (scripts/venue_queue.gd).
static func queue_people(body: StaticBody3D) -> void:
	for i in QUEUE_SPOTS.size():
		var person := PeopleLooks.resident((i * 3 + 1) % PeopleLooks.RESIDENT_OUTFITS)
		person.name = "QueuePerson%d" % (i + 1)
		person.position = QUEUE_SPOTS[i]
		person.visible = false
		person.process_mode = Node.PROCESS_MODE_DISABLED
		body.add_child(person)


## True if a world spot is inside a walk-in room (its "room_rect" metadata).
static func is_inside(place: Node3D, spot: Vector3) -> bool:
	if not place.has_meta("room_rect") or not place.is_inside_tree():
		return false
	var local := place.global_transform.affine_inverse() * spot
	return (place.get_meta("room_rect") as Rect2).has_point(Vector2(local.x, local.z)) and local.y < 3.0


## A coloured solid box.
static func block(body: StaticBody3D, size: Vector3, colour: Color, at: Vector3) -> MeshInstance3D:
	var view := LowPoly.box(body, size, colour, at)
	LowPoly.solid_box(body, size, at)
	return view


## Where you stand to collect in a venue type's room (the supermarket: at checkout 1).
static func counter_spot(kind: String) -> Vector3:
	return RestaurantStyles.style(kind).get("counter_spot", COUNTER_SPOT)
