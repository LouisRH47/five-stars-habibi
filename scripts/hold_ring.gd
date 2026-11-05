extends Control
## Session 69 (H5): while you hold E at a door, a round orange ring fills around a little "E"
## key just below the middle of the screen, and it pops when it's full. It only reads the
## hold progress the phone's bar uses (DeliveryManager.hold_progress()). Switch: GameConfig.HOLD_RING.

## Where the hold progress comes from (the world's DeliveryManager).
var delivery_manager: Node
## 0 to 1: how full the ring is (tests read it).
var value := 0.0
## How many times the ring popped when full (tests read it).
var pops := 0
var _pop := 0.0  # 1 right after a pop, fading to 0


func _ready() -> void:
	name = "HoldRing"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func _process(delta: float) -> void:
	if delivery_manager == null or not is_instance_valid(delivery_manager):
		delivery_manager = get_parent().get_parent().get_node_or_null("DeliveryManager") if get_parent() != null and get_parent().get_parent() != null else null
	var now := 0.0
	if delivery_manager != null and delivery_manager.has_method("hold_progress"):
		now = delivery_manager.hold_progress()
	# The hold resets as soon as it's done: if it was nearly full, that was a finish, so pop.
	if now <= 0.0 and value >= 0.9:
		_pop = 1.0
		pops += 1
	value = now
	_pop = maxf(_pop - delta / 0.3, 0.0)
	visible = value > 0.0 or _pop > 0.0
	if visible:
		queue_redraw()


## Where the ring sits: a little below the middle, lifted if the meters panel is in the way.
func centre() -> Vector2:
	var r := GameConfig.HOLD_RING_SIZE * 0.5
	var at := size * 0.5 + Vector2(0, GameConfig.HOLD_RING_BELOW_MIDDLE)
	var world := get_parent().get_parent() if get_parent() != null else null
	var meters := world.get_node_or_null("MetersPanel/Panel") as Control if world != null else null
	if meters != null and meters.is_visible_in_tree():
		var box := meters.get_global_rect()
		var top := box.position.y - 16.0 - r
		if top < at.y and top > size.y * 0.5 - r:  # only lift it a little, never into the top HUD
			at.y = top
		elif box.grow(16.0).intersects(Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0)):
			# Tall (stacked) meters it can't get above: sit beside them, on the side nearer the middle.
			var left := box.position.x - 16.0 - r
			var right := box.end.x + 16.0 + r
			at.x = left if left - r >= 0.0 and (at.x - left <= right - at.x or right + r > size.x) else right
	return at


func _draw() -> void:
	var radius := GameConfig.HOLD_RING_SIZE * 0.5
	var centre := centre()
	var grow := 1.0 if Settings.reduce_motion else 1.0 + 0.35 * (1.0 - _pop) * float(_pop > 0.0)
	var fade := _pop if value <= 0.0 else 1.0
	radius *= grow
	draw_circle(centre, radius, Color(UiPalette.PANEL, UiPalette.PANEL.a * fade))
	draw_arc(centre, radius - 8.0, 0.0, TAU, 64, Color(UiPalette.SOFT_TEXT, 0.2 * fade), 8.0, true)
	var amount := 1.0 if value <= 0.0 else value
	draw_arc(centre, radius - 8.0, -PI / 2.0, -PI / 2.0 + TAU * amount, 64, Color(UiPalette.ORANGE, fade), 8.0, true)
	# The key: a little rounded square with an E on it.
	var key := Rect2(centre - Vector2(22, 22), Vector2(44, 44))
	var cap := StyleBoxFlat.new()
	cap.bg_color = Color(UiPalette.SAND, fade)
	cap.set_corner_radius_all(9)
	cap.shadow_color = Color(0, 0, 0, 0.35 * fade)
	cap.shadow_offset = Vector2(0, 3)
	draw_style_box(cap, key)
	var font := get_theme_font("font", &"BigNumber")
	var font_size := 28
	var text_size := font.get_string_size("E", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := centre + Vector2(-text_size.x * 0.5, font.get_ascent(font_size) - text_size.y * 0.5)
	draw_string(font, baseline, "E", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UiPalette.INK, fade))
