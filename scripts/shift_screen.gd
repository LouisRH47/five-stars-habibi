extends CanvasLayer
## The shift on screen: an AM/PM clock at the top middle (8:00 AM to 6:00 PM) and,
## when the shift is over, the summary screen: deliveries, average stars, money earned,
## tips, insurance, bills, XP. "Start next shift" (or E) carries on. The game is paused
## while the summary shows. The numbers come from GameState.shift_summary().

## Sent when you press "Start next shift" (the ShiftManager starts it).
signal next_shift_pressed

const PANEL_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 0.9)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const SOFT := Color(0.79, 0.89, 0.92, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)

## True while the summary is up.
var showing := false
## The last summary shown (for the smoke test).
var last_summary: Dictionary = {}

var _clock: Label
var _sun_icon: Control
var _clock_note: Label
var _summary: PanelContainer
var _title: Label
var _stars: StarRow
var _table: GridContainer
var _shade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_build_clock()
	_build_summary()


func _process(_delta: float) -> void:
	_clock.text = GameClock.format_time(GameState.clock_hours())
	if GameState.shift_clock_out:
		_clock_note.text = "Shift over: finish your delivery" if GameState.current_order != null else "Shift over"
		_clock.modulate = ORANGE
	elif GameState.shift_time_left <= GameConfig.SHIFT_WARNING_TIME:
		_clock_note.text = "Last orders!"
		_clock.modulate = ORANGE
	else:
		_clock_note.text = "Shift %d" % GameState.shift_number
		_clock.modulate = Color(1, 1, 1, 1)


func _unhandled_input(event: InputEvent) -> void:
	if showing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_next_shift()


## Shows the end-of-shift summary and pauses the game.
func show_summary(summary: Dictionary) -> void:
	last_summary = summary
	showing = true
	get_tree().paused = true
	_title.text = "Shift %d done!" % GameState.shift_number
	_stars.stars = roundf(summary["stars"] * 2.0) / 2.0
	for child in _table.get_children():
		child.queue_free()
	var rows := [
		["Deliveries", str(summary["deliveries"])],
		["Average stars", "%.1f" % summary["stars"] if summary["deliveries"] + summary["cancelled"] > 0 else "-"],
		["Pay", "+%d Dh" % summary["pay"]],
		["Tips", "+%d Dh" % summary["tips"]],
		["Insurance", "-%d Dh" % summary["insurance"]],
		["Crash bills", "-%d Dh" % summary["bills"]],
		["You earned", "%d Dh" % summary["earned"]],
		["XP", "+%d" % summary["xp"]],
	]
	if summary["cancelled"] > 0:
		rows.insert(1, ["Cancelled", str(summary["cancelled"])])
	# Session 32: each shift goal, with its 15 Dh bonus if you did it.
	for goal in summary.get("goals", []):
		var at := rows.size() - 2  # just above "You earned"
		rows.insert(at, ["%s %s" % ["✓" if goal["done"] else "•", goal["text"]],
				"+%d Dh" % GameConfig.GOAL_BONUS if goal["done"] else "-"])
	for row in rows:
		var big: bool = row[0] == "You earned"
		_table.add_child(_label(row[0], 22 if big else 19, ORANGE if big else SOFT))
		var value := _label(row[1], 22 if big else 19, ORANGE if big else TEXT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_table.add_child(value)
	_shade.visible = true
	_summary.visible = true


func _next_shift() -> void:
	showing = false
	_summary.visible = false
	_shade.visible = false
	get_tree().paused = false
	next_shift_pressed.emit()


func _build_clock() -> void:
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.offset_top = 24
	box.custom_minimum_size = Vector2(220, 0)
	box.add_theme_stylebox_override("panel", _style(18, 2, 10))
	add_child(box)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", -2)
	box.add_child(rows)
	var clock_row := HBoxContainer.new()
	clock_row.alignment = BoxContainer.ALIGNMENT_CENTER
	clock_row.add_theme_constant_override("separation", 10)
	rows.add_child(clock_row)
	_sun_icon = Control.new()
	_sun_icon.custom_minimum_size = Vector2(22, 22)
	_sun_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sun_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sun_icon.draw.connect(_draw_sun)
	clock_row.add_child(_sun_icon)
	_clock = _label(GameClock.format_time(GameState.clock_hours()), 34, TEXT)
	_clock.theme_type_variation = &"BigNumber"
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_row.add_child(_clock)
	_clock_note = _label("Shift 1", 13, SOFT)
	_clock_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_clock_note)


## Draw the sun directly so it doesn't depend on a font's symbol coverage.
func _draw_sun() -> void:
	var centre := _sun_icon.size * 0.5
	_sun_icon.draw_circle(centre, 4.0, ORANGE)
	for ray in range(8):
		var direction := Vector2.from_angle(ray * TAU / 8.0)
		_sun_icon.draw_line(centre + direction * 7.0, centre + direction * 10.0, ORANGE, 2.0, true)


func _build_summary() -> void:
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.55)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.visible = false
	add_child(_shade)
	_summary = PanelContainer.new()
	_summary.visible = false
	_summary.set_anchors_preset(Control.PRESET_CENTER)
	_summary.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_summary.grow_vertical = Control.GROW_DIRECTION_BOTH
	_summary.custom_minimum_size = Vector2(480, 0)
	_summary.add_theme_stylebox_override("panel", _style(24, 4, 32))
	add_child(_summary)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	_summary.add_child(rows)
	_title = _label("Shift done!", 38, ORANGE)
	_title.theme_type_variation = &"Heading"
	rows.add_child(_title)
	_stars = StarRow.new()
	_stars.star_size = 36.0
	rows.add_child(_stars)
	_table = GridContainer.new()
	_table.columns = 2
	_table.add_theme_constant_override("v_separation", 6)
	rows.add_child(_table)
	var next := Button.new()
	next.text = "Start next shift  (E)"
	next.add_theme_font_size_override("font_size", 20)
	next.pressed.connect(_next_shift)
	rows.add_child(next)


func _style(radius: int, border: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOUR
	style.border_color = TEAL
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
