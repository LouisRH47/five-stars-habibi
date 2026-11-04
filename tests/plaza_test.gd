extends SceneTree
## Session 57: the Plaza outside. Builds Wahat Al Shams and checks the new shop rows:
## the shop order and sizes from Appendix A, low shops (4.5 m) with three floors of flats
## joined into one mesh per row, a passage only after every second shop, a logo and a
## bilingual sign on every shop, nothing overlapping (shops, beds, benches, palms, planters),
## every door reachable on foot from the walkways, the sliding doors, the signs lighting up
## after sunset and the grass beds getting real grass.
## Run:  Godot --path . --headless -s tests/plaza_test.gd   (prints RESULT: PASS)
## The smoke test runs the quick part (check_world) too.

const NORTH := ["pizza", "gelato", "passage", "boba", "shawarma", "passage", "bakery", "bikes"]
const SOUTH := ["market", "passage", "thai", "sushi", "passage", "tacos", "burger", "passage", "clothes", "pharmacy"]
var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "user://plaza_test.json"
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 6:
		await physics_frame
	for frame in 30:
		if world.get_node("DistrictDetail").has_meta("static_batch_report"):
			break
		await process_frame
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	for line in check_world(map, world):
		_expect(line[0], line[1])
	await _check_doors_and_glow(map, world)
	_check_reachable(map, world)
	await _check_pickups(map, world)
	_check_grass(map, world)
	print("RESULT: %s" % ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)


## The quick checks (no navigation grid). Returns [[passed, message], ...].
static func check_world(map: Dictionary, world: Node3D) -> Array:
	var results: Array = []
	if not GameConfig.PLAZA_LOOKS_PASS or not map.has("PLAZA_ROWS"):
		return [[true, "the Session 57 Plaza is switched off"]]
	var places := world.get_node("PlaceBuilder")
	var rows: Array = map["PLAZA_ROWS"]
	# 1) Shop order and sizes (Appendix A).
	var order: Array = []
	var widths_ok := true
	for row: Dictionary in rows:
		var ids: Array = []
		for unit: Dictionary in row["units"]:
			ids.append(unit["id"])
			var width: float = unit["to_x"] - unit["from_x"]
			var want := 4.0 if unit["kind"] == "passage" else (24.0 if unit["id"] == "market" else 12.0)
			widths_ok = widths_ok and is_equal_approx(width, want)
		order.append(ids)
	results.append([order == [NORTH, SOUTH], "the shops are in Appendix A's order %s" % [order]])
	results.append([widths_ok, "shops are 12 m wide (Grand Groceries 24 m), passages 4 m"])
	results.append([rows[0]["from_x"] == -240.0 and rows[0]["to_x"] == -160.0 and rows[1]["from_x"] == -254.0 and rows[1]["to_x"] == -146.0,
			"the rows run from x -240 to -160 (north) and -254 to -146 (south)"])
	# 2) Low shops: the room is 4.5 m high and the built side walls are no taller than 4.6 m.
	var tall: Array[String] = []
	var moved: Array[String] = []
	for row: Dictionary in rows:
		for unit: Dictionary in row["units"]:
			if unit["kind"] in ["restaurant", "shop"]:
				var node: Node3D = places.get_node_or_null(("Restaurant_" if unit["kind"] == "restaurant" else "Shop_") + str(unit["id"]))
				if node == null:
					moved.append("%s missing" % unit["id"])
					continue
				var centre := (float(unit["from_x"]) + float(unit["to_x"])) * 0.5
				if absf(node.global_position.x - centre) > 0.01:
					moved.append("%s at x %.1f" % [unit["id"], node.global_position.x])
				for part: MeshInstance3D in node.find_children("*", "MeshInstance3D", false, false):
					if part.mesh is BoxMesh and (part.mesh as BoxMesh).size.x < 0.31 and (part.mesh as BoxMesh).size.y > 4.0 \
							and part.position.y + (part.mesh as BoxMesh).size.y * 0.5 > 4.6:
						tall.append(str(unit["id"]))
	var room: Vector3 = map["RESTAURANT_SIZE"]
	results.append([room.y <= 4.6 and tall.is_empty(), "no shop's ground floor is taller than 4.6 m (%.1f m) %s" % [room.y, tall]])
	results.append([moved.is_empty(), "every shop, the bike shop and the clothes shop stand in their row unit %s" % [moved]])
	# 3) Flats: one joined mesh per row, over every shop and passage, three floors high.
	var flats_ok := 0
	for row: Dictionary in rows:
		var body := world.find_child(String(row["name"]).replace(" ", ""), true, false) as Node3D
		if body == null:
			continue
		var meshes := body.find_children("Flats", "MeshInstance3D", false, false)
		if meshes.size() != 1:
			continue
		var box: AABB = (meshes[0] as MeshInstance3D).global_transform * (meshes[0] as MeshInstance3D).get_aabb()
		var roof := GameConfig.PLAZA_GROUND_FLOOR + GameConfig.PLAZA_FLAT_FLOORS * GameConfig.PLAZA_FLOOR_HEIGHT
		if box.position.x <= float(row["from_x"]) + 0.01 and box.end.x >= float(row["to_x"]) - 0.01 \
				and box.end.y >= roof + GameConfig.PLAZA_PARAPET - 0.01 and box.position.y <= GameConfig.PLAZA_GROUND_FLOOR + 0.01:
			flats_ok += 1
	results.append([flats_ok == rows.size(), "the flats are one joined mesh per row, over the passages too (%d of %d)" % [flats_ok, rows.size()]])
	# 4) A passage only after every second shop (Grand Groceries counts as two).
	var bad_passages: Array[String] = []
	for row: Dictionary in rows:
		var count := 0
		var units: Array = row["units"]
		for i in units.size():
			var unit: Dictionary = units[i]
			if unit["kind"] == "passage":
				if count != 2:
					bad_passages.append("%s at x %d after %d shops" % [row["name"], unit["from_x"], count])
				count = 0
			else:
				count += 2 if unit["id"] == "market" else 1
				if count > 2:
					bad_passages.append("%s: no passage before %s" % [row["name"], unit["id"]])
	results.append([bad_passages.is_empty(), "passages come after every second shop and nowhere else %s" % [bad_passages]])
	# 5) Logos and bilingual signs on every front.
	var no_logo: Array[String] = []
	var no_sign: Array[String] = []
	for front: Node3D in world.find_children("ShopFront", "Node3D", true, false):
		var owner_name := str(front.get_parent().name)
		var logo := front.get_node_or_null("Logo") as MeshInstance3D
		if logo == null or logo.material_override == null or (logo.material_override as StandardMaterial3D).albedo_texture == null:
			no_logo.append(owner_name)
		var sign := front.get_node_or_null("BilingualSign")
		if sign == null or not _has_arabic(sign) or not _has_latin(sign):
			no_sign.append(owner_name)
	var fronts := world.find_children("ShopFront", "Node3D", true, false).size()
	results.append([fronts == 13 and no_logo.is_empty(), "all 13 shop fronts have their own logo (%d fronts) %s" % [fronts, no_logo]])
	results.append([no_sign.is_empty(), "every front's sign has Arabic and English %s" % [no_sign]])
	var missing_files: Array[String] = []
	for row: Dictionary in rows:
		for unit: Dictionary in row["units"]:
			if unit["kind"] != "passage" and (not FileAccess.file_exists("res://assets/logos/%s.svg" % unit["id"]) or not ResourceLoader.exists(unit["logo"])):
				missing_files.append(str(unit["id"]))
	results.append([missing_files.is_empty(), "every place has its logo SVGs in assets/logos/ %s" % [missing_files]])
	# 6) Nothing overlaps: shops, beds, benches, palms, planters, walkways.
	results.append_array(_overlaps(map, world))
	# 7) Spill the Brew keeps the old id, so old saves still load.
	var brew := {}
	for place: Dictionary in map["RESTAURANTS"]:
		if place["id"] == "boba":
			brew = place
	results.append([brew.get("name", "") == "Spill the Brew" and brew.get("arabic", "") == "سبيل ذا برو",
			"Spill the Tea is now Spill the Brew (id \"boba\" kept for old saves)"])
	return results


static func _overlaps(map: Dictionary, world: Node3D) -> Array:
	var results: Array = []
	var land: Dictionary = map["PLAZA_LANDSCAPE"]
	var blocks: Array = []   # [name, Rect2]
	for row: Dictionary in map["PLAZA_ROWS"]:
		var front: float = row["front_z"]
		var back: float = front - (1.0 if is_zero_approx(float(row["facing"])) else -1.0) * float(row["depth"])
		blocks.append([row["name"], Rect2(row["from_x"], minf(front, back), float(row["to_x"]) - float(row["from_x"]), absf(front - back))])
	var core: float = land["core_half"]
	var centre: Vector2 = map["PLAZA"]["centre"]
	var square := Rect2(centre - Vector2.ONE * core, Vector2.ONE * core * 2.0)
	var beds: Array = land["beds"]
	var walks: Array = land["walks"] + land["terraces"] + land["passages"]
	var hits: Array[String] = []
	for i in beds.size():
		var bed: Rect2 = beds[i]
		for block: Array in blocks:
			if _overlap(bed, block[1]):
				hits.append("bed %d and %s" % [i, block[0]])
		for walk: Rect2 in walks:
			if _overlap(bed, walk):
				hits.append("bed %d and a walkway" % i)
		if _overlap(bed, square):
			hits.append("bed %d and the paved square" % i)
		for k in range(i + 1, beds.size()):
			if _overlap(bed, beds[k]):
				hits.append("beds %d and %d" % [i, k])
		for road: Dictionary in map["ROADS"]:
			if _overlap(bed, ClusterSigns.road_rect(road, map["ROAD_WIDTH"])):
				hits.append("bed %d and %s" % [i, road["name"]])
	results.append([hits.is_empty(), "grass beds don't overlap shops, walkways, roads or each other %s" % [hits]])
	# Benches (on the walkways and outside the shops), planters, bins and racks: never on a
	# bed, in a shop row or on top of each other.
	var things: Array = []   # [name, Rect2]
	for bench: StaticBody3D in world.find_children("Bench*", "StaticBody3D", true, false):
		if _in_plaza(bench.global_position):
			things.append(["bench", _turned_rect(bench, Vector2(1.8, 0.5))])
	for pattern in ["Planter", "RoundPlanter", "Bin", "BikeRack"]:
		for body: StaticBody3D in world.find_children(pattern + "*", "StaticBody3D", true, false):
			if _in_plaza(body.global_position):
				var size := Vector2(1.2, 1.2) if pattern == "Planter" else Vector2(3.3, 3.3) if pattern == "RoundPlanter" \
						else Vector2(0.6, 0.6) if pattern == "Bin" else Vector2(3.0, 0.62)
				things.append([pattern, _turned_rect(body, size)])
	var crowded: Array[String] = []
	for i in things.size():
		var rect: Rect2 = things[i][1]
		for bed: Rect2 in beds:
			if things[i][0] != "BikeRack" and _overlap(rect, bed):
				crowded.append("%s at (%d, %d) on a bed" % [things[i][0], rect.get_center().x, rect.get_center().y])
		for block: Array in blocks:
			if things[i][0] != "BikeRack" and things[i][0] != "Bin" and _overlap(rect, block[1]):
				crowded.append("%s at (%d, %d) in %s" % [things[i][0], rect.get_center().x, rect.get_center().y, block[0]])
		for k in range(i + 1, things.size()):
			if _overlap(rect, things[k][1]):
				crowded.append("%s and %s at (%d, %d)" % [things[i][0], things[k][0], rect.get_center().x, rect.get_center().y])
	results.append([crowded.is_empty() and things.size() > 40, "benches, planters, bins and racks don't overlap beds, shops or each other (%d things) %s" % [things.size(), crowded]])
	# Palms: in a bed or a round planter, never on a walkway, in a shop or under a bench.
	var bad_palms: Array[String] = []
	var plaza_palms := 0
	for palm: Vector3 in map["PALM_TREES"]:
		var p := Vector2(palm.x, palm.z)
		if not _in_plaza(palm) or p.distance_to(centre) < float(map["PLAZA"]["sunken_radius"]):
			continue
		plaza_palms += 1
		var in_bed := false
		for bed: Rect2 in beds:
			in_bed = in_bed or bed.grow(-0.3).has_point(p)
		for spot: Vector3 in land.get("core_planters", []):
			in_bed = in_bed or Vector2(spot.x, spot.z).distance_to(p) < 0.5
		var on_walk := false
		for walk: Rect2 in walks:
			on_walk = on_walk or walk.grow(0.3).has_point(p)
		for thing: Array in things:
			on_walk = on_walk or (thing[0] != "RoundPlanter" and (thing[1] as Rect2).grow(0.3).has_point(p))
		if not in_bed or on_walk:
			bad_palms.append("(%d, %d)" % [p.x, p.y])
	results.append([bad_palms.is_empty() and plaza_palms >= 40, "%d Plaza palms stand in beds or planters, clear of walkways and benches %s" % [plaza_palms, bad_palms]])
	# Plan step 8: no bare paving bigger than 10 x 10 m except the sunken square.
	var slabs: Array[String] = []
	for walk: Rect2 in walks:
		if minf(walk.size.x, walk.size.y) > 10.0:
			slabs.append(str(walk))
	results.append([slabs.is_empty(), "no paved area is more than 10 m across both ways %s" % [slabs]])
	# Benches face the bed they're for.
	var facing_wrong: Array[String] = []
	for bench: Dictionary in land["benches"]:
		var facing := deg_to_rad(float(bench["facing"]))
		var ahead := Vector2(bench["position"].x, bench["position"].z) + Vector2(sin(facing), cos(facing)) * 1.5
		var found := false
		for bed: Rect2 in beds:
			found = found or bed.has_point(ahead)
		if not found:
			facing_wrong.append("(%d, %d)" % [bench["position"].x, bench["position"].z])
	results.append([facing_wrong.is_empty() and land["benches"].size() >= 8, "the benches on the walkways look at a grass bed %s" % [facing_wrong]])
	return results


## Sliding doors open when you walk up; the sign bands light up after sunset.
func _check_doors_and_glow(map: Dictionary, world: Node3D) -> void:
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	var walker: Node3D = world.get_node("Walker")
	var bike: Node3D = world.get_node("Bike")
	bike.global_position = Vector3(-300, 0.1, -175)
	var door := world.get_node("PlaceBuilder/Restaurant_pizza/ShopFront/SlidingDoor") as SlidingDoor
	_expect(door != null and door.open_amount < 0.01, "the pizza door is shut while nobody is near")
	if door != null:
		var was_visible := walker.visible
		walker.visible = true
		walker.global_position = places.restaurant_entrance("pizza")
		for frame in 60:
			await process_frame
		_expect(door.open_amount > 0.9, "the sliding door opens when you walk up (%.2f)" % door.open_amount)
		walker.global_position = Vector3(-300, 0.1, -160)
		for frame in 60:
			await process_frame
		_expect(door.open_amount < 0.1, "and slides shut when you walk away (%.2f)" % door.open_amount)
		walker.visible = was_visible
	var locked := world.find_child("Pharmacy", true, false)
	_expect(locked != null and (locked.get_node("ShopFront/SlidingDoor") as SlidingDoor).locked, "Wahat Pharmacy's door never opens (scenery only)")
	var glow := world.find_child("NightGlow", true, false) as NightGlow
	var band := world.get_node("PlaceBuilder/Restaurant_sushi/ShopFront/SignBand") as MeshInstance3D
	if glow == null or band == null:
		_expect(false, "the night glow and the sign bands exist")
		return
	glow.set_process(false)
	glow.apply_hour(12.0)
	var noon := (band.material_override as StandardMaterial3D).emission_energy_multiplier
	glow.apply_hour(17.9)
	var night := (band.material_override as StandardMaterial3D).emission_energy_multiplier
	var lamps := get_nodes_in_group("plaza_night_light")
	_expect(noon == 0.0 and night > 0.5 and lamps.size() == 5 and lamps.all(func(l): return l.visible),
			"the sign bands light up after sunset (%.1f at noon, %.1f at 17:54) and the 5 passage lamps come on" % [noon, night])
	glow.apply_hour(12.0)


## Every door and counter can be reached on foot from the walkways (navigation grid).
func _check_reachable(map: Dictionary, world: Node3D) -> void:
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	var grid := NavigationGrid.new()
	var before := Time.get_ticks_msec()
	grid.build(world.get_world_3d(), map["MAP_HALF"], [world.get_node("Bike"), world.get_node("Walker")])
	print("NAV_SCAN_MS: ", Time.get_ticks_msec() - before)
	var walks: Array = map["PLAZA_LANDSCAPE"]["walks"]
	var starts := [(walks[0] as Rect2).get_center(), (walks[1] as Rect2).get_center()]
	var blocked: Array[String] = []
	for place: Dictionary in places.restaurants:
		if not place.has("row"):
			continue
		var id: String = place["id"]
		for point: Vector3 in [places.restaurant_approach(id), places.restaurant_counter(id)]:
			var spot := Vector2(point.x, point.z)
			if not grid.is_free(spot) or not (grid.can_reach(starts[0], spot) and grid.can_reach(starts[1], spot)):
				blocked.append(id)
	for shop: Dictionary in map["SHOPS"]:
		var turn := Transform3D(Basis(Vector3.UP, deg_to_rad(float(shop["facing"]))), shop["position"])
		var counter: Vector3 = turn * (ShopInterior.COUNTER + Vector3(0, 0, 1.0))
		var spot := Vector2(counter.x, counter.z)
		if not grid.can_reach(starts[0], spot) or not grid.can_reach(starts[1], spot):
			blocked.append(str(shop["id"]))
	_expect(blocked.is_empty(), "every shop door and counter can be reached on foot from the walkways %s" % [blocked])
	var passages_open: Array[String] = []
	for passage: Rect2 in map["PLAZA_LANDSCAPE"]["passages"]:
		var a := Vector2(passage.get_center().x, passage.position.y + 0.6)
		var b := Vector2(passage.get_center().x, passage.end.y - 0.6)
		if grid.path(a, b).is_empty():
			passages_open.append(str(passage))
	_expect(passages_open.is_empty(), "you can ride right through every passage %s" % [passages_open])


## Plan step 9: an order can be picked up at every restaurant's counter (walking in from
## the bike), and both shops still open at their counters.
func _check_pickups(map: Dictionary, world: Node3D) -> void:
	var state := root.get_node("GameState")
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	var dm = world.get_node("DeliveryManager")
	var on_foot: Node = world.get_node("OnFoot")
	var bike: Node3D = world.get_node("Bike")
	world.get_node("EventManager").enabled = false
	var failed: Array[String] = []
	for place: Dictionary in places.restaurants:
		if not place.has("row"):
			continue
		var id: String = place["id"]
		state.reset()
		var order = dm.make_order(id, 101)
		if not (state.offer_order(order) and dm.accept()):
			failed.append(id + " (no order)")
			continue
		bike.global_position = places.restaurant_approach(id) + Vector3.UP * 0.05
		bike.velocity = Vector3.ZERO
		await physics_frame
		if not on_foot.get_off():
			failed.append(id + " (can't get off)")
			continue
		on_foot.walker.global_position = places.restaurant_counter(id) + Vector3.UP * 0.05
		for frame in 3:
			await physics_frame
		if not (dm.try_interact() and state.stage_name() == "TO_VILLA"):
			failed.append(id)
		on_foot.get_on(true)
		await physics_frame
	state.reset()
	_expect(failed.is_empty(), "an order can be picked up at the counter of all 10 Plaza restaurants %s" % [failed])
	var shops = world.get_node("ShopController")
	var opened: Array[String] = []
	for shop: Dictionary in map["SHOPS"]:
		bike.global_position = Vector3(shop["position"]) + Vector3(0, 0.05, 7.5 if is_zero_approx(float(shop["facing"])) else -7.5)
		await physics_frame
		on_foot.get_off()
		var turn := Transform3D(Basis(Vector3.UP, deg_to_rad(float(shop["facing"]))), shop["position"])
		on_foot.walker.global_position = turn * (ShopInterior.COUNTER + Vector3(0, 0.05, 1.0))
		await physics_frame
		if shops.nearby_shop() == shop["id"] and shops.open_shop(shop["id"]):
			opened.append(str(shop["id"]))
			shops.close_shop()
		on_foot.get_on(true)
		await physics_frame
	_expect(opened == ["bikes", "clothes"], "Pedal Point Bikes and Dune Drip still open at their counters %s" % [opened])


## The grass beds get real grass blades (they're lawns for GrassField).
func _check_grass(map: Dictionary, world: Node3D) -> void:
	if not GameConfig.GRASS_BLADES_ON:
		return
	var field := world.find_child("GrassField", true, false) as GrassField
	var beds: Array = map["PLAZA_LANDSCAPE"]["beds"]
	var found := 0
	if field != null:
		for bed: Rect2 in beds:
			for lawn: Array in field.lawns:
				if (lawn[0] as Rect2).grow(0.5).encloses(bed.grow(-0.5)):
					found += 1
					break
	_expect(found == beds.size(), "every grass bed grows real grass (%d of %d)" % [found, beds.size()])
	if field != null:
		var middle: Rect2 = beds[1]
		field.fill_around(Vector3(middle.get_center().x, 0, middle.get_center().y), -1.0)
		var y := field.ground_height(middle.get_center().x + 0.7, middle.get_center().y + 0.3)
		_expect(field.tuft_count > 0 and is_equal_approx(y, PlazaLandscape.LAWN_TOP), "grass grows on the Plaza beds at the lawn's height (%d tufts)" % field.tuft_count)


static func _in_plaza(spot: Vector3) -> bool:
	return Rect2(-290, -205, 150, 122).has_point(Vector2(spot.x, spot.z))


static func _turned_rect(body: Node3D, size: Vector2) -> Rect2:
	var along_x := absf(body.global_transform.basis.x.x) > 0.5
	var half := size * 0.5 if along_x else Vector2(size.y, size.x) * 0.5
	var at := Vector2(body.global_position.x, body.global_position.z)
	return Rect2(at - half, half * 2.0)


static func _overlap(a: Rect2, b: Rect2) -> bool:
	var both := a.intersection(b)
	return both.size.x > 0.01 and both.size.y > 0.01


static func _has_arabic(node: Node) -> bool:
	for label: Label3D in node.find_children("*", "Label3D", true, false):
		for i in label.text.length():
			if label.text.unicode_at(i) >= 0x0600 and label.text.unicode_at(i) <= 0x06FF:
				return true
	return false


static func _has_latin(node: Node) -> bool:
	for label: Label3D in node.find_children("*", "Label3D", true, false):
		for i in label.text.length():
			var code := label.text.unicode_at(i)
			if (code >= 0x41 and code <= 0x5A) or (code >= 0x61 and code <= 0x7A):
				return true
	return false


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
