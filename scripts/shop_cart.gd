class_name ShopCart
extends RefCounted
## An atomic cart: re-quotes every item before charging or changing equipment.

var state: Node
var entries: Array[String] = []


func _init(game_state: Node) -> void:
	state = game_state


func add(id: String) -> Dictionary:
	var trial := entries.duplicate()
	trial.append(id)
	var quoted := _quote(trial)
	if quoted["ok"]:
		entries.append(id)
	return quoted


func quote() -> Dictionary:
	return _quote(entries)


func clear() -> void:
	entries.clear()


func checkout() -> Dictionary:
	if entries.is_empty():
		return {"ok": false, "error": "Your cart is empty."}
	var quoted := quote()
	if not quoted["ok"]:
		return quoted
	if state.money < quoted["total"]:
		return {"ok": false, "error": "You need %d Dh more." % (quoted["total"] - state.money)}
	if not state.buy_shop_cart(quoted["total"], quoted["levels"], quoted["owned"], quoted["equipped"]):
		return {"ok": false, "error": "Your wallet changed. Please try again."}
	entries.clear()
	return quoted


func _quote(ids: Array) -> Dictionary:
	var levels: Dictionary = state.upgrade_levels.duplicate()
	var owned: Dictionary = state.owned_items.duplicate()
	var equipped: Dictionary = state.equipped_cosmetics.duplicate()
	var total := 0
	for id: String in ids:
		var item := GearCatalog.find(id)
		if item.is_empty():
			return {"ok": false, "error": "That item is unavailable."}
		if state.level() < int(item["level"]):
			return {"ok": false, "error": "%s unlocks at Rider Level %d." % [item["name"], item["level"]]}
		if item.get("collection", false) and state.owned_collection_rewards.is_empty():
			return {"ok": false, "error": "Complete a cluster's delivery stamp card first."}
		if item["slot"] == "upgrade":
			var level := int(levels.get(id, 0))
			if level >= int(item.get("max", 1)):
				return {"ok": false, "error": "%s is already owned." % item["name"]}
			if item.has("requires") and int(levels.get(item["requires"], 0)) == 0:
				return {"ok": false, "error": "Buy the aluminium frame first."}
			total += GearCatalog.price(item, level)
			levels[id] = level + 1
		else:
			# Equipping an already owned cosmetic is free; a duplicate cart entry is not
			# charged twice, and the last item in a slot is the one worn after checkout.
			if not owned.has(id):
				total += GearCatalog.price(item)
			owned[id] = true
			equipped[item["slot"]] = id
	return {"ok": true, "total": total, "levels": levels, "owned": owned, "equipped": equipped}
