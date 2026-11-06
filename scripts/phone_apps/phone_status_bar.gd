extends Control
## Session 89: the big phone's top strip: the time on the left, the notch in the middle,
## signal dots, "5G" and a battery on the right. White on the home wallpaper, dark on the
## white app pages.

var colour := Color.WHITE:
	set(value):
		colour = value
		queue_redraw()
var time_text := "8:00":
	set(value):
		if value != time_text:
			time_text = value
			queue_redraw()

const FONT_SIZE := 16


func _ready() -> void:
	custom_minimum_size.y = 46
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := get_theme_font("font", "Label")
	var baseline := 30.0
	draw_string(font, Vector2(30, baseline), time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, colour)
	# The notch.
	var notch := StyleBoxFlat.new()
	notch.bg_color = Color("11181b")
	notch.set_corner_radius_all(14)
	draw_style_box(notch, Rect2(size.x * 0.5 - 58, 10, 116, 28))
	# Battery, then "5G", then three signal dots, from the right edge in.
	var right := size.x - 30
	var body := Rect2(right - 28, baseline - 13, 25, 13)
	draw_rect(body, colour, false, 2.0)
	draw_rect(body.grow(-3.5), Color("2fa84f") if colour == Color.WHITE else colour)
	draw_rect(Rect2(body.end.x, body.position.y + 4, 3, 5), colour)
	var word_width := font.get_string_size("5G", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(body.position.x - 8 - word_width, baseline), "5G", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, colour)
	for i in 3:
		draw_circle(Vector2(body.position.x - 18 - word_width - i * 9, baseline - 6), 3.0, colour)
