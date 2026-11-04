class_name GrassField
extends Node3D
## Session 55: real-looking grass. Tufts of 6 blades (3 triangles each) cover the lawns,
## sway in the wind and bend away from the bike (assets/shaders/grass.gdshader).
## The lawn is big (about 40,000 m²), so grass is only made close to the camera, in squares
## of GRASS_CHUNK metres: new squares fill in a little each frame as you ride, far ones are
## thrown away. Every square is made from the same random seed, so it looks the same each
## time. No grass on paths, roads, pools, courts, beds, buildings or water: anything that
## sits on the lawn makes a hole. Numbers in game_config.gd ("real grass").

var tufts_per_m2 := 4.0
var radius := 38.0
## The lawns: [Rect2 (x, z), height of their top].
var lawns: Array = []
## Hills from the map data (grass grows over them).
var hills: Array = []
## Areas kept clear of grass from the map data (farm beds, hives, pools, courts...).
var clear_areas: Array = []
## How many tufts are showing now (the tests read it).
var tuft_count := 0

var _holes: Array = []        # [inverse transform, local box] or [centre, radius]
var _holes_by_chunk := {}     # chunk key -> hole indexes
var _chunks := {}             # chunk key -> MultiMeshInstance3D
var _sizes := {}              # chunk key -> how many tufts it has
var _work := {}               # chunk key -> a square that's half filled
var _mesh: ArrayMesh
var _material: ShaderMaterial


## world: the map (things on the lawn make holes). lawn_meshes: the lawn ground pieces.
func setup(world: Node, lawn_meshes: Array, hill_specs: Array, keep_clear: Array = []) -> void:
	add_to_group("graphics")   # Settings.apply() calls apply_graphics()
	hills = hill_specs
	for area: Rect2 in keep_clear:
		clear_areas.append(area.grow(0.3))
	for lawn: MeshInstance3D in lawn_meshes:
		var box := lawn.global_transform * lawn.get_aabb()
		lawns.append([Rect2(box.position.x, box.position.z, box.size.x, box.size.z), box.end.y])
	_mesh = _tuft_mesh()
	_material = ShaderMaterial.new()
	_material.shader = load("res://assets/shaders/grass.gdshader")
	_material.set_shader_parameter("root_colour", GameConfig.GRASS_ROOT)
	_material.set_shader_parameter("tip_colour", GameConfig.GRASS_TIP)
	_material.set_shader_parameter("wind_strength", GameConfig.GRASS_WIND_STRENGTH)
	_material.set_shader_parameter("wind_speed", GameConfig.GRASS_WIND_SPEED)
	_material.set_shader_parameter("push_radius", GameConfig.GRASS_PUSH_RADIUS)
	_find_holes(world, lawn_meshes)
	apply_graphics()


## Low has fewer blades and a shorter grass distance than Medium and High.
func apply_graphics() -> void:
	var level := clampi(Settings.graphics, 0, 2)
	tufts_per_m2 = GameConfig.GRASS_TUFTS_PER_M2[level]
	radius = GameConfig.GRASS_RADIUS[level]
	if _material != null:
		_material.set_shader_parameter("fade_start", radius - GameConfig.GRASS_FADE)
		_material.set_shader_parameter("fade_end", radius)
	for key in _chunks.keys():
		_drop(key)
	_work.clear()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or lawns.is_empty():
		return
	var bike := get_tree().get_first_node_in_group("bike") as Node3D
	if bike != null:
		_material.set_shader_parameter("pusher", bike.global_position)
	fill_around(camera.global_position, GameConfig.GRASS_BUILD_MS)


## Makes the missing squares near `centre` (nearest first) and drops the far ones.
## budget_ms: how long it may work this frame (a square can take a few frames to finish,
## so riding never stutters). Below 0: everything at once (tests).
func fill_around(centre: Vector3, budget_ms: float) -> void:
	var size := GameConfig.GRASS_CHUNK
	var wanted := []
	var reach := int(ceil(radius / size))
	var home := Vector2i(floori(centre.x / size), floori(centre.z / size))
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var key := home + Vector2i(dx, dz)
			var middle := (Vector2(key) + Vector2(0.5, 0.5)) * size
			var gap := middle.distance_to(Vector2(centre.x, centre.z)) - size * 0.71
			if gap < radius and _on_lawn(key):
				wanted.append([gap, key])
	wanted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var keep := {}
	for item in wanted:
		keep[item[1]] = true
	for key in _chunks.keys():
		if not keep.has(key):
			_drop(key)
	for key in _work.keys():
		if not keep.has(key):
			_work.erase(key)
	var stop := Time.get_ticks_usec() + int(budget_ms * 1000.0)
	for item in wanted:
		var key: Vector2i = item[1]
		if _chunks.has(key):
			continue
		if not _work.has(key):
			_work[key] = _start_spots(key)
		var job: Dictionary = _work[key]
		while job["left"] > 0:
			_more_spots(job, 128)
			if budget_ms >= 0.0 and Time.get_ticks_usec() > stop:
				return
		_work.erase(key)
		_build(key, job["spots"])
		if budget_ms >= 0.0 and Time.get_ticks_usec() > stop:
			return


## Where a tuft at (x, z) would stand, or NAN if there's no grass there.
func ground_height(x: float, z: float) -> float:
	var top := NAN
	for lawn in lawns:
		if (lawn[0] as Rect2).has_point(Vector2(x, z)):
			top = lawn[1]
	if is_nan(top):
		return NAN
	for hill: Dictionary in hills:
		var spot: Vector3 = hill["position"]
		var r := Vector2(x - spot.x, z - spot.z).length() / 10.0
		if r < 1.0:
			top += hill["height"] * pow(1.0 - r * r, 2) * smoothstep(3.0, 6.0, absf(z))
	return top


## True if something on the lawn (a path, pool, bed, building, water...) covers (x, z).
func in_hole(x: float, z: float, key: Vector2i) -> bool:
	for area: Rect2 in clear_areas:
		if area.has_point(Vector2(x, z)):
			return true
	for index: int in _holes_by_chunk.get(key, []):
		var hole: Array = _holes[index]
		if hole.size() == 2:
			if Vector2(x, z).distance_to(hole[0]) < hole[1]:
				return true
		else:
			var local: Vector3 = hole[0] * Vector3(x, hole[2], z)
			var box: AABB = hole[1]
			if local.x >= box.position.x and local.x <= box.end.x and local.z >= box.position.z and local.z <= box.end.z:
				return true
	return false


func chunk_count() -> int:
	return _chunks.size()


## Where the tufts in square `key` go (relative to the square's corner). Always the same
## for the same square and Graphics setting.
func make_spots(key: Vector2i) -> Array[Transform3D]:
	var job := _start_spots(key)
	_more_spots(job, job["left"])
	return job["spots"]


func _start_spots(key: Vector2i) -> Dictionary:
	var size := GameConfig.GRASS_CHUNK
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var spots: Array[Transform3D] = []
	return {"key": key, "rng": rng, "spots": spots, "left": int(size * size * tufts_per_m2)}


## Tries `count` more tuft spots for a square that's being filled.
func _more_spots(job: Dictionary, count: int) -> void:
	var size := GameConfig.GRASS_CHUNK
	var key: Vector2i = job["key"]
	var corner := Vector2(key) * size
	var rng: RandomNumberGenerator = job["rng"]
	var spots: Array[Transform3D] = job["spots"]
	count = mini(count, job["left"])
	job["left"] -= count
	for i in count:
		var x := corner.x + rng.randf() * size
		var z := corner.y + rng.randf() * size
		var turn := rng.randf() * TAU
		var tall := rng.randf_range(GameConfig.GRASS_HEIGHT.x, GameConfig.GRASS_HEIGHT.y)
		var y := ground_height(x, z)
		if is_nan(y) or in_hole(x, z, key):
			continue
		var basis := Basis(Vector3.UP, turn).scaled(Vector3(1.0, tall, 1.0))
		spots.append(Transform3D(basis, Vector3(x - corner.x, y, z - corner.y)))


## The keys of the squares with grass right now.
func chunk_keys() -> Array:
	return _chunks.keys().filter(func(key: Vector2i) -> bool: return _chunks[key] != null)


func _build(key: Vector2i, spots: Array[Transform3D]) -> void:
	var size := GameConfig.GRASS_CHUNK
	var corner := Vector2(key) * size
	if spots.is_empty():
		_chunks[key] = null
		return
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = _mesh
	many.instance_count = spots.size()
	for i in spots.size():
		many.set_instance_transform(i, spots[i])
	var view := MultiMeshInstance3D.new()
	view.name = "Grass_%d_%d" % [key.x, key.y]
	view.multimesh = many
	view.material_override = _material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.position = Vector3(corner.x, 0.0, corner.y)
	view.custom_aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3(size + 1.0, 2.0, size + 1.0))
	add_child(view)
	_chunks[key] = view
	_sizes[key] = spots.size()
	tuft_count += spots.size()


func _drop(key: Vector2i) -> void:
	var view: MultiMeshInstance3D = _chunks.get(key)
	if view != null and is_instance_valid(view):
		view.queue_free()
	tuft_count -= int(_sizes.get(key, 0))
	_sizes.erase(key)
	_chunks.erase(key)


func _on_lawn(key: Vector2i) -> bool:
	var size := GameConfig.GRASS_CHUNK
	var square := Rect2(Vector2(key) * size, Vector2(size, size))
	for lawn in lawns:
		if (lawn[0] as Rect2).intersects(square):
			return true
	return false


## Anything standing on the lawn makes a hole. Tall thin things (palms, lamp posts, sign
## posts) only make a small round one, so the grass grows right up to them.
func _find_holes(world: Node, lawn_meshes: Array) -> void:
	var area := Rect2()
	var lowest := INF
	for i in lawns.size():
		area = lawns[i][0] if i == 0 else area.merge(lawns[i][0])
		lowest = minf(lowest, lawns[i][1])
	var grass := TerrainMaterials.make("grass")
	for part: MeshInstance3D in world.find_children("*", "MeshInstance3D", true, false):
		if part in lawn_meshes or part.material_override == grass or not part.is_visible_in_tree() or part.mesh == null \
				or part.skin != null:   # people and animals move, they don't make holes
			continue
		var box := part.global_transform * part.get_aabb()
		var footprint := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
		if not footprint.intersects(area) or box.end.y < lowest + 0.004 or box.position.y > 0.6:
			continue
		var hole: Array
		if box.size.y > 2.0 and box.size.x * box.size.z < 25.0:
			hole = [Vector2(part.global_position.x, part.global_position.z), 0.5]
			footprint = Rect2(hole[0] - Vector2(0.5, 0.5), Vector2(1, 1))
		else:
			var local := part.get_aabb().grow(0.0)
			var scale := part.global_basis.get_scale()
			var edge := Vector3(0.15 / maxf(scale.x, 0.01), 0.0, 0.15 / maxf(scale.z, 0.01))
			local.position -= edge
			local.size += edge * 2.0
			hole = [part.global_transform.affine_inverse(), local, box.get_center().y]
			footprint = footprint.grow(0.15)
		_holes.append(hole)
		var size := GameConfig.GRASS_CHUNK
		for z in range(floori(footprint.position.y / size), floori(footprint.end.y / size) + 1):
			for x in range(floori(footprint.position.x / size), floori(footprint.end.x / size) + 1):
				var key := Vector2i(x, z)
				if not _holes_by_chunk.has(key):
					_holes_by_chunk[key] = []
				_holes_by_chunk[key].append(_holes.size() - 1)


## One tuft: 6 thin blades leaning out a little. Height 1 (each tuft is stretched to size).
func _tuft_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for blade in 6:
		var turn := blade * TAU / 6.0 + rng.randf_range(-0.4, 0.4)
		var out := Vector3(cos(turn), 0.0, sin(turn))
		var side := Vector3(-out.z, 0.0, out.x)
		var base := out * rng.randf_range(0.02, 0.12)
		var lean := out * rng.randf_range(0.06, 0.16)
		var tall := rng.randf_range(0.65, 1.0)
		var b_left := base - side * 0.03
		var b_right := base + side * 0.03
		var m_left := base + lean * 0.5 + Vector3.UP * tall * 0.5 - side * 0.022
		var m_right := base + lean * 0.5 + Vector3.UP * tall * 0.5 + side * 0.022
		var tip := base + lean + Vector3.UP * tall
		for corner in [[b_left, 0.0], [b_right, 0.0], [m_right, 0.5], [b_left, 0.0], [m_right, 0.5],
				[m_left, 0.5], [m_left, 0.5], [m_right, 0.5], [tip, 1.0]]:
			tool.set_normal(Vector3.UP)
			tool.set_uv(Vector2(0.5, corner[1]))
			tool.add_vertex(corner[0])
	return tool.commit()
