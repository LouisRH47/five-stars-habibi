extends VBoxContainer
## Session 89: the phone's Collection app. Three tabs: Bikes (paint and box colours),
## Looks (clothes) and Gear (upgrades), all from scripts/gear_catalog.gd. Things you own
## show in colour ("Riding", "Wearing" or "Owned"); locked ones are grey and say what
## unlocks them: a price, a Rider Level or filling a cluster's stamp card.

const TABS := [["bikes", "Bikes"], ["looks", "Looks"], ["gear", "Gear"]]

var tab := "bikes"


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	refresh()


func refresh() -> void:
	PhoneUI.clear(self)
	var state := get_tree().root.get_node("GameState")
	add_child(_tabs())
	var grid := GridContainer.new()
	grid.name = "Items"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for item in items(tab):
		grid.add_child(_tile(item, status(state, item)))
	add_child(PhoneUI.caps("Gear you have"))
	var gear := PhoneUI.card()
	(gear.get_child(0) as VBoxContainer).add_child(PhoneUI.label(_gear_line(state), 16))
	add_child(gear)
	var shop := "Buy clothes at Dune Drip in the Plaza." if tab == "looks" else "Buy things at Pedal Point Bikes in the Plaza."
	add_child(PhoneUI.label(shop, 15, PhoneUI.SOFT))


## Switches tab ("bikes", "looks" or "gear") and redraws.
func show_tab(id: String) -> void:
	tab = id
	refresh.call_deferred()  # after the pressed tab has finished its click


## The catalogue items on a tab.
static func items(tab_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in GearCatalog.items("clothes" if tab_id == "looks" else "bikes"):
		var upgrade: bool = item["slot"] == "upgrade"
		if (tab_id == "gear") == upgrade:
			result.append(item)
	return result


## What a tile says under the name, and whether you have it: {"text", "owned"}.
static func status(state: Node, item: Dictionary) -> Dictionary:
	var id: String = item["id"]
	var level: int = state.upgrade_level(id)
	if item["slot"] == "upgrade":
		var most := int(item.get("max", 1))
		if level >= most:
			return {"text": "Owned", "owned": true}
		if level > 0:
			return {"text": "%d/%d" % [level, most], "owned": true}
	elif state.equipped_cosmetics.get(item["slot"], "") == id:
		return {"text": "Riding" if item["category"] in ["paint", "box"] else "Wearing", "owned": true}
	elif state.owned_items.has(id):
		return {"text": "Owned", "owned": true}
	if state.level() < int(item["level"]):
		return {"text": "Lv %d" % item["level"], "owned": false}
	if item.get("collection", false) and state.owned_collection_rewards.is_empty():
		return {"text": "Fill a cluster", "owned": false}
	var price := GearCatalog.price(item, level)
	return {"text": "%d Dh" % price if price > 0 else "Free", "owned": false}


func _tabs() -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	for pair: Array in TABS:
		var on: bool = pair[0] == tab
		var button := PhoneUI.button(pair[1], PhoneUI.TEAL if on else PhoneUI.LINE, 16)
		button.name = "Tab_" + pair[0]
		button.custom_minimum_size = Vector2(84, 40)
		if not on:
			for colour in ["font_color", "font_hover_color", "font_focus_color"]:
				button.add_theme_color_override(colour, PhoneUI.SOFT)
		var id: String = pair[0]
		button.pressed.connect(func(): show_tab(id))
		line.add_child(button)
	return line


## One square: a colour dot (or a gear for upgrades, a lock when locked), name, status.
func _tile(item: Dictionary, info: Dictionary) -> Control:
	var tile := PhoneUI.card(PhoneUI.CARD, 14, 8)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rows: VBoxContainer = tile.get_child(0)
	rows.add_theme_constant_override("separation", 2)
	var owned: bool = info["owned"]
	var glyph: PhoneGlyph
	if not owned:
		glyph = PhoneGlyph.make("lock", PhoneUI.SOFT, 34, PhoneUI.CARD)
	elif item["slot"] == "upgrade":
		glyph = PhoneGlyph.make("gear", PhoneUI.TEAL, 34, PhoneUI.CARD)
	else:
		glyph = PhoneGlyph.make("dot", item.get("colour", PhoneUI.TEAL), 34, Color(1, 1, 1, 0.9))
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rows.add_child(glyph)
	var name_label := PhoneUI.label(item["name"], 14, PhoneUI.INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(name_label)
	var text := PhoneUI.label(info["text"], 14, PhoneUI.GREEN if owned else PhoneUI.SOFT, "BigNumber")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(text)
	if not owned:
		tile.modulate = Color(1, 1, 1, 0.6)
	return tile


## The upgrades you own, in one line ("GPS route · Stamina +10% (3/10)").
func _gear_line(state: Node) -> String:
	var names: Array[String] = []
	for item: Dictionary in GearCatalog.UPGRADES:
		var level: int = state.upgrade_level(item["id"])
		if level > 0:
			names.append(item["name"] + (" (%d/%d)" % [level, item["max"]] if item.has("max") else ""))
	return "  ·  ".join(names) if not names.is_empty() else "No gear yet. The GPS route unlocks at Rider Level 2."
