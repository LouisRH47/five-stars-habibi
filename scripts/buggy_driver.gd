class_name BuggyDriver
extends RouteMover
## Session 64: a golf buggy that drives all over the community instead of up and down one
## fixed route. It picks a random place on the buggy road map (scripts/buggy_roads.gd: the
## cluster lanes, the spine buggy road, car park buggy lanes... never the black car roads),
## drives there keeping to the right, slows down for corners, waits a few seconds, then
## picks the next place. Like every RouteMover it stops when the bike, the rider on foot,
## a person, another buggy or road works are just ahead; if they stay in the way it turns
## round and finds another way (not back through the same stretch).
## LifeBuilder makes these from the BUGGIES list. Some carry a resident (or two), some a
## gardener with tools in the back.

## The road map it drives on (shared by every buggy).
var roads: BuggyRoads
## Where the data says it starts.
var start_spot := Vector3.ZERO
## Its own cruising speed (m/s); it goes slower in corners.
var cruise := 3.3
## For each point of its route, the road map edge [from node, to node] it's on.
var edges: Array = []
## The node it's driving to.
var goal := -1
## How many places it has got to (the tests count these).
var trips := 0
## A second person sitting next to the driver, or null.
var passenger: Person

var _rng := RandomNumberGenerator.new()


## Makes the buggy's look for one line of the BUGGIES data: [model, driver].
## rider: "resident" (one person), "pair" (two) or "gardener" (with tools in the back).
static func look(entry: Dictionary) -> Array:
	var made := LifeLooks.buggy(entry["colour"])
	var model: Node3D = made[0]
	var driver: Person = made[1]
	match String(entry.get("rider", "resident")):
		"gardener":
			model.remove_child(driver)
			driver.free()
			driver = Person.new()
			driver.paint({"skin": PeopleLooks.SKINS.pick_random(), "shirt": Color(0.3, 0.5, 0.3), "pants": Color(0.35, 0.3, 0.25)})
			PeopleLooks.cap(driver, Color(0.9, 0.85, 0.7), driver)
			LifeLooks._sit(driver, model, Vector3(-0.28, 0.9, 0.3), [Vector3(-0.38, 0.75, -0.45), Vector3(-0.18, 0.75, -0.45)],
					[Vector3(-0.42, 1.18, -0.45), Vector3(-0.14, 1.18, -0.45)], 5.0)
			_tools(model)
		"pair":
			var friend := PeopleLooks.resident(randi() % PeopleLooks.RESIDENT_OUTFITS)
			friend.name = "Passenger"
			LifeLooks._sit(friend, model, Vector3(0.28, 0.9, 0.3), [Vector3(0.18, 0.75, -0.45), Vector3(0.38, 0.75, -0.45)],
					[Vector3(0.14, 1.0, 0.0), Vector3(0.42, 1.0, 0.0)], 2.0)
	return [model, driver]


## Gardening things on the little tray at the back: a green bin, a rake and a spade.
static func _tools(model: Node3D) -> void:
	var kit := MeshKit.new()
	kit.box(Vector3(1.1, 0.06, 0.5), LifeLooks.DARK, Vector3(0, 0.76, 0.92))          # the tray
	kit.box(Vector3(0.42, 0.5, 0.4), Color(0.2, 0.45, 0.25), Vector3(0.28, 1.04, 0.92))  # a green bin
	kit.box(Vector3(0.4, 0.3, 0.38), Color(0.55, 0.42, 0.25), Vector3(-0.25, 0.94, 0.95))  # a sack of soil
	var lean := Basis(Vector3.RIGHT, -0.35)
	kit.cylinder(0.02, 0.02, 1.5, Color(0.6, 0.45, 0.25), Vector3(-0.05, 1.35, 0.85), lean)  # rake handle
	kit.box(Vector3(0.4, 0.05, 0.06), Color(0.4, 0.4, 0.42), Vector3(-0.05, 2.03, 0.6))     # rake head
	kit.cylinder(0.02, 0.02, 1.3, Color(0.6, 0.45, 0.25), Vector3(0.08, 1.3, 0.88), lean)   # spade handle
	kit.box(Vector3(0.2, 0.25, 0.03), Color(0.45, 0.45, 0.48), Vector3(0.08, 0.82, 1.05))   # spade blade
	model.add_child(kit.finish())


func setup(what: String, route: Array, is_loop: bool, move_speed: float, body: Vector3,
		look_node: Node3D, rider: Person = null) -> void:
	_rng.seed = hash(name)
	cruise = move_speed
	passenger = look_node.get_node_or_null("Passenger") as Person
	if roads != null:
		roads.drivers.append(self)
	super.setup(what, route, is_loop, move_speed, body, look_node, rider)
	look_ahead = GameConfig.BUGGY_LOOK_AHEAD
	(_ahead.shape as BoxShape3D).size.z = look_ahead


## Buggies always drive forwards along their route.
func start_at(segment: int, along: float, _forwards: bool) -> void:
	super.start_at(segment, along, true)


## Drives along these nodes of the road map (the tests use it to set up a known drive).
func drive_route(route: Array[int]) -> void:
	if roads == null or route.is_empty():
		return
	var line := roads.driving_line(route)
	points.assign(line["points"])
	edges = line["edges"]
	goal = route[-1]
	if points.size() < 2:
		points.append(points[0])
		edges.append(edges[0])
	start_at(0, 0.0, true)


## Picks a new place to go from where it is now (after the road map was checked).
func replan() -> void:
	if roads == null or roads.node_count() == 0:
		return
	var here := Vector2(position.x, position.z)
	var near := roads.nearest_node(here)
	var came := Vector2(-sin(rotation.y), -cos(rotation.y))
	_plan_from(near, came if roads.nodes[near].distance_to(here) > 1.0 else Vector2.ZERO)


## True if the bike, the rider, a person, road works (see RouteMover) or another buggy is
## in the way. Other buggies: it checks where it will be over the next few metres of its
## route (round corners and U-turns too), so it never drives into the side of one.
func something_in_the_way(way: Vector3) -> bool:
	if super.something_in_the_way(way):
		return true
	return roads != null and _buggy_ahead()


func _buggy_ahead() -> bool:
	var reach := GameConfig.BUGGY_LOOK_AHEAD + 0.6
	for other: BuggyDriver in roads.drivers:
		if other == self or not is_instance_valid(other) or not other.is_inside_tree():
			continue
		if other.process_mode == Node.PROCESS_MODE_DISABLED or other.get_rid() in _ahead.exclude:
			continue   # hidden on this Graphics setting, or left out by a test
		if other.position.distance_squared_to(position) > (reach + 3.0) * (reach + 3.0):
			continue
		var theirs := _box(other.position, -other.global_basis.z, 0.05)
		var gone := 0.6
		while gone <= reach:
			var spot := _on_route(gone)
			if _boxes_touch(_box(spot[0], spot[1], 0.0), theirs):
				return true
			gone += 0.6
	return false


## Where it will be (and which way it will face) after driving `metres` more on its route.
func _on_route(metres: float) -> Array:
	var at := position
	var way := heading()
	for i in range(_next, points.size()):
		var gap := points[i] - at
		gap.y = 0.0
		if gap.length() > 0.001:
			way = gap.normalized()
		if gap.length() >= metres:
			return [at + way * metres, way]
		metres -= gap.length()
		at = points[i]
	return [at + way * metres, way]


## The 4 corners (x, z) of a buggy's footprint at `spot` facing `way`, grown by `grow`.
func _box(spot: Vector3, way: Vector3, grow: float) -> PackedVector2Array:
	var along := Vector2(way.x, way.z).normalized()
	var side := Vector2(-along.y, along.x)
	var half := Vector2(size.x * 0.5 - 0.05 + grow, size.z * 0.5 - 0.05 + grow)
	var middle := Vector2(spot.x, spot.z)
	return PackedVector2Array([middle + along * half.y + side * half.x, middle + along * half.y - side * half.x,
			middle - along * half.y - side * half.x, middle - along * half.y + side * half.x])


## True if two footprints overlap (separating axis test on the 4 edge directions).
static func _boxes_touch(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for shape: PackedVector2Array in [a, b]:
		for i in 2:
			var edge := shape[i + 1] - shape[i]
			var axis := Vector2(-edge.y, edge.x)
			var span_a := Vector2(INF, -INF)
			var span_b := Vector2(INF, -INF)
			for p in a:
				span_a = Vector2(minf(span_a.x, p.dot(axis)), maxf(span_a.y, p.dot(axis)))
			for p in b:
				span_b = Vector2(minf(span_b.x, p.dot(axis)), maxf(span_b.y, p.dot(axis)))
			if span_a.y < span_b.x or span_b.y < span_a.x:
				return false
	return true


## Far away: hide it and stop the people's animations (the passenger too).
func set_near(near: bool) -> void:
	super.set_near(near)
	if passenger != null:
		passenger.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED


func _start_somewhere() -> void:
	if roads == null or roads.node_count() == 0:
		super._start_somewhere()
		return
	var near := roads.nearest_node(Vector2(start_spot.x, start_spot.z))
	position = Vector3(roads.nodes[near].x, 0.0, roads.nodes[near].y)
	_plan_from(near, Vector2.ZERO)
	position = points[0]
	face(heading())


func _drive(delta: float) -> void:
	speed = cruise * _corner_share()
	super._drive(delta)


## Slower near corners (the sharper the corner, the slower) and when pulling up at the end.
func _corner_share() -> float:
	var gap := points[_next] - position
	gap.y = 0.0
	var dist := gap.length()
	if _next >= points.size() - 1:
		return clampf(dist / 4.0, 0.4, 1.0)
	var after := points[_next + 1] - points[_next]
	after.y = 0.0
	if dist < 0.001 or after.length() < 0.001:
		return 1.0
	var turn := gap.angle_to(after)
	var slowest := lerpf(1.0, GameConfig.BUGGY_CORNER_SLOW, clampf(turn / 1.6, 0.0, 1.0))
	return lerpf(slowest, 1.0, clampf((dist - 1.0) / 6.0, 0.0, 1.0))


## Got to a point: on to the next one, or (at the end) wait a moment and pick a new place.
func _arrive() -> void:
	if roads == null:
		super._arrive()
		return
	if _next < points.size() - 1:
		_next += 1
		return
	trips += 1
	_pause_left = _rng.randf_range(GameConfig.BUGGY_STOP_TIME.x, GameConfig.BUGGY_STOP_TIME.y)
	var came := Vector2.ZERO
	if points.size() >= 2:
		var last := points[-1] - points[-2]
		came = Vector2(last.x, last.z).normalized()
	_plan_from(goal if goal >= 0 else roads.nearest_node(Vector2(position.x, position.z)), came)


## Something stayed in the way: turn round and find another way, not back through it.
func _turn_round() -> void:
	if roads == null or edges.is_empty():
		super._turn_round()
		return
	var edge: Array = edges[clampi(_next, 0, edges.size() - 1)]
	var from: int = edge[0]
	var to: int = edge[1]
	if from == to or from >= roads.node_count() or to >= roads.node_count():
		replan()
		return
	var back := (roads.nodes[from] - roads.nodes[to]).normalized()
	var here := Vector2(position.x, position.z)
	var middle := Geometry2D.get_closest_point_to_segment(here, roads.nodes[from], roads.nodes[to])
	var keep: float = roads.keep_of.get(BuggyRoads.key(from, to), GameConfig.BUGGY_KEEP_RIGHT)
	var across := middle + BuggyRoads.right_of(back) * keep
	_plan_from(from, back, [from, to], [Vector3(across.x, 0.0, across.y)], [[to, from]])


## Plans a trip from node `from` to a new random place. came: the way it was going when it
## got to `from`. avoid: an edge not to use. lead, lead_edges: points to drive first.
func _plan_from(from: int, came: Vector2, avoid: Array = [], lead: Array = [], lead_edges: Array = []) -> void:
	var route: Array[int] = []
	for attempt in 8:
		var target := _rng.randi() % roads.node_count()
		if target == from or roads.nodes[target].distance_to(roads.nodes[from]) < 25.0:
			continue
		route = roads.path(from, target, avoid)
		if route.size() >= 2:
			break
	if route.size() < 2:
		route = [from]
	var line := roads.driving_line(route, came)
	var new_points: Array[Vector3] = [position]
	var new_edges: Array = [line["edges"][0]]
	for i in lead.size():
		new_points.append(lead[i])
		new_edges.append(lead_edges[i])
	for i in line["points"].size():
		var spot: Vector3 = line["points"][i]
		if spot.distance_to(new_points[-1]) > 0.05:
			new_points.append(spot)
			new_edges.append(line["edges"][i])
	if new_points.size() < 2:
		new_points.append(position)
		new_edges.append(new_edges[0])
	points = new_points
	edges = new_edges
	goal = route[-1]
	_way = 1
	_next = 1
