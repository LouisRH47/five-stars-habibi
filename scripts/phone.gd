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
	_show_goals(stage == GameState.Stage.NONE)


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
	_pick_up.add_theme_color_override("font_color", ORANGE if step == 1 else (SOFT if step == 2 else INK))
	_drop_off.add_theme_color_override("font_color", ORANGE if step == 2 else INK)
	_set_chip("food", order.food.capitalize(), TEAL)
	_set_chip("pay", "%d Dh" % order.pay, GREEN)
	# Session 32: a coloured chip for a special order, a heart for a regular customer.
	_set_chip("special", GameConfig.SPECIAL_NAMES.get(order.special, ""), GameConfig.SPECIAL_COLOURS.get(order.special, TEAL))
	_set_chip("regular", "♥ " + order.regular if order.regular != "" else "", GameConfig.REGULAR_COLOUR)
	_note.text = "\"%s\"" % order.note


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
	(_pill.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = colour


func _set_chip(key: String, text: String, colour: Color) -> void:
	var chip: Label = _chips[key]
	chip.visible = text != ""
	chip.text = text
	(chip.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = colour


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
	_hint.add_theme_color_override("font_color", HINT_LIT if hint_lit else HINT_DIM)


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
