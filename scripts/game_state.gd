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
## A neighbour order was sent on to the house next door (Session 32).
signal order_redirected(order: Order)
## Replay progress is independent of the rating's rolling delivery history.
signal collection_changed
signal offers_changed

var streak := 0
var day_kind := "normal"
var tomorrow_kind := "hot_noon"
var personal_bests: Dictionary = {"earnings": 0, "streak": 0, "deliveries": 0, "routes": {}}
var shift_new_bests: Array[String] = []
var visited_homes: Dictionary = {}
var visited_venues: Dictionary = {}
var animals_met: Dictionary = {}
var lines_heard: Dictionary = {}
var collection_claims: Dictionary = {}
var owned_collection_rewards: Dictionary = {}
var home_catalog: Dictionary = {}
var venue_catalog: Dictionary = {}
var collection_bonus_this_shift := 0
var offered_orders: Array[Order] = []
## Shared equipment state, consumed by the bike and meter systems and saved with progress.
var upgrade_levels: Dictionary = {}
var owned_items: Dictionary = {}
var equipped_cosmetics: Dictionary = {}

## The three meters for the order you're carrying, 100 (green) to 0 (red). Set by
## scripts/meters.gd while you ride from the restaurant to the villa.
var meter_time := 100.0
var meter_freshness := 100.0
var meter_damage := 100.0
## Seconds you have to reach the villa before the time meter is empty, and seconds ridden so far.
var target_time := 0.0
var ride_time := 0.0

## You, from the rider application (Session 14). Customers use your name.
var rider_name := ""
var rider_country := ""
## Your look: 0 Classic, 1 Sporty, 2 Chill (data/application.gd LOOKS).
var rider_look := 0
## Session 88: which delivery company you ride for: "snackaroo", "zoomaroo" or "deliverooz"
## (data/companies.gd). Old saves are Snackaroo.
var company := "snackaroo"
## Sent when you switch company (the box, shirt and phone change colour).
signal company_changed(id: String)
## True once you've been hired (the application is done).
var hired := false
## True once the first-order tutorial is finished (it only runs once).
var tutorial_done := false
## True while the tutorial is running: no other orders, and the shift clock waits.
var tutorial_running := false
## Money in the wallet, in Dh. Can go below 0 after a big crash without insurance.
var money := 0
## Crash insurance: 2 Dh per delivery, then a big crash only costs 20 Dh. Starts on (PRD).
var insurance_on := true
## True once the boss has paid for your first big crash (only happens once per game).
var boss_paid_crash := false
## The shift number of every big crash (Session 23: "Big crashes this week" on the clinic).
var crash_shifts: Array[int] = []

## The shift (Session 13). scripts/shift_manager.gd counts shift_time_left down.
var shift_number := 0  # start_shift() makes the first one shift 1
## True once this shift has ended (the summary showed). Saved, so quitting halfway through
## a shift and coming back plays that same shift again instead of counting a new one.
var shift_finished := false
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

## Session 32. This shift's goals (ids from scripts/shift_goals.gd), the goals this map can
## do (the DeliveryManager sets it), crashes this shift (big and small), the goals the last
## delivery finished (the Delivered card shows them), and how many times you've delivered
## to each regular customer (saved).
var shift_goals: Array[String] = []
var goal_pool: Array = ShiftGoals.ALL.keys()
var shift_crashes := 0
var last_goals_done: Array[String] = []
var regular_visits: Dictionary = {}
var _goal_bonus_paid := false  # the goal bonus is paid once per shift
## The order waiting on the phone for you to accept or skip (or null).
var offered_order: Order = null
## The order you accepted and are riding with (or null).
var current_order: Order = null
var stage: Stage = Stage.NONE

# Your last accept (true) / skip (false) choices, newest at the end.
var _choices: Array[bool] = []

## Where the game is saved (Session 15). The smoke test points this at its own file.
var save_path := "user://save.json"
var _save_waiting := false


func _ready() -> void:
	Settings.load_once()
	load_game()
	# Save by itself whenever something worth keeping changes.
	for changed in [money_changed, stats_changed, insurance_changed, shift_ended]:
		changed.connect(func(_a = null): save_soon())


## Saves at the end of this frame (several changes at once only save once).
func save_soon() -> void:
	if not _save_waiting:
		_save_waiting = true
		_save_if_waiting.call_deferred()


func _save_if_waiting() -> void:
	if _save_waiting:  # skip it if something already saved this frame
		save_game()


func save_game() -> bool:
	_save_waiting = false
	return SaveGame.save(self, save_path)


## Loads the saved game (if there is one) and starts a fresh shift. Opening the game only
## counts as a new shift if the last one was finished; otherwise it plays that one again
## (same number, same kind of day).
func load_game() -> bool:
	var found := SaveGame.load_into(self, save_path)
	start_shift(not found or shift_finished)
	money_changed.emit(money)
	stats_changed.emit()
	insurance_changed.emit(insurance_on)
	return found


## Wipes everything, you too: back to the application. Deletes the save.
func new_game() -> void:
	SaveGame.delete(save_path)
	rider_name = ""
	rider_country = ""
	rider_look = 0
	company = "snackaroo"
	hired = false
	tutorial_done = false
	tutorial_running = false
	reset()
	save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()  # closing the window: keep your progress


## Starts everything again from zero. Used by the smoke test.
func reset() -> void:
	money = 0
	xp = 0
	insurance_on = true
	boss_paid_crash = false
	crash_shifts.clear()
	regular_visits.clear()
	streak = 0
	upgrade_levels.clear()
	owned_items.clear()
	equipped_cosmetics.clear()
	day_kind = "normal"
	tomorrow_kind = "hot_noon"
	personal_bests = {"earnings": 0, "streak": 0, "deliveries": 0, "routes": {}}
	visited_homes.clear()
	visited_venues.clear()
	animals_met.clear()
	lines_heard.clear()
	collection_claims.clear()
	owned_collection_rewards.clear()
	offered_orders.clear()
	shift_number = 0
	history.clear()
	start_shift()
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
	offered_orders.assign([order])
	offers_changed.emit()
	order_offered.emit(order)
	_set_stage(Stage.OFFERED)
	return true


## E on a new order: it becomes your current order. Next stop: the restaurant.
func accept_offer(index := 0) -> bool:
	if stage != Stage.OFFERED:
		return false
	if index < 0 or index >= offered_orders.size():
		return false
	current_order = offered_orders[index]
	offered_order = null
	offered_orders.clear()
	offers_changed.emit()
	_remember_choice(true)
	_set_stage(Stage.TO_RESTAURANT)
	return true


## Q on a new order (or ignoring it for too long): it goes away.
func skip_offer() -> bool:
	if stage != Stage.OFFERED:
		return false
	var skipped := offered_order
	offered_order = null
	offered_orders.clear()
	offers_changed.emit()
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
	# The current five-star job contributes to the shown streak and its tip chance.
	streak = streak + 1 if stars >= 5.0 else 0
	if streak > int(personal_bests.get("streak", 0)):
		personal_bests["streak"] = streak
		_note_best("Longest five-star streak: %d" % streak)
	if done.regular_id != "":
		regular_visits[done.regular_id] = int(regular_visits.get(done.regular_id, 0)) + 1
	# Tips only on 5-star jobs, and not every time. Boring orders never tip (PRD).
	var tip := 0
	if stars >= 5.0 and not done.boring and not done.crashed and randf() < tip_chance(done):
		tip = randi_range(GameConfig.TIP_MIN, GameConfig.TIP_MAX)
		tip = Companies.tip_with_perk(tip, company)  # Session 88: Snackaroo tips 10% bigger
	var goals_before := goals_done()
	var earned_xp := GameConfig.XP_PER_DELIVERY + roundi(GameConfig.XP_PER_STAR * stars)
	var insurance := GameConfig.INSURANCE_PER_DELIVERY if insurance_on else 0
	money += done.pay + tip - insurance
	xp += earned_xp
	last_result = {
		"restaurant": done.restaurant_name,
		"restaurant_id": done.restaurant_id,
		"villa": done.villa_number,
		"address": done.address,
		"food": done.food,
		"pay": done.pay,
		"tip": tip,
		"time": meter_time,
		"freshness": meter_freshness,
		"damage": meter_damage,
		"stars": stars,
		"xp": earned_xp,
		"left_at_door": done.leave_at_door,
		"crashed": done.crashed,
		"insurance": insurance,
		"cancelled": false,
		# Session 32: special orders, regulars, school lunch orders and clusters (for the goals).
		"special": done.special,
		"base_pay": done.base_pay,
		"regular": done.regular,
		"cluster": done.cluster,
		"lunch": done.lunch,
		"regular_id": done.regular_id,
		"ride_time": ride_time,
		"streak": streak,
		"perfect": stars >= 5.0,
		"new_route_best": _record_route_best(done, ride_time),
		"collection_bonus": _stamp_delivery(done),
	}
	history.append(last_result)
	last_goals_done.clear()
	for id in goals_done():
		if not id in goals_before and id != "no_crashes":  # "No crashes" is only decided at the end
			last_goals_done.append(id)
	money_changed.emit(money)
	stats_changed.emit()
	_set_stage(Stage.NONE)
	# Sent last, so the phone's "Delivered!" message comes after "no order".
	order_delivered.emit(done)
	return true


## Tip chance on a 5-star job: regulars and fragile cakes tip more often (Session 32).
func tip_chance(order: Order) -> float:
	var base := GameConfig.TIP_CHANCE
	if order.regular != "":
		base = GameConfig.BEST_FRIEND_TIP_CHANCE if regular_visits.get(order.regular_id, 0) >= GameConfig.BEST_FRIEND_VISITS else GameConfig.REGULAR_TIP_CHANCE
	elif order.special == "fragile":
		base = GameConfig.FRAGILE_TIP_CHANCE
	base += minf(streak * GameConfig.STREAK_TIP_STEP, GameConfig.STREAK_TIP_MAX)
	if day_kind == "shop_special" and order.restaurant_id == "gelato":
		base *= GameConfig.SHOP_SPECIAL_TIP_MULTIPLIER
	return clampf(base, 0.0, 1.0)


## A neighbour order at the door: nobody's home, so it goes to another home in the same
## cluster. The order, its pay and the clock all carry on (Session 32).
func send_to_neighbour(number: int, address: String, cluster: String, compact_address := "") -> bool:
	var order := current_order
	if stage != Stage.TO_VILLA or order == null or order.special != "neighbour" or order.neighbour_done:
		return false
	order.neighbour_done = true
	order.villa_number = number
	order.address = address
	order.map_address = compact_address if compact_address != "" else address
	order.cluster = cluster
	order.note = GameConfig.NEIGHBOUR_NOTE % address
	order_redirected.emit(order)
	return true


## You crashed (small or big). "No crashes" goal (Session 32). The ShiftManager calls this.
func note_crash() -> void:
	shift_crashes += 1
	# Session 52: a crash with food on board costs that order its tip.
	if current_order != null:
		current_order.crashed = true
	streak = 0
	stats_changed.emit()


## Picks this shift's goals from the goals this map can do.
func pick_goals() -> void:
	var pool := goal_pool.duplicate()
	pool.shuffle()
	shift_goals.clear()
	for id in pool.slice(0, GameConfig.GOALS_PER_SHIFT):
		shift_goals.append(id)


## The ids of this shift's goals that are done.
func goals_done() -> Array[String]:
	var jobs := history.slice(shift_start_index)
	var ids: Array[String] = []
	for id in shift_goals:
		if ShiftGoals.is_done(id, jobs, shift_crashes):
			ids.append(id)
	return ids


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


## Session 87: the small bill for a bump (10 Dh) or a fall (30 Dh): the "bill" in the impact.
func pay_crash_bill(impact: Dictionary) -> int:
	var bill := int(impact.get("bill", 0))
	if bill <= 0:
		return 0
	money -= bill
	shift_bills += bill
	money_changed.emit(money)
	stats_changed.emit()
	return bill


## Session 87: a fall (12 to 22 km/h) ends at the clinic too, with a small bill (the
## "bill" in the impact, 30 Dh: CRASH_FALL_HOSPITAL + CRASH_FALL_REPAIR). Your order and your
## shift go on. Returns the bills for the clinic screen (same keys as big_crash()).
func fall_clinic(impact: Dictionary) -> Dictionary:
	var paid := pay_crash_bill(impact)
	return {
		"hospital": GameConfig.CRASH_FALL_HOSPITAL, "repair": paid - GameConfig.CRASH_FALL_HOSPITAL,
		"severity": "a fall", "impact": impact.duplicate(true), "boss": false, "insured": false,
		"insured_cap": 0, "lost_order": false, "food": "", "paid": paid, "big": false,
	}


## A big crash (PRD "Crashes, bills and insurance"): an accepted order is cancelled
## (0 stars, no pay) and the bills come in. The boss pays for the first big crash.
## After that, insurance caps your share based on the impact severity.
## Returns the bill and whether an accepted order was lost for the clinic screen.
func big_crash(impact: Dictionary = {}) -> Dictionary:
	streak = 0
	var quote := CrashImpact.quote(impact)
	var insured_at_impact := bool(impact.get("insured_at_impact", insurance_on))
	var bills := {
		"hospital": quote["hospital"],
		"repair": quote["repair"],
		"severity": quote.get("severity", "severe"),
		"impact": impact.duplicate(true),
		"boss": not boss_paid_crash,
		"insured": insured_at_impact,
		"insured_cap": quote["insured"],
		"lost_order": current_order != null,
		"food": current_order.food if current_order != null else "",
		"paid": 0,
	}
	crash_shifts.append(shift_number)
	if not boss_paid_crash:
		boss_paid_crash = true
	elif insured_at_impact:
		bills["paid"] = quote["insured"]
	else:
		bills["paid"] = bills["hospital"] + bills["repair"]
	if current_order != null:
		# Cancelled: counts as a 0-star job in your rating, no pay, no XP.
		history.append({
			"restaurant": current_order.restaurant_name, "villa": current_order.villa_number, "address": current_order.address,
			"food": current_order.food, "pay": 0, "tip": 0, "insurance": 0, "xp": 0,
			"time": 0.0, "freshness": 0.0, "damage": 0.0, "stars": 0.0,
			"left_at_door": false, "cancelled": true,
		})
	current_order = null
	offered_order = null
	offered_orders.clear()
	offers_changed.emit()
	money -= bills["paid"]
	shift_bills += bills["paid"]
	money_changed.emit(money)
	stats_changed.emit()
	_set_stage(Stage.NONE)
	big_crashed.emit(bills)
	return bills


## The application was sent in: you're hired. The tutorial runs on your first order.
func hire(rider: String, country: String, look: int, company_id := "snackaroo") -> void:
	rider_name = rider.strip_edges()
	rider_country = country
	rider_look = look
	company = company_id if Companies.find(company_id) != {} else "snackaroo"
	hired = true
	tutorial_done = false
	save_soon()


## Session 88: switch to another company in the phone's Company app. Costs
## COMPANY_SWITCH_PRICE; you keep your stars, level and everything you own. False if you
## can't (same company, unknown company, not enough money, or while carrying an order).
func switch_company(id: String) -> bool:
	if id == company or Companies.find(id) == {} or money < GameConfig.COMPANY_SWITCH_PRICE or current_order != null:
		return false
	money -= GameConfig.COMPANY_SWITCH_PRICE
	company = id
	money_changed.emit(money)
	stats_changed.emit()
	company_changed.emit(id)
	save_soon()
	return true


## Big crashes in the last CRASH_WEEK_SHIFTS shifts (a "week"), for the clinic screen.
func crashes_this_week() -> int:
	var count := 0
	for number in crash_shifts:
		if number > shift_number - GameConfig.CRASH_WEEK_SHIFTS:
			count += 1
	return count


## Starts a new shift: a full clock and a fresh summary.
## new_number false: the same shift again (you quit before it ended), so the day stays too.
func start_shift(new_number := true) -> void:
	if new_number:
		shift_number += 1
		if shift_number > 1:
			day_kind = tomorrow_kind
		tomorrow_kind = ReplayCatalog.next_day(day_kind)
	shift_finished = false
	shift_new_bests.clear()
	collection_bonus_this_shift = 0
	shift_time_left = GameConfig.SHIFT_LENGTH
	shift_clock_out = false
	shift_start_index = history.size()
	shift_bills = 0
	shift_crashes = 0
	_goal_bonus_paid = false
	last_goals_done.clear()
	pick_goals()
	shift_started.emit()


## True while new orders may still pop up (the shift clock hasn't run out).
func shift_open() -> bool:
	return not shift_clock_out


## Continuous game time at the fixed rate (one active second = one game minute).
## The display rounds to whole minutes; schedules and sunlight use this precise value.
func clock_hours() -> float:
	var elapsed := clampf(GameConfig.SHIFT_LENGTH - shift_time_left, 0.0, GameConfig.SHIFT_LENGTH)
	return minf(GameConfig.SHIFT_START_HOUR + elapsed * GameConfig.GAME_MINUTES_PER_REAL_SECOND / 60.0,
			GameConfig.SHIFT_END_HOUR)


## The shift's numbers for the summary screen: deliveries, cancelled, average stars,
## pay, tips, insurance, bills, xp and earned (what you took home after all costs).
func shift_summary() -> Dictionary:
	var jobs := history.slice(shift_start_index)
	var summary := {"deliveries": 0, "cancelled": 0, "stars": 0.0, "pay": 0, "tips": 0,
			"insurance": 0, "bills": shift_bills, "xp": 0, "earned": 0,
			"day": day_kind, "tomorrow": tomorrow_kind, "collection_bonus": collection_bonus_this_shift,
			"new_bests": shift_new_bests.duplicate()}
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
	# Session 32: the shift goals, and 15 Dh for each one done.
	summary["goals"] = []
	summary["goal_bonus"] = 0
	for id in shift_goals:
		var done := ShiftGoals.is_done(id, jobs, shift_crashes)
		summary["goals"].append({"id": id, "text": ShiftGoals.ALL.get(id, id), "done": done})
		if done:
			summary["goal_bonus"] += GameConfig.GOAL_BONUS
	summary["earned"] = summary["pay"] + summary["tips"] + summary["goal_bonus"] + collection_bonus_this_shift - summary["insurance"] - summary["bills"]
	return summary


## The clock ran out: the order on the phone (if any) goes away without counting as a skip.
func clock_out() -> void:
	shift_clock_out = true
	if stage == Stage.OFFERED:
		offered_order = null
		offered_orders.clear()
		offers_changed.emit()
		_set_stage(Stage.NONE)


## Ends the shift and sends the summary.
func end_shift() -> Dictionary:
	shift_clock_out = true
	shift_finished = true
	var summary := shift_summary()
	if summary["goal_bonus"] > 0 and not _goal_bonus_paid:
		_goal_bonus_paid = true
		money += summary["goal_bonus"]  # the goal bonus goes into the wallet (Session 32)
		money_changed.emit(money)
	if summary["earned"] > int(personal_bests.get("earnings", 0)):
		personal_bests["earnings"] = summary["earned"]
		_note_best("Best shift earnings: %d Dh" % summary["earned"])
	if summary["deliveries"] > int(personal_bests.get("deliveries", 0)):
		personal_bests["deliveries"] = summary["deliveries"]
		_note_best("Most deliveries in a shift: %d" % summary["deliveries"])
	summary["new_bests"] = shift_new_bests.duplicate()
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


## A second offer shares the first offer's single countdown and acceptance decision.
func offer_choices(orders: Array[Order]) -> bool:
	if orders.is_empty() or not offer_order(orders[0]):
		return false
	offered_orders.assign(orders)
	offers_changed.emit()
	return true


func day_label() -> String:
	return ReplayCatalog.day_name(day_kind)


func freshness_multiplier() -> float:
	return GameConfig.HOT_NOON_FRESHNESS_MULTIPLIER if day_kind == "hot_noon" else 1.0


func order_delay() -> float:
	return GameConfig.ORDER_NEXT_DELAY * (GameConfig.RUSH_HOUR_ORDER_DELAY_SHARE if day_kind == "rush_hour" else 1.0)


func regular_stage(id: String) -> String:
	var visits := int(regular_visits.get(id, 0))
	if visits >= GameConfig.BEST_FRIEND_VISITS:
		return "best_friends"
	return "friendly" if visits >= GameConfig.FRIENDLY_VISITS else "first"


func _note_best(message: String) -> void:
	if message.begins_with("Longest five-star streak:"):
		shift_new_bests = shift_new_bests.filter(func(line): return not line.begins_with("Longest five-star streak:"))
	if not message in shift_new_bests:
		shift_new_bests.append(message)


func _record_route_best(order: Order, seconds: float) -> bool:
	if seconds <= 0.0:
		return false
	var routes: Dictionary = personal_bests.get("routes", {})
	var key := "%s>%d:%s" % [order.restaurant_id, order.villa_number, order.special]
	if routes.has(key) and float(routes[key]) <= seconds:
		return false
	routes[key] = seconds
	personal_bests["routes"] = routes
	var labels: Dictionary = personal_bests.get("route_labels", {})
	labels[key] = "%s to %s%s" % [order.restaurant_name, order.address, " · " + GameConfig.SPECIAL_NAMES.get(order.special, order.special) if order.special != "" else ""]
	personal_bests["route_labels"] = labels
	var whole_seconds := int(seconds)
	_note_best("Fastest ride: %s · %d:%02d" % [labels[key], whole_seconds / 60, whole_seconds % 60])
	return true


## Catalogues are runtime map data; lifetime stamps and claims are separately saved.
func configure_collections(villas: Array) -> void:
	home_catalog.clear()
	venue_catalog.clear()
	for villa in villas:
		var key := str(villa["number"])
		if villa.get("kind", "") == "spot":
			venue_catalog[key] = villa.get("address", "Reception")
		elif villa.get("cluster", "") != "":
			home_catalog[key] = {"cluster": villa["cluster"], "house": villa.get("house", 0), "address": villa.get("address", key)}
	collection_changed.emit()


func _stamp_delivery(order: Order) -> int:
	var key := str(order.villa_number)
	var bonus := 0
	if order.cluster != "":
		visited_homes[key] = {"cluster": order.cluster, "address": order.address}
		var count := cluster_stamps(order.cluster)
		var paid := int(collection_claims.get(order.cluster, 0))
		var earned := count / GameConfig.COLLECTION_STAMP_INTERVAL
		if earned > paid:
			bonus = (earned - paid) * GameConfig.COLLECTION_STAMP_BONUS
			collection_claims[order.cluster] = earned
			money += bonus
			collection_bonus_this_shift += bonus
		if count >= GameConfig.COLLECTION_HOMES_PER_CLUSTER:
			owned_collection_rewards[order.cluster] = "gold_" + order.cluster
	elif venue_catalog.has(key):
		visited_venues[key] = order.address
	collection_changed.emit()
	return bonus


func cluster_stamps(cluster: String) -> int:
	return visited_homes.values().filter(func(home): return home.get("cluster", "") == cluster).size()


func note_animal_met(id: String, animal_name: String) -> void:
	if id == "" or animals_met.has(id):
		return
	animals_met[id] = animal_name
	collection_changed.emit()
	save_soon()


func note_customer_line(line: String) -> void:
	if line == "" or lines_heard.has(line):
		return
	lines_heard[line] = true
	collection_changed.emit()
	save_soon()


func upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))


## The shop validates its cart; the wallet mutation and save happen atomically here.
func buy_shop_cart(total: int, levels: Dictionary, owned: Dictionary, equipped: Dictionary) -> bool:
	if total < 0 or money < total:
		return false
	upgrade_levels = levels.duplicate(true)
	owned_items = owned.duplicate(true)
	equipped_cosmetics = equipped.duplicate(true)
	money -= total
	money_changed.emit(money)
	stats_changed.emit()
	save_soon()
	return true
