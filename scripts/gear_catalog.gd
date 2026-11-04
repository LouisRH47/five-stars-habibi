class_name GearCatalog
extends RefCounted
## The shop's contents. All prices live in GameConfig; effect IDs match bike/meters/GPS.

const UPGRADES := [
	{"id": "gps", "name": "GPS route", "level": 2, "description": "A glowing route on the road and mini-map."},
	{"id": "bell", "name": "Louder bell", "level": 2, "description": "Your bell reaches twice as far."},
	{"id": "insulated_bag", "name": "Insulated bag", "level": 3, "description": "Food loses freshness 25% slower."},
	{"id": "anti_spill", "name": "Anti-spill box", "level": 3, "description": "Bumps damage your food 30% less."},
	{"id": "stamina", "name": "Stamina +10%", "level": 3, "max": 10, "description": "Sprint 10% longer per level, up to +100%."},
	{"id": "brakes", "name": "Better brakes", "level": 4, "description": "Stop faster and spill less when braking."},
	{"id": "tyres", "name": "Comfy tyres", "level": 4, "description": "Softer bumps and smoother hills."},
	{"id": "aluminium", "name": "Aluminium frame", "level": 4, "description": "+1 km/h top speed."},
	{"id": "carbon", "name": "Carbon frame", "level": 7, "requires": "aluminium", "description": "+2 km/h more. Needs the aluminium frame."},
	{"id": "rocket", "name": "Rocket booster", "level": 10, "description": "X: 80 km/h for 4 seconds. 30 s recharge. Triple bump damage; every crash is big."},
]
const COLOURS := [
	{"name": "Teal", "key": "teal", "colour": Color(0.12, 0.53, 0.59)},
	{"name": "Sunset", "key": "sunset", "colour": Color(0.9, 0.27, 0.16)},
	{"name": "Sand", "key": "sand", "colour": Color(0.88, 0.78, 0.56)},
]
const TYPES := ["caps", "glasses", "helmets", "tops", "shoes", "bags"]
const TYPE_NAMES := {"caps": "Caps", "glasses": "Glasses", "helmets": "Helmets", "tops": "Tops",
		"shoes": "Trainers", "bags": "Backpacks", "paint": "Bike paint", "box": "Box colours", "upgrades": "Upgrades"}


static func items(shop := "bikes") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if shop == "bikes":
		for upgrade: Dictionary in UPGRADES:
			result.append(upgrade.merged({"category": "upgrades", "slot": "upgrade"}))
	for category: String in (["paint", "box"] if shop == "bikes" else TYPES):
		for colour: Dictionary in COLOURS:
			var slot := "head" if category in ["caps", "helmets"] else category
			result.append({"id": "%s_%s" % [category, colour["key"]],
					"name": "%s %s" % [colour["name"], TYPE_NAMES[category].to_lower()],
					"category": category, "slot": slot, "colour": colour["colour"], "level": 1,
					"description": "A fresh look. Try it on before you buy."})
	if shop == "bikes":
		result.append({"id": "box_gold", "name": "Gold delivery box", "category": "box", "slot": "box",
				"colour": Color(0.96, 0.69, 0.18), "level": 1, "collection": true,
				"description": "Your reward for delivering to every home in a cluster."})
	return result


static func find(id: String) -> Dictionary:
	for item in items("bikes") + items("clothes"):
		if item["id"] == id:
			return item
	return {}


static func price(item: Dictionary, owned_level := 0) -> int:
	if item.get("collection", false):
		return 0
	if item.get("slot", "") == "upgrade":
		return int(GameConfig.GEAR_PRICES[item["id"]]) + (owned_level * GameConfig.STAMINA_PRICE_STEP if item["id"] == "stamina" else 0)
	return int(GameConfig.COSMETIC_PRICES[item["category"]])


static func next_goal(state: Node) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var repeat_stamina: Dictionary = {}
	for item: Dictionary in UPGRADES:
		# Introduce stamina once, then show the new equipment before its repeat buys.
		if item["id"] == "stamina" and state.upgrade_level("stamina") > 0:
			repeat_stamina = item
			continue
		if item["id"] == "rocket" and not repeat_stamina.is_empty():
			candidates.append(repeat_stamina)
		candidates.append(item)
	for item: Dictionary in candidates:
		var owned: int = state.upgrade_level(item["id"])
		if owned >= int(item.get("max", 1)):
			continue
		var cost := price(item.merged({"slot": "upgrade"}), owned)
		return {"id": item["id"], "name": item["name"], "level": item["level"], "price": cost,
				"remaining": maxi(0, cost - state.money),
				"progress": minf(clampf(float(state.money) / maxf(cost, 1), 0, 1), clampf(float(state.level()) / item["level"], 0, 1)),
				"description": "%s · Level %d · %d Dh to go" % [item["name"], item["level"], maxi(0, cost - state.money)]}
	return {"id": "", "name": "All upgrades owned", "level": 1, "price": 0,
			"remaining": 0, "progress": 1.0, "description": "All upgrades owned — enjoy the ride!"}
