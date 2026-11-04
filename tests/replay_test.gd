extends SceneTree
## Replay progress checks. Run with an isolated Godot user-data directory.
const TEST_SAVE := "user://replay_test_save.json"
var state: Node
var failed := false
var maker_script: Script
var customer_script: Script


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	maker_script = load("res://scripts/order_maker.gd")
	customer_script = load("res://scripts/customer_spawner.gd")
	state.save_path = TEST_SAVE
	state.reset()
	state.shift_goals.clear()
	state.goal_pool.clear()
	_check_clock_and_days()
	_check_streak_and_records()
	_check_crash_aware_streak_goal()
	_check_choices()
	_check_friendship()
	_check_collections_and_save()
	_check_shop_transaction()
	_check_legacy_migration()
	SaveGame.delete(TEST_SAVE)
	state.save_path = "user://replay_test_finished.json"
	if not failed:
		print("RESULT: PASS replay progress")
	quit(1 if failed else 0)


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
	print("PASS: " if ok else "FAIL: ", message)


func _order(number := 101, cluster := "C1", shop := "pizza") -> Order:
	var order := Order.new()
	order.villa_number = number
	order.cluster = cluster
	order.address = "Villa %d, %s" % [number, cluster]
	order.restaurant_id = shop
	order.restaurant_name = "Test " + shop
	order.food = "pizza"
	order.base_pay = 10
	order.pay = 10
	return order


func _deliver(order: Order, seconds := 20.0, damage := 100.0) -> void:
	state.offer_order(order)
	state.accept_offer()
	state.pick_up()
	state.ride_time = seconds
	state.set_meters(100.0, 100.0, damage)
	state.deliver()


func _check_clock_and_days() -> void:
	_expect(is_equal_approx(GameConfig.SHIFT_LENGTH, 600.0), "8 AM–6 PM is exactly 600 active real seconds")
	state.shift_time_left = GameConfig.SHIFT_LENGTH - 1.0
	_expect(is_equal_approx(state.clock_hours(), 8.0 + 1.0 / 60.0), "one real second advances exactly one game minute")
	state.day_kind = "hot_noon"
	_expect(state.freshness_multiplier() > 1.0, "Hot Noon spoils food faster")
	state.day_kind = "rush_hour"
	_expect(state.order_delay() < GameConfig.ORDER_NEXT_DELAY, "Rush Hour offers arrive sooner")
	var places := PlaceBuilder.new()
	places.restaurants = [{"id": "pizza", "name": "Test Pizza", "food": "pizza", "position": Vector3.ZERO, "facing": 0.0}]
	places.villas = [{"number": 101, "position": Vector3(0, 0, 50), "facing": 0.0, "cluster": "C1"}]
	var maker = maker_script.new(places, 8.0)
	maker.day_kind = state.day_kind
	var rush: Order = maker.make("pizza", 101)
	state.day_kind = "normal"
	maker.day_kind = state.day_kind
	var normal: Order = maker.make("pizza", 101)
	_expect(rush.pay == roundi(normal.pay * GameConfig.RUSH_HOUR_PAY_MULTIPLIER), "Rush Hour applies ten percent more delivery pay")
	state.day_kind = "shop_special"
	var gelato := _order(101, "C1", "gelato")
	_expect(is_equal_approx(state.tip_chance(gelato), GameConfig.TIP_CHANCE * 2.0), "Brain Freeze special doubles that shop's tip chance")
	state.tomorrow_kind = "rush_hour"
	state.start_shift()
	_expect(state.day_kind == "rush_hour" and state.tomorrow_kind != "rush_hour", "next shift uses the announced special and previews a different tomorrow")
	_expect(state.shift_summary()["tomorrow"] == state.tomorrow_kind, "summary contains the exact next shift special")
	places.free()
	state.reset()
	state.shift_goals.clear()


func _check_streak_and_records() -> void:
	for index in 6:
		_deliver(_order(101 + index))
	_expect(state.streak == 6 and state.personal_bests["streak"] == 6, "six five-star jobs build a saved personal best streak")
	_expect(is_equal_approx(state.tip_chance(_order()), GameConfig.TIP_CHANCE + GameConfig.STREAK_TIP_MAX), "streak bonus is capped at thirty percentage points")
	state.start_shift()
	_expect(state.streak == 6, "starting a new shift preserves the streak")
	_deliver(_order(), 30.0, 45.0)
	_expect(state.streak == 0, "a delivery below five stars resets the streak")
	_deliver(_order(), 10.0)
	_expect(state.last_result["new_route_best"] and state.last_result["perfect"], "all-green delivery is PERFECT and a faster comparable route sets a record")
	_deliver(_order(), 15.0)
	_expect(not state.last_result["new_route_best"], "a slower repeat does not replace the route record")
	_deliver(_order(101, "C1", "gelato"), 25.0)
	_expect(state.last_result["new_route_best"], "different pickup routes have independent ride records")
	state.note_crash()
	_expect(state.streak == 0, "a crash resets the streak immediately")
	var summary: Dictionary = state.end_shift()
	_expect(not summary["new_bests"].is_empty() and state.personal_bests["deliveries"] > 0, "shift summary reports personal bests")
	state.reset()
	state.shift_goals.clear()


func _check_crash_aware_streak_goal() -> void:
	state.reset()
	state.shift_goals.assign(["streak"])
	_deliver(_order())
	_deliver(_order())
	state.note_crash()
	_deliver(_order())
	_expect(state.streak == 1 and not "streak" in state.goals_done()
			and state.shift_summary()["goal_bonus"] == 0,
			"a minor crash breaks the shift goal as well as the phone streak")
	_deliver(_order())
	_deliver(_order())
	_expect("streak" in state.goals_done() and state.shift_summary()["goal_bonus"] == GameConfig.GOAL_BONUS,
			"three new five-star jobs after the crash earn the streak goal")
	state.note_crash()
	_expect("streak" in state.goals_done(), "a later crash does not revoke a streak goal already earned")
	_deliver(_order())
	_deliver(_order())
	_deliver(_order())
	state.start_shift()
	state.shift_goals.assign(["streak"])
	_deliver(_order())
	_expect(state.streak == 4 and not "streak" in state.goals_done(),
			"the shift goal counts only this shift even when the lifetime streak carries over")
	_deliver(_order())
	_deliver(_order())
	_expect("streak" in state.goals_done(), "a carried streak still earns the goal after three jobs this shift")
	state.reset()
	state.shift_goals.clear()


func _check_choices() -> void:
	var first := _order()
	var second := _order(102)
	second.pay = 14
	var choices: Array[Order] = [first, second]
	_expect(state.offer_choices(choices), "two offers can share one decision")
	_expect(state.accept_offer(1) and state.current_order == second, "choosing 2 accepts only the second order")
	_expect(state.offered_orders.is_empty() and is_equal_approx(state.acceptance_rate(), 1.0), "accepting a pair records one acceptance")
	state.pick_up()
	state.deliver()
	state.offer_choices(choices)
	state.skip_offer()
	_expect(is_equal_approx(state.acceptance_rate(), 0.5), "Q skipping both records one skip")
	state.reset()
	state.shift_goals.clear()


func _check_friendship() -> void:
	var regular := _order()
	regular.regular_id = "mariam"
	regular.regular = "Auntie Mariam"
	state.regular_visits["mariam"] = 0
	var first: String = customer_script.line_for(regular, "Sam")
	state.regular_visits["mariam"] = 3
	var friendly: String = customer_script.line_for(regular, "Sam")
	state.regular_visits["mariam"] = 8
	var best: String = customer_script.line_for(regular, "Sam")
	_expect(first != friendly and friendly != best, "regulars use distinct first-visit, friendly and best-friend dialogue")
	state.streak = 0
	_expect(is_equal_approx(state.tip_chance(regular), 0.7), "eight visits makes a best friend's base tip chance seventy percent")
	state.note_customer_line(best)
	state.note_customer_line(best)
	state.note_animal_met("cat_lulu", "Lulu")
	state.note_animal_met("cat_lulu", "Lulu")
	_expect(state.lines_heard.size() == 1 and state.animals_met.size() == 1, "lines and named animal meetings are unique collection entries")


func _check_collections_and_save() -> void:
	var catalog: Array = []
	for cluster in range(1, 6):
		for house in range(1, 101):
			catalog.append({"number": cluster * 100 + house, "house": house, "cluster": "C%d" % cluster, "address": "Villa %d, Cluster %d" % [house, cluster]})
	for number in range(901, 905):
		catalog.append({"number": number, "kind": "spot", "address": "Venue %d" % number})
	state.configure_collections(catalog)
	var total_bonus := 0
	for villa in catalog:
		var order := _order(villa["number"], villa.get("cluster", ""))
		total_bonus += state._stamp_delivery(order)
	_expect(total_bonus == 400, "five clusters each award four twenty-dirham stamp milestones")
	_expect(state.visited_homes.size() == 500 and state.visited_venues.size() == 4, "all 500 homes and all four venues have independent stamps")
	_expect(state.cluster_stamps("C1") == 100 and state.visited_homes["200"]["cluster"] == "C1", "Villa 100 retains its explicit cluster across the numbering boundary")
	_expect(state.owned_collection_rewards.size() == 5 and state.owned_collection_rewards["C1"] == "gold_C1", "completed clusters unlock gold delivery box colours")
	_expect(state._stamp_delivery(_order()) == 0, "repeat delivery cannot pay a milestone twice")
	for index in 240:
		state.history.append({"villa": 101, "pay": 10, "tip": 0, "insurance": 0, "xp": 25, "stars": 5.0})
	state.streak = 4
	state.upgrade_levels = {"stamina": 2, "insulated_bag": 1}
	state.owned_items = {"orange_helmet": true}
	state.equipped_cosmetics = {"box": "gold_C1"}
	state.tomorrow_kind = "hot_noon"
	var before_money: int = state.money
	_expect(SaveGame.save(state, TEST_SAVE), "replay and equipment progress can be saved")
	state.reset()
	_expect(SaveGame.load_into(state, TEST_SAVE), "version 2 replay save can be loaded")
	_expect(state.history.size() == SaveGame.HISTORY_KEPT and state.visited_homes.size() == 500, "collection survives beyond the 200-delivery history limit")
	_expect(state.streak == 4 and state.tomorrow_kind == "hot_noon" and state.money == before_money, "saved streak, special preview and wallet survive reopening")
	_expect(state.upgrade_level("stamina") == 2 and state.equipped_cosmetics["box"] == "gold_C1", "saved equipment and equipped cosmetics survive reopening")
	_expect(state.animals_met.has("cat_lulu") and state.lines_heard.size() == 1, "named animals and heard dialogue survive reopening")


func _check_legacy_migration() -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "money": 173, "xp": 460, "rider_name": "Old Rider", "regular_visits": {"mariam": 3}, "history": [{"villa": 101, "cluster": "C1", "address": "Villa 1, Cluster 1", "stars": 5.0, "pay": 10, "tip": 2, "xp": 25, "insurance": 2}, {"villa": 901, "address": "School Gate", "stars": 5.0, "pay": 10, "tip": 0, "xp": 25, "insurance": 2}]}))
	file.close()
	state.reset()
	_expect(SaveGame.load_into(state, TEST_SAVE), "legacy version 1 save still loads")
	_expect(state.money == 173 and state.xp == 460 and state.rider_name == "Old Rider", "migration preserves the player's wallet, XP and identity")
	_expect(state.visited_homes.has("101") and state.regular_visits["mariam"] == 3 and state.streak == 0, "migration imports known stamps and visits with safe defaults for new replay progress")
	_expect(state.visited_venues.get("901", "") == "School Gate", "migration preserves known venue deliveries as well as home stamps")


func _check_shop_transaction() -> void:
	state.money = 50
	state.upgrade_levels.clear()
	_expect(not state.buy_shop_cart(-1, {"gps": 1}, {}, {}) and state.money == 50, "negative cart totals cannot increase the wallet")
	_expect(not state.buy_shop_cart(51, {"gps": 1}, {}, {}) and state.upgrade_level("gps") == 0, "an unaffordable cart cannot partially grant its gear")
	var levels := {"gps": 1}
	_expect(state.buy_shop_cart(50, levels, {"paint_teal": true}, {"paint": "paint_teal"}) and state.money == 0 and state.upgrade_level("gps") == 1, "checkout atomically grants the validated gear and charges once")
	levels["gps"] = 9
	_expect(state.upgrade_level("gps") == 1, "shop state is copied instead of retaining a mutable cart reference")
