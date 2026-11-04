extends SceneTree
## Session 53: the layout check. Builds Wahat Al Shams and looks for things that overlap,
## float or face the wrong way: the kind of bugs Louis found on 4 November (a sign in the
## middle of a road, lanes drawn over the ring road, the farm stall on a farm bed, a hill
## over the lap pool, the stream drawn over paths, benches facing the wrong way).
## Run it on its own:  Godot --path . --headless -s tests/layout_test.gd
## The smoke test runs the quick part (check_map) too.
const WahatBuilder := preload("res://scripts/wahat_builder.gd")
var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	for line in check_map(load("res://data/wahat_al_shams.gd").get_script_constant_map(), world):
		_expect(line[0], line[1])
	quit(1 if _failed else 0)


## Every rule. Returns [[passed, message], ...] so the smoke test can reuse it.
static func check_map(map: Dictionary, world: Node3D) -> Array:
	var results: Array = []
	var roads: Array = map["ROADS"]
	var width: float = map["ROAD_WIDTH"]
	# 1) Cluster signs: never in a road, posts never inside each other's.
	var in_road: Array[String] = []
	var crowded: Array[String] = []
	var boards: Array = []
	var signs := world.get_node_or_null("WahatBuilder/ClusterSigns")
	if signs != null:
		boards = signs.get_children()
	for board: Node3D in boards:
		var p := Vector2(board.global_position.x, board.global_position.z)
		var along := absf(board.global_transform.basis.x.x) > 0.5   # board runs along x
		var half := Vector2(ClusterSigns.BOARD.x * 0.5 + 0.1, 0.15) if along else Vector2(0.15, ClusterSigns.BOARD.x * 0.5 + 0.1)
		if ClusterSigns.touches_road(map, Rect2(p - half, half * 2.0)):
			in_road.append("%s at (%d, %d)" % [board.name, p.x, p.y])
		for other: Node3D in boards:
			if other != board and Vector2(other.global_position.x, other.global_position.z).distance_to(p) < 3.0:
				crowded.append(String(board.name))
	results.append([in_road.is_empty() and boards.size() == 10, "every cluster has 2 signs and none stands in a road %s" % [in_road]])
	results.append([crowded.is_empty(), "no two cluster signs stand on top of each other %s" % [crowded]])
	# 2) Flat things that must not overlap: beds, pools, hives, the donkey pen, courts, the gym.
	var keep_clear := {
		"lap pool": map["LAP_POOL"], "community pool": map["COMMUNITY_POOL"], "beehives": map["BEEHIVES"],
		"donkey pen": map["DONKEY_PEN"]["area"], "basketball court": map["BASKETBALL_COURT"],
		"playground": map["PLAYGROUND"], "gym": _footprint(map["GYM"]["position"], map["GYM"]["size"], map["GYM"]["facing"]),
	}
	for i in map["FARM_BEDS"].size():
		keep_clear["farm bed %d" % (i + 1)] = map["FARM_BEDS"][i]
	var stall := {}
	for shop: Dictionary in map["RESTAURANTS"]:
		if shop.get("style", "") == "stall":
			stall = shop
	var stall_rect := _footprint(stall["position"], stall["size"], stall["facing"])
	var stall_hits: Array[String] = []
	for name: String in keep_clear:
		if (keep_clear[name] as Rect2).intersects(stall_rect):
			stall_hits.append(name)
	results.append([stall_hits.is_empty(), "the farm stall stands clear of beds, pools and courts %s" % [stall_hits]])
	keep_clear["farm stall"] = stall_rect
	# 3) Hills: at most 0.5 m, 4 m clear of all of the above, never on a road.
	var hill_hits: Array[String] = []
	var too_tall: Array[String] = []
	for hill: Dictionary in map["HILLS"]:
		var c := Vector2(hill["position"].x, hill["position"].z)
		if float(hill["height"]) > GameConfig.HILL_MAX_HEIGHT + 0.001:
			too_tall.append("(%d, %d) %.1f m" % [c.x, c.y, hill["height"]])
		var reach: float = hill.get("radius", GameConfig.HILL_RADIUS)   # Session 63: hills have their own size
		for name: String in keep_clear:
			if _circle_hits(c, reach + GameConfig.HILL_CLEARANCE, keep_clear[name]):
				hill_hits.append("hill (%d, %d) and %s" % [c.x, c.y, name])
		for road: Dictionary in roads:
			if _circle_hits(c, reach - 0.01, ClusterSigns.road_rect(road, width)):
				hill_hits.append("hill (%d, %d) and %s" % [c.x, c.y, road["name"]])
	results.append([too_tall.is_empty(), "every hill is at most %.1f m high %s" % [GameConfig.HILL_MAX_HEIGHT, too_tall]])
	results.append([hill_hits.is_empty(), "hills keep clear of pools, beds, the gym, the stall and roads %s" % [hill_hits]])
	# 4) Black roads win: no other path is drawn onto the ring road, gate roads or bus road.
	var over_black: Array[String] = []
	for road: Dictionary in roads:
		if WahatBuilder.is_black_road(road):
			continue
		var drawn := _drawn_rect(map, road)
		for black: Dictionary in roads:
			if not WahatBuilder.is_black_road(black):
				continue
			if _shares_end(road, black):
				continue   # a path that carries straight on from the end of a black road (the Plaza Link)
			var overlap := drawn.intersection(ClusterSigns.road_rect(black, width))
			if overlap.size.x > 0.1 and overlap.size.y > 0.1:
				over_black.append("%s onto %s" % [road["name"], black["name"]])
	results.append([over_black.is_empty(), "no lane or path is drawn over a black road %s" % [over_black]])
	# 5) Every path end leads somewhere: another road, a plaza, paving or a building.
	var dead_ends: Array[String] = []
	for road: Dictionary in roads:
		for end: Vector2 in [road["from"], road["to"]]:
			if not _end_leads_somewhere(map, road, end):
				dead_ends.append("%s at (%d, %d)" % [road["name"], end.x, end.y])
	results.append([dead_ends.is_empty(), "every path end joins another path, a plaza or a building %s" % [dead_ends]])
	# 6) A bridge wherever a path crosses the stream.
	var bridges := world.get_node_or_null("WahatBuilder/Bridges")
	var spots := WahatBuilder.bridge_spots(map)
	var missing := 0
	for spot in spots:
		var found := false
		if bridges != null:
			for bridge: Node3D in bridges.get_children():
				found = found or Vector2(bridge.position.x, bridge.position.z).distance_to(Vector2(spot.x, spot.z)) < 1.0
		if not found:
			missing += 1
	results.append([spots.size() >= 2 and missing == 0, "a bridge at all %d places a path crosses the stream" % spots.size()])
	# 7) Benches face what they're for.
	var wrong: Array[String] = []
	var fountain := Vector2(map["PLAZA"]["centre"])
	for bench: Dictionary in map["PLAZA_BENCHES"]:
		if not _faces(bench, fountain):
			wrong.append("Plaza bench at (%d, %d)" % [bench["position"].x, bench["position"].z])
	for plaza: Dictionary in map["MINI_PLAZAS"]:
		var play := Vector2(plaza["playground"].x, plaza["playground"].z)
		for bench: Dictionary in plaza["benches"]:
			if not _faces(bench, play):
				wrong.append("%s bench" % plaza["cluster"])
	results.append([wrong.is_empty(), "benches face the fountain or the playground %s" % [wrong]])
	var shop_benches := 0
	var facing_shop := 0
	for shop: Dictionary in map["RESTAURANTS"]:
		var venue := world.get_node_or_null("PlaceBuilder/Restaurant_" + shop["id"])
		if venue == null:
			continue
		for child in venue.get_children():
			if child is StaticBody3D and String(child.name).begins_with("Bench") and child.position.z > 0.0:   # the outside benches
				shop_benches += 1
				var looks: Vector3 = child.global_transform.basis.z   # a bench's seat looks along +z
				var out: Vector3 = (child.global_position - venue.global_position) * Vector3(1, 0, 1)
				if looks.dot(out.normalized()) < 0.5:
					facing_shop += 1
	results.append([shop_benches >= 10 and facing_shop == 0,
			"the benches outside the shops look out at the Plaza, not at the glass (%d benches)" % shop_benches])
	# Session 65: no palm stands in a road or path (buggies had to drive round one on C1 Link).
	var palm_hits := []
	for palm: Vector3 in map.get("PALM_TREES", []):
		var spot := Vector2(palm.x, palm.z)
		for road: Dictionary in map["ROADS"]:
			var near := Geometry2D.get_closest_point_to_segment(spot, road["from"], road["to"])
			if spot.distance_to(near) < float(road.get("width", 6.0)) * 0.5:
				palm_hits.append("%s in %s" % [spot, road["name"]])
	results.append([palm_hits.is_empty(), "no palm stands in a road or path %s" % [palm_hits]])
	return results


static func _footprint(position: Vector3, size: Vector3, facing: float) -> Rect2:
	var turned := absf(sin(deg_to_rad(facing))) > 0.5
	var half := Vector2(size.z, size.x) * 0.5 if turned else Vector2(size.x, size.z) * 0.5
	return Rect2(Vector2(position.x, position.z) - half, half * 2.0)


static func _circle_hits(c: Vector2, radius: float, area: Rect2) -> bool:
	var nearest := Vector2(clampf(c.x, area.position.x, area.end.x), clampf(c.y, area.position.y, area.end.y))
	return nearest.distance_to(c) < radius


## A road's area as WahatBuilder draws it (ends at a black road aren't stretched).
static func _drawn_rect(map: Dictionary, road: Dictionary) -> Rect2:
	var w: float = road.get("width", map["ROAD_WIDTH"])
	var a: Vector2 = road["from"]
	var b: Vector2 = road["to"]
	if a.distance_to(b) < 0.01:
		return Rect2(a, Vector2.ZERO)
	var dir := (b - a).normalized()
	var start := a - dir * (0.0 if WahatBuilder.ends_on_black_road(map, a) else w * 0.5)
	var finish := b + dir * (0.0 if WahatBuilder.ends_on_black_road(map, b) else w * 0.5)
	var side := Vector2(-dir.y, dir.x) * w * 0.5
	return Rect2(start + side, Vector2.ZERO).expand(start - side).expand(finish + side).expand(finish - side)


static func _end_leads_somewhere(map: Dictionary, road: Dictionary, end: Vector2) -> bool:
	for other: Dictionary in map["ROADS"]:
		if other != road and ClusterSigns.road_rect(other, map["ROAD_WIDTH"]).grow(0.5).has_point(end):
			return true
	var plaza: Dictionary = map["PLAZA"]
	if end.distance_to(plaza["centre"]) <= float(plaza["radius"]) + 1.0:
		return true
	for area: Rect2 in map["PAVED_AREAS"] + map["PARKING_AREAS"] + map["BUILDING_SITES"]:
		if area.grow(1.0).has_point(end):
			return true
	for plot: Dictionary in map["PLOTS"]:
		if (plot["area"] as Rect2).grow(1.0).has_point(end):
			return true
	if (map["BUS_STATION"]["area"] as Rect2).grow(1.0).has_point(end):
		return true
	for shop: Dictionary in map.get("SHOPS", []):   # a path that leads to a shop's door
		if Vector2(shop["position"].x, shop["position"].z).distance_to(end) <= 15.0:
			return true
	for dome: Vector3 in map["SPINE_DOMES"]:
		if Vector2(dome.x, dome.z).distance_to(end) <= float(map["DOME_RADIUS"]) + 8.0:
			return true
	var edge: Vector2 = map["MAP_HALF"]
	return absf(end.x) >= edge.x - 10.0 or absf(end.y) >= edge.y - 10.0   # the gates and the highway


static func _shares_end(a: Dictionary, b: Dictionary) -> bool:
	for p: Vector2 in [a["from"], a["to"]]:
		for q: Vector2 in [b["from"], b["to"]]:
			if p.distance_to(q) < 0.5:
				return true
	return false


static func _faces(bench: Dictionary, target: Vector2) -> bool:
	var facing := deg_to_rad(float(bench["facing"]))
	var looks := Vector2(sin(facing), cos(facing))   # 0 = south (+z), 90 = east (+x)
	var at := Vector2(bench["position"].x, bench["position"].z)
	return looks.dot((target - at).normalized()) > cos(deg_to_rad(60.0))


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
