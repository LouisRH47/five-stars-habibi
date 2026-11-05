class_name Pool
extends Node3D
## Session 60: a real outdoor pool, built from the map data (LAP_POOL / COMMUNITY_POOL and
## their *_DETAIL entries in data/wahat_al_shams.gd):
##   - a light stone deck round the water, a white edge (coping) and moving blue water
##   - a fence all the way round with ONE open gate (glass for the lap pool, metal bars for
##     the community pool). Where a building closes a side (the gym's glass wall), no fence.
##   - lap pool: lanes with blue and white lane ropes, a ladder at each end, a bench by the gate
##   - community pool: a kids' pool, loungers, umbrellas, shade sails, a lifeguard chair, a
##     shower, a changing hut, a rules sign and palms (scripts/pool_props.gd)
##   - people who really swim (scripts/swimmer.gd)
## The area is the whole fenced deck. Node names: Deck, PoolWater, KidsWater, PoolFence, Gate.

const DECK := Color(0.9, 0.87, 0.8)
const COPING := Color(0.98, 0.98, 0.96)
const ROPE_BLUE := Color(0.1, 0.3, 0.8)
const ROPE_WHITE := Color(0.97, 0.97, 0.97)
const STEEL := Color(0.75, 0.77, 0.8)
const BARS := Color(0.2, 0.22, 0.25)
const GLASS := Color(0.75, 0.9, 0.95, 0.22)
const WATER_SHADER := preload("res://assets/shaders/water.gdshader")
const SWIM_COLOURS := [Color(0.1, 0.2, 0.55), Color(0.8, 0.15, 0.2), Color(0.1, 0.1, 0.12), Color(0.1, 0.55, 0.45)]
const CAP_COLOURS := [Color(1, 0.85, 0.1), Color(0.95, 0.4, 0.6), Color.WHITE, Color(0.2, 0.6, 1.0)]

## The whole fenced area (x, z).
var area := Rect2()
## The water (x, z).
var water := Rect2()
## Everyone who moves here (DistrictDetail steps them every frame).
var swimmers: Array[Swimmer] = []
## The straight fence pieces, each [from, to] (x, z). The tests check they close the area.
var fence_lines: Array = []
## Where the gate is (the middle of the gap, x and z) and how wide it is.
var gate := Vector2.ZERO
var gate_width := 0.0


## Builds it. detail: the *_DETAIL entry from the data ({} = a plain pool with two swimmers
## and no fence, like the school pools). community: the community pool's extras.
func setup(fenced_area: Rect2, detail: Dictionary, community: bool) -> void:
	area = fenced_area
	water = detail.get("water", area.grow(-1.0))
	var water_y := GameConfig.POOL_WATER_Y
	var holes: Array = [water]
	if community:
		holes.append(detail["kids"])
	_deck_round(holes)
	_water(water, "PoolWater")
	if detail.has("fence"):
		gate = detail["gate"]
		gate_width = detail["gate_width"]
		_fence(detail)
	if community:
		var kids: Rect2 = detail["kids"]
		_water(kids, "KidsWater")
		PoolProps.dress(self, detail)
		for side in [-1.0, 1.0]:
			_ladder(Vector3(water.get_center().x + side * (water.size.x * 0.5 - 1.5), 0, water.end.y), 1.0)
		for i in int(detail["swimmers"]):
			var lane_z := water.position.y + water.size.y * (i + 0.5) / float(detail["swimmers"])
			_add_lap_swimmer(lane_z, i, water_y)
		for i in int(detail["kids_in_pool"]):
			var spot := Vector3(kids.position.x + 1.5 + i * (kids.size.x - 3.0) / 2.0, water_y,
					kids.position.y + 1.6 + (i % 2) * 2.6)
			var kid := _swimwear(Person.new(GameConfig.KID_HEIGHT), i + 2)
			_add(Swimmer.kid(kid, spot, 70 + i))
		var loop: Array[Vector3] = []
		var round := water.grow(1.0)
		for corner in [round.position, Vector2(round.end.x, round.position.y), round.end, Vector2(round.position.x, round.end.y)]:
			loop.append(Vector3(corner.x, 0, corner.y))
		for i in int(detail["deck_walkers"]):
			var walker := PeopleLooks.resident(2 + i, i)
			_add(Swimmer.deck_walker(walker, loop, i * 2))
	else:
		var lanes: int = detail.get("lanes", 0)
		if lanes > 0:
			_lane_ropes(lanes)
			for side in [-1.0, 1.0]:
				_ladder(Vector3(water.get_center().x + side * (water.size.x * 0.5 - 1.0), 0, water.end.y), 1.0)
			# A bench just inside the gate, looking at the water.
			Props.bench(self, Vector3(gate.x + 2.2, 0, gate.y - 0.75), 180.0)
		var count: int = detail.get("swimmers", 2)
		var used := [0, 1, 3, 2]   # lap pool: lanes 1, 2 and 4 first
		for i in count:
			var lane: int = used[i % used.size()] % maxi(lanes, 1)
			var lane_z := water.position.y + water.size.y * (lane + 0.5) / float(maxi(lanes, 1)) if lanes > 0 \
					else water.position.y + water.size.y * (i + 1.0) / (count + 1.0)
			_add_lap_swimmer(lane_z, i + (10 if lanes > 0 else 40), water_y)


## A swimmer doing lengths at z = lane_z, along the pool's long side (x).
func _add_lap_swimmer(lane_z: float, number: int, water_y: float) -> void:
	var from := Vector3(water.position.x + 1.6, water_y, lane_z)
	var to := Vector3(water.end.x - 1.6, water_y, lane_z)
	var who := _swimwear(Person.new(), number)
	var cap := LowPoly.sphere(who.follow("Head"), 0.115, 0.17, CAP_COLOURS[number % CAP_COLOURS.size()], who.head_spot() + Vector3(0, 0.04, 0))
	cap.name = "SwimCap"
	_add(Swimmer.lap(who, from, to, fmod(number * 0.37, 1.0), number))


## Paints a person in swimming things: bare arms and chest (skin), coloured swimwear.
func _swimwear(who: Person, number: int) -> Person:
	var skin: Color = PeopleLooks.SKINS[number % PeopleLooks.SKINS.size()]
	who.paint({"skin": skin, "shirt": skin if number % 3 != 1 else SWIM_COLOURS[(number + 1) % 4],
			"pants": SWIM_COLOURS[number % SWIM_COLOURS.size()]})
	return who


func _add(swimmer: Swimmer) -> void:
	add_child(swimmer, true)
	swimmers.append(swimmer)


## The deck: stone slabs round the water (never under it, so they don't flicker). The area is
## cut into a grid at every water edge; each cell that isn't water gets a slab.
func _deck_round(holes: Array) -> void:
	var y := GameConfig.POOL_DECK_Y
	var xs := [area.position.x, area.end.x]
	var zs := [area.position.y, area.end.y]
	for hole: Rect2 in holes:
		xs.append_array([hole.position.x, hole.end.x])
		zs.append_array([hole.position.y, hole.end.y])
	xs = _sorted_unique(xs)
	zs = _sorted_unique(zs)
	for j in zs.size() - 1:
		var run_start := NAN
		for i in xs.size():
			var solid := false
			if i < xs.size() - 1:
				var middle := Vector2((xs[i] + xs[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5)
				solid = not holes.any(func(h: Rect2) -> bool: return h.has_point(middle))
			if solid and is_nan(run_start):
				run_start = xs[i]
			elif not solid and not is_nan(run_start):
				var slab := LowPoly.box(self, Vector3(xs[i] - run_start, y, zs[j + 1] - zs[j]), DECK,
						Vector3((run_start + xs[i]) * 0.5, y * 0.5, (zs[j] + zs[j + 1]) * 0.5))
				slab.name = "Deck"
				if GameConfig.POOL_DECK_PAVED:   # Review (outdoor): pavers, not a plain grey slab
					slab.material_override = TerrainMaterials.make("paving")
				run_start = NAN
	for hole: Rect2 in holes:
		_coping(hole)


static func _sorted_unique(values: Array) -> Array:
	values.sort()
	var out: Array = []
	for v in values:
		if out.is_empty() or v - out[-1] > 0.01:
			out.append(v)
	return out


## The white edge round a pool of water.
func _coping(hole: Rect2) -> void:
	var y := GameConfig.POOL_DECK_Y + 0.03
	var w := 0.3
	for z in [hole.position.y - w * 0.5, hole.end.y + w * 0.5]:
		LowPoly.box(self, Vector3(hole.size.x + w * 2.0, y, w), COPING, Vector3(hole.get_center().x, y * 0.5, z))
	for x in [hole.position.x - w * 0.5, hole.end.x + w * 0.5]:
		LowPoly.box(self, Vector3(w, y, hole.size.y), COPING, Vector3(x, y * 0.5, hole.get_center().y))


## Moving blue water (the same ripple shader as the stream, slower and pool blue).
func _water(hole: Rect2, id: String) -> void:
	var depth := 0.4
	var view := LowPoly.box(self, Vector3(hole.size.x, depth, hole.size.y), GameConfig.POOL_WATER_COLOUR,
			Vector3(hole.get_center().x, GameConfig.POOL_WATER_Y - depth * 0.5, hole.get_center().y))
	view.name = id
	var ripples := ShaderMaterial.new()
	ripples.shader = WATER_SHADER
	ripples.set_shader_parameter("water_colour", GameConfig.POOL_WATER_COLOUR)
	ripples.set_shader_parameter("flow_speed", 0.25)
	ripples.set_shader_parameter("kind", 1)  # Session 68: pool water (light patterns on the tiles)
	view.material_override = ripples


## Lane ropes: rows of blue and white floats between the lanes.
func _lane_ropes(lanes: int) -> void:
	var float_length := 0.5
	var count := int(water.size.x / float_length)
	for lane in range(1, lanes):
		var z := water.position.y + water.size.y * lane / float(lanes)
		for i in count:
			var x := water.position.x + (i + 0.5) * water.size.x / count
			var bead := LowPoly.box(self, Vector3(water.size.x / count - 0.04, 0.09, 0.09),
					ROPE_BLUE if (i / 2) % 2 == 0 else ROPE_WHITE, Vector3(x, GameConfig.POOL_WATER_Y + 0.02, z))
			bead.name = "LaneRope"


## A pool ladder on the edge at `spot` (x, z on the edge), going into the water towards -z * way.
func _ladder(spot: Vector3, way: float) -> void:
	for side in [-0.25, 0.25]:
		var foot := spot + Vector3(side, 0, 0.1 * way)
		LowPoly.box(self, Vector3(0.05, 0.75, 0.05), STEEL, foot + Vector3(0, GameConfig.POOL_DECK_Y + 0.37, 0))
		LowPoly.box(self, Vector3(0.05, 0.05, 0.5), STEEL, foot + Vector3(0, GameConfig.POOL_DECK_Y + 0.75, -0.22 * way))
		LowPoly.box(self, Vector3(0.05, 0.6, 0.05), STEEL, foot + Vector3(0, GameConfig.POOL_DECK_Y + 0.45, -0.45 * way))


## The fence: straight pieces along the four sides, leaving out the gate and any building wall.
func _fence(detail: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "PoolFence"
	add_child(body)
	var height: float = detail["fence_height"]
	var glass: bool = detail["fence"] == "glass"
	var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	var gaps: Array = [[gate - Vector2(gate_width * 0.5, 0), gate + Vector2(gate_width * 0.5, 0)]]
	if detail.has("wall"):
		gaps.append(detail["wall"])
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		for piece in _split(a, b, gaps):
			fence_lines.append(piece)
			_fence_piece(body, piece[0], piece[1], height, glass)
	_gate(body, height, glass)


## Cuts the side a-b where a gap (a [from, to] pair lying on it) is.
func _split(a: Vector2, b: Vector2, gaps: Array) -> Array:
	var length := a.distance_to(b)
	var way := (b - a) / length
	var cuts: Array = []
	for gap in gaps:
		var p: Vector2 = gap[0]
		var q: Vector2 = gap[1]
		var off_p := Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)
		var off_q := Geometry2D.get_closest_point_to_segment(q, a, b).distance_to(q)
		if off_p < 0.05 and off_q < 0.05:
			var s := clampf((p - a).dot(way), 0.0, length)
			var t := clampf((q - a).dot(way), 0.0, length)
			cuts.append([minf(s, t), maxf(s, t)])
	cuts.sort_custom(func(x, y): return x[0] < y[0])
	var pieces: Array = []
	var at := 0.0
	for cut in cuts:
		if cut[0] - at > 0.05:
			pieces.append([a + way * at, a + way * cut[0]])
		at = maxf(at, cut[1])
	if length - at > 0.05:
		pieces.append([a + way * at, b])
	return pieces


func _fence_piece(body: StaticBody3D, from: Vector2, to: Vector2, height: float, glass: bool) -> void:
	var length := from.distance_to(to)
	var middle := (from + to) * 0.5
	var holder := Node3D.new()
	holder.position = Vector3(middle.x, 0, middle.y)
	holder.rotation.y = atan2(to.x - from.x, to.y - from.y)   # the piece runs along its own Z
	body.add_child(holder, true)
	var posts := maxi(1, ceili(length / (1.5 if glass else 2.5)))
	for i in posts + 1:
		var z := -length * 0.5 + length * float(i) / posts
		LowPoly.box(holder, Vector3(0.07, height, 0.07), STEEL if glass else BARS, Vector3(0, height * 0.5, z))
	if glass:
		var panel := LowPoly.box(holder, Vector3(0.03, height - 0.15, length - 0.1), Color.WHITE, Vector3(0, (height - 0.15) * 0.5 + 0.05, 0))
		panel.material_override = _glass()
		panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		LowPoly.box(holder, Vector3(0.06, 0.05, length), STEEL, Vector3(0, height, 0))
	else:
		for y in [0.1, height - 0.05]:
			LowPoly.box(holder, Vector3(0.05, 0.05, length), BARS, Vector3(0, y, 0))
		holder.add_child(_bars(length, height))
	var shape := LowPoly.solid_box(body, Vector3(0.12, height, length), holder.position + Vector3(0, height * 0.5, 0))
	shape.rotation.y = holder.rotation.y


## Upright metal bars every 12 cm, drawn all at once (one MultiMesh).
func _bars(length: float, height: float) -> MultiMeshInstance3D:
	var bar := BoxMesh.new()
	bar.size = Vector3(0.025, height - 0.1, 0.025)
	bar.material = LowPoly.material(BARS)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = bar
	many.instance_count = maxi(1, int(length / 0.12))
	for i in many.instance_count:
		var z := -length * 0.5 + (i + 0.5) * length / many.instance_count
		many.set_instance_transform(i, Transform3D(Basis(), Vector3(0, (height - 0.1) * 0.5 + 0.05, z)))
	var view := MultiMeshInstance3D.new()
	view.name = "FenceBars"
	view.multimesh = many
	view.visibility_range_end = 140.0
	return view


## The gate: two posts and an open leaf swung into the pool area (you walk straight through).
func _gate(body: StaticBody3D, height: float, glass: bool) -> void:
	var holder := Node3D.new()
	holder.name = "Gate"
	holder.position = Vector3(gate.x, 0, gate.y)
	body.add_child(holder, true)
	var inward := -1.0 if gate.y > area.get_center().y else 1.0
	for side in [-0.5, 0.5]:
		LowPoly.box(holder, Vector3(0.1, height + 0.15, 0.1), STEEL if glass else BARS,
				Vector3(side * (gate_width + 0.1), (height + 0.15) * 0.5, 0))
	var leaf := Node3D.new()
	leaf.name = "OpenLeaf"
	leaf.position = Vector3(-gate_width * 0.5 - 0.05, 0, inward * 0.05)
	holder.add_child(leaf, true)
	if glass:
		var pane := LowPoly.box(leaf, Vector3(0.03, height - 0.15, gate_width - 0.05), Color.WHITE,
				Vector3(0, (height - 0.15) * 0.5 + 0.05, inward * gate_width * 0.5))
		pane.material_override = _glass()
	else:
		for y in [0.1, height - 0.05]:
			LowPoly.box(leaf, Vector3(0.05, 0.05, gate_width - 0.05), BARS, Vector3(0, y, inward * gate_width * 0.5))
		for i in 7:
			LowPoly.box(leaf, Vector3(0.025, height - 0.1, 0.025), BARS, Vector3(0, height * 0.5, inward * (0.1 + i * 0.13)))


static var _glass_material: StandardMaterial3D

func _glass() -> StandardMaterial3D:
	if _glass_material == null:
		_glass_material = StandardMaterial3D.new()
		_glass_material.albedo_color = GLASS
		_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass_material.roughness = 0.1
	return _glass_material
