extends SceneTree
## Integration checks against the built district and its real physics colliders.
var failures: Array[String] = []
var checks := 0
var world: Node3D

func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label + " " + detail)
		print("FAIL: ", label, " ", detail)
	else:
		print("PASS: ", label, " ", detail)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://detail_world_test.json"
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	for frame in 6:
		await physics_frame
	for frame in 10:
		if world.get_node("DistrictDetail").has_meta("static_batch_report"):
			break
		await process_frame
	var bike: Node3D = world.get_node("Bike")
	var walker: Node3D = world.get_node("Walker")
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	var dm: Node = world.get_node("DeliveryManager")
	dm.set_physics_process(false)
	world.get_node("EventManager").enabled = false
	_expect(WahatAlShams.MAP_HALF == Vector2(470, 250), "district measures 940 by 500 metres")
	_expect(bike.global_position.distance_to(WahatAlShams.START["position"]) < 0.5, "shift starts in front of bus station", str(bike.global_position))
	_expect(places.villas.size() == 504, "500 homes plus four delivery venues")
	var ids := {}
	var clusters := {}
	var good_homes := 0
	for home: Dictionary in places.villas:
		ids[home["number"]] = true
		if home.get("kind") == "spot":
			continue
		var counts: Dictionary = clusters.get(home["cluster"], {})
		counts[home["kind"]] = int(counts.get(home["kind"], 0)) + 1
		clusters[home["cluster"]] = counts
		var built: Node = places.find_child("Villa%d" % home["number"], true, false)
		if built != null and built.get_meta("house") == home["house"] and built.get_meta("batched", false):
			good_homes += 1
	_expect(ids.size() == 504 and good_homes == 500, "every stable address has its own built collision and identity")
	for id: String in clusters:
		_expect(clusters[id] == {"signature":2,"garden":8,"courtyard":90}, id + " has 90 courtyard, eight garden, two signature homes", str(clusters[id]))
	var rows: HousingRows = places.get_node("HousingRows")
	_expect(rows.row_count == 20 and rows.near_meshes.size() == 20 and rows.far_meshes.size() == 20, "joined rows use 20 detailed meshes and 20 distant versions")
	var grid := NavigationGrid.new()
	var before := Time.get_ticks_msec()
	grid.build(world.get_world_3d(), WahatAlShams.MAP_HALF, [bike, walker])
	print("NAV_SCAN_MS: ", Time.get_ticks_msec() - before, " blocked: ", grid.solid_count)
	var start := Vector2(WahatAlShams.START["position"].x, WahatAlShams.START["position"].z)
	var blocked: Array = []
	var unreachable: Array = []
	for home: Dictionary in places.villas:
		var number: int = home["number"]
		var approach := places.villa_approach(number)
		var door := places.villa_door(number)
		if not grid.is_free(Vector2(approach.x, approach.z)) or not grid.is_free(Vector2(door.x, door.z)):
			blocked.append(number)
		if not grid.can_reach(start, Vector2(door.x, door.z)):
			unreachable.append(number)
	_expect(blocked.is_empty(), "all 504 standing and approach points are clear", str(blocked))
	_expect(unreachable.is_empty(), "all 504 destinations are reachable from the bus station", str(unreachable))
	var inaccessible: Array = []
	var duplicate_decor := {}
	for shop: Dictionary in places.restaurants:
		var id: String = shop["id"]
		var approach := places.restaurant_approach(id)
		var counter := places.restaurant_counter(id)
		if not grid.is_free(Vector2(counter.x, counter.z)) or grid.path(Vector2(approach.x, approach.z), Vector2(counter.x, counter.z)).is_empty():
			inaccessible.append(id)
		if shop.get("interior", false):
			var room: Node = places.get_node("Restaurant_" + id)
			duplicate_decor[room.get_meta("venue_type")] = true
	_expect(inaccessible.is_empty(), "every pickup counter has a clear walk-in route", str(inaccessible))
	_expect(duplicate_decor.size() == 10, "all ten restaurants have distinct interior recipes")
	_expect(world.get_node("PlaceBuilder/Institute").get_meta("walk_in") and world.get_node("PlaceBuilder/Gym").get_meta("walk_in"), "institute and gym have real walk-in reception rooms")
	_expect(world.get_node("DistrictDetail").find_children("RollingHill*", "StaticBody3D", true, false).size() == WahatAlShams.HILLS.size() and WahatAlShams.HILLS.size() >= 4,
			"every smooth rideable spine hill in the data is built")
	_expect(world.get_node("SunCycle").find_child("HeatShimmer", true, false) == null, "heat shimmer is completely removed")
	_expect(world.get_node_or_null("ShopController") != null and places.get_node_or_null("Shop_bikes") != null and places.get_node_or_null("Shop_clothes") != null, "both walk-in shops are wired into ordinary gameplay")
	_expect(GameConfig.BIKE_MAX_SPEED_KMH == 28 and GameConfig.BIKE_SPRINT_MAX_SPEED_KMH == 36, "normal and sprint speed use 28 and 36 km/h")
	var road_conflicts: Array = []
	var parking_conflicts: Array = []
	for site: Rect2 in WahatAlShams.BUILDING_SITES:
		for road: Dictionary in WahatAlShams.ROADS:
			var a: Vector2 = road["from"]
			var b: Vector2 = road["to"]
			var bounds := Rect2(Vector2(minf(a.x,b.x), minf(a.y,b.y)), Vector2(absf(b.x-a.x), absf(b.y-a.y))).grow(road.get("width", WahatAlShams.ROAD_WIDTH) * 0.5)
			if site.grow(0.15).intersects(bounds):
				road_conflicts.append(road["name"])
		for park: Rect2 in WahatAlShams.PARKING_AREAS:
			if site.intersects(park):
				parking_conflicts.append(str(site))
	_expect(road_conflicts.is_empty(), "construction fences leave the full road network clear", str(road_conflicts))
	_expect(parking_conflicts.is_empty(), "construction sites do not occupy solar parking areas", str(parking_conflicts))
	var crossed: Array = []
	for cluster: Dictionary in WahatAlShams.CLUSTERS:
		var c: Vector2 = cluster["centre"]
		for offset in range(-60, 61):
			if not grid.is_free(Vector2(c.x+offset,c.y)):
				crossed.append(cluster["id"])
				break
	_expect(crossed.is_empty(), "each cluster has a reachable alley through its joined rows", str(crossed))
	_expect(places.get_node("Gym").get_meta("rounded_back", false), "gym has a rounded rear facade")
	var batches: Dictionary = world.get_node("DistrictDetail").get_meta("static_batch_report", {})
	_expect(batches.get("draws_saved", 0) > 0, "static scenery is batched without replacing collision nodes", str(batches))
	var walking: Node = world.get_node("OnFoot")
	bike.speed = 0.0
	_expect(walking.get_off(), "rider can get off beside the bus station")
	walker.global_position = places.villa_door(600)
	world.get_node("ShiftManager").start_next_shift()
	_expect(not walking.on_foot and dm.actor == bike and world.get_node("FollowCamera").target == bike \
		and bike.global_position.distance_to(WahatAlShams.START["position"]) < 0.1,
		"next shift reunites the rider, bike and camera at the bus station")
	state.equipped_cosmetics = {"head":"caps_sunset", "tops":"tops_sand"}
	var clinic: Node = world.get_node("ClinicScreen")
	clinic.open({"hospital":60,"repair":35,"paid":8,"insured":true,"insured_cap":8,"boss":false,"lost_order":false,
		"impact":{"what":"a wall","kmh":22,"severity":"moderate"}}, true)
	var patient: Person = clinic._patient
	_expect(patient.get_node("Wardrobe").get_child_count() > 0 \
		and patient._colours["shirt"] == GearCatalog.find("tops_sand")["colour"],
		"existing clinic patient refreshes clothes bought after the room was built")
	clinic.close()
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " detail world · ", checks, " checks · ", failures.size(), " failures")
	SaveGame.delete(state.save_path)
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
