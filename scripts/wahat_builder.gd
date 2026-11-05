extends Node3D
## Builds Wahat Al Shams (Session 25) from data/wahat_al_shams.gd when the game starts: the
## sand ground, the tree belt round the edge (with an invisible wall inside it), the horse
## track and bike track, the ring road, the gate road and the closed main gate with its
## gate house and welcome sign, the cluster lanes, the green spine with its path and stream,
## the cluster mini-plaza strips, bollards at the lane entrances,
## and flat plots for the school, mosque, stables and building site (LandmarkBuilder builds
## those, SpineBuilder the domes, farm and playgrounds).
## Shops and homes come from PlaceBuilder, palms/cars/bumps from DecorBuilder, cats and kids
## from ObstacleBuilder. Everything flat has no collision: you ride over it.

## The map data to build from (set in the scene): data/wahat_al_shams.gd.
@export var data: Script

const SAND := Color(0.91, 0.83, 0.65, 1)
const ROAD := Color(0.33, 0.34, 0.36, 1)
const LANE := Color(0.78, 0.72, 0.62, 1)       # light paving in the clusters
const PAVING := Color(0.86, 0.79, 0.66, 1)
const GRASS := Color(0.47, 0.66, 0.34, 1)
const WATER := Color(0.3, 0.6, 0.85, 1)
const HORSE_SAND := Color(0.8, 0.68, 0.5, 1)
const BIKE_RED := Color(0.18, 0.48, 0.72, 1)
const TRUNK := Color(0.5, 0.36, 0.22, 1)
const LEAVES := Color(0.3, 0.52, 0.26, 1)
const WALL := Color(0.95, 0.88, 0.74, 1)
const GATE := Color(0.85, 0.2, 0.2, 1)
const BOLLARD := Color(0.35, 0.37, 0.4, 1)
const BRIDGE_WOOD := Color(0.62, 0.45, 0.28, 1)
const TRACK_RED := Color(0.72, 0.3, 0.22, 1)    # Session 63: the walking track (textured red rubber)
const MARGIN := 20.0   # sand outside the edge

# The constants from the data script, e.g. _map["ROADS"].
var _map: Dictionary = {}


func _ready() -> void:
	if data == null:
		push_error("WahatBuilder has no data list set in the scene")
		return
	_map = data.get_script_constant_map()
	_build_ground()
	_build_tracks()
	for plot in _map["PLOTS"]:
		var area: Rect2 = plot["area"]
		_flat(area.get_center(), area.size, 0.02, plot["colour"], 0.01)
	var spine: Rect2 = _map["SPINE"]
	_flat(spine.get_center(), spine.size, 0.02, GRASS, 0.012)
	var stream: Dictionary = _map["STREAM"]
	_build_stream(stream)
	for area: Rect2 in _map["PAVED_AREAS"]:
		_flat(area.get_center(), area.size, 0.02, PAVING, 0.03)
	for road in _map["ROADS"]:
		_build_road(road)
	for spot: Vector2 in _map["BOLLARDS"]:
		var post := StaticBody3D.new()
		post.position = Vector3(spot.x, 0, spot.y)
		add_child(post)
		LowPoly.cylinder(post, 0.1, 0.12, 0.9, BOLLARD, Vector3(0, 0.45, 0))
		LowPoly.solid_cylinder(post, 0.12, 0.9, Vector3(0, 0.45, 0))
	_build_tree_belt()
	_build_walls_and_gate()
	_build_welcome()
	ClusterSigns.build(self, _map)  # Session 26: "Cluster 1" signs at the lane ends
	_build_bridges(_map["STREAM"])  # Session 53: a little bridge wherever a path crosses the stream


## The solid sand ground (top at 0), in 4 slabs round a square hole where the Plaza's sunken
## square goes (PlazaBuilder fills the hole with the steps, the floor and their slope).
func _build_ground() -> void:
	var half: Vector2 = _map["MAP_HALF"] + Vector2.ONE * MARGIN
	var plaza: Dictionary = _map["PLAZA"]
	var c: Vector2 = plaza["centre"]
	var hole: float = plaza.get("sunken_radius", 0.0)
	_flat(Vector2((-half.x + c.x - hole) * 0.5, 0), Vector2(c.x - hole + half.x, half.y * 2.0), 1.0, SAND, 0.0, true)
	_flat(Vector2((c.x + hole + half.x) * 0.5, 0), Vector2(half.x - c.x - hole, half.y * 2.0), 1.0, SAND, 0.0, true)
	_flat(Vector2(c.x, (-half.y + c.y - hole) * 0.5), Vector2(hole * 2.0, c.y - hole + half.y), 1.0, SAND, 0.0, true)
	_flat(Vector2(c.x, (c.y + hole + half.y) * 0.5), Vector2(hole * 2.0, half.y - c.y - hole), 1.0, SAND, 0.0, true)


## A flat coloured slab. middle: x/z. height: its thickness. top: how high its top is.
func _flat(middle: Vector2, size: Vector2, height: float, colour: Color, top: float, solid := false) -> Node3D:
	var spot := Vector3(middle.x, top - height * 0.5, middle.y)
	if not solid:
		return LowPoly.box(self, Vector3(size.x, height, size.y), colour, spot)
	var body := StaticBody3D.new()
	body.position = spot
	add_child(body)
	LowPoly.box(body, Vector3(size.x, height, size.y), colour, Vector3.ZERO)
	LowPoly.solid_box(body, Vector3(size.x, height, size.y), Vector3.ZERO)
	return body


## A road is a strip from one end of its middle line to the other, one width longer so
## corners are filled in. Lanes (narrower) are light paving, roads are asphalt.
func _build_road(road: Dictionary) -> void:
	var width: float = road.get("width", _map["ROAD_WIDTH"])
	var from: Vector2 = road["from"]
	var to: Vector2 = road["to"]
	var way := to - from
	if way.length() < 0.01:
		return
	var dir := way.normalized()
	# Each end normally sticks out half a width to fill the corner where paths meet. Session 53:
	# not where it ends at a black road (ring road, gate roads, bus road): the black road wins,
	# so a lane stops at its kerb instead of being drawn over it.
	var black := not is_black_road(road)
	var start := from - dir * (0.0 if black and ends_on_black_road(_map, from) else width * 0.5)
	var finish := to + dir * (0.0 if black and ends_on_black_road(_map, to) else width * 0.5)
	if GameConfig.ROAD_ENDS_GIVE_WAY:
		var ends := drawn_ends(_map, road)   # Review: stop at the edge of a road that wins
		start = ends[0]
		finish = ends[1]
	var length := start.distance_to(finish)
	var middle := (start + finish) * 0.5
	var kind: String = road.get("kind", "")
	if GameConfig.SPINE_LOOKS_V2 and kind == "walk_track":
		# Session 63: the red rubber walking track, a little lower than the paths that cross it.
		var top := GameConfig.SPINE_TRACK_TOP
		var track := LowPoly.box(self, Vector3(width, top - 0.004, length), TRACK_RED, Vector3(middle.x, (top + 0.004) * 0.5, middle.y))
		track.name = "WalkingTrack"
		track.material_override = TerrainMaterials.make("track")
		track.rotation.y = atan2(way.x, way.y)
		return
	var strip := LowPoly.box(self, Vector3(width, 0.04, length), ROAD if width >= 6.0 else LANE,
			Vector3(middle.x, 0.02 if width >= 6.0 else 0.025, middle.y))
	strip.rotation.y = atan2(way.x, way.y)
	if GameConfig.SPINE_LOOKS_V2 and kind == "buggy_road":
		strip.name = "BuggyRoad"   # Session 63: light asphalt (SpineBuilder adds the lane lines)
		strip.set_meta("light_asphalt", true)


## Session 53: the "black" roads cars use. Every other path gives way to them.
static func is_black_road(road: Dictionary) -> bool:
	return String(road["name"]) in GameConfig.BLACK_ROADS


## Review (outdoor): where a road's strip is drawn from and to. Like before, each end sticks
## out half a width to fill the corner where paths meet (but not onto a black road). New: if an
## end lies on a road that wins (see gives_way_to), the strip stops at that road's edge instead
## of being drawn over it to its middle (two slabs at one height flicker, and a light lane on a
## dark road looks like one road lying on another). Returns [start, finish].
static func drawn_ends(map: Dictionary, road: Dictionary) -> Array[Vector2]:
	var width: float = road.get("width", map["ROAD_WIDTH"])
	var from: Vector2 = road["from"]
	var to: Vector2 = road["to"]
	var length := from.distance_to(to)
	if length < 0.01:
		return [from, to]
	var dir := (to - from) / length
	var stops := not is_black_road(road)
	var start := from - dir * (0.0 if stops and ends_on_black_road(map, from) else width * 0.5)
	var finish := to + dir * (0.0 if stops and ends_on_black_road(map, to) else width * 0.5)
	var winners: Array = []
	for other: Dictionary in map["ROADS"]:
		if gives_way_to(road, other) and not (is_black_road(other) and _shares_end(road, other)):
			winners.append(other)   # (a path carrying straight on from a black road's end, like the Plaza Link, keeps its corner)
	# Walk in from each drawn tip until we're off every winning road that tip lies on.
	var out := start.distance_to(finish) * 0.5 - 0.05   # never past the middle (a path inside a road keeps its ends)
	var tips := [start, finish]
	for side in [[start, dir, 0], [finish, -dir, 1]]:
		var tip: Vector2 = side[0]
		var on: Array = winners.filter(func(r: Dictionary) -> bool: return on_road(map, r, tip))
		if on.is_empty():
			continue
		var t := 0.0
		while t < out and on.any(func(r: Dictionary) -> bool: return on_road(map, r, tip + side[1] * t)):
			t += 0.02
		if t >= out:
			continue
		tips[side[2]] = tip + side[1] * maxf(t - GameConfig.ROAD_END_OVERLAP, 0.0)
	return [tips[0], tips[1]]


static func _shares_end(a: Dictionary, b: Dictionary) -> bool:
	for p: Vector2 in [a["from"], a["to"]]:
		for q: Vector2 in [b["from"], b["to"]]:
			if p.distance_to(q) < 0.5:
				return true
	return false


## True if `road` gives way to `other` where it ends on it: black roads (ring road...) always
## win, then the spine buggy road, then any road that's wider. Same-width paths meet as equals.
static func gives_way_to(road: Dictionary, other: Dictionary) -> bool:
	if other == road or is_black_road(road):
		return false
	if is_black_road(other):
		return true
	var kind := String(road.get("kind", ""))
	if kind == "buggy_road":
		return false
	if String(other.get("kind", "")) == "buggy_road":
		return true
	return float(other.get("width", 6.0)) > float(road.get("width", 6.0)) + 0.01


## True if the point is on the strip drawn for `road` (its middle line, half a width out to the
## sides and past the ends, but not past an end that stops at a black road).
static func on_road(map: Dictionary, road: Dictionary, point: Vector2) -> bool:
	var width: float = road.get("width", map["ROAD_WIDTH"])
	var a: Vector2 = road["from"]
	var b: Vector2 = road["to"]
	var length := a.distance_to(b)
	if length < 0.01:
		return false
	var dir := (b - a) / length
	var stops := not is_black_road(road)
	var before := 0.0 if stops and ends_on_black_road(map, a) else width * 0.5
	var after := 0.0 if stops and ends_on_black_road(map, b) else width * 0.5
	var along := (point - a).dot(dir)
	var across := absf((point - a).dot(Vector2(-dir.y, dir.x)))
	return along >= -before - 0.001 and along <= length + after + 0.001 and across <= width * 0.5 + 0.001


## True if this point is on (or at the kerb of) a black road.
static func ends_on_black_road(map: Dictionary, point: Vector2) -> bool:
	for road: Dictionary in map["ROADS"]:
		if is_black_road(road) and ClusterSigns.road_rect(road, map["ROAD_WIDTH"]).grow(0.5).has_point(point):
			return true
	return false


## The horse track and the bike track: rings of sand and red paving inside the tree belt.
func _build_tracks() -> void:
	for pair in [[_map["HORSE_TRACK"], HORSE_SAND, 0.008], [_map["BIKE_TRACK"], BIKE_RED, 0.01]]:
		var track: Dictionary = pair[0]
		var h: Vector2 = track["half"]
		var w: float = track["width"]
		var colour: Color = pair[1]
		var top: float = pair[2]
		_flat(Vector2(0, -h.y), Vector2(h.x * 2.0 + w, w), 0.02, colour, top)
		_flat(Vector2(0, h.y), Vector2(h.x * 2.0 + w, w), 0.02, colour, top)
		_flat(Vector2(-h.x, 0), Vector2(w, h.y * 2.0 + w), 0.02, colour, top)
		_flat(Vector2(h.x, 0), Vector2(w, h.y * 2.0 + w), 0.02, colour, top)


## A winding blue stream through the spine (flat: you can ride through it).
func _build_stream(stream: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Stream"  # Session 30: AmbientMotion gives these pieces moving water
	add_child(holder)
	var x: float = stream["from_x"]
	var end_x: float = stream["to_x"]
	var width: float = stream["width"]
	var centre_z: float = stream["z"]
	const STEP := 8.0
	const PIECES_PER_CHUNK := 6
	while x < end_x:
		# Keep the original overlapping pieces in short chunks so distant water can be culled.
		var origin := Vector3(x, 0.0, centre_z)
		var chunk := SurfaceTool.new()
		chunk.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in PIECES_PER_CHUNK:
			if x >= end_x:
				break
			var z := centre_z + sin(x * 0.06) * 3.0
			var z2 := centre_z + sin((x + STEP) * 0.06) * 3.0
			var piece := BoxMesh.new()
			piece.size = Vector3(width, 0.02, Vector2(STEP, z2 - z).length() + 0.8)
			var middle := Vector3(x + STEP * 0.5, 0.03, (z + z2) * 0.5) - origin
			chunk.append_from(piece, 0, Transform3D(Basis(Vector3.UP, atan2(STEP, z2 - z)), middle))
			x += STEP
		chunk.set_material(LowPoly.material(WATER))
		var view := MeshInstance3D.new()
		view.mesh = chunk.commit()
		view.position = origin
		holder.add_child(view)


## Session 53: where a path or road crosses the stream, the water used to be drawn on top of
## the road. Now there's a small wooden bridge: a plank deck a little wider than the path,
## with railings on both sides (solid, but outside the path so they don't block it).
func _build_bridges(stream: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Bridges"
	add_child(holder)
	for spot: Vector3 in bridge_spots(_map):
		var bridge := Node3D.new()
		bridge.name = "Bridge_%d" % int(spot.x)
		bridge.position = Vector3(spot.x, 0, spot.z)
		holder.add_child(bridge)
		var width: float = spot.y   # the path's width (kept in y)
		var length := float(stream["width"]) + GameConfig.BRIDGE_EXTRA_LENGTH
		LowPoly.box(bridge, Vector3(width + 1.0, 0.03, length), BRIDGE_WOOD.darkened(0.2), Vector3(0, 0.05, 0))  # just above the water and the path, so riding over it is smooth
		var plank := 0.0
		while plank < length:   # planks across the deck
			LowPoly.box(bridge, Vector3(width + 0.9, 0.012, 0.42), BRIDGE_WOOD, Vector3(0, 0.07, -length * 0.5 + plank + 0.25))
			plank += 0.5
		for side in [-1.0, 1.0]:
			var rail := StaticBody3D.new()
			rail.position = Vector3(side * (width * 0.5 + 0.45), 0, 0)
			bridge.add_child(rail)
			LowPoly.box(rail, Vector3(0.12, 0.08, length), BRIDGE_WOOD, Vector3(0, 0.95, 0))
			LowPoly.box(rail, Vector3(0.08, 0.06, length), BRIDGE_WOOD, Vector3(0, 0.55, 0))
			var post_z := -length * 0.5
			while post_z <= length * 0.5 + 0.01:
				LowPoly.box(rail, Vector3(0.14, 1.0, 0.14), BRIDGE_WOOD.darkened(0.15), Vector3(0, 0.5, post_z))
				post_z += length / 3.0
			LowPoly.solid_box(rail, Vector3(0.2, 1.0, length), Vector3(0, 0.5, 0))


## Where paths cross the stream: x and z of the crossing, with the path's width in y.
static func bridge_spots(map: Dictionary) -> Array[Vector3]:
	var stream: Dictionary = map["STREAM"]
	var spots: Array[Vector3] = []
	for road: Dictionary in map["ROADS"]:
		var a: Vector2 = road["from"]
		var b: Vector2 = road["to"]
		if not is_equal_approx(a.x, b.x):
			continue   # only paths running north-south cross the stream (it runs west-east)
		var x := a.x
		if x < float(stream["from_x"]) or x > float(stream["to_x"]):
			continue
		var z := float(stream["z"]) + sin(x * 0.06) * 3.0   # the stream's wiggle, as drawn
		if z > minf(a.y, b.y) and z < maxf(a.y, b.y):
			spots.append(Vector3(x, float(road.get("width", 6.0)), z))
	return spots


## Two rows of trees around the edge. Spatial batches let the renderer skip distant sections.
func _build_tree_belt() -> void:
	const CHUNK_SIZE := 120.0
	var belt: Dictionary = _map["TREE_BELT"]
	var inner: Vector2 = belt["inner"]
	var half: Vector2 = _map["MAP_HALF"]
	var gap: float = _map["GATE_HALF_WIDTH"] + 4.0
	var spots: Array[Vector3] = []
	for row in [inner.x + 1.5, half.x - 1.5]:
		var z := -half.y
		while z <= half.y:
			spots.append(Vector3(row, 0, z))
			if _outside_gate_gap(z, gap):
				spots.append(Vector3(-row, 0, z))  # leave the gate open on the west
			z += belt["spacing"]
	for row in [inner.y + 1.5, half.y - 1.5]:
		var x := -half.x
		while x <= half.x:
			spots.append(Vector3(x, 0, row))
			spots.append(Vector3(x, 0, -row))
			x += belt["spacing"]
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.25
	trunk.bottom_radius = 0.35
	trunk.height = 4.0
	trunk.radial_segments = 6
	trunk.material = LowPoly.material(TRUNK)
	var crown := SphereMesh.new()
	crown.radius = 2.6
	crown.height = 4.4
	crown.radial_segments = 8
	crown.rings = 4
	crown.material = LowPoly.material(LEAVES)
	var chunks := {}
	for i in spots.size():
		var spot := spots[i]
		var cell := Vector2i(floori(spot.x / CHUNK_SIZE), floori(spot.z / CHUNK_SIZE))
		if not chunks.has(cell):
			chunks[cell] = []
		chunks[cell].append(i)
	for part in [[trunk, 2.0, "TreeTrunks"], [crown, 5.6, "TreeCrowns"]]:
		var group := Node3D.new()
		group.name = part[2]
		add_child(group)
		for cell: Vector2i in chunks:
			var origin := Vector3(cell.x + 0.5, 0.0, cell.y + 0.5) * CHUNK_SIZE
			var indices: Array = chunks[cell]
			var many := MultiMesh.new()
			many.transform_format = MultiMesh.TRANSFORM_3D
			many.mesh = part[0]
			many.instance_count = indices.size()
			for index in indices.size():
				var i: int = indices[index]
				var size := 0.85 + fmod(float(i) * 0.37, 0.4)
				var basis := Basis().scaled(Vector3.ONE * size)
				var offset: Vector3 = spots[i] - origin + Vector3.UP * part[1] * size
				many.set_instance_transform(index, Transform3D(basis, offset))
			var view := MultiMeshInstance3D.new()
			view.position = origin
			view.multimesh = many
			group.add_child(view)


## Invisible walls inside the tree belt (so you can't ride off the map), the gate house and
## the closed red gate bar across the gate road.
func _build_walls_and_gate() -> void:
	var inner: Vector2 = _map["TREE_BELT"]["inner"]
	var gap: float = _map["GATE_HALF_WIDTH"]
	var tall := Vector3(0, 2.0, 0)
	var walls := StaticBody3D.new()
	walls.name = "EdgeWalls"
	add_child(walls)
	LowPoly.solid_box(walls, Vector3(inner.x * 2.0, 4.0, 1.0), Vector3(0, 2, -inner.y))
	LowPoly.solid_box(walls, Vector3(inner.x * 2.0, 4.0, 1.0), Vector3(0, 2, inner.y))
	LowPoly.solid_box(walls, Vector3(1.0, 4.0, inner.y * 2.0), Vector3(inner.x, 2, 0))
	# Two west-side checkpoints, each with a side gap for bicycles.
	var cuts: Array[float] = [-inner.y]
	for entry: Dictionary in _map.get("GATES", [{"position": Vector3(-inner.x, 0, 0)}]):
		var z: float = entry["position"].z
		cuts.append(z - gap)
		cuts.append(z + gap)
	cuts.append(inner.y)
	cuts.sort()
	for i in range(0, cuts.size() - 1, 2):
		LowPoly.solid_box(walls, Vector3(1, 4, cuts[i+1] - cuts[i]), Vector3(-inner.x, 2, (cuts[i+1] + cuts[i]) * 0.5))


func _outside_gate_gap(z: float, gap: float) -> bool:
	for entry: Dictionary in _map.get("GATES", [{"position": Vector3.ZERO}]):
		if absf(z - entry["position"].z) <= gap:
			return false
	return true


## The big bilingual welcome sign by the gate road.
func _build_welcome() -> void:
	var welcome: Dictionary = _map["WELCOME_SIGN"]
	var holder := StaticBody3D.new()
	holder.name = "WelcomeSign"
	holder.position = welcome["position"]
	holder.rotation_degrees = Vector3(0, welcome["facing"], 0)
	add_child(holder)
	var board_size := Vector3(4.6, 1.8, 0.2)
	LowPoly.box(holder, board_size, Color(0.16470589, 0.5568628, 0.6117647, 1), Vector3(0, 2.4, 0))
	for x in [-1.8, 1.8]:
		LowPoly.box(holder, Vector3(0.18, 1.6, 0.18), Color(0.9, 0.9, 0.9, 1), Vector3(x, 0.8, 0))
		LowPoly.solid_box(holder, Vector3(0.25, 3.3, 0.25), Vector3(x, 1.65, 0))
	var size := SignText.fit_size(welcome["arabic"], welcome["name"], 64, board_size.x - 0.4)
	var faces := SignText.make_two_faces(welcome["arabic"], welcome["name"], size, Color(1, 1, 1, 1), board_size.z)
	faces.position.y = 2.4
	holder.add_child(faces)
