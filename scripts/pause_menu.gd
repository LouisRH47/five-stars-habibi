extends CanvasLayer
## Esc pauses and resumes the game. The "Paused" panel has Resume, Settings,
## Main menu (saves first) and Quit (saves first), and a list of the keys.
## This node keeps running while the game is paused (process_mode = Always).

const MENU_SCENE := "res://scenes/main_menu.tscn"
const KEYS := "W / Up: pedal     S / Down: brake     A / D: steer\nShift: sprint     Space: handbrake     R: back to the start\nE: accept, pick up, drop off     Q: skip order     I: insurance on/off"

var settings_panel: SettingsPanel

@onready var _panel: Control = $Panel
@onready var _buttons: HBoxContainer = $Panel/Margin/Rows/Buttons


func _ready() -> void:
	visible = false
	$Panel/Margin/Rows/Buttons/Resume.pressed.connect(_resume)
	var quit := $Panel/Margin/Rows/Buttons/Quit as Button
	quit.text = "Quit game"
	quit.pressed.connect(quit_game)
	var settings := _add_button("Settings", _open_settings)
	_buttons.move_child(settings, 1)
	var menu := _add_button("Main menu", to_main_menu)
	_buttons.move_child(menu, 2)
	var keys := Label.new()
	keys.text = KEYS
	keys.add_theme_font_size_override("font_size", 15)
	keys.add_theme_color_override("font_color", Color(0.16, 0.33, 0.37, 1))
	$Panel/Margin/Rows.add_child(keys)
	settings_panel = SettingsPanel.add_centered(self)
	settings_panel.closed.connect(func(): _panel.visible = true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused and not visible:
			return  # something else paused the game (like the clinic screen): leave it
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


## Saves, then goes back to the main menu.
func to_main_menu() -> void:
	GameState.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


## Saves, then closes the game.
func quit_game() -> void:
	GameState.save_game()
	get_tree().quit()


func _pause() -> void:
	get_tree().paused = true
	visible = true
	_panel.visible = true
	settings_panel.visible = false


func _resume() -> void:
	get_tree().paused = false
	visible = false


func _open_settings() -> void:
	_panel.visible = false
	settings_panel.visible = true


func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	var resume := $Panel/Margin/Rows/Buttons/Resume as Button
	button.custom_minimum_size = resume.custom_minimum_size
	button.add_theme_font_size_override("font_size", resume.get_theme_font_size("font_size"))
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button
