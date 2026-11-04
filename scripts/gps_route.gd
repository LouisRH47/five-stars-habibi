class_name GPSRoute
extends Node3D
## The purchased GPS shares a cached collision grid with navigation checks. It draws a
## ground ribbon and publishes the same route to the mini-map. No upgrade, no route.
var delivery_manager: Node
var points: Array[Vector2] = []
var grid: NavigationGrid
var replans := 0
var _mesh: MeshInstance3D
var _left := 0.0
var _frames := 0
var _last_from := Vector2(INF, INF)
var _last_target := Vector2(INF, INF)
var _last_works_area := Rect2()
var _works_dirty := -1
var _events: Node


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "GroundRoute"
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_connect_events.call_deferred()


func _connect_events() -> void:
	_events = delivery_manager.get_parent().get_node_or_null("EventManager")
	if _events != null and _events.has_signal("road_works_changed"):
		_events.road_works_changed.connect(func(): _works_dirty = 2)


func _physics_process(delta: float) -> void:
	_frames += 1
	if _frames < 4:
		return  # static shapes must have entered the physics world first
	var enabled := GameState.upgrade_level("gps") > 0 and delivery_manager != null and GameState.current_order != null and GameState.stage in [GameState.Stage.TO_RESTAURANT, GameState.Stage.TO_VILLA]
	if not enabled:
		_last_from = Vector2(INF, INF)
		_last_target = Vector2(INF, INF)
		if not points.is_empty():
			points.clear()
			_mesh.mesh = null
		return
	var actor: Node3D = delivery_manager.actor
	if actor == null:
		return
	var ignore: Array = [delivery_manager.bike, actor]
	if grid == null:
		grid = NavigationGrid.cached(get_world_3d(), _map_half(), ignore, true, delivery_manager.place_builder)
		_last_works_area = _works_area()
	if not grid.scan_complete:
		grid.scan_next(get_world_3d(), ignore, GameConfig.GPS_SCAN_CELLS_PER_FRAME)
		return
	if _works_dirty >= 0:
		_works_dirty -= 1
		if _works_dirty < 0:
			var current := _works_area()
			var changed := current if _last_works_area.size == Vector2.ZERO else _last_works_area
			if current.size != Vector2.ZERO and _last_works_area.size != Vector2.ZERO:
				changed = changed.merge(current)
			if changed.size != Vector2.ZERO:
				grid.refresh_region(get_world_3d(), changed, ignore)
			_last_works_area = current
			_last_target = Vector2(INF, INF)
	_left -= delta
	if _left > 0.0:
		return
	_left = GameConfig.GPS_REPLAN_SECONDS
	var from := Vector2(actor.global_position.x, actor.global_position.z)
	var target3: Vector3 = delivery_manager.target_door()
	var target := Vector2(target3.x, target3.z)
	if from.distance_to(_last_from) < GameConfig.GPS_REPLAN_METRES and target.is_equal_approx(_last_target):
		return
	points = grid.path(from, target)
	_last_from = from
	_last_target = target
	replans += 1
	_draw_ground_route()


func _map_half() -> Vector2:
	var places: Node = delivery_manager.place_builder
	if places.data != null:
		var data: Dictionary = places.data.get_script_constant_map()
		if data.has("MAP_HALF"):
			return data["MAP_HALF"]
		if data.has("HALF_SIZE"):
			return Vector2.ONE * data["HALF_SIZE"]
	var half := Vector2(30, 30)
	for place in places.villas + places.restaurants:
		var spot: Vector3 = place["position"]
		half.x = maxf(half.x, absf(spot.x) + 20.0)
		half.y = maxf(half.y, absf(spot.z) + 20.0)
	return half


func _works_area() -> Rect2:
	if _events == null or _events.get("road_works") == null:
		return Rect2()
	var works: Node3D = _events.get("road_works")
	var centre := Vector2(works.global_position.x, works.global_position.z)
	for item in _events.road_works_places():
		if item["centre"].distance_to(centre) < 1.0:
			var size := Vector2(item["width"], item["length"])
			if item["along"] == "x":
				size = Vector2(size.y, size.x)
			return Rect2(centre - size * 0.5, size).grow(4.0)
	return Rect2(centre - Vector2(20, 20), Vector2(40, 40))


func _draw_ground_route() -> void:
	if points.size() < 2:
		_mesh.mesh = null
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.1, 0.95, 0.9, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for index in points.size() - 1:
		var from := points[index]
		var to := points[index + 1]
		var steps := maxi(1, ceili(from.distance_to(to) / GameConfig.GPS_GROUND_SAMPLE_METRES))
		for step in steps:
			var a := from.lerp(to, float(step) / steps)
			var b := from.lerp(to, float(step + 1) / steps)
			var along := (b - a).normalized()
			var side := Vector2(-along.y, along.x) * GameConfig.GPS_LINE_WIDTH * 0.5
			var a_height := _ground_height(a)
			var b_height := _ground_height(b)
			var corners := [Vector3(a.x + side.x, a_height, a.y + side.y), Vector3(a.x - side.x, a_height, a.y - side.y), Vector3(b.x - side.x, b_height, b.y - side.y), Vector3(b.x + side.x, b_height, b.y + side.y)]
			for vertex in [0, 1, 2, 0, 2, 3]:
				mesh.surface_add_vertex(corners[vertex])
	mesh.surface_end()
	_mesh.mesh = mesh


func _ground_height(spot: Vector2) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(spot.x, 6.0, spot.y), Vector3(spot.x, -3, spot.y), 1)
	var skip: Array[RID] = []
	var moving: Array = get_tree().get_nodes_in_group("critter")
	if delivery_manager != null:
		moving.append_array([delivery_manager.bike, delivery_manager.actor])
	for body in moving:
		if body is CollisionObject3D and not body.get_rid() in skip:
			skip.append(body.get_rid())
	query.exclude = skip
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return (float(hit["position"].y) if not hit.is_empty() else 0.0) + GameConfig.GPS_LINE_HEIGHT
