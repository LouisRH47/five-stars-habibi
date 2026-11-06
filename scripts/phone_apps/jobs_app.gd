extends VBoxContainer
## The phone's Jobs app (Session 89): choose which kinds of order you want offered
## (normal, fragile, VIP, far), see today's shift goals and the order you have now.
## The phone shell (scripts/phone_app.gd) puts this under its "‹ Jobs" header and calls
## refresh() each time the app opens. The choices live in GameState.order_filters.

const INK := Color("#1b1d22")
const SOFT := Color("#5c6b70")
const TEAL := Color("#0f4c5c")
const ORANGE := Color("#f28c28")
const GREEN := Color("#2fa84f")
const RED := Color("#cc4033")
const CARD := Color("#fbf6ec")
const LINE := Color("#efe6d4")
## The four toggle rows: the kind in GameState.order_filters and what the row says.
const KINDS := [
	["normal", "Normal orders"],
	["fragile", "Fragile (cakes)"],
	["vip", "VIP (bigger pay and tips)"],
	["far", "Far (other side of the map)"],
]
const NOTE := "At least one kind stays on. Turning one off just means you see fewer of them."

var _switches := {}  # kind -> its Switch
var _note: Label
var _goals: VBoxContainer
var _now: VBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	add_child(_small_caps("Offer me these orders"))
	for row in KINDS:
		add_child(_toggle_row(row[0], row[1]))
	_note = _text(NOTE, 12, SOFT)
	add_child(_note)
	add_child(_small_caps("Today's shift goals · +%d Dh each" % GameConfig.GOAL_BONUS))
	_goals = _card("GoalsCard")
	add_child(_goals.get_parent())
	add_child(_small_caps("Now"))
	_now = _card("NowCard")
	add_child(_now.get_parent())
	refresh()


## Shows the saved choices, this shift's goals and the order you have now.
func refresh() -> void:
	for kind in _switches:
		_switches[kind].set_pressed_no_signal(GameState.wants_order_kind(kind))
		_switches[kind].queue_redraw()
	_note.text = NOTE
	_note.add_theme_color_override("font_color", SOFT)
	_fill_goals()
	_fill_now()


func _toggle_row(kind: String, text: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Row_" + kind
	row.custom_minimum_size.y = 40
	var label := _text(text, 15, INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var switch := Switch.new()
	switch.name = "Switch"
	switch.toggled.connect(func(on): _on_toggled(kind, on))
	row.add_child(switch)
	_switches[kind] = switch
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(row)
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size.y = 1
	box.add_child(line)
	return box


func _on_toggled(kind: String, on: bool) -> void:
	if not GameState.set_order_filter(kind, on):
		_switches[kind].set_pressed_no_signal(true)  # the last one on stays on
		_note.text = "You need at least one kind of order on."
		_note.add_theme_color_override("font_color", RED)
	_switches[kind].queue_redraw()


func _fill_goals() -> void:
	_clear(_goals)
	if GameState.shift_goals.is_empty():
		_goals.add_child(_text("No goals today.", 14, SOFT))
	var jobs := GameState.history.slice(GameState.shift_start_index)
	for id in GameState.shift_goals:
		var progress := ShiftGoals.progress(id, jobs, GameState.shift_crashes)
		var done := progress.x >= progress.y
		_goals.add_child(_pair(("✓  " if done else "•  ") + str(ShiftGoals.ALL.get(id, id)),
				"%d/%d" % [progress.x, progress.y], GREEN if done else INK))


func _fill_now() -> void:
	_clear(_now)
	var order: Order = GameState.current_order if GameState.current_order != null else GameState.offered_order
	if order == null:
		_now.add_child(_text("No order right now.", 14, SOFT))
		return
	_now.add_child(_text("%s → %s" % [order.restaurant_name, order.address], 15, INK, true))
	var chips := HBoxContainer.new()
	chips.add_child(_chip("%d Dh" % order.pay, GREEN))
	match GameState.stage:
		GameState.Stage.OFFERED: chips.add_child(_chip("New offer", ORANGE))
		GameState.Stage.TO_RESTAURANT: chips.add_child(_chip("Pick up", TEAL))
		GameState.Stage.TO_VILLA:
			var left := maxi(0, ceili(GameState.target_time - GameState.ride_time))
			chips.add_child(_chip("%d:%02d" % [left / 60, left % 60], ORANGE))
	if order.special != "":
		chips.add_child(_chip(GameConfig.SPECIAL_NAMES.get(order.special, order.special), SOFT))
	_now.add_child(chips)


# --- Small building blocks ---

func _small_caps(text: String) -> Label:
	var label := _text(text.to_upper(), 12, SOFT, true)
	label.add_theme_constant_override("line_spacing", 0)
	return label


func _text(text: String, size: int, colour: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", -4)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if bold:
		label.add_theme_font_override("font", Switch.bold_font())
	return label


## A line with text on the left and a bold number on the right.
func _pair(left: String, right: String, colour: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var a := _text(left, 14, colour)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	var number := _text(right, 14, colour, true)
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(number)
	return row


## A rounded sand card. Returns the VBox inside it (its parent is the card).
func _card(card_name: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.add_theme_stylebox_override("panel", _round(CARD, 16, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	return box


func _chip(text: String, colour: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _round(colour, 12, 8, 3))
	var label := _text(text, 12, Color.WHITE, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.add_child(label)
	return chip


static func _round(colour: Color, radius: int, pad_x: int, pad_y := -1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y if pad_y >= 0 else pad_x
	style.content_margin_bottom = pad_y if pad_y >= 0 else pad_x
	return style


static func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


## An on/off switch like a phone's: green with the knob on the right when on.
class Switch extends Button:
	static var _bold: FontVariation

	func _init() -> void:
		toggle_mode = true
		flat = true
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(44, 24)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _draw() -> void:
		var track := StyleBoxFlat.new()
		track.bg_color = GREEN if button_pressed else Color("#cfc6b6")
		track.set_corner_radius_all(12)
		draw_style_box(track, Rect2(Vector2.ZERO, size))
		var r := size.y * 0.5 - 3.0
		draw_circle(Vector2(size.x - r - 3.0 if button_pressed else r + 3.0, size.y * 0.5), r, Color.WHITE)

	## Nunito at its boldest, for headings inside the phone apps.
	static func bold_font() -> FontVariation:
		if _bold == null:
			_bold = FontVariation.new()
			_bold.base_font = load("res://assets/fonts/Nunito.ttf")
			_bold.fallbacks = [load("res://assets/fonts/NotoSansArabic.ttf")]
			_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
		return _bold
