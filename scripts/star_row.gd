class_name StarRow
extends Control
## Draws a row of 5 stars, filled up to `stars` (half stars too). The game's font has no
## star letter, so the stars are drawn as shapes. Used on the phone for your rating and
## for the stars you get after a delivery.

const GOLD := Color(1.0, 0.78, 0.2, 1)
const EMPTY := Color(0.25, 0.36, 0.39, 1)

## How many stars are filled in, 0 to 5, in half steps.
@export var stars := 0.0:
	set(value):
		stars = value
		queue_redraw()
## Width and height of one star, in pixels.
@export var star_size := 18.0:
	set(value):
		star_size = value
		custom_minimum_size = Vector2(star_size * 5.0 + GAP * 4.0, star_size)
		queue_redraw()

const GAP := 3.0


func _ready() -> void:
	custom_minimum_size = Vector2(star_size * 5.0 + GAP * 4.0, star_size)


func _draw() -> void:
	var top := (size.y - star_size) * 0.5
	for i in 5:
		var middle := Vector2(i * (star_size + GAP) + star_size * 0.5, top + star_size * 0.55)
		var shape := _star(middle, star_size * 0.5)
		draw_colored_polygon(shape, EMPTY)
		var fill := clampf(stars - i, 0.0, 1.0)
		if fill >= 1.0:
			draw_colored_polygon(shape, GOLD)
		elif fill > 0.0:
			# Half a star: only the left part of it, cut off by a box.
			var cut := middle.x - star_size * 0.5 + star_size * fill
			var left := PackedVector2Array([Vector2(middle.x - star_size, middle.y - star_size),
					Vector2(cut, middle.y - star_size), Vector2(cut, middle.y + star_size),
					Vector2(middle.x - star_size, middle.y + star_size)])
			for piece in Geometry2D.intersect_polygons(shape, left):
				draw_colored_polygon(piece, GOLD)


## A five-pointed star around a middle point, pointing up.
static func _star(middle: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var angle := -PI * 0.5 + i * PI / 5.0
		points.append(middle + Vector2(cos(angle), sin(angle)) * r)
	return points
