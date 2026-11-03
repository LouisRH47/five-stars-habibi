extends SceneTree
## Regression checks for the web touch layer's actual Input event path.
## Run: godot --headless --path . -s tests/touch_controls_test.gd

class InputProbe extends Node:
	var received: Array[String] = []
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventAction and event.pressed:
			received.append(event.action)
			if event.action == "pause":
				get_tree().paused = true

var _failed := false
var _controls: CanvasLayer


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	_failed = _failed or not ok


func _point(action: String) -> Vector2:
	for button in _controls._buttons:
		if button.action == action:
			return (button.rect as Rect2).get_center()
	return Vector2(-1, -1)


func _touch(index: int, action: String, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = _point(action)
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	_controls = root.get_node("TouchControls")
	var scene := Node.new()
	scene.name = "TouchTestWorld"
	var bike := Node3D.new()
	bike.name = "Bike"
	scene.add_child(bike)
	var probe := InputProbe.new()
	probe.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(probe)
	root.add_child(scene)
	current_scene = scene
	await process_frame
	_check(not _controls.visible, "desktop has no touch overlay before touch input")
	_touch(0, "move_forward", true)
	await process_frame
	_check(_controls.visible, "first touch enables controls in the world")
	_check(Input.is_action_pressed("move_forward"), "touch pedal reaches held input polling")
	_touch(1, "steer_left", true)
	await process_frame
	_check(Input.is_action_pressed("move_forward") and Input.is_action_pressed("steer_left"),
		"two fingers can pedal and steer together")
	_touch(1, "steer_left", false)
	_check(Input.is_action_pressed("move_forward") and not Input.is_action_pressed("steer_left"),
		"lifting steering finger leaves the pedal held")
	_touch(2, "move_forward", true)
	_touch(0, "move_forward", false)
	_check(Input.is_action_pressed("move_forward"), "one of two fingers on the same button can lift")
	_touch(2, "move_forward", false, true)
	_check(not Input.is_action_pressed("move_forward"), "canceled touch releases the final finger")
	_touch(3, "interact", true)
	await process_frame
	_check(probe.received.has("interact"), "Use reaches event-driven order acceptance")
	_check(Input.is_action_pressed("interact"), "Use remains held for pickup and drop-off")
	_touch(3, "interact", false)
	_touch(4, "sprint", true)
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = Vector2(5, 5)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	_check(not Input.is_action_pressed("sprint"), "sliding off a button releases it")
	_touch(5, "move_forward", true)
	_touch(6, "pause", true)
	await process_frame
	await process_frame
	_check(paused, "touch Pause reaches the pause event handler")
	_check(not _controls.visible and not Input.is_action_pressed("move_forward"),
		"pause hides controls and releases held motion")
	paused = false
	await process_frame
	_touch(7, "move_forward", true)
	_controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	Input.flush_buffered_events()
	_check(not Input.is_action_pressed("move_forward"), "losing focus releases held motion")
	_controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	_touch(8, "move_forward", true)
	var menu := Node.new()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	_check(not _controls.visible and not Input.is_action_pressed("move_forward"),
		"returning to a menu hides controls and releases motion")
	_touch(9, "interact", true)
	_check(not Input.is_action_pressed("interact"), "touch controls leave menu input alone")
	scene.queue_free()
	print("RESULT: FAIL" if _failed else "RESULT: PASS")
	quit(1 if _failed else 0)
