class_name PhoneApp
extends CanvasLayer
## Session 89: the big phone. Press P and it opens in the middle of the screen over a dark
## see-through shade, and the game pauses. The home screen (scripts/phone_apps/phone_home.gd)
## has 7 apps; each app is its own page script in scripts/phone_apps/<name>_app.gd.
## Keys: arrow keys + E (or a click) open an app, Esc goes back home (Esc on home closes),
## P always closes. Made by scripts/phone.gd, so every map with the corner phone has it.
##
## How an app page works (for whoever writes one): it `extends VBoxContainer`, builds
## itself in _ready(), and may have `func refresh()` (called each time the app opens),
## `signal close_phone` (closes the whole phone) and `func go_back() -> bool` (Esc or ‹
## inside the app: return true if the page went back a step itself, like chat -> list).

signal opened
signal closed
signal app_opened(id: String)

const APP_PATH := "res://scripts/phone_apps/%s_app.gd"

const STATUS_SCRIPT := preload("res://scripts/phone_apps/phone_status_bar.gd")
## The key action that opens and closes the phone (P; the touch HUD button sends it too).
const ACTION := "open_phone"

var showing := false
## The app on screen, or "" for the home screen.
var current_app := ""
var home: PhoneHome
var _pages: Dictionary = {}  # id -> page
var _root: Control
var _frame: Panel
var _wallpaper: TextureRect
var _status: Control
var _app_view: VBoxContainer
var _title: Label
var _scroll: ScrollContainer
var _page_holder: MarginContainer
var _home_bar: Panel


## Adds the "open_phone" action (the P key) if the project doesn't have it yet.
static func ensure_action() -> void:
	if InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_P
	InputMap.action_add_event(ACTION, key)


## The PhoneApp that `node` sits inside (for app pages), or null.
static func of(node: Node) -> PhoneApp:
	var at := node
	while at != null and not at is PhoneApp:
		at = at.get_parent()
	return at as PhoneApp


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_action()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.024, 0.027, GameConfig.PHONE_APP_SHADE)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	_root.add_child(_chip("Paused", Control.PRESET_TOP_LEFT, Vector2(24, 20)))
	_build_frame()
	_build_hints()
	var back_button := _app_view.get_node("Header/Back") as Button
	back_button.add_theme_font_override("font", _title.get_theme_font("font"))  # bold like the title
	_root.resized.connect(_fit)
	var state := get_tree().root.get_node("GameState")
	if state.has_signal("messages_changed"):
		state.connect("messages_changed", func(): if home != null: home.refresh())
	state.company_changed.connect(func(_id: String): if home != null: home.refresh())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION):
		if showing:
			close()
			get_viewport().set_input_as_handled()
		elif open():
			get_viewport().set_input_as_handled()
		return
	if not showing:
		return
	if event.is_action_pressed("pause"):
		back()
		get_viewport().set_input_as_handled()
	elif current_app == "" and (event is InputEventKey or event is InputEventJoypadButton):
		for pair in [["ui_left", Vector2i.LEFT], ["ui_right", Vector2i.RIGHT], ["ui_up", Vector2i.UP], ["ui_down", Vector2i.DOWN]]:
			if event.is_action_pressed(pair[0], true):
				home.move_highlight(pair[1])
				get_viewport().set_input_as_handled()
				return
		if (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")) and home.highlighted_app() != "":
			open_app(home.highlighted_app())
			get_viewport().set_input_as_handled()


## Opens the phone on the home screen and pauses the game. Not while something else has
## already paused it (the pause menu, a shop, the shift summary). True if it opened.
func open() -> bool:
	if showing or get_tree().paused:
		return false
	showing = true
	get_tree().paused = true
	_root.visible = true
	_fit()
	go_home()
	opened.emit()
	return true


## Closes the phone and lets the game run again.
func close() -> void:
	if not showing:
		return
	showing = false
	_root.visible = false
	current_app = ""
	get_tree().paused = false
	closed.emit()


## Back to the home screen (the app pages stay made, for next time).
func go_home() -> void:
	current_app = ""
	_app_view.visible = false
	home.visible = true
	_wallpaper.visible = true
	_set_ink(Color.WHITE)
	home.set_highlight(-1)
	home.refresh()


## Esc or ‹: a step back inside the app (if it has one), else home, else close.
func back() -> void:
	if current_app == "":
		close()
		return
	var page: Node = _pages.get(current_app)
	if page != null and page.has_method("go_back") and page.go_back():
		return
	go_home()


## Opens the app `id` ("jobs", "profile", "collection", "messages", "company", "map",
## "settings"). An app whose script isn't there yet shows "Coming soon".
func open_app(id: String) -> void:
	if not showing:
		return
	if not _pages.has(id):
		_pages[id] = _make_page(id)
	var page: Control = _pages[id]
	for each: Control in _pages.values():
		each.visible = each == page
	current_app = id
	home.visible = false
	_wallpaper.visible = false
	_app_view.visible = true
	_set_ink(PhoneUI.INK)
	for app: Array in PhoneHome.APPS:
		if app[0] == id:
			_title.text = app[1]
	if page.has_method("refresh"):
		page.refresh()
	_scroll.scroll_vertical = 0
	app_opened.emit(id)


## The page of an app (null if it hasn't been opened yet).
func page(id: String) -> Control:
	return _pages.get(id)


## Lets an app page change the title at the top (a chat shows the person's name).
func set_title(text: String) -> void:
	_title.text = text


## The Profile app's "Stamp card & neighbours" button: closes the phone and opens the old
## profile page (scripts/profile_page.gd), which pauses the game itself.
func open_profile_page() -> void:
	close()
	var profile := get_parent().get_node_or_null("ProfilePage") as ProfilePage
	if profile == null:
		profile = ProfilePage.new()
		profile.name = "ProfilePage"
		get_parent().add_child(profile)
	profile.open()


func _make_page(id: String) -> Control:
	var path := APP_PATH % id
	var script: Script = load(path) if ResourceLoader.exists(path) else null
	var made: Control
	if script != null and script.can_instantiate():
		made = script.new()
	else:
		made = VBoxContainer.new()
		made.add_theme_constant_override("separation", 14)
		var soon := PhoneUI.label("Coming soon", 26, PhoneUI.TEAL, "Heading")
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		made.add_child(soon)
		var note := PhoneUI.label("This app is still being built.", 17, PhoneUI.SOFT)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		made.add_child(note)
	made.name = id.capitalize() + "App"
	made.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if made.has_signal("close_phone"):
		made.connect("close_phone", close)
	_page_holder.add_child(made)
	return made


# --- Building the phone ---

func _build_frame() -> void:
	var size := GameConfig.PHONE_APP_SIZE
	_frame = Panel.new()
	_frame.name = "Frame"
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -size.x * 0.5
	_frame.offset_right = size.x * 0.5
	_frame.offset_top = -size.y * 0.5
	_frame.offset_bottom = size.y * 0.5
	var body := PhoneUI.flat(Color("11181b"), 54)
	body.shadow_color = Color(0, 0, 0, 0.4)
	body.shadow_size = 24
	body.shadow_offset = Vector2(0, 12)
	_frame.add_theme_stylebox_override("panel", body)
	_root.add_child(_frame)
	var screen := Panel.new()
	screen.name = "Screen"
	screen.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		screen.set_offset(side, 15.0 if side < 2 else -15.0)
	screen.add_theme_stylebox_override("panel", PhoneUI.flat(Color.WHITE, 40))
	_frame.add_child(screen)
	_wallpaper = TextureRect.new()
	_wallpaper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wallpaper.texture = _wallpaper_texture()
	_wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.add_child(_wallpaper)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	screen.add_child(column)
	_status = STATUS_SCRIPT.new()
	column.add_child(_status)
	home = PhoneHome.new()
	home.name = "Home"
	home.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home.app_chosen.connect(open_app)
	column.add_child(home)
	column.add_child(_build_app_view())
	var bar_holder := CenterContainer.new()
	bar_holder.custom_minimum_size.y = 26
	column.add_child(bar_holder)
	_home_bar = Panel.new()
	_home_bar.custom_minimum_size = Vector2(140, 6)
	_home_bar.add_theme_stylebox_override("panel", PhoneUI.flat(Color.WHITE, 3))
	bar_holder.add_child(_home_bar)


func _build_app_view() -> VBoxContainer:
	_app_view = VBoxContainer.new()
	_app_view.name = "AppView"
	_app_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_app_view.add_theme_constant_override("separation", 0)
	_app_view.visible = false
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 6)
	header.custom_minimum_size.y = 54
	_app_view.add_child(header)
	var back_button := Button.new()
	back_button.name = "Back"
	back_button.text = "‹"
	back_button.flat = true
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.custom_minimum_size = Vector2(52, 50)
	back_button.add_theme_font_size_override("font_size", 40)
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back_button.add_theme_color_override(colour, PhoneUI.TEAL)
	back_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	back_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	back_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	back_button.pressed.connect(back)
	header.add_child(back_button)
	_title = PhoneUI.label("", 30, PhoneUI.TEAL, "Heading")
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.clip_text = true
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var line := ColorRect.new()
	line.color = PhoneUI.LINE
	line.custom_minimum_size.y = 2
	_app_view.add_child(line)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_app_view.add_child(_scroll)
	_page_holder = MarginContainer.new()
	_page_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		_page_holder.add_theme_constant_override("margin_" + side, 22)
	_page_holder.add_theme_constant_override("margin_top", 16)
	_page_holder.add_theme_constant_override("margin_bottom", 16)
	_scroll.add_child(_page_holder)
	return _app_view


## The keys hint and a Close button under the phone (touch screens need the button).
func _build_hints() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.offset_top = -62
	row.offset_bottom = -14
	row.add_theme_constant_override("separation", 10)
	_root.add_child(row)
	row.add_child(_chip("Click an app (or arrow keys + E)  ·  Esc or P to close", -1, Vector2.ZERO))
	var close_button := PhoneUI.button("Close", PhoneUI.ORANGE, 17)
	close_button.custom_minimum_size = Vector2(96, 44)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	row.add_child(close_button)


## A dark rounded label, like the mock-up's "Paused" sign.
func _chip(text: String, preset: int, at: Vector2) -> Label:
	var chip := PhoneUI.label(text, 17, Color.WHITE)
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	var style := PhoneUI.flat(Color(0.06, 0.125, 0.15, 0.88), 14, 0)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	chip.add_theme_stylebox_override("normal", style)
	if preset >= 0:
		chip.set_anchors_preset(preset)
		chip.position = at
	return chip


func _wallpaper_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color("13606f"), Color("0f4c5c"), Color("0f4c5c").lerp(Color("f28c28"), 0.53)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.3, 0.0)
	texture.fill_to = Vector2(0.65, 1.0)
	texture.width = 64
	texture.height = 128
	return texture


## Text colour of the status bar and home bar: white on the wallpaper, dark on pages.
func _set_ink(colour: Color) -> void:
	var state := get_tree().root.get_node("GameState")
	var clock := GameClock.format_time(state.clock_hours())
	_status.time_text = clock.get_slice(" ", 0)
	_status.colour = colour
	(_home_bar.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = colour


## Shrinks the phone on short screens so it always fits with room for the hint below.
func _fit() -> void:
	var room := _root.size.y - GameConfig.PHONE_APP_MARGIN * 2.0
	var share := clampf(room / GameConfig.PHONE_APP_SIZE.y, 0.4, 1.0)
	_frame.pivot_offset = GameConfig.PHONE_APP_SIZE * 0.5
	_frame.scale = Vector2(share, share)
