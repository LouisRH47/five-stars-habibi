extends HFlowContainer
## Session 69 (H1): three dark chips at the top left, like the mockup: WALLET, RATING and LEVEL
## (with an XP bar and your 5-star streak). Money counts up and a green "+15" floats up.
## A level-up flashes the level chip gold. The chips wrap onto a second row when the
## window is narrow, so they never run into the clock. Switch: GameConfig.HUD_TOP_CHIPS.

## Gap between the chips and the clock at the top middle.
const CLOCK_GAP := 16.0
const MARGIN := 24.0

## The clock panel to keep clear of (ShiftScreen.clock_box), if there is one.
var clock_box: Control
## The money the wallet is showing (or counting towards).
var shown_money := 0
## How many "+N" floats were made, and the last one (tests read these).
var floats_made := 0
var last_float: Label
## How many times the level chip flashed gold (tests read it).
var level_flashes := 0
var _wallet: Label
var _wallet_chip: PanelContainer
var _rating: Label
var _star: Control
var _level: Label
var _xp: Label
var _xp_bar: Control
var _xp_ratio := 0.0
var _streak: Label
var _level_chip: PanelContainer
var _level_now := 0
var _count: Tween


func _ready() -> void:
	name = "Chips"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 12)
	add_theme_constant_override("v_separation", 12)
	position = Vector2(MARGIN, MARGIN)
	_wallet_chip = _chip("WALLET")
	_wallet = _value(_wallet_chip)
	var rating_chip := _chip("RATING")
	var rating_row := HBoxContainer.new()
	rating_row.add_theme_constant_override("separation", 8)
	_rows_of(rating_chip).add_child(rating_row)
	_rating = _value(rating_chip)
	_rating.reparent(rating_row)
	_star = Control.new()
	_star.custom_minimum_size = Vector2(26, 26)
	_star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_star.draw.connect(_draw_star)
	rating_row.add_child(_star)
	_build_level_chip()
	for label in find_children("*", "Label", true, false):
		tight(label)
	shown_money = GameState.money
	_wallet.text = "%d Dh" % shown_money
	_level_now = GameState.level()
	GameState.money_changed.connect(_on_money)
	GameState.stats_changed.connect(_refresh_stats)
	_refresh_stats()


func _process(_delta: float) -> void:
	# Stay left of the clock: the row wraps when there isn't room for all three chips.
	var room := get_viewport_rect().size.x - MARGIN * 2.0
	if clock_box != null and clock_box.is_visible_in_tree():
		room = clock_box.get_global_rect().position.x - CLOCK_GAP - MARGIN
	var width := maxf(room, _widest_chip())
	if not is_equal_approx(size.x, width):
		size = Vector2(width, 0)


func _widest_chip() -> float:
	var widest := 0.0
	for chip in get_children():
		if chip is Control and chip.visible and not (chip as Control).top_level:
			widest = maxf(widest, (chip as Control).get_combined_minimum_size().x)
	return widest


## Money changed: count up (or down) and float the difference.
func _on_money(money: int) -> void:
	var change := money - shown_money
	if change == 0:
		return
	var from := shown_money
	if _count != null and _count.is_valid():
		_count.kill()
		from = int(_wallet.text.to_int())
	shown_money = money
	_count = UiJuice.count_up(_wallet, from, money, GameConfig.CHIP_COUNT_TIME, "%d Dh")
	UiSounds.play("tick", 1.2 if change > 0 else 0.8)
	_float_change(change)


func _float_change(change: int) -> void:
	var label := Label.new()
	label.text = ("+%d" % change) if change > 0 else ("-%d" % -change)
	label.add_theme_font_size_override("font_size", UiPalette.FONT_LABEL + 4)
	var colour: Color = UiPalette.BAND[0] if change > 0 else UiPalette.BAND[2]
	label.add_theme_color_override("font_color", colour.lightened(0.3))
	label.add_theme_color_override("font_outline_color", UiPalette.INK)
	label.add_theme_constant_override("outline_size", 6)
	label.theme_type_variation = &"BigNumber"
	label.top_level = true  # floats freely, the row doesn't move it
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var chip := _wallet_chip.get_global_rect()
	var start := Vector2(chip.end.x + 6.0, chip.position.y + chip.size.y * 0.35)
	label.position = start
	floats_made += 1
	last_float = label
	var rise := 0.0 if Settings.reduce_motion else GameConfig.CHIP_FLOAT_PIXELS
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	t.tween_property(label, "position:y", start.y - rise, GameConfig.CHIP_FLOAT_TIME) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, GameConfig.CHIP_FLOAT_TIME * 0.5).set_delay(GameConfig.CHIP_FLOAT_TIME * 0.5)
	t.chain().tween_callback(label.queue_free)


func _refresh_stats() -> void:
	var rating := GameState.rating()
	_rating.text = "New" if rating <= 0.0 else "%.1f" % rating
	_star.visible = rating > 0.0
	var level := GameState.level()
	var progress := GameState.level_progress()
	_level.text = "LEVEL %d" % level
	_xp.text = "%d / %d XP" % [progress.x, progress.y]
	_xp_ratio = clampf(float(progress.x) / maxf(progress.y, 1.0), 0.0, 1.0)
	_xp_bar.queue_redraw()
	_streak.text = ("%d in a row · Snackaroo rider" % GameState.streak) if GameState.streak >= 2 else "Snackaroo rider"
	if level > _level_now:
		_level_up()
	_level_now = level


## Level up: the level chip flashes gold.
func _level_up() -> void:
	UiSounds.play("level_up")
	var style := _level_chip.get_theme_stylebox("panel") as StyleBoxFlat
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for i in 3:
		t.tween_property(style, "bg_color", Color(UiPalette.SUN, 0.95), 0.15)
		t.tween_property(style, "bg_color", UiPalette.PANEL, 0.25)
	level_flashes += 1
	UiJuice.pop_in(_level_chip)


func _build_level_chip() -> void:
	_level_chip = _chip("")
	var rows: VBoxContainer = _rows_of(_level_chip)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	rows.get_child(0).reparent(top)  # the caption becomes "LEVEL 3"
	_level = top.get_child(0)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp = _caption("")
	_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_xp)
	rows.add_child(top)
	_xp_bar = Control.new()
	_xp_bar.custom_minimum_size = Vector2(213, 13)
	_xp_bar.draw.connect(_draw_xp)
	rows.add_child(_xp_bar)
	_streak = _caption("")
	_streak.add_theme_color_override("font_color", Color.WHITE)
	rows.add_child(_streak)


func _chip(caption: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.PANEL
	style.set_corner_radius_all(21)
	style.content_margin_left = 21
	style.content_margin_right = 21
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	chip.add_theme_stylebox_override("panel", style)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	chip.add_child(rows)
	rows.add_child(_caption(caption))
	add_child(chip)
	return chip


func _rows_of(chip: PanelContainer) -> VBoxContainer:
	return chip.get_child(0)


## The game's fonts (with the Arabic fallback) leave a lot of empty room above and below the
## letters. This wraps a label in a box with negative margins so only the letters take room:
## `above` and `below` are how much to keep, as a share of the font size.
static func tight(label: Label, above := 0.82, below := 0.14) -> MarginContainer:
	var parent := label.get_parent()
	var index := label.get_index()
	var box := MarginContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = label.size_flags_horizontal
	box.size_flags_vertical = label.size_flags_vertical
	parent.add_child(box)
	parent.move_child(box, index)
	label.reparent(box)
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	box.add_theme_constant_override("margin_top", -maxi(roundi(font.get_ascent(font_size) - font_size * above), 0))
	box.add_theme_constant_override("margin_bottom", -maxi(roundi(font.get_descent(font_size) - font_size * below), 0))
	return box


func _caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SMALL)
	label.add_theme_color_override("font_color", UiPalette.SOFT_TEXT)
	return label


func _value(chip: PanelContainer) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"BigNumber"
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.WHITE)
	_rows_of(chip).add_child(label)
	return label


func _draw_xp() -> void:
	var r := Rect2(Vector2.ZERO, _xp_bar.size)
	_xp_bar.draw_style_box(_bar_style(Color(UiPalette.SOFT_TEXT, 0.2)), r)
	if _xp_ratio > 0.0:
		_xp_bar.draw_style_box(_bar_style(UiPalette.CYAN), Rect2(r.position, Vector2(maxf(r.size.x * _xp_ratio, r.size.y), r.size.y)))


func _bar_style(colour: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = colour
	s.set_corner_radius_all(7)
	return s


## The font has no star letter, so draw one.
func _draw_star() -> void:
	var centre := _star.size * 0.5
	var points := PackedVector2Array()
	for i in 10:
		var radius := 12.5 if i % 2 == 0 else 5.2
		points.append(centre + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * radius)
	_star.draw_colored_polygon(points, UiPalette.SUN)
