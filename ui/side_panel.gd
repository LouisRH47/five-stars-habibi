class_name SidePanel
extends CanvasLayer
## Reusable left-side shop/reception panel, leaving the 3D room visible.
## Session 71 (GameConfig.SCREENS_V2): it slides in from the left with a soft whoosh, and the
## progress bar and labels use the game's palette (UiPalette).

var rows: VBoxContainer
var heading: Label
var detail: Label
var footer: Label
var progress: ProgressBar
var _panel: PanelContainer
var _scroll: ScrollContainer
var _counter_mode := false
var _slide: Tween
const HOME := Vector2(28, 28)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 35
	_build()
	hide_panel()
	if GameConfig.SCREENS_V2:
		_restyle()
		visibility_changed.connect(_on_visibility_changed)


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = HOME
	_panel.size = Vector2(500, 720)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.12, 0.15, 0.95)
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)
	var banner := PanelContainer.new()
	var orange := style.duplicate() as StyleBoxFlat
	orange.bg_color = Color(0.95, 0.55, 0.16)
	banner.add_theme_stylebox_override("panel", orange)
	box.add_child(banner)
	heading = Label.new()
	heading.theme_type_variation = "Heading"
	heading.add_theme_color_override("font_color", Color(0.08, 0.1, 0.12))
	heading.add_theme_font_size_override("font_size", 26)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_child(heading)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size.y = 340
	_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(_scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 7)
	_scroll.add_child(rows)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 10
	box.add_child(progress)
	footer = Label.new()
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_color_override("font_color", Color(0.96, 0.81, 0.51))
	box.add_child(footer)


func clear_rows() -> void:
	_counter_mode = false
	_scroll.visible = true
	_panel.size.y = 720
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()


func add_row(text: String, status: String, selected := false, action: Callable = Callable()) -> Button:
	var row := Button.new()
	row.text = "%s    %s" % [text, status]
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.custom_minimum_size.y = 42
	row.focus_mode = Control.FOCUS_NONE
	if selected:
		var selected_style := StyleBoxFlat.new()
		selected_style.bg_color = Color(0.95, 0.7, 0.19)
		selected_style.set_corner_radius_all(9)
		selected_style.content_margin_left = 12
		row.add_theme_stylebox_override("normal", selected_style)
		row.add_theme_color_override("font_color", Color(0.08, 0.1, 0.12))
		_focus_row.call_deferred(row)
	if action.is_valid():
		row.pressed.connect(action)
	rows.add_child(row)
	get_tree().root.get_node("TouchControls").fit_touch_widget(row)
	return row


func _focus_row(row: Control) -> void:
	if is_instance_valid(row) and row.is_inside_tree() and _scroll.visible:
		# Keep the list at a fixed height. ensure_control_visible() can repeatedly
		# grow an unattached PanelContainer while its containers are sorting.
		_scroll.scroll_vertical = maxi(0, roundi(row.position.y - _scroll.size.y * 0.5))


func show_counter(title: String, copy: String, amount := 0.0) -> void:
	if not _counter_mode:
		clear_rows()
		_counter_mode = true
		_scroll.visible = false
	heading.text = title
	detail.text = copy
	progress.value = clampf(amount, 0.0, 1.0) * 100.0
	progress.visible = true
	footer.text = "Hold E · Esc to leave"
	visible = true


func hide_panel() -> void:
	visible = false


## Session 71: slides in from the left (x -40 to 0) and fades in, each time it opens.
func _on_visibility_changed() -> void:
	if _slide != null:
		_slide.kill()
	_panel.position = HOME
	_panel.modulate.a = 1.0
	if not visible:
		return
	var ui := get_tree().root.get_node_or_null("UiSounds")
	if ui != null:
		ui.play("whoosh", 1.15)
	if Settings.reduce_motion:
		return
	_panel.position = HOME - Vector2(GameConfig.SIDE_PANEL_SLIDE, 0)
	_panel.modulate.a = 0.0
	_slide = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_slide.tween_property(_panel, "position", HOME, GameConfig.SIDE_PANEL_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_slide.tween_property(_panel, "modulate:a", 1.0, GameConfig.SIDE_PANEL_TIME * 0.7)


## Session 71: the palette's panel colour, a rounded orange bar and softer detail text.
func _restyle() -> void:
	var style := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	style.bg_color = Color(UiPalette.PANEL, 0.93)
	style.border_color = Color(UiPalette.CYAN, 0.25)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	detail.add_theme_color_override("font_color", UiPalette.SOFT_TEXT)
	detail.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL)
	footer.add_theme_color_override("font_color", UiPalette.SUN)
	footer.add_theme_font_size_override("font_size", UiPalette.FONT_BODY)
	progress.custom_minimum_size.y = 14
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.12)
	back.set_corner_radius_all(7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiPalette.ORANGE
	fill.set_corner_radius_all(7)
	progress.add_theme_stylebox_override("background", back)
	progress.add_theme_stylebox_override("fill", fill)


func _process(_delta: float) -> void:
	if not visible:
		return
	# Wrapped labels briefly report a tall minimum before their width is laid out.
	# Let the panel shrink back once that first container sort has finished.
	var height := maxf(220.0 if _counter_mode else 720.0, _panel.get_combined_minimum_size().y)
	if not is_equal_approx(_panel.size.y, height):
		_panel.size.y = height
