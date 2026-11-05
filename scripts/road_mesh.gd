class_name RoadMesh
extends Node3D
## Session 61: real road surfaces built from the map's ROADS list.
## The short pieces of each road are joined into one smooth strip ("chain"), so rounded
## corners and the roundabout are real curves, not overlapping boxes. On every asphalt road:
## a CC0 asphalt texture that is a little darker in the middle, a yellow dashed centre line,
## white arrows on each side showing which way to drive (on the right, like the UAE), and a
## low kerb on both sides. Where a road meets another, it stops at the other road's edge and
## a curved corner piece (a "fillet") fills the gap, so no two road surfaces lie on top of
## each other at the same height (that is what made textures flicker). Pavers sit lower than
## asphalt, so asphalt always runs through on top.
## Everything is flat with no collision (you ride over it) and merged into a few big meshes
## per 120 m square, so it stays fast on Low.

const ASPHALT_TOP := 0.05     # road surface height (speed bumps sit on this)
const UNDER_TOP := 0.04       # a road that passes under a crossing road (the highway)
const LEVEL_STEP := 0.002     # roads that meet are this much apart in height (never equal)
const PAVING_TOP := 0.035     # paver paths, lower than asphalt
const MARK_LIFT := 0.006      # paint sits this far above the asphalt
const KERB_TOP := 0.13
const KERB_WIDTH := 0.25
const FILLET := 3.0           # radius of the curved corner where two roads meet
const STEP := 1.5             # roads are cut into pieces this long (for curves and gaps)
const TILE := 6.0             # one asphalt texture tile covers this many metres
const DASH := 3.0             # centre line: 3 m paint, 3 m gap
const LINE_WIDTH := 0.14
const ARROW_EVERY := 40.0
const RING_ARROW_EVERY := 60.0
const ROUNDABOUT_ARROW_EVERY := 14.0
const CELL := 120.0
const ASPHALT_MIN_WIDTH := 6.0
## One-way roads: +1 drives from the first point to the last, -1 the other way.
## The roundabout goes anticlockwise, as roundabouts do when you drive on the right.
const ONE_WAY := {"Institute Roundabout": -1, "Bus Loop": 1}
const UNDER := ["Highway"]
## Roads whose kerbs another builder makes (Session 62: SpineTracks builds the spine road's).
const NO_KERB := ["Spine Road"]

const YELLOW := Color(0.96, 0.78, 0.18)
const WHITE := Color(0.95, 0.95, 0.92)
const KERB := Color(0.8, 0.78, 0.74)

## The joined roads: {name, width, asphalt, points (Array of Vector2), closed, top}.
var chains: Array = []
## Counts for the smoke test.
var stats := {"chains": 0, "asphalt_chains": 0, "dashes": 0, "arrows": 0, "fillets": 0,
		"kerb_pieces": 0, "same_height_overlaps": 0, "meshes": 0}

var _batches := {}           # "kind|cell" -> {verts, normals, colours, uvs}
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
	_add_parking_access(map)
	var junctions := _find_junctions()
	_pick_heights(junctions)
	for i in chains.size():
		_build_chain(i, junctions[i])
	_count_overlaps(junctions)
	_finish()
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
	for area: Rect2 in map.get("PARKING_AREAS", []):
		var north := area.get_center().y < 0.0
		var x := parking_access_x(area)
		var edge := -half.y if north else half.y
		chains.append({"name": "Car Park Access", "width": 6.0, "asphalt": true,
				"points": [Vector2(x, edge), Vector2(x, area.end.y - 9.0)], "closed": false})


# --- Where roads meet ---------------------------------------------------------------

## For every chain: {trim: [start, end] metres (negative = longer), fillets: [...],
## gaps: [[point, half length, side or Vector2.ZERO], ...], crossings: [point...]}.
func _find_junctions() -> Array:
	var info: Array = []
	for i in chains.size():
		info.append({"trim": [0.0, 0.0], "fillets": [], "gaps": [], "crossings": [], "neighbours": []})
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
				continue
			var other: Dictionary = chains[host]
			var hit := _closest_on(other, p)
			if not chain["asphalt"]:
				if other["asphalt"]:
					info[i]["trim"][end] = other["width"] * 0.5
					info[host]["gaps"].append([hit[0], chain["width"] * 0.5 + 0.3, -inward])
				continue
			if not other["asphalt"]:
				continue
			var away: Array[Vector2] = []
			var at_end := _end_of(other, p)
			if at_end >= 0:
				var opts: Array = other["points"]
				var leave: Vector2 = ((opts[1] - opts[0]) if at_end == 0 else (opts[opts.size() - 2] - opts.back())).normalized()
				if leave.dot(inward) > 0.7:
					continue  # the road just carries on under another name
				var major: bool = chain["width"] > other["width"] or (is_equal_approx(chain["width"], other["width"]) and i < host)
				if major:
					info[i]["trim"][end] = -other["width"] * 0.5
					info[i]["gaps"].append([p, other["width"] * 0.5 + FILLET, leave])
					info[i]["neighbours"].append(host)
					continue
				away.append(leave)
			elif other["closed"] and _length(other) < 150.0:
				# A roundabout: the road runs a little way into the curved ring (it sits lower,
				# so the ring stays on top) instead of curved corners against a curved edge.
				info[i]["trim"][end] = other["width"] * 0.5 - 1.5
				info[i]["neighbours"].append(host)
				info[host]["neighbours"].append(i)
				info[host]["gaps"].append([hit[0], chain["width"] * 0.5 + 1.2, -inward])
				continue
			else:
				var tangent: Vector2 = hit[1]
				away.append(tangent)
				away.append(-tangent)
			info[i]["trim"][end] = other["width"] * 0.5
			info[i]["neighbours"].append(host)
			info[host]["neighbours"].append(i)
			var gap_half: float = chain["width"] * 0.5 + FILLET
			info[host]["gaps"].append([hit[0], gap_half, -inward])
			for u: Vector2 in away:
				if absf(u.dot(inward)) < 0.8:
					info[i]["fillets"].append({"point": p, "inward": inward, "along": u,
							"host_half": other["width"] * 0.5, "own_half": chain["width"] * 0.5, "top": 0.0, "host": host})
			# Its own kerbs stop where the curved corners start.
			info[i]["gaps"].append([p - inward * other["width"] * 0.5, FILLET, Vector2.ZERO])
	# Roads that cross in the middle (the highway and the gate roads, lanes and alleys).
	for i in chains.size():
		for j in range(i + 1, chains.size()):
			for spot: Vector2 in _crossings(chains[i], chains[j]):
				for pair in [[i, j], [j, i]]:
					var other: Dictionary = chains[pair[1]]
					info[pair[0]]["gaps"].append([spot, other["width"] * 0.5 + 0.4, Vector2.ZERO])
					info[pair[0]]["crossings"].append([spot, other["width"] * 0.5 + 0.5])
	return info


func _length(chain: Dictionary) -> float:
	var pts: Array = chain["points"]
	var total := 0.0
	for k in pts.size() - 1:
		total += (pts[k + 1] - pts[k]).length()
	return total


## The asphalt (or any, for paver paths) chain whose middle line passes through p.
func _host_at(p: Vector2, skip: int) -> int:
	var best := -1
	for j in chains.size():
		if j == skip:
			continue
		var hit := _closest_on(chains[j], p)
		if (hit[0] as Vector2).distance_to(p) < 0.6:
			if best < 0 or chains[j]["width"] > chains[best]["width"]:
				best = j
	return best


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
	for fillet: Dictionary in info["fillets"]:
		# Just under both roads it joins, so it never shares their height.
		fillet["top"] = minf(top, chains[fillet["host"]]["top"]) - LEVEL_STEP * 0.5
		_fillet(fillet, top)
	if not chain["name"] in NO_KERB:
		_kerbs(pts, sides, closed, half, top, info["gaps"])
	var no_paint: Array = []
	for g in info["gaps"]:
		if g[2] == Vector2.ZERO:
			no_paint.append([g[0], g[1]])
	for c in info["crossings"]:
		no_paint.append(c)
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


## The curved corner piece between a road that ends and the road it meets.
func _fillet(f: Dictionary, top: float) -> void:
	var d: Vector2 = f["inward"]
	var u: Vector2 = f["along"]
	var corner: Vector2 = f["point"] - d * f["host_half"] + u * f["own_half"]
	var t1 := corner - d * FILLET
	var t2 := corner + u * FILLET
	var centre := corner - d * FILLET + u * FILLET
	var arc: Array = []
	for s in 7:  # from t1 (centre - u R) round to t2 (centre + d R)
		var angle := PI * 0.5 * s / 6.0
		arc.append(centre + (-u * cos(angle) + d * sin(angle)) * FILLET)
	arc[0] = t1
	arc[6] = t2
	for s in 6:
		_tri("asphalt", [corner, arc[s], arc[s + 1]], f["top"], Color.WHITE, corner / TILE, arc[s] / TILE, arc[s + 1] / TILE)
	# The kerb follows the curve, set back from the road.
	for s in 6:
		var a0: Vector2 = arc[s]
		var a1: Vector2 = arc[s + 1]
		var o0: Vector2 = a0 + (centre - a0).normalized() * KERB_WIDTH
		var o1: Vector2 = a1 + (centre - a1).normalized() * KERB_WIDTH
		_kerb_piece(a0, a1, o0, o1, top)
	stats["fillets"] += 1


## Low kerbs along both edges, with gaps where other roads and paths join.
func _kerbs(pts: Array, sides: Array, closed: bool, half: float, top: float, gaps: Array) -> void:
	var n := pts.size()
	var count := n if closed else n - 1
	for side in [-1.0, 1.0]:
		for k in count:
			var a := k
			var b := (k + 1) % n
			var mid: Vector2 = (pts[a] + pts[b]) * 0.5
			var out_dir: Vector2 = (sides[a] + sides[b]).normalized() * side
			if _in_gap(mid, out_dir, gaps):
				continue
			var i0: Vector2 = pts[a] + sides[a] * half * side
			var i1: Vector2 = pts[b] + sides[b] * half * side
			var o0: Vector2 = pts[a] + sides[a] * (half + KERB_WIDTH) * side
			var o1: Vector2 = pts[b] + sides[b] * (half + KERB_WIDTH) * side
			_kerb_piece(i0, i1, o0, o1, top)


func _in_gap(mid: Vector2, out_dir: Vector2, gaps: Array) -> bool:
	for g in gaps:
		var spot: Vector2 = g[0]
		var gap_half: float = g[1]
		var side: Vector2 = g[2]
		if mid.distance_to(spot) > gap_half:
			continue
		if side == Vector2.ZERO or side.dot(out_dir) > 0.3:
			return true
	return false


## One bit of kerb: a top and the face towards the road.
func _kerb_piece(i0: Vector2, i1: Vector2, o0: Vector2, o1: Vector2, top: float) -> void:
	_quad("kerb", [i0, o0, i1, o1], KERB_TOP, [KERB, KERB, KERB, KERB], [i0, o0, i1, o1])
	var a := Vector3(i0.x, top - 0.01, i0.y)
	var b := Vector3(i1.x, top - 0.01, i1.y)
	var c := Vector3(i0.x, KERB_TOP, i0.y)
	var d := Vector3(i1.x, KERB_TOP, i1.y)
	var facing := Vector3(i0.x - o0.x, 0, i0.y - o0.y).normalized()
	_tri3("kerb", [a, b, c], facing, KERB)
	_tri3("kerb", [b, d, c], facing, KERB)
	stats["kerb_pieces"] += 1


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
	var key := "%s|%d|%d" % [kind, floori(at.x / CELL), floori(at.y / CELL)]
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
	for key: String in _batches:
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
		view.name = key.replace("|", "_").replace("-", "m")
		view.mesh = mesh
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if batch["kind"] in ["yellow", "white"]:
			view.visibility_range_end = 220.0
		add_child(view)
		stats["meshes"] += 1
	_batches.clear()
