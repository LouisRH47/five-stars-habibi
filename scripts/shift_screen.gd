extends CanvasLayer
## The shift on screen: an AM/PM clock at the top middle (8:00 AM to 6:00 PM) and,
## when the shift is over, the summary screen: deliveries, average stars, money earned,
## tips, insurance, bills, XP. "Start next shift" (or E) carries on. The game is paused
## while the summary shows. The numbers come from GameState.shift_summary().
## Session 69: the clock also shows the temperature, today's special and a shift progress bar
## (GameConfig.HUD_CLOCK_V2), and the summary counts up row by row with goal stamps and a
## "New best!" ribbon; E skips to the end (GameConfig.SUMMARY_V2).

## Sent when you press "Start next shift" (the ShiftManager starts it).
signal next_shift_pressed

const PANEL_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 0.9)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const SOFT := Color(0.79, 0.89, 0.92, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const HudChips := preload("res://scripts/hud_chips.gd")

## True while the summary is up.
var showing := false
## The last summary shown (for the smoke test).
var last_summary: Dictionary = {}

var _clock: Label
var _sun_icon: Control
var _clock_note: Label
var _day_note: Label
var _summary: PanelContainer
var _title: Label
var _stars: StarRow
var _new_best: Label
var _table: GridContainer
var _gear_goal: Label
var _gear_progress: ProgressBar
var _tomorrow: Label
var _shade: ColorRect
## Session 69: the clock's panel (the top-left chips keep clear of it) and its progress bar.
var clock_box: PanelContainer
var progress_bar: Control
var _progress := 0.0
var _clock_row: HBoxContainer
var _last_pulse_minute := -1
## Session 69: the summary's count-up (null when finished) and its rows, for E to skip.
var reveal: Tween
var _reveal_rows: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_build_clock()
	_build_summary()


func _process(_delta: float) -> void:
	_clock.text = GameClock.format_time(GameState.clock_hours())
	_day_note.text = GameState.day_label()
	_day_note.tooltip_text = ReplayCatalog.day_detail(GameState.day_kind)
	if GameState.shift_clock_out:
		_clock_note.text = "Shift over: finish your delivery" if GameState.current_order != null else "Shift over"
		_clock.modulate = ORANGE
	elif GameState.shift_time_left <= GameConfig.SHIFT_WARNING_TIME:
		_clock_note.text = "Last orders!"
		_clock.modulate = ORANGE
	else:
		_clock_note.text = "Shift %d" % GameState.shift_number
		_clock.modulate = Color(1, 1, 1, 1)
		if GameConfig.HUD_CLOCK_V2:
			_clock_note.text = info_line()
	if GameConfig.HUD_CLOCK_V2:
		_update_progress()


func _unhandled_input(event: InputEvent) -> void:
	if showing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if is_revealing():
			finish_reveal()  # the first E skips the count-up, the next one starts the shift
		else:
			_next_shift()


## Session 69: "Shift 3 · 41°C · Brain Freeze special".
func info_line() -> String:
	return "Shift %d · %d°C · %s" % [GameState.shift_number, temperature_at(GameState.clock_hours(), GameState.day_kind),
			GameState.day_label()]


## The temperature for the clock: slides between the hours in GameConfig.SHIFT_TEMPERATURE.
static func temperature_at(hour: float, day_kind := "normal") -> int:
	var hours: Array = GameConfig.SHIFT_TEMPERATURE.keys()
	hours.sort()
	var degrees: float = GameConfig.SHIFT_TEMPERATURE[hours[0]]
	if hour >= hours[-1]:
		degrees = GameConfig.SHIFT_TEMPERATURE[hours[-1]]
	else:
		for i in range(hours.size() - 1):
			if hour >= hours[i] and hour < hours[i + 1]:
				var t: float = (hour - hours[i]) / (hours[i + 1] - hours[i])
				degrees = lerpf(GameConfig.SHIFT_TEMPERATURE[hours[i]], GameConfig.SHIFT_TEMPERATURE[hours[i + 1]], t)
	if day_kind == "hot_noon":
		degrees += GameConfig.HOT_NOON_EXTRA_DEGREES
	return roundi(degrees)


## How far through the shift we are: 0 at 8 AM, 1 at 6 PM.
static func shift_progress(hour: float) -> float:
	return clampf((hour - GameConfig.SHIFT_START_HOUR) / (GameConfig.SHIFT_END_HOUR - GameConfig.SHIFT_START_HOUR), 0.0, 1.0)


func progress_value() -> float:
	return _progress


func _update_progress() -> void:
	var hour := GameState.clock_hours()
	var now := shift_progress(hour)
	if not is_equal_approx(now, _progress):
		_progress = now
		progress_bar.queue_redraw()
	# The last hour: the bar turns orange and the clock pulses gently every 10 game minutes.
	var last_hour := hour >= GameConfig.SHIFT_END_HOUR - 1.0 and not GameState.shift_clock_out
	var minute := floori(hour * 60.0 + 0.000001)
	if last_hour and minute % 10 == 0 and minute != _last_pulse_minute:
		_last_pulse_minute = minute
		_pulse_clock()


func _pulse_clock() -> void:
	if Settings.reduce_motion or _clock_row.size.x <= 0.0:
		return
	_clock_row.pivot_offset = _clock_row.size * 0.5
	var t := _clock_row.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_clock_row, "scale", Vector2.ONE * GameConfig.CLOCK_LAST_HOUR_PULSE, 0.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(_clock_row, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)


func _draw_progress() -> void:
	var r := Rect2(Vector2.ZERO, progress_bar.size)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(UiPalette.SOFT_TEXT, 0.18)
	back.set_corner_radius_all(4)
	progress_bar.draw_style_box(back, r)
	if _progress <= 0.0:
		return
	var last_hour := GameState.clock_hours() >= GameConfig.SHIFT_END_HOUR - 1.0
	back.bg_color = UiPalette.ORANGE if last_hour else UiPalette.SUN
	progress_bar.draw_style_box(back, Rect2(r.position, Vector2(maxf(r.size.x * _progress, r.size.y), r.size.y)))


## Shows the end-of-shift summary and pauses the game.
func show_summary(summary: Dictionary) -> void:
	last_summary = summary
	showing = true
	get_tree().paused = true
	_title.text = "Shift %d done!" % GameState.shift_number
	_stars.stars = roundf(summary["stars"] * 2.0) / 2.0
	var new_bests: Array = summary.get("new_bests", [])
	_new_best.visible = not new_bests.is_empty()
	var next_goal := GearCatalog.next_goal(GameState)
	_gear_goal.text = "Next upgrade: " + next_goal["description"]
	_gear_progress.ratio = next_goal["progress"]
	_tomorrow.text = "Tomorrow: " + ReplayCatalog.day_name(summary.get("tomorrow", "normal"))
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
	if summary.get("collection_bonus", 0) > 0:
		rows.insert(4, ["Stamp card bonus", "+%d Dh" % summary["collection_bonus"]])
	for best in new_bests:
		rows.append(["Personal best", best])
	if summary["cancelled"] > 0:
		rows.insert(1, ["Cancelled", str(summary["cancelled"])])
	# Session 32: each shift goal, with its 15 Dh bonus if you did it.
	for goal in summary.get("goals", []):
		var at := 0
		while at < rows.size() and rows[at][0] != "You earned":
			at += 1
		rows.insert(at, ["%s %s" % ["✓" if goal["done"] else "•", goal["text"]],
				"+%d Dh" % GameConfig.GOAL_BONUS if goal["done"] else "-"])
	_reveal_rows.clear()
	for row in rows:
		var big: bool = row[0] == "You earned"
		var name_label := _label(row[0], 20 if big else 16, ORANGE if big else SOFT)
		_table.add_child(name_label)
		var value := _label(row[1], 20 if big else 16, ORANGE if big else TEXT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_table.add_child(value)
		if GameConfig.SUMMARY_V2:
			_style_row(name_label, value, row, big)
	_shade.visible = true
	_summary.visible = true
	if GameConfig.SUMMARY_V2:
		# Taller list on big screens, shorter on small ones so the button always fits.
		var scroll := _table.get_parent() as Control
		scroll.custom_minimum_size.y = clampf(_summary.get_viewport_rect().size.y - 600.0, 220.0, 400.0)
		_start_reveal()


## Session 69: bigger text, gold personal bests, and goal bonuses as stamps.
func _style_row(name_label: Label, value: Label, row: Array, big: bool) -> void:
	var size := UiPalette.FONT_TITLE if big else UiPalette.FONT_BODY
	name_label.add_theme_font_size_override("font_size", size)
	value.add_theme_font_size_override("font_size", size if big else UiPalette.FONT_LABEL)
	if big:
		value.theme_type_variation = &"BigNumber"
	var kind := "count"
	if row[0] == "Personal best":
		kind = "best"
		name_label.add_theme_color_override("font_color", UiPalette.SUN)
		value.add_theme_color_override("font_color", UiPalette.SUN)
	elif String(row[0]).begins_with("✓ "):
		kind = "stamp"
		value.add_theme_color_override("font_color", UiPalette.ORANGE)
		value.size_flags_horizontal = Control.SIZE_SHRINK_END
		var stamp := StyleBoxFlat.new()
		stamp.bg_color = Color(UiPalette.ORANGE, 0.12)
		stamp.border_color = UiPalette.ORANGE
		stamp.set_border_width_all(2)
		stamp.set_corner_radius_all(6)
		stamp.content_margin_left = 8
		stamp.content_margin_right = 8
		value.add_theme_stylebox_override("normal", stamp)
	elif String(row[0]).begins_with("• "):
		kind = "plain"
	_reveal_rows.append({"name": name_label, "value": value, "text": row[1], "kind": kind})


## Session 69: the rows appear one after another, numbers counting up from 0.
func _start_reveal() -> void:
	if reveal != null and reveal.is_valid():
		reveal.kill()
	var quick := 0.5 if Settings.reduce_motion else 1.0
	reveal = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	var at := 0.15
	_title.modulate.a = 0.0
	reveal.tween_property(_title, "modulate:a", 1.0, UiPalette.PANEL_TIME)
	for item in _reveal_rows:
		var name_label: Label = item["name"]
		var value: Label = item["value"]
		name_label.modulate.a = 0.0
		value.modulate.a = 0.0
		reveal.tween_property(name_label, "modulate:a", 1.0, UiPalette.FAST * 2.0).set_delay(at)
		reveal.tween_property(value, "modulate:a", 1.0, UiPalette.FAST * 2.0).set_delay(at)
		reveal.tween_callback(_scroll_to.bind(value)).set_delay(at)
		var parts := _number_parts(item["text"])
		if item["kind"] == "count" and not parts.is_empty():
			value.text = _format_number(parts, 0.0)
			reveal.tween_method(func(v: float): value.text = _format_number(parts, v), 0.0, parts["number"],
					GameConfig.SUMMARY_COUNT_TIME * quick).set_delay(at).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			reveal.tween_callback(UiSounds.play.bind("tick", 1.0 + at * 0.1)).set_delay(at)
		elif item["kind"] == "stamp":
			value.pivot_offset = value.get_combined_minimum_size() * 0.5
			value.rotation_degrees = -6.0
			if not Settings.reduce_motion:
				value.scale = Vector2.ONE * 1.8
				reveal.tween_property(value, "scale", Vector2.ONE, GameConfig.SUMMARY_STAMP_TIME).set_delay(at) \
						.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			reveal.tween_callback(UiSounds.play.bind("stamp")).set_delay(at)
		at += GameConfig.SUMMARY_ROW_GAP * quick
	for extra in [_new_best, _tomorrow]:
		var final_alpha := 1.0
		extra.modulate.a = 0.0
		reveal.tween_property(extra, "modulate:a", final_alpha, UiPalette.PANEL_TIME).set_delay(at)
	if _new_best.visible:
		reveal.tween_callback(UiSounds.play.bind("level_up")).set_delay(at)
		if not Settings.reduce_motion:
			reveal.tween_callback(func(): UiJuice.pop_in(_new_best)).set_delay(at)
	reveal.chain().tween_callback(finish_reveal)


## Keep the newest row in view while the list counts up.
func _scroll_to(row: Control) -> void:
	var scroll := _table.get_parent() as ScrollContainer
	if scroll != null and is_instance_valid(row):
		scroll.ensure_control_visible(row)


func is_revealing() -> bool:
	return reveal != null and reveal.is_valid() and reveal.is_running()


## Jump to the end: every row and number shows its final value.
func finish_reveal() -> void:
	if reveal != null and reveal.is_valid():
		reveal.kill()
	reveal = null
	_title.modulate.a = 1.0
	for item in _reveal_rows:
		item["name"].modulate.a = 1.0
		item["value"].modulate.a = 1.0
		item["value"].text = item["text"]
		item["value"].scale = Vector2.ONE
	_new_best.modulate.a = 1.0
	_new_best.scale = Vector2.ONE
	_tomorrow.modulate.a = 1.0


## "+98 Dh" -> sign "+", number 98, decimals 0, unit " Dh". Empty if there's no number.
static func _number_parts(text: String) -> Dictionary:
	var regex := RegEx.create_from_string("^([+-]?)(\\d+(?:\\.(\\d+))?)(.*)$")
	var found := regex.search(text)
	if found == null:
		return {}
	return {"sign": found.get_string(1), "number": found.get_string(2).to_float(),
			"decimals": found.get_string(3).length(), "unit": found.get_string(4)}


static func _format_number(parts: Dictionary, value: float) -> String:
	var number := ("%." + str(parts["decimals"]) + "f") % value if parts["decimals"] > 0 else str(roundi(value))
	return parts["sign"] + number + parts["unit"]


func _next_shift() -> void:
	if reveal != null:
		finish_reveal()
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
	_day_note = _label(GameState.day_label(), 13, ORANGE)
	_day_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_day_note)
	clock_box = box
	_clock_row = clock_row
	if GameConfig.HUD_CLOCK_V2:
		_clock_v2(box, rows)


## Session 69: a smaller, fuller clock like the mockup: time, one info line, a progress bar.
func _clock_v2(box: PanelContainer, rows: VBoxContainer) -> void:
	var style := _style(24, 0, 0)
	style.bg_color = UiPalette.PANEL
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	box.add_theme_stylebox_override("panel", style)
	box.custom_minimum_size = Vector2(330, 0)
	rows.add_theme_constant_override("separation", 2)
	_clock.add_theme_font_size_override("font_size", 39)
	_clock_note.add_theme_font_size_override("font_size", UiPalette.FONT_BODY)
	_clock_note.add_theme_color_override("font_color", UiPalette.SOFT_TEXT)
	_clock_note.text = info_line()
	_day_note.visible = false  # today's special is on the info line now
	# Only the letters take room (the fonts leave a lot of empty space), like the mockup's slim clock.
	HudChips.tight(_clock)
	HudChips.tight(_clock_note)
	progress_bar = Control.new()
	progress_bar.name = "ShiftProgress"
	progress_bar.custom_minimum_size = Vector2(0, 9)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.draw.connect(_draw_progress)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	rows.add_child(gap)
	rows.add_child(progress_bar)
	_progress = shift_progress(GameState.clock_hours())


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
	_new_best = _label("New best!", 20, ORANGE)
	_new_best.hide()
	rows.add_child(_new_best)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(scroll)
	_table = GridContainer.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.columns = 2
	_table.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_table)
	var upgrade := VBoxContainer.new()
	upgrade.name = "NextUpgrade"
	rows.add_child(upgrade)
	_gear_goal = _label("", 16, TEXT)
	_gear_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade.add_child(_gear_goal)
	_gear_progress = ProgressBar.new()
	_gear_progress.custom_minimum_size.y = 5
	_gear_progress.show_percentage = false
	_gear_progress.step = 0.0
	upgrade.add_child(_gear_progress)
	_tomorrow = _label("", 18, ORANGE)
	_tomorrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_tomorrow)
	if GameConfig.SUMMARY_V2:
		_summary_v2_look()
	var next := Button.new()
	next.text = "Start next shift  (E)"
	next.add_theme_font_size_override("font_size", 20)
	next.pressed.connect(_next_shift)
	rows.add_child(next)


## Session 69: a gold "New best!" ribbon and a "Tomorrow" card (same labels, so tests still find them).
func _summary_v2_look() -> void:
	_title.add_theme_font_size_override("font_size", 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stars.star_size = 40.0
	_new_best.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_new_best.add_theme_color_override("font_color", UiPalette.INK)
	_new_best.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL + 2)
	_new_best.theme_type_variation = &"Heading"
	var ribbon := StyleBoxFlat.new()
	ribbon.bg_color = UiPalette.SUN
	ribbon.set_corner_radius_all(6)
	ribbon.content_margin_left = 28
	ribbon.content_margin_right = 28
	ribbon.content_margin_top = 2
	ribbon.content_margin_bottom = 2
	ribbon.skew = Vector2(-0.18, 0)
	_new_best.add_theme_stylebox_override("normal", ribbon)
	var card := StyleBoxFlat.new()
	card.bg_color = Color(UiPalette.ORANGE, 0.14)
	card.border_color = Color(UiPalette.ORANGE, 0.7)
	card.set_border_width_all(2)
	card.set_corner_radius_all(14)
	card.set_content_margin_all(10)
	_tomorrow.add_theme_stylebox_override("normal", card)
	_tomorrow.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL)
	_gear_goal.add_theme_font_size_override("font_size", UiPalette.FONT_BODY)


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
