class_name SettingsPanel
extends PanelContainer
## The Settings box, used by the main menu and the pause menu. Changes are saved straight
## away (scripts/settings.gd). Back closes it.

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
## One slider per sound bus (Master, Music, Effects, Ambience), 0 to 100.
var volume_sliders: Dictionary = {}


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
	add_child(rows)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ORANGE)
	rows.add_child(title)
	fullscreen_box = CheckButton.new()
	fullscreen_box.text = "Fullscreen"
	fullscreen_box.add_theme_font_size_override("font_size", 20)
	fullscreen_box.button_pressed = Settings.fullscreen
	fullscreen_box.toggled.connect(_on_fullscreen)
	rows.add_child(fullscreen_box)
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
	rows.add_child(back)


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.save()


func _on_volume(value: float, bus: String) -> void:
	Settings.volumes[bus] = value / 100.0
	Settings.save()


func _on_back() -> void:
	visible = false
	closed.emit()
