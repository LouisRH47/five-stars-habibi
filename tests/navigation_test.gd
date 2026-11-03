extends SceneTree
## Shared routing uses actual colliders and local roadworks refreshes, with no save writes.
var failed := false
var state: Node


class FakeDelivery extends Node:
	var actor: Node3D
	var bike: Node3D
	var place_builder: Node
	func target_door() -> Vector3:
		return Vector3(6, 0, 0)


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
	print("PASS: " if ok else "FAIL: ", message)


func _block(parent: Node3D, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body


func _run() -> void:
	state = root.get_node("GameState")
	state.save_path = "user://navigation_test.json"
	state.reset()
	var world := Node3D.new()
	root.add_child(world)
	_block(world, Vector3(0, -0.5, 0), Vector3(60, 1, 60))
	await physics_frame
	await physics_frame
	var navigation = load("res://scripts/navigation_grid.gd")
	var grid = navigation.cached(world.get_world_3d(), Vector2(12, 12))
	var same = navigation.cached(world.get_world_3d(), Vector2(12, 12))
	_expect(grid == same and grid.builds == 1, "navigation scans a cached world grid once")
	var open: Array[Vector2] = grid.path(Vector2(-6, 0), Vector2(6, 0))
	_expect(open.size() == 2, "an open lane has a direct route")
	var barrier := _block(world, Vector3(0, 0.75, 0), Vector3(1, 1.5, 8))
	await physics_frame
	await physics_frame
	grid.refresh_region(world.get_world_3d(), Rect2(-3, -7, 6, 14))
	var detour: Array[Vector2] = grid.path(Vector2(-6, 0), Vector2(6, 0))
	_expect(detour.size() > 2 and grid.builds == 1 and grid.region_refreshes == 1, "new roadworks produce a detour without rescanning the map")
	var clear := true
	for index in detour.size() - 1:
		var a := detour[index]
		var b := detour[index + 1]
		var shape := SphereShape3D.new()
		shape.radius = 0.45
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = Vector3(a.x, 0.9, a.y)
		query.motion = Vector3(b.x - a.x, 0, b.y - a.y)
		var hit: PackedFloat32Array = world.get_world_3d().direct_space_state.cast_motion(query)
		if not hit.is_empty() and hit[0] < 0.999:
			clear = false
	_expect(clear, "smoothed route segments have physical bike clearance around barriers")
	barrier.queue_free()
	await physics_frame
	await physics_frame
	grid.refresh_region(world.get_world_3d(), Rect2(-3, -7, 6, 14))
	_expect(grid.path(Vector2(-6, 0), Vector2(6, 0)).size() == 2 and grid.region_refreshes == 2, "ending roadworks restores the direct lane using a local refresh")
	var places := PlaceBuilder.new()
	places.villas = [{"number": 101, "position": Vector3(6, 0, 0)}]
	var rider := Node3D.new()
	rider.position = Vector3(-6, 0, 0)
	world.add_child(rider)
	var dm := FakeDelivery.new()
	dm.actor = rider
	dm.bike = rider
	dm.place_builder = places
	world.add_child(dm)
	var gps = load("res://scripts/gps_route.gd").new()
	gps.delivery_manager = dm
	dm.add_child(gps)
	state.current_order = Order.new()
	state.stage = state.Stage.TO_RESTAURANT
	for frame in 6:
		await physics_frame
	_expect(gps.points.is_empty() and gps.grid == null, "GPS route stays locked before the GPS purchase")
	state.upgrade_levels["gps"] = 1
	for frame in 70:
		await physics_frame
	_expect(not gps.points.is_empty() and gps.get_node("GroundRoute").mesh != null, "purchased GPS draws a collision-safe glowing ground route")
	var builds: int = gps.grid.builds
	rider.position = Vector3(-2, 0, 0)
	for frame in 40:
		await physics_frame
	_expect(gps.replans >= 2 and gps.grid.builds == builds, "riding updates GPS while reusing the scanned map")
	state.stage = state.Stage.NONE
	await physics_frame
	await physics_frame
	state.stage = state.Stage.TO_RESTAURANT
	for frame in 40:
		await physics_frame
	_expect(not gps.points.is_empty(), "a later order rebuilds the route even at the same stop and position")
	# Use the production HeightMapShape3D hill generator, not a flat stand-in box.
	var terrain = load("res://scripts/district_detail.gd").new()
	terrain._hill({"position": Vector3(0, 0, 9), "height": 1.2})
	var hill: Node3D = terrain.get_child(0)
	terrain.remove_child(hill)
	world.add_child(hill)
	terrain.free()
	var moving := _block(world, Vector3(0, 2.0, 9), Vector3(1, 1, 1))
	moving.add_to_group("critter")
	_block(world, Vector3(6, 8, 0), Vector3(4, 0.5, 4))
	await physics_frame
	await physics_frame
	var hill_height: float = gps._ground_height(Vector2(0, 9))
	_expect(absf(hill_height - (1.2 + GameConfig.GPS_LINE_HEIGHT)) < 0.02, "GPS ground ribbon samples the actual 1.2m hill while ignoring a moving actor above it")
	_expect(absf(gps._ground_height(Vector2(6, 0)) - GameConfig.GPS_LINE_HEIGHT) < 0.02, "GPS height ray stays below an indoor venue roof")
	world.queue_free()
	places.free()
	await process_frame
	print("RESULT: ", "FAIL" if failed else "PASS", " shared navigation and GPS")
	quit(1 if failed else 0)
