extends Control
## The main menu (the game opens here): Play (or Continue if you have a save), New game,
## Settings and Quit, with a slowly turning bike in your look. Play goes to the rider
## application the first time, and straight to Palm Grove once you're hired.

const BIKE_SCENE := preload("res://scenes/bike.tscn")
const APPLICATION_SCENE := "res://scenes/application.tscn"
const GAME_SCENE := "res://scenes/palm_grove.tscn"

const SAND := Color(0.91, 0.83, 0.65, 1)
const DARK := Color(0.05882353, 0.1254902, 0.14901961, 1)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)

var play_button: Button
var new_button: Button
var settings_panel: SettingsPanel

var _buttons: VBoxContainer
var _bike: Node3D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = SAND
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	add_child(_build_bike_view())
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.offset_left = 160
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	column.add_child(_label("Five Stars Habibi", 72, DARK))
	column.add_child(_label("From bike rider to luxury chauffeur in Al Sarab", 24, TEAL))
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	_buttons.custom_minimum_size = Vector2(360, 0)
	column.add_child(_buttons)
	play_button = _button("Continue" if GameState.hired else "Play", play)
	new_button = _button("New game", new_game)
	new_button.visible = GameState.hired
	_button("Settings", _open_settings)
	_button("Quit", quit)
	settings_panel = SettingsPanel.add_centered(self)
	settings_panel.closed.connect(func(): _buttons.visible = true)
	play_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	if _bike != null:
		_bike.rotate_y(delta * 0.4)


## Where Play takes you: the application the first time, Palm Grove after that.
func play_scene() -> String:
	return GAME_SCENE if GameState.hired else APPLICATION_SCENE


func play() -> void:
	get_tree().change_scene_to_file(play_scene())


## Starts over from the application (your save is wiped).
func new_game() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(APPLICATION_SCENE)


func quit() -> void:
	GameState.save_game()
	get_tree().quit()


func _open_settings() -> void:
	_buttons.visible = false
	settings_panel.visible = true


func _build_bike_view() -> Control:
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	frame.offset_left = -900
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	frame.add_child(view)
	_bike = BIKE_SCENE.instantiate()
	_bike.process_mode = Node.PROCESS_MODE_DISABLED
	view.add_child(_bike)
	var camera := Camera3D.new()
	camera.fov = 40.0
	view.add_child(camera)
	camera.look_at_from_position(Vector3(5.0, 2.4, 1.2), Vector3(0, 0.9, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 50, 0)
	view.add_child(sun)
	var light := WorldEnvironment.new()
	light.environment = Environment.new()
	light.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	light.environment.ambient_light_color = Color(0.7, 0.7, 0.7, 1)
	view.add_child(light)
	return frame


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 28)
	button.custom_minimum_size = Vector2(0, 56)
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
