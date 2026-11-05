class_name SpineTracks
extends Node3D
## Session 62: the spine road copies Louis's photo. On both sides of the asphalt:
## a narrow planter (low kerb, grass, hedges, bougainvillea and purple flowers under the
## date palms), then a smooth matte red-brown walking track, slightly raised.
## Gaps: where a road joins, the planter and track stop and white stripes mark the crossing;
## at paths, the planter becomes a marked paved crossing. Joggers and walkers use the tracks
## (PEOPLE_ROUTES in the data). Layout numbers come from SPINE_TRACKS in the data.
## Session 75: no invisible walls any more. The low planter kerbs are just kerbs: you can
## ride over them anywhere with a small bump (KerbBumps). Session 76: the kerb along the
## road's edge is RoadMesh's (so it curves round the junctions); this builds the planter's
## other kerb and a kerb across each end of a planter, so every planter is closed.

const KERB := RoadMesh.KERB
const GRASS := Color(0.36, 0.58, 0.25)
const HEDGE := Color(0.18, 0.4, 0.17)
const BUSH := Color(0.22, 0.45, 0.2)
const BOUGAINVILLEA := Color(0.86, 0.16, 0.55)
const PURPLE := Color(0.55, 0.3, 0.82)
const PAD := Color(0.78, 0.74, 0.68)
const STRIPE := Color(0.96, 0.96, 0.94)
const TRACK_SIDE := Color(0.5, 0.25, 0.2)

const TRACK_TOP := 0.08      # the red track (raised a little)
const GRASS_TOP := 0.1       # planter soil and grass
const PAD_TOP := 0.06        # paved crossing through the planter
const CHUNK := 120.0

## For the tests: the gaps [x from, x to, side, kind], and every planter kerb line (the
## park-side kerbs and the ends) as a list of flat points.
var gaps: Array = []
var kerb_lines: Array = []
var plants := 0

var track_length := 0.0

## Session 75: the kerb lines are given to this, so riding over them gives a small bump.
var bumps: KerbBumps

var _spec: Dictionary = {}
var _kits := {}
var _tracks := {}


static func build(parent: Node3D, map: Dictionary, kerb_bumps: KerbBumps = null) -> SpineTracks:
	var tracks := SpineTracks.new()
	tracks.name = "SpineTracks"
	tracks.bumps = kerb_bumps
	parent.add_child(tracks)
	tracks.make(map.get("SPINE_TRACKS", {}))
	return tracks


static func track_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = SurfaceTextures.picture("walking_track")  # Session 82: red running_track photo
	mat.roughness = 0.97  # matte
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / SurfaceTextures.metres("walking_track")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


func make(spec: Dictionary) -> void:
	if spec.is_empty():
		return
	_spec = spec
	var from_x: float = spec["from_x"]
	var to_x: float = spec["to_x"]
	var road: float = spec["road_half"]
	var planter: float = spec["planter"]
	var track: float = spec["track"]
	for side: int in [-1, 1]:
		# The gaps on this side, as [from, to, kind]. Road gaps: [x, side, planter half gap,
		# track half gap] (Session 76: the planter stops where the road's curved corner
		# starts; the red track runs on a little closer, up to the curve).
		var cuts: Array = []
		var track_cuts: Array = []
		for g in spec["road_gaps"]:
			if int(g[1]) == 0 or int(g[1]) == side:
				var track_half: float = g[3] if g.size() > 3 else g[2]
				cuts.append([g[0] - g[2], g[0] + g[2], "road"])
				track_cuts.append([g[0] - track_half, g[0] + track_half, "road"])
		for g in spec["path_gaps"]:
			if int(g[1]) == 0 or int(g[1]) == side:
				cuts.append([g[0] - g[2], g[0] + g[2], "path"])
		cuts.sort_custom(func(a, b): return a[0] < b[0])
		track_cuts.sort_custom(func(a, b): return a[0] < b[0])
		gaps.append_array(cuts.map(func(c): return [c[0], c[1], side, c[2]]))
		var z0 := road * side                     # road edge
		var z1 := (road + planter) * side         # planter / track edge
		var z2 := (road + planter + track) * side # track / park edge
		for run in _runs_between(cuts, from_x, to_x):
			_planter(run[0], run[1], z0, z1, side)
		for run in _runs_between(track_cuts, from_x, to_x):
			_track(run[0], run[1], z1, z2)
		for cut in cuts:
			if cut[2] == "path":
				_crossing_pad(cut[0], cut[1], z0, z1)
		for cut in track_cuts:
			_road_stripes(cut[0], cut[1], z1, z2)
	_finish()


## The open stretches [from, to] between the gaps.
func _runs_between(cuts: Array, from_x: float, to_x: float) -> Array:
	var runs: Array = []
	var x := from_x
	for cut in cuts:
		if cut[0] > x:
			runs.append([x, cut[0]])
		x = maxf(x, cut[1])
	if x < to_x:
		runs.append([x, to_x])
	return runs


func _kit(key: String, x: float) -> MeshKit:
	var id := "%s_%d" % [key, floori(x / CHUNK)]
	if not _kits.has(id):
		_kits[id] = MeshKit.new()
	return _kits[id]


## Grass between two low kerbs, then the plants (no palms: DecorBuilder places those).
## The road-side kerb is RoadMesh's; this adds the track-side kerb and one across each end.
func _planter(a: float, b: float, z0: float, z1: float, side: int) -> void:
	var length := b - a
	var mid := (a + b) * 0.5
	var kit := _kit("planter", mid)
	var w := GameConfig.KERB_WIDTH
	var top := RoadMesh.ASPHALT_TOP + GameConfig.KERB_HEIGHT
	var outer := z1 - w * 0.5 * side
	kit.box(Vector3(length, top, w), KERB, Vector3(mid, top * 0.5, outer))
	var inside := absf(z1 - z0) - w * 2.0  # between the road's kerb and this one
	for x in [a + w * 0.5, b - w * 0.5]:
		kit.box(Vector3(w, top, inside), KERB, Vector3(x, top * 0.5, (z0 + z1) * 0.5))
	_kerb_line([Vector2(a, outer), Vector2(b, outer)])
	for x in [a + w * 0.5, b - w * 0.5]:
		_kerb_line([Vector2(x, z0 + w * side), Vector2(x, z1 - w * side)])
	kit.box(Vector3(length - w * 2.0, GRASS_TOP, inside), GRASS, Vector3(mid, GRASS_TOP * 0.5, (z0 + z1) * 0.5))
	# Plants: a repeating pattern every 15 m (hedge, bougainvillea, purple flowers).
	var green := _kit("plants", mid)
	var centre := (z0 + z1) * 0.5
	var x := ceilf((a + 1.0) / 15.0) * 15.0
	while x + 1.0 < b:
		var kind := posmod(int(x / 15.0), 3)
		if _near_palm(x):
			x += 15.0
			continue
		match kind:
			0:  # a clipped hedge
				green.box(Vector3(3.2, 0.7, 0.9), HEDGE, Vector3(x, GRASS_TOP + 0.35, centre))
			1:  # a bougainvillea bush, bright pink
				green.ball(0.55, BUSH, Vector3(x, GRASS_TOP + 0.5, centre), 0.9)
				for k in 6:
					var angle := k * TAU / 6.0
					green.ball(0.24, BOUGAINVILLEA, Vector3(x + cos(angle) * 0.42, GRASS_TOP + 0.55 + 0.18 * sin(k * 1.7), centre + sin(angle) * 0.38))
			2:  # a bed of purple flowers
				for k in 9:
					green.ball(0.13, PURPLE, Vector3(x - 1.6 + k * 0.4, GRASS_TOP + 0.12, centre + 0.25 * sin(k * 2.1)))
					green.ball(0.1, BUSH, Vector3(x - 1.4 + k * 0.4, GRASS_TOP + 0.06, centre - 0.25 * sin(k * 1.3)))
		plants += 1
		x += 15.0


## Palms stand every 45 m in the planters; keep the shrubs a little away from them.
func _near_palm(x: float) -> bool:
	return absf(fposmod(x + 310.0, 45.0)) < 2.5 or absf(fposmod(x + 310.0, 45.0) - 45.0) < 2.5


## The red track: a textured top (merged per 120 m) and its two thin darker edges.
func _track(a: float, b: float, z1: float, z2: float) -> void:
	var lo := minf(z1, z2)
	var hi := maxf(z1, z2)
	var id := "track_%d" % floori((a + b) * 0.5 / CHUNK)
	if not _tracks.has(id):
		var fresh := SurfaceTool.new()
		fresh.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tracks[id] = fresh
	var tool: SurfaceTool = _tracks[id]
	var corners := [Vector3(a, TRACK_TOP, lo), Vector3(b, TRACK_TOP, lo), Vector3(a, TRACK_TOP, hi), Vector3(b, TRACK_TOP, hi)]
	for tri in [[0, 1, 2], [1, 3, 2]]:
		for i in tri:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corners[i])
	var kit := _kit("edges", (a + b) * 0.5)
	for z in [lo, hi]:
		kit.box(Vector3(b - a, TRACK_TOP - 0.01, 0.02), TRACK_SIDE, Vector3((a + b) * 0.5, (TRACK_TOP - 0.01) * 0.5, z))
	track_length += b - a


var _mat: StandardMaterial3D
func _track_mat() -> StandardMaterial3D:
	if _mat == null:
		_mat = track_material()
	return _mat


## Remembers a planter kerb line (for the tests) and gives it to KerbBumps.
func _kerb_line(points: Array) -> void:
	kerb_lines.append(points)
	if bumps != null:
		bumps.add_line(points)


## A paved crossing through the planter with white stripes.
func _crossing_pad(a: float, b: float, z0: float, z1: float) -> void:
	var kit := _kit("pads", a)
	var mid := (a + b) * 0.5
	kit.box(Vector3(b - a, PAD_TOP, absf(z1 - z0)), PAD, Vector3(mid, PAD_TOP * 0.5, (z0 + z1) * 0.5))
	var x := a + 0.3
	while x + 0.4 <= b - 0.2:
		kit.box(Vector3(0.4, 0.01, absf(z1 - z0) - 0.3), STRIPE, Vector3(x + 0.2, PAD_TOP + 0.005, (z0 + z1) * 0.5))
		x += 0.8


## Where a road crosses the red track: white stripes on the road across the track's line.
func _road_stripes(a: float, b: float, z1: float, z2: float) -> void:
	var kit := _kit("pads", a)
	var x := a + 0.3
	while x + 0.5 <= b - 0.3:
		kit.box(Vector3(0.5, 0.01, absf(z2 - z1)), STRIPE, Vector3(x + 0.25, RoadMesh.ASPHALT_TOP + 0.012, (z1 + z2) * 0.5))
		x += 1.0


func _finish() -> void:
	for id: String in _tracks:
		var view := MeshInstance3D.new()
		view.name = "RedTrack_" + id.replace("-", "m")
		view.mesh = (_tracks[id] as SurfaceTool).commit()
		view.material_override = _track_mat()
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(view)
	_tracks.clear()
	for id: String in _kits:
		var view: MeshInstance3D = (_kits[id] as MeshKit).finish(id)
		if id.begins_with("plants"):
			view.visibility_range_end = 260.0
		add_child(view)
	_kits.clear()
