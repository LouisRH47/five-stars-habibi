extends CanvasLayer
## The rider's phone (top right): the Snackaroo app on a white card (Session 20, styled
## like the mockup). It shows your wallet, star rating and Rider Level (with an XP bar), a
## status pill, the order (pick-up and drop-off rows, food / pay / timer chips and the
## customer's note), what to do next, the orange hold-E bar, and the insurance setting.
## After a delivery it shows the stars, pay, tip and XP. It only shows things: the data
## lives in GameState, and the countdown and "close enough" checks come from the
## DeliveryManager.

## Used for the order countdown and to light up the hint when you're at the door.
@export var delivery_manager: DeliveryManager

const INK := Color(0.105882354, 0.11372549, 0.13333334, 1)
const SOFT := Color(0.36, 0.42, 0.44, 1)
const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const SUN := Color(0.9490196, 0.69803923, 0.1882353, 1)
const SAND := Color(0.9529412, 0.8901961, 0.7647059, 1)
const GREEN := Color(0.2, 0.6, 0.36, 1)
const GREY := Color(0.55, 0.6, 0.61, 1)
const RED := Color(0.8, 0.25, 0.2, 1)
const HINT_DIM := SOFT    # not there yet
const HINT_LIT := ORANGE  # do it now

var _flash_left := 0.0
var _chips: Dictionary = {}  # "food", "pay", "time", "special", "regular" -> Label
var _event_banner: Label  # Session 33: road works / horses warning
var _choices_box: HBoxContainer
var _choice_info: Array[Label] = []
var _streak: Label
var _gear_goal: Label
var _gear_progress: ProgressBar
var _goals: Label  # Session 32: this shift's 2 goals, shown while you wait for an order

@onready var _wallet: Label = $Panel/Margin/Rows/Header/Wallet
@onready var _pill: Label = $Panel/Margin/Rows/Pill
@onready var _status: Label = $Panel/Margin/Rows/Status
@onready var _stops: Control = $Panel/Margin/Rows/Stops
@onready var _pick_up: Label = $Panel/Margin/Rows/Stops/PickUp
@onready var _drop_off: Label = $Panel/Margin/Rows/Stops/DropOff
@onready var _chip_row: HBoxContainer = $Panel/Margin/Rows/Chips
@onready var _note: Label = $Panel/Margin/Rows/Note
@onready var _detail: Label = $Panel/Margin/Rows/Detail
@onready var _hint: Label = $Panel/Margin/Rows/Hint
@onready var _rating_stars: StarRow = $Panel/Margin/Rows/Profile/Stars
@onready var _rating: Label = $Panel/Margin/Rows/Profile/Rating
@onready var _level: Label = $Panel/Margin/Rows/Profile/Level
@onready var _xp_bar: ProgressBar = $Panel/Margin/Rows/XP
@onready var _result: StarRow = $Panel/Margin/Rows/Result
@onready var _insurance: Label = $Panel/Margin/Rows/Insurance
@onready var _rider: Label = $Panel/Margin/Rows/Rider
@onready var _hold_bar: ProgressBar = $Panel/Margin/Rows/HoldBar


func _ready() -> void:
	for key in ["food", "pay", "time", "special", "regular"]:
		_chips[key] = _make_chip()
	_make_event_banner()
	_goals = _make_goals()
	_make_choices()
	_make_profile_link()
	var profile := ProfilePage.new()
	profile.name = "ProfilePage"
	add_child(profile)
	var observer := preload("res://scripts/collection_observer.gd").new()
	observer.delivery_manager = delivery_manager
	add_child(observer)
	GameState.money_changed.connect(_on_money_changed)
	GameState.order_delivered.connect(_on_order_delivered)
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.insurance_changed.connect(_on_insurance_changed)
	GameState.order_offered.connect(func(_order): buzz())  # Session 31
	_on_insurance_changed(GameState.insurance_on)
	_on_money_changed(GameState.money)
	_on_stats_changed()
	# Your rider profile from the application (Session 14).
	_rider.visible = GameState.rider_name != ""
	_rider.text = "%s  ·  %s" % [GameState.rider_name, GameState.rider_country]


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	var near := delivery_manager != null and delivery_manager.is_near_target()
	var stage := GameState.stage
	if stage == GameState.Stage.OFFERED:
		var offer := GameState.offered_order
		var secs := 0 if delivery_manager == null else ceili(delivery_manager.time_left_on_offer())
		_set_pill("NEW ORDER", ORANGE)
		_show("New order!", "", "E accept   Q skip", true)
		_set_order(offer, 0)
		_set_chip("time", "" if GameState.tutorial_running else "%d s" % secs, ORANGE)
	elif stage == GameState.Stage.TO_RESTAURANT:
		var order := GameState.current_order
		_set_pill("PICK UP", TEAL)
		_show("Ride to %s" % order.restaurant_name, "", _hold_hint("pick up"), near)
		_set_order(order, 1)
	elif stage == GameState.Stage.TO_VILLA:
		var order := GameState.current_order
		_set_pill("DROP OFF", TEAL)
		_show("Deliver to %s" % order.address, "", _hold_hint("drop off"), near)
		_set_order(order, 2)
	elif _flash_left > 0.0 and not GameState.last_result.is_empty():
		var job := GameState.last_result
		var lines := "+%d Dh pay" % job["pay"]
		if job["tip"] > 0:
			lines += "\n+%d Dh tip!" % job["tip"]
		if job["insurance"] > 0:
			lines += "\n-%d Dh insurance" % job["insurance"]
		lines += "\n+%d XP" % job["xp"]
		var done := "Left at the door!" if job["left_at_door"] else "Delivered!"
		_set_pill("DONE", GREEN)
		_show("%s  %s stars" % [done, _stars_text(job["stars"])], lines, "", false)
		_set_order(null, 0)
	else:
		var walking := delivery_manager != null and delivery_manager.on_foot
		_set_pill("WAITING", GREY)
		_show("Waiting for orders...", "", _walking_hint("Walk back to your bike") if walking else "", walking)
		_set_order(null, 0)
	_show_goals(true)
	_streak.text = "%d in a row  ·  +%d%% tip chance" % [GameState.streak, roundi(minf(GameState.streak * GameConfig.STREAK_TIP_STEP, GameConfig.STREAK_TIP_MAX) * 100.0)] if GameState.streak > 0 else "Build a five-star streak"
	_show_choices(stage == GameState.Stage.OFFERED and GameState.offered_orders.size() > 1)


## The order part of the card: pick-up and drop-off rows (the one you're on now in bold
## orange, a done one ticked), food and pay chips and the customer's note.
## step: 0 = not accepted yet, 1 = riding to the restaurant, 2 = riding to the villa.
func _set_order(order: Order, step: int) -> void:
	_stops.visible = order != null
	_chip_row.visible = order != null
	_note.visible = order != null and order.note != ""
	if step != 0 or order == null:
		_set_chip("time", "", ORANGE)  # the countdown only shows on a new order
	if order == null:
		return
	_pick_up.text = "%s  Pick up · %s" % ["✓" if step == 2 else "•", order.restaurant_name]
	_drop_off.text = "•  Drop off · %s" % order.address
	_font_colour(_pick_up, ORANGE if step == 1 else (SOFT if step == 2 else INK))
	_font_colour(_drop_off, ORANGE if step == 2 else INK)
	_set_chip("food", order.food.capitalize(), TEAL)
	_set_chip("pay", "%d Dh" % order.pay, GREEN)
	# Session 32: a coloured chip for a special order, a heart for a regular customer.
	_set_chip("special", GameConfig.SPECIAL_NAMES.get(order.special, ""), GameConfig.SPECIAL_COLOURS.get(order.special, TEAL))
	_set_chip("regular", "♥ " + order.regular if order.regular != "" else "", GameConfig.REGULAR_COLOUR)
	_note.text = "\"%s\"" % order.note
	if order.special != "":
		_note.visible = true
		_note.text = ("\"%s\"\n" % order.note if order.note != "" else "") + order.requirement_text()


## This shift's goals (Session 32): a tick when done, otherwise how far along you are.
func _show_goals(on: bool) -> void:
	_goals.visible = on and not GameState.shift_goals.is_empty()
	if not _goals.visible:
		return
	var jobs := GameState.history.slice(GameState.shift_start_index)
	var lines := "Shift goals  (+%d Dh each)" % GameConfig.GOAL_BONUS
	for id in GameState.shift_goals:
		var done := ShiftGoals.is_done(id, jobs, GameState.shift_crashes)
		lines += "\n%s  %s" % ["✓" if done else "•", ShiftGoals.line(id, jobs, GameState.shift_crashes)]
	_goals.text = lines


func _make_goals() -> Label:
	var label := Label.new()
	label.name = "Goals"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TEAL)
	var rows := _chip_row.get_parent()
	rows.add_child(label)
	rows.move_child(label, _insurance.get_index())  # just above the insurance line
	return label


func _set_pill(text: String, colour: Color) -> void:
	_pill.text = text
	_background_colour(_pill, colour)


func _set_chip(key: String, text: String, colour: Color) -> void:
	var chip: Label = _chips[key]
	chip.visible = text != ""
	chip.text = text
	_background_colour(chip, colour)


## StyleBox changes emit resource notifications even if their colour is unchanged.
## Steady gameplay frames should reuse the existing theme/layout caches.
func _background_colour(control: Control, colour: Color) -> void:
	var style := control.get_theme_stylebox("normal") as StyleBoxFlat
	if style.bg_color != colour:
		style.bg_color = colour


func _font_colour(control: Control, colour: Color) -> void:
	if control.get_theme_color("font_color") != colour:
		control.add_theme_color_override("font_color", colour)


func _make_chip() -> Label:
	var chip := Label.new()
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	chip.add_theme_stylebox_override("normal", style)
	chip.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	chip.add_theme_font_size_override("font_size", 14)
	_chip_row.add_child(chip)
	return chip


## The hint for a stop: park near the door, get off with F, walk over and hold E.
func _hold_hint(action: String) -> String:
	var dm := delivery_manager
	if dm == null:
		return "Hold E to " + action
	if dm.needs_walking and not dm.on_foot:
		if dm.is_near_target():
			return "Slow down, then press F" if dm.too_fast_at_door() else "Press F to get off"
		return "Park near the door"
	if dm.too_fast_at_door():
		return "Slow down, then hold E"
	if dm.on_foot and not dm.is_near_target():
		return _walking_hint("Walk to the door")
	return "Hold E to " + action


## On foot and away from the door: where's the bike?
func _walking_hint(otherwise: String) -> String:
	var gap := delivery_manager.distance_to_bike()
	if gap > GameConfig.BIKE_FAR_DISTANCE:
		return "Your bike is over there (see the map)"
	if gap <= GameConfig.GET_ON_DISTANCE:
		return "Press F to ride"
	return otherwise


func _show(status: String, detail: String, hint: String, hint_lit: bool) -> void:
	var holding := delivery_manager != null and delivery_manager.hold_progress() > 0.0
	_hold_bar.visible = holding
	if holding:
		_hold_bar.value = delivery_manager.hold_progress() * 100.0
	_result.visible = _flash_left > 0.0 and GameState.stage == GameState.Stage.NONE \
			and not GameState.last_result.is_empty()
	if _result.visible:
		_result.stars = GameState.last_result["stars"]
	_status.text = status
	_detail.text = detail
	_detail.visible = detail != ""
	_hint.text = hint
	_hint.visible = hint != ""
	_font_colour(_hint, HINT_LIT if hint_lit else HINT_DIM)


## Session 31: the phone buzzes when a new order comes in, a quick little side-to-side
## shake (the buzz sound is played by scripts/sounds.gd). buzzes counts them (smoke test).
var buzzes := 0
var _buzz_tween: Tween


func buzz() -> void:
	buzzes += 1
	if _buzz_tween != null:
		_buzz_tween.kill()
	_buzz_tween = create_tween()
	var px := GameConfig.PHONE_BUZZ_PIXELS
	var step := GameConfig.PHONE_BUZZ_TIME / 6.0
	for x in [px, -px, px * 0.7, -px * 0.7, px * 0.3, 0.0]:
		_buzz_tween.tween_property(self, "offset", Vector2(x, 0.0), step)


func _on_money_changed(new_money: int) -> void:
	_wallet.text = "Dh %d" % new_money
	_show_gear_goal()


func _on_order_delivered(_order: Order) -> void:
	_flash_left = GameConfig.RESULT_MESSAGE_TIME


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_insurance"):
		GameState.set_insurance(not GameState.insurance_on)
		get_viewport().set_input_as_handled()


func _on_insurance_changed(on: bool) -> void:
	_insurance.text = "Insurance %s  (I to switch)" % ("ON, 2 Dh a job" if on else "OFF")
	_insurance.add_theme_color_override("font_color", SOFT if on else RED)


func _on_stats_changed() -> void:
	_show_gear_goal()
	var rating := GameState.rating()
	_rating_stars.stars = roundf(rating * 2.0) / 2.0
	_rating.text = "New" if GameState.history.is_empty() else _stars_text(rating)
	_level.text = "Lv %d" % GameState.level()
	var progress := GameState.level_progress()
	_xp_bar.max_value = progress.y
	_xp_bar.value = progress.x


## 4.5 shows as "4.5", 5 as "5.0".
func _stars_text(stars: float) -> String:
	return "%.1f" % stars


# --- Random events (Session 33) ---

## Shows a line about a random event under your profile: orange while it's a warning
## ("Heads up! Road works soon"), teal while it's going on. "" hides it.
## scripts/event_manager.gd calls this.
func show_event(text: String, warning: bool) -> void:
	_event_banner.text = text
	_event_banner.visible = text != ""
	(_event_banner.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = ORANGE if warning else TEAL


## The event line's text ("" when hidden), for the smoke test.
func event_text() -> String:
	return _event_banner.text if _event_banner.visible else ""


func _make_event_banner() -> void:
	_event_banner = Label.new()
	_event_banner.name = "EventBanner"
	_event_banner.visible = false
	_event_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	_event_banner.add_theme_stylebox_override("normal", style)
	_event_banner.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_event_banner.add_theme_font_size_override("font_size", 14)
	var rows := $Panel/Margin/Rows
	rows.add_child(_event_banner)
	rows.move_child(_event_banner, $Panel/Margin/Rows/Line.get_index())


func _make_profile_link() -> void:
	var rows := $Panel/Margin/Rows
	_streak = Label.new()
	_streak.add_theme_font_size_override("font_size", 14)
	_streak.add_theme_color_override("font_color", GREEN)
	rows.add_child(_streak)
	rows.move_child(_streak, _xp_bar.get_index() + 1)
	var profile := Button.new()
	profile.text = "Profile & collections  ·  P"
	profile.add_theme_font_size_override("font_size", 14)
	profile.pressed.connect(func(): $ProfilePage.open())
	rows.add_child(profile)
	_gear_goal = Label.new()
	_gear_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gear_goal.add_theme_font_size_override("font_size", 13)
	_gear_goal.add_theme_color_override("font_color", TEAL)
	rows.add_child(_gear_goal)
	_gear_progress = ProgressBar.new()
	_gear_progress.custom_minimum_size.y = 5
	_gear_progress.show_percentage = false
	rows.add_child(_gear_progress)


func _show_gear_goal() -> void:
	if _gear_goal == null:
		return
	var goal := GearCatalog.next_goal(GameState)
	_gear_goal.text = "Next goal: " + goal["description"]
	_gear_progress.value = goal["progress"] * 100.0


func _make_choices() -> void:
	_choices_box = HBoxContainer.new()
	_choices_box.name = "OrderChoices"
	_choices_box.add_theme_constant_override("separation", 12)
	_choices_box.visible = false
	var rows := $Panel/Margin/Rows
	rows.add_child(_choices_box)
	rows.move_child(_choices_box, _stops.get_index())
	for index in 2:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.x = 260
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.94, 0.97, 0.96)
		style.border_color = GREEN if index == 1 else TEAL
		style.set_border_width_all(2)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(12)
		card.add_theme_stylebox_override("panel", style)
		_choices_box.add_child(card)
		var inside := VBoxContainer.new()
		inside.add_theme_constant_override("separation", 10)
		card.add_child(inside)
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", INK)
		inside.add_child(label)
		_choice_info.append(label)
		var button := Button.new()
		button.text = "Choose %d" % (index + 1)
		button.pressed.connect(func(): delivery_manager.choose(index))
		inside.add_child(button)


func _show_choices(on: bool) -> void:
	_choices_box.visible = on
	var panel: PanelContainer = $Panel
	var width := 640.0 if on else 330.0
	var left := -664.0 if on else -354.0
	if panel.custom_minimum_size.x != width:
		panel.custom_minimum_size.x = width
	if panel.offset_left != left:
		panel.offset_left = left
	if not on:
		return
	_stops.visible = false
	_chip_row.visible = false
	_note.visible = false
	_status.text = "Choose your next delivery"
	var secs := ceili(delivery_manager.time_left_on_offer()) if delivery_manager != null else 0
	_hint.text = "1 or 2 to choose  ·  Q skips both  ·  %d s" % secs
	for index in 2:
		var order := GameState.offered_orders[index]
		var kind: String = GameConfig.SPECIAL_NAMES.get(order.special, "Standard order")
		var places := delivery_manager.place_builder
		var metres := roundi(places.restaurant_approach(order.restaurant_id).distance_to(places.villa_approach(order.villa_number)))
		var customer := "  ·  ♥ " + order.regular if order.regular != "" else ("  ·  Tip-friendly" if order.special == "fragile" else "")
		_choice_info[index].text = "%s%s\n%s  ·  %d Dh\nTo %s\n%d m route%s\n%s\n%s" % [order.restaurant_name, "  ·  Better offer" if index == 1 else "", order.food.capitalize(), order.pay, order.address, metres, customer, kind, order.requirement_text()]
