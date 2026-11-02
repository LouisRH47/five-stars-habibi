extends CanvasLayer
## The rider's phone (top right): the Snackaroo app with your wallet, new orders
## and where to ride next. It only shows things: the data lives in GameState and
## the countdown and "close enough" check come from the DeliveryManager.

## Used for the order countdown and to light up the E hint when you're at the door.
@export var delivery_manager: DeliveryManager

const HINT_DIM := Color(0.49803922, 0.62745098, 0.65882355, 1)  # grey-teal: not there yet
const HINT_LIT := Color(0.9490196, 0.54901963, 0.15686275, 1)   # orange: press E now

var _flash_left := 0.0
var _flash_pay := 0

@onready var _wallet: Label = $Panel/Margin/Rows/Header/Wallet
@onready var _status: Label = $Panel/Margin/Rows/Status
@onready var _detail: Label = $Panel/Margin/Rows/Detail
@onready var _hint: Label = $Panel/Margin/Rows/Hint


func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.order_delivered.connect(_on_order_delivered)
	_on_money_changed(GameState.money)


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
	elif _flash_left > 0.0:
		_show("+%d Dh  Delivered!" % _flash_pay, "", "", false)
	else:
		_show("Waiting for orders...", "", "", false)


func _show(status: String, detail: String, hint: String, hint_lit: bool) -> void:
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


func _on_order_delivered(order: Order) -> void:
	_flash_pay = order.pay
	_flash_left = GameConfig.DELIVERED_MESSAGE_TIME
