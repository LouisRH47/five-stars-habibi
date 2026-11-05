extends RefCounted
## World polish pass, Sessions 64 to 66 (signs wave), run by tests/smoke_test.gd:
## the bus stop and car parks (64), cluster entrance signs, end houses, bins and the pool
## sign (65), Majlis Gardens and the phase 3 building site (66). Wahat Al Shams only.

var _t: SceneTree
var _main: Node
var _data: Dictionary


func run(t: SceneTree) -> void:
	_t = t
	_main = t.get("_main")
	var builder := _main.get_node_or_null("WahatBuilder")
	if builder == null or not (builder.data as Script).get_script_constant_map().has("BUS_PLATFORM"):
		print("      not Wahat Al Shams, Sessions 64 to 66 not checked")
		return
	_data = (builder.data as Script).get_script_constant_map()
	_session64()
	_session65()
	_session66()


func _check(label: String, ok: bool, detail := "") -> void:
	_t.call("_check", label, ok, detail)


## Session 64: the bus station platform, people boarding, the stables and school car parks.
func _session64() -> void:
	var stop = _main.get_node_or_null("DistrictDetail/BusStop")
	_check("Session 64: the bus station platform has two shelters with glass, a route map, benches and a bin",
			stop != null and stop.shelters == 2 and stop.find_children("GlassBack", "", true, false).size() == 2
			and stop.find_children("RouteMap", "", true, false).size() == 2
			and stop.find_children("ShelterSign", "", true, false).size() == 2)
	if stop == null:
		return
	var platform: Rect2 = _data["BUS_PLATFORM"]["area"]
	var bay: Vector3 = _data["BUS_LOOP"]["bay"]
	var lane_edge := bay.x + 3.5  # the bay lane is 7 m wide
	_check("Session 64: the platform is right next to the bay lane, not in the road",
			platform.position.x > lane_edge and platform.position.x - lane_edge < 1.0 and platform.has_point(Vector2(platform.get_center().x, bay.z)),
			"%s, lane edge %.1f" % [platform, lane_edge])
	var ready_count: int = stop.waiting.filter(func(e): return e["state"] == "waiting").size()
	_check("Session 64: 3 to 5 people wait at the stop", stop.waiting.size() >= 3 and stop.waiting.size() <= 5, "%d" % stop.waiting.size())
	var before: int = stop.boarded
	var fake_bus := Node3D.new()  # stands in for a bus at the bay
	for i in 200:
		stop.tick(0.1, fake_bus)
	fake_bus.free()
	_check("Session 64: the people get on when a bus stops at the bay", stop.boarded - before >= maxi(ready_count, 1),
			"%d got on" % (stop.boarded - before))
	for i in int(GameConfig.BUS_STOP_SPAWN_EVERY * 2.5 / 0.25):
		stop.tick(0.25, null)
	var standing: int = stop.waiting.filter(func(e): return e["state"] == "waiting").size()
	_check("Session 64: new people arrive at the stop over time", standing >= 2, "%d waiting" % standing)
	# The stables car park and the school car park look like the others.
	var stables: Rect2 = _data["PARKING_AREAS"][-1]
	var cars := 0
	for car in _main.get_node("DecorBuilder").get_children():
		if String(car.name).begins_with("ParkedCar_") and stables.has_point(Vector2(car.position.x, car.position.z)):
			cars += 1
	var roofs := 0
	var school_roofs := 0
	var school: Rect2 = _data["SCHOOL_PARKING"]
	for roof in _main.get_node("DistrictTraffic").get_children():
		if String(roof.name).begins_with("SolarBay_"):
			var at := Vector2(roof.position.x, roof.position.z)
			roofs += 1 if stables.has_point(at) else 0
			school_roofs += 1 if school.has_point(at) else 0
	_check("Session 64: the stables car park has parked cars, bay lines and solar roofs", cars >= 4 and roofs >= 5, "%d cars, %d roofs" % [cars, roofs])
	var pad := _main.get_node_or_null("DistrictDetail/SchoolCarParkPad")
	_check("Session 64: the school car park has an asphalt pad, cars and solar roofs", pad != null and school_roofs >= 8, "%d roofs" % school_roofs)


## Session 65: the cluster entrance signs, police and STOP signs, bins, pool gate, end houses.
func _session65() -> void:
	var signs := _main.get_node_or_null("WahatBuilder/ClusterSigns")
	var entrances: Array = _data["CLUSTER_ENTRANCES"]
	var complete := 0
	var ranges_ok := true
	var on_road: Array = []
	for entrance: Dictionary in entrances:
		var id: String = entrance["cluster"]
		var green: Node3D = signs.get_node_or_null("ClusterSign_" + id) if signs else null
		var police: Node3D = signs.get_node_or_null("PoliceSign_" + id) if signs else null
		var stop: Node3D = signs.get_node_or_null("StopSign_" + id) if signs else null
		if green == null or police == null or stop == null:
			continue
		var texts := _texts(green)
		if texts.has("Cluster " + id.substr(1)) and texts.has(_data["CLUSTER_NAMES"][id]) and texts.has("EXIT") \
				and texts.has("خروج") and texts.filter(func(w): return w.begins_with("Villa ")).size() == 2 \
				and _texts(police).has("5-Star Habibi Police") and _texts(police).has("Attention") \
				and _texts(police).has("Habibi Smart Home Security") and _texts(police).has("شرطة حبيبي الخمس نجوم") \
				and _texts(stop).has("STOP") and _texts(stop).has("قف"):
			complete += 1
		# Each arrow points at its villas, for a rider coming in (heading away from the spine).
		var heading := Vector2(0, -entrance["out"])
		var left := Vector2(heading.y, -heading.x)
		for side in [["left", 1.0], ["right", -1.0]]:
			var words: String = entrance[side[0]][0]
			var first := int(words.get_slice(" ", 1).get_slice("–", 0))
			var last := int(words.get_slice("–", 1))
			for villa: Dictionary in _data["VILLAS"]:
				if villa["cluster"] == id and villa["house"] >= first and villa["house"] <= last:
					if (villa["position"].x - entrance["lane_x"]) * left.x * side[1] <= 0.0:
						ranges_ok = false
		for board: Node3D in [green, police, stop]:
			for dx in [-0.9, 0.0, 0.9]:  # the pole and both ends of the board
				var spot: Vector3 = board.global_position + board.global_basis.x * dx
				if _on_road(Vector2(spot.x, spot.z), 0.2):
					on_road.append(board.name)
	_check("Session 65: every cluster has its green sign, police sign and STOP sign, in English and Arabic",
			complete == entrances.size(), "%d of %d" % [complete, entrances.size()])
	_check("Session 65: the house ranges on each sign match the villas on that side", ranges_ok)
	var track_police := 0
	if signs:
		for board in signs.get_children():
			if String(board.name).begins_with("PoliceSign_Track"):
				track_police += 1
				var spot: Vector3 = board.global_position
				if _on_road(Vector2(spot.x, spot.z), 0.2) or absf(spot.z) < 7.8:
					on_road.append(board.name)
	_check("Session 65: police signs along the spine's red tracks", track_police >= 3, "%d" % track_police)
	_check("Session 65: no sign stands in the road or on the track", on_road.is_empty(), "%s" % [on_road])
	_check("Session 65: the Arabic on the signs is joined up and runs right to left",
			_arabic_ok(_data["CLUSTER_NAMES"]["C1"]) and _arabic_ok("شرطة حبيبي الخمس نجوم") and _arabic_ok("خروج"))
	# Bins at the back of each cluster beside the back cross road.
	var bins_ok := 0
	for entrance: Dictionary in entrances:
		var bins := _main.get_node_or_null("DistrictDetail/StreetFurniture/ClusterBins_" + entrance["cluster"])
		if bins == null:
			continue
		var cluster: Dictionary = _data["CLUSTERS"].filter(func(c): return c["id"] == entrance["cluster"])[0]
		var back_z: float = cluster["centre"].y - entrance["out"] * (63.0 if entrance["out"] > 0 else 69.0)
		var gap: float = absf(bins.global_position.z - back_z)
		if gap > 3.2 and gap < 6.0 and not _on_road(Vector2(bins.global_position.x, bins.global_position.z), 0.4):
			bins_ok += 1
	_check("Session 65: the bins are at the back of each cluster, beside the back road", bins_ok == entrances.size(), "%d" % bins_ok)
	var pool := _main.get_node_or_null("DistrictDetail/CommunityPool")
	var gate: Node3D = pool.get_node_or_null("PoolGate") if pool else null
	var pool_sign: Node3D = pool.get_node_or_null("PoolSign") if pool else null
	var fence: Rect2 = _data["POOL_GATE"]["fence"]
	_check("Session 65: the pool sign stands in front of the pool gate (outside the fence)",
			gate != null and pool_sign != null and not fence.has_point(Vector2(pool_sign.global_position.x, pool_sign.global_position.z))
			and pool_sign.global_position.distance_to(gate.global_position) < 5.0 and _texts(pool_sign).has("Community Pool"))
	# Big end houses: same kit, bigger, off the roads; all 500 homes still there.
	var ends := _main.get_node_or_null("DistrictDetail/EndHouses")
	var count: int = ends.count if ends else 0
	var clear := true
	var bigger := true
	if ends:
		var space := (ends as Node3D).get_world_3d().direct_space_state
		for body in ends.get_children():
			if not body is StaticBody3D:
				continue
			for shape_node in body.get_children():
				if shape_node is CollisionShape3D:
					var query := PhysicsShapeQueryParameters3D.new()
					query.shape = shape_node.shape
					query.transform = shape_node.global_transform
					for hit in space.intersect_shape(query, 8):
						if String((hit["collider"] as Node).name).begins_with("Villa"):
							clear = false
		for place: Dictionary in _data["END_HOUSES"]:
			if place["size"].x <= _data["VILLA_SIZE"].x or place["size"].z <= _data["VILLA_SIZE"].z:
				bigger = false
			var p: Vector3 = place["position"]
			var half: Vector3 = place["size"] * 0.5
			var dx := half.z if absf(place["facing"]) == 90.0 else half.x
			var dz := half.x if absf(place["facing"]) == 90.0 else half.z
			for corner in [Vector2(-dx, -dz), Vector2(dx, -dz), Vector2(-dx, dz), Vector2(dx, dz), Vector2.ZERO]:
				if _on_road(Vector2(p.x, p.z) + corner * 0.98, 0.0):
					clear = false
	var homes: Array = _data["VILLAS"].filter(func(v): return v["kind"] != "spot")
	_check("Session 65: big end houses at the row ends, bigger than the others, clear of roads and homes",
			count >= 20 and bigger and clear and homes.size() == 500, "%d end houses" % count)


func _texts(node: Node) -> Array:
	var out: Array = []
	for label in node.find_children("*", "Label3D", true, false):
		out.append(label.text)
	return out


func _on_road(spot: Vector2, slack: float) -> bool:
	for road: Dictionary in _data["ROADS"]:
		var width: float = road.get("width", _data["ROAD_WIDTH"])
		if Geometry2D.get_closest_point_to_segment(spot, road["from"], road["to"]).distance_to(spot) <= width * 0.5 + slack:
			return true
	return false


## True when the sign font joins these Arabic letters (they don't all keep their lone
## shapes) and lays them out right to left.
func _arabic_ok(words: String) -> bool:
	var ts := TextServerManager.get_primary_interface()
	var font := SignText.font()
	var shaped := ts.create_shaped_text()
	ts.shaped_text_add_string(shaped, words, font.get_rids(), 32)
	var glyphs := ts.shaped_text_get_glyphs(shaped)
	var rtl := ts.shaped_text_get_inferred_direction(shaped) == TextServer.DIRECTION_RTL
	var alone := {}
	for i in words.length():
		var one := ts.create_shaped_text()
		ts.shaped_text_add_string(one, words[i], font.get_rids(), 32)
		for g in ts.shaped_text_get_glyphs(one):
			alone[g["index"]] = true
		ts.free_rid(one)
	var joined := false
	for g in glyphs:
		if not alone.has(g["index"]):
			joined = true
	# Right to left: the first glyph drawn (leftmost) belongs to the last letter.
	var last_first: bool = glyphs.size() > 0 and int(glyphs[0]["start"]) > int(glyphs[glyphs.size() - 1]["start"])
	ts.free_rid(shaped)
	return rtl and joined and last_first


## Session 66: Majlis Gardens and the phase 3 building site.
func _session66() -> void:
	var park = _main.get_node_or_null("DistrictDetail/MajlisGardens")
	var spec: Dictionary = _data["MAJLIS_GARDENS"]
	var area: Rect2 = spec["area"]
	_check("Session 66: Majlis Gardens has a fountain, palms, benches, a majlis shade and a garden bed",
			park != null and park.get_node_or_null("MajlisFountain") != null and park.palms >= 4 and park.benches >= 4
			and park.get_node_or_null("MajlisShade") != null and park.get_node_or_null("CommunityGardenBed") != null
			and _texts(park).has("Majlis Gardens") and _texts(park).has("حدائق المجلس"))
	if park == null:
		return
	# The free strip really is free: nothing of the car park, the cluster or a road inside it.
	var clash: Array = []
	for parking: Rect2 in _data["PARKING_AREAS"]:
		if parking.intersects(area):
			clash.append("car park")
	for cluster: Dictionary in _data["CLUSTERS"]:
		if (cluster["area"] as Rect2).intersects(area):
			clash.append(cluster["id"])
	for road: Dictionary in _data["ROADS"]:
		var a: Vector2 = road["from"]
		var b: Vector2 = road["to"]
		var bounds := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y))).grow(road.get("width", 6.0) * 0.5)
		if bounds.intersects(area):
			clash.append(road["name"])
	_check("Session 66: the gardens are in the empty strip between the car park and Cluster 1", clash.is_empty(), "%s" % [clash])
	# Each path that leaves the park ends on a road or lane (it joins the paths around).
	var joined := 0
	var leaving := 0
	for path: Array in spec["paths"]:
		var end: Vector2 = path[-1]
		var start: Vector2 = path[0]
		for point: Vector2 in [start, end]:
			if not area.grow(-0.5).has_point(point):
				leaving += 1
				var parking_edge := false
				for parking: Rect2 in _data["PARKING_AREAS"]:
					if parking.grow(1.0).has_point(point):
						parking_edge = true
				if _on_road(point, 1.0) or parking_edge:
					joined += 1
	_check("Session 66: the paver paths join the lanes, the car park and the spine loop road", leaving >= 5 and joined == leaving,
			"%d of %d ends join up, %.0f m of paths" % [joined, leaving, park.path_length])
	var space: PhysicsDirectSpaceState3D = (park as Node3D).get_world_3d().direct_space_state
	var blocked: Array = []
	for path: Array in spec["paths"]:
		for point: Vector2 in path:
			var query := PhysicsPointQueryParameters3D.new()
			query.position = Vector3(point.x, 0.4, point.y)
			for hit in space.intersect_point(query, 4):
				var thing: Node = hit["collider"]
				if park.is_ancestor_of(thing):
					blocked.append("%s at %s" % [thing.name, point])
	_check("Session 66: nothing stands on the garden paths", blocked.is_empty(), "%s" % [blocked.slice(0, 4)])
	var crowds = _main.get_node_or_null("LifeBuilder").get("crowds") if _main.get_node_or_null("LifeBuilder") else null
	var here := 0
	if crowds != null:
		for entry in crowds.people:
			var p: Node3D = entry[0]
			if area.grow(2.0).has_point(Vector2(p.global_position.x, p.global_position.z)):
				here += 1
	var walkers := 0
	for mover in _main.get_node("LifeBuilder").get_children():
		if String(mover.name).begins_with("MajlisWalker") or String(mover.name) == "MajlisGardener":
			walkers += 1
	_check("Session 66: people sit, walk and garden in Majlis Gardens", here >= 5 and walkers >= 3, "%d sitting or standing, %d moving" % [here, walkers])
	# The phase 3 site is dressed like phase 2.
	var site := _main.get_node_or_null("LandmarkBuilder/Phase3Site")
	var phase2 := _main.get_node_or_null("LandmarkBuilder/BuildingSite")
	var same := site != null and phase2 != null and site.get_node_or_null("Crane") != null
	if same:
		same = site.find_children("SiteWorker*", "", true, false).size() >= 2 and site.get_child_count() >= phase2.get_child_count() - 1
	_check("Session 66: the phase 3 site has a fence, a crane, materials and workers like phase 2", same,
			"%d vs %d parts" % [site.get_child_count() if site else 0, phase2.get_child_count() if phase2 else 0])
	_check("Session 66: the phase 3 sign says Phase 3 coming soon in English and Arabic",
			site != null and _texts(site).has("Phase 3 coming soon") and _texts(site).has("المرحلة الثالثة قريباً"))
	var generic := 0
	for node in _main.get_node("DistrictDetail").get_children():
		if String(node.name).begins_with("ConstructionSite"):
			var floor_spot: Vector3 = (node.get_child(0) as Node3D).position
			if (_data["PHASE3_SITE"]["area"] as Rect2).has_point(Vector2(floor_spot.x, floor_spot.z)):
				generic += 1
	_check("Session 66: the phase 3 site isn't built twice", generic == 0)
