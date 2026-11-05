class_name CountdownRing
extends Control
## Session 70: a ring that runs down round a key, like the accept button in a driver app.
## `value` goes from 1.0 (full ring, just arrived) to 0.0 (time's up). The ring is orange
## and turns red in the last few seconds. In the middle: a keycap ("E"), or the seconds left
## when `key_text` is "".

## How much of the ring is left, 1.0 = full.
var value := 1.0:
	set(v):
		v = clampf(v, 0.0, 1.0)
		if is_equal_approx(v, value):
			return
		value = v
		queue_redraw()
## Seconds left (shown in the middle when there's no key, and turns the ring red at the end).
var seconds_left := 30:
	set(v):
		if v == seconds_left:
			return
		seconds_left = v
		queue_redraw()
## The key in the middle ("" = show the seconds instead).
var key_text := "E":
	set(v):
		key_text = v
		if _key != null:
			_key.key_text = v
			_key.visible = v != ""
		queue_redraw()

var _key: Keycap


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_size := GameConfig.OFFER_RING_SIZE
	custom_minimum_size = Vector2(ring_size, ring_size)
	_key = Keycap.new()
	_key.name = "Key"
	_key.key_size = ring_size * 0.42
	_key.key_text = key_text
	_key.visible = key_text != ""
	add_child(_key)
	resized.connect(_centre_key)
	_key.resized.connect(_centre_key)
	_centre_key()


func _centre_key() -> void:
	_key.size = _key.custom_minimum_size
	_key.position = (size - _key.size) * 0.5


## Orange normally, red in the last few seconds.
func ring_colour() -> Color:
	return UiPalette.band_colour(2) if seconds_left <= GameConfig.OFFER_RING_WARN_SECONDS else UiPalette.ORANGE


func _draw() -> void:
	var centre := size * 0.5
	var width := GameConfig.OFFER_RING_WIDTH
	var radius := minf(size.x, size.y) * 0.5 - width * 0.5 - 1.0
	draw_circle(centre, radius + width * 0.5, Color(1, 1, 1, 1))
	draw_arc(centre, radius, 0.0, TAU, 64, UiPalette.SAND, width, true)
	if value > 0.0:
		# Starts at the top and runs clockwise, shrinking as time runs out.
		var start := -PI * 0.5
		draw_arc(centre, radius, start, start + TAU * value, maxi(8, roundi(64 * value)), ring_colour(), width, true)
	if key_text == "":
		var font := get_theme_default_font()
		var font_size := UiPalette.FONT_LABEL
		var text := str(seconds_left)
		var baseline := centre.y - font.get_height(font_size) * 0.5 + font.get_ascent(font_size)
		draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, UiPalette.INK)
