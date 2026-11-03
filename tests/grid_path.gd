extends RefCounted
## Finds bike routes on any map (Session 25), for the smoke test and the play-test bot.
## It lays a grid over the map (1 m squares), asks the physics engine which squares have
## something solid at bike height (walls, houses, palms, bollards, parked cars...), and
## then uses Godot's AStarGrid2D to find a way between two spots. Moving things (the bike,
## the walker, cats, kids) are ignored. path() returns the corners of a smoothed route.

## How big each square is, in metres.
var cell := 1.0
## How far round the bike needs to be clear (half its width plus a little).
var clearance := 0.5
## How many squares the last scan found blocked (0 means the physics world wasn't ready).
var solid_count := 0
## Keep away from walls (play-test bot): squares closer than keep_away to something solid
## cost up to (1 + wall_cost) times more to ride through, so routes run down the middle
## of lanes, and smoothing never cuts closer to a wall than the route already was.
## 0 = off (plain shortest route, the smoke test uses that).
var wall_cost := 0.0
var keep_away := 3

var _astar := AStarGrid2D.new()
var _origin := Vector2.ZERO
var _size := Vector2i.ZERO
var _dist := PackedInt32Array()  # squares to the nearest solid square (capped at keep_away + 1)


## Scans the map. world: the 3D world. half: half the map size (x, z). ignore: bodies to skip.
func build(world: World3D, half: Vector2, ignore: Array = []) -> void:
	_origin = -half
	_size = Vector2i(ceili(half.x * 2.0 / cell), ceili(half.y * 2.0 / cell))
	_astar.region = Rect2i(Vector2i.ZERO, _size)
	_astar.cell_size = Vector2(cell, cell)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	solid_count = 0
	var space := world.direct_space_state
	var ball := SphereShape3D.new()
	ball.radius = clearance
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	query.collide_with_areas = false
	var skip: Array[RID] = []
	for body in ignore:
		if body is CollisionObject3D:
			skip.append((body as CollisionObject3D).get_rid())
	query.exclude = skip
	for x in _size.x:
		for y in _size.y:
			var spot := _world(Vector2i(x, y))
			# High enough that the ball never touches the ground, low enough to catch bollards.
			query.transform = Transform3D(Basis(), Vector3(spot.x, maxf(0.9, clearance + 0.12), spot.y))
			for hit in space.intersect_shape(query, 4):
				var thing: Object = hit["collider"]
				if thing is Node and ((thing as Node).is_in_group("critter") or (thing as Node).is_in_group("bike") or (thing as Node).name == "Walker"):
					continue
				_astar.set_point_solid(Vector2i(x, y), true)
				solid_count += 1
				break
	_measure_wall_distance()


## For every square, how many squares away the nearest solid one is (a flood fill
## outwards from all solid squares), then makes squares near walls cost more.
func _measure_wall_distance() -> void:
	var cap := keep_away + 1
	_dist = PackedInt32Array()
	_dist.resize(_size.x * _size.y)
	_dist.fill(cap)
	if wall_cost <= 0.0:
		return
	var front: Array[Vector2i] = []
	for x in _size.x:
		for y in _size.y:
			if _astar.is_point_solid(Vector2i(x, y)):
				_dist[x * _size.y + y] = 0
				front.append(Vector2i(x, y))
	for d in range(1, cap):
		var next: Array[Vector2i] = []
		for square in front:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var near := square + Vector2i(dx, dy)
					if near.x < 0 or near.y < 0 or near.x >= _size.x or near.y >= _size.y:
						continue
					var i := near.x * _size.y + near.y
					if _dist[i] > d:
						_dist[i] = d
						next.append(near)
		front = next
	for x in _size.x:
		for y in _size.y:
			var d := _dist[x * _size.y + y]
			if d > 0 and d < cap:
				_astar.set_point_weight_scale(Vector2i(x, y), 1.0 + wall_cost * float(cap - d) / float(keep_away))


## Squares from this spot (x, z) to the nearest solid square (keep_away + 1 if far away).
func wall_distance(spot: Vector2) -> int:
	var square := _square(spot)
	if not _astar.is_in_boundsv(square) or _dist.is_empty():
		return 0
	return _dist[square.x * _size.y + square.y]


## True if the square at this spot (x, z) is free for the bike.
func is_free(spot: Vector2) -> bool:
	var square := _square(spot)
	return _astar.is_in_boundsv(square) and not _astar.is_point_solid(square)


## The corners of a route from one spot to another (x, z), or [] if there's no way.
## Starts or ends inside something solid are moved to the nearest free square.
func path(from: Vector2, to: Vector2) -> Array[Vector2]:
	var a := _nearest_free(_square(from))
	var b := _nearest_free(_square(to))
	var route: Array[Vector2] = []
	if a.x < 0 or b.x < 0:
		return route
	var squares := _astar.get_id_path(a, b)
	if squares.is_empty():
		return route
	var points: Array[Vector2] = []
	for square in squares:
		points.append(_world(square))
	return _smooth(points)


## Skips every point you can see past: from each corner, go straight to the furthest point
## with nothing solid in between.
func _smooth(points: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = [points[0]]
	var i := 0
	while i < points.size() - 1:
		var j := points.size() - 1
		while j > i + 1 and not _clear(points[i], points[j]):
			j -= 1
		out.append(points[j])
		i = j
	return out


func _clear(a: Vector2, b: Vector2) -> bool:
	var need := 0
	if wall_cost > 0.0:
		need = mini(mini(wall_distance(a), wall_distance(b)), keep_away)
	var steps := ceili(a.distance_to(b) / (cell * 0.5))
	for k in steps + 1:
		var spot := a.lerp(b, float(k) / maxf(steps, 1))
		if not is_free(spot) or (need > 0 and wall_distance(spot) < need):
			return false
	return true


func _nearest_free(square: Vector2i) -> Vector2i:
	for r in 6:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var near := square + Vector2i(dx, dy)
				if _astar.is_in_boundsv(near) and not _astar.is_point_solid(near):
					return near
	return Vector2i(-1, -1)


func _square(spot: Vector2) -> Vector2i:
	return Vector2i(floori((spot.x - _origin.x) / cell), floori((spot.y - _origin.y) / cell))


func _world(square: Vector2i) -> Vector2:
	return _origin + (Vector2(square) + Vector2(0.5, 0.5)) * cell
