class_name RestaurantWaiter
extends Node3D
## Session 90: the waiter outside a Plaza restaurant is always busy. Round and round:
##   wipe one café table with a cloth, chat to the diner at the other (or wipe it too),
##   pick up the used plates on a tray and carry them inside, come back out with food on
##   the tray and put it down at a table with someone at it. They walk between the tables
##   and the door along the shop front (in front of the benches), and the glass doors
##   slide open for them. Never more than a second standing still.
## PlaceCrowds makes one for every restaurant with café tables (PlazaLife's tables).
## This node sits on the restaurant (its +Z is out of the front), so every spot is the
## restaurant's own metres. It only moves while the waiter is shown and animated.

## What the waiter is doing now: "walk", "wipe", "chat", "inside", "serve" or "pause".
var task := ""
## Every task done so far, and how many times (the tests read this).
var tasks_seen := {}
var person: Person
var arms: WaiterArms
var tray: Node3D
var cloth: Node3D
## The café tables of this restaurant, in its own metres: [{"at": Vector3, "sitter": Person}].
var tables: Array = []

var _front := 8.0               # the shop front (half the restaurant's depth)
var _world: Node
var _steps: Array = []          # [task, spot or facing target, seconds]
var _step := -1
var _left := 0.0
var _path: Array[Vector3] = []  # spots still to walk to
var _chatting_with: Person
var _looked := false
var _start := 0                 # which waiter this is (they start at different points)
var _look_tries := 0


## A waiter for one restaurant in the data list. i: which waiter (their look).
static func make(shop: Dictionary, size: Vector3, i: int, world: Node) -> RestaurantWaiter:
	var waiter := RestaurantWaiter.new()
	waiter.name = "Waiter_%s" % shop.get("id", str(i))
	waiter.position = shop["position"]
	waiter.rotation_degrees.y = shop["facing"]
	waiter._front = size.z * 0.5
	waiter._world = world
	waiter._start = i
	var person := PlaceLooks.waiter(i)
	person.name = "Waiter"
	person.position = Vector3(1.8, 0.02, waiter._front + 1.2)
	person.rotation.y = PI  # facing out of the shop (+Z); people face -Z
	person.add_to_group("opens_doors")
	waiter.add_child(person)
	waiter.person = person
	waiter._dress()
	return waiter


## The tray (with plates and a glass) and the cloth, and the arms that hold them.
func _dress() -> void:
	arms = WaiterArms.new()
	arms.name = "WaiterArms"
	arms.person = person
	arms.pose = person.pose
	person.skeleton.add_child(arms)
	tray = Node3D.new()
	tray.name = "Tray"
	tray.position = Vector3(0, GameConfig.WAITER_TRAY_HEIGHT, -0.36)
	person.add_child(tray)
	LowPoly.cylinder(tray, 0.26, 0.24, 0.02, Color(0.62, 0.62, 0.64), Vector3.ZERO)
	for k in 2:
		LowPoly.cylinder(tray, 0.1, 0.08, 0.02, Color(0.98, 0.98, 0.96), Vector3(-0.1 + k * 0.2, 0.02, 0.02))
		LowPoly.sphere(tray, 0.06, 0.05, [Color(0.85, 0.45, 0.2), Color(0.5, 0.7, 0.3)][k], Vector3(-0.1 + k * 0.2, 0.045, 0.02))
	LowPoly.cylinder(tray, 0.035, 0.03, 0.12, Color(0.85, 0.95, 1.0), Vector3(0, 0.07, -0.12))
	tray.visible = false
	var hand := person.follow("RightHand")
	cloth = Node3D.new()
	cloth.name = "Cloth"
	hand.add_child(cloth)
	LowPoly.box(cloth, Vector3(0.16, 0.03, 0.12), Color(0.95, 0.95, 0.97), person.spot("RightHand") + Vector3(0, -0.06, -0.04))
	cloth.visible = false


func _process(delta: float) -> void:
	if person == null or not person.visible or person.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if not _looked:
		_find_tables()
	if _steps.is_empty():
		return
	if task == "serve":  # the tray goes down onto the table
		arms.lower = minf(1.0, arms.lower + delta / maxf(0.3, GameConfig.WAITER_SERVE_SECONDS * 0.5))
		tray.position = Vector3(0, lerpf(GameConfig.WAITER_TRAY_HEIGHT, 0.86, arms.lower), lerpf(-0.36, -0.55, arms.lower))
	if not _path.is_empty():
		_walk(delta)
		return
	_left -= delta
	if _left <= 0.0:
		_next()


## PlazaLife's café tables in front of this restaurant, and who sits at them.
func _find_tables() -> void:
	_look_tries += 1
	var life := _world.get_node_or_null("PlazaBuilder/PlazaLife") if _world != null else null
	if life == null and _look_tries < 600:
		return
	_looked = true
	tables.clear()
	var furniture := life.get_node_or_null("PlazaFurniture") if life != null else null
	if furniture != null:
		for node in furniture.get_children():
			if not str(node.name).begins_with("CafeTable") or str(node.name).contains("Solid") or node is CollisionShape3D:
				continue
			var local := to_local((node as Node3D).global_position)
			if absf(local.x) < 11.0 and local.z > _front and local.z < _front + 6.0:
				tables.append({"at": Vector3(local.x, 0, local.z), "sitter": null})
		tables.sort_custom(func(a, b): return a["at"].x < b["at"].x)
		for sitter in life.get_children():
			if sitter is Person and str(sitter.name).begins_with("CafeSitter"):
				var local := to_local((sitter as Node3D).global_position)
				for table: Dictionary in tables:
					if Vector2(local.x - table["at"].x, local.z - table["at"].z).length() < 1.3:
						table["sitter"] = sitter
	_plan()
	_step = -1
	if _start > 0:  # waiters start at different points of the round, so they aren't in step
		_jump_to((_start * 5) % _steps.size())
	_next()


## Starts the round at step k: stands where the walking so far would have taken them.
func _jump_to(k: int) -> void:
	var spot := person.position
	var carrying := false
	for j in k:
		var step: Array = _steps[j]
		if step[0] == "walk":
			spot = step[1]
		elif step[0] == "carry":
			carrying = step[1]
	person.position = Vector3(spot.x, 0.06 if spot.z < _front - 0.2 else 0.02, spot.z)
	tray.visible = carrying
	arms.carrying = carrying
	_step = k - 1


## The round of tasks (see the top of this file).
func _plan() -> void:
	_steps.clear()
	var door := Vector3(0, 0, _front + 1.2)
	var inside := Vector3(0, 0, _front - 1.8)
	var out_side := Vector3(0, 0, _front + 10.0)
	if tables.is_empty():  # no tables here: in and out with plates, by the door
		_steps = [["walk", inside], ["inside", out_side, GameConfig.WAITER_INSIDE_SECONDS],
				["carry", true], ["walk", door], ["serve", out_side, GameConfig.WAITER_SERVE_SECONDS],
				["carry", false], ["pause", out_side, GameConfig.WAITER_PAUSE_SECONDS]]
		return
	var a: Dictionary = tables[0]
	var b: Dictionary = tables[tables.size() - 1]
	var with_diner: Dictionary = b if b["sitter"] != null else a
	_steps.append_array(_go_to_table(a))
	_steps.append(["wipe", a["at"], GameConfig.WAITER_WIPE_SECONDS])
	if b != a:
		_steps.append_array(_go_to_table(b))
	_steps.append(["chat" if b["sitter"] != null else "wipe", b["at"], GameConfig.WAITER_CHAT_SECONDS])
	_steps.append(["carry", true])  # the used plates
	_steps.append(["walk", _lane(b["at"].x)])
	_steps.append(["walk", door])
	_steps.append(["walk", inside])
	_steps.append(["inside", Vector3(0, 0, -20.0), GameConfig.WAITER_INSIDE_SECONDS])
	_steps.append(["walk", door])  # coming back out with food on the tray
	_steps.append(["pause", out_side, GameConfig.WAITER_PAUSE_SECONDS])
	_steps.append_array(_go_to_table(with_diner, door))
	_steps.append(["serve", with_diner["at"], GameConfig.WAITER_SERVE_SECONDS])
	_steps.append(["carry", false])
	_steps.append(["walk", _lane(with_diner["at"].x)])


## Walk along the shop front (in front of the benches), then up to the table.
func _go_to_table(table: Dictionary, from := Vector3.INF) -> Array:
	var at: Vector3 = table["at"]
	var steps := []
	if from != Vector3.INF:
		steps.append(["walk", from])
	steps.append(["walk", _lane(at.x)])
	steps.append(["walk", Vector3(at.x, 0, at.z - 0.8)])
	return steps


## A spot on the walkway along the shop front, between the glass and the benches.
func _lane(x: float) -> Vector3:
	return Vector3(x, 0, _front + 1.2)


func _next() -> void:
	_step = (_step + 1) % _steps.size()
	var step: Array = _steps[_step]
	var kind: String = step[0]
	if kind == "carry":
		tray.visible = step[1]
		tray.position = Vector3(0, GameConfig.WAITER_TRAY_HEIGHT, -0.36)
		arms.carrying = step[1]
		arms.lower = 0.0
		_next()
		return
	if kind == "walk":
		var to: Vector3 = step[1]
		to.y = person.position.y
		if person.position.distance_to(to) < 0.05:
			_next()
			return
		_path = [to]
		_set_task("walk")
		person.play("walk")
		return
	_set_task(kind)
	_left = step[2]
	person.play("idle")
	var target: Vector3 = step[1]
	if kind == "chat" and _sitter_at(target) != null:
		_chatting_with = _sitter_at(target)
		target = _chatting_with.position if _chatting_with.get_parent() == self else to_local(_chatting_with.global_position)
		person.pose.talking = true  # they take turns to talk (scripts/alive_pose.gd)
		_chatting_with.pose.talking = true
		person.pose.talk_turn = 0.0
		_chatting_with.pose.talk_turn = 1.0
	_face(target - person.position)


func _set_task(kind: String) -> void:
	if task == "chat" and kind != "chat":
		person.pose.talking = false
		if _chatting_with != null and is_instance_valid(_chatting_with):
			_chatting_with.pose.talking = false
		_chatting_with = null
	task = kind
	tasks_seen[kind] = tasks_seen.get(kind, 0) + 1
	arms.task = kind
	cloth.visible = kind == "wipe"


func _sitter_at(at: Vector3) -> Person:
	for table: Dictionary in tables:
		if table["at"].distance_to(at) < 0.1 and table["sitter"] != null and is_instance_valid(table["sitter"]):
			return table["sitter"]
	return null


func _walk(delta: float) -> void:
	var goal: Vector3 = _path[0]
	var way := goal - person.position
	way.y = 0.0
	var step := GameConfig.WAITER_WALK_SPEED * delta
	if way.length() <= step:
		person.position = Vector3(goal.x, person.position.y, goal.z)
		_path.pop_front()
		if _path.is_empty():
			_next()
		return
	person.position += way.normalized() * step
	# Inside, the tiled floor is a little higher than the Plaza paving.
	person.position.y = 0.06 if person.position.z < _front - 0.2 else 0.02
	_face(way)


## Turns the waiter to look along `way` (in the restaurant's metres).
func _face(way: Vector3) -> void:
	if Vector2(way.x, way.z).length() > 0.01:
		person.rotation.y = atan2(-way.x, -way.z)  # people face -Z
