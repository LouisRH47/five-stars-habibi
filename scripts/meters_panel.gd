extends CanvasLayer
## The meters panel: time, freshness and damage bars while you carry food.
## Each bar is green, orange or red (PRD bands). It only shows things: the values live
## in GameState and scripts/meters.gd changes them.
## Session 69 (GameConfig.METERS_V2): the panel sits at the bottom middle like the mockup.
## Each meter has an icon, a word ("On time / A bit late / Late", the Delivered card words)
## and tick marks where the colours change. When one drops into a worse colour it flashes,
## shakes a little and blips. Colour help (Settings.colour_assist) uses the colour-blind set,
## and red gets stripes so colour is never the only clue. Old look: METERS_V2 = false.

const GREEN := Color(0.36, 0.8, 0.45, 1)
const ORANGE := Color(0.95, 0.6, 0.18, 1)
const RED := Color(0.9, 0.25, 0.22, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const SOFT := Color(0.79, 0.89, 0.92, 1)
## The words for green, orange and red (the same as the Delivered card's tiles).
const WORDS := {
	"time": ["On time", "A bit late", "Late"],
	"freshness": ["Fresh", "Okay", "Not fresh"],
	"damage": ["Perfect", "Shaken", "Smashed"],
}
## Foods that should stay cold get a snowflake; the rest a thermometer.
const COLD_FOODS := ["ice cream", "bubble tea", "iced latte", "farm juice"]
const MARGIN := 24.0
const GAP := 16.0  # room kept between the meters and other panels
const WIDE_WIDTH := 780.0  # the mockup's 520 px at 1280, at the 1920 base

var _bars: Dictionary = {}    # "time" -> ProgressBar
var _fills: Dictionary = {}   # "time" -> StyleBoxFlat (its colour changes)
var _values: Dictionary = {}  # "time" -> Label
## Session 69: the word on each meter, its band (0 green, 1 orange, 2 red) and its column.
var words: Dictionary = {}    # "time" -> Label
var bands: Dictionary = {}    # "time" -> int
var _columns: Dictionary = {} # "time" -> PanelContainer
var _icons: Dictionary = {}   # "time" -> Control
## How many warning pulses have played (tests read it).
var pulses := 0
## "wide" (three meters side by side) or "stacked" (one under the other).
var layout_mode_name := "wide"
var _grid: GridContainer

@onready var _panel: Control = $Panel
@onready var _rows: VBoxContainer = $Panel/Margin/Rows
@onready var _title: Label = $Panel/Margin/Rows/Title


func _ready() -> void:
	if GameConfig.METERS_V2:
		_build_v2()
	else:
		for key in ["time", "freshness", "damage"]:
			_add_row(key)
	GameState.meters_changed.connect(_refresh)
	GameState.order_stage_changed.connect(func(_stage): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	if _panel.visible:
		var left := maxf(GameState.target_time - GameState.ride_time, 0.0)
		_values["time"].text = "%d:%02d" % [int(left) / 60, int(left) % 60]
		if GameConfig.METERS_V2:
			place()


func _refresh() -> void:
	var was_visible := _panel.visible
	_panel.visible = GameState.stage == GameState.Stage.TO_VILLA and GameState.current_order != null
	if not _panel.visible:
		bands.clear()
		return
	_title.text = GameState.current_order.food.capitalize()
	if GameConfig.METERS_V2 and not was_visible:
		bands.clear()  # a new delivery: no warnings for the bars filling up
		var cold: bool = GameState.current_order.food in COLD_FOODS
		_icons["freshness"].set_meta("cold", cold)
		_icons["freshness"].queue_redraw()
		place()
	_show("time", GameState.meter_time)
	_show("freshness", GameState.meter_freshness)
	_show("damage", GameState.meter_damage)


func _show(key: String, value: float) -> void:
	_bars[key].value = value
	if GameConfig.METERS_V2:
		_show_v2(key, value)
		return
	var colour := RED
	match Meters.band(value):
		Meters.Band.GREEN:
			colour = GREEN
		Meters.Band.ORANGE:
			colour = ORANGE
	var fill: StyleBoxFlat = _fills[key]
	if fill.bg_color != colour:
		fill.bg_color = colour
	if key != "time":
		_values[key].text = "%d%%" % roundi(value)


func _show_v2(key: String, value: float) -> void:
	var band := int(Meters.band(value))
	var colour := UiPalette.band_colour(band)
	var fill: StyleBoxFlat = _fills[key]
	if fill.bg_color != colour or words[key].text == "":
		fill.bg_color = colour
		words[key].text = WORDS[key][band]
		words[key].add_theme_color_override("font_color", colour.lightened(0.35))
		var ring := _columns[key].get_theme_stylebox("panel") as StyleBoxFlat
		ring.border_color = Color(colour, 0.75 if band > 0 else 0.0)
	_bars[key].get_child(0).queue_redraw()  # ticks and stripes
	if bands.has(key) and band > bands[key]:
		_pulse(key)
	bands[key] = band


## A meter dropped into a worse colour: flash, a little shake and a soft blip.
func _pulse(key: String) -> void:
	pulses += 1
	UiSounds.play("meter_warn")
	var column: Control = _columns[key]
	var t := column.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var flash := GameConfig.METER_FLASH_TIME / 4.0
	for i in 2:
		t.tween_property(column, "modulate", Color(1.8, 1.8, 1.8), flash)
		t.tween_property(column, "modulate", Color.WHITE, flash)
	UiJuice.shake(column, 4.0, 0.25)


## Bottom middle, between the mini-map and the speed panel. If three meters side by side
## don't fit there, they stack; above the tutorial tip and the touch buttons when those show.
func place() -> void:
	var screen := _panel.get_viewport_rect().size
	var world := get_parent()
	var left_edge := MARGIN
	var right_edge := screen.x - MARGIN
	var bottom := screen.y - MARGIN
	var minimap := _rect_of(world, "Minimap/Panel")
	var speed := _rect_of(world, "HUD/Panel")
	if minimap.size.x > 0.0:
		left_edge = maxf(left_edge, minimap.end.x + GAP)
	if speed.size.x > 0.0:
		right_edge = minf(right_edge, speed.position.x - GAP)
	var half := minf(screen.x * 0.5 - left_edge, right_edge - screen.x * 0.5)
	var wide := half * 2.0 >= _wide_width()
	_set_columns(3 if wide else 1)
	var hud_panel := world.get_node_or_null("HUD/Panel") if world != null else null
	if hud_panel != null and hud_panel.has_meta("touch_raised"):
		bottom -= 300.0  # the touch buttons fill the bottom of the screen
	var tutorial := world.get_node_or_null("Tutorial") if world != null else null
	if tutorial != null and tutorial.get("visible") != false and tutorial.get_child_count() > 0:
		var tip := tutorial.get_child(0) as Control
		if tip != null and tip.visible:
			bottom = minf(bottom, tip.get_global_rect().position.y - 12.0)
	var width := _wide_width() if wide else 0.0
	width = maxf(width, _panel.get_combined_minimum_size().x)
	var height := _panel.get_combined_minimum_size().y
	# A tall phone on a narrow screen: stay left of it.
	var phone := _rect_of(world, "Phone/Panel")
	if phone.size.x > 0.0 and phone.end.y > bottom - height and phone.position.x < screen.x * 0.5 + width * 0.5 + GAP:
		var room := phone.position.x - GAP - left_edge
		if room >= width:
			var x := clampf(roundf((screen.x - width) * 0.5), left_edge, phone.position.x - GAP - width)
			_apply(Rect2(Vector2(x, roundf(bottom - height)), Vector2(width, height)))
			return
	_apply(Rect2(Vector2(roundf((screen.x - width) * 0.5), roundf(bottom - height)), Vector2(width, height)))


func _apply(want: Rect2) -> void:
	if _panel.position != want.position or _panel.size != want.size:
		_panel.position = want.position
		_panel.size = want.size


## How wide the three meters side by side are (at least the mockup's width).
func _wide_width() -> float:
	var column := 0.0
	for key in _columns:
		column = maxf(column, _columns[key].get_combined_minimum_size().x)
	var margin: MarginContainer = $Panel/Margin
	var sides: float = margin.get_theme_constant("margin_left") + margin.get_theme_constant("margin_right")
	return maxf(WIDE_WIDTH, column * 3.0 + _grid.get_theme_constant("h_separation") * 2.0 + sides)


func _rect_of(world: Node, path: String) -> Rect2:
	var node := world.get_node_or_null(path) as Control if world != null else null
	if node == null or not node.is_visible_in_tree():
		return Rect2()
	return node.get_global_rect()


func _set_columns(count: int) -> void:
	if _grid.columns == count:
		return
	_grid.columns = count
	layout_mode_name = "wide" if count == 3 else "stacked"
	_panel.size = Vector2.ZERO  # shrink to the new shape


func _build_v2() -> void:
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.custom_minimum_size = Vector2.ZERO
	var style := (_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = UiPalette.PANEL
	style.set_corner_radius_all(27)
	_panel.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = $Panel/Margin
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 21)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_title.visible = false  # the phone already says what food it is
	_grid = GridContainer.new()
	_grid.name = "Meters"
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 6)
	_rows.add_child(_grid)
	for key in ["time", "freshness", "damage"]:
		_add_meter(key)


func _add_meter(key: String) -> void:
	var column := PanelContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.set_border_width_all(2)
	ring.border_color = Color(0, 0, 0, 0)
	ring.set_corner_radius_all(14)
	ring.set_content_margin_all(6)
	column.add_theme_stylebox_override("panel", ring)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 6)
	column.add_child(inside)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	inside.add_child(head)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.draw.connect(_draw_icon.bind(icon, key))
	head.add_child(icon)
	head.add_child(_label(key.capitalize(), UiPalette.FONT_LABEL, Color.WHITE))
	var value := _label("", UiPalette.FONT_BODY, UiPalette.SOFT_TEXT)
	value.visible = key == "time"  # the time left; percentages stay off the bars (words instead)
	head.add_child(value)
	var word := _label("", UiPalette.FONT_BODY, UiPalette.SOFT_TEXT)
	word.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(word)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(212, 16)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(UiPalette.SOFT_TEXT, 0.18)
	back.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiPalette.band_colour(0)
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	var marks := Control.new()
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marks.draw.connect(_draw_marks.bind(marks, bar))
	bar.add_child(marks)
	inside.add_child(bar)
	_grid.add_child(column)
	_bars[key] = bar
	_fills[key] = fill
	_values[key] = value
	words[key] = word
	_columns[key] = column
	_icons[key] = icon


## Tick marks where the colours change (60% and 30%), and stripes on red with Colour help.
func _draw_marks(marks: Control, bar: ProgressBar) -> void:
	var h := marks.size.y
	if Settings.colour_assist and bar.value < GameConfig.METER_RED_BELOW:
		var end := marks.size.x * bar.ratio
		var x := -h
		while x < end:
			# A line from (x, h) up to (x + h, 0), cut to the filled part of the bar.
			var from := Vector2(maxf(x, 0.0), h - (maxf(x, 0.0) - x))
			var to := Vector2(minf(x + h, end), h - (minf(x + h, end) - x))
			if from.x < to.x:
				marks.draw_line(from, to, Color(1, 1, 1, 0.5), 3.0)
			x += 9.0
	for at in [GameConfig.METER_RED_BELOW, GameConfig.METER_GREEN_ABOVE]:
		var px := roundf(marks.size.x * at / 100.0)
		marks.draw_line(Vector2(px, -3), Vector2(px, h + 3), UiPalette.PANEL, 3.0)


func _draw_icon(icon: Control, key: String) -> void:
	var c := icon.size * 0.5
	var ink := Color.WHITE
	match key:
		"time":  # a stopwatch
			icon.draw_arc(c + Vector2(0, 1.5), 9.0, 0.0, TAU, 24, ink, 2.5, true)
			icon.draw_line(c + Vector2(-2.5, -11), c + Vector2(2.5, -11), ink, 3.0)
			icon.draw_line(c + Vector2(0, 1.5), c + Vector2(0, -4.5), ink, 2.5)
			icon.draw_line(c + Vector2(0, 1.5), c + Vector2(4, 1.5), ink, 2.5)
		"freshness":
			if icon.get_meta("cold", false):  # a snowflake
				for i in 3:
					var way := Vector2.from_angle(i * PI / 3.0 + PI / 2.0) * 10.0
					icon.draw_line(c - way, c + way, ink, 2.5)
					for end in [way, -way]:
						var tip: Vector2 = c + end * 0.62
						icon.draw_line(tip, tip + end.rotated(0.8) * 0.3, ink, 2.0)
						icon.draw_line(tip, tip + end.rotated(-0.8) * 0.3, ink, 2.0)
			else:  # a thermometer
				icon.draw_line(c + Vector2(0, -10), c + Vector2(0, 3), ink, 5.0)
				icon.draw_circle(c + Vector2(0, 6), 5.0, ink)
				icon.draw_line(c + Vector2(0, -6), c + Vector2(0, 4), UiPalette.ORANGE, 2.0)
				icon.draw_circle(c + Vector2(0, 6), 3.0, UiPalette.ORANGE)
		"damage":  # a box
			var top := PackedVector2Array([c + Vector2(0, -10), c + Vector2(10, -5), c + Vector2(0, 0), c + Vector2(-10, -5)])
			icon.draw_colored_polygon(top, Color(ink, 0.9))
			icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -5), c + Vector2(0, 0), c + Vector2(0, 11), c + Vector2(-10, 6)]), Color(ink, 0.7))
			icon.draw_colored_polygon(PackedVector2Array([c + Vector2(10, -5), c + Vector2(0, 0), c + Vector2(0, 11), c + Vector2(10, 6)]), Color(ink, 0.5))


func _add_row(key: String) -> void:
	var head := HBoxContainer.new()
	var name_label := _label(key.to_upper(), 13, SOFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := _label("", 15, TEXT)
	value.theme_type_variation = &"BigNumber"
	head.add_child(name_label)
	head.add_child(value)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.18, 0.29, 0.32, 1)
	back.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GREEN
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	_rows.add_child(head)
	_rows.add_child(bar)
	_bars[key] = bar
	_fills[key] = fill
	_values[key] = value


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
