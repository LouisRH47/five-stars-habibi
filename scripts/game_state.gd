extends Node
## Shared game data: money, delivery history and the current order.
## This is an autoload called GameState (Project > Project Settings > Globals),
## so every script can reach it. Nothing else should store these things.
## Other scripts change the data only through the functions below, so the
## signals always go out and the phone always shows the right thing.

## Where the current order is up to.
enum Stage { NONE, OFFERED, TO_RESTAURANT, TO_VILLA }

signal money_changed(new_money: int)
signal order_offered(order: Order)
signal order_stage_changed(stage: int)
signal order_delivered(order: Order)
signal order_skipped(order: Order)
## The time, freshness and damage meters changed (Session 8).
signal meters_changed

## The three meters for the order you're carrying, 100 (green) to 0 (red). Set by
## scripts/meters.gd while you ride from the restaurant to the villa.
var meter_time := 100.0
var meter_freshness := 100.0
var meter_damage := 100.0
## Seconds you have to reach the villa before the time meter is empty, and seconds ridden so far.
var target_time := 0.0
var ride_time := 0.0

## Money in the wallet, in Dh.
var money := 0
## One small Dictionary per finished delivery: restaurant, villa, food, pay.
var history: Array[Dictionary] = []
## The order waiting on the phone for you to accept or skip (or null).
var offered_order: Order = null
## The order you accepted and are riding with (or null).
var current_order: Order = null
var stage: Stage = Stage.NONE

# Your last accept (true) / skip (false) choices, newest at the end.
var _choices: Array[bool] = []


## Starts everything again from zero. Used by the smoke test.
func reset() -> void:
	money = 0
	history.clear()
	offered_order = null
	current_order = null
	_choices.clear()
	start_meters(0.0)
	money_changed.emit(money)
	_set_stage(Stage.NONE)


## A new order pops up on the phone. Only works when you have no order.
func offer_order(order: Order) -> bool:
	if stage != Stage.NONE or order == null:
		return false
	offered_order = order
	order_offered.emit(order)
	_set_stage(Stage.OFFERED)
	return true


## E on a new order: it becomes your current order. Next stop: the restaurant.
func accept_offer() -> bool:
	if stage != Stage.OFFERED:
		return false
	current_order = offered_order
	offered_order = null
	_remember_choice(true)
	_set_stage(Stage.TO_RESTAURANT)
	return true


## Q on a new order (or ignoring it for too long): it goes away.
func skip_offer() -> bool:
	if stage != Stage.OFFERED:
		return false
	var skipped := offered_order
	offered_order = null
	_remember_choice(false)
	_set_stage(Stage.NONE)
	order_skipped.emit(skipped)
	return true


## E at the restaurant: you have the food. Next stop: the villa.
func pick_up() -> bool:
	if stage != Stage.TO_RESTAURANT:
		return false
	_set_stage(Stage.TO_VILLA)
	return true


## E at the villa: you get paid and the order is done.
func deliver() -> bool:
	if stage != Stage.TO_VILLA:
		return false
	var done := current_order
	current_order = null
	money += done.pay
	history.append({
		"restaurant": done.restaurant_name,
		"villa": done.villa_number,
		"food": done.food,
		"pay": done.pay,
		"time": meter_time,
		"freshness": meter_freshness,
		"damage": meter_damage,
	})
	money_changed.emit(money)
	_set_stage(Stage.NONE)
	# Sent last, so the phone's "Delivered!" message comes after "no order".
	order_delivered.emit(done)
	return true


## Fills all three meters for a new ride. target: seconds before the time meter is empty.
func start_meters(target: float) -> void:
	target_time = target
	ride_time = 0.0
	meter_time = 100.0
	meter_freshness = 100.0
	meter_damage = 100.0
	meters_changed.emit()


## Sets the meters (each is kept between 0 and 100).
func set_meters(time: float, freshness: float, damage: float) -> void:
	meter_time = clampf(time, 0.0, 100.0)
	meter_freshness = clampf(freshness, 0.0, 100.0)
	meter_damage = clampf(damage, 0.0, 100.0)
	meters_changed.emit()


## Share of your last ORDER_ACCEPT_HISTORY orders that you accepted, 0.0 to 1.0.
## With no choices yet it counts as 100%.
func acceptance_rate() -> float:
	if _choices.is_empty():
		return 1.0
	return float(_choices.count(true)) / float(_choices.size())


## The stage as a word ("NONE", "OFFERED", ...). Handy for tests and printing.
func stage_name() -> String:
	return Stage.keys()[stage]


func _set_stage(new_stage: Stage) -> void:
	stage = new_stage
	order_stage_changed.emit(stage)


func _remember_choice(accepted: bool) -> void:
	_choices.append(accepted)
	while _choices.size() > GameConfig.ORDER_ACCEPT_HISTORY:
		_choices.pop_front()
