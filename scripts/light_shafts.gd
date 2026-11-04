extends Node3D
## Session 67: soft beams of sunlight with floating dust coming in through the big shop glass
## (PRD "Polish pass", Light and colour; polish plan L6). Added by scripts/polish/look_extras.gd.
## Walk-in rooms built the Looks-pass way (meta "room_size", glass on their +z side) get two
## beams each. A beam starts just inside the glass and slants down along the sun, and each
## edge stops at the floor or a wall, so no beam pokes out of its room.
## There are at most GameConfig.SHAFT_MAX beams: they go to the rooms nearest the camera
## (checked twice a second), and are only drawn within GameConfig.SHAFT_RANGE metres.
## Strongest in the morning and late afternoon (GameConfig.SHAFT_HOUR_KEYS). Medium and High only.

const SHADER := preload("res://assets/shaders/light_shaft.gdshader")
const MARGIN := 0.15        # metres the beams stay inside the walls, floor and ceiling
const GLASS_IN := 0.3       # metres inside the glass where a beam starts
const WINDOW_Y := Vector2(1.0, 3.0)  # the part of the glass the beams come through (height)
const MAX_LENGTH := 7.0     # metres: the longest a beam edge gets
const REBUILD_HOURS := 0.25  # the beams follow the sun every quarter of a game hour

var sun: DirectionalLight3D
## The beams in use: {"view": MeshInstance3D, "room": Node3D, "x": metres across the glass}.
var shafts: Array[Dictionary] = []
var rooms: Array[Node3D] = []
var _pool: Array[MeshInstance3D] = []
var _material: ShaderMaterial
var _built_hour := -100.0
var _level := -1


## Finds the rooms under `world` and makes the beams (not drawn until apply_graphics()).
func setup(world: Node, sun_light: DirectionalLight3D) -> void:
	sun = sun_light
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	rooms = find_rooms(world)
	for i in GameConfig.SHAFT_MAX:
		var view := MeshInstance3D.new()
		view.name = "Shaft%d" % i
		view.material_override = _material
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		view.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		view.visibility_range_end = GameConfig.SHAFT_RANGE
		view.visibility_range_end_margin = 6.0
		view.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		view.visible = false
		add_child(view)
		_pool.append(view)
	add_to_group("graphics")  # Settings.apply() calls apply_graphics()
	apply_graphics()


## The Looks-pass walk-in rooms (restaurants and shops) that have a glass front.
static func find_rooms(world: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for node in world.find_children("*", "StaticBody3D", true, false):
		if node.has_meta("room_size") and node.get_meta("interior_looks", false):
			found.append(node)
	return found


func apply_graphics() -> void:
	_level = Settings.graphics
	visible = GameConfig.LIGHT_SHAFTS_ON and _level >= 1
	_built_hour = -100.0
	if visible:
		_update(GameState.clock_hours())


func _process(_delta: float) -> void:
	if visible and Engine.get_process_frames() % 30 == 0:
		_update(GameState.clock_hours())


## Gives the beams to the rooms nearest the camera, moves them with the sun and sets how
## strong they are for this hour.
func _update(hour: float) -> void:
	if sun == null or rooms.is_empty():
		return
	var rebuild := absf(hour - _built_hour) >= REBUILD_HOURS
	if rebuild:
		_built_hour = hour
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var from := camera.global_position if camera != null else Vector3.ZERO
	var nearest := rooms.duplicate()
	nearest.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	var per_room := GameConfig.SHAFTS_PER_ROOM
	var wanted: Array[Dictionary] = []
	for room: Node3D in nearest:
		var size: Vector3 = room.get_meta("room_size")
		# Beside the middle door (the beams come through the glass, not the door).
		var spots: Array = [-size.x * 0.25] if per_room == 1 else [-size.x * 0.25, size.x * 0.25]
		for x: float in spots:
			if wanted.size() < _pool.size():
				wanted.append({"room": room, "x": x})
	shafts.clear()
	for i in _pool.size():
		var view := _pool[i]
		view.visible = i < wanted.size()
		if not view.visible:
			continue
		var shaft := {"view": view, "room": wanted[i]["room"], "x": wanted[i]["x"]}
		if rebuild or view.get_meta("room", null) != shaft["room"] or view.get_meta("x", 0.0) != shaft["x"]:
			_build(shaft)
		shafts.append(shaft)
	_material.set_shader_parameter("strength", GameConfig.SHAFT_ALPHA * strength_at(hour))
	_material.set_shader_parameter("colour", sun.light_color.lerp(Color(1.0, 0.86, 0.62), 0.5))


## 0 to 1 from GameConfig.SHAFT_HOUR_KEYS ([hour, strength] pairs, blended in between).
static func strength_at(hour: float) -> float:
	var keys: Array = GameConfig.SHAFT_HOUR_KEYS
	if hour <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		if hour <= keys[i][0]:
			return lerpf(keys[i - 1][1], keys[i][1], smoothstep(keys[i - 1][0], keys[i][0], hour))
	return keys[keys.size() - 1][1]


## The direction the sunlight travels, in the room's own directions, always going into the
## room through the glass (+z side) and downwards, so every shop gets its beams.
func _light_in_room(room: Node3D) -> Vector3:
	var travel := -sun.global_basis.z.normalized()
	var local := room.global_basis.inverse() * travel
	local.z = -maxf(absf(local.z), 0.45)
	local.y = minf(local.y, -0.3)
	return local.normalized()


func _build(shaft: Dictionary) -> void:
	var room: Node3D = shaft["room"]
	var view: MeshInstance3D = shaft["view"]
	view.global_transform = room.global_transform
	var size: Vector3 = room.get_meta("room_size")
	var half := size * 0.5
	var travel := _light_in_room(room)
	var x: float = shaft["x"]
	var w := GameConfig.SHAFT_WIDTH * 0.5
	var z := half.z - GLASS_IN
	# The beam's start: a rectangle on the inside of the glass.
	var start: Array[Vector3] = [Vector3(x - w, WINDOW_Y.x, z), Vector3(x + w, WINDOW_Y.x, z),
			Vector3(x + w, WINDOW_Y.y, z), Vector3(x - w, WINDOW_Y.y, z)]
	# Each edge of the beam goes on until it reaches the floor or a wall (or MAX_LENGTH), so
	# every corner stays inside the room.
	var low := Vector3(-half.x + MARGIN, MARGIN, -half.z + MARGIN)
	var high := Vector3(half.x - MARGIN, size.y - MARGIN, half.z - MARGIN)
	var end: Array[Vector3] = []
	for corner in start:
		end.append(corner + travel * minf(MAX_LENGTH, _room_exit(corner, travel, low, high)))
	view.mesh = _prism(start, end)
	view.set_meta("corners", start + end)
	view.set_meta("room", room)
	view.set_meta("x", x)


## How far you can go from `from` along `dir` before leaving the box low..high.
static func _room_exit(from: Vector3, dir: Vector3, low: Vector3, high: Vector3) -> float:
	var best := INF
	for axis in 3:
		if dir[axis] > 0.0001:
			best = minf(best, (high[axis] - from[axis]) / dir[axis])
		elif dir[axis] < -0.0001:
			best = minf(best, (low[axis] - from[axis]) / dir[axis])
	return maxf(best, 0.0)


## The 4 sides of the beam (open at both ends). UV.x across a side, UV.y along the beam.
static func _prism(start: Array[Vector3], end: Array[Vector3]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var j := (i + 1) % 4
		var quad := [start[i], start[j], end[j], end[i]]
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		var normal := (start[j] - start[i]).cross(end[i] - start[i]).normalized()
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(normal)
			st.set_uv(uvs[k])
			st.add_vertex(quad[k])
	return st.commit()
