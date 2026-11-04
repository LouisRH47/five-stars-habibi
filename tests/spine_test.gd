extends SceneTree
## Session 63: checks the spine, the farm and the stream (Appendix D and J).
## Run: Godot --path . --headless -s tests/spine_test.gd
## The red track and buggy road (widths, order, kerbs, strip, lane lines, markings), the
## gentle hills, the planting round the domes, the farm beds, the bee yard and beekeeper,
## the farmer, the stream's bridges and banks, and the new horses.
const WAHAT := preload("res://scripts/wahat_builder.gd")
const LayoutTest := preload("res://tests/layout_test.gd")
const DistrictDetail := preload("res://scripts/district_detail.gd")
var _failed := 0
var _count := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	_count += 1
	if not ok:
		_failed += 1
	print(("PASS: " if ok else "FAIL: ") + what)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "user://spine_test.json"
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 6:
		await physics_frame
	for frame in 20:
		if world.get_node("DistrictDetail").has_meta("static_batch_report"):
			break
		await process_frame
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var spine: Node3D = world.get_node("SpineBuilder")
	_paths(map, world, spine)
	_hills(map)
	_planting(map, spine)
	_farm(map, world, spine)
	_bees(map, world)
	_stream(map, world, spine)
	_horses(world)
	print("SPINE RESULT: %s (%d checks, %d failed)" % ["PASS" if _failed == 0 else "FAIL", _count, _failed])
	print("RESULT: ", "PASS" if _failed == 0 else "FAIL")
	SaveGame.delete(state.save_path)
	quit(1 if _failed > 0 else 0)


func _paths(map: Dictionary, world: Node3D, spine: Node3D) -> void:
	var track := SpinePaths.track(map)
	var road := SpinePaths.buggy_road(map)
	_expect(track.get("kind") == "walk_track" and is_equal_approx(track["width"], 3.5),
			"the red walking track is in the data, 3.5 m wide")
	_expect(road.get("kind") == "buggy_road" and is_equal_approx(road["width"], 6.0),
			"the buggy road is in the data (a clear name for the buggies), 6 m wide")
	var parts := SpinePaths.cross_section(map)
	var names: Array = parts.map(func(p: Array) -> String: return p[0])
	var widths: Array = parts.map(func(p: Array) -> float: return snappedf(p[2] - p[1], 0.01))
	var joined := true
	for i in parts.size() - 1:
		joined = joined and is_equal_approx(parts[i][2], parts[i + 1][1])
	_expect(names == ["track", "kerb", "strip", "kerb", "road"] and joined,
			"north to south: track, kerb, strip, kerb, buggy road, with no gaps %s" % [names])
	var want := [3.5, 0.3, 1.4, 0.3, 6.0]
	var sizes_ok := widths.size() == 5
	for i in mini(5, widths.size()):
		sizes_ok = sizes_ok and absf(widths[i] - want[i]) < 0.01
	_expect(sizes_ok, "widths 3.5 / 0.3 / 1.4 / 0.3 / 6 m %s" % [widths])
	var domes_north := true
	for dome: Vector3 in map["SPINE_DOMES"]:
		domes_north = domes_north and dome.z + float(map["DOME_RADIUS"]) < parts[0][1]
	_expect(domes_north, "the red track is the path nearest the domes")
	var walking := world.get_node_or_null("WahatBuilder/WalkingTrack") as MeshInstance3D
	_expect(walking != null and walking.material_override == TerrainMaterials.make("track"),
			"the track uses the red rubber texture")
	var kerbs: Array = spine.find_children("Kerb*", "MeshInstance3D", true, false)
	var strips: Array = spine.find_children("PlantedStrip*", "MeshInstance3D", true, false)
	var kerb_ok := kerbs.size() >= 8
	for kerb: MeshInstance3D in kerbs:
		var box := (kerb.mesh as BoxMesh).size
		kerb_ok = kerb_ok and is_equal_approx(box.z, 0.3) and is_equal_approx(box.y, 0.12)
	_expect(kerb_ok, "%d raised kerbs, 0.3 m wide and 0.12 m high" % kerbs.size())
	var strip_ok := strips.size() >= 4
	for strip: MeshInstance3D in strips:
		var box := (strip.mesh as BoxMesh).size
		strip_ok = strip_ok and is_equal_approx(box.z, 1.4) and box.y < 0.12 and box.y > 0.1
	_expect(strip_ok, "%d planted strip pieces, 1.4 m wide, raised just under the kerbs" % strips.size())
	# Every path that crosses has a gap in the kerbs (a dropped kerb).
	var blocked: Array = []
	for cut: Array in SpinePaths.crossings(map, -20.0, 20.0):
		var x := (float(cut[0]) + float(cut[1])) * 0.5
		for kerb: MeshInstance3D in kerbs:
			var half := (kerb.mesh as BoxMesh).size.x * 0.5
			if absf(kerb.global_position.x - x) < half:
				blocked.append(x)
	_expect(blocked.is_empty() and SpinePaths.crossings(map, -20.0, 20.0).size() >= 3,
			"kerbs stop where paths cross, so the bike can ride across %s" % [blocked])
	var dashes := 0
	for line: MeshInstance3D in spine.find_children("LaneLine*", "MeshInstance3D", true, false):
		dashes += line.mesh.get_faces().size() / 36
	_expect(dashes > 200, "the buggy road has a dashed white middle line (%d dashes)" % dashes)
	var marks := spine.find_children("WalkMarking*", "Node3D", true, false)
	var arabic := marks.size() > 0 and (marks[0].get_child(0) as Label3D).text == "مشي"
	_expect(marks.size() >= 10 and arabic, "WALK · مشي is painted on the track (%d times)" % marks.size())
	var walkers_on_track := true
	for route: Dictionary in map["PEOPLE_ROUTES"]:
		if not route["jog"]:
			for p: Vector3 in route["points"]:
				walkers_on_track = walkers_on_track and absf(p.z - track["from"].y) < track["width"] * 0.5
	_expect(walkers_on_track, "the spine walkers keep to the red track")


func _hills(map: Dictionary) -> void:
	var hills: Array = map["HILLS"]
	_expect(hills.size() >= 10 and hills.size() <= 14, "10 to 14 gentle hills (%d)" % hills.size())
	var bad: Array = []
	var keep: Array = map["FARM_BEDS"] + [map["LAP_POOL"], map["COMMUNITY_POOL"], map["BASKETBALL_COURT"],
			map["PLAYGROUND"], (map["BEEHIVES"] as Rect2).grow(BeeYard.BED_WIDTH + 0.2), map["DONKEY_PEN"]["area"],
			LayoutTest._footprint(map["GYM"]["position"], map["GYM"]["size"], map["GYM"]["facing"]), GameConfig.SPINE_FREE_CORNER]
	for shop: Dictionary in map["RESTAURANTS"]:
		if shop.get("style", "") == "stall":
			keep.append(LayoutTest._footprint(shop["position"], shop["size"], shop["facing"]))
	for road: Dictionary in map["ROADS"]:
		keep.append(ClusterSigns.road_rect(road, map["ROAD_WIDTH"]))
	var stream: Dictionary = map["STREAM"]
	for hill: Dictionary in hills:
		var c := Vector2(hill["position"].x, hill["position"].z)
		var r: float = hill.get("radius", GameConfig.HILL_RADIUS)
		var h: float = hill["height"]
		if h > 0.5 + 0.001 or h < 0.25 - 0.001 or r < 5.0 or r > 10.0:
			bad.append("(%d, %d) size" % [c.x, c.y])
		for area: Rect2 in keep:
			if LayoutTest._circle_hits(c, r + 4.0, area):
				bad.append("(%d, %d) near %s" % [c.x, c.y, area])
		for dome: Vector3 in map["SPINE_DOMES"]:
			if c.distance_to(Vector2(dome.x, dome.z)) < r + float(map["DOME_RADIUS"]) + 4.0:
				bad.append("(%d, %d) near a dome" % [c.x, c.y])
		var x := c.x - r
		while x <= c.x + r:
			var z := StreamBanks.centre_z(stream, x)
			if x >= stream["from_x"] and x <= stream["to_x"] and absf(z - c.y) - float(stream["width"]) * 0.5 < sqrt(maxf(0.0, r * r - (x - c.x) * (x - c.x))):
				bad.append("(%d, %d) on the stream" % [c.x, c.y])
				break
			x += 1.0
	_expect(bad.is_empty(), "hills are 0.25-0.5 m, 10-20 m across, 4 m from paths, pools, beds, buildings, courts and domes, and off the stream %s" % [bad])
	var rough := 0.0
	for hill: Dictionary in hills:
		var c: Vector3 = hill["position"]
		for i in 40:
			var a := Vector2(c.x + i * 0.25 - 5.0, c.z)
			var slope := absf(DistrictDetail.hill_height(hill, a.x + 0.5, a.y) - DistrictDetail.hill_height(hill, a.x, a.y)) / 0.5
			rough = maxf(rough, slope)
	_expect(rough < 0.2, "hills are smooth: steepest slope %.2f (under 1 in 5)" % rough)


func _planting(map: Dictionary, spine: Node3D) -> void:
	var holder := spine.get_node_or_null("SpinePlanting")
	_expect(holder != null, "the spine has its planting")
	if holder == null:
		return
	var report: Dictionary = holder.get_meta("report")
	var keep: Array = []
	for road: Dictionary in map["ROADS"]:
		keep.append(ClusterSigns.road_rect(road, map["ROAD_WIDTH"]).grow(0.3))
	for key in ["LAP_POOL", "COMMUNITY_POOL", "BASKETBALL_COURT", "PLAYGROUND"]:
		keep.append(map[key])
	keep.append(LayoutTest._footprint(map["GYM"]["position"], map["GYM"]["size"], map["GYM"]["facing"]))
	keep.append(GameConfig.SPINE_FREE_CORNER)
	var per_dome: Array = []
	var in_the_way: Array = []
	for dome: Vector3 in map["SPINE_DOMES"]:
		var counts := [0, 0, 0]
		var kinds := ["palms", "trees", "shrubs"]
		for k in 3:
			for spot: Vector3 in report[kinds[k]]:
				if Vector2(spot.x - dome.x, spot.z - dome.z).length() < GameConfig.SPINE_DOME_RING.y + 1.5:
					counts[k] += 1
		per_dome.append(counts)
	for kind in ["palms", "trees", "shrubs"]:
		for spot: Vector3 in report[kind]:
			for area: Rect2 in keep:
				if area.has_point(Vector2(spot.x, spot.z)):
					in_the_way.append("%s at (%d, %d)" % [kind, spot.x, spot.z])
	var full := per_dome.all(func(c: Array) -> bool: return c[0] == 3 and c[1] == 2 and c[2] >= 8 and c[2] <= 12)
	_expect(full, "every dome has 3 date palms, 2 fruit trees and 8-12 shrubs round it %s" % [per_dome])
	_expect(in_the_way.is_empty(), "no plant stands on a path, pool, court or the gym %s" % [in_the_way])
	_expect(report["strip"].size() > 300, "low plants along the raised strip (%d)" % report["strip"].size())
	var kit := SpinePlanting.has_kit(SpinePlanting.PALMS[0])
	var many := holder.find_children("*", "MultiMeshInstance3D", true, false).size()
	_expect(not kit or many > 20, "the plants use the CC0 packs, drawn many at once (%d groups)" % many)


func _farm(map: Dictionary, world: Node3D, spine: Node3D) -> void:
	var farm := spine.get_node_or_null("FarmBeds")
	_expect(farm != null, "the farm beds are built")
	if farm == null:
		return
	var report: Dictionary = farm.get_meta("report")
	var areas: int = map["FARM_BEDS"].size()
	_expect(report["beds"] == areas * 3 and report["plants"] > areas * 90 and report["fruit"] > areas * 20,
			"%d raised beds with %d plants and %d melons and pumpkins" % [report["beds"], report["plants"], report["fruit"]])
	var props := 0
	for name in ["Scarecrow", "Wheelbarrow", "WateringCan"]:
		props += farm.find_children(name, "MeshInstance3D", true, false).size()
	_expect(props == areas * 3, "every farm has a scarecrow, a wheelbarrow and a watering can (%d)" % props)
	var kinds := {}
	for group: Node in farm.find_children("*", "Node3D", true, false):
		if group.has_meta("kit_id"):
			kinds[String(group.get_meta("kit_id")).get_file().get_slice("_", 0)] = true
	_expect(not SpinePlanting.has_kit("quaternius_crops/Watermelon_4") or (kinds.has("Watermelon") and kinds.has("Pumpkin") and kinds.has("Tomato")),
			"watermelons, pumpkins and tomatoes from the crops pack %s" % [kinds.keys()])
	# The farm stall stands beside the beds, not on them.
	var stall_ok := true
	for shop: Dictionary in map["RESTAURANTS"]:
		if shop.get("style", "") == "stall":
			for bed: Rect2 in map["FARM_BEDS"]:
				stall_ok = stall_ok and not bed.intersects(LayoutTest._footprint(shop["position"], shop["size"], shop["facing"]))
	_expect(stall_ok, "the farm stall and the beds don't overlap")
	# No grass blades on the beds.
	var field: Node3D = world.get_node_or_null("DistrictDetail/GrassField")
	if field == null:
		_expect(not GameConfig.GRASS_BLADES_ON, "grass field exists")
		return
	var bad := 0
	var checked := 0
	for bed: Rect2 in map["FARM_BEDS"] + [(map["BEEHIVES"] as Rect2).grow(BeeYard.BED_WIDTH)]:
		for key in [Vector2i(floori(bed.get_center().x / GameConfig.GRASS_CHUNK), floori(bed.get_center().y / GameConfig.GRASS_CHUNK))]:
			for spot: Transform3D in field.make_spots(key):
				var at := Vector2(key) * GameConfig.GRASS_CHUNK + Vector2(spot.origin.x, spot.origin.z)
				checked += 1
				if bed.grow(-0.05).has_point(at):
					bad += 1
	_expect(bad == 0 and checked > 100, "no grass grows on the farm beds or the bee yard (%d checked)" % checked)


func _bees(map: Dictionary, world: Node3D) -> void:
	var yard := world.get_node_or_null("SpineBuilder/BeeYard")
	_expect(yard != null and yard.get_node_or_null("BeeGate") != null and yard.get_node_or_null("BeeSign") != null
			and yard.get_node_or_null("Bees") != null, "the bee yard has a fence with a gate, a sign and bees")
	var lids := root.get_tree().get_nodes_in_group("hive_lid")
	_expect(lids.size() == 8, "8 hives with lids (%d)" % lids.size())
	var sign_text := ""
	if yard != null:
		for label: Label3D in yard.find_children("*", "Label3D", true, false):
			sign_text += label.text + " "
	_expect(sign_text.contains("Bees at work") and sign_text.contains("نحل يعمل"), "bilingual 'Bees at work · نحل يعمل' sign")
	var keeper: Node3D = world.get_node_or_null("LifeBuilder/Beekeeper")
	_expect(keeper != null, "there's a beekeeper")
	if keeper == null:
		return
	var area: Rect2 = map["BEEHIVES"]
	var inside := true
	var lifted := false
	for i in 900:
		keeper.step(0.1)
		inside = inside and area.grow(0.2).has_point(Vector2(keeper.position.x, keeper.position.z))
		for lid: Node3D in lids:
			lifted = lifted or lid.rotation.x < -0.2
	_expect(inside, "the beekeeper stays by the hives, inside the fence")
	_expect(keeper.walked > 5.0 and keeper.jobs_done >= 4 and lifted,
			"the beekeeper walks between hives and lifts lids (%.0f m, %d hives checked)" % [keeper.walked, keeper.jobs_done])
	var farmer: Node3D = world.get_node_or_null("LifeBuilder/FieldFarmer")
	_expect(farmer != null, "there's a farmer in the rows")
	if farmer == null:
		return
	var bed: Rect2 = map["FARM_BEDS"][1]
	var on_paths := true
	for i in 900:
		farmer.step(0.1)
		var at := Vector2(farmer.position.x, farmer.position.z)
		var on_walk := false
		for z: float in FarmBeds.walk_lines(bed):
			on_walk = on_walk or absf(at.y - z) < 0.3
		on_paths = on_paths and bed.grow(1.0).has_point(at) and (on_walk or at.x < bed.position.x or at.x > bed.end.x)
	_expect(on_paths and farmer.walked > 5.0 and farmer.jobs_done >= 4,
			"the farmer walks the paths between the beds and waters (%.0f m, %d stops)" % [farmer.walked, farmer.jobs_done])


func _stream(map: Dictionary, world: Node3D, spine: Node3D) -> void:
	var spots := WAHAT.bridge_spots(map)
	var bridges := world.get_node_or_null("WahatBuilder/Bridges")
	var missing := 0
	for spot in spots:
		var found := false
		if bridges != null:
			for bridge: Node3D in bridges.get_children():
				found = found or Vector2(bridge.position.x, bridge.position.z).distance_to(Vector2(spot.x, spot.z)) < 1.0
		missing += 0 if found else 1
	_expect(spots.size() >= 2 and missing == 0, "a bridge at every stream crossing (%d)" % spots.size())
	var banks := spine.get_node_or_null("StreamBanks")
	var report: Dictionary = banks.get_meta("report") if banks != null else {}
	_expect(report.get("reeds", 0) > 100 and report.get("pads", 0) > 40 and report.get("stones", 0) > 50,
			"the stream has reeds and papyrus, lily pads and stones %s" % [report])
	var on_bridge := false
	for spot in spots:
		on_bridge = on_bridge or not StreamBanks.near_crossing(map, spot.x)
	_expect(not on_bridge, "no reeds or stones on the bridges")


func _horses(world: Node3D) -> void:
	var horse: Node3D = world.get_node_or_null("LifeBuilder/Horse_0")
	var coats := {}
	for node: Node in world.find_children("Horse_*", "", true, false) + [world.get_node_or_null("DistrictTraffic/ArenaHorse")]:
		if node != null and node.get("model") != null:
			coats[node.get("model").get_meta("coat", "")] = true
	_expect(horse != null and horse.model.get_meta("legs", []).size() == 4, "the horses still have 4 trotting legs")
	_expect(not GameConfig.HORSE_LOOK_V2 or (coats.has("brown") and coats.has("grey") and coats.has("chestnut")),
			"horses come in brown, grey and chestnut coats %s" % [coats.keys()])
