extends CanvasLayer
## Speed lines (Session 31, PRD "Juice"): thin white streaks that rush outwards at the edges
## of the screen while you sprint. The middle of the screen stays clear. The follow camera
## sets `strength` (0 = none, 1 = full sprint); the lines fade in and out with it.
## The numbers are in scripts/game_config.gd ("Juice").

## 0 (no lines) to 1 (full sprint).
var strength := 0.0

var _canvas: Control
var _streaks: Array[Dictionary] = []  # each: angle, distance (0 = centre, 1 = corner), speed, length


func _ready() -> void:
	layer = 0  # under the HUD, the phone and the menus
	process_mode = Node.PROCESS_MODE_ALWAYS  # so it can hide itself while the game is paused
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_lines)
	add_child(_canvas)
	for i in GameConfig.SPEED_LINES_COUNT:
		_streaks.append(_new_streak(randf_range(0.55, 1.0)))


func _process(delta: float) -> void:
	var camera := get_parent() as Camera3D
	visible = strength > 0.01 and not get_tree().paused and (camera == null or camera.current)
	if not visible:
		return
	for streak in _streaks:
		streak["distance"] += streak["speed"] * delta
		if streak["distance"] > 1.15:
			streak.merge(_new_streak(0.55), true)
	_canvas.queue_redraw()


func _new_streak(distance: float) -> Dictionary:
	return {"angle": randf() * TAU, "distance": distance, "speed": randf_range(1.2, 2.0),
			"length": randf_range(0.12, 0.22), "width": randf_range(2.0, 4.0)}


func _draw_lines() -> void:
	var middle := _canvas.size * 0.5
	var reach := middle.length()  # from the middle to a corner
	for streak in _streaks:
		var way := Vector2(cos(streak["angle"]), sin(streak["angle"]))
		# Squash to the screen's shape, so lines sit near the left/right and top/bottom edges.
		way = Vector2(way.x * middle.x, way.y * middle.y).normalized()
		var near: float = streak["distance"] * reach
		var far: float = near + streak["length"] * reach
		# Fade in from the inside, so nothing shows in the middle of the screen.
		var edge := clampf((streak["distance"] - 0.55) / 0.2, 0.0, 1.0)
		var colour := Color(1, 1, 1, GameConfig.SPEED_LINES_ALPHA * strength * edge)
		var side: Vector2 = Vector2(-way.y, way.x) * streak["width"] * 0.5
		var a := middle + way * near
		var b := middle + way * far
		_canvas.draw_colored_polygon(PackedVector2Array([a, b + side, b - side]), colour)
