class_name Keycap
extends Control
## Session 70: a little rounded key with a letter on it ("E", "Q", "1"...), so the phone
## shows the key to press instead of "E accept". Drawn in code: a dark key with a lighter
## top face, like a real keyboard key. The countdown ring and the phone use it.

## The letter (or short word) on the key.
@export var key_text := "E":
	set(value):
		if key_text == value:
			return
		key_text = value
		_fit()
## Key height in pixels at the 1920 x 1080 base size.
@export var key_size := 30.0:
	set(value):
		key_size = value
		_fit()
## The key's colour (dark ink by default; orange for "do it now").
@export var colour := UiPalette.INK:
	set(value):
		if colour == value:
			return
		colour = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()


## Wide enough for the text, never narrower than it is tall.
func _fit() -> void:
	var font := get_theme_default_font()
	var width := key_size
	if font != null:
		width = maxf(key_size, font.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size()).x + key_size * 0.5)
	custom_minimum_size = Vector2(width, key_size)
	queue_redraw()


func _font_size() -> int:
	return roundi(key_size * 0.6)


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size).grow(-1.0)
	var depth := maxf(2.0, key_size * 0.1)
	var radius := roundi(key_size * 0.22)
	var base := StyleBoxFlat.new()
	base.bg_color = colour.darkened(0.35)
	base.set_corner_radius_all(radius)
	draw_style_box(base, box)
	var face := StyleBoxFlat.new()
	face.bg_color = colour
	face.set_corner_radius_all(radius)
	face.border_color = colour.lightened(0.25)
	face.border_width_top = 1
	var top := Rect2(box.position, box.size - Vector2(0, depth))
	draw_style_box(face, top)
	var font := get_theme_default_font()
	var font_size := _font_size()
	var baseline := top.position.y + (top.size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	draw_string(font, Vector2(top.position.x, baseline), key_text, HORIZONTAL_ALIGNMENT_CENTER,
			top.size.x, font_size, Color.WHITE)
