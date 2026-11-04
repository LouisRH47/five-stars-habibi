extends Control
## The start screen (Session 21, like the mockup's "Start: rider application"): the main
## menu and the Snackaroo rider application on one screen. Left: "AL SARAB · السراب", the
## big title, "Rider to Driver" and one line about the game, in front of a low-poly 3D
## desert (dunes, a big pale sun, a palm). Right: a phone. On the menu the phone has Play
## (or Continue), New game, Settings and Quit. The first time you play, the phone becomes
## the rider application: name, where you're from, 3 look cards each with a little 3D rider,
## Submit application, then "Reviewing..." and "Congrats, you're hired!" and Start riding.
## Used by scenes/main_menu.tscn (opens on the menu) and scenes/application.tscn (opens
## straight on the form). The choices are in data/application.gd.

## Which phone page to open on: "menu" or "form".
@export var start_page := "menu"

const LIST := preload("res://data/application.gd")
const PALM_SCENE := preload("res://scenes/palm_tree.tscn")
const GAME_SCENE := "res://scenes/wahat_al_shams.tscn"

const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const SUN := Color(0.9490196, 0.69803923, 0.1882353, 1)
const SAND := Color(0.9529412, 0.8901961, 0.7647059, 1)
const INK := Color(0.105882354, 0.11372549, 0.13333334, 1)
const SOFT := Color(0.36, 0.42, 0.44, 1)
const WHITE := Color(1, 1, 1, 1)

## The form's fields (the smoke test fills them in).
var name_box: LineEdit
var country_box: OptionButton
var look := 0
## Which page the phone shows: "menu", "form", "reviewing" or "hired".
var page := "menu"
var play_button: Button
var new_button: Button
var settings_panel: SettingsPanel

var _pages: Dictionary = {}       # page name -> Control
var _look_cards: Array[Button] = []
var _look_riders: Array[Node3D] = []
var _submit: Button
var _hired_text: Label
var _spinner: Control
var _desert_camera: Camera3D
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_build_desert())
	add_child(_build_title())
	var phone := _build_phone()
	add_child(phone)
	settings_panel = SettingsPanel.add_centered(self)
	settings_panel.closed.connect(func(): phone.visible = true)
	settings_panel.set_meta("phone", phone)
	_show_page(start_page)
	_pick_look(GameState.rider_look)


func _process(delta: float) -> void:
	_time += delta
	if _spinner.visible:
		_spinner.rotation += delta * 6.0
	for rider in _look_riders:
		rider.rotation.y = sin(_time * 0.8) * 0.6
	if _desert_camera != null:  # a slow drift over the dunes
		_desert_camera.position.x = sin(_time * 0.05) * 3.0


# --- What the buttons do ---

## Where Play takes you: Wahat Al Shams once you're hired, the application first.
func play_scene() -> String:
	return GAME_SCENE if GameState.hired else "form"


## Play / Continue: straight into the game if you're hired, otherwise the application.
func play() -> void:
	if GameState.hired:
		_open_game(false)
	else:
		_show_page("form")


## Starts over from the application (your save is wiped).
func new_game() -> void:
	GameState.new_game()
	play_button.text = "Play"
	new_button.visible = false
	_show_page("form")


func quit() -> void:
	GameState.save_game()
	get_tree().quit()


func _open_settings() -> void:
	(settings_panel.get_meta("phone") as Control).visible = false
	settings_panel.visible = true


## Submit application: check the name, then "Reviewing..." for a moment, then hired.
func submit() -> bool:
	var rider := name_box.text.strip_edges()
	if rider == "" or page != "form":
		return false
	GameState.hire(rider, country_box.get_item_text(country_box.selected), look)
	_show_page("reviewing")
	get_tree().create_timer(GameConfig.APPLICATION_REVIEW_TIME).timeout.connect(finish_review)
	return true


## The review is done: always accepted.
func finish_review() -> void:
	if page != "reviewing":
		return
	_hired_text.text = "Congrats, %s, you're hired!" % GameState.rider_name
	_show_page("hired")


## "Start riding": off to Wahat Al Shams (the tutorial starts there).
func start_riding() -> void:
	_open_game(true)


## Session 53: behind the loading screen. Every button is switched off on the first click, so
## clicking again (or pressing Enter) can't start a second load.
func _open_game(first_shift: bool) -> void:
	if Loader.busy:
		return
	for button in find_children("*", "Button", true, false):
		(button as Button).disabled = true
	Loader.go_to_game(first_shift)


func _pick_look(number: int) -> void:
	look = number
	for i in _look_cards.size():
		_look_cards[i].button_pressed = i == number


func _show_page(which: String) -> void:
	page = which
	for key in _pages:
		_pages[key].visible = key == which
	_spinner.visible = which == "reviewing"
	if which == "menu" and play_button != null:
		play_button.grab_focus.call_deferred()


# --- The 3D desert behind the title ---

func _build_desert() -> Control:
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	view.own_world_3d = true
	frame.add_child(view)
	var world := Node3D.new()
	view.add_child(world)
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.31, 0.66, 0.84)
	sky_material.sky_horizon_color = Color(0.98, 0.86, 0.66)
	sky_material.ground_horizon_color = Color(0.98, 0.86, 0.66)
	sky_material.ground_bottom_color = Color(0.85, 0.7, 0.45)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.98, 0.86, 0.66)
	environment.fog_density = 0.004
	var lights := WorldEnvironment.new()
	lights.environment = environment
	world.add_child(lights)
	var sun_light := DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-25, -150, 0)
	sun_light.light_color = Color(1, 0.9, 0.75)
	sun_light.shadow_enabled = true
	world.add_child(sun_light)
	# The big pale sun, low over the dunes.
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1, 0.96, 0.82)
	var disc := SphereMesh.new()
	disc.radius = 14.0
	disc.height = 28.0
	disc.material = glow
	var sun_ball := MeshInstance3D.new()
	sun_ball.mesh = disc
	sun_ball.position = Vector3(-35, 16, -140)
	world.add_child(sun_ball)
	# Dunes: big squashed sand balls in a few warm shades.
	var shades := [Color(0.93, 0.8, 0.58), Color(0.89, 0.74, 0.5), Color(0.96, 0.85, 0.65)]
	var dunes := [[Vector3(-40, -10, -60), 36.0], [Vector3(30, -12, -80), 44.0], [Vector3(0, -14, -30), 30.0],
			[Vector3(-80, -16, -110), 50.0], [Vector3(70, -15, -40), 34.0], [Vector3(10, -40, -5), 44.0]]
	for i in dunes.size():
		var dune := LowPoly.sphere(world, dunes[i][1], dunes[i][1] * 0.6, shades[i % shades.size()], dunes[i][0])
		dune.scale = Vector3(1.6, 1.0, 1.0)
	var palm: Node3D = PALM_SCENE.instantiate()
	world.add_child(palm)
	palm.setup(2)
	palm.position = Vector3(9, 1.0, -22)
	palm.scale = Vector3.ONE * 1.4
	_desert_camera = Camera3D.new()
	_desert_camera.fov = 55.0
	world.add_child(_desert_camera)
	_desert_camera.position = Vector3(0, 6, 12)
	_desert_camera.rotation_degrees = Vector3(-4, 0, 0)
	return frame


# --- The title on the left ---

func _build_title() -> Control:
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.offset_left = 140
	column.offset_right = 900
	column.add_theme_constant_override("separation", 6)
	column.add_child(_label("AL SARAB  ·  السراب", 26, TEAL, "Heading"))
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", -120)  # Baloo 2 has tall lines: pull them together
	for word in ["Five Stars", "Habibi"]:
		var line_label := _label(word, 128, WHITE, "Heading")
		line_label.add_theme_color_override("font_outline_color", TEAL)
		line_label.add_theme_constant_override("outline_size", 18)
		title.add_child(line_label)
	column.add_child(title)
	column.add_child(_label("Rider to Driver", 44, ORANGE, "Heading"))
	var line := _label("Deliver food by bike in a sunny desert city, earn your stars, and work your way up to luxury chauffeur.", 24, INK)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(620, 0)
	column.add_child(line)
	return column


# --- The phone on the right ---

func _build_phone() -> Control:
	var phone := PanelContainer.new()
	phone.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	phone.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	phone.grow_vertical = Control.GROW_DIRECTION_BOTH
	phone.offset_right = -150
	phone.custom_minimum_size = Vector2(520, 900)
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE
	style.border_color = INK
	style.set_border_width_all(10)
	style.set_corner_radius_all(48)
	style.set_content_margin_all(38)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 10)
	phone.add_theme_stylebox_override("panel", style)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	phone.add_child(rows)
	var header := HBoxContainer.new()
	header.add_child(_label("Snackaroo", 40, ORANGE, "Heading"))
	rows.add_child(header)
	_spinner = Control.new()  # made here so _show_page can always reach it
	_pages["menu"] = _build_menu()
	_pages["form"] = _build_form()
	_pages["reviewing"] = _build_reviewing()
	_pages["hired"] = _build_hired()
	for key in _pages:
		_pages[key].size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.add_child(_pages[key])
	return phone


func _build_menu() -> VBoxContainer:
	var part := VBoxContainer.new()
	part.alignment = BoxContainer.ALIGNMENT_CENTER
	part.add_theme_constant_override("separation", 16)
	part.add_child(_label("Your delivery app", 22, SOFT))
	play_button = _button(part, "Continue" if GameState.hired else "Play", play, 32)
	new_button = _button(part, "New game", new_game, 26)
	new_button.visible = GameState.hired
	_button(part, "Settings", _open_settings, 26)
	_button(part, "Quit", quit, 26)
	return part


func _build_form() -> VBoxContainer:
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 8)
	form.add_child(_label("Rider Application", 26, TEAL, "Heading"))
	form.add_child(_label("What's your name?", 18, INK))
	name_box = LineEdit.new()
	name_box.placeholder_text = "Customers will call you this"
	name_box.max_length = GameConfig.RIDER_NAME_MAX
	name_box.add_theme_font_size_override("font_size", 20)
	name_box.text_changed.connect(func(text): _submit.disabled = text.strip_edges() == "")
	form.add_child(name_box)
	form.add_child(_label("Where are you from?", 18, INK))
	country_box = OptionButton.new()
	country_box.add_theme_font_size_override("font_size", 18)
	for country in LIST.COUNTRIES:
		country_box.add_item(country)
	form.add_child(country_box)
	form.add_child(_label("Pick your look", 18, INK))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	for i in LIST.LOOKS.size():
		cards.add_child(_build_look_card(i))
	form.add_child(cards)
	_submit = _button(form, "Submit application", submit, 26)
	_submit.disabled = true
	return form


## One look card: a little 3D rider in that look, its name and what it wears.
func _build_look_card(number: int) -> Button:
	var card := Button.new()
	card.toggle_mode = true
	card.custom_minimum_size = Vector2(140, 280)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "focus"]:
		var plain := StyleBoxFlat.new()
		plain.bg_color = SAND
		plain.set_corner_radius_all(18)
		if state == "focus":
			plain.draw_center = false
		card.add_theme_stylebox_override(state, plain)
	var picked := StyleBoxFlat.new()
	picked.bg_color = Color(1, 0.93, 0.82)
	picked.border_color = ORANGE
	picked.set_border_width_all(5)
	picked.set_corner_radius_all(18)
	card.add_theme_stylebox_override("pressed", picked)
	card.add_theme_stylebox_override("hover_pressed", picked)
	card.pressed.connect(_pick_look.bind(number))
	var inside := VBoxContainer.new()
	inside.set_anchors_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 6
	inside.offset_right = -6
	inside.offset_top = 6
	inside.offset_bottom = -6
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inside)
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.custom_minimum_size = Vector2(0, 140)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	frame.add_child(view)
	var rider := Walker.build_model()
	view.add_child(rider)
	RiderLook.apply(rider, number)
	_look_riders.append(rider)
	var camera := Camera3D.new()
	camera.fov = 30.0
	view.add_child(camera)
	camera.look_at_from_position(Vector3(0, 1.3, -4.2), Vector3(0, 1.0, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, 160, 0)
	view.add_child(light)
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.75, 0.75, 0.75)
	view.add_child(ambient)
	inside.add_child(frame)
	var name_label := _label(LIST.LOOKS[number]["name"], 20, TEAL, "Heading")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inside.add_child(name_label)
	var about := _label(LIST.LOOKS[number]["about"], 13, SOFT)
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inside.add_child(about)
	_look_cards.append(card)
	return card


func _build_reviewing() -> VBoxContainer:
	var part := VBoxContainer.new()
	part.alignment = BoxContainer.ALIGNMENT_CENTER
	part.add_theme_constant_override("separation", 24)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 90)
	_spinner.custom_minimum_size = Vector2(70, 70)
	_spinner.pivot_offset = Vector2(35, 35)
	_spinner.draw.connect(func(): _spinner.draw_arc(Vector2(35, 35), 30.0, 0.0, PI * 1.4, 32, ORANGE, 7.0, true))
	holder.add_child(_spinner)
	part.add_child(holder)
	var text := _label("Reviewing...", 30, INK, "Heading")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	part.add_child(text)
	return part


func _build_hired() -> VBoxContainer:
	var part := VBoxContainer.new()
	part.alignment = BoxContainer.ALIGNMENT_CENTER
	part.add_theme_constant_override("separation", 24)
	_hired_text = _label("Congrats, you're hired!", 38, ORANGE, "Heading")
	_hired_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hired_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	part.add_child(_hired_text)
	var boss := _label("Your boss has a first order ready for you. Grab your bike!", 20, SOFT)
	boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	part.add_child(boss)
	_button(part, "Start riding", start_riding, 30)
	return part


func _button(parent: Control, text: String, action: Callable, size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", size)
	button.custom_minimum_size = Vector2(0, 64)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _label(text: String, size: int, colour: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if variation != "":
		label.theme_type_variation = variation
	return label
