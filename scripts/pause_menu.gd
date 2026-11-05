extends CanvasLayer
## Esc pauses and resumes the game. The "Paused" panel has Resume, Settings,
## Main menu (saves first) and Quit (saves first), and a list of the keys.
## This node keeps running while the game is paused (process_mode = Always).
## Session 71 (GameConfig.SCREENS_V2): the game behind goes soft and blurry with a dark
## tint (the Blur node, assets/shaders/pause_blur.gdshader), the panel pops in with a sound.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const KEYS := "W / Up: pedal     S / Down: brake     A / D: steer\nShift: sprint     Space: handbrake     R: back to the start\nE: accept, pick up, drop off     Q: skip order     I: insurance on/off"

var settings_panel: SettingsPanel

@onready var _panel: Control = $Panel
@onready var _buttons: HBoxContainer = $Panel/Margin/Rows/Buttons
@onready var _blur: ColorRect = $Blur
@onready var _dim: Control = $Dim


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
	if GameConfig.SCREENS_V2:
		_restyle(keys)


## Session 71: the Paused card in the game's style (big rounded title, a shadow, an orange
## top edge, the keys in a soft box), and the blur's numbers from GameConfig.
func _restyle(keys: Label) -> void:
	var material := _blur.material as ShaderMaterial
	material.set_shader_parameter("lod", GameConfig.PAUSE_BLUR_LOD)
	material.set_shader_parameter("tint_amount", GameConfig.PAUSE_TINT)
	var card := (_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	card.bg_color = Color("FFF6E8")
	card.border_color = UiPalette.ORANGE
	card.border_width_top = 8
	card.shadow_color = Color(0, 0, 0, 0.35)
	card.shadow_size = 26
	card.shadow_offset = Vector2(0, 10)
	_panel.add_theme_stylebox_override("panel", card)
	var title := $Panel/Margin/Rows/Title as Label
	title.theme_type_variation = "Heading"
	title.add_theme_font_size_override("font_size", UiPalette.FONT_BIG)
	title.add_theme_color_override("font_color", UiPalette.TEAL)
	var hint := $Panel/Margin/Rows/Hint as Label
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_BODY)
	hint.add_theme_color_override("font_color", Color(0.36, 0.42, 0.44))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UiPalette.SAND, 0.6)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(14)
	keys.add_theme_stylebox_override("normal", box)
	keys.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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
	_blur.visible = GameConfig.SCREENS_V2  # Session 71: the blur only shows while paused
	_dim.visible = not GameConfig.SCREENS_V2
	if GameConfig.SCREENS_V2:
		load("res://scripts/polish/screen_extras.gd").open_panel(_panel)


func _resume() -> void:
	get_tree().paused = false
	visible = false
	_blur.visible = false
	if GameConfig.SCREENS_V2:
		load("res://scripts/polish/screen_extras.gd").sound("ui_close")


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
