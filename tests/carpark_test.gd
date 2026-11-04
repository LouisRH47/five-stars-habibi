extends SceneTree
## Session 62: the car parks and kerbs. Builds Wahat Al Shams and checks Louis's rows
## (1 row, 2 back to back, 1 row), a solar roof over every row, the kerbs, the buggy lanes,
## that nothing overlaps, that the parked cars stand inside their bays and that real-life
## distances hold (every car park hugs its cluster; homes are at most 85 m from a car park).
## The 8th car park (Cluster 3 East) is turned: its rows run east-west ("turned": true). The
## layout checks look at it with x and z swapped (_flip), so the same rules apply to it.
## Run it on its own:  Godot --path . --headless -s tests/carpark_test.gd
const WahatBuilder := preload("res://scripts/wahat_builder.gd")
const MAX_WALK := 85.0       # real car parks are at most 85 m from any home
const MAX_GAP := 3.5         # kerb + buggy lane + kerb between a cluster and its car park
const MAX_WALK_NO_LAND := 115.0   # C3's far east homes, with no free land within 85 m (were up to 120 m)
var _failed := false
var _count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	_check_layout(map)
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	_check_built(map, world)
	print("CARPARK RESULT: %s (%d checks)" % ["FAIL" if _failed else "PASS", _count])
	print("RESULT: %s" % ["FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)


## Checks on the map data alone.
func _check_layout(map: Dictionary) -> void:
	var parks: Array = map["CAR_PARKS"]
	_expect(parks.size() >= 7 and parks.size() == map["PARKING_AREAS"].size(), "%d car parks, one parking area each" % parks.size())
	var bad_rows: Array[String] = []
	var overlaps: Array[String] = []
	var fill: Array[String] = []
	var bays_total := 0
	for park: Dictionary in parks:
		park = _flat(park)
		var rows: Array = park["rows"].duplicate()
		rows.sort_custom(func(a, b): return (a["area"] as Rect2).position.x < (b["area"] as Rect2).position.x)
		# the pattern across the rows: "|" back to back, "a" an aisle between
		var pattern := ""
		for i in rows.size() - 1:
			var gap := (rows[i + 1]["area"] as Rect2).position.x - (rows[i]["area"] as Rect2).end.x
			pattern += "|" if absf(gap) < 0.01 else ("a" if gap >= 5.5 and gap <= 7.5 else "?")
		var wanted := ["a|a"] if park["kind"] == "full" else ["a|a", "|a", "a|"]
		if not pattern in wanted or (park["kind"] == "full" and rows.size() != 4) or rows.size() < 3:
			bad_rows.append("%s: %s" % [park["name"], pattern])
		for row: Dictionary in rows:
			var area: Rect2 = row["area"]
			if absf(area.size.x - 5.0) > 0.01 or absf(area.size.y - 2.5 * int(row["bays"])) > 0.01:
				bad_rows.append("%s row is %s" % [park["name"], area.size])
			for other: Dictionary in rows:
				if other != row and _overlap((other["area"] as Rect2), area):
					overlaps.append("%s rows" % park["name"])
			for aisle: Rect2 in park["aisles"]:
				if _overlap(aisle, area):
					overlaps.append("%s row and aisle" % park["name"])
			bays_total += int(row["bays"])
	_expect(bad_rows.is_empty(), "every car park is 1 row, an aisle, 2 rows back to back, an aisle, 1 row (or the narrow 1-2 in the 29 m gaps), bays 2.5 x 5 m %s" % [bad_rows])
	_expect(overlaps.is_empty(), "no row overlaps another row or an aisle (so no bay overlaps another) %s" % [overlaps])
	# Roofs: every row is under a solar roof.
	var bare: Array[String] = []
	for park: Dictionary in parks:
		for row: Dictionary in park["rows"]:
			var covered := false
			for roof: Dictionary in park["roofs"]:
				covered = covered or (roof["area"] as Rect2).encloses(row["area"])
			if not covered:
				bare.append(park["name"])
	_expect(bare.is_empty(), "every row has a solar roof in the data %s" % [bare])
	# Parked cars: inside a bay of their own car park, one per bay, the visitor's bay kept free.
	var by_bay := {}
	var outside: Array[String] = []
	var per_park := {}
	for car: Dictionary in map["PARKED_CARS"]:
		if not car.has("park"):
			continue
		var park: Dictionary = _flat(parks[int(car["park"])])
		var spot := Vector2(car["position"].x, car["position"].z)
		var half := Vector2(0.95, 2.15) if absf(sin(deg_to_rad(float(car["facing"])))) < 0.5 else Vector2(2.15, 0.95)
		if park.get("turned", false):
			spot = Vector2(spot.y, spot.x)
			half = Vector2(half.y, half.x)
		var body := Rect2(spot - half, half * 2.0)
		var in_bay := false
		for row: Dictionary in park["rows"]:
			var area: Rect2 = row["area"]
			if area.encloses(body):
				var bay := floori((spot.y - area.position.y) / 2.5)
				var bay_rect := Rect2(area.position.x, area.position.y + bay * 2.5, area.size.x, 2.5)
				in_bay = bay_rect.encloses(body)
				var key := "%d_%d_%d" % [int(car["park"]), roundi(area.position.x * 10), bay]
				by_bay[key] = by_bay.get(key, 0) + 1
		if not in_bay:
			outside.append("car at (%.1f, %.1f)" % [spot.x, spot.y])
		per_park[int(car["park"])] = per_park.get(int(car["park"]), 0) + 1
		var visitor: Vector3 = parks[int(car["park"])]["visitor"]["bay"]
		if Vector2(visitor.x, visitor.z).distance_to(Vector2(car["position"].x, car["position"].z)) < 2.0:
			outside.append("a car in the visitor's bay")
	var doubled := by_bay.values().filter(func(n): return n > 1).size()
	_expect(outside.is_empty() and doubled == 0, "every parked car stands inside one bay, one car per bay, the visitor's bay free %s" % [outside.slice(0, 5)])
	for i in parks.size():
		var bays := 0
		for row: Dictionary in parks[i]["rows"]:
			bays += int(row["bays"])
		var share := float(per_park.get(i, 0)) / bays
		if share < 0.4 or share > 0.6:
			fill.append("%s %d%%" % [parks[i]["name"], roundi(share * 100)])
	_expect(fill.is_empty(), "40 to 60%% of the bays have a car (%d bays, %d cars) %s" % [bays_total, map["PARKED_CARS"].size(), fill])
	# Tight against the cluster: the car park starts within 3.5 m of its cluster's outside lane.
	var loose: Array[String] = []
	for park: Dictionary in parks:
		if park.get("turned", false):
			# Cluster 3 East is in the spine lawn: it hugs the path into its cluster instead
			var path := _nearest_cluster_path(map, park)
			if path.y > MAX_GAP + 0.01:
				loose.append("%s to the path into %s: %.1f m" % [park["name"], park["clusters"][0], path.y])
			continue
		var area: Rect2 = park["area"]
		for id: String in park["clusters"]:
			var centre := _cluster_centre(map, id)
			var gap := minf(absf(area.position.x - (centre.x + 63.0)), absf(area.end.x - (centre.x - 63.0)))
			var nearest_row := INF
			for row: Dictionary in park["rows"]:
				var r: Rect2 = row["area"]
				nearest_row = minf(nearest_row, minf(absf(r.position.x - (centre.x + 63.0)), absf(r.end.x - (centre.x - 63.0))))
			if gap > MAX_GAP + 0.01:
				loose.append("%s to %s: %.1f m" % [park["name"], id, gap])
			if park["kind"] == "full" and nearest_row > MAX_GAP + 0.01:
				loose.append("%s first row to %s: %.1f m" % [park["name"], id, nearest_row])
	_expect(loose.is_empty(), "every car park is within %.1f m of its cluster (just a kerb and a buggy lane; Cluster 3 East: of the path into C3) %s" % [MAX_GAP, loose])
	# 85 m from every home (the real community's rule). Cluster 3's homes run right up to the
	# ring road, so the only free land for its east homes is the spine lawn's north-east corner
	# (up to the ring road kerb), where Cluster 3 East Parking now is. A home may only be further
	# than 85 m if even that free land is further than 85 m from it (the far, north end of C3's
	# east rows): then it must still be no further than before (MAX_WALK_NO_LAND).
	var ring_kerb := 425.0 - float(map["ROAD_WIDTH"]) * 0.5
	var corner: Rect2 = GameConfig.SPINE_FREE_CORNER
	var free_land := corner.expand(Vector2(ring_kerb, corner.end.y))
	var far: Array[String] = []
	var no_land: Array[String] = []
	var worst := 0.0
	for home: Dictionary in map["VILLAS"]:
		if home.get("kind", "") == "spot":
			continue
		var p := Vector2(home["position"].x, home["position"].z)
		var best := INF
		for area: Rect2 in map["PARKING_AREAS"]:
			best = minf(best, _distance(p, area))
		if best <= MAX_WALK:
			continue
		if home["cluster"] == "C3" and _distance(p, free_land) > MAX_WALK and best <= MAX_WALK_NO_LAND:
			no_land.append(home["map_address"])
			worst = maxf(worst, best)
		else:
			far.append("%s %d m" % [home["map_address"], roundi(best)])
	_expect(far.is_empty(), "every home is within %d m of a car park, unless no free land is that close (C3's 29 east homes were up to 120 m) %s" % [MAX_WALK, far])
	_expect(no_land.size() <= 12, "Cluster 3 East Parking brings C3's far east homes down to %d (from 29), none over %d m" % [no_land.size(), MAX_WALK_NO_LAND])
	if not no_land.is_empty():
		print("NOTE: %d homes at the north end of C3's east rows are up to %d m from a car park: no free land within %d m of them (%s ... %s)" % [no_land.size(), roundi(worst), MAX_WALK, no_land[0], no_land[-1]])
	# Buggy lanes: both ends join another (non-black) road, never the ring road.
	var lanes := 0
	var loose_ends: Array[String] = []
	for road: Dictionary in map["ROADS"]:
		if not String(road["name"]).ends_with("Car Park Buggy Lane"):
			continue
		lanes += 1
		for end: Vector2 in [road["from"], road["to"]]:
			var joined := false
			for other: Dictionary in map["ROADS"]:
				if other == road:
					continue
				var hits := ClusterSigns.road_rect(other, 6.0).grow(0.5).has_point(end)
				if hits and WahatBuilder.is_black_road(other):
					loose_ends.append("%s touches %s" % [road["name"], other["name"]])
				joined = joined or (hits and not WahatBuilder.is_black_road(other))
			if not joined:
				loose_ends.append("%s at (%d, %d)" % [road["name"], end.x, end.y])
	_expect(lanes == parks.size() and loose_ends.is_empty(), "every car park's buggy lane joins a cluster lane and the spine road at its ends (%d lanes) %s" % [lanes, loose_ends])
	# Nothing overlaps: car parks and grass beds against roads, homes and buildings.
	var hits: Array[String] = []
	var solid := _buildings(map)
	for i in parks.size():
		var area: Rect2 = map["PARKING_AREAS"][i]
		for road: Dictionary in map["ROADS"]:
			if String(road["name"]).begins_with(String(parks[i]["clusters"][-1]) + " Car Park Buggy"):
				continue
			var cross := area.intersection(ClusterSigns.road_rect(road, 6.0))
			if cross.size.x > 0.05 and cross.size.y > 0.05:
				hits.append("%s and %s" % [parks[i]["name"], road["name"]])
		for name: String in solid:
			if (solid[name] as Rect2).intersects(area) and not _in_free_corner(name, solid[name], area):
				hits.append("%s and %s" % [parks[i]["name"], name])
	for bed: Rect2 in map["CARPARK_GARDENS"]:
		for name: String in solid:
			if (solid[name] as Rect2).intersects(bed) and not _in_free_corner(name, solid[name], bed):
				hits.append("grass bed %s and %s" % [bed, name])
		for road: Dictionary in map["ROADS"]:
			var cross := bed.intersection(ClusterSigns.road_rect(road, 6.0))
			if cross.size.x > 0.05 and cross.size.y > 0.05 and road["name"] != "Ring Road":
				hits.append("grass bed %s and %s" % [bed, road["name"]])
	_expect(hits.is_empty(), "no car park or grass bed overlaps a road, a home or a building %s" % [hits.slice(0, 6)])
	# Kerbs: along the cluster side of every car park, all the way along its rows.
	var no_kerb: Array[String] = []
	for park: Dictionary in parks:
		park = _flat(park)
		var area: Rect2 = park["area"]
		var rows_z := Vector2(minf(park["first_bay_z"], park["last_bay_z"]), maxf(park["first_bay_z"], park["last_bay_z"]))
		var found := false
		for kerb: Rect2 in map["CARPARK_KERBS"]:
			kerb = _swap(kerb) if park.get("turned", false) else kerb
			var on_edge := absf(kerb.position.x - area.position.x) < 0.01 or absf(kerb.end.x - area.end.x) < 0.01
			if on_edge and kerb.size.x <= 0.31 and kerb.position.y <= rows_z.x + 0.01 and kerb.end.y >= rows_z.y - 0.01:
				found = true
		if not found:
			no_kerb.append(park["name"])
	_expect(no_kerb.is_empty(), "kerbstones run between the homes and every car park, all along its rows %s" % [no_kerb])
	var ring := Kerbs.ring_segments(map)
	var length := 0.0
	var blocking: Array[String] = []
	for kerb in ring:
		length += maxf(kerb.size.x, kerb.size.y)
		for park: Dictionary in parks:
			for aisle: Rect2 in park["aisles"]:
				if aisle.intersects(kerb):
					blocking.append("%s aisle" % park["name"])
	for road: Dictionary in map["ROADS"]:
		if WahatBuilder.is_black_road(road):
			continue
		for end: Vector2 in [road["from"], road["to"]]:
			if not WahatBuilder.ends_on_black_road(map, end):
				continue
			var opening := ClusterSigns.road_rect(road, 6.0).grow(-0.1)
			for kerb in ring:
				if opening.intersects(kerb):
					blocking.append("%s at (%d, %d)" % [road["name"], end.x, end.y])
	_expect(length > 4000.0 and blocking.is_empty(), "kerbstones along both sides of the ring road (%d m), open at every lane and car park entrance %s" % [length, blocking.slice(0, 5)])


## Checks on the built world.
func _check_built(map: Dictionary, world: Node3D) -> void:
	var traffic := world.get_node("DistrictTraffic")
	var holder := traffic.get_node_or_null("CarParks")
	_expect(holder != null, "the car parks are built")
	if holder == null:
		return
	var roofs := 0
	var low_high: Array[String] = []
	for child in holder.get_children():
		if String(child.name).begins_with("SolarRoof_"):
			roofs += 1
			var view: MeshInstance3D = child.get_node("Roof")
			var box: AABB = view.global_transform * view.get_aabb()
			if box.end.y < GameConfig.CARPARK_ROOF_HIGH or box.end.y > GameConfig.CARPARK_ROOF_HIGH + 0.4 or box.position.y > 0.1:
				low_high.append("%s %.2f..%.2f" % [child.name, box.position.y, box.end.y])
	var wanted := 0
	for park: Dictionary in map["CAR_PARKS"]:
		wanted += park["roofs"].size()
	_expect(roofs == wanted and traffic.solar_bays == wanted, "every row has its solar roof built (%d roofs)" % roofs)
	_expect(low_high.is_empty(), "solar roofs stand on posts from the ground up to about 3 m %s" % [low_high.slice(0, 3)])
	# Roofs really are above the bays: a ray straight down over a bay hits the roof first.
	var space := world.get_world_3d().direct_space_state
	var posts_in_aisles: Array[String] = []
	for child in holder.get_children():
		if not child is StaticBody3D:
			continue
		for shape in child.get_children():
			if shape is CollisionShape3D:
				var p: Vector3 = (shape as CollisionShape3D).global_position
				for park: Dictionary in map["CAR_PARKS"]:
					for aisle: Rect2 in park["aisles"]:
						if aisle.grow(-0.05).has_point(Vector2(p.x, p.z)):
							posts_in_aisles.append("%s at (%.1f, %.1f)" % [child.name, p.x, p.z])
	_expect(posts_in_aisles.is_empty(), "no roof post, charger or sign stands in an aisle %s" % [posts_in_aisles.slice(0, 4)])
	var covered := 0
	var tried := 0
	for park: Dictionary in map["CAR_PARKS"]:
		for row: Dictionary in park["rows"]:
			var area: Rect2 = row["area"]
			tried += 1
			if _roof_over(holder, area.get_center()):
				covered += 1
	_expect(covered == tried, "a solar roof is overhead in the middle of every row (%d of %d)" % [covered, tried])
	var chargers := 0
	var signs := 0
	for child in holder.get_children():
		chargers += 1 if String(child.name).begins_with("EVCharger_") else 0
		signs += 1 if String(child.name).begins_with("CarParkSign_") else 0
	_expect(chargers >= 2 * map["CAR_PARKS"].size() and signs == map["CAR_PARKS"].size(), "electric car chargers (%d) and a bilingual sign at every car park (%d)" % [chargers, signs])
	_expect(holder.get_node_or_null("CarParkKerbs") != null and holder.get_node_or_null("RingRoadKerbs") != null, "the car park kerbs and the ring road kerbs are built")
	# Parked cars: a solid body each (DecorBuilder) and drawn together (CarParkCars).
	var decor := world.get_node("DecorBuilder")
	var bodies := 0
	for i in map["PARKED_CARS"].size():
		if decor.get_node_or_null("ParkedCar_%d" % i) != null:
			bodies += 1
	var looks := traffic.get_node_or_null("ParkedCarLooks")
	var drawn: int = looks.drawn if looks != null else 0
	_expect(bodies == map["PARKED_CARS"].size() and (drawn == bodies or not GameConfig.CARPARK_CAR_BATCH),
			"every parked car has a solid body (%d) and is drawn (%d)" % [bodies, drawn])
	# Visiting cars drive in and out through the aisle only, never on a buggy lane.
	var on_buggy: Array[String] = []
	var visitors := 0
	for car: TrafficVehicle in traffic.cars:
		var route: Array[Vector3] = car.points
		if car.stop_index < 0:
			continue
		visitors += 1
		for i in route.size() - 1:
			for road: Dictionary in map["ROADS"]:
				if String(road["name"]).contains("Buggy") and _segment_hits(route[i], route[i + 1], _road_body(road).grow(1.0)):
					on_buggy.append("%s on %s" % [car.name, road["name"]])
	_expect(visitors == map["CAR_PARKS"].size() and on_buggy.is_empty(), "a visiting car drives in and out of every car park, never on a buggy lane %s" % [on_buggy.slice(0, 3)])
	# Street furniture (ring road lamp posts, the bike racks) never stands in an aisle.
	var lamps_in: Array[String] = []
	var furniture := world.get_node("DistrictDetail").get_node_or_null("StreetFurniture")
	if furniture != null:
		for part in furniture.get_children():
			if part is MeshInstance3D and (part as MeshInstance3D).get_aabb().size.y > 0.3:
				var p := Vector2(part.position.x, part.position.z)
				for park: Dictionary in map["CAR_PARKS"]:
					for aisle: Rect2 in park["aisles"]:
						if aisle.has_point(p):
							lamps_in.append("(%d, %d)" % [p.x, p.y])
	_expect(lamps_in.is_empty(), "no lamp post, bike rack or ticket machine stands in a car park aisle %s" % [lamps_in])


## A turned car park (rows east-west) with x and z swapped, so its rows run along z like the
## others'. Other car parks come back unchanged.
func _flat(park: Dictionary) -> Dictionary:
	if not park.get("turned", false):
		return park
	var out := park.duplicate()
	out["area"] = _swap(park["area"])
	out["first_bay_z"] = park["first_bay_x"]
	out["last_bay_z"] = park["last_bay_x"]
	var rows: Array = []
	for row: Dictionary in park["rows"]:
		rows.append({"area": _swap(row["area"]), "facing": row["facing"], "bays": row["bays"]})
	out["rows"] = rows
	var roofs: Array = []
	for roof: Dictionary in park["roofs"]:
		roofs.append({"area": _swap(roof["area"]), "double": roof["double"]})
	out["roofs"] = roofs
	var aisles: Array = []
	for aisle: Rect2 in park["aisles"]:
		aisles.append(_swap(aisle))
	out["aisles"] = aisles
	return out


func _swap(r: Rect2) -> Rect2:
	return Rect2(r.position.y, r.position.x, r.size.y, r.size.x)


## Only the spine lawn's free corner (kept for Cluster 3 East Parking) may hold a car park.
func _in_free_corner(name: String, solid: Rect2, area: Rect2) -> bool:
	return name == "spine" and GameConfig.SPINE_FREE_CORNER.grow(0.01).encloses(solid.intersection(area))


## The non-black path nearest to a turned car park that leads into its cluster (it joins one
## of the cluster's lanes or its link): x = how many paths were found, y = the gap in metres.
func _nearest_cluster_path(map: Dictionary, park: Dictionary) -> Vector2:
	var id: String = park["clusters"][0]
	var area: Rect2 = park["area"]
	var best := INF
	var found := 0
	for road: Dictionary in map["ROADS"]:
		var name := String(road["name"])
		if WahatBuilder.is_black_road(road) or name.contains("Buggy") or name.begins_with(id):
			continue
		var r := ClusterSigns.road_rect(road, 6.0)
		var joins := false
		for lane: Dictionary in map["ROADS"]:
			var lane_name := String(lane["name"])
			if (lane_name == id + " Lane" or lane_name == id + " Link") and ClusterSigns.road_rect(lane, 6.0).intersects(r):
				joins = true
		if not joins:
			continue
		found += 1
		var dx := maxf(0.0, maxf(r.position.x - area.end.x, area.position.x - r.end.x))
		var dz := maxf(0.0, maxf(r.position.y - area.end.y, area.position.y - r.end.y))
		best = minf(best, Vector2(dx, dz).length())
	return Vector2(found, best)


## Overlapping by more than a centimetre (edges that only touch don't count).
func _overlap(a: Rect2, b: Rect2) -> bool:
	var cross := a.intersection(b)
	return cross.size.x > 0.01 and cross.size.y > 0.01


func _roof_over(holder: Node, spot: Vector2) -> bool:
	for child in holder.get_children():
		if String(child.name).begins_with("SolarRoof_"):
			var view: MeshInstance3D = child.get_node("Roof")
			var box: AABB = view.global_transform * view.get_aabb()
			if Rect2(box.position.x, box.position.z, box.size.x, box.size.z).has_point(spot) and box.end.y > 2.5:
				return true
	return false


func _buildings(map: Dictionary) -> Dictionary:
	var out := {}
	for home: Dictionary in map["VILLAS"]:
		var size: Vector3 = home["size"]
		var turned := absf(sin(deg_to_rad(float(home["facing"])))) > 0.5
		var half := Vector2(size.z, size.x) * 0.5 if turned else Vector2(size.x, size.z) * 0.5
		out["%s" % home["address"]] = Rect2(Vector2(home["position"].x, home["position"].z) - half, half * 2.0)
	for shop: Dictionary in map["RESTAURANTS"] + map["SHOPS"]:
		var size: Vector3 = shop.get("size", map["RESTAURANT_SIZE"])
		out[shop["name"]] = Rect2(Vector2(shop["position"].x, shop["position"].z) - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))
	for plot: Dictionary in map["PLOTS"]:
		out[plot["name"]] = plot["area"]
	for i in map["BUILDING_SITES"].size():
		out["building site %d" % i] = map["BUILDING_SITES"][i]
	out["bus station"] = map["BUS_STATION"]["area"]
	out["spine"] = map["SPINE"]
	return out


func _cluster_centre(map: Dictionary, id: String) -> Vector2:
	for cluster: Dictionary in map["CLUSTERS"]:
		if cluster["id"] == id:
			return cluster["centre"]
	return Vector2.ZERO


func _distance(p: Vector2, area: Rect2) -> float:
	var nearest := Vector2(clampf(p.x, area.position.x, area.end.x), clampf(p.y, area.position.y, area.end.y))
	return nearest.distance_to(p)


## The paved strip of a road, not past its ends (ClusterSigns.road_rect adds half a width at
## each end, so the Spine Buggy Road's would reach onto the ring road where the cars drive).
func _road_body(road: Dictionary) -> Rect2:
	var a: Vector2 = road["from"]
	var b: Vector2 = road["to"]
	var half: float = float(road.get("width", 6.0)) * 0.5
	var box := Rect2(a, Vector2.ZERO).expand(b)
	if absf(a.y - b.y) < 0.01:
		return box.grow_individual(0, half, 0, half)
	if absf(a.x - b.x) < 0.01:
		return box.grow_individual(half, 0, half, 0)
	return box.grow(half)


func _segment_hits(a: Vector3, b: Vector3, box: Rect2) -> bool:
	for i in 21:
		var p := a.lerp(b, i / 20.0)
		if box.has_point(Vector2(p.x, p.z)):
			return true
	return false


func _expect(ok: bool, message: String) -> void:
	_count += 1
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
