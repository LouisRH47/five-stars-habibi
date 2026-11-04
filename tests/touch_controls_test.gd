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
	# Input.parse_input_event receives window coordinates, including at iPad scale.
	event.position = root.get_final_transform() * _point(action)
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
	await _check_ipad_layouts()
	await _check_dynamic_touch_widgets()
	await _check_rocket_control()
	print("RESULT: FAIL" if _failed else "RESULT: PASS")
	quit(1 if _failed else 0)


func _visible_widgets(node: Node) -> Array[Control]:
	var widgets: Array[Control] = []
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and (
				child is BaseButton or child is LineEdit or child is Slider):
			widgets.append(child)
		widgets.append_array(_visible_widgets(child))
	return widgets


func _widget_failures(node: Node, bounds: Rect2) -> Array[String]:
	var failures: Array[String] = []
	var rects: Array[Rect2] = []
	for child in _visible_widgets(node):
		var rect: Rect2 = root.get_final_transform() * child.get_global_rect()
		if rect.size.x < 43.99 or rect.size.y < 43.99 or not bounds.encloses(rect):
			failures.append("%s %s" % [child.get_class(), rect])
		for earlier in rects:
			if rect.intersects(earlier):
				failures.append("overlapping targets: %s %s" % [earlier, rect])
		rects.append(rect)
	return failures


func _game_control_failures(bounds: Rect2) -> Array[String]:
	var failures: Array[String] = []
	var rects: Array[Rect2] = []
	for button in _controls._buttons:
		var rect: Rect2 = root.get_final_transform() * (button.rect as Rect2)
		if rect.size.x < 43.99 or rect.size.y < 43.99 or not bounds.encloses(rect):
			failures.append("%s %s" % [button.action, rect])
		var font_size: int = _controls._button_font_size(button)
		var text_width := ThemeDB.fallback_font.get_string_size(button.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if font_size * _controls._css_scale.y < 13.99 or text_width * _controls._css_scale.x > rect.size.x - 3.99:
			failures.append("label too small or overflowing: %s" % button.label)
		for earlier in rects:
			if rect.intersects(earlier):
				failures.append("overlapping controls: %s %s" % [earlier, rect])
		rects.append(rect)
	return failures


func _check_ipad_layouts() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	# Reuse a scene across orientations: values must grow and shrink on rotation.
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for dimensions in [Vector2i(1024, 768), Vector2i(768, 1024), Vector2i(1180, 820), Vector2i(1024, 650)]:
		root.size = dimensions
		await process_frame
		await process_frame
		await process_frame
		var bounds := Rect2(Vector2.ZERO, dimensions)
		var control_errors := _game_control_failures(bounds)
		_check(control_errors.is_empty(), "%s gameplay targets fit without overlap: %s" % [dimensions, control_errors])
		for page in ["menu", "form", "hired"]:
			menu._show_page(page)
			await process_frame
			await process_frame
			var errors := _widget_failures(menu, bounds)
			_check(errors.is_empty(), "%s %s controls fit and are at least 44px: %s" % [dimensions, page, errors])
			if page == "form":
				var popup: PopupMenu = menu.country_box.get_popup()
				menu.country_box.show_popup()
				await process_frame
				await process_frame
				var popup_rect: Rect2 = root.get_final_transform() * Rect2(popup.position, popup.size)
				var row_height := popup.get_theme_font("font").get_height(popup.get_theme_font_size("font_size")) + popup.get_theme_constant("v_separation")
				_check(bounds.grow(0.1).encloses(popup_rect) and row_height * _controls._css_scale.y >= 43.99,
					"%s country popup fits with 44px rows and scrolls: %s row %.2f" % [dimensions, popup_rect, row_height * _controls._css_scale.y])
				popup.hide()
		menu._open_settings()
		await process_frame
		await process_frame
		var errors := _widget_failures(menu, bounds)
		_check(errors.is_empty(), "%s settings targets fit and are at least 44px: %s" % [dimensions, errors])
		menu.settings_panel._on_back()
		var pause: CanvasLayer = load("res://ui/pause_menu.tscn").instantiate()
		menu.add_child(pause)
		_controls._widgets_dirty = true
		pause._pause()
		await process_frame
		await process_frame
		await process_frame
		errors = _widget_failures(pause, bounds)
		_check(errors.is_empty(), "%s pause targets fit and are at least 44px: %s" % [dimensions, errors])
		paused = false
		pause.queue_free()
		await process_frame
	menu.queue_free()
	await process_frame


func _has_touch_target(control: Control) -> bool:
	var rect: Rect2 = root.get_final_transform() * control.get_global_rect()
	return rect.size.x >= 43.99 and rect.size.y >= 43.99


func _check_dynamic_touch_widgets() -> void:
	root.size = Vector2i(1024, 768)
	var scene := Node.new()
	var shop: CanvasLayer = load("res://ui/side_panel.gd").new()
	var profile: CanvasLayer = load("res://scripts/profile_page.gd").new()
	scene.add_child(shop)
	scene.add_child(profile)
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	shop.visible = true
	var initial_row: Button = shop.add_row("Leave shop", "")
	await process_frame
	_check(_has_touch_target(initial_row), "shop rows created after scene load have 44px touch targets")
	shop.clear_rows()
	var rebuilt_row: Button = shop.add_row("Checkout", "")
	await process_frame
	_check(_has_touch_target(rebuilt_row), "rebuilt shop rows keep 44px touch targets")

	var state: Node = root.get_node("GameState")
	var original_routes: Dictionary = state.personal_bests["routes"]
	state.personal_bests["routes"] = {"touch-test": 30}
	profile.open()
	state.personal_bests["routes"] = original_routes
	await process_frame
	var reveal: Button
	for widget in profile._content.get_children():
		if widget is Button and widget.text == "View fastest rides":
			reveal = widget
			break
	_check(reveal != null and _has_touch_target(reveal), "profile's late-created reveal button has a 44px touch target")
	profile.close()
	scene.queue_free()
	await process_frame


func _rocket_button() -> Dictionary:
	for button in _controls._buttons:
		if button.action == "rocket_boost":
			return button
	return {}


func _check_rocket_control() -> void:
	var scene := Node3D.new()
	var bike: Node3D = load("res://scenes/bike.tscn").instantiate()
	bike.name = "Bike"
	scene.add_child(bike)
	root.add_child(scene)
	current_scene = scene
	bike.set_physics_process(false)
	bike.configure_upgrades({})
	await process_frame
	await process_frame
	_check(not _rocket_button().get("visible", false), "rocket touch button is hidden before the upgrade is owned")
	bike.configure_upgrades({"rocket": 1})
	await process_frame
	var button := _rocket_button()
	_check(button.get("visible", false) and button.get("enabled", false), "buying a rocket exposes an enabled touch control")
	_touch(20, "rocket_boost", true)
	bike._physics_process(1.0 / 60.0)
	_check(bike.boost_active, "touching Boost fires the actual bike rocket without a keyboard")
	_touch(20, "rocket_boost", false)
	await process_frame
	_check(not _rocket_button().get("enabled", true), "active rocket disables another activation")
	bike._boost_left = 0.0
	bike.boost_cooldown_left = 12.0
	await process_frame
	_check("12" in str(_rocket_button().get("label", "")), "the touch button shows remaining rocket recharge seconds")
	_touch(21, "rocket_boost", true)
	bike._physics_process(1.0 / 60.0)
	_check(not bike.boost_active and not Input.is_action_pressed("rocket_boost"), "touching a recharging rocket cannot activate or latch input")
	_touch(21, "rocket_boost", false)
	for dimensions in [Vector2i(1024, 768), Vector2i(768, 1024), Vector2i(1180, 820), Vector2i(1024, 650)]:
		root.size = dimensions
		await process_frame
		await process_frame
		var errors := _game_control_failures(Rect2(Vector2.ZERO, dimensions))
		_check(errors.is_empty(), "%s rocket layout keeps 44px non-overlapping controls: %s" % [dimensions, errors])
	bike.boost_cooldown_left = 0.0
	await process_frame
	_touch(22, "rocket_boost", true)
	paused = true
	await process_frame
	_check(not Input.is_action_pressed("rocket_boost"), "pausing releases a held rocket control")
	paused = false
	await process_frame
	_touch(23, "rocket_boost", true)
	_controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	Input.flush_buffered_events()
	_check(not Input.is_action_pressed("rocket_boost"), "losing focus releases a held rocket control")
	_controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	_touch(24, "rocket_boost", true)
	root.size = Vector2i(768, 1024)
	await process_frame
	await process_frame
	_check(not Input.is_action_pressed("rocket_boost"), "rotating releases a held rocket control")
	bike.set_parked(true)
	await process_frame
	_check(not _rocket_button().get("enabled", true), "the rocket control cannot fire while the rider is on foot")
	bike.set_parked(false)
	bike.configure_upgrades({})
	await process_frame
	_check(not _rocket_button().get("visible", true), "removing rocket equipment hides its touch control")
	scene.queue_free()
	await process_frame
