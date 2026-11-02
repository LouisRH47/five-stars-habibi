class_name SettingsPanel
extends PanelContainer
## The Settings box, used by the main menu and the pause menu. Changes are saved straight
## away (scripts/settings.gd). Back closes it.

## Sent when you press Back.
signal closed

const PANEL_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 0.97)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const TEXT := Color(1, 0.95, 0.87, 1)

var rows: VBoxContainer
var fullscreen_box: CheckButton


func _ready() -> void:
	Settings.load_once()
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
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
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_on_back)
	rows.add_child(back)


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.save()


func _on_back() -> void:
	visible = false
	closed.emit()
