class_name PhoneGlyph
extends Control
## Session 89: a small picture drawn with simple shapes (the game's fonts have no emoji).
## kind: "bike", "star", "bag", "chat", "map", "gear", "lock", "dot".
## colour is the main colour, accent the second one (the gear's hole, the chat's dots).
## Other scripts can also call PhoneGlyph.paint(...) to draw one inside their own _draw().

@export var kind := "star"
@export var colour := Color.WHITE
@export var accent := Color(0, 0, 0, 0.35)


func _draw() -> void:
	paint(self, kind, Rect2(Vector2.ZERO, size), colour, accent)


## Makes a glyph of a fixed size.
static func make(glyph_kind: String, glyph_colour: Color, pixels: float, second := Color(0, 0, 0, 0.35)) -> PhoneGlyph:
	var glyph := PhoneGlyph.new()
	glyph.kind = glyph_kind
	glyph.colour = glyph_colour
	glyph.accent = second
	glyph.custom_minimum_size = Vector2(pixels, pixels)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glyph


## Draws the glyph `kind` centred in `rect` on `item`.
static func paint(item: CanvasItem, glyph_kind: String, rect: Rect2, main: Color, second: Color) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y)
	match glyph_kind:
		"star":
			item.draw_colored_polygon(star_points(c + Vector2(0, s * 0.03), s * 0.46, s * 0.19), main)
		"bike":
			_bike(item, c, s, main, second)
		"bag":
			_box(item, Rect2(c + Vector2(-0.24, -0.2) * s, Vector2(0.48, 0.5) * s), main, s * 0.1)
			_box(item, Rect2(c + Vector2(-0.24, -0.2) * s, Vector2(0.48, 0.2) * s), second, s * 0.1)
			item.draw_arc(c + Vector2(0, -0.2) * s, s * 0.11, PI, TAU, 12, main, s * 0.05)
			_box(item, Rect2(c + Vector2(-0.07, 0.04) * s, Vector2(0.14, 0.08) * s), second, s * 0.02)
		"chat":
			_box(item, Rect2(c + Vector2(-0.32, -0.26) * s, Vector2(0.64, 0.44) * s), main, s * 0.16)
			item.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.2, 0.12) * s,
					c + Vector2(-0.28, 0.32) * s, c + Vector2(-0.02, 0.16) * s]), main)
			for i in 3:
				item.draw_circle(c + Vector2(-0.14 + i * 0.14, -0.04) * s, s * 0.045, second)
		"map":
			var panels := [[-0.36, -0.28, -0.12, -0.2], [-0.12, -0.2, 0.12, -0.28], [0.12, -0.28, 0.36, -0.2]]
			for i in panels.size():
				var p: Array = panels[i]
				item.draw_colored_polygon(PackedVector2Array([c + Vector2(p[0], p[1]) * s,
						c + Vector2(p[2], p[3]) * s, c + Vector2(p[2], p[3] + 0.5) * s,
						c + Vector2(p[0], p[1] + 0.5) * s]), main if i != 1 else main.darkened(0.12))
			item.draw_line(c + Vector2(-0.3, 0.1) * s, c + Vector2(0.3, -0.02) * s, Color("7fb069"), s * 0.05)
			item.draw_circle(c + Vector2(0.05, -0.08) * s, s * 0.09, second)
			item.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.03, -0.04) * s,
					c + Vector2(0.13, -0.04) * s, c + Vector2(0.05, 0.1) * s]), second)
			item.draw_circle(c + Vector2(0.05, -0.08) * s, s * 0.035, Color.WHITE)
		"gear":
			var points := PackedVector2Array()
			for i in 32:
				var angle := TAU * i / 32.0
				var tooth := (i / 2) % 2 == 0
				points.append(c + Vector2.from_angle(angle) * s * (0.4 if tooth else 0.3))
			item.draw_colored_polygon(points, main)
			item.draw_circle(c, s * 0.13, second)
		"lock":
			item.draw_arc(c + Vector2(0, -0.08) * s, s * 0.15, PI, TAU, 14, main, s * 0.07)
			item.draw_line(c + Vector2(-0.15, -0.08) * s, c + Vector2(-0.15, 0.0) * s, main, s * 0.07)
			item.draw_line(c + Vector2(0.15, -0.08) * s, c + Vector2(0.15, 0.0) * s, main, s * 0.07)
			_box(item, Rect2(c + Vector2(-0.25, -0.02) * s, Vector2(0.5, 0.36) * s), main, s * 0.06)
			item.draw_circle(c + Vector2(0, 0.14) * s, s * 0.05, second)
		_:
			item.draw_circle(c, s * 0.38, main)
			item.draw_arc(c, s * 0.38, 0, TAU, 32, second, maxf(s * 0.04, 1.5), true)


## A five-pointed star's corners.
static func star_points(centre: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(centre + Vector2.from_angle(angle) * (outer if i % 2 == 0 else inner))
	return points


## A delivery bike: two wheels, a frame and a box on the back.
static func _bike(item: CanvasItem, c: Vector2, s: float, main: Color, second: Color) -> void:
	var back := c + Vector2(-0.24, 0.14) * s
	var front := c + Vector2(0.26, 0.14) * s
	var pedals := c + Vector2(0.0, 0.14) * s
	var seat := c + Vector2(-0.1, -0.1) * s
	var head := c + Vector2(0.16, -0.1) * s
	var width := s * 0.055
	for wheel in [back, front]:
		item.draw_arc(wheel, s * 0.15, 0, TAU, 24, main, width, true)
	for pair in [[back, pedals], [pedals, head], [head, front], [back, seat], [seat, pedals], [seat, head]]:
		item.draw_line(pair[0], pair[1], main, width, true)
	item.draw_line(head, head + Vector2(0.02, -0.1) * s, main, width, true)
	item.draw_line(head + Vector2(-0.04, -0.1) * s, head + Vector2(0.08, -0.1) * s, main, width, true)
	_box(item, Rect2(c + Vector2(-0.42, -0.4) * s, Vector2(0.26, 0.24) * s), main, s * 0.04)
	_box(item, Rect2(c + Vector2(-0.38, -0.34) * s, Vector2(0.18, 0.04) * s), second, 0)


static func _box(item: CanvasItem, rect: Rect2, fill: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = true
	item.draw_style_box(style, rect)
