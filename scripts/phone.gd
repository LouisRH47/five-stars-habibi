extends CanvasLayer
## The rider's phone (top right): the Snackaroo app with your wallet, your star rating
## and Rider Level (with an XP bar), new orders and where to ride next. After a delivery
## it shows the stars you got, the pay, any tip and the XP. It only shows things: the data lives in GameState and
## the countdown and "close enough" check come from the DeliveryManager.

## Used for the order countdown and to light up the E hint when you're at the door.
@export var delivery_manager: DeliveryManager

const HINT_DIM := Color(0.49803922, 0.62745098, 0.65882355, 1)  # grey-teal: not there yet
const HINT_LIT := Color(0.9490196, 0.54901963, 0.15686275, 1)   # orange: press E now

var _flash_left := 0.0

@onready var _wallet: Label = $Panel/Margin/Rows/Header/Wallet
@onready var _status: Label = $Panel/Margin/Rows/Status
@onready var _detail: Label = $Panel/Margin/Rows/Detail
@onready var _hint: Label = $Panel/Margin/Rows/Hint
@onready var _rating_stars: StarRow = $Panel/Margin/Rows/Profile/Stars
@onready var _rating: Label = $Panel/Margin/Rows/Profile/Rating
@onready var _level: Label = $Panel/Margin/Rows/Profile/Level
@onready var _xp_bar: ProgressBar = $Panel/Margin/Rows/XP
@onready var _result: StarRow = $Panel/Margin/Rows/Result
@onready var _insurance: Label = $Panel/Margin/Rows/Insurance


func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.order_delivered.connect(_on_order_delivered)
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.insurance_changed.connect(_on_insurance_changed)
	_on_insurance_changed(GameState.insurance_on)
	_on_money_changed(GameState.money)
	_on_stats_changed()


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	var near := delivery_manager != null and delivery_manager.is_near_target()
	var stage := GameState.stage
	if stage == GameState.Stage.OFFERED:
		var offer := GameState.offered_order
		var secs := 0 if delivery_manager == null else ceili(delivery_manager.time_left_on_offer())
		_show("New order!  %d Dh" % offer.pay,
				"%s (%s)\nto villa %d%s" % [offer.restaurant_name, offer.food, offer.villa_number, _note(offer)],
				"E accept   Q skip   %d s" % secs, true)
	elif stage == GameState.Stage.TO_RESTAURANT:
		var order := GameState.current_order
		_show("Ride to %s" % order.restaurant_name, "Pick up the %s" % order.food, "E to pick up", near)
	elif stage == GameState.Stage.TO_VILLA:
		var order := GameState.current_order
		_show("Deliver to villa %d" % order.villa_number,
				"%s, %d Dh%s" % [order.food.capitalize(), order.pay, _note(order)], "E to drop off", near)
	elif _flash_left > 0.0 and not GameState.last_result.is_empty():
		var job := GameState.last_result
		var lines := "+%d Dh pay" % job["pay"]
		if job["tip"] > 0:
			lines += "\n+%d Dh tip!" % job["tip"]
		if job["insurance"] > 0:
			lines += "\n-%d Dh insurance" % job["insurance"]
		lines += "\n+%d XP" % job["xp"]
		var done := "Left at the door!" if job["left_at_door"] else "Delivered!"
		_show("%s  %s stars" % [done, _stars_text(job["stars"])], lines, "", false)
	else:
		_show("Waiting for orders...", "", "", false)


func _show(status: String, detail: String, hint: String, hint_lit: bool) -> void:
	_result.visible = _flash_left > 0.0 and GameState.stage == GameState.Stage.NONE \
			and not GameState.last_result.is_empty()
	if _result.visible:
		_result.stars = GameState.last_result["stars"]
	_status.text = status
	_detail.text = detail
	_detail.visible = detail != ""
	_hint.text = hint
	_hint.visible = hint != ""
	_hint.modulate = HINT_LIT if hint_lit else HINT_DIM


func _note(order: Order) -> String:
	return "" if order.note == "" else "\n\"%s\"" % order.note


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
	_insurance.modulate = Color(1, 1, 1, 1) if on else Color(1, 0.6, 0.5, 1)


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
