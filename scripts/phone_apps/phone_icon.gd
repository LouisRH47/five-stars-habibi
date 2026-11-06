class_name PhoneIcon
extends Control
## Session 89: one app icon on the big phone's home screen: a rounded coloured square with
## a drawn picture (or the company logo), the app's name under it, a red badge with a
## number (hidden at 0) and a white ring when the arrow keys have picked it.
## Click it (or tap it) and it sends `chosen`.

signal chosen
## The mouse moved onto it (the home screen moves the keyboard ring here).
signal hovered

const ICON := 86.0
const LABEL_SIZE := 16

var app_id := ""
var title := ""
var background := Color.WHITE
var glyph := "star"
var glyph_colour := Color.WHITE
var glyph_accent := Color(0, 0, 0, 0.3)
var outlined := false
## A picture drawn instead of the glyph (the Company icon's logo).
var logo: Texture2D
var badge := 0:
	set(value):
		badge = value
		queue_redraw()
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(ICON + 24, ICON + 34)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): hovered.emit())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		chosen.emit()
		accept_event()


func icon_rect() -> Rect2:
	return Rect2((size.x - ICON) * 0.5, 6, ICON, ICON)


func _draw() -> void:
	var rect := icon_rect()
	if selected:
		draw_style_box(_round(Color(1, 1, 1, 0.0), 28, Color.WHITE, 4), rect.grow(7))
	var square := _round(background, 24, Color.WHITE if outlined else Color(0, 0, 0, 0), 3 if outlined else 0)
	square.shadow_color = Color(0, 0, 0, 0.2)
	square.shadow_size = 8
	square.shadow_offset = Vector2(0, 4)
	draw_style_box(square, rect)
	if logo != null:
		draw_texture_rect(logo, rect.grow(-8), false)
	else:
		PhoneGlyph.paint(self, glyph, rect.grow(-14), glyph_colour, glyph_accent)
	var font := get_theme_font("font", "Label")
	var baseline := rect.end.y + 8 + font.get_ascent(LABEL_SIZE)
	draw_string(font, Vector2(0, baseline + 1), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, LABEL_SIZE, Color(0, 0, 0, 0.35))
	draw_string(font, Vector2(0, baseline), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, LABEL_SIZE, Color.WHITE)
	if badge > 0:
		_draw_badge(rect, font)


## The red unread circle at the icon's top-right corner, with a white edge.
func _draw_badge(rect: Rect2, font: Font) -> void:
	var text := str(badge) if badge < 100 else "99+"
	var width := maxf(30.0, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 16)
	var spot := Rect2(rect.end.x - width + 10, rect.position.y - 10, width, 30)
	draw_style_box(_round(PhoneUI.RED, 15, Color.WHITE, 3), spot)
	var baseline := spot.position.y + (spot.size.y - font.get_height(17)) * 0.5 + font.get_ascent(17)
	draw_string(font, Vector2(spot.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, spot.size.x, 17, Color.WHITE)


func _round(fill: Color, radius: int, edge: Color, edge_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.border_color = edge
	style.set_border_width_all(edge_width)
	style.anti_aliasing = true
	return style
