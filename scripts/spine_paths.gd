class_name SpinePaths
extends RefCounted
## Session 63: the spine's paths, the way Louis asked (PRD "Looks pass", Appendix D).
## WahatBuilder lays the red walking track and the buggy road from ROADS. This adds what
## goes with them, north to south:
##   - small paved aprons from every dome door (and pool gate) to the red track
##   - white edge lines and "WALK · مشي" painted on the track every 40 m
##   - a grey stone kerb, the raised planted strip (1.4 m) and another kerb
##   - the white dashed middle line on the buggy road (1.5 m dash, 1.5 m gap)
## Where a path crosses, the kerbs and strip stop (a dropped kerb), so you can ride across.
## Kerbs and the strip aren't solid: like the car park kerbs, you ride over them.

const KERB := Color(0.8, 0.79, 0.75, 1)
const WHITE := Color(0.96, 0.96, 0.93, 1)
const CHUNK := 64.0   # lines are made in pieces this long, so far pieces aren't drawn


## The track and the buggy road from the data (by the names in SPINE_PATHS).
static func track(map: Dictionary) -> Dictionary:
	return _road(map, map["SPINE_PATHS"]["track"])


static func buggy_road(map: Dictionary) -> Dictionary:
	return _road(map, map["SPINE_PATHS"]["road"])


## The strips between the track and the road, north to south: [[name, z from, z to], ...].
static func cross_section(map: Dictionary) -> Array:
	var spec: Dictionary = map["SPINE_PATHS"]
	var t := track(map)
	var r := buggy_road(map)
	var kerb: float = spec["kerb_width"]
	var start: float = t["from"].y + t["width"] * 0.5      # the track's south edge
	var finish: float = r["from"].y - r["width"] * 0.5      # the road's north edge
	return [["track", t["from"].y - t["width"] * 0.5, start], ["kerb", start, start + kerb],
			["strip", start + kerb, finish - kerb], ["kerb", finish - kerb, finish],
			["road", finish, r["from"].y + r["width"] * 0.5]]


## Where north-south paths cross between z0 and z1: [[x from, x to], ...] (sorted).
static func crossings(map: Dictionary, z0: float, z1: float, extra := 0.0) -> Array:
	var cuts: Array = []
	for road: Dictionary in map["ROADS"]:
		var a: Vector2 = road["from"]
		var b: Vector2 = road["to"]
		if not is_equal_approx(a.x, b.x) or String(road.get("kind", "")) != "":
			continue
		if maxf(a.y, b.y) + road["width"] * 0.5 < z0 or minf(a.y, b.y) - road["width"] * 0.5 > z1:
			continue
		cuts.append([a.x - road["width"] * 0.5 - extra, a.x + road["width"] * 0.5 + extra])
	cuts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	return cuts


## Review (outdoor): the gaps in the kerbs and planted strip. Only paths that really cross the
## strip (from the track's south edge to the buggy road's north edge) cut it, plus the dome
## crossings. Before, the C4 and C5 links (which end at the buggy road from the south) also
## left a grassy gap with no path in it.
static func strip_gaps(map: Dictionary) -> Array:
	var section := cross_section(map)
	var z0: float = section[1][1]   # the north kerb's north edge
	var z1: float = section[3][2]   # the south kerb's south edge
	return crossings(map, z0 + 0.05, z1 - 0.05) + dome_gaps(map)


## Dome crossings: a 2.4 m gap in the strip in front of every dome door, so you can walk
## from the buggy road across to the dome.
static func dome_gaps(map: Dictionary) -> Array:
	var gaps: Array = []
	for dome: Vector3 in map["SPINE_DOMES"]:
		gaps.append([dome.x - 1.2, dome.x + 1.2])
	return gaps


## Splits [x0, x1] round the gaps. Returns the pieces left: [[a, b], ...].
static func pieces(x0: float, x1: float, gaps: Array) -> Array:
	var out: Array = []
	var x := x0
	var sorted := gaps.duplicate()
	sorted.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	for gap: Array in sorted:
		if gap[1] <= x or gap[0] >= x1:
			continue
		if gap[0] > x:
			out.append([x, gap[0]])
		x = maxf(x, gap[1])
	if x < x1:
		out.append([x, x1])
	return out


## Builds it all under `parent`. Returns the strip pieces (Rect2s) for planting.
static func build(parent: Node3D, map: Dictionary) -> Array:
	var holder := Node3D.new()
	holder.name = "SpinePaths"
	parent.add_child(holder)
	var spec: Dictionary = map["SPINE_PATHS"]
	var t := track(map)
	var x0: float = t["from"].x
	var x1: float = t["to"].x
	var strips: Array = []
	var gaps := crossings(map, -20.0, 20.0) + dome_gaps(map)
	if GameConfig.SPINE_GAPS_ONLY_REAL:
		gaps = strip_gaps(map)
	for part: Array in cross_section(map):
		var z0: float = part[1]
		var z1: float = part[2]
		if part[0] == "kerb":
			for piece: Array in pieces(x0, x1, gaps):
				_slab(holder, piece, z0, z1, spec["kerb_height"], KERB, "Kerb")
		elif part[0] == "strip":
			for piece: Array in pieces(x0, x1, gaps):
				var bed := _slab(holder, piece, z0, z1, GameConfig.SPINE_STRIP_TOP, KERB, "PlantedStrip")
				bed.material_override = TerrainMaterials.make("grass")
				strips.append(Rect2(piece[0], z0, piece[1] - piece[0], z1 - z0))
			# Paved crossings where the strip stops in front of a dome.
			for gap: Array in dome_gaps(map):
				var paving := _slab(holder, gap, z0 - 0.3, z1 + 0.3, 0.035, KERB, "StripCrossing")
				paving.material_override = TerrainMaterials.make("paving")
	_aprons(holder, map, t)
	_track_lines(holder, map, t)
	_road_lines(holder, map, buggy_road(map), spec)
	return strips


## A flat box from x piece[0] to piece[1] and z0 to z1, top at `top`.
static func _slab(parent: Node3D, piece: Array, z0: float, z1: float, top: float, colour: Color,
		node_name: String) -> MeshInstance3D:
	var size := Vector3(piece[1] - piece[0], top, z1 - z0)
	var box := LowPoly.box(parent, size, colour, Vector3((piece[0] + piece[1]) * 0.5, top * 0.5, (z0 + z1) * 0.5))
	box.name = node_name
	return box


## Paved aprons from each dome door, and each pool gate (Session 60 data, if it's there),
## south to the red track's edge.
static func _aprons(parent: Node3D, map: Dictionary, t: Dictionary) -> void:
	var edge: float = t["from"].y - t["width"] * 0.5
	var spots: Array = []
	for dome: Vector3 in map["SPINE_DOMES"]:
		spots.append([dome.x, dome.z + float(map["DOME_RADIUS"]) + 0.25, 2.4])
	for key in ["LAP_POOL_DETAIL", "COMMUNITY_POOL_DETAIL"]:
		var pool: Dictionary = map.get(key, {})
		if pool.has("gate"):
			var gate: Vector2 = pool["gate"]
			if gate.y < edge:
				spots.append([gate.x, gate.y, 1.8])
	for spot: Array in spots:
		var z0: float = spot[1]
		if edge - z0 < 0.2:
			continue
		var apron := _slab(parent, [spot[0] - spot[2] * 0.5, spot[0] + spot[2] * 0.5], z0, edge + 0.05,
				0.034, KERB, "DoorApron")
		apron.material_override = TerrainMaterials.make("paving")


## Thin white lines along both edges of the red track, and "WALK · مشي" every 40 m.
static func _track_lines(parent: Node3D, map: Dictionary, t: Dictionary) -> void:
	var z: float = t["from"].y
	var half: float = t["width"] * 0.5 - 0.15
	var top := GameConfig.SPINE_TRACK_TOP
	var gaps := crossings(map, z - 2.0, z + 2.0, 0.3)
	var x0: float = t["from"].x
	var x1: float = t["to"].x
	for piece: Array in pieces(x0, x1, gaps):
		var a: float = piece[0]
		while a < piece[1] - 0.5:
			var b := minf(a + CHUNK, piece[1])
			var kit := MeshKit.new()
			for side in [-1.0, 1.0]:
				kit.box(Vector3(b - a, 0.006, 0.07), WHITE, Vector3((a + b) * 0.5, top + 0.003, z + side * half))
			var view := kit.finish("TrackLines_%d" % parent.get_child_count())
			parent.add_child(view)
			a = b
	var every: float = map["SPINE_PATHS"]["walk_every"]
	var x := x0 + every * 0.5
	while x < x1:
		var clear := true
		for gap: Array in gaps:
			clear = clear and (x < gap[0] - 4.0 or x > gap[1] + 4.0)
		if clear:
			var words := SignText.make_face("مشي", "WALK", 64, WHITE)
			words.name = "WalkMarking_%d" % int(x)
			words.position = Vector3(x, top + 0.008, z)
			words.rotation = Vector3(-PI * 0.5, -PI * 0.5, 0)   # flat on the track, read walking east
			parent.add_child(words)
		x += every


## The white dashed middle line down the buggy road, stopping at junctions.
static func _road_lines(parent: Node3D, map: Dictionary, r: Dictionary, spec: Dictionary) -> void:
	var z: float = r["from"].y
	var gaps := crossings(map, z - 4.0, z + 4.0, 1.0)
	var dash: float = spec["dash"]
	var step: float = dash + float(spec["gap"])
	for piece: Array in pieces(r["from"].x + 2.0, r["to"].x - 2.0, gaps):
		var a: float = piece[0]
		while a < piece[1] - dash:
			var b := minf(a + CHUNK, piece[1])
			var kit := MeshKit.new()
			var x := a
			while x + dash <= b:
				kit.box(Vector3(dash, 0.008, 0.12), WHITE, Vector3(x + dash * 0.5, 0.045, z))
				x += step
			if kit.part_count() > 0:
				parent.add_child(kit.finish("LaneLine_%d" % parent.get_child_count()))
			a = maxf(x, a + step)


static func _road(map: Dictionary, road_name: String) -> Dictionary:
	for road: Dictionary in map["ROADS"]:
		if road["name"] == road_name:
			return road
	return {}
