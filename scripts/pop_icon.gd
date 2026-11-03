class_name PopIcon
extends Control
## A little icon that pops up and fades away (Session 31): a gold star or a gold coin.
## The Delivered card makes them when the stars fill in and the money comes in.
## It runs while the game is paused, and frees itself when it's done.

## "star" or "coin".
var kind := "star"
## Pixels across.
var icon_size := 26.0

const GOLD := Color(1.0, 0.78, 0.2, 1)
const DARK_GOLD := Color(0.85, 0.55, 0.08, 1)
const SHINE := Color(1.0, 0.95, 0.7, 1)


## Makes one icon on `parent` at `spot` (screen pixels) that flies `move` pixels away.
static func spawn(parent: Node, kind_name: String, spot: Vector2, move: Vector2, size_px: float) -> PopIcon:
	var icon := PopIcon.new()
	icon.kind = kind_name
	icon.icon_size = size_px
	icon.add_to_group("pop_icon")
	parent.add_child(icon)
	icon.fly(spot, move)
	return icon


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2.ONE * icon_size
	pivot_offset = size * 0.5


## Grows in quickly, drifts away and fades out, then it's gone.
func fly(spot: Vector2, move: Vector2) -> void:
	position = spot - size * 0.5
	scale = Vector2.ZERO
	var time := GameConfig.POP_ICON_TIME
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, time * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + move, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", randf_range(-0.6, 0.6), time)
	tween.tween_property(self, "modulate:a", 0.0, time * 0.35).set_delay(time * 0.65)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var middle := size * 0.5
	var r := icon_size * 0.5
	if kind == "coin":
		draw_circle(middle, r, DARK_GOLD)
		draw_circle(middle, r * 0.8, GOLD)
		draw_circle(middle + Vector2(-r, -r) * 0.3, r * 0.18, SHINE)
	else:
		draw_colored_polygon(StarRow._star(middle, r), GOLD)
		draw_colored_polygon(StarRow._star(middle, r * 0.45), SHINE)
