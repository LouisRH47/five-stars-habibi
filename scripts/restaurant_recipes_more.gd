class_name RestaurantRecipesMore
## The other restaurant rooms (looks pass, Session 55), from the approved designs:
##   Tok Tok Thai: woks over flames, red lanterns, dark wood floor
##   Sushi You: sushi bar with a moving conveyor belt of coloured plates and diners on
##     stools, glass fish case, two chefs, paper lanterns, navy curtain over the kitchen,
##     a booth table, bamboo, a pick-up counter
##   Mario Bonito: colourful tile band, paper bunting, cactus pots, taco counter
##   Burgerology: flat grill with patties, fryer, pink neon "Burgerology" sign, white metro tiles
## Shared bits (counters, flames, dishes) are in scripts/restaurant_recipes.gd.

const STEEL := RestaurantRecipes.STEEL
const DARK := RestaurantRecipes.DARK
const CREAM := RestaurantRecipes.CREAM
const TOP_Y := RestaurantRecipes.TOP_Y
const COUNTER_Z := RestaurantRoom.COUNTER_Z
const PLATE_COLOURS := [Color(0.85, 0.15, 0.15), Color(0.2, 0.45, 0.85), Color(0.95, 0.8, 0.2),
		Color(0.25, 0.65, 0.35), Color(0.97, 0.97, 0.95), Color(0.1, 0.1, 0.12)]
const FISH := [Color(1.0, 0.55, 0.35), Color(0.8, 0.15, 0.2), Color(0.97, 0.94, 0.9), Color(0.95, 0.75, 0.3)]


static func build(kind: String, body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	match kind:
		"thai":
			thai(body, back, tint, motion)
		"sushi":
			sushi(body, back, tint, motion)
		"tacos":
			tacos(body, back, tint, motion)
		"burger":
			burger(body, back, tint, motion)


## A wall band of patterned tiles (back and both side walls) from y0 to y1.
static func wall_band(body: StaticBody3D, back: float, material_for: Callable, y0: float, y1: float) -> void:
	var tall := y1 - y0
	var band := LowPoly.box(body, Vector3(11.9, tall, 0.02), Color.WHITE, Vector3(0, y0 + tall * 0.5, back + 0.015))
	band.material_override = material_for.call(Vector2(11.9, tall))
	for side in [-1.0, 1.0]:
		var wall := LowPoly.box(body, Vector3(0.02, tall, 9.8), Color.WHITE, Vector3(side * 5.985, y0 + tall * 0.5, back + 5.0))
		wall.material_override = material_for.call(Vector2(9.8, tall))


## A lantern hanging from the ceiling on a cord. paper = white paper, otherwise red silk.
static func lantern(body: StaticBody3D, spot: Vector3, colour: Color, motion: VenueMotion, paper := false) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Lantern"
	holder.position = Vector3(spot.x, RestaurantRoom.CEILING, spot.z)
	holder.set_meta("static_batch_dynamic", true)
	body.add_child(holder, true)
	var drop := 1.0 + fmod(absf(spot.x * 0.37 + spot.z * 0.21), 0.5)
	LowPoly.cylinder(holder, 0.01, 0.01, drop, DARK, Vector3(0, -drop * 0.5, 0))
	var shade: MeshInstance3D
	if paper:
		shade = LowPoly.cylinder(holder, 0.22, 0.22, 0.5, colour, Vector3(0, -drop - 0.25, 0))
	else:
		shade = LowPoly.sphere(holder, 0.28, 0.45, colour, Vector3(0, -drop - 0.22, 0))
		for y in [-drop + 0.02, -drop - 0.46]:
			LowPoly.cylinder(holder, 0.12, 0.12, 0.05, Color(0.85, 0.65, 0.2), Vector3(0, y, 0))
		LowPoly.box(holder, Vector3(0.02, 0.2, 0.02), Color(0.85, 0.65, 0.2), Vector3(0, -drop - 0.58, 0))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = colour
	glow.emission_enabled = true
	glow.emission = colour.lerp(Color(1, 0.8, 0.5), 0.5)
	glow.emission_energy_multiplier = 1.6
	shade.material_override = glow
	motion.spinners.append([holder, "z", 0.8 + fmod(spot.x, 0.3)])
	return holder


# ---------------- Tok Tok Thai ----------------

static func thai(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "woks over flames and red lanterns")
	RestaurantRecipes.back_counters(body, [-3.6, -1.8, 0.0, 1.8, 3.6], back, ["restaurant/stove_multi", "restaurant/stove_multi",
			"restaurant/kitchencounter_straight_A_backsplash", "restaurant/kitchencounter_sink_backsplash", "restaurant/kitchencounter_straight_decorated"])
	# Three woks over roaring flames.
	for i in 3:
		var at := Vector3(-4.1 + i * 0.95, 1.14, back + 0.5)
		for k in 2:
			RestaurantRecipes.flame(body, at + Vector3(-0.1 + k * 0.2, -0.02, 0), motion, 0.6)
		var wok := LowPoly.sphere(body, 0.32, 0.25, Color(0.15, 0.15, 0.16), at + Vector3(0, 0.2, 0))
		wok.name = "Wok"
		LowPoly.box(body, Vector3(0.04, 0.04, 0.4), Color(0.4, 0.28, 0.16), at + Vector3(0, 0.26, 0.45))
		LowPoly.sphere(body, 0.2, 0.08, [Color(0.95, 0.75, 0.4), Color(0.35, 0.6, 0.25), Color(0.85, 0.35, 0.15)][i], at + Vector3(0, 0.3, 0))
	Props.kit("restaurant/extractorhood", body, Vector3(-3.0, 1.0, back + 0.1), 0.0, Vector3(1.2, 0.6, 0.5))
	Props.kit("restaurant/pot_A_stew", body, Vector3(0.0, 0.95, back + 0.45), 0.0, 0.4)
	for i in 4:
		Props.kit("restaurant/bowl", body, Vector3(1.3 + i * 0.3, 0.95, back + 0.45), 0.0, 0.22)
	RestaurantRoom.cook(body, Vector3(-3.2, 0, 0.0), 0.0, "Cook")
	# Red lanterns hanging over the room and the counter.
	for spot in [Vector3(-4.0, 0, 4.3), Vector3(4.0, 0, 4.3), Vector3(-4.0, 0, 6.7), Vector3(4.0, 0, 6.7),
			Vector3(-1.8, 0, COUNTER_Z), Vector3(1.8, 0, COUNTER_Z), Vector3(0, 0, 5.5), Vector3(-2.4, 0, 2.8), Vector3(2.4, 0, 2.8)]:
		lantern(body, spot, Color(0.85, 0.12, 0.1), motion)
	# Gold trim and two pictures (from the furniture kit) on the side walls.
	for side in [-1.0, 1.0]:
		LowPoly.box(body, Vector3(0.03, 0.12, 9.6), Color(0.85, 0.65, 0.2), Vector3(side * 5.98, 2.6, back + 5.0))
		Props.kit("furniture/pictureframe_large_A", body, Vector3(side * 5.98, 2.0, 5.5), -90.0 * side, 1.0)
	# Chopsticks and spring rolls ready on the counter.
	for i in 5:
		var roll := LowPoly.cylinder(body, 0.04, 0.04, 0.2, Color(0.9, 0.7, 0.35), Vector3(-2.2 + i * 0.1, TOP_Y + 0.04, COUNTER_Z))
		roll.rotation.x = PI * 0.5


# ---------------- Sushi You ----------------

static func sushi(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "sushi conveyor belt")
	var style := RestaurantStyles.style("sushi")
	RestaurantRecipes.back_counters(body, [-3.6, -1.8, 1.8, 3.6], back, ["restaurant/kitchencounter_straight_A_backsplash",
			"restaurant/kitchencounter_sink_backsplash", "restaurant/kitchencounter_straight_decorated"])
	RestaurantRoom.cook(body, Vector3(-2.6, 0, 0.0), 0.0, "Cook")
	# The navy curtain (noren) over the kitchen door in the back wall, behind the menu.
	LowPoly.box(body, Vector3(1.4, 2.3, 0.05), DARK, Vector3(0, 1.15, back + 0.03))
	for i in 3:
		LowPoly.box(body, Vector3(0.44, 1.0, 0.03), tint, Vector3(-0.47 + i * 0.47, 1.85, back + 0.08))
		LowPoly.box(body, Vector3(0.3, 0.05, 0.035), CREAM, Vector3(-0.47 + i * 0.47, 1.7, back + 0.09))
	# The pick-up counter: a sign and the glass fish case.
	var sign := SignText.make_face("استلام", "Pick-up", 22, CREAM)
	sign.position = Vector3(1.6, 0.6, COUNTER_Z + 0.42)
	body.add_child(sign)
	var floor_y := RestaurantRecipes.display_case(body, -1.6, 2.6)
	var fish := Node3D.new()
	fish.name = "FishCase"
	body.add_child(fish)
	for i in 8:
		LowPoly.box(fish, Vector3(0.5, 0.07, 0.22), FISH[i % 4], Vector3(-2.65 + (i % 4) * 0.7, floor_y + 0.04, COUNTER_Z - 0.12 + (i / 4) * 0.26))
	# The sushi bar along the right with a conveyor belt loop on top, and the bar chef.
	var bar := Rect2(2.6, 3.4, 1.8, 4.0)   # x, z, width, depth
	var middle := Vector3(bar.position.x + bar.size.x * 0.5, 0, bar.position.y + bar.size.y * 0.5)
	RestaurantRoom.block(body, Vector3(bar.size.x, 1.0, bar.size.y), Color(0.55, 0.38, 0.22), middle + Vector3(0, 0.5, 0))
	LowPoly.box(body, Vector3(bar.size.x + 0.1, 0.05, bar.size.y + 0.1), Color(0.75, 0.6, 0.4), middle + Vector3(0, 1.02, 0))
	var inset := 0.32
	var loop := PackedVector2Array([
		Vector2(bar.position.x + inset, bar.position.y + inset), Vector2(bar.end.x - inset, bar.position.y + inset),
		Vector2(bar.end.x - inset, bar.end.y - inset), Vector2(bar.position.x + inset, bar.end.y - inset)])
	for i in 4:  # the dark belt itself
		var a := loop[i]
		var b := loop[(i + 1) % 4]
		var mid := (a + b) * 0.5
		var along_x := absf(b.x - a.x) > 0.01
		LowPoly.box(body, Vector3(a.distance_to(b) + 0.3 if along_x else 0.3, 0.03, 0.3 if along_x else a.distance_to(b) + 0.3),
				Color(0.2, 0.2, 0.22), Vector3(mid.x, 1.06, mid.y))
	var belt := Node3D.new()
	belt.name = "SushiBelt"
	belt.set_meta("static_batch_dynamic", true)
	body.add_child(belt)
	var plates: Array[Node3D] = []
	for i in 14:
		var plate := Node3D.new()
		plate.name = "BeltPlate%d" % i
		plate.position.y = 1.08
		belt.add_child(plate)
		LowPoly.cylinder(plate, 0.12, 0.1, 0.03, PLATE_COLOURS[i % PLATE_COLOURS.size()], Vector3.ZERO)
		RestaurantRecipes.dish("code:sushi", plate, Vector3(0, 0.0, 0), 1.0)
		plates.append(plate)
	motion.belt_speed = GameConfig.SUSHI_BELT_SPEED
	motion.set_belt(loop, plates)
	var chef := RestaurantRoom.cook(body, Vector3(5.3, 0, middle.z), 90.0, "BarChef")
	PeopleLooks.head_cloth(chef, tint, false)
	# Stools along the bar with people eating off the belt.
	for i in 4:
		var at := Vector3(bar.position.x - 0.45, 0, bar.position.y + 0.5 + i * 1.0)
		Props.kit("furniture/chair_stool_wood", body, at, 0.0, Vector3(0.7, 1.5, 0.7))
		if i != 2:
			var diner := PeopleLooks.resident(i + 1)
			diner.name = "SeatedCustomer"
			diner.position = at + Vector3(0, 0.75 - 0.88, 0)
			diner.rotation_degrees.y = -90.0  # faces the belt
			body.add_child(diner, true)
			diner.play("sit")
			motion.diners.append(diner)
			RestaurantRecipes.dish("code:sushi", body, Vector3(bar.position.x + 0.1, 1.05, at.z), 1.0)
	# A booth on the left (a couch from the furniture kit and a table) and one round table.
	var booth := Vector3(-5.35, 0, 6.2)
	Props.kit("furniture/couch_pillows", body, booth, 90.0, 0.7)
	LowPoly.solid_box(body, Vector3(1.1, 0.85, 2.1), booth + Vector3(0, 0.42, 0))
	var booth_table := booth + Vector3(1.15, 0, 0)
	Props.kit("furniture/table_medium", body, booth_table, 0.0, Vector3(0.45, 0.75, 0.9))
	LowPoly.solid_box(body, Vector3(0.9, 0.75, 1.8), booth_table + Vector3(0, 0.375, 0))
	for i in 2:
		var guest := PeopleLooks.resident(i * 2)
		guest.name = "SeatedCustomer"
		guest.position = booth + Vector3(0.1, 0.45 - 0.88, -0.5 + i * 1.0)
		guest.rotation_degrees.y = -90.0
		body.add_child(guest, true)
		guest.play("sit")
		motion.diners.append(guest)
		RestaurantRecipes.dish("code:sushi", body, booth_table + Vector3(-0.2, 0.75, -0.5 + i * 1.0), 1.0)
	RestaurantRoom.table(body, Vector2(-4.0, 4.3), style)
	# Paper lanterns and bamboo.
	for spot in [Vector3(-1.8, 0, COUNTER_Z), Vector3(1.8, 0, COUNTER_Z), Vector3(3.5, 0, 4.2), Vector3(3.5, 0, 6.6),
			Vector3(-4.2, 0, 4.3), Vector3(-4.2, 0, 6.2)]:
		lantern(body, spot, Color(0.98, 0.95, 0.88), motion, true)
	for corner in [Vector3(-4.6, 0, 7.5), Vector3(-5.3, 0, 3.4)]:
		bamboo(body, corner)


static func bamboo(body: StaticBody3D, spot: Vector3) -> void:
	LowPoly.cylinder(body, 0.3, 0.25, 0.4, Color(0.25, 0.25, 0.27), spot + Vector3(0, 0.2, 0))
	for i in 5:
		var tall := 2.2 + (i % 3) * 0.5
		var at := spot + Vector3(cos(i * 1.3) * 0.15, tall * 0.5 + 0.3, sin(i * 1.3) * 0.15)
		LowPoly.cylinder(body, 0.035, 0.035, tall, Color(0.45, 0.65, 0.3), at)
		for k in 3:
			LowPoly.cylinder(body, 0.042, 0.042, 0.03, Color(0.35, 0.5, 0.22), at + Vector3(0, -tall * 0.3 + k * tall * 0.3, 0))
		LowPoly.sphere(body, 0.18, 0.12, Color(0.35, 0.6, 0.28), at + Vector3(0.1, tall * 0.5, 0))


# ---------------- Mario Bonito ----------------

static func tacos(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "colourful tiles and bunting")
	var style := RestaurantStyles.style("tacos")
	wall_band(body, back, func(area: Vector2): return RoomProps.floor_material(tint, style["accent"], "talavera", 0.3, area), 0.7, 1.6)
	RestaurantRecipes.back_counters(body, [-3.6, -1.8, 0.0, 1.8], back, ["restaurant/stove_multi",
			"restaurant/kitchencounter_straight_A_backsplash", "restaurant/kitchencounter_straight_decorated"])
	Props.kit("restaurant/crate_tomatoes", body, Vector3(4.9, 0, back + 0.5), 0.0, 0.4)
	Props.kit("restaurant/crate_onions", body, Vector3(4.9, 0.38, back + 0.5), 20.0, 0.38)
	RestaurantRoom.cook(body, Vector3(-3.0, 0, 0.0), 0.0, "Cook")
	# The taco counter: trays of fillings, a stack of tortillas and tacos in a stand.
	var fillings := [Color(0.85, 0.2, 0.15), Color(0.4, 0.7, 0.3), Color(0.97, 0.95, 0.9), Color(0.98, 0.8, 0.3), Color(0.5, 0.3, 0.15)]
	for i in 5:
		var at := Vector3(-2.8 + i * 0.5, TOP_Y, COUNTER_Z - 0.1)
		LowPoly.box(body, Vector3(0.44, 0.08, 0.3), STEEL, at + Vector3(0, 0.04, 0))
		LowPoly.box(body, Vector3(0.38, 0.03, 0.24), fillings[i], at + Vector3(0, 0.085, 0))
	for i in 10:
		LowPoly.cylinder(body, 0.15, 0.15, 0.012, Color(0.95, 0.85, 0.6), Vector3(0.0, TOP_Y + 0.008 + i * 0.013, COUNTER_Z))
	var stand := Vector3(1.8, TOP_Y, COUNTER_Z)
	LowPoly.box(body, Vector3(0.5, 0.04, 0.18), STEEL, stand + Vector3(0, 0.02, 0))
	RestaurantRecipes.dish("code:taco", body, stand + Vector3(-0.1, 0.0, 0), 1.0)
	RestaurantRecipes.dish("code:taco", body, stand + Vector3(0.12, 0.0, 0), 1.0)
	# Paper bunting: strings of bright flags across the room.
	var flags := [tint, style["accent"], Color(0.98, 0.8, 0.2), Color(0.95, 0.45, 0.65), Color(0.35, 0.7, 0.35)]
	var bunting := Node3D.new()
	bunting.name = "Bunting"
	body.add_child(bunting)
	for line in 3:
		var a := Vector3(-5.9, 4.1, 2.5 + line * 2.2)
		var b := Vector3(5.9, 4.1, 3.6 + line * 2.2)
		var cord := LowPoly.box(bunting, Vector3(a.distance_to(b), 0.01, 0.01), DARK, (a + b) * 0.5)
		cord.rotation.y = -atan2(b.z - a.z, b.x - a.x)
		for k in 16:
			var at := a.lerp(b, (k + 0.5) / 16.0) + Vector3(0, -0.16 - sin(PI * (k + 0.5) / 16.0) * 0.25, 0)
			var flag := LowPoly.box(bunting, Vector3(0.22, 0.22, 0.01), flags[(k + line) % flags.size()], at)
			flag.rotation = Vector3(0, cord.rotation.y, PI * 0.25)
	# Cactus pots on the counter, the tables and the floor.
	Props.kit("furniture/cactus_medium_A", body, Vector3(-5.3, 0, 3.6), 0.0, 1.2)
	Props.kit("furniture/cactus_medium_B", body, Vector3(5.3, 0, 3.4), 0.0, 1.2)
	for spot: Vector2 in RestaurantRoom.TABLES:
		Props.kit("furniture/cactus_small_A" if spot.x < 0 else "furniture/cactus_small_B", body, Vector3(spot.x, 0.72, spot.y), 0.0, 0.35)
	Props.kit("furniture/cactus_small_A", body, Vector3(2.6, TOP_Y, COUNTER_Z), 0.0, 0.45)
	# A painted sun on the left wall.
	var sun := Vector3(-5.95, 2.9, 5.5)
	var disc := LowPoly.cylinder(body, 0.5, 0.5, 0.02, Color(0.98, 0.7, 0.15), sun)
	disc.rotation.z = PI * 0.5
	for k in 10:
		var ray := LowPoly.box(body, Vector3(0.015, 0.35, 0.08), Color(0.95, 0.45, 0.15), sun + Vector3(0, sin(k * TAU / 10) * 0.75, cos(k * TAU / 10) * 0.75))
		ray.rotation.x = PI * 0.5 - k * TAU / 10


# ---------------- Burgerology ----------------

static func burger(body: StaticBody3D, back: float, tint: Color, motion: VenueMotion) -> void:
	body.set_meta("signature", "flat grill and pink neon")
	var pink: Color = RestaurantStyles.style("burger")["accent"]
	wall_band(body, back, func(area: Vector2): return RoomProps.floor_material(RestaurantStyles.WHITE, Color(0.7, 0.72, 0.74), "metro", 0.3, area), 0.2, 2.8)
	# The flat grill with patties and buns, under the kit extractor hood.
	var grill := Vector3(-3.2, 0, back + 0.5)
	RestaurantRoom.block(body, Vector3(2.4, 0.95, 0.9), STEEL, grill + Vector3(0, 0.475, 0))
	LowPoly.box(body, Vector3(2.3, 0.05, 0.8), Color(0.12, 0.12, 0.13), grill + Vector3(0, 0.98, 0))
	var griddle := Node3D.new()
	griddle.name = "FlatGrill"
	body.add_child(griddle)
	for i in 6:
		Props.kit("restaurant/food_ingredient_burger_cooked", griddle, grill + Vector3(-0.9 + (i % 3) * 0.4, 1.0, -0.15 + (i / 3) * 0.32), 0.0, 0.32)
	for i in 3:
		Props.kit("restaurant/food_ingredient_bun", griddle, grill + Vector3(0.5 + i * 0.3, 1.0, 0.1), 0.0, 0.3)
	Props.kit("restaurant/extractorhood", body, grill + Vector3(0, 0.9, -0.4), 0.0, Vector3(1.2, 0.6, 0.5))
	# The fryer: two baskets in hot oil.
	var fryer := Vector3(-0.6, 0, back + 0.5)
	RestaurantRoom.block(body, Vector3(1.2, 0.95, 0.9), STEEL, fryer + Vector3(0, 0.475, 0))
	for i in 2:
		LowPoly.box(body, Vector3(0.42, 0.03, 0.5), Color(0.9, 0.72, 0.2), fryer + Vector3(-0.25 + i * 0.5, 0.94, 0))
		LowPoly.box(body, Vector3(0.36, 0.2, 0.44), DARK, fryer + Vector3(-0.25 + i * 0.5, 1.02, 0))
		LowPoly.box(body, Vector3(0.04, 0.04, 0.35), DARK, fryer + Vector3(-0.25 + i * 0.5, 1.12, 0.38))
	RestaurantRecipes.back_counters(body, [1.4, 3.2], back, ["restaurant/kitchencounter_straight_decorated", "restaurant/kitchencounter_sink_backsplash"])
	RestaurantRoom.cook(body, Vector3(-3.0, 0, 0.0), 0.0, "Cook")
	# The pink neon "Burgerology" sign on the left wall, glowing.
	var neon := SignText.make_label("Burgerology", 90, Color(1.0, 0.55, 0.8), pink, 14)
	neon.name = "NeonSign"
	neon.position = Vector3(-5.85, 3.1, 5.0)
	neon.rotation.y = PI * 0.5
	body.add_child(neon)
	var neon_ar := SignText.make_label("برجرولوجي", 50, Color(1.0, 0.55, 0.8), pink, 10)
	neon_ar.position = Vector3(-5.85, 2.45, 5.0)
	neon_ar.rotation.y = PI * 0.5
	body.add_child(neon_ar)
	var glow := OmniLight3D.new()
	glow.name = "NeonGlow"
	glow.position = Vector3(-5.3, 2.9, 5.0)
	glow.light_color = pink
	glow.light_energy = 0.8
	glow.omni_range = 3.0
	glow.distance_fade_enabled = true
	glow.distance_fade_begin = 30.0
	glow.distance_fade_length = 8.0
	body.add_child(glow)
	# Ketchup and mustard on every table, and fries on the counter.
	for spot: Vector2 in RestaurantRoom.TABLES:
		Props.kit("restaurant/ketchup", body, Vector3(spot.x - 0.08, 0.72, spot.y + 0.25), 0.0, 0.3)
		Props.kit("restaurant/mustard", body, Vector3(spot.x + 0.08, 0.72, spot.y + 0.25), 0.0, 0.3)
	for i in 3:
		LowPoly.box(body, Vector3(0.14, 0.16, 0.1), Color(0.85, 0.15, 0.15), Vector3(-2.4 + i * 0.25, TOP_Y + 0.08, COUNTER_Z))
		for k in 4:
			LowPoly.box(body, Vector3(0.015, 0.1, 0.015), Color(0.98, 0.8, 0.3), Vector3(-2.44 + i * 0.25 + k * 0.025, TOP_Y + 0.2, COUNTER_Z))
