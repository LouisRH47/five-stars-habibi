extends CanvasLayer
## The loading screen (Session 53). An autoload called Loader. Instead of switching straight
## to the game (which froze the screen for a few seconds while 500 homes were built, so
## people clicked the button again and again), the start screen calls Loader.go_to_game().
## The loading screen shows at once in the game's style, loads the game scene in the
## background, builds the homes one row per frame (HousingRows.prebuilt) so the bar really
## moves, then opens the game and fades away.

signal finished

const GAME_SCENE := "res://scenes/wahat_al_shams.tscn"
const DATA := "res://data/wahat_al_shams.gd"

const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const SAND := Color(0.9529412, 0.8901961, 0.7647059, 1)
const INK := Color(0.105882354, 0.11372549, 0.13333334, 1)
const SOFT := Color(0.36, 0.42, 0.44, 1)

## True from the first click until the game is showing. Extra clicks are ignored.
var busy := false
## 0.0 to 1.0, what the bar shows.
var progress := 0.0
## How many times the game scene was opened (the loading test checks it's once per click).
var opened_count := 0

var _root: Control
var _bar_fill: Panel
var _percent: Label
var _step: Label
var _tip: Label
var _title: Label
var _tip_left := 0.0
var _tip_index := 0
var _shown_at := 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func _process(delta: float) -> void:
	if not _root.visible:
		return
	_tip_left -= delta
	if _tip_left <= 0.0:
		_next_tip()


## Opens the game behind a loading screen. first_shift: the wording for a brand-new rider.
## Returns false if a load is already going (a second click).
func go_to_game(first_shift := false) -> bool:
	if busy:
		return false
	busy = true
	_title.text = "Getting your first shift ready…" if first_shift else "Getting your shift ready…"
	_show()
	_run.call_deferred()
	return true


func _run() -> void:
	# Let the loading screen draw before any heavy work starts.
	await get_tree().process_frame
	await get_tree().process_frame
	# 1) Load the game scene in the background: 0 to 15%.
	_set_step("Loading the map…", 0.0)
	var packed: PackedScene = null
	if ResourceLoader.load_threaded_request(GAME_SCENE) == OK:
		while true:
			var info := []
			var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, info)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				packed = ResourceLoader.load_threaded_get(GAME_SCENE)
				break
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			if not info.is_empty():
				_set_progress(0.15 * float(info[0]))
			await get_tree().process_frame
	if packed == null:
		packed = load(GAME_SCENE)
	_set_progress(0.15)
	# 2) Build the homes, one row per frame: 15 to 85%.
	var homes := _joined_homes()
	if not homes.is_empty():
		var lists: Dictionary = load(DATA).get_script_constant_map()
		var rows := HousingRows.begin(homes, lists["VILLA_SIZE"])
		var total := maxi(rows.rows_left(), 1)
		while true:
			var done := total - rows.rows_left()
			_set_step("Building the homes… (row %d of %d)" % [done + 1, total], 0.15 + 0.7 * float(done) / total)
			await get_tree().process_frame
			if rows.build_next():
				break
		HousingRows.prebuilt = rows
	# 3) Open the game: 85 to 100%. This last part can't be split, so the bar sits here a moment.
	_set_step("Opening Wahat Al Shams…", 0.88)
	await get_tree().process_frame
	await get_tree().process_frame
	opened_count += 1
	get_tree().change_scene_to_packed(packed)
	# Wait for the game's first frames (its builders run on the first one).
	for i in 3:
		await get_tree().process_frame
	_set_step("Ready!", 1.0)
	var wait_ms := GameConfig.LOADING_MIN_SHOW_MS - (Time.get_ticks_msec() - _shown_at)
	if wait_ms > 0:
		await get_tree().create_timer(wait_ms / 1000.0, true, false, true).timeout
	await _fade_out()
	busy = false
	finished.emit()


func _joined_homes() -> Array:
	var lists: Dictionary = load(DATA).get_script_constant_map()
	var joined: Array = []
	for place: Dictionary in lists.get("VILLAS", []):
		if place.get("row_mode", false):
			joined.append(place)
	return joined


func _show() -> void:
	progress = 0.0
	_shown_at = Time.get_ticks_msec()
	_root.modulate.a = 1.0
	_root.visible = true
	_tip_index = randi() % GameConfig.LOADING_TIPS.size()
	_next_tip()
	_set_step("Starting…", 0.0)


func _fade_out() -> void:
	if DisplayServer.get_name() == "headless":
		_root.visible = false
		return
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, GameConfig.LOADING_FADE_TIME)
	await tween.finished
	_root.visible = false


func _set_step(text: String, value: float) -> void:
	_step.text = text
	_set_progress(value)


func _set_progress(value: float) -> void:
	progress = clampf(maxf(value, progress), 0.0, 1.0)  # the bar never goes backwards
	_bar_fill.anchor_right = progress
	_percent.text = "%d%%" % roundi(progress * 100.0)


func _next_tip() -> void:
	var tips: Array = GameConfig.LOADING_TIPS
	_tip_index = (_tip_index + 1) % tips.size()
	_tip.text = "Tip: " + tips[_tip_index]
	_tip_left = GameConfig.LOADING_TIP_TIME


# --- Building the screen ---

func _build() -> void:
	_root = Control.new()
	_root.name = "LoadingScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # clicks don't reach the buttons underneath
	add_child(_root)
	var background := ColorRect.new()
	background.color = SAND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(background)
	# A big pale sun behind the card, like the start screen's desert.
	var sun := Panel.new()
	var sun_style := StyleBoxFlat.new()
	sun_style.bg_color = Color(1, 0.93, 0.72, 1)
	sun_style.set_corner_radius_all(400)
	sun.add_theme_stylebox_override("panel", sun_style)
	sun.set_anchors_preset(Control.PRESET_CENTER)
	sun.offset_left = -400
	sun.offset_right = 400
	sun.offset_top = -470
	sun.offset_bottom = 330
	_root.add_child(sun)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -440
	column.offset_right = 440
	column.offset_top = -200
	column.offset_bottom = 200
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	_root.add_child(column)
	column.add_child(_label("Snackaroo", 64, ORANGE, "Heading"))
	_title = _label("Getting your shift ready…", 36, TEAL, "Heading")
	column.add_child(_title)
	# The bar: a rounded track with an orange fill.
	var track := Panel.new()
	track.custom_minimum_size = Vector2(760, 34)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(1, 1, 1, 0.85)
	track_style.border_color = TEAL
	track_style.set_border_width_all(3)
	track_style.set_corner_radius_all(17)
	track.add_theme_stylebox_override("panel", track_style)
	column.add_child(track)
	_bar_fill = Panel.new()
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = ORANGE
	fill_style.set_corner_radius_all(14)
	_bar_fill.add_theme_stylebox_override("panel", fill_style)
	_bar_fill.anchor_left = 0.0
	_bar_fill.anchor_top = 0.0
	_bar_fill.anchor_bottom = 1.0
	_bar_fill.anchor_right = 0.0
	_bar_fill.offset_left = 4
	_bar_fill.offset_top = 4
	_bar_fill.offset_bottom = -4
	_bar_fill.offset_right = -4
	track.add_child(_bar_fill)
	var under := HBoxContainer.new()
	column.add_child(under)
	_step = _label("Starting…", 22, SOFT)
	_step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	under.add_child(_step)
	_percent = _label("0%", 26, TEAL, "Heading")
	under.add_child(_percent)
	_tip = _label("", 24, INK)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(760, 70)
	column.add_child(_tip)


func _label(text: String, size: int, colour: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if variation != "":
		label.theme_type_variation = variation
	return label
