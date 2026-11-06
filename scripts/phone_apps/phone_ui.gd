class_name PhoneUI
extends RefCounted
## Session 89: the shared look of the big phone's app pages (white pages, sand cards,
## teal titles, an orange XP bar), so every app looks the same. Colours copy
## docs/phone_mockup.html. Only small helpers that make labels, cards and buttons.

const INK := Color("1b1d22")
const SOFT := Color("5c6b70")
const TEAL := Color("0f4c5c")
const ORANGE := Color("f28c28")
const SUN := Color("f2b230")
const SAND := Color("e9d9b5")
const GREEN := Color("2fa84f")
const RED := Color("cc4033")
const CARD := Color("fbf6ec")
const LINE := Color("efe6d4")
const BAR_BACK := Color("ede3d0")


## A label that wraps. variation: "" (normal), "Heading" (Baloo, bold) or "BigNumber".
static func label(text: String, font_size := 17, colour := INK, variation := "") -> Label:
	var made := Label.new()
	made.text = text
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	made.add_theme_font_size_override("font_size", font_size)
	made.add_theme_color_override("font_color", colour)
	if variation != "":
		made.theme_type_variation = variation
	else:
		made.add_theme_font_override("font", body_font())
	return made


static var _body: FontVariation

## The game's body font (Nunito) without the Arabic font behind it: the Arabic font's tall
## lines push wrapped English lines far apart. (Negative line_spacing instead made Godot's
## layout loop forever.) Arabic text uses the normal theme font: see arabic().
static func body_font() -> FontVariation:
	if _body == null:
		_body = FontVariation.new()
		_body.base_font = load("res://assets/fonts/Nunito.ttf")
		_body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 650}
	return _body


## A label for Arabic words (the theme font, which has Noto Sans Arabic for joined,
## right-to-left letters).
static func arabic(text: String, font_size := 16, colour := INK) -> Label:
	var made := label(text, font_size, colour)
	made.remove_theme_font_override("font")
	made.autowrap_mode = TextServer.AUTOWRAP_OFF
	return made


## The small grey capital-letter heading above a card ("RIDER LEVEL 6").
static func caps(text: String) -> Label:
	var made := label(text.to_upper(), 14, SOFT)
	made.add_theme_constant_override("line_spacing", 0)
	return made


## A rounded box in `colour`. Returns the box; put things in box.get_child(0) (a VBox).
static func card(colour := CARD, radius := 18, padding := 14) -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", flat(colour, radius, padding))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	box.add_child(rows)
	return box


static func flat(colour: Color, radius: int, padding := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	return style


## A big rounded button (teal, or another colour).
static func button(text: String, colour := TEAL, font_size := 18) -> Button:
	var made := Button.new()
	made.text = text
	made.add_theme_font_size_override("font_size", font_size)
	made.custom_minimum_size.y = 50
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var shade := colour
		if state == "hover" or state == "focus":
			shade = colour.lightened(0.12)
		elif state == "pressed":
			shade = colour.darkened(0.15)
		elif state == "disabled":
			shade = colour.lerp(Color(0.8, 0.8, 0.8), 0.6)
		var style := flat(shade, 16, 10)
		if state == "focus":
			style.border_color = Color.WHITE
			style.set_border_width_all(2)
		made.add_theme_stylebox_override(state, style)
	fit_touch(made)
	return made


## The orange XP-style bar on a sand track. value goes from 0 to 1.
static func bar(share: float, colour := ORANGE) -> ProgressBar:
	var made := ProgressBar.new()
	made.show_percentage = false
	made.custom_minimum_size.y = 14
	made.max_value = 1.0
	made.step = 0.0
	made.value = clampf(share, 0.0, 1.0)
	made.add_theme_stylebox_override("background", flat(BAR_BACK, 7))
	made.add_theme_stylebox_override("fill", flat(colour, 7))
	return made


## One line with text on the left and a bold number on the right ("• 20 deliveries  14/20").
static func row(left: String, right: String, font_size := 16, colour := INK) -> HBoxContainer:
	var line := HBoxContainer.new()
	var name_label := label(left, font_size, colour)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	var value := label(right, font_size, colour, "BigNumber")
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(value)
	return line


## Removes every child of `node` straight away (for pages that rebuild on refresh()).
static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Touch screens: makes the button at least finger-sized (scripts/touch_controls.gd).
static func fit_touch(control: Control) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var touch: Node = tree.root.get_node_or_null("TouchControls") if tree != null else null
	if touch != null and touch.has_method("fit_touch_widget"):
		touch.fit_touch_widget(control)


## An on/off switch picture for CheckButtons on the white pages (green when on).
static func switch_icon(on: bool) -> ImageTexture:
	var image := Image.create(46, 26, false, Image.FORMAT_RGBA8)
	var track := GREEN if on else Color("cfc6b6")
	var knob := Vector2(33.0 if on else 13.0, 13.0)
	for y in 26:
		for x in 46:
			var point := Vector2(x + 0.5, y + 0.5)
			var nearest := Vector2(clampf(point.x, 13.0, 33.0), 13.0)
			var colour := track
			colour.a = clampf(13.0 - point.distance_to(nearest) + 0.5, 0.0, 1.0)
			var inside := clampf(10.0 - point.distance_to(knob) + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, colour.lerp(Color.WHITE, inside) if colour.a > 0.0 else colour)
	return ImageTexture.create_from_image(image)
