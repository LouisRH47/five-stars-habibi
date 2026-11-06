class_name RestaurantRecipes
## What makes each restaurant room different (looks pass, from the approved designs):
##   1000 Pizza: brick dome oven with flames, pizza on a peel, stacked pizza boxes, red accents
##   Brain Freeze Gelato: glass freezer of 8 colourful tubs, cone jar, pink-and-white stripes
##   Spill the Tea: 4 tea taps, cup sealing machine, cups with pearls, plant wall
##   Shawarma Supreme: two spinning shawarma grills, stack of bread, Arabic patterned tiles
##   Bread & Zaatar: bread oven, glass cake display, bread baskets
## The room itself (walls, counter, tables, lamps) is scripts/restaurant_room.gd.
## Local coordinates: front +Z; the kitchen is between the back wall and the counter.

const BRICK := Color(0.66, 0.3, 0.2)
const STEEL := Color(0.72, 0.74, 0.76)
const DARK := Color(0.1, 0.1, 0.11)
const DOUGH := Color(0.93, 0.78, 0.5)
const SAUCE := Color(0.8, 0.18, 0.1)
const CHEESE := Color(1.0, 0.9, 0.55)
const CREAM := Color(0.98, 0.95, 0.88)
const SCOOPS := [Color(1.0, 0.72, 0.8), Color(0.98, 0.96, 0.85), Color(0.45, 0.27, 0.16), Color(0.7, 0.9, 0.6),
		Color(1.0, 0.65, 0.3), Color(0.75, 0.6, 0.9), Color(0.95, 0.35, 0.4), Color(0.98, 0.9, 0.4)]
const COUNTER_TOP := RestaurantRoom.COUNTER_Z
const TOP_Y := 1.06   # the counter top


static func build(kind: String, body: StaticBody3D, size: Vector3, tint: Color, motion: VenueMotion) -> void:
	var back := size.z * 0.5 - RestaurantRoom.ROOM_DEPTH
	match kind:
		"pizza":
			pizza(body, back, tint, motion)
		"gelato":
			gelato(body, back, tint, motion)
		"boba":
			boba(body, back, tint, motion)
		"shawarma":
			shawarma(body, back, tint, motion)
		"bakery":
			bakery(body, back, tint, motion)
		_:
			RestaurantRecipesMore.build(kind, body, back, tint, motion)


# ---------------- Shared bits ----------------

## Kit kitchen counters along the back wall, one per x (each 1.8 m wide). Solid.
static func back_counters(body: StaticBody3D, xs: Array, back: float, models := ["restaurant/kitchencounter_straight_A_backsplash"]) -> void:
	for i in xs.size():
		var at := Vector3(xs[i], 0, back + 0.48)
		Props.kit(models[i % models.size()], body, at, 0.0, Vector3(0.9, 0.95, 0.45))
		LowPoly.solid_box(body, Vector3(1.8, 0.95, 0.9), at + Vector3(0, 0.475, 0))


## A flickering flame (orange outside, yellow inside).
static func flame(parent: Node3D, spot: Vector3, motion: VenueMotion, size := 1.0) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Flame"
	holder.position = spot
	holder.set_meta("static_batch_dynamic", true)
	parent.add_child(holder, true)
	var outer := LowPoly.cylinder(holder, 0.0, 0.14 * size, 0.4 * size, Color(1.0, 0.45, 0.1), Vector3(0, 0.2 * size, 0))
	var inner := LowPoly.cylinder(holder, 0.0, 0.08 * size, 0.26 * size, Color(1.0, 0.85, 0.3), Vector3(0, 0.13 * size, 0.02))
	for part in [outer, inner]:
		var glow := StandardMaterial3D.new()
		glow.albedo_color = part.mesh.material.albedo_color
		glow.emission_enabled = true
		glow.emission = glow.albedo_color
		glow.emission_energy_multiplier = 2.5
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		part.material_override = glow
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	motion.flames.append(holder)
	return holder


## A glowing strip (heater, oven window). Not batched (it glows).
static func glow_box(parent: Node3D, size: Vector3, colour: Color, spot: Vector3, energy := 2.0) -> MeshInstance3D:
	var view := LowPoly.box(parent, size, colour, spot)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = colour
	glow.emission_enabled = true
	glow.emission = colour
	glow.emission_energy_multiplier = energy
	view.material_override = glow
	return view


## A glass display case on the counter, w wide. Returns the floor height inside.
static func display_case(body: StaticBody3D, x: float, w: float, shelves := 1) -> float:
	var z := COUNTER_TOP
	LowPoly.box(body, Vector3(w, 0.06, 0.7), STEEL, Vector3(x, TOP_Y + 0.03, z))
	RoomProps.pane(body, Vector3(w, 0.5, 0.03), Vector3(x, TOP_Y + 0.3, z + 0.34))
	RoomProps.pane(body, Vector3(w, 0.03, 0.7), Vector3(x, TOP_Y + 0.56, z))
	for side in [-1.0, 1.0]:
		RoomProps.pane(body, Vector3(0.03, 0.5, 0.7), Vector3(x + side * w * 0.5, TOP_Y + 0.3, z))
	if shelves > 1:
		RoomProps.pane(body, Vector3(w, 0.02, 0.6), Vector3(x, TOP_Y + 0.3, z))
	return TOP_Y + 0.06


## Food on a table plate (or anywhere): "code:pizza" etc. are built here, other names are kit models.
static func dish(name: String, parent: Node3D, spot: Vector3, size := 0.3) -> void:
	match name:
		"":
			return
		"code:pizza":
			LowPoly.cylinder(parent, 0.17, 0.17, 0.025, DOUGH, spot + Vector3(0, 0.02, 0))
			LowPoly.cylinder(parent, 0.14, 0.14, 0.012, SAUCE, spot + Vector3(0, 0.036, 0))
			for i in 4:
				LowPoly.sphere(parent, 0.03, 0.02, CHEESE, spot + Vector3(cos(i * 1.6) * 0.08, 0.044, sin(i * 1.6) * 0.08))
		"code:sundae":
			LowPoly.cylinder(parent, 0.07, 0.04, 0.1, Color(0.9, 0.95, 1.0), spot + Vector3(0, 0.05, 0))
			LowPoly.sphere(parent, 0.06, 0.1, SCOOPS[int(absf(spot.x * 7 + spot.z * 3)) % SCOOPS.size()], spot + Vector3(0, 0.12, 0))
		"code:boba":
			boba_cup(parent, spot, Color(0.78, 0.6, 0.45))
		"code:wrap":
			var wrap := LowPoly.cylinder(parent, 0.04, 0.04, 0.22, CREAM, spot + Vector3(0, 0.05, 0))
			wrap.rotation.z = PI * 0.5
			LowPoly.box(parent, Vector3(0.08, 0.09, 0.09), Color(0.85, 0.82, 0.75), spot + Vector3(-0.08, 0.05, 0))
		"code:cake":
			LowPoly.cylinder(parent, 0.09, 0.09, 0.09, Color(0.98, 0.85, 0.88), spot + Vector3(0, 0.045, 0))
			LowPoly.sphere(parent, 0.025, 0.05, Color(0.85, 0.1, 0.2), spot + Vector3(0, 0.1, 0))
		"code:taco":
			for i in 2:
				var shell := LowPoly.cylinder(parent, 0.07, 0.07, 0.04, Color(0.95, 0.78, 0.4), spot + Vector3(-0.05 + i * 0.1, 0.06, 0))
				shell.rotation.x = PI * 0.5
				LowPoly.box(parent, Vector3(0.03, 0.03, 0.06), Color(0.3, 0.6, 0.25), spot + Vector3(-0.05 + i * 0.1, 0.1, 0))
		"code:sushi":
			for i in 3:
				LowPoly.box(parent, Vector3(0.05, 0.04, 0.09), CREAM, spot + Vector3(-0.07 + i * 0.07, 0.03, 0))
				LowPoly.box(parent, Vector3(0.055, 0.015, 0.1), Color(1.0, 0.55, 0.4), spot + Vector3(-0.07 + i * 0.07, 0.055, 0))
		_:
			Props.kit(name, parent, spot, 0.0, size)


## A see-through cup of bubble tea with dark pearls and a straw.
static func boba_cup(parent: Node3D, spot: Vector3, tea: Color) -> void:
	LowPoly.cylinder(parent, 0.045, 0.038, 0.14, tea, spot + Vector3(0, 0.07, 0))
	for i in 3:
		LowPoly.sphere(parent, 0.012, 0.024, DARK, spot + Vector3(-0.015 + i * 0.015, 0.02, 0.03))
	LowPoly.cylinder(parent, 0.008, 0.008, 0.12, Color(0.95, 0.3, 0.4), spot + Vector3(0.01, 0.18, 0))


# ---------------- 1000 Pizza ----------------

static func pizza(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "brick dome oven")
	# The brick dome oven in the back-left corner, with flames inside and a chimney.
	var oven := Vector3(-3.7, 0, back + 1.0)
	RestaurantRoom.block(body, Vector3(2.6, 0.9, 1.9), BRICK.darkened(0.15), oven + Vector3(0, 0.45, 0))
	var dome := LowPoly.sphere(body, 1.15, 1.8, BRICK, oven + Vector3(0, 1.1, 0))
	dome.name = "BrickOven"
	for i in 6:  # brick lines round the dome
		LowPoly.cylinder(body, 1.02 - i * 0.1, 1.02 - i * 0.1, 0.03, BRICK.darkened(0.3), oven + Vector3(0, 1.2 + i * 0.14, 0))
	LowPoly.box(body, Vector3(0.95, 0.6, 0.3), DARK, oven + Vector3(0, 1.2, 0.85))
	LowPoly.box(body, Vector3(1.15, 0.12, 0.34), BRICK.darkened(0.35), oven + Vector3(0, 1.55, 0.86))
	for i in 3:
		flame(body, oven + Vector3(-0.25 + i * 0.25, 0.92, 0.7), motion, 1.0 + (i % 2) * 0.3)
	# Session 90: the flue starts inside the top of the dome and goes up into the ceiling,
	# with a collar where it meets the dome and a plate where it meets the ceiling.
	var flue_bottom := 1.85
	var flue_top := RestaurantRoom.CEILING + 0.08
	var flue := LowPoly.cylinder(body, 0.22, 0.22, flue_top - flue_bottom, Color(0.3, 0.3, 0.32),
			oven + Vector3(0, (flue_top + flue_bottom) * 0.5, -0.2))
	flue.name = "OvenFlue"
	LowPoly.cylinder(body, 0.3, 0.36, 0.14, BRICK.darkened(0.3), oven + Vector3(0, 1.96, -0.2))
	LowPoly.cylinder(body, 0.34, 0.34, 0.05, Color(0.3, 0.3, 0.32), oven + Vector3(0, RestaurantRoom.CEILING - 0.035, -0.2))
	# Logs stacked beside it.
	for i in 4:
		var wood := LowPoly.cylinder(body, 0.07, 0.07, 0.5, Color(0.45, 0.3, 0.18), Vector3(-5.6, 0.08 + (i / 2) * 0.14, back + 0.4 + (i % 2) * 0.16))
		wood.rotation.z = PI * 0.5
	# The pizza peel with a pizza, leaning on the counter by the oven.
	var peel := Node3D.new()
	peel.position = Vector3(-2.1, 0, COUNTER_TOP - 0.5)
	peel.rotation.x = -0.35
	body.add_child(peel)
	LowPoly.box(peel, Vector3(0.05, 1.6, 0.05), Color(0.6, 0.45, 0.28), Vector3(0, 0.8, 0))
	LowPoly.box(peel, Vector3(0.45, 0.45, 0.02), Color(0.7, 0.55, 0.35), Vector3(0, 1.75, 0))
	# Kitchen counters, the dough table and a cook at the oven.
	back_counters(body, [0.3, 2.1, 3.9], back, ["restaurant/kitchencounter_straight_decorated",
			"restaurant/kitchencounter_straight_A_backsplash", "restaurant/kitchencounter_sink_backsplash"])
	for i in 2:
		dish("code:pizza", body, Vector3(2.0 + i * 0.4, 0.95, back + 0.55), 1.0)
	Props.kit("restaurant/crate_tomatoes", body, Vector3(5.3, 0, back + 0.45), 0.0, 0.42)
	Props.kit("restaurant/crate_cheese", body, Vector3(5.3, 0.4, back + 0.45), 15.0, 0.4)
	RestaurantRoom.cook(body, Vector3(-3.7, 0, 0.1), 0.0)
	# Stacked pizza boxes on the counter (white with a red stripe) and a ready pizza.
	for stack in 2:
		for i in 5 + stack * 2:
			var at := Vector3(2.1 + stack * 0.55, TOP_Y + 0.035 + i * 0.065, COUNTER_TOP - 0.05)
			LowPoly.box(body, Vector3(0.45, 0.06, 0.45), CREAM, at)
			LowPoly.box(body, Vector3(0.46, 0.015, 0.1), tint, at + Vector3(0, 0.03, 0))
	dish("code:pizza", body, Vector3(-1.6, TOP_Y, COUNTER_TOP), 1.0)
	# Red accents: a red band round the room and red-and-white table cloths.
	for side in [-1.0, 1.0]:
		LowPoly.box(body, Vector3(0.03, 0.25, 9.6), tint, Vector3(side * 5.98, 2.4, back + 5.0))
	LowPoly.box(body, Vector3(11.9, 0.25, 0.03), tint, Vector3(0, 2.4, back + 0.02))
	for spot: Vector2 in RestaurantRoom.TABLES:
		for i in 4:
			LowPoly.box(body, Vector3(0.18, 0.006, 0.9), tint if i % 2 == 0 else CREAM, Vector3(spot.x - 0.27 + i * 0.18, 0.724, spot.y))


# ---------------- Brain Freeze Gelato ----------------

static func gelato(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "glass freezer of 8 tubs")
	# Pink-and-white stripes on the walls.
	for i in 20:
		LowPoly.box(body, Vector3(0.3, 4.4, 0.02), tint.lightened(0.25), Vector3(-5.7 + i * 0.6, 2.2, back + 0.015))
	for side in [-1.0, 1.0]:
		for i in 16:
			LowPoly.box(body, Vector3(0.02, 4.4, 0.3), tint.lightened(0.25), Vector3(side * 5.985, 2.2, back + 0.3 + i * 0.6))
	# The glass freezer on the counter: 8 tubs of gelato, each with a scoop on top.
	var floor_y := display_case(body, -1.6, 2.8)
	var freezer := Node3D.new()
	freezer.name = "GelatoFreezer"
	body.add_child(freezer)
	for i in 8:
		var at := Vector3(-2.75 + (i % 4) * 0.76, floor_y, COUNTER_TOP - 0.15 + (i / 4) * 0.3)
		LowPoly.box(freezer, Vector3(0.32, 0.12, 0.24), STEEL, at + Vector3(0, 0.06, 0))
		LowPoly.sphere(freezer, 0.14, 0.14, SCOOPS[i], at + Vector3(0, 0.14, 0))
	# The cone jar.
	RoomProps.pane(body, Vector3(0.3, 0.4, 0.3), Vector3(0.4, TOP_Y + 0.2, COUNTER_TOP))
	for i in 5:
		LowPoly.cylinder(body, 0.05, 0.0, 0.25, Color(0.85, 0.62, 0.3), Vector3(0.33 + (i % 3) * 0.06, TOP_Y + 0.2 + (i / 3) * 0.08, COUNTER_TOP - 0.05 + (i % 2) * 0.1))
	# The back: a milkshake machine, kit fridge and counters, and the gelato maker.
	back_counters(body, [-3.6, -1.8, 0.0, 1.8], back)
	Props.kit("restaurant/fridge_A", body, Vector3(4.4, 0, back + 0.5), 0.0, 0.62)
	LowPoly.solid_box(body, Vector3(1.5, 2.1, 1.0), Vector3(4.4, 1.05, back + 0.5))
	for i in 3:
		LowPoly.box(body, Vector3(0.3, 0.5, 0.3), STEEL, Vector3(-1.0 + i * 0.4, 1.2, back + 0.45))
		LowPoly.cylinder(body, 0.08, 0.06, 0.2, SCOOPS[i + 3], Vector3(-1.0 + i * 0.4, 1.05, back + 0.62))
	for i in 6:
		LowPoly.box(body, Vector3(0.2, 0.2, 0.2), SCOOPS[i].darkened(0.1), Vector3(-4.2 + i * 0.25, 1.06, back + 0.4))
	RestaurantRoom.cook(body, Vector3(-0.6, 0, 0.0), 0.0, "Cook")
	# Pastel cushions on the chairs feel: little pink pots with flowers on each table.
	for spot: Vector2 in RestaurantRoom.TABLES:
		LowPoly.cylinder(body, 0.05, 0.04, 0.1, tint, Vector3(spot.x, 0.78, spot.y))
		LowPoly.sphere(body, 0.06, 0.1, Color(1, 0.95, 0.5), Vector3(spot.x, 0.88, spot.y))


# ---------------- Spill the Tea ----------------

static func boba(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "4 tea taps and a plant wall")
	back_counters(body, [-3.6, -1.8, 0.0, 1.8, 3.6], back)
	# Four tea taps: tall urns of different teas with a tap each.
	var teas := [Color(0.55, 0.32, 0.18), Color(0.62, 0.48, 0.75), Color(0.45, 0.62, 0.3), Color(0.95, 0.6, 0.2)]
	for i in 4:
		var at := Vector3(-3.9 + i * 1.0, 0.95, back + 0.45)
		LowPoly.cylinder(body, 0.22, 0.22, 0.75, STEEL, at + Vector3(0, 0.38, 0))
		LowPoly.cylinder(body, 0.18, 0.18, 0.4, teas[i], at + Vector3(0, 0.45, 0.06))
		LowPoly.box(body, Vector3(0.06, 0.06, 0.18), DARK, at + Vector3(0, 0.15, 0.25))
		var label := SignText.make_label(["Black", "Taro", "Green", "Mango"][i], 14, Color.WHITE, DARK, 4)
		label.position = at + Vector3(0, 0.85, 0.24)
		body.add_child(label)
	# Shaker cups and syrup bottles on the back counter.
	for i in 6:
		LowPoly.cylinder(body, 0.05, 0.05, 0.28, [Color(0.9, 0.3, 0.3), Color(0.95, 0.75, 0.2), Color(0.4, 0.75, 0.4)][i % 3], Vector3(0.6 + i * 0.25, 1.09, back + 0.35))
	# The cup sealing machine on the counter, with a cup under it.
	var sealer := Vector3(2.3, TOP_Y, COUNTER_TOP - 0.1)
	LowPoly.box(body, Vector3(0.36, 0.55, 0.4), Color(0.92, 0.92, 0.93), sealer + Vector3(0, 0.275, 0))
	LowPoly.box(body, Vector3(0.3, 0.1, 0.05), Color(0.3, 0.75, 0.9), sealer + Vector3(0, 0.45, 0.2))
	boba_cup(body, sealer + Vector3(0, 0.0, 0.12), teas[1])
	# A row of finished cups with pearls, waiting to go.
	for i in 4:
		boba_cup(body, Vector3(-2.6 + i * 0.22, TOP_Y, COUNTER_TOP + 0.15), teas[i])
	# The plant wall on the right: a wooden frame covered in leaves.
	var wall_x := 5.9
	LowPoly.box(body, Vector3(0.06, 3.2, 5.0), Color(0.45, 0.32, 0.2), Vector3(wall_x, 2.1, 5.2))
	for i in 60:
		var z := 2.9 + (i % 10) * 0.48
		var y := 0.7 + (i / 10) * 0.55 + (i % 3) * 0.08
		LowPoly.sphere(body, 0.24, 0.3, RoomProps.LEAF.lightened(0.05 * (i % 4)).darkened(0.04 * (i % 3)), Vector3(wall_x - 0.1, y, z))
	var neon := SignText.make_label("spill the tea", 40, Color(1, 0.75, 0.9), Color(0.9, 0.3, 0.6), 10)
	neon.position = Vector3(wall_x - 0.25, 3.4, 5.2)
	neon.rotation.y = -PI * 0.5
	body.add_child(neon)
	RestaurantRoom.cook(body, Vector3(-2.4, 0, -0.2), 0.0, "Cook")
	for i in 3:
		Props.kit("furniture/cactus_small_A" if i % 2 == 0 else "furniture/cactus_small_B", body, Vector3(-4.5 + i * 0.5, TOP_Y, COUNTER_TOP + 0.1), 0.0, 0.5)


# ---------------- Shawarma Supreme ----------------

static func shawarma(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "two spinning shawarma grills")
	# Arabic patterned tiles on the lower walls.
	var tiles := RoomProps.floor_material(Color(0.95, 0.9, 0.8), tint, "star", 0.3, Vector2(12, 1.4))
	var band := LowPoly.box(body, Vector3(11.9, 1.4, 0.02), Color.WHITE, Vector3(0, 0.7, back + 0.015))
	band.material_override = tiles
	for side in [-1.0, 1.0]:
		var side_band := LowPoly.box(body, Vector3(0.02, 1.4, 9.8), Color.WHITE, Vector3(side * 5.985, 0.7, back + 5.0))
		side_band.material_override = RoomProps.floor_material(Color(0.95, 0.9, 0.8), tint, "star", 0.3, Vector2(9.8, 1.4))
	# Two shawarma grills: a glowing heater behind a meat cone that spins.
	var spits: Array[Node3D] = []
	for i in 2:
		var at := Vector3(-2.6 + i * 1.5, 0, back + 0.9)
		RestaurantRoom.block(body, Vector3(1.0, 0.95, 0.9), STEEL, at + Vector3(0, 0.475, 0))
		LowPoly.box(body, Vector3(0.9, 1.4, 0.1), DARK, at + Vector3(0, 1.75, -0.4))
		glow_box(body, Vector3(0.7, 1.1, 0.03), Color(1.0, 0.45, 0.15), at + Vector3(0, 1.75, -0.34), 2.5)
		LowPoly.cylinder(body, 0.025, 0.025, 1.6, STEEL, at + Vector3(0, 1.75, 0))
		var spit := Node3D.new()
		spit.name = "ShawarmaSpit%d" % (i + 1)
		spit.position = at + Vector3(0, 1.7, 0)
		spit.set_meta("static_batch_dynamic", true)
		body.add_child(spit)
		LowPoly.cylinder(spit, 0.24, 0.36, 1.0, Color(0.6, 0.33, 0.15), Vector3.ZERO)
		for k in 6:  # crispy brown edges, so you can see it turn
			LowPoly.box(spit, Vector3(0.08, 0.9, 0.08), Color(0.42, 0.22, 0.1), Vector3(cos(k) * 0.3, 0, sin(k) * 0.3))
		spits.append(spit)
	motion.spits = spits
	back_counters(body, [1.4, 3.2], back, ["restaurant/kitchencounter_straight_decorated", "restaurant/stove_single"])
	Props.kit("restaurant/crate_lettuce", body, Vector3(4.9, 0.95, back + 0.4), 0.0, 0.3)
	Props.kit("restaurant/crate_tomatoes", body, Vector3(1.0, 0.95, back + 0.4), 0.0, 0.3)
	Props.kit("restaurant/crate_onions", body, Vector3(1.7, 0.95, back + 0.4), 0.0, 0.3)
	RestaurantRoom.cook(body, Vector3(-1.85, 0, 0.0), 0.0, "Cook")
	# Stacks of bread on the counter and a tray of wraps.
	for stack in 2:
		for i in 12:
			LowPoly.cylinder(body, 0.17, 0.17, 0.012, CREAM.darkened(0.04 * (i % 2)), Vector3(-2.4 + stack * 0.45, TOP_Y + 0.008 + i * 0.014, COUNTER_TOP - 0.1))
	LowPoly.box(body, Vector3(0.6, 0.03, 0.35), STEEL, Vector3(2.3, TOP_Y + 0.015, COUNTER_TOP))
	for i in 4:
		dish("code:wrap", body, Vector3(2.1 + (i % 2) * 0.25, TOP_Y + 0.02, COUNTER_TOP - 0.07 + (i / 2) * 0.14), 1.0)
	# A brass lantern over the counter.
	var lantern := LowPoly.cylinder(body, 0.18, 0.25, 0.45, Color(0.8, 0.6, 0.25), Vector3(0, 3.5, 2.4))
	lantern.name = "BrassLantern"


# ---------------- Bread & Zaatar ----------------

static func bakery(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "bread oven and cake display")
	# The bread oven: a steel deck oven with three glowing doors.
	var oven := Vector3(-3.7, 0, back + 0.7)
	RestaurantRoom.block(body, Vector3(2.6, 2.3, 1.2), Color(0.55, 0.56, 0.58), oven + Vector3(0, 1.15, 0))
	for i in 3:
		LowPoly.box(body, Vector3(2.2, 0.5, 0.04), DARK, oven + Vector3(0, 0.55 + i * 0.6, 0.6))
		glow_box(body, Vector3(1.4, 0.18, 0.02), Color(1.0, 0.55, 0.2), oven + Vector3(0, 0.6 + i * 0.6, 0.63), 2.0)
		LowPoly.box(body, Vector3(1.6, 0.05, 0.08), STEEL, oven + Vector3(0, 0.38 + i * 0.6, 0.66))
	var label := SignText.make_label("فرن · Oven", 22, Color.WHITE, DARK, 4)
	label.position = oven + Vector3(0, 2.15, 0.62)
	body.add_child(label)
	back_counters(body, [-0.6, 1.2, 3.0], back, ["restaurant/kitchentable_A", "restaurant/kitchencounter_straight_A_backsplash"])
	# Manakish trays on the back counter (round breads with green zaatar).
	for i in 6:
		LowPoly.cylinder(body, 0.15, 0.15, 0.02, DOUGH, Vector3(-1.2 + (i % 3) * 0.38, 1.0, back + 0.35 + (i / 3) * 0.35))
		LowPoly.cylinder(body, 0.12, 0.12, 0.01, Color(0.35, 0.45, 0.2), Vector3(-1.2 + (i % 3) * 0.38, 1.015, back + 0.35 + (i / 3) * 0.35))
	Props.kit("restaurant/crate_buns", body, Vector3(4.9, 0, back + 0.5), 0.0, 0.45)
	RestaurantRoom.cook(body, Vector3(-3.7, 0, 0.2), 0.0, "Cook")
	# The glass cake display on the counter: two shelves of cakes (the fragile cake orders).
	var floor_y := display_case(body, -1.7, 2.6, 2)
	var cakes := Node3D.new()
	cakes.name = "CakeDisplay"
	body.add_child(cakes)
	var icing := [Color(0.98, 0.82, 0.87), CREAM, Color(0.42, 0.25, 0.15), Color(0.85, 0.95, 0.75)]
	for i in 8:
		var at := Vector3(-2.75 + (i % 4) * 0.7, floor_y if i < 4 else TOP_Y + 0.32, COUNTER_TOP)
		LowPoly.cylinder(cakes, 0.15, 0.15, 0.16 if i < 4 else 0.1, icing[i % 4], at + Vector3(0, 0.08 if i < 4 else 0.05, 0))
		LowPoly.sphere(cakes, 0.03, 0.06, Color(0.85, 0.1, 0.2), at + Vector3(0, 0.19 if i < 4 else 0.12, 0))
	# Bread baskets on the counter and on a shelf by the door.
	for i in 3:
		bread_basket(body, Vector3(1.6 + i * 0.5, TOP_Y, COUNTER_TOP))
	LowPoly.box(body, Vector3(0.5, 1.5, 1.6), Color(0.6, 0.42, 0.26), Vector3(5.6, 0.75, 3.6))
	LowPoly.solid_box(body, Vector3(0.5, 1.5, 1.6), Vector3(5.6, 0.75, 3.6))
	for y in [0.5, 1.0, 1.5]:
		for i in 2:
			bread_basket(body, Vector3(5.6, y, 3.25 + i * 0.7))


static func bread_basket(parent: Node3D, spot: Vector3) -> void:
	LowPoly.cylinder(parent, 0.2, 0.15, 0.14, Color(0.7, 0.5, 0.28), spot + Vector3(0, 0.07, 0))
	for i in 3:
		var loaf := LowPoly.sphere(parent, 0.06, 0.1, Color(0.85, 0.6, 0.3), spot + Vector3(-0.08 + i * 0.08, 0.16, 0))
		loaf.scale = Vector3(1, 1, 2.0)
