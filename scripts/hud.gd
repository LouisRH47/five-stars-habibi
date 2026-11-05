extends CanvasLayer
## On-screen panel (bottom right): speed in km/h and the sprint stamina bar.
## Session 69: the number and "km/h" sit on one line, and stamina shows as 5 segments that
## glow while you sprint and pulse orange when you're tired (GameConfig.SPEED_PANEL_V2).
## The HUD also holds the top-left chips (scripts/hud_chips.gd, GameConfig.HUD_TOP_CHIPS)
## and the hold-E ring (scripts/hold_ring.gd, GameConfig.HOLD_RING).

## The bike to read speed and stamina from.
@export var bike: Node
## The world's DeliveryManager, for the hold ring (scripts/polish/hud_extras.gd sets it).
var delivery_manager: Node:
	set(value):
		delivery_manager = value
		if hold_ring != null:
			hold_ring.delivery_manager = value

const BAR_NORMAL := Color("7FD3E0")
const BAR_TIRED := Color("F59A2E")

## Session 69 parts (null when their switch is off).
var chips: Control
var hold_ring: Control
var segments: Control

@onready var _speed: Label = $Panel/Margin/Rows/SpeedRow/Speed
@onready var _bar: ProgressBar = $Panel/Margin/Rows/Stamina
@onready var _fill: StyleBoxFlat = _bar.get_theme_stylebox("fill").duplicate()


func _ready() -> void:
	_bar.max_value = GameConfig.STAMINA_MAX
	_bar.add_theme_stylebox_override("fill", _fill)
	if GameConfig.SPEED_PANEL_V2:
		_build_speed_v2()
	if GameConfig.HUD_TOP_CHIPS:
		chips = preload("res://scripts/hud_chips.gd").new()
		add_child(chips)
	if GameConfig.HOLD_RING:
		hold_ring = preload("res://scripts/hold_ring.gd").new()
		add_child(hold_ring)
		hold_ring.delivery_manager = delivery_manager
	_find_clock.call_deferred()


func _process(_delta: float) -> void:
	if bike == null:
		return
	_speed.text = str(roundi(absf(bike.speed) * 3.6))
	_bar.max_value = bike.stamina_capacity()
	_bar.value = bike.stamina
	var colour := BAR_TIRED if bike.tired else BAR_NORMAL
	if _fill.bg_color != colour:
		_fill.bg_color = colour
	if segments != null:
		segments.queue_redraw()


## The chips keep clear of the clock (it lives on the ShiftScreen).
func _find_clock() -> void:
	if chips == null or get_parent() == null:
		return
	var screen := get_parent().get_node_or_null("ShiftScreen")
	if screen != null and screen.get("clock_box") != null:
		chips.clock_box = screen.clock_box


func _build_speed_v2() -> void:
	var panel: PanelContainer = $Panel
	var rows: VBoxContainer = $Panel/Margin/Rows
	var speed_row: HBoxContainer = $Panel/Margin/Rows/SpeedRow
	var unit: Label = $Panel/Margin/Rows/SpeedRow/Unit
	var hint: Label = $Panel/Margin/Rows/StaminaRow/Hint
	panel.custom_minimum_size = Vector2(276, 0)
	panel.offset_left = -300.0
	panel.offset_top = -144.0
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = UiPalette.PANEL
	style.set_corner_radius_all(27)
	panel.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = $Panel/Margin
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 21)
	margin.add_theme_constant_override("margin_bottom", 18)
	_speed.add_theme_font_size_override("font_size", 60)
	unit.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL)
	unit.add_theme_color_override("font_color", UiPalette.SOFT_TEXT)
	speed_row.add_theme_constant_override("separation", 8)
	# Same baseline: both labels sit at the bottom of the row, and the small one is lifted
	# by the difference in how far each font hangs below its baseline.
	for label in [_speed, unit]:
		label.size_flags_vertical = Control.SIZE_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_lift_unit.call_deferred()
	# "SHIFT sprint" moves up next to the number; the old STAMINA title hides.
	hint.text = "SHIFT sprint"
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	hint.reparent(speed_row)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.custom_minimum_size.y = 0
	# The number font has a lot of empty room above and below its digits: trim it with
	# negative margins (the labels stay whole, so the shared baseline still lines up).
	var font := _speed.get_theme_font("font")
	var trim_top := maxi(roundi(font.get_ascent(60) - 60 * 0.8), 0)
	var trim_below := maxi(roundi(font.get_descent(60) - 60 * 0.14), 0)
	margin.add_theme_constant_override("margin_top", 12 - trim_top)
	rows.add_theme_constant_override("separation", 10 - trim_below)
	var top_pad := StyleBoxEmpty.new()
	top_pad.content_margin_top = trim_top + 2
	hint.add_theme_stylebox_override("normal", top_pad)
	$Panel/Margin/Rows/StaminaRow.visible = false
	# The ProgressBar stays (tests and other code read it); it just draws nothing itself.
	_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_bar.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	_bar.custom_minimum_size.y = 14
	segments = Control.new()
	segments.name = "Segments"
	segments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	segments.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	segments.draw.connect(_draw_segments)
	_bar.add_child(segments)


func _lift_unit() -> void:
	var unit: Label = $Panel/Margin/Rows/SpeedRow/Unit
	var big := _speed.get_theme_font("font")
	var small := unit.get_theme_font("font")
	var lift := big.get_descent(_speed.get_theme_font_size("font_size")) - small.get_descent(unit.get_theme_font_size("font_size"))
	var pad := StyleBoxEmpty.new()
	pad.content_margin_bottom = maxf(lift, 0.0)
	unit.add_theme_stylebox_override("normal", pad)


## Baseline of a bottom-aligned label (tests check the speed and its unit match).
static func baseline_of(label: Label) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var pad := label.get_theme_stylebox("normal").content_margin_bottom if label.has_theme_stylebox("normal") else 0.0
	return label.get_global_rect().end.y - maxf(pad, 0.0) - font.get_descent(font_size)


## Five segments: cyan, brighter while sprinting, pulsing orange when tired.
func _draw_segments() -> void:
	var count := GameConfig.STAMINA_SEGMENTS
	var gap := 5.0
	var width := (segments.size.x - gap * (count - 1)) / count
	var height := segments.size.y
	var filled := _bar.ratio * count
	var sprinting: bool = bike != null and bike.get("sprinting") == true
	var tired: bool = bike != null and bike.get("tired") == true
	var colour := UiPalette.CYAN
	if tired:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU * 1.5)
		colour = BAR_TIRED.lerp(BAR_TIRED.lightened(0.4), 0.0 if Settings.reduce_motion else pulse)
	elif sprinting:
		colour = UiPalette.CYAN.lightened(0.35)
	var empty := Color(UiPalette.SOFT_TEXT, 0.18)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	for i in count:
		var rect := Rect2(i * (width + gap), 0, width, height)
		style.bg_color = empty
		segments.draw_style_box(style, rect)
		var part := clampf(filled - i, 0.0, 1.0)
		if part > 0.0:
			style.bg_color = colour
			segments.draw_style_box(style, Rect2(rect.position, Vector2(maxf(rect.size.x * part, 4.0), height)))
	if sprinting and not tired:
		var glow := Rect2(Vector2(-2, -2), Vector2(segments.size.x * clampf(_bar.ratio, 0.0, 1.0) + 4, height + 4))
		var halo := StyleBoxFlat.new()
		halo.draw_center = false
		halo.set_border_width_all(2)
		halo.border_color = Color(UiPalette.CYAN, 0.5)
		halo.set_corner_radius_all(6)
		segments.draw_style_box(halo, glow)
