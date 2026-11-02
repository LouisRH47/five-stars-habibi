extends Control
## The Snackaroo rider application (PRD "Start of the game"), on a big phone screen:
## 1. your name (customers call you this), 2. where you're from, 3. pick one of 3 looks
## (a 3D preview shows your rider), then Submit, a short "Reviewing..." spinner and
## "Congrats, you're hired!". "Start riding" opens Palm Grove, where the tutorial starts.
## It always gets accepted: it's about the mood, not a challenge.
## The choices are in data/application.gd. GameState.hire() keeps what you picked.

const LIST := preload("res://data/application.gd")
const BIKE_SCENE := preload("res://scenes/bike.tscn")
const GAME_SCENE := "res://scenes/palm_grove.tscn"

const SAND := Color(0.91, 0.83, 0.65, 1)
const PHONE := Color(0.05882353, 0.1254902, 0.14901961, 1)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const SOFT := Color(0.79, 0.89, 0.92, 1)

## The form's fields (the smoke test fills them in).
var name_box: LineEdit
var country_box: OptionButton
var look := 0
## Which page is showing: "form", "reviewing" or "hired".
var page := "form"

var _look_buttons: Array[Button] = []
var _submit: Button
var _form: VBoxContainer
var _reviewing: VBoxContainer
var _hired: VBoxContainer
var _hired_text: Label
var _spinner: Control
var _preview_bike: Node3D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = SAND
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var phone := PanelContainer.new()
	phone.set_anchors_preset(Control.PRESET_CENTER)
	phone.grow_horizontal = Control.GROW_DIRECTION_BOTH
	phone.grow_vertical = Control.GROW_DIRECTION_BOTH
	phone.custom_minimum_size = Vector2(520, 900)
	var style := StyleBoxFlat.new()
	style.bg_color = PHONE
	style.border_color = TEAL
	style.set_border_width_all(6)
	style.set_corner_radius_all(40)
	style.set_content_margin_all(36)
	phone.add_theme_stylebox_override("panel", style)
	add_child(phone)
	var pages := VBoxContainer.new()
	phone.add_child(pages)
	pages.add_child(_label("Snackaroo", 40, ORANGE))
	pages.add_child(_label("Rider Application", 22, SOFT))
	_form = _build_form()
	_reviewing = _build_reviewing()
	_hired = _build_hired()
	for part in [_form, _reviewing, _hired]:
		part.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pages.add_child(part)
	_show_page("form")
	_pick_look(0)


func _process(delta: float) -> void:
	if _spinner.visible:
		_spinner.rotation += delta * 6.0
	if _preview_bike != null:
		_preview_bike.rotate_y(delta * 0.6)


## Submit: check the name, then "Reviewing..." for a moment, then you're hired.
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


## "Start riding": off to Palm Grove (the tutorial starts there).
func start_riding() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _pick_look(number: int) -> void:
	look = number
	for i in _look_buttons.size():
		_look_buttons[i].button_pressed = i == number
	if _preview_bike != null:
		RiderLook.apply(_preview_bike.get_node("Model"), number)


func _show_page(which: String) -> void:
	page = which
	_form.visible = which == "form"
	_reviewing.visible = which == "reviewing"
	_hired.visible = which == "hired"
	_spinner.visible = which == "reviewing"


func _build_form() -> VBoxContainer:
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	form.add_child(_label("1. What's your name?", 20, TEXT))
	name_box = LineEdit.new()
	name_box.placeholder_text = "Your name (customers call you this)"
	name_box.max_length = GameConfig.RIDER_NAME_MAX
	name_box.add_theme_font_size_override("font_size", 20)
	name_box.text_changed.connect(func(text): _submit.disabled = text.strip_edges() == "")
	form.add_child(name_box)
	form.add_child(_label("2. Where are you from?", 20, TEXT))
	country_box = OptionButton.new()
	country_box.add_theme_font_size_override("font_size", 18)
	for country in LIST.COUNTRIES:
		country_box.add_item(country)
	form.add_child(country_box)
	form.add_child(_label("3. Pick your look", 20, TEXT))
	var looks := HBoxContainer.new()
	looks.add_theme_constant_override("separation", 8)
	for i in LIST.LOOKS.size():
		var button := Button.new()
		button.toggle_mode = true
		button.text = "%s\n%s" % [LIST.LOOKS[i]["name"], LIST.LOOKS[i]["about"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(140, 80)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_pick_look.bind(i))
		looks.add_child(button)
		_look_buttons.append(button)
	form.add_child(looks)
	form.add_child(_build_preview())
	_submit = Button.new()
	_submit.text = "Submit"
	_submit.disabled = true
	_submit.add_theme_font_size_override("font_size", 24)
	_submit.pressed.connect(submit)
	form.add_child(_submit)
	return form


## A little 3D window with your rider on the bike, slowly turning.
func _build_preview() -> Control:
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.custom_minimum_size = Vector2(0, 260)
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	frame.add_child(view)
	_preview_bike = BIKE_SCENE.instantiate()
	_preview_bike.process_mode = Node.PROCESS_MODE_DISABLED  # just for show: no physics
	view.add_child(_preview_bike)
	var camera := Camera3D.new()
	camera.position = Vector3(2.6, 1.6, 0)
	camera.fov = 45.0
	view.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0, 1.0, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 50, 0)
	view.add_child(sun)
	var fill := WorldEnvironment.new()
	fill.environment = Environment.new()
	fill.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	fill.environment.ambient_light_color = Color(0.7, 0.7, 0.7, 1)
	view.add_child(fill)
	return frame


func _build_reviewing() -> VBoxContainer:
	var part := VBoxContainer.new()
	part.alignment = BoxContainer.ALIGNMENT_CENTER
	part.add_theme_constant_override("separation", 24)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 90)
	_spinner = Control.new()
	_spinner.custom_minimum_size = Vector2(70, 70)
	_spinner.pivot_offset = Vector2(35, 35)
	_spinner.draw.connect(func(): _spinner.draw_arc(Vector2(35, 35), 30.0, 0.0, PI * 1.4, 32, ORANGE, 7.0, true))
	holder.add_child(_spinner)
	part.add_child(holder)
	var text := _label("Reviewing your application...", 22, TEXT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	part.add_child(text)
	return part


func _build_hired() -> VBoxContainer:
	var part := VBoxContainer.new()
	part.alignment = BoxContainer.ALIGNMENT_CENTER
	part.add_theme_constant_override("separation", 24)
	_hired_text = _label("Congrats, you're hired!", 30, ORANGE)
	_hired_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	part.add_child(_hired_text)
	var boss := _label("Your boss has a first order ready for you. Grab your bike!", 20, SOFT)
	boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	part.add_child(boss)
	var go := Button.new()
	go.text = "Start riding"
	go.add_theme_font_size_override("font_size", 24)
	go.pressed.connect(start_riding)
	part.add_child(go)
	return part


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
