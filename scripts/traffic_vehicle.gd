class_name TrafficVehicle
extends AnimatableBody3D
## A car or bus on a fixed authored route. It waits for riders; it never chooses a road.

var points: Array[Vector3] = []
var watch: Array[Node3D] = []
var speed := 0.0
var moving := false
var kind := "car"
var stop_index := -1
var dwell_time := 0.0
var despawn_at_end := false
var loops := 0
var visits := 0
var size := Vector3(1.9, 1.7, 4.2)
var _next := 1
var _wait_left := 0.0
var _look: Node3D
var _ahead := PhysicsShapeQueryParameters3D.new()


func _init() -> void:
	sync_to_physics = false
	add_to_group("critter") # Navigation treats moving obstacles as temporary.
	add_to_group("traffic_vehicle")
	set_meta("impact_category", "vehicle")


func setup(route: Array, what: String, look: Node3D, body: Vector3, pace: float) -> void:
	for point: Vector3 in route:
		points.append(point)
	kind = what
	size = body
	speed = pace
	_look = look
	add_child(look)
	LowPoly.solid_box(self, size, Vector3.UP * size.y * 0.5)
	set_meta("impact_name", "a community bus" if kind == "bus" else "a moving car")
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x + 0.5, size.y * 0.8, GameConfig.TRAFFIC_STOP_DISTANCE)
	_ahead.shape = shape
	_ahead.exclude = [get_rid()]
	_ahead.collide_with_areas = false
	if not points.is_empty():
		position = points[0]
		_face(heading())


func heading() -> Vector3:
	if points.size() < 2:
		return -global_basis.z
	var gap := points[_next] - position
	return gap.normalized() if gap.length_squared() > 0.0001 else -global_basis.z


func start_at(index: int) -> void:
	if points.size() < 2:
		return
	index = posmod(index, points.size())
	position = points[index]
	_next = (index + 1) % points.size()
	_face(heading())


func _physics_process(delta: float) -> void:
	moving = false
	if _wait_left > 0.0:
		_wait_left = maxf(_wait_left - delta, 0.0)
		return
	if points.size() < 2 or something_in_the_way(heading()):
		return
	var direction := heading()
	var distance := position.distance_to(points[_next])
	var step := speed * delta
	_face(direction)
	moving = true
	if distance <= step:
		position = points[_next]
		if _next == stop_index:
			_wait_left = dwell_time
			visits += 1
		_next += 1
		if _next >= points.size():
			loops += 1
			if despawn_at_end:
				queue_free()
				return
			_next = 0
	else:
		position += direction * step


## Direct actor checks also work immediately after R or scripted teleportation.
func something_in_the_way(direction: Vector3) -> bool:
	for actor in watch:
		if not is_instance_valid(actor) or (not actor.visible and not actor.is_in_group("bike")):
			continue
		var gap := actor.global_position - global_position
		gap.y = 0.0
		var ahead := gap.dot(direction)
		var sideways := absf(gap.dot(Vector3(-direction.z, 0, direction.x)))
		if ahead > -0.5 and ahead < size.z * 0.5 + GameConfig.TRAFFIC_STOP_DISTANCE and sideways < size.x * 0.5 + 1.0:
			return true
	if not is_inside_tree():
		return false
	var centre := global_position + direction * (size.z * 0.5 + GameConfig.TRAFFIC_STOP_DISTANCE * 0.5)
	_ahead.transform = Transform3D(Basis.looking_at(direction), centre + Vector3.UP * size.y * 0.5)
	for hit in get_world_3d().direct_space_state.intersect_shape(_ahead, 8):
		var obstacle := hit["collider"] as Node
		if obstacle != null and (obstacle.is_in_group("critter") or obstacle.is_in_group("bike")):
			return true
	return false


func distance_to_route() -> float:
	var nearest := INF
	for i in points.size():
		var point := Geometry3D.get_closest_point_to_segment(position, points[i], points[(i + 1) % points.size()])
		nearest = minf(nearest, point.distance_to(position))
	return nearest


func _face(direction: Vector3) -> void:
	if direction.length_squared() > 0.0001:
		rotation.y = atan2(-direction.x, -direction.z)
