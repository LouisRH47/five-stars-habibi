extends SceneTree
## Session 61: the road surfaces, markings, kerbs and curved corners (no full game needed).
## Session 76: kerbs that join up: no kerb end in mid-air, no kerb on a road, the roundabout
## wrapped all the way round, curved corners at the junctions, the C Institute road curved.
## Run: godot --path . --headless -s tests/road_mesh_test.gd

const TOUCH := 0.35   # a kerb end this close to another kerb counts as joined

var _failures := 0
var _count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var map: Dictionary = (load("res://data/wahat_al_shams.gd") as Script).get_script_constant_map()
	var started := Time.get_ticks_msec()
	var roads := RoadMesh.build(world, map)
	var tracks := SpineTracks.build(world, map, roads.bumps)
	print("built in %d ms" % (Time.get_ticks_msec() - started))
	var stats: Dictionary = roads.stats
	print("ROADS: ", JSON.stringify(stats))
	_check("the short road pieces are joined into smooth chains", stats["chains"] < WahatAlShams.ROADS.size() / 2)
	var ring: Array = roads.chains.filter(func(c): return c["name"] == "Ring Road")
	_check("the ring road is one closed, rounded loop", ring.size() == 1 and ring[0]["closed"] and ring[0]["points"].size() > 20)
	var round: Array = roads.chains.filter(func(c): return c["name"] == "Institute Roundabout")
	_check("the roundabout is one closed curve", round.size() == 1 and round[0]["closed"])
	_check("every asphalt road gets a dashed yellow centre line", stats["dashes"] > 1000)
	_check("arrows on both sides of the roads", stats["arrows"] > 200)
	_check("curved corner pieces where roads meet", stats["fillets"] >= 60)
	_check("kerbs along the roads", stats["kerb_pieces"] > 3000)
	_check("no two road surfaces meet at the same height", stats["same_height_overlaps"] == 0)
	_check("road heights stay above the pavers", roads.chains.all(func(c): return not c["asphalt"] or c["top"] > RoadMesh.PAVING_TOP))
	_check("pavers stay below the asphalt", roads.chains.all(func(c): return c["asphalt"] or c["top"] < RoadMesh.UNDER_TOP))
	_check("roads are merged into a few meshes", stats["meshes"] > 0 and stats["meshes"] < 200)
	var lane: Array = roads.chains.filter(func(c): return c["name"] == "C1 Lane")
	_check("cluster lanes are asphalt", not lane.is_empty() and lane.all(func(c): return c["asphalt"]))
	# A car park access road leaves the ring road at every car park.
	_check("car park access roads", roads.chains.filter(func(c): return c["name"] == "Car Park Access").size() == WahatAlShams.PARKING_AREAS.size())
	_check_kerbs(roads, tracks, map)
	world.free()
	_check_parking_lots(map)
	print("ROAD RESULT: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _count])
	quit(0 if _failures == 0 else 1)


## Session 76 checks.
func _check_kerbs(roads: RoadMesh, tracks: SpineTracks, map: Dictionary) -> void:
	var lines: Array = []  # every kerb as a list of flat points
	for run: Dictionary in roads.kerbs.runs:
		var pts: Array = run["points"].duplicate()
		if run["closed"]:
			pts.append(pts[0])
		lines.append(pts)
	lines.append_array(tracks.kerb_lines)
	var loose := dangling_ends(roads.kerbs, tracks.kerb_lines, roads.area)
	_check("Session 76: no kerb ends in mid-air (%d found)" % loose.size(), loose.is_empty())
	for spot in loose.slice(0, 12):
		print("      loose kerb end at ", spot)
	# No kerb lies on a road (they never cross a lane).
	var on_road: Array = []
	for run: Dictionary in roads.kerbs.runs:
		for k in run["points"].size():
			var middle: Vector2 = run["points"][k] + run["out"][k] * GameConfig.KERB_WIDTH * 0.5
			if roads.area.on_asphalt(middle, 0.05):
				on_road.append(middle)
	_check("Session 76: no kerb lies on a road (%d bits)" % on_road.size(), on_road.is_empty())
	for spot in on_road.slice(0, 6):
		print("      kerb on a road at ", spot)
	# The roundabout: the island is one closed kerb, and the outside joins all the way round
	# (only broken where roads come in, and there the curved corners carry it on).
	var centre: Vector2 = map["ROUNDABOUTS"][0]["centre"]
	var island: bool = roads.kerbs.runs.any(func(r): return r["closed"] and (r["points"][0] as Vector2).distance_to(centre) < 7.0)
	_check("Session 76: the roundabout's island has one closed kerb all round", island)
	var round_loose := loose.filter(func(p): return (p as Vector2).distance_to(centre) < 30.0)
	_check("Session 76: the roundabout's outside kerbs join up", round_loose.is_empty())
	var round_corners := roads.corners.filter(func(c): return (c["corner"] as Vector2).distance_to(centre) < 20.0)
	_check("Session 76: curved corners where the three roads meet the roundabout (%d)" % round_corners.size(), round_corners.size() == 6)
	# Every junction gets curved corners; lane corners about 6 m, bigger roads about 10 m.
	var small := roads.corners.filter(func(c): return c["radius"] < 1.0)
	print("      corners: %d, smaller than 1 m: %d (the 1 m islands at the cluster entrances)" % [roads.corners.size(), small.size()])
	var lane_corners := roads.corners.filter(func(c): return is_equal_approx(c["radius"], 6.0))
	var road_corners := roads.corners.filter(func(c): return is_equal_approx(c["radius"], 10.0))
	_check("Session 76: lanes meet roads with curved 6 m corners (%d)" % lane_corners.size(), lane_corners.size() >= 40)
	_check("Session 76: bigger roads meet with curved 10 m corners (%d)" % road_corners.size(), road_corners.size() >= 6)
	# The cluster lane corners are rounded too: each cluster's outer lanes and cross roads are
	# one loop with rounded corners.
	var loops := roads.chains.filter(func(c): return String(c["name"]).ends_with(" Lane") and c["closed"])
	_check("Session 76: each cluster's lane loop has rounded corners", loops.size() == 5)
	# The C Institute access road: one smooth curve from the spine road to the door.
	var access: Array = roads.chains.filter(func(c): return c["name"] == "Institute Access")
	var smooth: bool = access.size() == 1 and access[0]["points"].size() > 6
	if smooth:
		var pts: Array = access[0]["points"]
		for k in range(1, pts.size() - 1):
			var turn := absf(((pts[k] - pts[k - 1]) as Vector2).angle_to(pts[k + 1] - pts[k]))
			if turn > deg_to_rad(20.0):
				smooth = false
	_check("Session 76: the C Institute access road is one smooth curve", smooth)
	# Kerbs are raised (not flat strips) and the kerb lines are given to KerbBumps.
	_check("Session 76: kerbs are raised", GameConfig.KERB_HEIGHT >= 0.08)
	_check("Session 75: every kerb line gives a bump", roads.bumps != null and roads.bumps.lines.size() > 1000)


## Car parks in a PARKING_LOTS list (lane R2's data): the kerb leaves a gap all along each
## entrance and keeps out of the lot, but the kerb across the road from it stays.
func _check_parking_lots(map: Dictionary) -> void:
	var test_map := map.duplicate()
	test_map["PARKING_LOTS"] = [{"area": Rect2(-165, 146, 24, 50),
			"entrances": [{"road": "Stables Car Park Road", "at": Vector2(-144.5, 205), "lot_at": Vector2(-144.5, 196), "width": 8.0}]}]
	var world := Node3D.new()
	root.add_child(world)
	var roads := RoadMesh.build(world, test_map)
	var tracks := SpineTracks.build(world, test_map, roads.bumps)
	var loose := dangling_ends(roads.kerbs, tracks.kerb_lines, roads.area)
	_check("Session 76: PARKING_LOTS entrances leave kerb gaps and every kerb still joins (%d loose)" % loose.size(),
			loose.is_empty() and roads.area.in_gap(Vector2(-144.5, 199)) and not roads.area.in_gap(Vector2(-144.5, 210)))
	world.free()


## Kerb ends that don't touch another kerb, a gap or a crossing. Static so other tests can use it.
static func dangling_ends(kerbs: RoadKerbs, extra_lines: Array, area: RoadArea) -> Array:
	var lines: Array = []
	for run: Dictionary in kerbs.runs:
		var pts: Array = run["points"].duplicate()
		if run["closed"]:
			pts.append(pts[0])
		lines.append(pts)
	lines.append_array(extra_lines)
	var ends: Array = []  # [point, line index, which end]
	for i in lines.size():
		var pts: Array = lines[i]
		if pts.size() >= 2 and (pts[0] as Vector2).distance_to(pts.back()) > 0.01:
			ends.append([pts[0], i, 0])
			ends.append([pts.back(), i, 1])
	var loose: Array = []
	for item: Array in ends:
		var p: Vector2 = item[0]
		if _near_gap(p, area):
			continue
		var joined := false
		for j in lines.size():
			if j == item[1]:
				continue
			var pts: Array = lines[j]
			for k in pts.size() - 1:
				if Geometry2D.get_closest_point_to_segment(p, pts[k], pts[k + 1]).distance_to(p) < TOUCH:
					joined = true
					break
			if joined:
				break
		if not joined:
			loose.append(p)
	return loose


static func _near_gap(p: Vector2, area: RoadArea) -> bool:
	for offset in [Vector2.ZERO, Vector2(0.2, 0), Vector2(-0.2, 0), Vector2(0, 0.2), Vector2(0, -0.2)]:
		if area.in_gap(p + offset):
			return true
	return false


func _check(label: String, good: bool) -> void:
	_count += 1
	print("%s: %s" % ["PASS" if good else "FAIL", label])
	if not good:
		_failures += 1
