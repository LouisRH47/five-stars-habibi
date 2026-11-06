class_name SpineGreenery
extends Node3D
## Looks pass Session 58: the spine park looks alive.
##   (Session 82: the rectangle grass blade clumps are gone; the lawn is a grass photo now)
##   flower patches: little groups of one colour on short stems
##   rocks: grey and sandy stones, some in small groups
##   trees: round shade trees with solid trunks
## Everything keeps clear of the spine road, its planters and red tracks (SPINE_TRACKS),
## the domes, farm beds, pools, court, playground, pen, hives, stream, gym and stalls.
## SpineBuilder makes this.

const CHUNK := 40.0
const FLOWERS := [Color(1.0, 0.85, 0.2), Color(0.95, 0.5, 0.7), Color(0.97, 0.97, 0.95),
		Color(0.65, 0.45, 0.9), Color(1.0, 0.55, 0.2)]
const ROCKS := [Color(0.62, 0.6, 0.57), Color(0.78, 0.7, 0.56), Color(0.52, 0.5, 0.48)]
const LEAVES := [Color(0.28, 0.52, 0.24), Color(0.36, 0.58, 0.26)]
const TRUNK := Color(0.45, 0.33, 0.22)

var flower_count := 0
var rock_count := 0
var tree_count := 0
var tree_spots: Array[Vector2] = []
var _map: Dictionary
var _clear: ClearSpots
var _rng := RandomNumberGenerator.new()
var _blocked: Array[Rect2] = []
var _round: Array = []  # [Vector2, radius]


static func make(map: Dictionary) -> SpineGreenery:
	var green := SpineGreenery.new()
	green.name = "SpineGreenery"
	green._map = map
	green._clear = ClearSpots.new(map)
	green._build()
	return green


func _build() -> void:
	_rng.seed = 58058
	_areas()
	_flowers()
	_rocks()
	_trees()
	set_meta("counts", {"flowers": flower_count, "rocks": rock_count, "trees": tree_count})


## Where nothing may grow (besides the spine road, planters and tracks).
func _areas() -> void:
	for key in ["COMMUNITY_POOL", "LAP_POOL", "BASKETBALL_COURT", "PLAYGROUND", "BEEHIVES"]:
		if _map.has(key):
			_blocked.append((_map[key] as Rect2).grow(1.2))
	for bed in _map.get("FARM_BEDS", []):
		_blocked.append((bed as Rect2).grow(0.6))
	if _map.has("DONKEY_PEN"):
		_blocked.append((_map["DONKEY_PEN"]["area"] as Rect2).grow(0.8))
	if _map.has("GYM"):
		var gym: Vector3 = _map["GYM"]["position"]
		var size: Vector3 = _map["GYM"]["size"]
		_blocked.append(Rect2(gym.x - size.x * 0.5 - 2, gym.z - size.z * 0.5 - 3, size.x + 4, size.z + 5))
	for shop: Dictionary in _map.get("RESTAURANTS", []):
		if shop.get("style", "") == "stall":
			var p: Vector3 = shop["position"]
			var size: Vector3 = shop.get("size", Vector3(9, 4, 6))
			_blocked.append(Rect2(p.x - size.x * 0.5 - 3, p.z - size.z * 0.5 - 4, size.x + 6, size.z + 8))
	for dome: Vector3 in _map.get("SPINE_DOMES", []):
		_round.append([Vector2(dome.x, dome.z), _map.get("DOME_RADIUS", 7.0) + 1.0])
	if _map.has("STREAM"):  # Session 81: nothing grows in the stream's ponds or on their stones
		for pond: Dictionary in _map["STREAM"].get("ponds", []):
			_round.append([pond["centre"], pond["radius"] + 1.6])
	for mini: Dictionary in _map.get("MINI_PLAZAS", []):
		var tower: Vector3 = mini["tower"]
		_round.append([Vector2(tower.x, tower.z), 3.5])


## True if plants may grow at this spot (radius: how much room it needs).
func can_grow(spot: Vector2, radius := 0.0) -> bool:
	var spine: Rect2 = _map.get("SPINE", Rect2(-145, -35, 560, 70))
	if not spine.grow(-0.5 - radius).has_point(spot):
		return false
	if _map.has("SPINE_TRACKS"):
		var spec: Dictionary = _map["SPINE_TRACKS"]
		if absf(spot.y) < spec["road_half"] + spec["planter"] + spec["track"] + 0.7 + radius:
			return false
	if _map.has("STREAM"):
		var stream: Dictionary = _map["STREAM"]
		# The stream wiggles 3 m either side of its line (same curve as WahatBuilder._build_stream).
		var water_z: float = stream["z"] + sin(spot.x * 0.06) * 3.0
		if absf(spot.y - water_z) < stream["width"] * 0.5 + 1.2 + radius:
			return false
	for box in _blocked:
		if box.grow(radius).has_point(spot):
			return false
	for point: Array in _round:
		if (point[0] as Vector2).distance_to(spot) < point[1] + radius:
			return false
	return true


## The ground height (the spine hills rise here and there).
func ground(spot: Vector2) -> float:
	var y := 0.0
	for hill: Dictionary in _map.get("HILLS", []):
		var r := Vector2(spot.x - hill["position"].x, spot.y - hill["position"].z).length() / 10.0
		var flat: Vector2 = hill.get("clear", Vector2(3, 6))
		y += hill["height"] * pow(maxf(0.0, 1.0 - r * r), 2) * smoothstep(flat.x, flat.y, absf(spot.y))
	return y


func _random_spot(spine: Rect2) -> Vector2:
	return Vector2(_rng.randf_range(spine.position.x, spine.end.x), _rng.randf_range(spine.position.y, spine.end.y))


# --- Flowers, rocks and trees ---

func _flowers() -> void:
	var spine: Rect2 = _map.get("SPINE", Rect2(-145, -35, 560, 70))
	var heads: Array[Transform3D] = []
	var colours: Array[Color] = []
	var stems: Array[Transform3D] = []
	var patches := 0
	for i in GameConfig.SPINE_FLOWER_PATCHES * 3:
		if patches >= GameConfig.SPINE_FLOWER_PATCHES:
			break
		var middle := _random_spot(spine)
		if not can_grow(middle, 1.0):
			continue
		patches += 1
		var colour: Color = FLOWERS[_rng.randi() % FLOWERS.size()]
		for k in _rng.randi_range(6, 12):
			var spot := middle + Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9))
			var y := ground(spot)
			var tall := _rng.randf_range(0.18, 0.34)
			stems.append(Transform3D(Basis().scaled(Vector3(1, tall / 0.3, 1)), Vector3(spot.x, y + tall * 0.5, spot.y)))
			heads.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(spot.x, y + tall, spot.y)))
			colours.append(colour.lightened(_rng.randf_range(-0.1, 0.15)))
	flower_count = heads.size()
	var stem := BoxMesh.new()
	stem.size = Vector3(0.02, 0.3, 0.02)
	stem.material = LowPoly.material(Color(0.25, 0.5, 0.2))
	_chunks("FlowerStems", stem, stems, 70.0)
	var head := SphereMesh.new()
	head.radius = 0.06
	head.height = 0.07
	head.radial_segments = 6
	head.rings = 2
	var petal := StandardMaterial3D.new()
	petal.vertex_color_use_as_albedo = true
	petal.roughness = 0.9
	head.material = petal
	_chunks("FlowerHeads", head, heads, 70.0, colours)


func _rocks() -> void:
	var spine: Rect2 = _map.get("SPINE", Rect2(-145, -35, 560, 70))
	var places: Array[Transform3D] = []
	var colours: Array[Color] = []
	var groups := 0
	for i in GameConfig.SPINE_ROCKS * 3:
		if groups >= GameConfig.SPINE_ROCKS:
			break
		var middle := _random_spot(spine)
		if not can_grow(middle, 1.0) or not _clear.is_free(middle, 0.8):
			continue
		groups += 1
		for k in (_rng.randi_range(2, 4) if groups % 3 == 0 else 1):
			var spot := middle + Vector2(_rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.8, 0.8))
			var size := _rng.randf_range(0.18, 0.55)
			var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(size * _rng.randf_range(1.0, 1.6), size * 0.6, size))
			places.append(Transform3D(basis, Vector3(spot.x, ground(spot) + size * 0.12, spot.y)))
			colours.append(ROCKS[_rng.randi() % ROCKS.size()])
	rock_count = places.size()
	var rock := SphereMesh.new()
	rock.radius = 0.5
	rock.height = 0.8
	rock.radial_segments = 7
	rock.rings = 3
	var stone := StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.roughness = 0.95
	rock.material = stone
	_chunks("Rocks", rock, places, 110.0, colours)


func _trees() -> void:
	var spine: Rect2 = _map.get("SPINE", Rect2(-145, -35, 560, 70))
	var trunks := StaticBody3D.new()
	trunks.name = "TreeTrunks"
	add_child(trunks)
	var lists: Array = [[], []]
	for i in GameConfig.SPINE_TREES * 8:
		if tree_count >= GameConfig.SPINE_TREES:
			break
		var spot := _random_spot(spine)
		if not can_grow(spot, 3.0) or not _clear.is_free(spot, 3.0):
			continue
		var close := false
		for other in tree_spots:
			if other.distance_to(spot) < 9.0:
				close = true
				break
		if close:
			continue
		var size := _rng.randf_range(0.8, 1.15)
		var at := Vector3(spot.x, ground(spot), spot.y)
		lists[tree_count % 2].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size), at))
		LowPoly.solid_cylinder(trunks, 0.35 * size, 3.0, at + Vector3(0, 1.5, 0))
		tree_spots.append(spot)
		_clear.add(spot, 3.0)
		tree_count += 1
	for k in 2:
		_chunks("ShadeTrees%d" % k, _tree_mesh(LEAVES[k]), lists[k], 260.0)


## A round shade tree in one mesh (like the edge trees, Session 63).
func _tree_mesh(leaves: Color) -> Mesh:
	var kit := MeshKit.new()
	kit.cylinder(0.25, 0.35, 4.0, TRUNK, Vector3(0, 2.0, 0))
	kit.ball(2.4, leaves, Vector3(0, 5.3, 0), 0.85)
	kit.ball(1.5, leaves.lightened(0.08), Vector3(1.1, 4.8, 0.6), 0.85)
	var view := kit.finish()
	var mesh: Mesh = view.mesh
	view.free()  # only the mesh is kept; the node would leak otherwise
	mesh.surface_set_material(0, MeshKit.material())
	return mesh


## Splits instances into CHUNK-sized MultiMeshes (so far-off chunks aren't drawn).
func _chunks(id: String, mesh: Mesh, places: Array, reach: float, colours: Array = []) -> Array[MultiMeshInstance3D]:
	var cells := {}
	for i in places.size():
		var t: Transform3D = places[i]
		var cell := Vector2i(floori(t.origin.x / CHUNK), floori(t.origin.z / CHUNK))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(i)
	var group := Node3D.new()
	group.name = id
	add_child(group)
	var views: Array[MultiMeshInstance3D] = []
	for cell: Vector2i in cells:
		var origin := Vector3(cell.x + 0.5, 0, cell.y + 0.5) * CHUNK
		var list: Array = cells[cell]
		var many := MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_3D
		many.use_colors = not colours.is_empty()
		many.mesh = mesh
		many.instance_count = list.size()
		for k in list.size():
			var t: Transform3D = places[list[k]]
			many.set_instance_transform(k, Transform3D(t.basis, t.origin - origin))
			if not colours.is_empty():
				many.set_instance_color(k, colours[list[k]])
		var view := MultiMeshInstance3D.new()
		view.position = origin
		view.multimesh = many
		# Headless runs (the tests) can't read copies back from a MultiMesh, so keep the list.
		var kept: Array = []
		for k in list.size():
			var t: Transform3D = places[list[k]]
			kept.append(Transform3D(t.basis, t.origin - origin))
		view.set_meta("instance_transforms", kept)
		view.visibility_range_end = reach
		if id.begins_with("Flower"):
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(view)
		views.append(view)
	return views
