class_name HomeWalker
extends Node3D
## Session 68: someone who has just eaten (or shopped) at a restaurant and walks home.
## They follow a list of corners: out of the restaurant door, along the paths and lanes
## (worked out by scripts/navigation_grid.gd) to their home in a cluster, up to the front
## door and in through it. Once they're inside the house they're removed (out of sight).
## Not solid, like customers, so they never trap the bike. Made by scripts/home_walkers.gd.

## The animated person (a shopper with a bag).
var person: Person
## The corners to walk through (y is the ground).
var points: Array[Vector3] = []
## The home's front door (the last-but-one corner) and its number.
var door := Vector3.ZERO
var home := 0
## True once they've walked in through the door.
var inside := false
## Metres per second.
var speed := GameConfig.WALKER_SPEED

var _next := 1


func setup(who: Person, route: Array[Vector3], home_door: Vector3, number: int) -> void:
	person = who
	points = route
	door = home_door
	home = number
	add_child(person)
	position = points[0]
	person.play("walk")
	_face()


## Walks `delta` seconds further along. False once they're inside (then it's removed).
func advance(delta: float) -> bool:
	var left := speed * delta
	while left > 0.0 and _next < points.size():
		var target := points[_next]
		var flat := Vector3(target.x - position.x, 0.0, target.z - position.z)
		var gap := flat.length()
		if gap <= left:
			position = Vector3(target.x, position.y, target.z)
			left -= gap
			_next += 1
			_face()
		else:
			position += flat / gap * left
			left = 0.0
	if _next >= points.size() and not inside:
		inside = true
		queue_free()
	return not inside


## How far along they are: the next corner's number (the smoke test reads it).
func next_corner() -> int:
	return _next


func _physics_process(delta: float) -> void:
	advance(delta)


func _face() -> void:
	if _next >= points.size():
		return
	var way := points[_next] - position
	way.y = 0.0
	if way.length() > 0.01:
		rotation.y = atan2(-way.x, -way.z)  # a Person faces -Z
