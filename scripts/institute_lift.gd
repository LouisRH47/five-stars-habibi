class_name InstituteLift
extends Node3D
## Session 91: the glass lift in the C Institute lobby. Its door downstairs faces the
## lobby; its door upstairs opens onto the back balcony (the other side of the car).
## On foot, stand at a lift door and press E: the doors open, you step in, the doors
## close, the car rides up (or down) for a few seconds, the doors on the other side open
## and you step out. If the car is on the other floor, it comes to you first.
## The ride doesn't use physics: you ride along with the car, then you're set down outside.
## Timings and distances: game_config.gd (Session 91).

## Where the lift stands in the institute room (its middle, on the ground) and half its size.
const CENTRE := Vector3(13.25, 0, -5.15)
const HALF := 1.75
const TOP := 9.6               # the top of the glass shaft
const WHITE := Color(0.97, 0.97, 0.96)
const STEEL := Color(0.72, 0.74, 0.76)
const CAR := Color(0.85, 0.86, 0.87)
const DOOR_GAP := 0.65         # half the width of a door opening

## Which floor the car is at: 0 downstairs, 1 upstairs.
var floor_now := 0
## True from the moment you press E until you're out again.
var busy := false
## How many rides there have been (the test reads this).
var rides := 0
var car: Node3D
var _doors: Array[Node3D] = []  # [downstairs doors, upstairs doors]
var _open := [0.0, 0.0]         # how open each pair is (0 closed, 1 open)
var _steps: Array = []          # what's left to do: ["open", floor], ["close", floor], ["ride", floor], ["in"], ["out"]
var _step_time := 0.0
var _rider: CharacterBody3D  # the walker (scripts/walker.gd)
var _prompt: Label
var _prompt_layer: CanvasLayer


## Builds the lift into the institute room `body` (the shaft is solid).
static func build(body: StaticBody3D, floor2: float) -> InstituteLift:
	var lift := InstituteLift.new()
	lift.name = "Lift"
	lift.position = CENTRE
	lift.set_meta("floor2", floor2)
	lift.set_meta("static_batch_dynamic", true)
	body.add_child(lift)
	LowPoly.solid_box(body, Vector3(HALF * 2.0, TOP, HALF * 2.0), CENTRE + Vector3(0, TOP * 0.5, 0))
	LiftLook.shaft(lift, HALF, TOP, floor2)
	lift.car = LiftLook.car(lift, HALF)
	lift._doors = [LiftLook.doors(lift, HALF, 0.0, 1.0), LiftLook.doors(lift, HALF, floor2, -1.0)]
	LiftLook.call_panel(lift, HALF, 0.0, 1.0, "Lift up")
	LiftLook.call_panel(lift, HALF, floor2, -1.0, "Lift down")
	return lift


func _ready() -> void:
	_prompt_layer = CanvasLayer.new()
	_prompt_layer.layer = 20
	add_child(_prompt_layer)
	_prompt = Label.new()
	_prompt.position = Vector2(620, 940)
	_prompt.add_theme_font_size_override("font_size", 25)
	_prompt.add_theme_color_override("font_color", Color(1, 0.86, 0.56))
	_prompt.visible = false
	_prompt_layer.add_child(_prompt)


## The floor height of floor 0 or 1 (in the room's metres).
func floor_height(which: int) -> float:
	return 0.0 if which == 0 else float(get_meta("floor2", 6.5))


## Where you stand to call the lift on a floor, in the world.
func call_spot(which: int) -> Vector3:
	var out := 1.0 if which == 0 else -1.0
	return to_global(Vector3(0, floor_height(which), out * (HALF + GameConfig.LIFT_STEP_OUT)))


## The floor (0 or 1) whose lift door the walker is standing at, or -1.
func door_near(walker: Node3D) -> int:
	if walker == null or not walker.is_visible_in_tree():
		return -1
	for which in 2:
		var spot := call_spot(which)
		var gap := walker.global_position - spot
		if absf(gap.y) < 1.2 and Vector2(gap.x, gap.z).length() < GameConfig.LIFT_CALL_DISTANCE:
			return which
	return -1


## Starts a ride for `walker` from the floor they're at. Returns true if it started.
func press(walker: CharacterBody3D) -> bool:
	var which := door_near(walker)
	if busy or which < 0 or walker.get("active") != true:
		return false
	busy = true
	_rider = walker
	_steps.clear()
	if floor_now != which:
		_steps.append(["ride", which])  # the car comes to you first
	var other := 1 - which
	_steps.append_array([["open", which], ["in"], ["close", which], ["ride", other], ["open", other], ["out"], ["close", other]])
	_step_time = 0.0
	return true


## At a lift door, E is for the lift: it doesn't also accept a phone order.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not busy and door_near(_walker()) >= 0:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var walker := _walker()
	var near := -1 if walker == null or busy else door_near(walker)
	if near >= 0 and Input.is_action_just_pressed("interact") and not get_tree().paused:
		press(walker)
		near = -1
	_prompt.visible = near >= 0
	if near >= 0:
		_prompt.text = "E · Lift %s" % ("up" if near == 0 else "down")
	if not _steps.is_empty():
		_do_step(delta)
	for which in 2:
		LiftLook.slide(_doors[which], _open[which], DOOR_GAP)


func _do_step(delta: float) -> void:
	var step: Array = _steps[0]
	_step_time += delta
	var done := false
	match step[0]:
		"open", "close":
			var which: int = step[1]
			var goal := 1.0 if step[0] == "open" else 0.0
			_open[which] = move_toward(_open[which], goal, delta / GameConfig.LIFT_DOOR_SECONDS)
			done = is_equal_approx(_open[which], goal)
		"in":
			_hold_rider(Vector3(0, floor_height(floor_now), 0), PI if floor_now == 1 else 0.0)  # face the far door
			done = true
		"ride":
			var to: int = step[1]
			var t := clampf(_step_time / GameConfig.LIFT_RIDE_SECONDS, 0.0, 1.0)
			var eased := t * t * (3.0 - 2.0 * t)  # gentle start and stop
			car.position.y = lerpf(floor_height(floor_now), floor_height(to), eased)
			if _rider != null and _rider.has_meta("in_lift"):
				_hold_rider(Vector3(0, car.position.y, 0), PI if to == 0 else 0.0)
			done = t >= 1.0
			if done:
				floor_now = to
		"out":
			var out := 1.0 if floor_now == 0 else -1.0
			_set_down(Vector3(0, floor_height(floor_now) + 0.05, out * (HALF + GameConfig.LIFT_STEP_OUT)), 0.0 if out < 0.0 else PI)
			done = true
	if done:
		_steps.pop_front()
		_step_time = 0.0
		if _steps.is_empty():
			busy = false


## Keeps the walker standing still in the car (no walking while you ride).
func _hold_rider(local: Vector3, turn: float) -> void:
	if _rider == null:
		return
	_rider.set_meta("in_lift", true)
	_rider.set_physics_process(false)
	_rider.velocity = Vector3.ZERO
	_rider.set("speed", 0.0)
	_rider.global_position = to_global(local + Vector3(0, 0.15, 0))  # on the car's floor
	_rider.global_rotation = Vector3(0, global_rotation.y + turn, 0)
	var person := _rider.get_node_or_null("Model") as Person
	if person != null:
		person.play("idle")


## Puts the walker down outside the door, facing out, and gives them back control.
func _set_down(local: Vector3, turn: float) -> void:
	if _rider == null:
		return
	_rider.global_position = to_global(local)
	_rider.global_rotation = Vector3(0, global_rotation.y + turn, 0)
	_rider.velocity = Vector3.ZERO
	_rider.remove_meta("in_lift")
	_rider.set_physics_process(true)
	_rider = null
	rides += 1


## The walker (the rider on foot), if they're on foot right now.
func _walker() -> CharacterBody3D:
	for who in get_tree().get_nodes_in_group("opens_doors"):
		if who is CharacterBody3D and who.get("active") == true:
			return who
	return null
