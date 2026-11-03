class_name RouteMover
extends Critter
## Something that follows its own fixed route from the data list (Session 30): golf buggies,
## horses with riders, joggers, walkers, kids at the playgrounds and ducks. A gardener is one
## with a single point (it stays put). There's no traffic AI: it just goes point to point.
## Back-and-forth routes turn round at each end, loops go round and round.
## It looks a little way ahead. If the bike, the rider on foot or another moving thing is
## there, it stops and waits (so it never pushes the parked bike). If you stay in the way
## for a while, it turns round and goes the other way.
## Bumping into one is like bumping a kid: a small knock to the food (scripts/critter.gd).
## LifeBuilder makes these and calls setup(). How each kind looks: scripts/life_looks.gd.

## "buggy", "horse", "person", "gardener" or "duck".
var kind := ""
## The route: the points it moves between (y = 0).
var points: Array[Vector3] = []
var loop := false
## Metres per second.
var speed := 1.0
## Its solid box: width, height, length.
var size := Vector3.ONE
## How far in front it looks for something in the way (metres).
var look_ahead := 2.0
## What you see. LifeBuilder hides it (and stops the person's animation) when far away.
var model: Node3D
## The person to animate (walkers, kids, drivers and riders), or null.
var person: Person
## True if it moved in the last physics frame (for the animations).
var moving := false
## The bike and the rider on foot (LifeBuilder fills it in). We look for these by where they
## are, not with physics, so a bike that was just moved (R, or the smoke test) counts at once.
var watch: Array[Node3D] = []

var _next := 1            # the point it's heading for
var _way := 1             # +1 forwards along the list, -1 backwards
var _pause_left := 0.0
var _blocked := 0.0       # seconds something has been in the way
var _clock := 0.0         # for the animations
var _ahead := PhysicsShapeQueryParameters3D.new()


## route: the points. is_loop: go round instead of back and forth. body: the solid box.
## look: the model (LifeLooks makes it). rider: the person to animate, if any.
func setup(what: String, route: Array, is_loop: bool, move_speed: float, body: Vector3,
		look: Node3D, rider: Person = null) -> void:
	kind = what
	for spot: Vector3 in route:
		points.append(Vector3(spot.x, 0.0, spot.z))
	loop = is_loop
	speed = move_speed
	size = body
	model = look
	person = rider
	look_ahead = clampf(body.z * 0.8, 0.8, 2.5)
	add_child(look)
	make_body(body)
	var box := BoxShape3D.new()
	box.size = Vector3(body.x + 0.1, body.y * 0.8, look_ahead)
	_ahead.shape = box
	_ahead.collide_with_areas = false
	_ahead.exclude = [get_rid()]
	_start_somewhere()


## Starts somewhere along the route (random), going a random way.
func start_at(segment: int, along: float, forwards: bool) -> void:
	if points.size() < 2:
		position = points[0]
		return
	var count := points.size() if loop else points.size() - 1
	segment = clampi(segment, 0, count - 1)
	var a := points[segment]
	var b := points[(segment + 1) % points.size()]
	position = a.lerp(b, along)
	_way = 1 if forwards or loop else -1
	_next = (segment + 1) % points.size() if _way == 1 else segment
	face(heading())
	if not forwards and loop:  # a loop the other way round
		_turn_round()


## Which way it's going (flat, length 1).
func heading() -> Vector3:
	if points.size() < 2:
		return -global_basis.z
	var gap := points[_next] - position
	gap.y = 0.0
	return gap.normalized() if gap.length() > 0.001 else -global_basis.z


## How far it is from the nearest bit of its route (the smoke test checks it stays on it).
func distance_to_route() -> float:
	var best := INF
	var count := points.size() if loop else points.size() - 1
	for i in maxi(count, 1):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var near := Geometry3D.get_closest_point_to_segment(position, a, b)
		best = minf(best, near.distance_to(position))
	return best


## Far away: hide it and stop the person's animation (saves time each frame).
func set_near(near: bool) -> void:
	if model.visible == near:
		return
	model.visible = near
	if person != null:
		person.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED


func _physics_process(delta: float) -> void:
	_clock += delta
	moving = false
	if scared_left > 0.0:
		scared_left -= delta
	elif _pause_left > 0.0:
		_pause_left -= delta
	elif points.size() >= 2:
		_drive(delta)
	if model.visible:
		LifeLooks.animate(self, delta, _clock)


func _drive(delta: float) -> void:
	var way := heading()
	if something_in_the_way(way):
		# Wait politely, but if it stays in the way (a parked bike?), turn round.
		_blocked += delta
		if _blocked > GameConfig.LIFE_GIVE_UP_TIME:
			_blocked = 0.0
			_turn_round()
			_pause_left = 1.0
		return
	_blocked = 0.0
	# Turn to face the way it's going, a bit at a time (round corners).
	var want := atan2(-way.x, -way.z)
	rotation.y = lerp_angle(rotation.y, want, minf(1.0, delta * GameConfig.LIFE_TURN_SPEED))
	var gap := points[_next] - position
	gap.y = 0.0
	var step := speed * delta
	moving = true
	if gap.length() <= step:
		position = points[_next]
		_arrive()
	else:
		position += way * step


## Reached a point: on to the next one, or turn round at the end.
func _arrive() -> void:
	var after := _next + _way
	if loop:
		_next = posmod(after, points.size())
	elif after < 0 or after >= points.size():
		_turn_round()
		_pause_left = GameConfig.LIFE_END_PAUSE
	else:
		_next = after


func _turn_round() -> void:
	_way = -_way
	if loop:
		_next = posmod(_next + _way, points.size())  # back to the point behind us
	else:
		_next = clampi(_next + _way, 0, points.size() - 1)
		if position.distance_to(points[_next]) < 0.01:  # we're on that point already
			_next = clampi(_next + _way, 0, points.size() - 1)


## True if the bike, the rider on foot or another moving thing is just ahead (way: the
## direction we'd move). Also true if we'd swing round into the bike or the rider.
func something_in_the_way(way: Vector3) -> bool:
	var turning := absf(angle_difference(rotation.y, atan2(-way.x, -way.z))) > 0.8
	var sweep := maxf(size.x, size.z) * 0.55 + 0.2  # turning a long thing round sweeps this far
	for other in watch:
		if not other.is_visible_in_tree() and not other.is_in_group("bike"):
			continue  # the rider on foot, while riding the bike
		var reach := 0.9 if other.is_in_group("bike") else 0.4  # how far it sticks out round its middle
		var gap := other.global_position - position
		gap.y = 0.0
		var along := gap.dot(way)
		var beside := absf(gap.dot(Vector3(-way.z, 0.0, way.x)))
		if along > 0.0 and along < size.z * 0.5 + look_ahead + reach and beside < size.x * 0.5 + reach:
			return true
		if turning and gap.length() < sweep + reach:
			return true
	# Other moving things (kids, cats, buggies, walkers...): ask the physics world.
	var middle := position + way * (size.z * 0.5 + look_ahead * 0.5) + Vector3.UP * size.y * 0.5
	_ahead.transform = Transform3D(Basis.looking_at(way), middle)
	for hit in get_world_3d().direct_space_state.intersect_shape(_ahead, 6):
		var thing: Object = hit["collider"]
		if thing is Node and (thing as Node).is_in_group("critter"):
			return true
	return false


## Bumped by the bike or startled by the bell: stop for a moment (Critter counts it down).
func _on_scared(_bike: Node3D) -> void:
	_pause_left = 0.0


func _start_somewhere() -> void:
	if points.size() < 2:
		start_at(0, 0.0, true)
		return
	var count := points.size() if loop else points.size() - 1
	start_at(randi() % count, randf(), randf() < 0.5)
