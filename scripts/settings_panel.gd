class_name SettingsPanel
extends PanelContainer
## The Settings box, used by the main menu and the pause menu. Changes are saved straight
## away (scripts/settings.gd). Back closes it.
## Session 71: a second column, "Accessibility": Text size (100 / 115 / 130%), Colour help,
## Less motion and Mini-map (Turns with you / North up). The values are made in Session 66.

## Sent when you press Back.
signal closed


## Makes a Settings box sitting in the middle of the screen, inside `parent`. Hidden at first.
static func add_centered(parent: Node) -> SettingsPanel:
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	var panel := SettingsPanel.new()
	panel.visible = false
	holder.add_child(panel)
	return panel

const PANEL_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 0.97)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const TEXT := Color(1, 0.95, 0.87, 1)

var rows: VBoxContainer
var fullscreen_box: CheckButton
## Low / Medium / High (Session 28).
var graphics_option: OptionButton
## One slider per sound bus (Master, Music, Effects, Ambience), 0 to 100.
var volume_sliders: Dictionary = {}
## Session 71: the Accessibility column.
var access_rows: VBoxContainer
var text_size_option: OptionButton
var colour_box: CheckButton
var motion_box: CheckButton
var minimap_option: OptionButton
var _swatches: Array[ColorRect] = []


func _ready() -> void:
	Settings.load_once()
	custom_minimum_size = Vector2(460, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOUR
	style.border_color = TEAL
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(32)
	add_theme_stylebox_override("panel", style)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 16)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ORANGE)
	var columns: HBoxContainer = null
	var outer: VBoxContainer = null
	if GameConfig.SCREENS_V2:
		# Session 71: the title on top, then two columns side by side, then Back.
		style.bg_color = Color(UiPalette.PANEL, 0.97)
		title.theme_type_variation = "Heading"
		title.add_theme_font_size_override("font_size", UiPalette.FONT_TITLE + 6)
		outer = VBoxContainer.new()
		outer.add_theme_constant_override("separation", 14)
		add_child(outer)
		outer.add_child(title)
		columns = HBoxContainer.new()
		columns.add_theme_constant_override("separation", 28)
		outer.add_child(columns)
		rows.custom_minimum_size = Vector2(400, 0)
		columns.add_child(rows)
		rows.add_child(_section("Screen and sound"))
	else:
		add_child(rows)
		rows.add_child(title)
	fullscreen_box = CheckButton.new()
	fullscreen_box.text = "Fullscreen"
	fullscreen_box.add_theme_font_size_override("font_size", 20)
	fullscreen_box.button_pressed = Settings.fullscreen
	fullscreen_box.toggled.connect(_on_fullscreen)
	rows.add_child(fullscreen_box)
	rows.add_child(_make_graphics_row())
	for bus in Settings.BUSES:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "Volume" if bus == "Master" else bus
		name_label.custom_minimum_size = Vector2(130, 0)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", TEXT)
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.value = Settings.volumes[bus] * 100.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(_on_volume.bind(bus))
		row.add_child(slider)
		rows.add_child(row)
		volume_sliders[bus] = slider
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_on_back)
	if columns != null:
		var line := VSeparator.new()
		line.add_theme_constant_override("separation", 2)
		columns.add_child(line)
		columns.add_child(_make_access_column())
		back.custom_minimum_size = Vector2(220, 0)
		back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		outer.add_child(back)
	else:
		rows.add_child(back)
	visibility_changed.connect(_on_visibility_changed)


## The Graphics row (Session 28): Low / Medium / High.
func _make_graphics_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = "Graphics"
	name_label.custom_minimum_size = Vector2(130, 0)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", TEXT)
	row.add_child(name_label)
	graphics_option = OptionButton.new()
	graphics_option.add_theme_font_size_override("font_size", 20)
	graphics_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for level_name in Settings.GRAPHICS_NAMES:
		graphics_option.add_item(level_name)
	graphics_option.selected = Settings.graphics
	graphics_option.item_selected.connect(_on_graphics)
	row.add_child(graphics_option)
	return row


func _on_graphics(level: int) -> void:
	Settings.graphics = level
	Settings.save()


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.save()


func _on_volume(value: float, bus: String) -> void:
	Settings.volumes[bus] = value / 100.0
	Settings.save()


func _on_back() -> void:
	visible = false
	if GameConfig.SCREENS_V2:
		load("res://scripts/polish/screen_extras.gd").sound("ui_close")
	closed.emit()


func _on_visibility_changed() -> void:
	if visible and is_inside_tree() and GameConfig.SCREENS_V2:
		_sync()
		load("res://scripts/polish/screen_extras.gd").open_panel(self)


# --- Session 71: Accessibility ---

func _make_access_column() -> VBoxContainer:
	access_rows = VBoxContainer.new()
	access_rows.name = "Accessibility"
	access_rows.custom_minimum_size = Vector2(400, 0)
	access_rows.add_theme_constant_override("separation", 16)
	access_rows.add_child(_section("Accessibility"))
	text_size_option = _option_row(access_rows, "Text size", ["100%", "115%", "130%"], Settings.text_size, _on_text_size)
	var colour_row := HBoxContainer.new()
	colour_box = _check(colour_row, "Colour help", Settings.colour_assist, _on_colour_help)
	colour_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colour_box.tooltip_text = "Blue, orange and red-orange that colour-blind players can tell apart"
	for i in 3:  # a little preview of the meter colours
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(18, 18)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		colour_row.add_child(swatch)
		_swatches.append(swatch)
	access_rows.add_child(colour_row)
	var motion_row := HBoxContainer.new()
	motion_box = _check(motion_row, "Less motion", Settings.reduce_motion, _on_less_motion)
	motion_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	motion_box.tooltip_text = "No shaking, speed lines or zoom, and quicker pops"
	access_rows.add_child(motion_row)
	minimap_option = _option_row(access_rows, "Mini-map", ["Turns with you", "North up"], 1 if Settings.minimap_north_up else 0, _on_minimap)
	var note := Label.new()
	note.text = "Saved straight away."
	note.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	note.add_theme_color_override("font_color", UiPalette.SOFT_TEXT)
	access_rows.add_child(note)
	_sync()
	return access_rows


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = "Heading"
	label.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL + 2)
	label.add_theme_color_override("font_color", UiPalette.CYAN)
	return label


func _option_row(parent: Control, text: String, items: Array, selected: int, action: Callable) -> OptionButton:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = text
	name_label.custom_minimum_size = Vector2(130, 0)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", TEXT)
	row.add_child(name_label)
	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", 20)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		option.add_item(item)
	option.selected = selected
	option.item_selected.connect(action)
	row.add_child(option)
	parent.add_child(row)
	return option


func _check(parent: Control, text: String, on: bool, action: Callable) -> CheckButton:
	var box := CheckButton.new()
	box.text = text
	box.add_theme_font_size_override("font_size", 20)
	box.add_theme_color_override("font_color", TEXT)
	box.add_theme_color_override("font_hover_color", Color.WHITE)
	box.add_theme_color_override("font_pressed_color", TEXT)
	box.button_pressed = on
	box.toggled.connect(action)
	parent.add_child(box)
	return box


## Shows the saved values (another screen may have changed them).
func _sync() -> void:
	if access_rows == null:
		return
	text_size_option.selected = Settings.text_size
	colour_box.set_pressed_no_signal(Settings.colour_assist)
	motion_box.set_pressed_no_signal(Settings.reduce_motion)
	minimap_option.selected = 1 if Settings.minimap_north_up else 0
	for i in _swatches.size():
		_swatches[i].color = UiPalette.band_colour(i)


func _on_text_size(index: int) -> void:
	Settings.text_size = clampi(index, 0, Settings.TEXT_SCALES.size() - 1)
	Settings.save()
	Settings.apply_text_size(get_tree().root)  # straight away (Settings.apply skips it in tests)


func _on_colour_help(on: bool) -> void:
	Settings.colour_assist = on
	Settings.save()
	_sync()


func _on_less_motion(on: bool) -> void:
	Settings.reduce_motion = on
	Settings.save()


func _on_minimap(index: int) -> void:
	Settings.minimap_north_up = index == 1
	Settings.save()
