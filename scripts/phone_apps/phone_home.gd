class_name PhoneHome
extends VBoxContainer
## Session 89: the big phone's home screen (on the teal wallpaper): the game clock, the
## shift and kind of day, 7 app icons in a 3-column grid (Messages has a red unread
## badge, Company shows your company's logo) and a dock with your money, stars and level.
## Arrow keys move a white ring between the icons; the shell (scripts/phone_app.gd) opens
## the ringed one on E. Clicking an icon sends app_chosen too.

signal app_chosen(id: String)

## The apps in grid order: id, name, square colour, drawn picture, picture colour, accent.
const APPS := [
	["jobs", "Jobs", Color("f28c28"), "bike", Color.WHITE, Color("f28c28")],
	["profile", "Profile", Color("0f4c5c"), "star", Color("f2b230"), Color.WHITE],
	["collection", "Collection", Color("f2b230"), "bag", Color("d8432f"), Color("a52a1c")],
	["messages", "Messages", Color("2fa84f"), "chat", Color.WHITE, Color("2fa84f")],
	["company", "Company", Color.WHITE, "logo", Color.WHITE, Color.WHITE],
	["map", "Map", Color("e9d9b5"), "map", Color("4f9fd6"), Color("cc4033")],
	["settings", "Settings", Color("5c6b70"), "gear", Color("e8ecec"), Color("5c6b70")],
]

var icons: Array[PhoneIcon] = []
var highlight := -1
var _clock: Label
var _date: Label
var _money: Label
var _rating: Label
var _level: Label


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	_clock = _centred(64, "Heading")
	_clock.custom_minimum_size.y = 76
	add_child(_clock)
	_date = _centred(18)
	_date.modulate = Color(1, 1, 1, 0.88)
	add_child(_date)
	var grid_margin := MarginContainer.new()
	for side in ["left", "right"]:
		grid_margin.add_theme_constant_override("margin_" + side, 14)
	grid_margin.add_theme_constant_override("margin_top", 34)
	add_child(grid_margin)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 22)
	grid_margin.add_child(grid)
	for app: Array in APPS:
		var icon := PhoneIcon.new()
		icon.name = "Icon_" + app[0]
		icon.app_id = app[0]
		icon.title = app[1]
		icon.background = app[2]
		icon.glyph = app[3]
		icon.glyph_colour = app[4]
		icon.glyph_accent = app[5]
		icon.outlined = app[0] == "profile"
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index := icons.size()
		icon.chosen.connect(func(): app_chosen.emit(icon.app_id))
		icon.hovered.connect(func(): set_highlight(index))
		grid.add_child(icon)
		icons.append(icon)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(gap)
	add_child(_make_dock())
	refresh()


## Fills in the clock, the day, the badge, the company logo and the dock.
func refresh() -> void:
	var state := get_tree().root.get_node("GameState")
	_clock.text = GameClock.format_time(state.clock_hours())
	_date.text = "Shift %d  ·  %s" % [maxi(state.shift_number, 1), state.day_label()]
	icon("messages").badge = unread_count()
	icon("company").logo = Companies.logo(Companies.current())
	icon("company").queue_redraw()
	_money.text = "Dh %d" % state.money
	_rating.text = "New" if state.history.is_empty() else "%.2f" % state.rating()
	_level.text = "Lv %d" % state.level()


## Unread messages, once the Messages app's data exists (0 until then).
func unread_count() -> int:
	var state := get_tree().root.get_node("GameState")
	return int(state.unread_messages()) if state.has_method("unread_messages") else 0


func icon(id: String) -> PhoneIcon:
	for each in icons:
		if each.app_id == id:
			return each
	return null


## Arrow keys: moves the ring by `step` (x = columns, y = rows). The first press only
## shows the ring on the first icon.
func move_highlight(step: Vector2i) -> void:
	if highlight < 0:
		set_highlight(0)
		return
	var columns := 3
	var target := highlight + step.x + step.y * columns
	if step.y != 0 and (target < 0 or target >= icons.size()):
		return
	set_highlight(clampi(target, 0, icons.size() - 1))


func set_highlight(index: int) -> void:
	highlight = index
	for i in icons.size():
		icons[i].selected = i == highlight


## The app under the ring ("" if none).
func highlighted_app() -> String:
	return icons[highlight].app_id if highlight >= 0 and highlight < icons.size() else ""


func _make_dock() -> Control:
	var dock := PanelContainer.new()
	var style := PhoneUI.flat(Color(1, 1, 1, 0.14), 0, 0)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	dock.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_child(line)
	_money = _dock_label(line)
	var star_box := HBoxContainer.new()
	star_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star_box.alignment = BoxContainer.ALIGNMENT_CENTER
	star_box.add_theme_constant_override("separation", 4)
	line.add_child(star_box)
	star_box.add_child(PhoneGlyph.make("star", Color("f2b230"), 20))
	_rating = _dock_label(star_box)
	_rating.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_level = _dock_label(line)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return dock


func _dock_label(parent: Control) -> Label:
	var made := PhoneUI.label("", 17, Color.WHITE, "BigNumber")
	made.autowrap_mode = TextServer.AUTOWRAP_OFF
	made.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(made)
	return made


func _centred(font_size: int, variation := "") -> Label:
	var made := PhoneUI.label("", font_size, Color.WHITE, variation)
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return made
