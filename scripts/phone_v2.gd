class_name PhoneV2
extends RefCounted
## Session 70: the clearer phone (PRD "Polish pass", Phone). scripts/phone.gd still decides
## what to show; this only changes the look, so every node, name and text the tests read
## stays the same. Switch: GameConfig.PHONE_V2 (false = the Session 20 phone).
##   - bigger text (18 px body, 28 px titles at the 1920 x 1080 base), the status pill in the header
##   - wallet, stars and level hidden when the HUD chips show them (GameConfig.HUD_TOP_CHIPS)
##   - a new order: big pay, distance and minutes, the pick-up → drop-off line, a ring round E
##   - on a job: the place name big, the live distance, the two-step timeline, one orange
##     "what now" line with its key drawn as a keycap
##   - goals fold into a small "Goals 1/2" row (G or tap), insurance is a little shield

const GREY := Color(0.55, 0.6, 0.61, 1)
const SOFT := Color(0.36, 0.42, 0.44, 1)

var phone: CanvasLayer
var offer := PhoneOfferCard.new()
var distance: Label          # "180 m away" while riding to a stop
var goals_button: Button     # "Goals 1/2"
var profile_button: Button
var choice_pay: Array[Label] = []
var _card_style: StyleBoxFlat
var _hint_key: Keycap
var _hint_arrow: Control
var _wait_dots: Control
var _shield: Control
var _goals_toggled := false
var _tick_left := 0.0
var _step := -1
var _last_mode := ""
var _time := 0.0


func setup(owner: CanvasLayer) -> void:
	phone = owner
	var rows: VBoxContainer = phone.get_node("Panel/Margin/Rows")
	var panel: PanelContainer = phone.get_node("Panel")
	panel.custom_minimum_size.x = GameConfig.PHONE_V2_WIDTH
	panel.offset_left = -GameConfig.PHONE_V2_WIDTH - 24.0
	_card_style = (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	panel.add_theme_stylebox_override("panel", _card_style)
	rows.add_theme_constant_override("separation", 10)
	# The status pill moves up into the header, next to "Snackaroo".
	var header: HBoxContainer = phone.get_node("Panel/Margin/Rows/Header")
	var pill: Label = phone._pill
	pill.reparent(header, false)
	header.move_child(pill, 1)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill_style := pill.get_theme_stylebox("normal") as StyleBoxFlat
	pill_style.content_margin_top = 3
	pill_style.content_margin_bottom = 3
	pill_style.set_corner_radius_all(14)
	# Money, stars, level and streak: the HUD chips show them now.
	var on_hud := GameConfig.HUD_TOP_CHIPS
	for path in ["Header/Wallet", "Rider", "Profile", "XP"]:
		phone.get_node("Panel/Margin/Rows/" + path).visible = not on_hud and phone.get_node("Panel/Margin/Rows/" + path).visible
	phone._streak.visible = not on_hud
	_restyle_text()
	_build_distance(rows)
	_build_timeline()
	_build_note_tail()
	_build_hint_key()
	_build_wait_dots()
	offer.build(rows, phone._stops, phone._note)
	_build_footer(rows)
	_restyle_choices()


# --- Text sizes ---

func _restyle_text() -> void:
	var sizes := {
		"Header/Title": UiPalette.FONT_TITLE, "Pill": UiPalette.FONT_SMALL,
		"Status": UiPalette.FONT_TITLE, "Stops/PickUp": UiPalette.FONT_BODY, "Stops/DropOff": UiPalette.FONT_BODY,
		"Note": UiPalette.FONT_BODY, "Detail": UiPalette.FONT_BODY, "Hint": UiPalette.FONT_LABEL,
		"Insurance": UiPalette.FONT_SMALL, "Rider": UiPalette.FONT_SMALL, "Profile/Rating": UiPalette.FONT_SMALL,
		"Profile/Level": UiPalette.FONT_SMALL, "Goals": UiPalette.FONT_BODY, "EventBanner": UiPalette.FONT_BODY,
	}
	for path: String in sizes:
		var node := phone.get_node_or_null("Panel/Margin/Rows/" + path) as Label
		if node == null and path == "Pill":
			node = phone._pill
		if node != null:
			node.add_theme_font_size_override("font_size", sizes[path])
	phone._status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The Arabic fallback font makes lines very tall: pull lines of the same text closer.
	for label: Label in [phone._goals, phone._note, phone._detail, phone._status, phone._hint]:
		label.add_theme_constant_override("line_spacing", -12)
	for chip: Label in phone._chips.values():
		chip.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
		var style := chip.get_theme_stylebox("normal") as StyleBoxFlat
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		style.set_corner_radius_all(14)
	phone._chip_row.add_theme_constant_override("separation", 8)
	phone._streak.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	phone._gear_goal.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	phone._gear_goal.add_theme_color_override("font_color", SOFT)
	phone._gear_progress.custom_minimum_size.y = 6
	phone._result.star_size = 30.0
	var note := phone._note as Label
	note.add_theme_color_override("font_color", Color(0.33, 0.25, 0.05, 1))
	var note_style := (note.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
	note_style.set_corner_radius_all(16)
	note_style.content_margin_left = 14
	note_style.content_margin_right = 14
	note.add_theme_stylebox_override("normal", note_style)


func _build_distance(rows: VBoxContainer) -> void:
	distance = Label.new()
	distance.name = "Distance"
	distance.visible = false
	distance.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL)
	distance.add_theme_color_override("font_color", UiPalette.TEAL.lightened(0.15))
	rows.add_child(distance)
	rows.move_child(distance, phone._status.get_index() + 1)


# --- The pick-up → drop-off timeline: two dots joined by a dashed line, drawn on the left ---

func _build_timeline() -> void:
	var stops: VBoxContainer = phone._stops
	stops.add_theme_constant_override("separation", 6)
	for label: Label in [phone._pick_up, phone._drop_off]:
		var gutter := StyleBoxEmpty.new()
		gutter.content_margin_left = 28
		label.add_theme_stylebox_override("normal", gutter)
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stops.draw.connect(_draw_timeline)
	stops.sort_children.connect(stops.queue_redraw)


func set_stops(order: Order, step: int) -> void:
	var picked := step == 2
	_set_text(phone._pick_up, ("Picked up · %s" if picked else "Pick up · %s") % order.restaurant_name)
	_set_text(phone._drop_off, "Drop off · %s" % order.address)
	if step != _step:
		_step = step
		phone._stops.queue_redraw()


func _draw_timeline() -> void:
	var stops: VBoxContainer = phone._stops
	var a: Label = phone._pick_up
	var b: Label = phone._drop_off
	var top := Vector2(10, a.position.y + a.size.y * 0.5)
	var bottom := Vector2(10, b.position.y + b.size.y * 0.5)
	stops.draw_dashed_line(top + Vector2(0, 9), bottom - Vector2(0, 9), GREY, 2.0, 4.0)
	_draw_stop(stops, top, 0)
	_draw_stop(stops, bottom, 1)


## One dot: done (teal with a tick), now (orange with a white ring), or still to come.
func _draw_stop(canvas: CanvasItem, at: Vector2, which: int) -> void:
	var now := (_step == 1 and which == 0) or (_step == 2 and which == 1)
	var done := _step == 2 and which == 0
	if now:
		canvas.draw_circle(at, 9.0, UiPalette.ORANGE)
		canvas.draw_circle(at, 4.0, Color.WHITE)
	elif done:
		canvas.draw_circle(at, 8.0, UiPalette.TEAL)
		canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, 0), at + Vector2(-1, 3), at + Vector2(4, -3)]), Color.WHITE, 2.0, true)
	elif _step == 0:
		canvas.draw_circle(at, 7.0, UiPalette.TEAL if which == 0 else UiPalette.ORANGE)
	else:
		canvas.draw_circle(at, 7.0, GREY)
		canvas.draw_circle(at, 4.0, Color.WHITE)


## The customer's note as a speech bubble: a little tail on its top-left corner.
func _build_note_tail() -> void:
	var note: Label = phone._note
	note.draw.connect(func():
		var colour := (note.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
		note.draw_colored_polygon(PackedVector2Array([Vector2(22, 1), Vector2(30, -8), Vector2(38, 1)]), colour))


# --- The "what now" line: the key to press as a keycap (or an orange arrow) on its left ---

func _build_hint_key() -> void:
	var hint: Label = phone._hint
	var gutter := StyleBoxEmpty.new()
	gutter.content_margin_left = 40
	hint.add_theme_stylebox_override("normal", gutter)
	_hint_key = Keycap.new()
	_hint_key.name = "HintKey"
	_hint_key.key_size = 28.0
	_hint_key.visible = false
	hint.add_child(_hint_key)
	_hint_arrow = Control.new()
	_hint_arrow.name = "HintArrow"
	_hint_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_arrow.size = Vector2(28, 28)
	_hint_arrow.draw.connect(func():
		var c := _hint_arrow.get_parent().get_theme_color("font_color") as Color
		_hint_arrow.draw_colored_polygon(PackedVector2Array([Vector2(8, 6), Vector2(22, 14), Vector2(8, 22), Vector2(11, 14)]), c))
	hint.add_child(_hint_arrow)
	hint.resized.connect(_place_hint_key)
	hint.theme_changed.connect(_hint_arrow.queue_redraw)


func _place_hint_key() -> void:
	var hint: Label = phone._hint
	var line := minf(hint.size.y, hint.get_line_height(0) if hint.get_line_count() > 0 else hint.size.y)
	_hint_key.size = _hint_key.custom_minimum_size
	_hint_key.position = Vector2(0, (line - _hint_key.size.y) * 0.5)
	_hint_arrow.position = Vector2(0, (line - 28.0) * 0.5)


## The key a hint talks about: "Press F to get off" → F. "" if none.
static func hint_key(text: String) -> String:
	for word in text.replace(",", " ").split(" ", false):
		if word in ["E", "F", "Q"]:
			return word
	return ""


func _update_hint_key() -> void:
	var hint: Label = phone._hint
	var key := hint_key(hint.text)
	var lit: bool = hint.get_theme_color("font_color") == phone.HINT_LIT
	_hint_key.key_text = key if key != "" else _hint_key.key_text
	_hint_key.colour = UiPalette.ORANGE if lit else SOFT
	if _hint_key.visible != (key != ""):
		_hint_key.visible = key != ""
		_hint_arrow.visible = key == ""
		_place_hint_key()


# --- "Waiting for orders" with three bouncing dots ---

func _build_wait_dots() -> void:
	_wait_dots = Control.new()
	_wait_dots.name = "WaitDots"
	_wait_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wait_dots.size = Vector2(40, 30)
	_wait_dots.visible = false
	_wait_dots.draw.connect(func():
		for i in 3:
			var hop := 0.0 if Settings.reduce_motion else absf(sin(_time * 5.0 - i * 0.7)) * 6.0
			_wait_dots.draw_circle(Vector2(6 + i * 12, 22 - hop), 4.0, UiPalette.ORANGE))
	phone._status.add_child(_wait_dots)


func _place_wait_dots() -> void:
	var status: Label = phone._status
	var font := status.get_theme_font("font")
	var width := font.get_string_size(status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiPalette.FONT_TITLE).x
	_wait_dots.position = Vector2(width + 4.0, (status.get_line_height(0) - 30.0) * 0.5 + 2.0)


# --- Footer: goals fold and the profile button; insurance as a little shield ---

func _build_footer(rows: VBoxContainer) -> void:
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 10)
	goals_button = _key_button("Goals", "G")
	goals_button.name = "GoalsButton"
	goals_button.pressed.connect(toggle_goals)
	footer.add_child(goals_button)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(gap)
	for child in rows.get_children():
		if child is Button and child.get_parent() == rows:
			profile_button = child
	if profile_button != null:
		profile_button.reparent(footer, false)
		_style_key_button(profile_button, "Profile", "P")
	rows.add_child(footer)
	# At the bottom: goals and the next upgrade (folded away on a job), insurance, the footer.
	for node: Control in [phone._goals, phone._gear_goal, phone._gear_progress, phone._insurance, footer]:
		rows.move_child(node, rows.get_child_count() - 1)
	var insurance: Label = phone._insurance
	var gutter := StyleBoxEmpty.new()
	gutter.content_margin_left = 26
	gutter.content_margin_right = 34
	insurance.add_theme_stylebox_override("normal", gutter)
	_shield = Control.new()
	_shield.name = "Shield"
	_shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield.size = Vector2(20, 22)
	_shield.draw.connect(_draw_shield)
	insurance.add_child(_shield)
	var key := Keycap.new()
	key.name = "InsuranceKey"
	key.key_text = "I"
	key.key_size = 24.0
	insurance.add_child(key)
	insurance.resized.connect(func():
		key.size = key.custom_minimum_size
		key.position = Vector2(insurance.size.x - key.size.x, (insurance.size.y - key.size.y) * 0.5)
		_shield.position = Vector2(0, (insurance.size.y - 22.0) * 0.5))


func _draw_shield() -> void:
	var on := GameState.insurance_on
	var colour := UiPalette.TEAL if on else UiPalette.band_colour(2)
	var shape := PackedVector2Array([Vector2(10, 1), Vector2(19, 4), Vector2(18, 12), Vector2(10, 21), Vector2(2, 12), Vector2(1, 4)])
	_shield.draw_colored_polygon(shape, colour)
	if on:
		_shield.draw_polyline(PackedVector2Array([Vector2(6, 11), Vector2(9, 14), Vector2(14, 7)]), Color.WHITE, 2.0, true)
	else:
		_shield.draw_line(Vector2(6, 7), Vector2(14, 15), Color.WHITE, 2.0, true)
		_shield.draw_line(Vector2(14, 7), Vector2(6, 15), Color.WHITE, 2.0, true)


func show_insurance(on: bool) -> void:
	var insurance: Label = phone._insurance
	insurance.text = "Insurance ON  ·  %d Dh a job" % GameConfig.INSURANCE_PER_DELIVERY if on else "Insurance OFF"
	insurance.add_theme_color_override("font_color", SOFT if on else UiPalette.band_colour(2))
	if _shield != null:
		_shield.queue_redraw()


func _key_button(text: String, key: String) -> Button:
	var button := Button.new()
	_style_key_button(button, text, key)
	return button


## A small flat button with its key drawn as a keycap on the right.
func _style_key_button(button: Button, text: String, key: String) -> void:
	button.text = text
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = UiPalette.SAND if state != "hover" else UiPalette.SAND.darkened(0.06)
		style.set_corner_radius_all(12)
		style.content_margin_left = 12
		style.content_margin_right = 40
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		if state == "focus":
			style.draw_center = false
		button.add_theme_stylebox_override(state, style)
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(colour, UiPalette.INK)
	var cap := Keycap.new()
	cap.key_text = key
	cap.key_size = 22.0
	button.add_child(cap)
	button.resized.connect(func():
		cap.size = cap.custom_minimum_size
		cap.position = Vector2(button.size.x - cap.size.x - 8.0, (button.size.y - cap.size.y) * 0.5))
	button.pressed.connect(func(): UiJuice.press(button); UiSounds.play("ui_click"))


# --- Two orders to choose from: each card gets its key and its pay, big ---

func _restyle_choices() -> void:
	var box: HBoxContainer = phone._choices_box
	for index in box.get_child_count():
		var card := box.get_child(index) as PanelContainer
		card.custom_minimum_size.x = 0
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = Color(1, 0.98, 0.94)
		style.set_corner_radius_all(16)
		style.set_border_width_all(3)
		style.border_color = UiPalette.ORANGE if index == 1 else UiPalette.TEAL
		var inside := card.get_child(0) as VBoxContainer
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		var cap := Keycap.new()
		cap.key_text = str(index + 1)
		cap.key_size = 34.0
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(cap)
		var pay := Label.new()
		pay.theme_type_variation = &"BigNumber"
		pay.add_theme_font_size_override("font_size", 36)
		pay.add_theme_color_override("font_color", UiPalette.INK)
		top.add_child(pay)
		choice_pay.append(pay)
		inside.add_child(top)
		inside.move_child(top, 0)
		phone._choice_info[index].add_theme_font_size_override("font_size", UiPalette.FONT_BODY)
		phone._choice_info[index].add_theme_constant_override("line_spacing", -12)


func set_choice(index: int, order: Order, _metres: int) -> void:
	_set_text(choice_pay[index], "%d Dh" % order.pay)
	_set_text(phone._choice_info[index], PhoneOfferCard.choice_text(order, _route_metres(order), index == 1))


# --- What the phone asks each frame ---

## Which chips show: the countdown is the ring now, and a new order shows its pay big.
func chip_shown(key: String) -> bool:
	if key == "time":
		return false
	return not (key == "pay" and phone.mode == "offer")


## The plain "what now" line hides on a new order: the skip key and the E ring say it.
func hint_shown() -> bool:
	return GameState.stage != GameState.Stage.OFFERED


## Goals are open while you wait (and after a delivery); on a job they fold unless you press G.
func goals_open() -> bool:
	return _goals_toggled or phone.mode == "waiting" or phone.mode == "done"


func toggle_goals() -> void:
	_goals_toggled = not _goals_toggled
	UiSounds.play("ui_open" if _goals_toggled else "ui_close")


func show_gear_goal(on: bool) -> void:
	if phone._gear_goal.visible != on:
		phone._gear_goal.visible = on
		phone._gear_progress.visible = on


## A new order: the phone slides in from the right before it buzzes.
func slide_in(tween: Tween) -> void:
	if Settings.reduce_motion:
		return
	phone.offset = Vector2(GameConfig.PHONE_OFFER_SLIDE_PX, 0.0)
	tween.tween_property(phone, "offset", Vector2.ZERO, UiPalette.PANEL_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func update(delta: float) -> void:
	_time += delta
	var mode: String = phone.mode
	var choosing := mode == "offer" and GameState.offered_orders.size() > 1
	var riding := mode == "to_restaurant" or mode == "to_villa"
	if mode != _last_mode:
		_last_mode = mode
		_tick_left = 0.0
		_card_style.border_color = UiPalette.ORANGE if mode == "offer" else UiPalette.INK
	offer.top.visible = mode == "offer" and not choosing
	offer.actions.visible = mode == "offer"
	phone._status.visible = mode != "offer" or choosing
	distance.visible = riding
	var waiting: bool = mode == "waiting" and GameState.shift_open() and phone._status.text.begins_with("Waiting")
	_wait_dots.visible = waiting
	if waiting:
		_place_wait_dots()
		_wait_dots.queue_redraw()
	_update_hint_key()
	_tick_left -= delta
	var tick := _tick_left <= 0.0
	if tick:
		_tick_left = GameConfig.PHONE_DISTANCE_EVERY
		_update_goals_button()
	if mode == "offer":
		var dm: DeliveryManager = phone.delivery_manager
		var left := 0.0 if dm == null else dm.time_left_on_offer()
		var total := GameConfig.ORDER_OFFER_TIMEOUT if dm == null else dm.offer_timeout
		offer.set_time(left, total, GameState.tutorial_running)
		if choosing:
			offer.show_choice()
		elif tick and GameState.offered_order != null:
			offer.show_order(GameState.offered_order, _route_metres(GameState.offered_order))
	elif riding and tick:
		_set_text(distance, "%s away" % PhoneOfferCard.distance_text(live_distance()))


## Metres from you (on the bike or on foot) to the next stop.
func live_distance() -> float:
	var dm: DeliveryManager = phone.delivery_manager
	if dm == null or dm.actor == null:
		return 0.0
	var door := dm.target_door()
	var at := dm.actor.global_position
	return Vector2(at.x, at.z).distance_to(Vector2(door.x, door.z))


func _route_metres(order: Order) -> float:
	var dm: DeliveryManager = phone.delivery_manager
	if dm == null or dm.place_builder == null:
		return 0.0
	var from: Vector3 = dm.actor.global_position if dm.actor != null else dm.place_builder.restaurant_approach(order.restaurant_id)
	return PhoneOfferCard.route_metres(dm.place_builder, order, from)


func _update_goals_button() -> void:
	var jobs := GameState.history.slice(GameState.shift_start_index)
	var done := 0
	for id in GameState.shift_goals:
		done += 1 if ShiftGoals.is_done(id, jobs, GameState.shift_crashes) else 0
	_set_text(goals_button, "Goals %d/%d" % [done, GameState.shift_goals.size()])


func _set_text(control: Control, text: String) -> void:
	if control.get("text") != text:
		control.set("text", text)
