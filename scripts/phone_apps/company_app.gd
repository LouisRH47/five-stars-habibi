extends VBoxContainer
## Session 89: the phone's Company app. The three delivery companies (data/companies.gd)
## as cards in their own colour, with the logo, English and Arabic name and the perk.
## Yours says "you work here". Tap another card, then "Switch to X · 50 Dh" calls
## GameState.switch_company(); the line under the button says how it went.

## The company the cards have picked (starts on yours each time the app opens).
var picked := ""
## What happened at the last switch ("" before any).
var result_text := ""
var _switch: Button


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	refresh()


func refresh() -> void:
	picked = str(Companies.current()["id"])
	result_text = ""
	_build()


## Picks a card (does not switch yet).
func pick(id: String) -> void:
	picked = id
	result_text = ""
	_build.call_deferred()  # after the pressed card has finished its click


## The Switch button: true if you now work for the picked company.
func switch_to_picked() -> bool:
	var state := get_tree().root.get_node("GameState")
	var target := Companies.find(picked)
	if target.is_empty() or picked == str(state.company):
		return false
	var done: bool = state.switch_company(picked)
	if done:
		result_text = "Welcome to %s! Your box, shirt and phone are %s now." % [target["name"], _colour_word(target)]
	elif state.current_order != null:
		result_text = "Finish the order you're carrying first, then switch."
	elif state.money < GameConfig.COMPANY_SWITCH_PRICE:
		result_text = "Switching costs %d Dh. You have %d Dh." % [GameConfig.COMPANY_SWITCH_PRICE, state.money]
	else:
		result_text = "You can't switch right now."
	_build.call_deferred()
	return done


func _build() -> void:
	PhoneUI.clear(self)
	var state := get_tree().root.get_node("GameState")
	for company: Dictionary in Companies.all():
		add_child(_card(company, company["id"] == state.company))
	var note := PhoneUI.label("Switching costs %d Dh. You keep your stars, level and everything you own. Your box, shirt and phone change colour." % GameConfig.COMPANY_SWITCH_PRICE, 15, PhoneUI.SOFT)
	add_child(note)
	var target := Companies.find(picked)
	_switch = PhoneUI.button("", PhoneUI.TEAL)
	_switch.name = "Switch"
	if picked == state.company:
		_switch.text = "You work for %s" % target.get("name", "")
		_switch.disabled = true
	else:
		_switch.text = "Switch to %s  ·  %d Dh" % [target.get("name", ""), GameConfig.COMPANY_SWITCH_PRICE]
	_switch.pressed.connect(switch_to_picked)
	add_child(_switch)
	if result_text != "":
		var result := PhoneUI.label(result_text, 16, PhoneUI.TEAL, "BigNumber")
		result.name = "Result"
		add_child(result)


## One company card: a big button in the brand colour, white edge when picked.
func _card(company: Dictionary, mine: bool) -> Button:
	var card := Button.new()
	card.name = "Card_" + company["id"]
	card.custom_minimum_size.y = 112
	card.focus_mode = Control.FOCUS_ALL
	var colour: Color = company["colour"]
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := PhoneUI.flat(colour.lightened(0.08) if state == "hover" else colour, 18)
		if company["id"] == picked or state == "focus":
			style.border_color = PhoneUI.INK if company["id"] == picked else Color.WHITE
			style.set_border_width_all(4)
		card.add_theme_stylebox_override(state, style)
	var id: String = company["id"]
	card.pressed.connect(func(): pick(id))
	PhoneUI.fit_touch(card)
	var inside := HBoxContainer.new()
	inside.set_anchors_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 14
	inside.offset_right = -10
	inside.add_theme_constant_override("separation", 12)
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inside)
	var logo_box := PanelContainer.new()
	logo_box.custom_minimum_size = Vector2(62, 62)
	logo_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_box.add_theme_stylebox_override("panel", PhoneUI.flat(Color(1, 1, 1, 0.95), 14, 4))
	logo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo := TextureRect.new()
	logo.texture = Companies.logo(company)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_box.add_child(logo)
	inside.add_child(logo_box)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", -4)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(words)
	words.add_child(PhoneUI.label(company["name"], 25, Color.WHITE, "Heading"))
	words.add_child(PhoneUI.arabic(company["arabic"], 16, Color(1, 1, 1, 0.92)))
	words.add_child(PhoneUI.label(company["perk"] + "  ·  you work here" if mine else company["perk_long"], 15, Color.WHITE, "BigNumber" if mine else ""))
	for label in words.get_children():
		(label as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _colour_word(company: Dictionary) -> String:
	return {"snackaroo": "orange", "zoomaroo": "green", "deliverooz": "teal"}.get(company["id"], "new")
