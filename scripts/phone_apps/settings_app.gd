extends VBoxContainer
## Session 89: the phone's Settings app. It shows the game's own settings box
## (scripts/settings_panel.gd, the same one as the pause menu), re-coloured for the white
## phone page, plus the insurance switch (I on the keyboard does the same).

var panel: SettingsPanel
var insurance: CheckButton


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	panel = SettingsPanel.new()
	panel.name = "SettingsPanel"
	add_child(panel)
	panel.custom_minimum_size = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.rows.get_child(0).visible = false  # its "Settings" title: the phone has one
	var back := panel.rows.get_node_or_null("Back") as Control
	if back != null:
		back.visible = false  # the phone's ‹ goes back instead
	_recolour(panel)
	insurance = CheckButton.new()
	insurance.name = "Insurance"
	insurance.text = "Insurance (%d Dh a job)" % GameConfig.INSURANCE_PER_DELIVERY
	insurance.add_theme_font_size_override("font_size", 18)
	insurance.toggled.connect(func(on: bool): get_tree().root.get_node("GameState").set_insurance(on))
	add_child(insurance)
	_recolour(insurance)
	add_child(PhoneUI.label("The same settings as the pause menu. Changes are saved straight away.", 15, PhoneUI.SOFT))
	PhoneUI.fit_touch(self)


func refresh() -> void:
	insurance.set_pressed_no_signal(get_tree().root.get_node("GameState").insurance_on)


## Dark text on the white page, and no teal box behind the on/off switches.
func _recolour(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", PhoneUI.INK)
		node.add_theme_font_size_override("font_size", 18)
	elif node is CheckButton:
		for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			node.add_theme_color_override(colour, PhoneUI.INK)
		for style in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			node.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		for icon in ["checked", "checked_mirrored", "checked_disabled", "checked_disabled_mirrored"]:
			node.add_theme_icon_override(icon, PhoneUI.switch_icon(true))
		for icon in ["unchecked", "unchecked_mirrored", "unchecked_disabled", "unchecked_disabled_mirrored"]:
			node.add_theme_icon_override(icon, PhoneUI.switch_icon(false))
		node.add_theme_font_size_override("font_size", 18)
	elif node is OptionButton:
		node.add_theme_font_size_override("font_size", 17)
	for child in node.get_children():
		_recolour(child)
