class_name VenueQueue
extends Node
## The short queue at a restaurant counter (looks pass, Session 54). When you take an
## order, sometimes 1 or 2 people are already waiting at that counter. When you walk in
## and reach the counter, they're served one by one and leave, which takes 2 to 4
## seconds; until then holding E doesn't fill the bar (DeliveryManager asks waiting()).
## Teleporting in (tests) skips the queue. Chances and times are in game_config.gd.

## The rider on foot.
var walker: Node3D
var places: PlaceBuilder
## People still in front of you, and seconds left to wait.
var ahead := 0
var wait_left := 0.0
## The room of the order being queued for (null when there's no queue).
var room: Node3D

var _order: Order
var _wait_total := 0.0
var _was_inside := false
var _walked_in := false
var _last_spot := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	GameState.shift_ended.connect(func(_summary): clear())


## True while someone is still being served before you.
func waiting() -> bool:
	return wait_left > 0.0


func _process(delta: float) -> void:
	var order := GameState.current_order
	var stage := GameState.stage
	if order != _order:
		clear()
		_order = order
		if order != null and stage == GameState.Stage.TO_RESTAURANT:
			start(order.restaurant_id, roll())
	if room == null or walker == null:
		return
	var spot := walker.global_position
	var inside := walker.is_visible_in_tree() and RestaurantRoom.is_inside(room, spot)
	if inside and not _was_inside:
		var step := Vector2(spot.x - _last_spot.x, spot.z - _last_spot.z).length()
		if step < 1.0:
			_walked_in = true
		else:
			clear()  # jumped straight in (a test, or a respawn): no queue
			return
	_was_inside = inside
	_last_spot = spot
	# The wait starts when you reach the counter (close enough to hold E).
	if _walked_in and ahead > 0 and _wait_total == 0.0 and inside:
		var counter := room.to_global(room.get_meta("counter_spot", Vector3.ZERO))
		if Vector2(spot.x - counter.x, spot.z - counter.z).length() <= GameConfig.INTERACT_RADIUS:
			_wait_total = _rng.randf_range(GameConfig.QUEUE_WAIT_MIN, GameConfig.QUEUE_WAIT_MAX)
			wait_left = _wait_total
	if wait_left > 0.0:
		wait_left = maxf(0.0, wait_left - delta)
		# The first person leaves part-way through, the last one when the wait is over.
		var still := ceili(wait_left / _wait_total * ahead - 0.001) if _wait_total > 0.0 else 0
		while ahead > still:
			_serve_next()


## How many people are waiting: 0 (most of the time), 1 or 2.
func roll() -> int:
	var dice := _rng.randf()
	if dice < GameConfig.QUEUE_NONE_CHANCE:
		return 0
	return 2 if dice > 1.0 - GameConfig.QUEUE_TWO_CHANCE else 1


## Puts `count` people at the counter of a restaurant (tests call this directly).
func start(restaurant_id: String, count: int) -> void:
	clear()
	_order = GameState.current_order
	if places == null or count <= 0:
		return
	room = places.get_node_or_null("Restaurant_" + restaurant_id)
	if room == null or not room.has_meta("queue_spots"):
		room = null
		return
	var spots: Array = room.get_meta("queue_spots")
	ahead = mini(count, spots.size())
	for i in ahead:
		var person := room.get_node_or_null("QueuePerson%d" % (i + 1)) as Person
		if person == null:
			continue
		person.position = spots[i]
		person.rotation = Vector3(0, room.get_meta("queue_facing", 0.0), 0)
		person.visible = true
		person.process_mode = Node.PROCESS_MODE_INHERIT
		person.play("idle")
	_was_inside = walker != null and RestaurantRoom.is_inside(room, walker.global_position)
	if walker != null:
		_last_spot = walker.global_position


## Everyone goes away at once (new order, end of shift, teleport).
func clear() -> void:
	if room != null and is_instance_valid(room):
		for i in range(1, 3):
			var person := room.get_node_or_null("QueuePerson%d" % i) as Node3D
			if person != null:
				person.visible = false
	room = null
	ahead = 0
	wait_left = 0.0
	_wait_total = 0.0
	_walked_in = false


## The person at the front walks out; the next one steps up to the counter.
func _serve_next() -> void:
	var spots: Array = room.get_meta("queue_spots")
	var front := room.get_node_or_null("QueuePerson1") as Person
	var second := room.get_node_or_null("QueuePerson2") as Person
	# Whoever stands at the front spot leaves.
	var leaving := front if front != null and front.visible and front.position.distance_to(spots[0]) < 0.3 else second
	var staying := second if leaving == front else front
	ahead -= 1
	if leaving != null:
		var exit: Vector3 = room.get_meta("queue_exit", spots[0] + Vector3(0, 0, 6))
		leaving.play("walk")
		var face := Vector3(exit.x, leaving.position.y, exit.z)
		if face.distance_to(leaving.position) > 0.1:
			leaving.look_at(room.to_global(face), Vector3.UP)
		var walk := leaving.create_tween()
		var seconds := leaving.position.distance_to(exit) / GameConfig.PERSON_WALK_ANIM_MPS
		walk.tween_property(leaving, "position", exit, seconds)
		walk.tween_callback(func(): leaving.visible = false)
	if staying != null and staying.visible and ahead > 0:
		staying.play("walk")
		var step := staying.create_tween()
		step.tween_property(staying, "position", spots[0], 0.6)
		step.tween_callback(func(): staying.play("idle"))
