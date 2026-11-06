class_name RoadMesh
extends Node3D
## Session 61: real road surfaces built from the map's ROADS list.
## The short pieces of each road are joined into one smooth strip ("chain"), so rounded
## corners and the roundabout are real curves, not overlapping boxes. On every asphalt road:
## a CC0 asphalt texture that is a little darker in the middle, a yellow dashed centre line,
## white arrows on each side showing which way to drive (on the right, like the UAE).
## Where a road meets another, it stops at the other road's edge and a curved corner piece
## (a "fillet", worked out by RoadCorners) rounds off each inside corner. Roads that meet sit
## a couple of millimetres apart in height, so no two surfaces lie on top of each other at
## the same height (that is what made textures flicker). Pavers sit lower than asphalt.
## Session 76: the kerbs are raised stone strips that follow every road edge, curve round
## every corner and join up (RoadKerbs works out where), with gaps only at paver paths,
## crossings and car parks. Kerbs have no collision: KerbBumps gives a small bump instead.
## Everything is flat with no collision (you ride over it) and merged into a few big meshes
## per 120 m square, so it stays fast on Low.

const ASPHALT_TOP := 0.05     # road surface height (speed bumps sit on this)
const UNDER_TOP := 0.04       # a road that passes under a crossing road (the highway)
const LEVEL_STEP := 0.002     # roads that meet are this much apart in height (never equal)
const PAVING_TOP := 0.035     # paver paths, lower than asphalt
const MARK_LIFT := 0.006      # paint sits this far above the asphalt
const PAINT_GAP := 6.0        # no centre line this close to where a road joins another
const STEP := 1.5             # roads are cut into pieces this long (for curves and gaps)
const TILE := 6.0             # one asphalt texture tile covers this many metres
const DASH := 3.0             # centre line: 3 m paint, 3 m gap
const LINE_WIDTH := 0.14
const ARROW_EVERY := 40.0
const RING_ARROW_EVERY := 60.0
const ROUNDABOUT_ARROW_EVERY := 14.0
const CELL := 120.0
const KINDS := ["asphalt", "paving", "kerb", "yellow", "white"]  # the kinds of mesh
const ASPHALT_MIN_WIDTH := 6.0
## One-way roads: +1 drives from the first point to the last, -1 the other way.
## The roundabout goes anticlockwise, as roundabouts do when you drive on the right.
const ONE_WAY := {"Institute Roundabout": -1, "Bus Loop": 1}
const UNDER := ["Highway"]
## A dead-end road this close to the Plaza's edge runs into it (no kerb across its end).
const PLAZA_REACH := 4.0
## Kerb gap where the horses cross a road (HORSE_CROSSINGS).
const HORSE_CROSSING_HALF := 2.5
## Data lists of extra kerb gaps (crossings, car park entrances). Each item can be a point
## (Vector2/Vector3), or {position/at/centre, width or half}, or {from, to, width or half}.
const GAP_LISTS := ["KERB_GAPS", "CAR_PARK_ENTRANCES", "PARKING_ENTRANCES"]

const YELLOW := Color(0.96, 0.78, 0.18)
const WHITE := Color(0.95, 0.95, 0.92)
const KERB := Color(0.66, 0.65, 0.62)       # the top of a kerb (concrete, not paint white)
const KERB_FACE := Color(0.52, 0.51, 0.49)  # its sides, a little darker

## The joined roads: {name, width, asphalt, points (Array of Vector2), closed, top}.
var chains: Array = []
## Session 76: where the asphalt is (roads, curved corners, kerb gaps): kerbs, tests, buggies.
var area: RoadArea
## The curved inside corners (RoadCorners) and the kerb runs (RoadKerbs).
var corners: Array = []
var kerbs: RoadKerbs
## Session 75: gives the bike a small bump when it rides over a kerb.
var bumps: KerbBumps
## Counts for the smoke test.
var stats := {"chains": 0, "asphalt_chains": 0, "dashes": 0, "arrows": 0, "fillets": 0,
		"kerb_pieces": 0, "kerb_runs": 0, "kerb_metres": 0, "dead_end_caps": 0,
		"same_height_overlaps": 0, "meshes": 0, "zebras": 0, "zebra_stripes": 0}

var _joins: Array = []       # roads that end on another road (for the curved corners)
var _crosses: Array = []     # asphalt roads that cross each other in the middle
var _dead_ends: Array = []   # [chain, end] of roads that just stop

var _zebra_list: Array = []  # Session 90: ZEBRA_CROSSINGS from the data
var _batches := {}           # Vector3i(kind, square x, square z) -> {kind, verts, normals, colours, uvs}
var _materials := {}
static var _asphalt_cache: StandardMaterial3D


static func build(parent: Node3D, map: Dictionary) -> RoadMesh:
	var roads := RoadMesh.new()
	roads.name = "Roads"
	parent.add_child(roads)
	roads.make(map)
	return roads


## Where a car park's access road leaves the ring road (DistrictTraffic uses the same line).
static func parking_access_x(area: Rect2) -> float:
	return area.end.x - 3.5


## The asphalt material (also used by other builders for car park access and pads).
static func asphalt_material() -> StandardMaterial3D:
	if _asphalt_cache == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load("res://assets/textures/asphalt_road_1k.jpg")
		mat.vertex_color_use_as_albedo = true
		mat.albedo_color = Color(0.92, 0.92, 0.93)
		mat.roughness = 0.94
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_asphalt_cache = mat
	return _asphalt_cache


func _ready() -> void:
	add_to_group("graphics")  # Settings.apply() calls apply_graphics()
	apply_graphics()


## Low graphics uses plain grey asphalt (no texture to sample).
func apply_graphics() -> void:
	Settings.load_once()
	var mat := asphalt_material()
	mat.albedo_texture = null if Settings.graphics == 0 else load("res://assets/textures/asphalt_road_1k.jpg")
	mat.albedo_color = Color(0.36, 0.37, 0.39) if Settings.graphics == 0 else Color(0.92, 0.92, 0.93)


func make(map: Dictionary) -> void:
	chains = make_chains(map.get("ROADS", []), map.get("ROAD_WIDTH", 10.0))
	_zebra_list = map.get("ZEBRA_CROSSINGS", [])
	var clock := Time.get_ticks_msec()  # build times (ms since the start) go in stats
	_add_parking_access(map)
	var junctions := _find_junctions()
	_pick_heights(junctions)
	_fill_area(map, junctions)
	stats["ms_junctions"] = Time.get_ticks_msec() - clock
	corners = RoadCorners.make(chains, _joins, _crosses, area, map.get("ROAD_CORNERS", {}))
	stats["ms_corners"] = Time.get_ticks_msec() - clock
	for i in chains.size():
		_build_chain(i, junctions[i])
	for corner: Dictionary in corners:
		_fillet(corner)
	stats["ms_surfaces"] = Time.get_ticks_msec() - clock
	_build_kerbs()
	stats["ms_kerbs"] = Time.get_ticks_msec() - clock
	_count_overlaps(junctions)
	_finish()
	stats["ms_total"] = Time.get_ticks_msec() - clock
	stats["fillets"] = corners.size()
	stats["chains"] = chains.size()
	stats["asphalt_chains"] = chains.filter(func(c): return c["asphalt"]).size()


## Joins pieces that follow on from each other (same name and width) into chains.
static func make_chains(roads: Array, default_width := 10.0) -> Array:
	var out: Array = []
	for road: Dictionary in roads:
		var a: Vector2 = road["from"]
		var b: Vector2 = road["to"]
		var width: float = road.get("width", default_width)
		var name: String = road.get("name", "")
		var last: Dictionary = out.back() if not out.is_empty() else {}
		if not last.is_empty() and last["name"] == name and is_equal_approx(last["width"], width) \
				and not last["closed"] and (last["points"].back() as Vector2).distance_to(a) < 0.05:
			last["points"].append(b)
		else:
			last = {"name": name, "width": width, "asphalt": width >= ASPHALT_MIN_WIDTH, "points": [a, b], "closed": false}
			out.append(last)
		var pts: Array = last["points"]
		if pts.size() > 3 and (pts[0] as Vector2).distance_to(pts.back()) < 0.05:
			pts.pop_back()
			last["closed"] = true
	return out


func _add_parking_access(map: Dictionary) -> void:
	var ring: Dictionary = map.get("RING_ROAD", {})
	if ring.is_empty():
		return
	var half: Vector2 = ring["half"]
	for lot: Rect2 in map.get("PARKING_AREAS", []):
		var north := lot.get_center().y < 0.0
		var x := parking_access_x(lot)
		var edge := -half.y if north else half.y
		chains.append({"name": "Car Park Access", "width": 6.0, "asphalt": true,
				"points": [Vector2(x, edge), Vector2(x, lot.end.y - 9.0)], "closed": false})


# --- Where roads meet ---------------------------------------------------------------


## For every chain: {trim: [start, end] metres (negative = longer), gaps (no paint here):
## [[point, half length], ...], crossings: [[point, half], ...], neighbours: [chain...]}.
## Also fills _joins (a road ending on another: curved corners), _crosses and _dead_ends.
func _find_junctions() -> Array:
	var info: Array = []
	_joins.clear()
	_crosses.clear()
	_dead_ends.clear()
	for i in chains.size():
		info.append({"trim": [0.0, 0.0], "gaps": [], "crossings": [], "neighbours": []})
	for i in chains.size():
		var chain: Dictionary = chains[i]
		if chain["closed"]:
			continue
		var pts: Array = chain["points"]
		for end in [0, 1]:
			var p: Vector2 = pts[0] if end == 0 else pts.back()
			var inward: Vector2 = ((pts[0] - pts[1]) if end == 0 else (pts.back() - pts[pts.size() - 2])).normalized()
			var host := _host_at(p, i)
			if host < 0:
				_dead_ends.append([i, end])
				continue
			var other: Dictionary = chains[host]
			var hit := _closest_on(other, p)
			if not chain["asphalt"]:
				if other["asphalt"]:
					info[i]["trim"][end] = other["width"] * 0.5
				continue
			if not other["asphalt"]:
				continue
			var join := {"chain": i, "host": host, "point": p, "inward": inward,
					"host_point": hit[0], "host_dir": hit[1], "round": false}
			var at_end := _end_of(other, p)
			if at_end >= 0:
				var opts: Array = other["points"]
				var leave: Vector2 = ((opts[1] - opts[0]) if at_end == 0 else (opts[opts.size() - 2] - opts.back())).normalized()
				if leave.dot(inward) > 0.7:
					continue  # the road just carries on under another name
				# An L corner: the bigger road runs on to cover the corner square.
				var major: bool = chain["width"] > other["width"] or (is_equal_approx(chain["width"], other["width"]) and i < host)
				if major:
					info[i]["trim"][end] = -other["width"] * 0.5
					info[i]["neighbours"].append(host)
					continue
				join["host_dir"] = leave
			elif other["closed"] and _length(other) < 150.0:
				# A roundabout: the road runs a little way under the ring (which sits higher),
				# and curved corners round its edges onto the ring's outside.
				info[i]["trim"][end] = other["width"] * 0.5 - 1.5
				info[i]["neighbours"].append(host)
				info[host]["neighbours"].append(i)
				info[i]["gaps"].append([p, other["width"] * 0.5 + PAINT_GAP])
				join["round"] = true
				_joins.append(join)
				continue
			info[i]["trim"][end] = other["width"] * 0.5
			info[i]["neighbours"].append(host)
			info[host]["neighbours"].append(i)
			info[i]["gaps"].append([p, other["width"] * 0.5 + PAINT_GAP])
			_joins.append(join)
	# Roads that cross in the middle (the highway and the gate roads, lanes and alleys).
	for i in chains.size():
		for j in range(i + 1, chains.size()):
			for spot: Vector2 in _crossings(chains[i], chains[j]):
				for pair in [[i, j], [j, i]]:
					var other: Dictionary = chains[pair[1]]
					info[pair[0]]["gaps"].append([spot, other["width"] * 0.5 + 0.4])
					info[pair[0]]["crossings"].append([spot, other["width"] * 0.5 + 0.5])
				if chains[i]["asphalt"] and chains[j]["asphalt"]:
					_crosses.append({"a": i, "b": j, "spot": spot,
							"dir_a": _closest_on(chains[i], spot)[1], "dir_b": _closest_on(chains[j], spot)[1]})
	return info


func _length(chain: Dictionary) -> float:
	var pts: Array = chain["points"]
	var total := 0.0
	for k in pts.size() - 1:
		total += (pts[k + 1] - pts[k]).length()
	return total


## The chain whose middle line passes through p (the widest). A road that p lies in the
## middle of wins over one that only ends there, so a lane and a link meeting a cross road
## from opposite sides both join the cross road (not each other).
func _host_at(p: Vector2, skip: int) -> int:
	var best := -1
	var best_middle := false
	for j in chains.size():
		if j == skip:
			continue
		var hit := _closest_on(chains[j], p)
		if (hit[0] as Vector2).distance_to(p) >= 0.6:
			continue
		var middle := _end_of(chains[j], p) < 0
		if best < 0 or (middle and not best_middle) \
				or (middle == best_middle and chains[j]["width"] > chains[best]["width"]):
			best = j
			best_middle = middle
	return best


## Session 76: fills in where the asphalt and the kerb gaps are (RoadArea).
func _fill_area(map: Dictionary, junctions: Array) -> void:
	area = RoadArea.new()
	RoadArea.current = area
	for i in chains.size():
		var chain: Dictionary = chains[i]
		var pts: Array = chain["points"].duplicate()
		if not chain["closed"]:
			# A road that runs on past an L corner covers the corner square too.
			var trim: Array = junctions[i]["trim"]
			if trim[0] < 0.0:
				pts[0] = pts[0] + (pts[0] - pts[1]).normalized() * -trim[0]
			if trim[1] < 0.0:
				pts[-1] = pts[-1] + (pts[-1] - pts[-2]).normalized() * -trim[1]
		area.add_road(i, pts, chain["width"], chain["closed"], chain["asphalt"])
	# Crossings through the spine road's planters (where paths cross).
	var spine: Dictionary = map.get("SPINE_TRACKS", {})
	for gap: Array in spine.get("path_gaps", []):
		for side in [-1, 1]:
			if int(gap[1]) == 0 or int(gap[1]) == side:
				area.add_gap_circle(Vector2(gap[0], spine["road_half"] * side), gap[2])
	# Where the blue run-and-cycle track and the horse track cross a road (the gate roads).
	for key in ["BIKE_TRACK", "HORSE_TRACK"]:
		var track: Dictionary = map.get(key, {})
		if track.is_empty():
			continue
		var loop := EdgeBuilder.rounded_rect(track["half"], track.get("radius", 0.0))
		for k in loop.size():
			area.add_gap_line(loop[k], loop[(k + 1) % loop.size()], track["width"] * 0.5 + 0.3)
	for crossing: Dictionary in map.get("HORSE_CROSSINGS", []):
		var a: Vector3 = crossing["from"]
		var b: Vector3 = crossing["to"]
		area.add_gap_line(Vector2(a.x, a.z), Vector2(b.x, b.z), HORSE_CROSSING_HALF)
	# Car parks: their kerbs and layout are DistrictDetail's; the road kerbs stop at them.
	for lot: Rect2 in map.get("PARKING_AREAS", []):
		area.add_gap_rect(lot.grow(0.5))
	if map.has("PLAZA"):
		area.add_gap_circle(map["PLAZA"]["centre"], map["PLAZA"]["radius"] + PLAZA_REACH)
	for list_name: String in GAP_LISTS:
		for item in map.get(list_name, []):
			_add_gap_item(item)
	# Car parks listed in PARKING_LOTS (when the data has it): no kerb inside a lot, and a
	# gap all along each entrance, from where it leaves the road (at) to the lot (lot_at).
	for lot: Dictionary in map.get("PARKING_LOTS", []):
		for key in ["area", "rect", "bounds"]:
			if lot.get(key) is Rect2:
				area.add_gap_rect((lot[key] as Rect2).grow(0.5))
		for entrance: Dictionary in lot.get("entrances", []):
			var half: float = entrance.get("width", 6.0) * 0.5 + 0.5
			var ends: Array = []
			for key in ["at", "lot_at"]:
				if entrance.has(key):
					var p = entrance[key]
					ends.append(Vector2(p.x, p.z) if p is Vector3 else p)
			if ends.size() == 2:
				# If `at` is in the middle of a road, start the gap where the entrance leaves
				# that road's asphalt, so the kerb on the far side of the road stays. (The
				# entrance's own road, the one the lot end is on, doesn't count.)
				var own := area.road_at(ends[1])
				var dir: Vector2 = (ends[1] - ends[0]).normalized()
				var walked := 0.0
				while walked < ends[0].distance_to(ends[1]) and area.road_at(ends[0] + dir * walked, 0.0, own) >= 0:
					walked += 0.25
				var start: Vector2 = ends[0] + dir * walked
				area.add_gap_line(start, ends[1], half)
				if area.road_at(ends[0], 0.5, own) < 0:
					area.add_gap_circle(ends[0], half)
			if not ends.is_empty():
				area.add_gap_circle(ends.back(), half)


## One kerb gap from a data list: a point, {position, width}, or {from, to, width}.
func _add_gap_item(item) -> void:
	var flat := func(v) -> Vector2:
		return Vector2(v.x, v.z) if v is Vector3 else v
	if item is Vector2 or item is Vector3:
		area.add_gap_circle(flat.call(item), 3.0)
		return
	if not item is Dictionary:
		return
	var half: float = item.get("half", item.get("width", 6.0) * 0.5)
	if item.has("from") and item.has("to"):
		area.add_gap_line(flat.call(item["from"]), flat.call(item["to"]), half)
		return
	for key in ["position", "at", "centre"]:
		if item.has(key):
			area.add_gap_circle(flat.call(item[key]), half)
			return


## [closest point, unit direction there] on a chain's middle line.
func _closest_on(chain: Dictionary, p: Vector2) -> Array:
	var pts: Array = chain["points"]
	var count: int = pts.size() if chain["closed"] else pts.size() - 1
	var best := [Vector2(INF, INF), Vector2.RIGHT]
	var best_d := INF
	for k in count:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % pts.size()]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := q.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = [q, (b - a).normalized()]
	return best


## 0 or 1 if p is the first or last point of an open chain, else -1.
func _end_of(chain: Dictionary, p: Vector2) -> int:
	if chain["closed"]:
		return -1
	var pts: Array = chain["points"]
	if (pts[0] as Vector2).distance_to(p) < 0.35:
		return 0
	if (pts.back() as Vector2).distance_to(p) < 0.35:
		return 1
	return -1


## Points where two chains' middle lines cross, away from either chain's ends.
func _crossings(a: Dictionary, b: Dictionary) -> Array:
	var found: Array = []
	var pa: Array = a["points"]
	var pb: Array = b["points"]
	var na: int = pa.size() if a["closed"] else pa.size() - 1
	var nb: int = pb.size() if b["closed"] else pb.size() - 1
	for i in na:
		var a0: Vector2 = pa[i]
		var a1: Vector2 = pa[(i + 1) % pa.size()]
		for j in nb:
			var b0: Vector2 = pb[j]
			var b1: Vector2 = pb[(j + 1) % pb.size()]
			var hit = Geometry2D.segment_intersects_segment(a0, a1, b0, b1)
			if hit == null:
				continue
			var spot: Vector2 = hit
			if _end_of(a, spot) >= 0 or _end_of(b, spot) >= 0:
				continue
			if not found.any(func(f): return (f as Vector2).distance_to(spot) < 0.5):
				found.append(spot)
	return found


## Roads that meet get different heights a couple of millimetres apart: the ring road and
## the big roads first (highest), then each road takes the highest height none of the
## roads it meets has taken. Too small to see, but it stops any flicker where they touch.
func _pick_heights(junctions: Array) -> void:
	var order: Array = range(chains.size())
	order.sort_custom(func(a, b):
		var ca: Dictionary = chains[a]
		var cb: Dictionary = chains[b]
		if ca["closed"] != cb["closed"]:
			return ca["closed"]
		if not is_equal_approx(ca["width"], cb["width"]):
			return ca["width"] > cb["width"]
		return a < b)
	var level := {}
	for i: int in order:
		var chain: Dictionary = chains[i]
		if not chain["asphalt"]:
			chain["top"] = PAVING_TOP
			continue
		if chain["name"] in UNDER:
			chain["top"] = UNDER_TOP
			continue
		var taken := {}
		for j: int in junctions[i]["neighbours"]:
			if level.has(j):
				taken[level[j]] = true
		var mine := 0
		while taken.has(mine):
			mine += 1
		level[i] = mine
		chain["top"] = ASPHALT_TOP - LEVEL_STEP * mine
	stats["levels"] = level.values().max() + 1 if not level.is_empty() else 0


## Counts places where two road surfaces overlap at the same height (should be none).
func _count_overlaps(junctions: Array) -> void:
	var bad := 0
	for i in chains.size():
		for c in junctions[i]["crossings"]:
			for j in chains.size():
				if j != i and is_equal_approx(chains[j]["top"], chains[i]["top"]) and chains[j]["asphalt"] == chains[i]["asphalt"]:
					var hit := _closest_on(chains[j], c[0])
					if (hit[0] as Vector2).distance_to(c[0]) < 0.5:
						bad += 1
	for i in chains.size():
		for j: int in junctions[i]["neighbours"]:
			if chains[i]["asphalt"] and chains[j]["asphalt"] and is_equal_approx(chains[i]["top"], chains[j]["top"]):
				bad += 2
	stats["same_height_overlaps"] = bad / 2


# --- Building one chain --------------------------------------------------------------

func _build_chain(index: int, info: Dictionary) -> void:
	var chain: Dictionary = chains[index]
	var pts := _resample(_trimmed(chain, info["trim"]), chain["closed"])
	if pts.size() < 2:
		return
	var top: float = chain["top"]
	var half: float = chain["width"] * 0.5
	var closed: bool = chain["closed"]
	var sides := _sides(pts, closed)
	var along := _lengths(pts, closed)
	var kind := "asphalt" if chain["asphalt"] else "paving"
	# The surface: three rows across (edge, middle, edge), the middle a little darker.
	var rows := pts.size() if not closed else pts.size() + 1
	for k in rows - 1:
		var a := k % pts.size()
		var b := (k + 1) % pts.size()
		var wear_a := 1.0 - 0.05 * _noise(along[a] * 0.13 + index)
		var wear_b := 1.0 - 0.05 * _noise((along[a] + (pts[b] - pts[a]).length()) * 0.13 + index)
		var v_a: float = along[a] / TILE
		var v_b: float = (along[a] + (pts[b] - pts[a]).length()) / TILE
		for lane in [[-1.0, 0.0], [0.0, 1.0]]:
			var l0: float = lane[0]
			var l1: float = lane[1]
			var shade0 := wear_a * (1.0 - 0.12 * (1.0 - absf(l0)))
			var shade1 := wear_a * (1.0 - 0.12 * (1.0 - absf(l1)))
			var shade2 := wear_b * (1.0 - 0.12 * (1.0 - absf(l0)))
			var shade3 := wear_b * (1.0 - 0.12 * (1.0 - absf(l1)))
			var p0: Vector2 = pts[a] + sides[a] * half * l0
			var p1: Vector2 = pts[a] + sides[a] * half * l1
			var p2: Vector2 = pts[b] + sides[b] * half * l0
			var p3: Vector2 = pts[b] + sides[b] * half * l1
			var u0 := (l0 + 1.0) * half / TILE
			var u1 := (l1 + 1.0) * half / TILE
			_quad(kind, [p0, p1, p2, p3], top, [Color(shade0, shade0, shade0), Color(shade1, shade1, shade1),
					Color(shade2, shade2, shade2), Color(shade3, shade3, shade3)],
					[Vector2(u0, v_a), Vector2(u1, v_a), Vector2(u0, v_b), Vector2(u1, v_b)])
	if not chain["asphalt"]:
		return
	# Kept for the kerbs: the road's edges are these points moved half the width sideways.
	chain["drawn"] = pts
	chain["sides"] = sides
	var no_paint: Array = info["gaps"] + info["crossings"] + _zebras(pts, half, top)
	var one_way: int = ONE_WAY.get(chain["name"], 0)
	if one_way == 0:
		_centre_line(pts, along, closed, top, no_paint)
	var every := RING_ARROW_EVERY if chain["name"] == "Ring Road" else (ROUNDABOUT_ARROW_EVERY if one_way != 0 and closed else ARROW_EVERY)
	_arrows(pts, sides, along, closed, half, top, one_way, every, no_paint)


## The chain's points with its ends shortened (or made longer, if negative).
func _trimmed(chain: Dictionary, trim: Array) -> Array:
	var pts: Array = chain["points"].duplicate()
	if chain["closed"]:
		return pts
	for end in [0, 1]:
		var amount: float = trim[end]
		if end == 1:
			pts.reverse()
		if amount < 0.0:
			pts[0] = pts[0] + (pts[0] - pts[1]).normalized() * -amount
		else:
			while amount > 0.0 and pts.size() >= 2:
				var piece: float = (pts[1] - pts[0]).length()
				if piece > amount + 0.01:
					pts[0] = pts[0] + (pts[1] - pts[0]).normalized() * amount
					amount = 0.0
				else:
					pts.pop_front()
					amount -= piece
		if end == 1:
			pts.reverse()
	return pts


## Cuts long straight pieces into STEP-long bits (curves already have short pieces).
func _resample(pts: Array, closed: bool) -> Array:
	var out: Array = []
	var count := pts.size() if closed else pts.size() - 1
	for k in count:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % pts.size()]
		var bits := maxi(1, ceili(a.distance_to(b) / STEP))
		for s in bits:
			out.append(a.lerp(b, float(s) / bits))
	if not closed and not pts.is_empty():
		out.append(pts.back())
	return out


## The right-hand side direction at every point, longer at corners so the width stays even.
func _sides(pts: Array, closed: bool) -> Array:
	var out: Array = []
	var n := pts.size()
	for k in n:
		var prev: Vector2 = pts[(k - 1 + n) % n] if (closed or k > 0) else pts[k]
		var next: Vector2 = pts[(k + 1) % n] if (closed or k < n - 1) else pts[k]
		var d1: Vector2 = (pts[k] - prev).normalized() if pts[k] != prev else (next - pts[k]).normalized()
		var d2: Vector2 = (next - pts[k]).normalized() if next != pts[k] else d1
		var s1 := Vector2(-d1.y, d1.x)
		var s2 := Vector2(-d2.y, d2.x)
		var mid := (s1 + s2).normalized()
		var stretch := 1.0 / maxf(mid.dot(s1), 0.5)
		out.append(mid * stretch)
	return out


func _lengths(pts: Array, _closed: bool) -> Array:
	var out: Array = [0.0]
	for k in range(1, pts.size()):
		out.append(out[k - 1] + (pts[k] - pts[k - 1]).length())
	return out


## Smooth 0..1 wobble for light wear along the road.
func _noise(x: float) -> float:
	return 0.5 + 0.3 * sin(x * 1.7) + 0.2 * sin(x * 4.3 + 1.1)


## A curved corner piece: asphalt filling the corner up to the curve, just under both
## roads it joins, so it never shares their height.
func _fillet(corner: Dictionary) -> void:
	var top: float = minf(chains[corner["chain"]]["top"], chains[corner["host"]]["top"]) - LEVEL_STEP * 0.5
	var poly: PackedVector2Array = corner["poly"]
	var tris := Geometry2D.triangulate_polygon(poly)
	for k in range(0, tris.size(), 3):
		var a := poly[tris[k]]
		var b := poly[tris[k + 1]]
		var c := poly[tris[k + 2]]
		_tri("asphalt", [a, b, c], top, Color.WHITE, a / TILE, b / TILE, c / TILE)


## Session 76: the kerbs. Every road edge, every curved corner and the end of every road
## that just stops is a kerb line; RoadKerbs cuts them where they'd lie on other asphalt or
## in a gap. The runs that are left are drawn as raised kerbs and given to KerbBumps.
func _build_kerbs() -> void:
	kerbs = RoadKerbs.new(area)
	for i in chains.size():
		var chain: Dictionary = chains[i]
		if not chain["asphalt"] or not chain.has("drawn"):
			continue
		var pts: Array = chain["drawn"]
		var sides: Array = chain["sides"]
		var half: float = chain["width"] * 0.5
		for side in [-1.0, 1.0]:
			var edge: Array = []
			var out: Array = []
			for k in pts.size():
				edge.append(pts[k] + sides[k] * half * side)
				out.append((sides[k] as Vector2).normalized() * side)
			kerbs.add_line(edge, out, chain["closed"], i)
	for f in corners.size():
		var arc: Array = corners[f]["arc"]
		var centre: Vector2 = corners[f]["centre"]
		kerbs.add_line(arc, arc.map(func(q): return (centre - q).normalized()), false, -1, f)
	# A road that just stops (and doesn't run into a car park or the Plaza): a kerb across its end.
	for dead: Array in _dead_ends:
		var chain: Dictionary = chains[dead[0]]
		if not chain["asphalt"] or not chain.has("drawn"):
			continue
		var pts: Array = chain["drawn"]
		var k: int = 0 if dead[1] == 0 else pts.size() - 1
		var p: Vector2 = pts[k]
		if area.in_gap(p):
			continue
		var ahead: Vector2 = ((pts[0] - pts[1]) if k == 0 else (pts[k] - pts[k - 1])).normalized()
		var across: Vector2 = Vector2(-ahead.y, ahead.x) * float(chain["width"]) * 0.5
		kerbs.add_line([p - across, p + across], [ahead, ahead], false, dead[0])
		stats["dead_end_caps"] += 1
	bumps = KerbBumps.new()
	bumps.name = "KerbBumps"
	add_child(bumps)
	for run: Dictionary in kerbs.runs:
		_kerb_run(run)
		var middle: Array = []
		for k in run["points"].size():
			middle.append(run["points"][k] + run["out"][k] * GameConfig.KERB_WIDTH * 0.5)
		if run["closed"]:
			middle.append(middle[0])
		bumps.add_line(middle)
	stats["kerb_runs"] = kerbs.runs.size()
	stats["kerb_metres"] = roundi(kerbs.length())


## One kerb run as a raised strip: a top, the face towards the road, the back face and an
## end at each open end.
func _kerb_run(run: Dictionary) -> void:
	var pts: Array = run["points"]
	var outs: Array = run["out"]
	var n := pts.size()
	var count := n if run["closed"] else n - 1
	var top := ASPHALT_TOP + GameConfig.KERB_HEIGHT
	var width := GameConfig.KERB_WIDTH
	for k in count:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % n]
		var oa: Vector2 = a + (outs[k] as Vector2) * width
		var ob: Vector2 = b + (outs[(k + 1) % n] as Vector2) * width
		_quad("kerb", [a, oa, b, ob], top, [KERB, KERB, KERB, KERB], [a, oa, b, ob])
		var out: Vector2 = ((outs[k] as Vector2) + (outs[(k + 1) % n] as Vector2)).normalized()
		_wall(a, b, top, -out, KERB_FACE)
		_wall(oa, ob, top, out, KERB_FACE)
		stats["kerb_pieces"] += 1
	if not run["closed"]:
		for k in [0, n - 1]:
			var p: Vector2 = pts[k]
			var o: Vector2 = p + (outs[k] as Vector2) * width
			var end_dir: Vector2 = (pts[0] - pts[1]) if k == 0 else (pts[k] - pts[k - 1])
			_wall(p, o, top, end_dir.normalized(), KERB_FACE)


## A flat upright face from a to b, from the ground up to `top`, facing `facing` (flat).
func _wall(a: Vector2, b: Vector2, top: float, facing: Vector2, colour: Color) -> void:
	var face := Vector3(facing.x, 0, facing.y)
	var a0 := Vector3(a.x, 0.0, a.y)
	var b0 := Vector3(b.x, 0.0, b.y)
	var a1 := Vector3(a.x, top, a.y)
	var b1 := Vector3(b.x, top, b.y)
	_tri3("kerb", [a0, b0, a1], face, colour)
	_tri3("kerb", [b0, b1, a1], face, colour)


## Yellow dashes down the middle.
func _centre_line(pts: Array, along: Array, closed: bool, top: float, no_paint: Array) -> void:
	var total: float = along.back() + ((pts[0] - pts.back()).length() if closed else 0.0)
	var s := DASH * 0.5
	while s + DASH < total - 0.5:
		var a := _point_at(pts, along, closed, s)
		var m := _point_at(pts, along, closed, s + DASH * 0.5)
		var b := _point_at(pts, along, closed, s + DASH)
		if not _near(m[0], no_paint):
			_paint_strip("yellow", [a, m, b], 0.0, LINE_WIDTH, top)
			stats["dashes"] += 1
		s += DASH * 2.0


## Session 90: paints the zebra crossings (ZEBRA_CROSSINGS) that lie on this road: white bars
## as long as the crossing is wide, lying along the road, one after another from one edge to
## the other (you step over them as you cross). Returns [middle, half length] for each, so the
## centre line and arrows leave the crossing clear.
func _zebras(pts: Array, half: float, top: float) -> Array:
	var clear: Array = []
	for zebra: Dictionary in _zebra_list:
		var a: Vector2 = zebra["from"]
		var b: Vector2 = zebra["to"]
		var middle := (a + b) * 0.5
		var on_road := false
		for k in pts.size() - 1:
			on_road = on_road or Geometry2D.get_closest_point_to_segment(middle, pts[k], pts[k + 1]).distance_to(middle) < half * 0.5
		if not on_road:
			continue
		var across := (b - a).normalized()
		var along := Vector2(-across.y, across.x)
		var width: float = zebra.get("width", 3.0)
		var stripe := GameConfig.ZEBRA_STRIPE
		var length := a.distance_to(b)
		var count := maxi(1, int((length - 0.3 + stripe) / (stripe * 2.0)))  # bar, gap, bar...
		for k in count:
			var centre := middle + across * ((k - (count - 1) * 0.5) * stripe * 2.0)
			var p := centre - across * stripe * 0.5
			var q := centre + across * stripe * 0.5
			var side := along * width * 0.5
			var quad := [p - side, p + side, q - side, q + side]
			_quad("white", quad, top + MARK_LIFT, [WHITE, WHITE, WHITE, WHITE], quad)
			stats["zebra_stripes"] += 1
		stats["zebras"] += 1
		clear.append([middle, width * 0.5 + 1.0])
	return clear


## White arrows: one on each side (pointing the way that side drives), or one in the
## middle of a one-way road.
func _arrows(pts: Array, sides: Array, along: Array, closed: bool, half: float, top: float,
		one_way: int, every: float, no_paint: Array) -> void:
	var total: float = along.back() + ((pts[0] - pts.back()).length() if closed else 0.0)
	if not closed and total < 24.0:
		return
	var s := every * 0.5 if not closed else every * 0.25
	while s < total - (0.0 if closed else 10.0):
		var here := _point_at(pts, along, closed, s)
		if (closed or s > 10.0) and not _near(here[0], no_paint, 6.0):
			var d: Vector2 = here[1]
			var right := Vector2(-d.y, d.x)
			if one_way != 0:
				_arrow(here[0], d * one_way, top)
			else:
				_arrow(here[0] + right * half * 0.5, d, top)
				_arrow(here[0] - right * half * 0.5, -d, top)
		s += every


func _arrow(at: Vector2, d: Vector2, top: float) -> void:
	var r := Vector2(-d.y, d.x)
	var y := top + MARK_LIFT
	var shaft := [at - d * 1.0 - r * 0.12, at - d * 1.0 + r * 0.12, at + d * 0.25 - r * 0.12, at + d * 0.25 + r * 0.12]
	_quad("white", shaft, y, [WHITE, WHITE, WHITE, WHITE], shaft)
	_tri("white", [at + d * 0.25 - r * 0.42, at + d * 0.25 + r * 0.42, at + d * 1.05], y, WHITE, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	stats["arrows"] += 1


## A thin painted strip through a few points [point, direction].
func _paint_strip(kind: String, marks: Array, offset: float, width: float, top: float) -> void:
	var y := top + MARK_LIFT
	for k in marks.size() - 1:
		var a: Vector2 = marks[k][0]
		var b: Vector2 = marks[k + 1][0]
		var ra: Vector2 = Vector2(-marks[k][1].y, marks[k][1].x)
		var rb: Vector2 = Vector2(-marks[k + 1][1].y, marks[k + 1][1].x)
		var quad := [a + ra * (offset - width * 0.5), a + ra * (offset + width * 0.5),
				b + rb * (offset - width * 0.5), b + rb * (offset + width * 0.5)]
		_quad(kind, quad, y, [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], quad)


## [position, direction] at distance s along the points.
func _point_at(pts: Array, along: Array, closed: bool, s: float) -> Array:
	var n := pts.size()
	var total: float = along.back() + ((pts[0] - pts.back()).length() if closed else 0.0)
	s = fposmod(s, total) if closed else clampf(s, 0.0, total)
	var k := 0
	while k < n - 1 and along[k + 1] < s:
		k += 1
	var a: Vector2 = pts[k]
	var b: Vector2 = pts[(k + 1) % n] if (closed or k < n - 1) else pts[k]
	var start: float = along[k]
	var piece := a.distance_to(b)
	if piece < 0.0001:
		return [a, (pts[k] - pts[maxi(k - 1, 0)]).normalized()]
	return [a.lerp(b, clampf((s - start) / piece, 0.0, 1.0)), (b - a) / piece]


func _near(p: Vector2, spots: Array, extra := 0.0) -> bool:
	for spot in spots:
		if p.distance_to(spot[0]) < spot[1] + extra:
			return true
	return false


# --- Mesh batching -------------------------------------------------------------------

func _batch(kind: String, at: Vector2) -> Dictionary:
	# A number key (kind, square) is much quicker than building a text key every triangle.
	var key := Vector3i(KINDS.find(kind), floori(at.x / CELL), floori(at.y / CELL))
	if not _batches.has(key):
		_batches[key] = {"kind": kind, "verts": PackedVector3Array(), "normals": PackedVector3Array(),
				"colours": PackedColorArray(), "uvs": PackedVector2Array()}
	return _batches[key]


## A flat quad given as [p0, p1, p2, p3] where p0-p1 is one end and p2-p3 the other.
func _quad(kind: String, p: Array, y: float, colours: Array, uvs: Array) -> void:
	_tri(kind, [p[0], p[1], p[2]], y, colours[0], uvs[0], uvs[1], uvs[2], [colours[0], colours[1], colours[2]])
	_tri(kind, [p[1], p[3], p[2]], y, colours[1], uvs[1], uvs[3], uvs[2], [colours[1], colours[3], colours[2]])


## A flat triangle facing up (the corners are put in the order the renderer wants).
func _tri(kind: String, p: Array, y: float, colour: Color, uv0: Vector2, uv1: Vector2, uv2: Vector2, colours := []) -> void:
	var a := Vector3(p[0].x, y, p[0].y)
	var b := Vector3(p[1].x, y, p[1].y)
	var c := Vector3(p[2].x, y, p[2].y)
	var cols: Array = colours if colours.size() == 3 else [colour, colour, colour]
	var uvs := [uv0, uv1, uv2]
	if (b - a).cross(c - a).y > 0.0:
		var t := b
		b = c
		c = t
		cols = [cols[0], cols[2], cols[1]]
		uvs = [uvs[0], uvs[2], uvs[1]]
	var batch := _batch(kind, p[0])
	batch["verts"].append_array([a, b, c])
	batch["normals"].append_array([Vector3.UP, Vector3.UP, Vector3.UP])
	batch["colours"].append_array(cols)
	batch["uvs"].append_array(uvs)


## A triangle that faces a given way (for the kerb fronts).
func _tri3(kind: String, p: Array, facing: Vector3, colour: Color) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var c: Vector3 = p[2]
	if (b - a).cross(c - a).dot(facing) > 0.0:
		var t := b
		b = c
		c = t
	var batch := _batch(kind, Vector2(a.x, a.z))
	batch["verts"].append_array([a, b, c])
	batch["normals"].append_array([facing, facing, facing])
	batch["colours"].append_array([colour, colour, colour])
	batch["uvs"].append_array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func _material(kind: String) -> Material:
	if _materials.has(kind):
		return _materials[kind]
	var mat: StandardMaterial3D
	match kind:
		"asphalt":
			mat = asphalt_material()
		"paving":
			mat = TerrainMaterials.make("paving")
		_:
			mat = StandardMaterial3D.new()
			mat.vertex_color_use_as_albedo = kind == "kerb"
			mat.albedo_color = {"yellow": YELLOW, "white": WHITE}.get(kind, Color.WHITE)
			mat.roughness = 0.85
	_materials[kind] = mat
	return mat


func _finish() -> void:
	for key: Vector3i in _batches:
		var batch: Dictionary = _batches[key]
		if batch["verts"].is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = batch["verts"]
		arrays[Mesh.ARRAY_NORMAL] = batch["normals"]
		arrays[Mesh.ARRAY_COLOR] = batch["colours"]
		arrays[Mesh.ARRAY_TEX_UV] = batch["uvs"]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, _material(batch["kind"]))
		var view := MeshInstance3D.new()
		view.name = ("%s_%d_%d" % [batch["kind"], key.y, key.z]).replace("-", "m")
		view.mesh = mesh
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if batch["kind"] in ["yellow", "white"]:
			view.visibility_range_end = 220.0
		add_child(view)
		stats["meshes"] += 1
	_batches.clear()
