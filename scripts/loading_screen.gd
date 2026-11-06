class_name LoadingScreen
extends CanvasLayer
## The loading screen (Session 86): shown while the world is built step by step, and
## (short) at the start of each shift. It covers everything: the start-screen desert at
## the back (scripts/desert_backdrop.gd), "AL SARAB" and the game's name at the top left,
## a tip that changes every few seconds, a rounded orange progress bar with the step name
## under it, and a little bike riding along the bottom as the bar fills
## (scripts/loading_bike.gd). It keeps moving even while the game is paused.
##
## How to use it:
##   var screen := LoadingScreen.make()
##   get_tree().root.add_child(screen)
##   screen.set_progress(12, 40, "Laying the roads...")   # after each build step
##   await screen.finish()                                 # fills up, fades out, goes away

signal closed

const TIPS := preload("res://data/loading_tips.gd")
const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const SAND := Color(0.9529412, 0.8901961, 0.7647059, 1)
const INK := Color(0.105882354, 0.11372549, 0.13333334, 1)
const WHITE := Color(1, 1, 1, 1)
const TRACK := Color(0.05882353, 0.29803923, 0.36078432, 0.55)
## How quickly the shown bar catches up with the real progress (bigger = faster).
const BAR_CATCH_UP := 5.0
## Slowest the bar ever fills (whole bar per second), so it always gets there.
const BAR_MIN_SPEED := 0.3
## Slowest it fills once the world is done.
const BAR_FINISH_SPEED := 1.5
## Seconds a tip takes to fade out (and the next one to fade in).
const TIP_FADE := 0.25
const BAR_HEIGHT := 26.0

## How full the bar looks right now (0 to 1). It slides smoothly to the real progress.
var shown_fraction := 0.0
## The tip line above the bar, and the step name under it.
var tip_label: Label
var step_label: Label

var short := false
var _target := 0.0
var _root: Control
var _bar: Control
var _count_label: Label
var _bike: LoadingBike
var _camera: Camera3D
var _opened_ms := 0
var _last_ms := 0
var _tip := 0
var _tip_ms := 0
var _finishing := false


## Makes a new loading screen (add it to the tree yourself). short: the quick one at
## the start of a shift.
static func make(is_short := false) -> LoadingScreen:
	var screen := LoadingScreen.new()
	screen.short = is_short
	return screen


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # nothing behind can be clicked
	add_child(_root)
	var backing := ColorRect.new()  # solid, in case the desert hasn't drawn yet
	backing.color = SAND
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(backing)
	var desert := DesertBackdrop.build()
	_camera = desert["camera"]
	_root.add_child(desert["frame"])
	_bike = LoadingBike.new()
	_root.add_child(_bike)
	_root.add_child(_build_title())
	_root.add_child(_build_middle())
	_tip = randi() % TIPS.TIPS.size()
	tip_label.text = TIPS.TIPS[_tip]


func _ready() -> void:
	_opened_ms = Time.get_ticks_msec()
	_last_ms = _opened_ms
	_tip_ms = _opened_ms - int(TIP_FADE * 1000.0)  # the first tip is there straight away


## Tells the screen how far the build is: `done` steps out of `total`, and what the
## step is doing ("Laying the roads..."). The bar never goes backwards.
func set_progress(done: int, total: int, step_name: String) -> void:
	if total > 0:
		_target = maxf(_target, clampf(float(done) / float(total), 0.0, 1.0))
		_count_label.text = "step %d of %d" % [done, total]
	step_label.text = step_name


## The world is ready: fills the bar, waits until the screen has been up long enough,
## fades out, says `closed` and goes away. You can await it.
func finish() -> void:
	_finishing = true
	_target = 1.0
	var least := GameConfig.LOADING_SHIFT_SECONDS if short else GameConfig.LOADING_MIN_SECONDS
	while shown_fraction < 1.0 or _seconds_since(_opened_ms) < least:
		await get_tree().process_frame
	var fade_from := Time.get_ticks_msec()
	while _seconds_since(fade_from) < GameConfig.LOADING_FADE_SECONDS:
		_root.modulate.a = 1.0 - _seconds_since(fade_from) / GameConfig.LOADING_FADE_SECONDS
		await get_tree().process_frame
	_root.modulate.a = 0.0
	closed.emit()
	queue_free()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var step := minf((now - _last_ms) / 1000.0, 0.1)  # real seconds since last frame
	_last_ms = now
	var gap := _target - shown_fraction
	var least := (BAR_FINISH_SPEED if _finishing else BAR_MIN_SPEED) * step
	shown_fraction = minf(shown_fraction + maxf(gap * (1.0 - exp(-BAR_CATCH_UP * step)), least), _target)
	_bar.queue_redraw()
	_bike.ride(shown_fraction)
	_camera.position.x = sin(now / 1000.0 * 0.05) * 3.0  # the same slow drift as the start screen
	_update_tip(now)


## Every LOADING_TIP_SECONDS: fade the tip out, swap it for the next one, fade it in.
func _update_tip(now: int) -> void:
	var age := _seconds_since(_tip_ms)
	if age >= GameConfig.LOADING_TIP_SECONDS:
		_tip = (_tip + 1) % TIPS.TIPS.size()
		tip_label.text = TIPS.TIPS[_tip]
		_tip_ms = now
		age = 0.0
	var fade_in := clampf(age / TIP_FADE, 0.0, 1.0)
	var fade_out := clampf((GameConfig.LOADING_TIP_SECONDS - age) / TIP_FADE, 0.0, 1.0)
	tip_label.modulate.a = minf(fade_in, fade_out)


func _seconds_since(ms: int) -> float:
	return (Time.get_ticks_msec() - ms) / 1000.0


# --- Building the screen ---

## "AL SARAB · السراب" and the game's name, small at the top left.
func _build_title() -> Control:
	var column := VBoxContainer.new()
	column.position = Vector2(80, 50)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", -12)
	column.add_child(_label("AL SARAB  ·  السراب", 26, TEAL, "Heading"))
	var name_label := _label("Five Stars Habibi", 56, WHITE, "Heading")
	name_label.add_theme_color_override("font_outline_color", TEAL)
	name_label.add_theme_constant_override("outline_size", 12)
	column.add_child(name_label)
	return column


## The tip, the bar and the step name, in the middle above the bike's road.
func _build_middle() -> Control:
	var column := VBoxContainer.new()
	column.anchor_left = 0.2
	column.anchor_right = 0.8
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.offset_bottom = -LoadingBike.STRIP_HEIGHT - 30.0
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 12)
	tip_label = _label("", 28, INK)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.custom_minimum_size = Vector2(0, 84)
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	column.add_child(tip_label)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar.draw.connect(_draw_bar)
	column.add_child(_bar)
	var row := HBoxContainer.new()
	step_label = _label("Getting ready...", 26, TEAL, "Heading")
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(step_label)
	_count_label = _label("", 20, TEAL)
	row.add_child(_count_label)
	column.add_child(row)
	return column


## The rounded bar: a dark see-through track with the orange fill on top.
func _draw_bar() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = TRACK
	track.set_corner_radius_all(int(BAR_HEIGHT * 0.5))
	_bar.draw_style_box(track, Rect2(Vector2.ZERO, _bar.size))
	if shown_fraction <= 0.0:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = ORANGE
	fill.set_corner_radius_all(int(BAR_HEIGHT * 0.5))
	var inset := 4.0
	var width := maxf((_bar.size.x - inset * 2.0) * shown_fraction, BAR_HEIGHT - inset * 2.0)
	_bar.draw_style_box(fill, Rect2(Vector2(inset, inset), Vector2(width, BAR_HEIGHT - inset * 2.0)))


func _label(text: String, size: int, colour: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if variation != "":
		label.theme_type_variation = variation
	return label
