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
## XP, Rider Level or rating changed (Session 10).
signal stats_changed
## Insurance was switched on or off (Session 12).
signal insurance_changed(on: bool)
## A big crash happened; bills: what it cost (see big_crash()). Session 13 ends the shift.
signal big_crashed(bills: Dictionary)
## A new shift started / the shift is over (Session 13).
signal shift_started
signal shift_ended(summary: Dictionary)

## The three meters for the order you're carrying, 100 (green) to 0 (red). Set by
## scripts/meters.gd while you ride from the restaurant to the villa.
var meter_time := 100.0
var meter_freshness := 100.0
var meter_damage := 100.0
## Seconds you have to reach the villa before the time meter is empty, and seconds ridden so far.
var target_time := 0.0
var ride_time := 0.0

## Your name from the rider application (customers use it). Empty until Session 14's form.
var rider_name := ""
## Money in the wallet, in Dh. Can go below 0 after a big crash without insurance.
var money := 0
## Crash insurance: 2 Dh per delivery, then a big crash only costs 20 Dh. Starts on (PRD).
var insurance_on := true
## True once the boss has paid for your first big crash (only happens once per game).
var boss_paid_crash := false

## The shift (Session 13). scripts/shift_manager.gd counts shift_time_left down.
var shift_number := 1
var shift_time_left := GameConfig.SHIFT_LENGTH
## True once the shift clock has run out (you may still be finishing your last order).
var shift_clock_out := false
## Where this shift's deliveries start in history, and crash bills paid this shift.
var shift_start_index := 0
var shift_bills := 0
## All the XP you've ever earned. Your Rider Level comes from it (see level()).
var xp := 0
## One small Dictionary per finished delivery: restaurant, villa, food, pay, tip,
## the three meters, stars and xp.
var history: Array[Dictionary] = []
## The last delivery's Dictionary from history (the phone shows its stars), or empty.
var last_result: Dictionary = {}
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
	xp = 0
	insurance_on = true
	boss_paid_crash = false
	shift_number = 0
	start_shift()
	history.clear()
	last_result = {}
	offered_order = null
	current_order = null
	_choices.clear()
	start_meters(0.0)
	money_changed.emit(money)
	stats_changed.emit()
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
	var stars := stars_for(meter_time, meter_freshness, meter_damage)
	# Tips only on 5-star jobs, and not every time. Boring orders never tip (PRD).
	var tip := 0
	if stars >= 5.0 and not done.boring and randf() < GameConfig.TIP_CHANCE:
		tip = randi_range(GameConfig.TIP_MIN, GameConfig.TIP_MAX)
	var earned_xp := GameConfig.XP_PER_DELIVERY + roundi(GameConfig.XP_PER_STAR * stars)
	var insurance := GameConfig.INSURANCE_PER_DELIVERY if insurance_on else 0
	money += done.pay + tip - insurance
	xp += earned_xp
	last_result = {
		"restaurant": done.restaurant_name,
		"villa": done.villa_number,
		"food": done.food,
		"pay": done.pay,
		"tip": tip,
		"time": meter_time,
		"freshness": meter_freshness,
		"damage": meter_damage,
		"stars": stars,
		"xp": earned_xp,
		"left_at_door": done.leave_at_door,
		"insurance": insurance,
		"cancelled": false,
	}
	history.append(last_result)
	money_changed.emit(money)
	stats_changed.emit()
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


## Turns crash insurance on or off (the I key on the phone).
func set_insurance(on: bool) -> void:
	insurance_on = on
	insurance_changed.emit(on)


## A big crash (PRD "Crashes, bills and insurance"): the order you had is cancelled
## (0 stars, no pay) and the bills come in. The boss pays for your very first one;
## with insurance you only pay INSURED_CRASH_COST. Returns what happened, for the clinic
## screen: hospital, repair, paid (what came off your wallet), boss, insured, lost_order.
func big_crash() -> Dictionary:
	var bills := {
		"hospital": GameConfig.HOSPITAL_BILL,
		"repair": GameConfig.REPAIR_BILL,
		"boss": not boss_paid_crash,
		"insured": insurance_on,
		"lost_order": current_order != null or offered_order != null,
		"paid": 0,
	}
	if not boss_paid_crash:
		boss_paid_crash = true
	elif insurance_on:
		bills["paid"] = GameConfig.INSURED_CRASH_COST
	else:
		bills["paid"] = GameConfig.HOSPITAL_BILL + GameConfig.REPAIR_BILL
	if current_order != null:
		# Cancelled: counts as a 0-star job in your rating, no pay, no XP.
		history.append({
			"restaurant": current_order.restaurant_name, "villa": current_order.villa_number,
			"food": current_order.food, "pay": 0, "tip": 0, "insurance": 0, "xp": 0,
			"time": 0.0, "freshness": 0.0, "damage": 0.0, "stars": 0.0,
			"left_at_door": false, "cancelled": true,
		})
	current_order = null
	offered_order = null
	money -= bills["paid"]
	shift_bills += bills["paid"]
	money_changed.emit(money)
	stats_changed.emit()
	_set_stage(Stage.NONE)
	big_crashed.emit(bills)
	return bills


## Starts a new shift: a full clock and a fresh summary.
func start_shift() -> void:
	shift_number += 1
	shift_time_left = GameConfig.SHIFT_LENGTH
	shift_clock_out = false
	shift_start_index = history.size()
	shift_bills = 0
	shift_started.emit()


## True while new orders may still pop up (the shift clock hasn't run out).
func shift_open() -> bool:
	return not shift_clock_out


## The time on the in-game clock, in hours (8.5 = 08:30).
func clock_hours() -> float:
	var done := 1.0 - shift_time_left / GameConfig.SHIFT_LENGTH
	return lerpf(GameConfig.SHIFT_START_HOUR, GameConfig.SHIFT_END_HOUR, clampf(done, 0.0, 1.0))


## The shift's numbers for the summary screen: deliveries, cancelled, average stars,
## pay, tips, insurance, bills, xp and earned (what you took home after all costs).
func shift_summary() -> Dictionary:
	var jobs := history.slice(shift_start_index)
	var summary := {"deliveries": 0, "cancelled": 0, "stars": 0.0, "pay": 0, "tips": 0,
			"insurance": 0, "bills": shift_bills, "xp": 0, "earned": 0}
	var star_total := 0.0
	for job in jobs:
		if job["cancelled"]:
			summary["cancelled"] += 1
		else:
			summary["deliveries"] += 1
		star_total += job["stars"]
		summary["pay"] += job["pay"]
		summary["tips"] += job["tip"]
		summary["insurance"] += job["insurance"]
		summary["xp"] += job["xp"]
	if not jobs.is_empty():
		summary["stars"] = star_total / jobs.size()
	summary["earned"] = summary["pay"] + summary["tips"] - summary["insurance"] - summary["bills"]
	return summary


## The clock ran out: the order on the phone (if any) goes away without counting as a skip.
func clock_out() -> void:
	shift_clock_out = true
	if stage == Stage.OFFERED:
		offered_order = null
		_set_stage(Stage.NONE)


## Ends the shift and sends the summary.
func end_shift() -> Dictionary:
	shift_clock_out = true
	var summary := shift_summary()
	shift_ended.emit(summary)
	return summary


## Stars for a delivery from its three meters (PRD "Stars"): start at 5, each orange meter
## takes off half a star, each red one one and a half. Rounded to the nearest half star,
## never below 1.
static func stars_for(time: float, freshness: float, damage: float) -> float:
	var stars := 5.0
	for value in [time, freshness, damage]:
		if value < GameConfig.METER_RED_BELOW:
			stars -= GameConfig.STARS_RED_COST
		elif value <= GameConfig.METER_GREEN_ABOVE:
			stars -= GameConfig.STARS_ORANGE_COST
	return maxf(roundf(stars * 2.0) / 2.0, GameConfig.STARS_MIN)


## Your star rating: the average of your last 50 deliveries (0 before your first one).
func rating() -> float:
	var recent := history.slice(-GameConfig.RATING_WINDOW)
	if recent.is_empty():
		return 0.0
	var total := 0.0
	for job in recent:
		total += job["stars"]
	return total / recent.size()


## Your Rider Level, from 1 up. Level 1 to 2 needs LEVEL_XP_FIRST XP, each level after
## that needs LEVEL_XP_STEP more than the one before.
func level() -> int:
	return level_for(xp)


## How far you are into your current level: x = XP so far, y = XP that level needs.
func level_progress() -> Vector2i:
	var left := xp
	var need := GameConfig.LEVEL_XP_FIRST
	while left >= need:
		left -= need
		need += GameConfig.LEVEL_XP_STEP
	return Vector2i(left, need)


static func level_for(total_xp: int) -> int:
	var lvl := 1
	var need := GameConfig.LEVEL_XP_FIRST
	var left := total_xp
	while left >= need:
		left -= need
		need += GameConfig.LEVEL_XP_STEP
		lvl += 1
	return lvl


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
