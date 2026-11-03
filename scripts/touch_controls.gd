extends CanvasLayer
## Touch-only driving controls. Send real action events so both held inputs and
## the game's event-driven buttons behave exactly like the keyboard.

var touch_enabled := false
var _surface: Control
var _buttons: Array[Dictionary] = []
var _fingers: Dictionary = {}  # touch index -> action
var _scene: Node
var _focused := true
var _widgets_dirty := true
var _css_scale := Vector2.ONE

const MIN_TOUCH_TARGET := 44.0
const MIN_WIDGET_TEXT := 16.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 9  # normal HUD above the world; pause and results stay above us
	touch_enabled = DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		touch_enabled = touch_enabled or JavaScriptBridge.eval("('ontouchstart' in window) || navigator.maxTouchPoints > 0") == true
	_surface = Control.new()
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_surface)
	_surface.draw.connect(_draw_buttons)
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = false


func _process(_delta: float) -> void:
	_refresh_state()


func _refresh_state() -> void:
	var current := get_tree().current_scene
	if current != _scene:
		_release_all()
		_scene = current
		_widgets_dirty = true
	if touch_enabled and _widgets_dirty and is_instance_valid(_scene):
		_resize_touch_widgets(_scene)
		_widgets_dirty = false
	var playing := is_instance_valid(_scene) and _scene.has_node("Bike")
	var active := touch_enabled and playing and not get_tree().paused and _focused
	if not active:
		_release_all()
	visible = active
	if touch_enabled and playing:
		_make_room_for_controls()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not touch_enabled:
			_widgets_dirty = true
		touch_enabled = true
		_refresh_state()
		if _fingers.has(event.index):
			if not event.pressed or event.canceled:
				_release_finger(event.index)
			get_viewport().set_input_as_handled()
		elif visible and event.pressed and not event.canceled:
			var action := _action_at(event.position)
			if action != "":
				_press_finger(event.index, action)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _fingers.has(event.index):
		# Sliding off a control releases it; starting another action needs a new tap.
		if _action_at(event.position) != _fingers[event.index]:
			_release_finger(event.index)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_release_all()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true


func _exit_tree() -> void:
	_release_all()


func _press_finger(index: int, action: String) -> void:
	var already_held := _fingers.values().has(action)
	_fingers[index] = action
	if not already_held:
		_send_action(action, true)
	_surface.queue_redraw()


func _release_finger(index: int) -> void:
	var action: String = _fingers[index]
	_fingers.erase(index)
	if not _fingers.values().has(action):
		_send_action(action, false)
	_surface.queue_redraw()


func _release_all() -> void:
	# Release only actions this layer owns, leaving desktop keyboard input alone.
	for index in _fingers.keys():
		_release_finger(index)


func _send_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _action_at(point: Vector2) -> String:
	for button in _buttons:
		if (button.rect as Rect2).has_point(point):
			return button.action
	return ""


func _layout() -> void:
	_release_all()
	_update_css_scale()
	_widgets_dirty = true
	_buttons.clear()
	var size := get_viewport().get_visible_rect().size
	var w := size.x
	var h := size.y
	_add("steer_left", "Left", Rect2(24, h - 150, 140, 126))
	_add("steer_right", "Right", Rect2(178, h - 150, 140, 126))
	_add("move_forward", "Go", Rect2(w - 164, h - 290, 140, 126))
	_add("move_back", "Brake", Rect2(w - 164, h - 150, 140, 126))
	_add("sprint", "Fast", Rect2(w - 318, h - 290, 140, 126))
	_add("handbrake", "Stop", Rect2(w - 318, h - 150, 140, 126))
	_add("toggle_bike", "Bike/walk", Rect2(w / 2 - 200, h - 290, 190, 126))
	_add("interact", "Use / hold", Rect2(w / 2 + 10, h - 290, 190, 126))
	var extras := [["skip_order", "Skip"], ["ring_bell", "Bell"],
		["reset_bike", "Reset"], ["toggle_insurance", "Insure"], ["pause", "Pause"]]
	for i in extras.size():
		_add(extras[i][0], extras[i][1], Rect2(w / 2 - 325 + i * 132, h - 136, 122, 112))
	_surface.queue_redraw()


func _update_css_scale() -> void:
	_css_scale = get_viewport().get_final_transform().get_scale().abs()
	if OS.has_feature("web"):
		# Measure the actual game rectangle, including safe-area padding. CSS
		# pixels stay finger-sized regardless of the Retina backing resolution.
		var result: Variant = JavaScriptBridge.eval("(() => { const c = document.getElementById('canvas'); if (!c) return ''; const r = c.getBoundingClientRect(); return JSON.stringify({width:r.width,height:r.height}); })()")
		if result is String and result != "":
			var rect: Variant = JSON.parse_string(result)
			if rect is Dictionary and rect.get("width", 0) > 0 and rect.get("height", 0) > 0:
				var logical := get_viewport().get_visible_rect().size
				_css_scale = Vector2(float(rect.width) / logical.x, float(rect.height) / logical.y)
	_css_scale.x = maxf(_css_scale.x, 0.01)
	_css_scale.y = maxf(_css_scale.y, 0.01)


func fit_touch_widget(control: Control) -> void:
	if touch_enabled:
		_resize_touch_widgets(control)


func _resize_touch_widgets(node: Node) -> void:
	# Keep the desktop layout untouched. Store original values once so rotating
	# back to landscape can shrink a portrait target to the appropriate size.
	if node is BaseButton or node is LineEdit or node is Slider:
		var control := node as Control
		if not control.has_meta("touch_original_minimum"):
			control.set_meta("touch_original_minimum", control.custom_minimum_size)
		var original: Vector2 = control.get_meta("touch_original_minimum")
		control.custom_minimum_size = Vector2(
			maxf(original.x, ceilf(MIN_TOUCH_TARGET / _css_scale.x)),
			maxf(original.y, ceilf(MIN_TOUCH_TARGET / _css_scale.y)))
		if node is BaseButton or node is LineEdit:
			if not control.has_meta("touch_original_font_size"):
				control.set_meta("touch_original_font_size", control.get_theme_font_size("font_size"))
			var original_font: int = control.get_meta("touch_original_font_size")
			var font_size := maxi(original_font, ceili(MIN_WIDGET_TEXT / _css_scale.y))
			control.add_theme_font_size_override("font_size", font_size)
			if node is OptionButton:
				var popup := (node as OptionButton).get_popup()
				popup.add_theme_font_size_override("font_size", font_size)
				if not popup.has_meta("touch_original_separation"):
					popup.set_meta("touch_original_separation", popup.get_theme_constant("v_separation"))
				var font_height := popup.get_theme_font("font").get_height(font_size)
				var original_gap: int = popup.get_meta("touch_original_separation")
				popup.add_theme_constant_override("v_separation", maxi(original_gap,
					ceili(MIN_TOUCH_TARGET / _css_scale.y - font_height)))
				# OptionButton clamps its popup to the viewport and scrolls long lists.
	for child in node.get_children():
		_resize_touch_widgets(child)


func _add(action: String, label: String, rect: Rect2) -> void:
	_buttons.append({"action": action, "label": label, "rect": rect})


func _button_font_size(button: Dictionary) -> int:
	var font := ThemeDB.fallback_font
	var desired := ceili(16.0 / _css_scale.y)
	var minimum := ceili(14.0 / _css_scale.y)
	var available: float = button.rect.size.x - 4.0 / _css_scale.x
	while desired > minimum and font.get_string_size(button.label, HORIZONTAL_ALIGNMENT_LEFT, -1, desired).x > available:
		desired -= 1
	return desired


func _draw_buttons() -> void:
	var font := ThemeDB.fallback_font
	for button in _buttons:
		var held := _fingers.values().has(button.action)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.55, 0.16, 0.95) if held else Color(0.04, 0.16, 0.19, 0.85)
		style.border_color = Color(1, 0.95, 0.87, 0.65)
		style.set_border_width_all(2)
		style.set_corner_radius_all(20)
		_surface.draw_style_box(style, button.rect)
		var rect: Rect2 = button.rect
		var font_size := _button_font_size(button)
		var baseline := (rect.size.y - font.get_height(font_size)) / 2 + font.get_ascent(font_size)
		_surface.draw_string(font, rect.position + Vector2(0, baseline),
			button.label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color.WHITE)


func _make_room_for_controls() -> void:
	# Leave the maps, speed and tutorial readable above the bottom touch strip.
	# The adjustment belongs to this scene instance, never the saved desktop UI.
	for path in ["HUD/Panel", "Minimap/Panel"]:
		var panel := _scene.get_node_or_null(path) as Control
		if panel != null and not panel.has_meta("touch_raised"):
			panel.offset_top -= 300
			panel.offset_bottom -= 300
			panel.set_meta("touch_raised", true)
	var tutorial := _scene.get_node_or_null("Tutorial")
	if tutorial != null and tutorial.get_child_count() > 0:
		var panel := tutorial.get_child(0) as Control
		if panel != null and not panel.has_meta("touch_raised"):
			panel.offset_top -= 300
			panel.offset_bottom -= 300
			panel.set_meta("touch_raised", true)
