class_name CounterQueue
extends Node3D
## Session 58: a short queue at the counter (PRD "Looks pass", Interiors). Sometimes, when
## you walk in to pick up an order, 1 or 2 people are at the till in front of you, and you
## wait 2 to 4 seconds (never more) before holding E works. Then they take their food and
## walk out. The chance and the wait are in game_config.gd (Session 58).

## Tests that time an exact E hold turn the queue off.
static var enabled := true
## Seconds you still have to wait (0 = it's your turn). The DeliveryManager reads it.
static var wait_left := 0.0
## How many people are in front of you (for the counter panel).
static var ahead := 0

var _people: Array[Person] = []
var _room: Node3D
var _id := ""
var _checked_order: Object = null
var _check_left := 0.0
var _door := Vector3(0, 0, 4.0)
var _mine := false   # this room's queue is the one you're waiting in


## p: the room's parts; pickup: where you stand; till: where the people in the queue stand.
func setup(p: InteriorParts, pickup: Vector3, till: Vector3) -> void:
	_room = p.body
	_id = p.id
	for k in 2:
		var person := PeopleLooks.resident((k * 3 + p.seats) % PeopleLooks.RESIDENT_OUTFITS)
		person.name = "Queue%d" % (k + 1)
		person.position = till + Vector3(0, 0, 0.75 * k)
		person.set_meta("spot", person.position)
		person.visible = false
		person.process_mode = Node.PROCESS_MODE_DISABLED
		person.add_to_group("queue_person")
		_people.append(person)
		p.inside.add_child(person)
	_door = Vector3(pickup.x * 0.2, 0, p.size.z * 0.5 - 0.8)


func _process(delta: float) -> void:
	if _mine:
		wait_left = maxf(wait_left - delta, 0.0)
		if wait_left <= 0.0:
			_leave()
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 0.2
	# The GameState autoload, looked up by path (this script is also used by tests that
	# run before the autoloads exist).
	var state := get_node_or_null("/root/GameState")
	if state == null or not enabled:
		return
	var order: Object = state.current_order
	if order == null or order == _checked_order or order.restaurant_id != _id or state.stage_name() != "TO_RESTAURANT":
		return
	var walker := _walker()
	if walker == null or not walker.is_inside_tree():
		return
	var local := _room.to_local(walker.global_position)
	if absf(local.x) > 6.0 or local.z > 5.0 or local.z < -5.0:
		return   # not inside yet
	_checked_order = order
	if randf() >= GameConfig.QUEUE_CHANCE:
		return
	_mine = true
	ahead = 1 + (randi() % 2)
	wait_left = randf_range(GameConfig.QUEUE_WAIT.x, GameConfig.QUEUE_WAIT.y)
	for k in _people.size():
		var person := _people[k]
		person.position = person.get_meta("spot")
		person.rotation.y = 0.0   # facing the counter (our people face -Z)
		person.visible = k < ahead
		person.process_mode = Node.PROCESS_MODE_INHERIT if k < ahead else Node.PROCESS_MODE_DISABLED
		person.play("idle")


## Their turn is over: they walk to the door and go.
func _leave() -> void:
	_mine = false
	ahead = 0
	for person in _people:
		if not person.visible:
			continue
		person.play("walk")
		person.look_at(_room.to_global(_door), Vector3.UP)
		var walk := create_tween()
		walk.tween_property(person, "position", _door, person.position.distance_to(_door) / 1.3)
		walk.tween_callback(func():
			person.visible = false
			person.process_mode = Node.PROCESS_MODE_DISABLED)


func _walker() -> Node3D:
	var world := _room.get_parent().get_parent() if _room.get_parent() != null else null
	return world.get_node_or_null("Walker") as Node3D if world != null else null
