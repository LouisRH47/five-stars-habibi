extends SceneTree
## Fixed routes and physical separation, using an isolated user-data copy.

var _failures := 0
var _count := 0


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://district_traffic_test_save.json"
	_run.call_deferred()


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.reset()
	gs.tutorial_done = true
	var world := Node3D.new()
	root.add_child(world)
	var bike := Node3D.new()
	bike.name = "Bike"
	bike.add_to_group("bike")
	bike.position = Vector3(-1000, 0, -1000)
	world.add_child(bike)
	var traffic: Node3D = load("res://scripts/district_traffic.gd").new()
	traffic.data = WahatAlShams
	world.add_child(traffic)
	_check("every car park has a moving car route", traffic.cars.size() == 4 + WahatAlShams.PARKING_AREAS.size())
	var bays := WahatAlShams.PARKED_CARS.filter(func(place): return place["bay"]).size()
	_check("all marked bays and visiting car bays have a solar roof", traffic.solar_bays == bays + WahatAlShams.PARKING_AREAS.size())
	_check("both horse-track edges and the arena have rails", traffic.rail_segments >= 16)
	for car in traffic.cars:
		var safe := true
		for point in car.points:
			var on_ring := _ring_distance(point) <= 3.0
			var in_park := false
			for area: Rect2 in WahatAlShams.PARKING_AREAS:
				var to_road := area.expand(Vector2(area.position.x, -205 if area.get_center().y < 0 else 205))
				if to_road.grow(0.2).has_point(Vector2(point.x, point.z)):
					in_park = true
			if not on_ring and not in_park:
				safe = false
		for i in car.points.size() - 1:
			var gap: Vector3 = car.points[i + 1] - car.points[i]
			if absf(gap.x) > 0.01 and absf(gap.z) > 0.01:
				safe = false
		_check("%s uses only ring road and its parking access" % car.name, safe)
	var first: Node3D = traffic.cars[0]
	bike.position = first.position + first.heading() * 5.0
	var before := first.position
	first._physics_process(1.0)
	_check("a car stops before the bike", first.position == before and not first.moving)
	bike.position = Vector3(-1000, 0, -1000)
	first._physics_process(1.0)
	_check("the car continues when its route is clear", first.position != before and first.moving)
	_check("vehicles expose a hard material and temporary navigation group", first.is_in_group("critter") and CrashImpact.category_for(first) == "vehicle")
	for line: Dictionary in WahatAlShams.BUGGIES:
		var inside := true
		for point: Vector3 in line["points"]:
			if _ring_distance(point) <= 7.0:
				inside = false
		_check("buggy route stays off the ring road", inside)
		var clear := true
		for i in line["points"].size() - 1:
			var a: Vector3 = line["points"][i]
			var b: Vector3 = line["points"][i + 1]
			for home: Dictionary in WahatAlShams.VILLAS:
				if home.get("kind", "") == "spot":
					continue
				var centre: Vector3 = home["position"]
				var size: Vector3 = home["size"]
				var area := Rect2(Vector2(centre.x - size.z * 0.5, centre.z - size.x * 0.5), Vector2(size.z, size.x)).grow(0.8)
				if _intersects_box(Vector2(a.x, a.z), Vector2(b.x, b.z), area):
					clear = false
		_check("buggy route clears every joined home", clear)
	_check("the first bus waits at the station", traffic.bus_arrivals == 1 and traffic.buses[0]._wait_left > 0)
	gs.shift_time_left = GameConfig.SHIFT_LENGTH - 59.0
	traffic._physics_process(0.0)
	_check("the next bus approaches in time for the next game hour", traffic.bus_arrivals == 2)
	traffic._physics_process(0.0)
	_check("one game hour cannot spawn duplicate buses", traffic.bus_arrivals == 2)
	gs.shift_time_left = GameConfig.SHIFT_LENGTH - 119.0
	traffic._physics_process(0.0)
	_check("another game hour schedules the following bus", traffic.bus_arrivals == 3)
	var horse: Node3D = traffic.arena_horse
	horse.start_at(0, 0, true)
	horse.position = horse.jumps[0] + Vector3.LEFT * 2.0
	horse._physics_process(0.1)
	_check("the arena horse visibly clears a jump", horse.jump_height > 0.7 and horse.model.position.y > 0.7)
	await physics_frame
	await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(Vector3(-440, 0.7, 0), Vector3(-458, 0.7, 0))
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	_check("solid rails prevent the bike entering the horse track", not hit.is_empty() and (hit["collider"] as Node).has_meta("impact_name"))
	for gate: Dictionary in WahatAlShams.GATES:
		var z: float = gate["position"].z
		ray.from = Vector3(-440, 0.7, z)
		ray.to = Vector3(-458, 0.7, z)
		hit = world.get_world_3d().direct_space_state.intersect_ray(ray)
		_check("checkpoint road has a gap through both horse rails", hit.is_empty())
	var obstacles: Node3D = load("res://scripts/obstacle_builder.gd").new()
	obstacles.data = WahatAlShams
	world.add_child(obstacles)
	_check("all named cats carry their collection identity", obstacles.get_node("Cat_0").get_meta("collection_id", "") == WahatAlShams.CATS[0]["collection_id"])
	var life: Node3D = load("res://scripts/life_builder.gd").new()
	life.data = WahatAlShams
	var decor := Node3D.new()
	decor.name = "DecorBuilder"
	world.add_child(decor)
	var map_builder := Node3D.new()
	map_builder.name = "WahatBuilder"
	world.add_child(map_builder)
	world.add_child(life)
	_check("named horses carry their collection identity", life.get_node("Horse_0").get_meta("collection_id", "") == WahatAlShams.HORSE_RIDERS[0]["collection_id"])
	world.queue_free()
	await process_frame
	gs._save_waiting = false
	SaveGame.delete(gs.save_path)
	print("TRAFFIC RESULT: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _count])
	quit(0 if _failures == 0 else 1)


func _ring_distance(point: Vector3) -> float:
	var nearest := INF
	for road: Dictionary in WahatAlShams.ROADS:
		if road.get("name", "") == "Ring Road":
			nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(Vector2(point.x, point.z), road["from"], road["to"]).distance_to(Vector2(point.x, point.z)))
	return nearest


func _intersects_box(a: Vector2, b: Vector2, box: Rect2) -> bool:
	if box.has_point(a) or box.has_point(b):
		return true
	var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false


func _check(label: String, good: bool) -> void:
	_count += 1
	print("%s: %s" % ["PASS" if good else "FAIL", label])
	if not good:
		_failures += 1
