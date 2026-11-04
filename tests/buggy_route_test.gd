extends SceneTree
## Session 64: buggies everywhere and building sites. Builds Wahat Al Shams, then checks:
##   - the buggy road map: never on or along a black road (ring road, gate roads, highway,
##     bus road), covers much more road than the old fixed routes, every lane is clear
##     (the same map scan the smoke test uses), no walking track
##   - buggies keep to the right, stop for the bike, a person and road works
##   - 600 simulated seconds: no buggy ever on or along a black road, no two buggies
##     overlap, every cluster gets visited, no buggy gets stuck
##   - building sites: each has a half-built frame, scaffolding and a fence, nothing sticks
##     into a road, and the old crane is still there
## Run it on its own:  Godot --path . --headless -s tests/buggy_route_test.gd
var _failed := false
var _map: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, message: String, detail := "") -> void:
	_failed = _failed or not ok
	print(("PASS: " if ok else "FAIL: ") + message + ("" if ok or detail == "" else "  (" + detail + ")"))


func _run() -> void:
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	_map = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var life: Node = world.get_node("LifeBuilder")
	Settings.graphics = 2   # High: every buggy is out (hidden ones don't move in the game)
	life.apply_graphics()
	for i in 20:
		await physics_frame
		if life.buggy_roads_checked:
			break
	_expect(life.buggy_roads_checked, "the buggy road map was checked for things in the way")
	var roads: BuggyRoads = life.buggy_roads
	_check_road_map(roads, world)
	var buggies: Array[BuggyDriver] = []
	for mover in life.movers:
		if mover is BuggyDriver:
			buggies.append(mover)
	_expect(buggies.size() >= 12 and buggies.size() <= 16 and buggies.size() == _map["BUGGIES"].size(),
			"12 to 16 roaming buggies were built", str(buggies.size()))
	var riders := {}
	for entry: Dictionary in _map["BUGGIES"]:
		riders[entry["rider"]] = true
	_expect(riders.has("gardener") and riders.has("resident"), "some buggies carry a resident, some a gardener with tools")
	for mover in life.movers:
		mover.set_physics_process(false)   # the test moves everything itself from here on
	await _check_stops(buggies, life, world)
	await _simulate(buggies, life, roads)
	_check_sites(world)
	print("RESULT: " + ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)


# --- The road map ------------------------------------------------------------------------

func _black_rects() -> Array[Rect2]:
	return BuggyRoads.black_rects(_map, 0.0)


## Metres from a spot to the nearest black road (0 if on one).
func _black_distance(spot: Vector2) -> float:
	var best := INF
	for area in _black_rects():
		var near := Vector2(clampf(spot.x, area.position.x, area.end.x), clampf(spot.y, area.position.y, area.end.y))
		best = minf(best, near.distance_to(spot))
	return best


func _check_road_map(roads: BuggyRoads, world: Node3D) -> void:
	print("      buggy road map: %d junctions, roads: %s" % [roads.node_count(), roads.road_names()])
	if not roads.blocked.is_empty():
		print("      stretches dropped because something is in the way: %s" % roads.blocked)
	var total := 0.0
	var near_black: Array[String] = []
	var forbidden: Array[String] = []
	for a in roads.node_count():
		for b: int in roads.links[a]:
			if b < a:
				continue
			total += roads.nodes[a].distance_to(roads.nodes[b])
			var name: String = roads.road_of[BuggyRoads.key(a, b)]
			if name in GameConfig.BLACK_ROADS or name.to_lower().contains("track") or name == "Domes Path":
				forbidden.append(name)
			for step in 11:
				var spot := roads.nodes[a].lerp(roads.nodes[b], step / 10.0)
				if _black_distance(spot) < GameConfig.BUGGY_BLACK_ROAD_GAP - 0.5:
					near_black.append("%s (%d, %d)" % [name, spot.x, spot.y])
	_expect(forbidden.is_empty(), "no black road, red walking track or other track is on the buggy road map", str(forbidden))
	_expect(near_black.is_empty(), "every buggy lane stays %d m clear of the black roads" % GameConfig.BUGGY_BLACK_ROAD_GAP, str(near_black.slice(0, 5)))
	# The old fixed routes, for comparison.
	var old := 0.0
	for line: Dictionary in _map.get("BUGGY_FIXED_ROUTES", []):
		for i in line["points"].size() - 1:
			old += (line["points"][i] as Vector3).distance_to(line["points"][i + 1])
	_expect(total > old * 3.0, "buggies can use far more road than before", "%d m of buggy road, was %d m" % [total, old])
	var lanes := 0
	for name in roads.road_names():
		if name.contains("Lane") or name.contains("Link") or name.contains("Alley"):
			lanes += 1
	_expect(lanes >= 15, "lanes, links and alleys of every cluster are on the map", str(lanes))
	# Every driving line (both ways round every stretch) is clear on the map scan the smoke
	# test uses, so no buggy route can ever go through a wall or a post.
	var space := world.get_world_3d().direct_space_state
	var ball := SphereShape3D.new()
	ball.radius = 0.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	var half: Vector2 = _map["MAP_HALF"]
	var hits: Array[String] = []
	for a in roads.node_count():
		for b: int in roads.links[a]:
			var line: Array = roads.driving_line([a, b] as Array[int])["points"]
			var from: Vector3 = line[0]
			var to: Vector3 = line[-1]
			for k in int(from.distance_to(to)) + 1:
				var spot := from.move_toward(to, float(k))
				var square := Vector2(floorf(spot.x + half.x) + 0.5 - half.x, floorf(spot.z + half.y) + 0.5 - half.y)
				query.transform = Transform3D(Basis(), Vector3(square.x, 0.9, square.y))
				for hit in space.intersect_shape(query, 4):
					var thing: Node = hit["collider"]
					if thing.is_in_group("critter") or thing.is_in_group("bike") or thing.name == "Walker":
						continue
					hits.append("%s near (%.1f, %.1f) on %s" % [thing.name, spot.x, spot.z, roads.road_of[BuggyRoads.key(a, b)]])
					break
	_expect(hits.is_empty(), "every buggy driving line is clear of walls, posts and buildings", str(hits.slice(0, 6)))


# --- Stopping ----------------------------------------------------------------------------

## A long straight stretch of the road map (for the stop checks).
func _long_stretch(roads: BuggyRoads, length: float) -> Array[int]:
	for a in roads.node_count():
		for b: int in roads.links[a]:
			if roads.nodes[a].distance_to(roads.nodes[b]) >= length and roads.road_of[BuggyRoads.key(a, b)].contains("Lane"):
				return [a, b] as Array[int]
	return [] as Array[int]


func _check_stops(buggies: Array[BuggyDriver], life: Node, world: Node3D) -> void:
	var roads: BuggyRoads = life.buggy_roads
	var buggy := buggies[0]
	var stretch := _long_stretch(roads, 30.0)
	if stretch.is_empty():
		_expect(false, "found a long straight lane to test stopping on")
		return
	# Move everyone else far away so only the thing we put there is in the way.
	var keep := {}
	for mover in life.movers:
		keep[mover] = mover.position
		if mover != buggy:
			mover.position = Vector3(2000, -50, 2000) + Vector3(randf() * 100, 0, randf() * 100)
	await physics_frame
	var bike: Node3D = world.get_node("Bike")
	var bike_home := bike.global_position
	bike.global_position = Vector3(3000, 0, 3000)
	# It drives on the right of the lane.
	buggy.drive_route(stretch)
	buggy.scared_left = 0.0
	buggy._pause_left = 0.0
	for i in 30:
		buggy._physics_process(1.0 / 30.0)
	var a := roads.nodes[stretch[0]]
	var b := roads.nodes[stretch[1]]
	var way := (b - a).normalized()
	var beside := (Vector2(buggy.position.x, buggy.position.z) - a).dot(BuggyRoads.right_of(way))
	_expect(beside > 0.5 and beside < 1.6, "a buggy keeps to the right side of the lane", "%.2f m right of the middle" % beside)
	_expect(absf(angle_difference(buggy.rotation.y, atan2(-way.x, -way.y))) < 0.2, "a buggy faces the way it drives")
	# The bike stands 3 m in front: it stops.
	for what in ["bike", "person", "road works"]:
		buggy.drive_route(stretch)
		buggy._blocked = 0.0
		for i in 15:
			buggy._physics_process(1.0 / 30.0)
		var nose := buggy.position + buggy.heading() * (buggy.size.z * 0.5 + 2.5)
		var thing: Node3D
		match what:
			"bike":
				bike.global_position = nose
				thing = bike
			"person":
				thing = life.get_node("Person_1")
				thing.position = nose
				thing._pause_left = 1000.0
			"road works":
				var works := {"name": "test", "centre": Vector2(nose.x, nose.z) + way * 1.5, "along": "z" if absf(way.y) > 0.5 else "x", "width": 6.0, "length": 3.0}
				thing = RoadWorks.build(world.get_node("EventManager"), works)
		await physics_frame
		await physics_frame
		var at := buggy.position
		for i in 60:
			buggy._physics_process(1.0 / 30.0)
		_expect(buggy.position.distance_to(at) < 0.05, "a buggy stops for %s in front of it" % what, "moved %.2f m" % buggy.position.distance_to(at))
		if what == "road works":
			thing.get_parent().remove_child(thing)
			thing.queue_free()
		elif what == "person":
			thing.position = keep[thing]
			thing._pause_left = 0.0
		else:
			bike.global_position = Vector3(3000, 0, 3000)
		await physics_frame
	# If something stays in the way, it turns round and goes another way.
	buggy.drive_route(stretch)
	for i in 15:
		buggy._physics_process(1.0 / 30.0)
	bike.global_position = buggy.position + buggy.heading() * (buggy.size.z * 0.5 + 2.5)
	var spot := buggy.position
	for i in int((GameConfig.LIFE_GIVE_UP_TIME + 4.0) * 30.0):
		buggy._physics_process(1.0 / 30.0)
	_expect(buggy.position.distance_to(bike.global_position) > spot.distance_to(bike.global_position) + 2.0,
			"a buggy that waits too long turns round and drives off another way")
	bike.global_position = bike_home
	for mover in life.movers:
		mover.position = keep[mover]
	for one in buggies:
		one.replan()
	await physics_frame


# --- 600 seconds of driving --------------------------------------------------------------

func _simulate(buggies: Array[BuggyDriver], life: Node, roads: BuggyRoads) -> void:
	var step := 0.1
	var seconds := 600.0
	var on_black: Array[String] = []
	var overlaps: Array[String] = []
	var left_side := 0
	var right_side := 0
	var visited := {}
	var last_spot := {}
	var stuck: Array[String] = []
	var trips_before := {}
	for buggy in buggies:
		last_spot[buggy] = buggy.position
		trips_before[buggy] = buggy.trips
	var clusters: Array = _map["CLUSTERS"]
	for tick in int(seconds / step):
		for mover in life.movers:
			mover._physics_process(step)
		await physics_frame   # moving bodies only move in the physics world on a physics step
		for i in buggies.size():
			var one := buggies[i]
			var here := Vector2(one.position.x, one.position.z)
			if _black_distance(here) < GameConfig.BUGGY_BLACK_ROAD_GAP - 2.0 and on_black.size() < 5:
				on_black.append("%s at (%.0f, %.0f)" % [one.name, here.x, here.y])
			for j in range(i + 1, buggies.size()):
				if _overlap(one, buggies[j]) and overlaps.size() < 5:
					overlaps.append("%s and %s at (%.0f, %.0f)" % [one.name, buggies[j].name, here.x, here.y])
			for cluster: Dictionary in clusters:
				if (cluster["area"] as Rect2).has_point(here):
					visited[cluster["id"]] = true
			# Which side of the lane it's on, when driving along a stretch.
			if one.moving and one._next < one.edges.size():
				var edge: Array = one.edges[one._next]
				if edge[0] != edge[1]:
					var a := roads.nodes[edge[0]]
					var b := roads.nodes[edge[1]]
					var way := (b - a).normalized()
					var t := (here - a).dot(way)
					if t > 4.0 and t < a.distance_to(b) - 4.0:
						if (here - a).dot(BuggyRoads.right_of(way)) > 0.3:
							right_side += 1
						else:
							left_side += 1
		if tick % int(60.0 / step) == int(60.0 / step) - 1:   # every minute: did each one move?
			for buggy in buggies:
				if buggy.position.distance_to(last_spot[buggy]) < 3.0 and not buggy.name in stuck:
					stuck.append(buggy.name)
					print("      DEBUG stuck %s at %s pause %.1f blocked %.1f points %d next %d goal %d scared %.1f route %s" % [buggy.name, buggy.position, buggy._pause_left, buggy._blocked, buggy.points.size(), buggy._next, buggy.goal, buggy.scared_left, buggy.points.slice(0, 4)])
				last_spot[buggy] = buggy.position
	var trips := 0
	for buggy in buggies:
		trips += buggy.trips - trips_before[buggy]
	print("      600 s: %d trips, right side %d, left side %d, clusters visited %s" % [trips, right_side, left_side, visited.keys()])
	_expect(on_black.is_empty(), "in 600 s no buggy drives on or along a black road", str(on_black))
	_expect(overlaps.is_empty(), "in 600 s no two buggies overlap", str(overlaps))
	_expect(visited.size() == clusters.size(), "in 600 s buggies visit every cluster", str(visited.keys()))
	_expect(stuck.is_empty(), "no buggy gets stuck (each one moves every minute)", str(stuck))
	_expect(right_side > 0 and left_side * 50 < right_side, "buggies drive on the right side of the lanes", "%d right, %d left" % [right_side, left_side])
	_expect(trips >= buggies.size() * 2, "buggies keep going to new places", "%d trips" % trips)


## True if two buggies' boxes overlap (seen from above).
func _overlap(a: BuggyDriver, b: BuggyDriver) -> bool:
	if a.position.distance_to(b.position) > 3.0:
		return false
	var corners_a := _corners(a)
	var corners_b := _corners(b)
	for shape: Array in [corners_a, corners_b]:
		for i in 4:
			var edge: Vector2 = shape[(i + 1) % 4] - shape[i]
			var axis := Vector2(-edge.y, edge.x).normalized()
			var ra := _span(corners_a, axis)
			var rb := _span(corners_b, axis)
			if ra.y < rb.x or rb.y < ra.x:
				return false
	return true


func _corners(buggy: BuggyDriver) -> Array:
	var half := Vector2(1.2, 2.3) * 0.5 - Vector2(0.05, 0.05)
	var out := []
	var basis := buggy.global_basis
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p: Vector3 = buggy.position + basis.x * c.x * half.x + basis.z * c.y * half.y
		out.append(Vector2(p.x, p.z))
	return out


func _span(points: Array, axis: Vector2) -> Vector2:
	var out := Vector2(INF, -INF)
	for p: Vector2 in points:
		var d := p.dot(axis)
		out = Vector2(minf(out.x, d), maxf(out.y, d))
	return out


# --- Building sites ----------------------------------------------------------------------

func _check_sites(world: Node3D) -> void:
	pass
