class_name OrderMaker
extends RefCounted
## Makes one new order (Session 32; the DeliveryManager asks it). It picks the shop and the
## home, and sometimes makes the order special (rush, fragile cake, neighbour, big family),
## a regular customer's order, a school order (only 08:00 to 15:00, lots at lunch), a stables
## order or a farm stall pickup. The hour on the shift clock is handed in, so the smoke test
## can try any time of day. All numbers are in game_config.gd (Session 32 block).

var places: PlaceBuilder
## The shift clock in hours (11.5 = 11:30).
var hour := 8.0
var day_kind := "normal"
var regular_visits: Dictionary = {}
var streak := 0
## Chances, handed in by the DeliveryManager (the smoke test turns them off for its old checks).
var special_chance := GameConfig.SPECIAL_ORDER_CHANCE
var regular_chance := GameConfig.REGULAR_ORDER_CHANCE


func _init(place_builder: PlaceBuilder, clock_hour: float) -> void:
	places = place_builder
	hour = clock_hour


## A new order. restaurant_id / villa_number pick an exact shop or home (the tutorial and the
## tests use them: then it's never a regular). special: force one kind of special order.
## boring: you skipped too much, so it's a short ride for the lowest pay (never special).
func make(restaurant_id := "", villa_number := 0, special := "", boring := false) -> Order:
	var exact := restaurant_id != "" or villa_number != 0
	if not exact and not boring and special == "" and randf() < regular_chance:
		var regular := pick_regular()
		if not regular.is_empty():
			return make_regular(regular)
	if not exact and not boring and special == "" and randf() < special_chance:
		special = _pick_special()
	var restaurant := _find(places.restaurants, "id", restaurant_id)
	if special == "fragile" and restaurant_id == "":
		restaurant = _find(places.restaurants, "id", GameConfig.FRAGILE_SHOP)
	if restaurant.is_empty():
		restaurant = _pick_shop()
	var from := places.restaurant_door(restaurant["id"])
	var villa := _find(places.villas, "number", villa_number)
	if villa.is_empty():
		villa = _short_ride_villa(from) if boring else _pick_drop_off(special != "neighbour", from)
	var order := _order_for(restaurant, villa)
	order.food = restaurant.get("foods", [restaurant["food"]]).pick_random()  # the farm stall sells two
	order.boring = boring
	order.base_pay = GameConfig.ORDER_PAY_MIN if boring else pay_for(from.distance_to(places.villa_door(villa["number"])))
	# Reception staff take indoor deliveries at the counter.
	if randf() < GameConfig.ORDER_LEAVE_AT_DOOR_CHANCE and not villa.get("interior", false):
		order.leave_at_door = true
		order.note = GameConfig.ORDER_LEAVE_AT_DOOR_NOTE
	elif randf() < GameConfig.ORDER_NOTE_CHANCE:
		order.note = GameConfig.ORDER_NOTES.pick_random()
	_make_special(order, special)
	_apply_day_pay(order)
	return order


## A regular customer's usual order (shop, food and home from REGULARS).
func make_regular(regular: Dictionary) -> Order:
	var restaurant := _find(places.restaurants, "id", regular["shop"])
	var villa := _find(places.villas, "number", regular["villa"])
	var order := _order_for(restaurant, villa)
	order.food = regular["food"]
	order.regular = regular["name"]
	order.regular_id = regular["id"]
	order.who = regular["who"]
	order.look = regular["look"]
	order.base_pay = pay_for(places.restaurant_door(restaurant["id"]).distance_to(places.villa_door(villa["number"])))
	order.pay = order.base_pay
	_apply_day_pay(order)
	return order


## One of the regulars who can order now (Ms Dana only while the school is open), or {}.
func pick_regular() -> Dictionary:
	var open: Array = []
	for regular in places.regulars:
		var known := not _find(places.villas, "number", regular["villa"]).is_empty() \
				and not _find(places.restaurants, "id", regular["shop"]).is_empty()
		if known and (regular["villa"] != GameConfig.SCHOOL_SPOT or school_open(hour)):
			open.append(regular)
	return {} if open.is_empty() else open.pick_random()


## Nobody home on a neighbour order: another home in the same cluster (on maps without
## clusters, one of the nearest homes). {} if there's none.
func neighbour_for(villa_number: int) -> Dictionary:
	var home := _find(places.villas, "number", villa_number)
	if home.is_empty():
		return {}
	var others := _homes().filter(func(v): return v["number"] != villa_number)
	var cluster: String = home.get("cluster", "")
	if cluster != "":
		others = others.filter(func(v): return v.get("cluster", "") == cluster)
	else:
		var door := places.villa_door(villa_number)
		_sort_by_villa_distance(others, door)
		others = others.slice(0, GameConfig.NEIGHBOUR_CHOICES)
	return {} if others.is_empty() else others.pick_random()


## True between 08:00 and 15:00, when the school takes orders.
static func school_open(clock_hour: float) -> bool:
	return clock_hour >= GameConfig.SCHOOL_OPEN_HOUR and clock_hour < GameConfig.SCHOOL_CLOSE_HOUR


## True during the school lunch rush (11:30 to 12:30).
static func is_lunch(clock_hour: float) -> bool:
	return clock_hour >= GameConfig.LUNCH_START_HOUR and clock_hour < GameConfig.LUNCH_END_HOUR


## Session 89: the kind of order for the phone's Jobs app: "fragile" (a fragile cake),
## "vip" (a regular or a big family order: bigger pay or tips), "far" (the drop-off is more
## than ORDER_FAR_METRES from the shop) or "normal" (everything else). First match wins.
func kind_of(order: Order) -> String:
	if order.special == "fragile":
		return "fragile"
	if order.regular_id != "" or order.special == "family":
		return "vip"
	if places.restaurant_door(order.restaurant_id).distance_to(places.villa_door(order.villa_number)) > GameConfig.ORDER_FAR_METRES:
		return "far"
	return "normal"


## Pay for a ride of `metres` (straight line, shop to home), 8 to 15 Dh.
static func pay_for(metres: float) -> int:
	var pay := roundi(GameConfig.ORDER_PAY_BASE + metres * GameConfig.ORDER_PAY_PER_METRE)
	return clampi(pay, GameConfig.ORDER_PAY_MIN, GameConfig.ORDER_PAY_MAX)


## The special order's rule: its pay (the meters and the bike read order.special for the rest).
func _make_special(order: Order, special: String) -> void:
	order.special = special
	order.pay = order.base_pay
	match special:
		"rush":
			order.pay = roundi(order.base_pay * GameConfig.RUSH_PAY_SHARE)
		"fragile":
			order.food = GameConfig.FRAGILE_FOOD
		"neighbour":
			order.pay = order.base_pay + GameConfig.NEIGHBOUR_BONUS
			order.leave_at_door = false  # you need to knock to find out nobody's home
			order.note = ""
		"family":
			order.pay = order.base_pay * GameConfig.FAMILY_PAY_TIMES


## A random special kind this map can do (fragile cakes need Sunrise Bakery).
func _pick_special() -> String:
	var kinds: Array = GameConfig.SPECIAL_KINDS.duplicate()
	if _find(places.restaurants, "id", GameConfig.FRAGILE_SHOP).is_empty():
		kinds.erase("fragile")
	return kinds.pick_random()


## The shop: the farm stall for about 1 in 8 orders, otherwise any other shop.
func _pick_shop() -> Dictionary:
	var farm := _find(places.restaurants, "id", GameConfig.FARM_SHOP)
	if farm.is_empty():
		return places.restaurants.pick_random()
	if randf() < GameConfig.FARM_PICKUP_CHANCE:
		return farm
	return places.restaurants.filter(func(r): return r["id"] != GameConfig.FARM_SHOP).pick_random()


## Where it goes: sometimes the school (only while it's open, lots at lunch) or the stables,
## otherwise a home. spots_ok = false: always a home (neighbour orders). from: the shop door.
func _pick_drop_off(spots_ok: bool, from: Vector3) -> Dictionary:
	var school := _find(places.villas, "number", GameConfig.SCHOOL_SPOT)
	var stables := _find(places.villas, "number", GameConfig.STABLES_SPOT)
	if spots_ok and not school.is_empty() and school_open(hour):
		var chance := GameConfig.LUNCH_SCHOOL_CHANCE if is_lunch(hour) else GameConfig.SCHOOL_ORDER_CHANCE
		if randf() < chance:
			return school
	if spots_ok and not stables.is_empty() and randf() < GameConfig.STABLES_ORDER_CHANCE:
		return stables
	var receptions: Array = places.villas.filter(func(v): return v["number"] in [903, 904])
	if spots_ok and not receptions.is_empty() and randf() < GameConfig.RECEPTION_ORDER_CHANCE:
		return receptions.pick_random()
	var homes := _homes()
	if randf() < GameConfig.ORDER_NEARBY_HOME_CHANCE:
		# Like a real delivery app: many orders are for homes not far from the shop.
		_sort_by_villa_distance(homes, from)
		homes = homes.slice(0, maxi(1, homes.size() / 2))
	return homes.pick_random()


## Who comes to the door, the address and the cluster for a shop and a home.
func _order_for(restaurant: Dictionary, villa: Dictionary) -> Order:
	var order := Order.new()
	order.restaurant_id = restaurant["id"]
	order.restaurant_name = restaurant["name"]
	order.food = restaurant["food"]
	order.villa_number = villa["number"]
	order.address = villa.get("address", "Villa %d" % villa["number"])
	order.map_address = villa.get("map_address", order.address)
	order.cluster = villa.get("cluster", "")
	if villa["number"] == GameConfig.SCHOOL_SPOT:
		order.who = ["teacher", "kid"].pick_random()
		order.lunch = is_lunch(hour)
	elif villa["number"] == GameConfig.STABLES_SPOT:
		order.who = ["rider", "groom"].pick_random()
	elif villa["number"] == 903:
		order.who = "institute"
	elif villa["number"] == 904:
		order.who = "gym"
	return order


## Every real home (not the school booth or the stable office).
func _homes() -> Array:
	return places.villas.filter(func(v): return not PlaceBuilder.is_spot(v))


## One of the homes closest to the given shop door (for boring orders). Never the school
## after 15:00.
func _short_ride_villa(from: Vector3) -> Dictionary:
	var villas: Array = places.villas.filter(func(v): return v["number"] != GameConfig.SCHOOL_SPOT or school_open(hour))
	_sort_by_villa_distance(villas, from)
	return villas.slice(0, GameConfig.ORDER_BORING_CHOICES).pick_random()


## The entry in `list` whose `key` is `value`, or {} if there isn't one.
static func _find(list: Array, key: String, value) -> Dictionary:
	for item in list:
		if item[key] == value:
			return item
	return {}


func _apply_day_pay(order: Order) -> void:
	if day_kind == "rush_hour":
		order.base_pay = roundi(order.base_pay * GameConfig.RUSH_HOUR_PAY_MULTIPLIER)
		order.pay = roundi(order.pay * GameConfig.RUSH_HOUR_PAY_MULTIPLIER)


## A better offer uses the existing pay, journey and customer rules, including pay caps.
func better_than(order: Order) -> Order:
	for attempt in 24:
		var candidate := make()
		if is_better(candidate, order):
			return candidate
	# A deterministic fallback makes a useful pair even when random sampling repeats.
	var home_choices := _homes()
	for restaurant in places.restaurants:
		if home_choices.is_empty():
			break
		var from := places.restaurant_door(restaurant["id"])
		_sort_by_villa_distance(home_choices, from)
		for villa in [home_choices.front(), home_choices.back()]:
			var candidate := make(restaurant["id"], villa["number"])
			if is_better(candidate, order):
				return candidate
	for regular in places.regulars:
		if regular["villa"] == GameConfig.SCHOOL_SPOT and not school_open(hour):
			continue
		var candidate := make_regular(regular)
		if is_better(candidate, order):
			return candidate
	return null  # a map with just one identical possible job has no honest alternative


func is_better(candidate: Order, original: Order) -> bool:
	if candidate == null:
		return false
	var candidate_ride := places.restaurant_approach(candidate.restaurant_id).distance_to(places.villa_approach(candidate.villa_number))
	var original_ride := places.restaurant_approach(original.restaurant_id).distance_to(places.villa_approach(original.villa_number))
	return candidate.pay > original.pay or candidate_ride + 0.1 < original_ride or _tip_chance(candidate) > _tip_chance(original)


func _tip_chance(order: Order) -> float:
	var base := GameConfig.TIP_CHANCE
	if order.regular != "":
		base = GameConfig.BEST_FRIEND_TIP_CHANCE if regular_visits.get(order.regular_id, 0) >= GameConfig.BEST_FRIEND_VISITS else GameConfig.REGULAR_TIP_CHANCE
	elif order.special == "fragile":
		base = GameConfig.FRAGILE_TIP_CHANCE
	base += minf(streak * GameConfig.STREAK_TIP_STEP, GameConfig.STREAK_TIP_MAX)
	if day_kind == "shop_special" and order.restaurant_id == "gelato":
		base *= GameConfig.SHOP_SPECIAL_TIP_MULTIPLIER
	return clampf(base, 0.0, 1.0)


## Calculate each door distance once while preserving the sort's input order and comparisons.
func _sort_by_villa_distance(villas: Array, from: Vector3) -> void:
	var ranked: Array = []
	for villa: Dictionary in villas:
		ranked.append([villa, _villa_point(villa).distance_to(from)])
	ranked.sort_custom(func(a, b): return a[1] < b[1])
	for index in villas.size():
		villas[index] = ranked[index][0]


func _villa_point(villa: Dictionary) -> Vector3:
	if villa.get("interior", false):
		return VenueBuilder.world_point(villa, VenueBuilder.counter_local(places.villa_size_of(villa)))
	return PlaceBuilder.door_point(villa["position"], villa["facing"], places.villa_size_of(villa))
