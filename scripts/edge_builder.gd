class_name EdgeBuilder
extends Node3D
## Session 63: the edges of Wahat Al Shams, green and round.
## - The blue run-and-cycle track (a fine rubbery texture with lane lines) and the sandy horse
##   track, both with rounded corners that match the ring road's.
## - Palms, round trees and hedges in the strip between the ring road and the blue track,
##   all the way round (open at the gate roads and where the horses cross).
## - Past the fence: a thicker tree belt, low sand dunes and a few far-off towers, so the
##   world doesn't end in flat sand.
## WahatBuilder calls build(). Trees are MultiMeshes in 120 m squares, so it stays fast.

const TRUNK := Color(0.5, 0.36, 0.22)
const LEAVES := Color(0.3, 0.52, 0.26)
const LEAVES_LIGHT := Color(0.42, 0.6, 0.3)
const PALM_TRUNK := Color(0.55, 0.42, 0.28)
const FROND := Color(0.27, 0.55, 0.24)
const HEDGE := Color(0.2, 0.42, 0.18)
const DUNE := Color(0.88, 0.78, 0.58)
const FAR := Color(0.66, 0.71, 0.77)

const BIKE_TOP := 0.02
const HORSE_TOP := 0.015
const CHUNK := 120.0

## For the smoke test.
var greenery_count := 0
var belt_trees := 0
var dunes := 0
var far_shapes := 0

var _map: Dictionary = {}
var _spots := {"palm": [], "tree": [], "hedge": [], "belt": []}


static func build(parent: Node3D, map: Dictionary) -> EdgeBuilder:
	var edge := EdgeBuilder.new()
	edge.name = "EdgeBuilder"
	parent.add_child(edge)
	edge.make(map)
	return edge


## Points round a rectangle (half size) with rounded corners, clockwise from the north-west
## (the same as rounded_loop() in tools/build_wahat_data.py). radius 0 gives sharp corners.
static func rounded_rect(half: Vector2, radius: float, steps := 8) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var r := clampf(radius, 0.0, minf(half.x, half.y))
	var corners := [[Vector2(-half.x + r, -half.y + r), 180.0], [Vector2(half.x - r, -half.y + r), 270.0],
			[Vector2(half.x - r, half.y - r), 0.0], [Vector2(-half.x + r, half.y - r), 90.0]]
	for corner in corners:
		var count := steps if r > 0.0 else 0
		for j in count + 1:
			var angle := deg_to_rad(corner[1] + 90.0 * j / maxf(count, 1))
			out.append(corner[0] + Vector2(cos(angle), sin(angle)) * r)
	return out


func make(map: Dictionary) -> void:
	_map = map
	_tracks()
	_greenery()
	_belt_extras()
	_dunes_and_far()
	_plant_all()


# --- Tracks --------------------------------------------------------------------------

func _tracks() -> void:
	var bike: Dictionary = _map.get("BIKE_TRACK", {})
	var horse: Dictionary = _map.get("HORSE_TRACK", {})
	if not horse.is_empty():
		_ring_strip("HorseTrack", horse, HORSE_TOP, TerrainMaterials.make("sand"))
	if not bike.is_empty():
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = SurfaceTextures.picture("blue_track")  # Session 82: running_track photo
		mat.roughness = 0.95
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_ring_strip("BikeTrack", bike, BIKE_TOP, mat)


## A closed strip round the map along a rounded rectangle; u runs across (0 to 1), v along
## (one texture tile every 8 m), so the lane lines follow the track.
func _ring_strip(id: String, track: Dictionary, top: float, mat: Material) -> void:
	var pts := rounded_rect(track["half"], track.get("radius", 0.0))
	var w: float = track["width"] * 0.5
	var n := pts.size()
	var tools := {}
	var along := 0.0
	for k in n:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % n]
		var sa := _side(pts, k)
		var sb := _side(pts, (k + 1) % n)
		var length := a.distance_to(b)
		# Long straight sides are cut into 40 m pieces, so each 120 m square gets its own mesh.
		var bits := maxi(1, ceili(length / 40.0))
		for s in bits:
			var p0 := a.lerp(b, float(s) / bits)
			var p1 := a.lerp(b, float(s + 1) / bits)
			var s0 := sa.lerp(sb, float(s) / bits)
			var s1 := sa.lerp(sb, float(s + 1) / bits)
			var v0 := along / 8.0
			along += length / bits
			var v1 := along / 8.0
			var cell := Vector2i(floori((p0.x + p1.x) * 0.5 / CHUNK), floori((p0.y + p1.y) * 0.5 / CHUNK))
			if not tools.has(cell):
				var fresh := SurfaceTool.new()
				fresh.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[cell] = fresh
			var tool: SurfaceTool = tools[cell]
			var quad := [[p0 - s0 * w, Vector2(0, v0)], [p0 + s0 * w, Vector2(1, v0)],
					[p1 - s1 * w, Vector2(0, v1)], [p1 + s1 * w, Vector2(1, v1)]]
			for tri in [[0, 1, 2], [1, 3, 2]]:
				var corner_a: Vector2 = quad[tri[0]][0]
				var corner_b: Vector2 = quad[tri[1]][0]
				var corner_c: Vector2 = quad[tri[2]][0]
				var order: Array = tri if (Vector3(corner_b.x - corner_a.x, 0, corner_b.y - corner_a.y)).cross(Vector3(corner_c.x - corner_a.x, 0, corner_c.y - corner_a.y)).y < 0.0 else [tri[0], tri[2], tri[1]]
				for i in order:
					tool.set_normal(Vector3.UP)
					tool.set_uv(quad[i][1])
					tool.add_vertex(Vector3(quad[i][0].x, top, quad[i][0].y))
	var holder := Node3D.new()
	holder.name = id
	add_child(holder)
	for cell: Vector2i in tools:
		var view := MeshInstance3D.new()
		view.mesh = (tools[cell] as SurfaceTool).commit()
		view.material_override = mat
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(view)


## The outward-pointing side at point k of a clockwise loop, longer at corners.
func _side(pts: Array[Vector2], k: int) -> Vector2:
	var n := pts.size()
	var d1 := (pts[k] - pts[(k - 1 + n) % n]).normalized()
	var d2 := (pts[(k + 1) % n] - pts[k]).normalized()
	var s1 := Vector2(d1.y, -d1.x)
	var s2 := Vector2(d2.y, -d2.x)
	var mid := (s1 + s2).normalized()
	return mid / maxf(mid.dot(s1), 0.5)


# --- Greenery between the ring road and the blue track -------------------------------------

func _greenery() -> void:
	var strip: Dictionary = _map.get("EDGE_GREENERY", {})
	if strip.is_empty():
		return
	var pts := rounded_rect(strip["half"], strip["radius"], 6)
	var spacing: float = strip["spacing"]
	var offset: float = strip["width"] * 0.5 - 0.9
	var n := pts.size()
	var index := 0
	var leftover := 0.0
	for k in n:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % n]
		var length := a.distance_to(b)
		var d := (b - a) / maxf(length, 0.001)
		var outward := Vector2(d.y, -d.x)
		var s := leftover
		while s < length:
			var p := a + d * s
			if not _blocked(p):
				var kind: String = ["palm", "tree", "palm", "tree_light"][index % 4]
				_spots["palm" if kind == "palm" else "tree"].append([p - outward * 0.6, index, kind == "tree_light"])
				# A hedge between this plant and the next, on the blue-track side.
				var h := p + d * spacing * 0.5 + outward * offset
				if not _blocked(h) and s + spacing * 0.5 < length:
					_spots["hedge"].append([h, atan2(d.x, d.y)])
				greenery_count += 1
			index += 1
			s += spacing
		leftover = s - length


## Gaps in the greenery: the gate roads and where the horses cross to the track.
func _blocked(p: Vector2) -> bool:
	for gate: Dictionary in _map.get("GATES", []):
		if p.x < 0.0 and absf(p.y - gate["position"].z) < 10.0:
			return true
	for crossing: Dictionary in _map.get("HORSE_CROSSINGS", []):
		var to: Vector3 = crossing["to"]
		if absf(p.x - to.x) < 6.0 and absf(absf(p.y) - absf(to.z)) < 30.0 and signf(p.y) == signf(to.z):
			return true
	return false


# --- Past the fence --------------------------------------------------------------------

## Three more rows of trees outside the walls (west: beyond the highway).
func _belt_extras() -> void:
	var half: Vector2 = _map.get("MAP_HALF", Vector2(470, 250))
	var spacing: float = _map.get("TREE_BELT", {}).get("spacing", 8.0)
	for row in 3:
		var east := half.x + 4.0 + row * 4.0
		var west := -(half.x + 24.0 + row * 5.0)   # past the highway and the gate road ends
		var z := -half.y - 12.0
		while z <= half.y + 12.0:
			_spots["belt"].append(Vector3(east, 0, z + row * 2.7))
			_spots["belt"].append(Vector3(west, 0, z + row * 2.7))
			z += spacing
		var x := west
		while x <= east:
			for side in [-1.0, 1.0]:
				_spots["belt"].append(Vector3(x + row * 2.7, 0, side * (half.y + 4.0 + row * 4.0)))
			x += spacing


func _dunes_and_far() -> void:
	var half: Vector2 = _map.get("MAP_HALF", Vector2(470, 250))
	# Sand stretching away under the dunes (below the map's own ground).
	var floor_view := MeshInstance3D.new()
	floor_view.name = "DesertFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(3200, 3200)
	floor_view.mesh = plane
	floor_view.position.y = -0.03
	floor_view.material_override = TerrainMaterials.make("sand")
	floor_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_view)
	# Low dunes in a ring beyond the trees.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6363
	var mound := SphereMesh.new()
	mound.radial_segments = 12
	mound.rings = 6
	mound.material = LowPoly.material(DUNE)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = mound
	var places: Array[Transform3D] = []
	for i in 56:
		var angle := TAU * i / 56.0 + rng.randf_range(-0.04, 0.04)
		var reach := rng.randf_range(1.12, 1.45)
		var spot := Vector3(cos(angle) * (half.x + 40.0) * reach, 0, sin(angle) * (half.y + 40.0) * reach)
		var size := Vector3(rng.randf_range(30, 60), rng.randf_range(2.5, 6.0), rng.randf_range(14, 26))
		places.append(Transform3D(Basis(Vector3.UP, angle + PI * 0.5).scaled(size * 0.5), spot))
	many.instance_count = places.size()
	for i in places.size():
		many.set_instance_transform(i, places[i])
	var dune_view := MultiMeshInstance3D.new()
	dune_view.name = "Dunes"
	dune_view.multimesh = many
	dune_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dune_view)
	dunes = places.size()
	# A few far-off towers of the city of Al Sarab, hazy in the distance.
	var kit := MeshKit.new()
	for i in 14:
		var angle := deg_to_rad(-150.0 + i * 9.0 + rng.randf_range(-3, 3))
		var spot := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(1050, 1300)
		var tall := rng.randf_range(40, 150)
		var wide := rng.randf_range(18, 34)
		kit.box(Vector3(wide, tall, wide), FAR, spot + Vector3.UP * tall * 0.5)
		if i % 4 == 1:
			kit.cylinder(0.0, wide * 0.3, 30.0, FAR, spot + Vector3.UP * (tall + 15.0))
		far_shapes += 1
	var far := kit.finish("FarCity")
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(far)


# --- Planting ------------------------------------------------------------------------

func _plant_all() -> void:
	var palm := _palm_mesh()
	var tree := _tree_mesh(LEAVES)
	var tree_light := _tree_mesh(LEAVES_LIGHT)
	var hedge := BoxMesh.new()
	hedge.size = Vector3(0.9, 0.9, 4.2)
	hedge.material = LowPoly.material(HEDGE)
	var solid := StaticBody3D.new()
	solid.name = "EdgeGreenerySolid"
	solid.set_meta("impact_category", "wood")
	solid.set_meta("impact_name", "a tree")
	add_child(solid)
	var lists := {"palm": [], "tree": [], "tree_light": [], "hedge": [], "belt": []}
	for item in _spots["palm"]:
		var p: Vector2 = item[0]
		lists["palm"].append(Transform3D(Basis(Vector3.UP, float(item[1]) * 2.4).scaled(Vector3.ONE * (0.9 + fmod(item[1] * 0.37, 0.3))), Vector3(p.x, 0, p.y)))
		LowPoly.solid_cylinder(solid, 0.35, 2.0, Vector3(p.x, 1.0, p.y))
	for item in _spots["tree"]:
		var p: Vector2 = item[0]
		lists["tree_light" if item[2] else "tree"].append(Transform3D(Basis().scaled(Vector3.ONE * (0.75 + fmod(item[1] * 0.29, 0.3))), Vector3(p.x, 0, p.y)))
		LowPoly.solid_cylinder(solid, 0.35, 2.0, Vector3(p.x, 1.0, p.y))
	for item in _spots["hedge"]:
		var p: Vector2 = item[0]
		lists["hedge"].append(Transform3D(Basis(Vector3.UP, item[1]), Vector3(p.x, 0.45, p.y)))
		var shape := LowPoly.solid_box(solid, Vector3(0.9, 0.9, 4.2), Vector3(p.x, 0.45, p.y))
		shape.basis = Basis(Vector3.UP, item[1])
	for spot: Vector3 in _spots["belt"]:
		var i: int = lists["belt"].size()
		lists["belt"].append(Transform3D(Basis().scaled(Vector3.ONE * (0.85 + fmod(i * 0.37, 0.4))), spot))
		belt_trees += 1
	for pair in [["palm", palm], ["tree", tree], ["tree_light", tree_light], ["hedge", hedge], ["belt", tree]]:
		_multimesh("Edge_" + pair[0], pair[1], lists[pair[0]])


func _multimesh(id: String, mesh: Mesh, places: Array) -> void:
	var cells := {}
	for t: Transform3D in places:
		var cell := Vector2i(floori(t.origin.x / CHUNK), floori(t.origin.z / CHUNK))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(t)
	var group := Node3D.new()
	group.name = id
	add_child(group)
	for cell: Vector2i in cells:
		var origin := Vector3(cell.x + 0.5, 0, cell.y + 0.5) * CHUNK
		var list: Array = cells[cell]
		var many := MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_3D
		many.mesh = mesh
		many.instance_count = list.size()
		for i in list.size():
			var t: Transform3D = list[i]
			many.set_instance_transform(i, Transform3D(t.basis, t.origin - origin))
		var view := MultiMeshInstance3D.new()
		view.position = origin
		view.multimesh = many
		group.add_child(view)


## A simple date palm in one mesh: a leaning trunk and a crown of drooping fronds.
func _palm_mesh() -> Mesh:
	var kit := MeshKit.new()
	for i in 4:
		var y := 1.5 * i
		kit.cylinder(0.24 - i * 0.03, 0.3 - i * 0.03, 1.55, PALM_TRUNK, Vector3(0.1 * i, y + 0.75, 0))
	var top := Vector3(0.4, 6.1, 0)
	for f in 8:
		var turn := Basis(Vector3.UP, f * TAU / 8.0) * Basis(Vector3.RIGHT, deg_to_rad(28))
		kit.box(Vector3(0.5, 0.05, 2.8), FROND, top + turn * Vector3(0, 0, 1.3), turn)
	var view := kit.finish()
	var mesh: Mesh = view.mesh
	view.free()  # only the mesh is kept; the node would leak otherwise
	mesh.surface_set_material(0, MeshKit.material())
	return mesh


## A round shade tree in one mesh.
func _tree_mesh(leaves: Color) -> Mesh:
	var kit := MeshKit.new()
	kit.cylinder(0.25, 0.35, 4.0, TRUNK, Vector3(0, 2.0, 0))
	kit.ball(2.6, leaves, Vector3(0, 5.6, 0), 0.85)
	var view := kit.finish()
	var mesh: Mesh = view.mesh
	view.free()  # only the mesh is kept; the node would leak otherwise
	mesh.surface_set_material(0, MeshKit.material())
	return mesh
