class_name DeliveredCard
extends CanvasLayer
## The Delivered card (Session 22, PRD "Screens", like the mockup's "Delivery complete").
## After every delivery the game pauses (the shift clock too), the camera cuts to a 3D shot
## of you and the customer at the door (or the bag on the doorstep), and a white card on the
## right shows: "Delivered!", the stars, "Ice cream to Villa 14 · 1:58", three tiles (Time,
## Freshness, Damage) with a word and a colour each, then Delivery pay, 5-star tip (if you
## got one), Insurance, a bold "You earned" total and the XP. "Next order · E" carries on.
## The numbers come from GameState.last_result.
## Session 31: the stars pop in one by one (a blip each) and coins fly out of the total
## with a jingle. The tweens run while the game is paused, like the card itself.
## Session 71 (GameConfig.CARD_V2): the card slides in, the three tiles flip in one by one,
## the stars pop with rising dings, "You earned" counts up with ticks, a tip drops in like a
## coin, a perfect delivery gets a big PERFECT! stamp, and the XP bar fills ("Level up!").
## On the Mac the world behind goes soft (depth of field). E jumps to the end and carries on
## (GameConfig.CARD_E_SKIPS_FIRST: the first E only skips); a click on the card only skips.

## Sent when the card closes (the ShiftManager waits for this at the end of a shift).
signal closed

## Knows where the villas are (for the camera shot).
@export var delivery_manager: DeliveryManager
## The customer (or bag) at the door; it waits there until the card closes.
@export var customer_spawner: CustomerSpawner

const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const SAND := Color(0.9529412, 0.8901961, 0.7647059, 1)
const INK := Color(0.105882354, 0.11372549, 0.13333334, 1)
const SOFT := Color(0.36, 0.42, 0.44, 1)
const GREEN := Color(0.2, 0.6, 0.36, 1)
const RED := Color(0.8, 0.25, 0.2, 1)
## The word on each tile for green, orange and red.
const WORDS := {
	"time": ["On time", "A bit late", "Late"],
	"freshness": ["Fresh", "Okay", "Not fresh"],
	"damage": ["Perfect", "Shaken", "Smashed"],
}

## The other screen panels, hidden while the card is up so nothing covers it.
const HIDDEN_WHILE_UP := ["HUD", "Phone", "Minimap", "MetersPanel", "ShiftScreen", "Tutorial"]

## True while the card is up.
var showing := false
## What the card showed (for the smoke test): earned, stars, tip...
var shown: Dictionary = {}

var _camera: Camera3D
var _old_camera: Camera3D
var _card: PanelContainer
var _title: Label
var _stars: StarRow
var _what: Label
var _tiles: HBoxContainer
var _rows: GridContainer
var _earned: Label
var _xp: Label
## How many stars and coin bursts have popped (the smoke test checks it).
var pops := 0
var _pop_tween: Tween
var _extra: Label  # Session 32: the regular's name, and any shift goal this delivery finished
# Session 71: the reveal.
var _stamp: Label
var _xp_bar: ProgressBar
var _level_text: Label
var _level_up: Label
var _tip_value: Label
var _slide: Tween
## The order things happened in the last reveal (the screens test reads it).
var reveal_log: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # works while the game is paused
	layer = 12
	_build()
	_camera = Camera3D.new()
	_camera.fov = 50.0
	add_child(_camera)
	GameState.order_delivered.connect(_on_delivered)


func _unhandled_input(event: InputEvent) -> void:
	if showing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if revealing():
			skip()
			if GameConfig.CARD_E_SKIPS_FIRST:
				return
		close()


## True while the Session 71 reveal is still running.
func revealing() -> bool:
	return GameConfig.CARD_V2 and _pop_tween != null and _pop_tween.is_valid() and _pop_tween.is_running()


## Jumps the reveal to the end: every tile, star, number and stamp in its final place.
func skip() -> void:
	if _slide != null and _slide.is_valid():
		_slide.custom_step(99.0)
	if revealing():
		_pop_tween.custom_step(99.0)


## "Next order · E": the game carries on.
func close() -> void:
	if not showing:
		return
	showing = false
	_stop_pops()
	_card.visible = false
	if _camera.attributes != null:
		_camera.attributes = null  # Session 71: no blur left behind
	_show_hud(true)
	if _old_camera != null and is_instance_valid(_old_camera):
		_old_camera.make_current()
	if customer_spawner != null and customer_spawner.last_spawned != null and is_instance_valid(customer_spawner.last_spawned):
		customer_spawner.last_spawned.set("held", false)  # the customer goes back inside
	get_tree().paused = false
	closed.emit()


func _on_delivered(_order: Order) -> void:
	var job := GameState.last_result
	if job.is_empty():
		return
	var earned: int = job["pay"] + job["tip"] - job["insurance"] + job.get("collection_bonus", 0)
	shown = {"earned": earned, "stars": job["stars"], "tip": job["tip"], "food": job["food"], "villa": job["villa"]}
	_title.text = "PERFECT!" if job.get("perfect", false) else ("Left at the door!" if job["left_at_door"] else "Delivered!")
	_stars.stars = job["stars"]
	var ride := int(GameState.ride_time)
	_what.text = "%s to %s  ·  %d:%02d" % [str(job["food"]).capitalize(), job.get("address", "Villa %d" % job["villa"]), ride / 60, ride % 60]
	for child in _tiles.get_children():
		child.queue_free()
	for key in ["time", "freshness", "damage"]:
		_tiles.add_child(_tile(key, job[key]))
	for child in _rows.get_children():
		child.queue_free()
	_tip_value = null
	# Session 32: a special order shows its extra pay on its own row.
	var extra_pay: int = job["pay"] - job.get("base_pay", job["pay"])
	if job.get("special", "") != "" and extra_pay > 0:
		_row("Delivery pay", "+%d Dh" % job["base_pay"], INK)
		_row(GameConfig.SPECIAL_NAMES[job["special"]] + " extra", "+%d Dh" % extra_pay, GameConfig.SPECIAL_COLOURS[job["special"]])
	else:
		_row("Delivery pay", "+%d Dh" % job["pay"], INK)
	if job["tip"] > 0:
		_tip_value = _row("5-star tip", "+%d Dh" % job["tip"], GREEN)
	if job.get("collection_bonus", 0) > 0:
		_row("Stamp card bonus", "+%d Dh" % job["collection_bonus"], GREEN)
	if job.get("crashed", false) and job["stars"] >= 5.0:
		_row("Crashed on the way", "no tip", SOFT)
	if job["insurance"] > 0:
		_row("Insurance", "-%d Dh" % job["insurance"], SOFT)
	_earned.text = "%d Dh" % earned
	_xp.text = "+%d XP" % job["xp"]
	_fill_xp(job)
	_extra.text = _extra_text(job)
	_extra.visible = _extra.text != ""
	showing = true
	_card.visible = true
	_show_hud(false)
	_point_camera(job["villa"])
	if customer_spawner != null and customer_spawner.last_spawned != null:
		customer_spawner.last_spawned.set("held", true)  # stay at the door while the card is up
	get_tree().paused = true
	_start_pops(job["stars"])


## Session 31: the stars fill in one at a time with a little pop each, then coins fly out
## of the "You earned" total and it gives a small bounce.
func _start_pops(stars: float) -> void:
	if GameConfig.CARD_V2:
		_start_reveal(stars)
		return
	_stop_pops()
	_stars.stars = 0.0
	_pop_tween = create_tween()
	_pop_tween.tween_interval(GameConfig.POP_FIRST_DELAY)
	for i in ceili(stars):
		_pop_tween.tween_callback(_pop_star.bind(i, stars))
		_pop_tween.tween_interval(GameConfig.POP_STAR_GAP)
	if stars >= 5.0:
		_pop_tween.tween_callback(func(): _play("perfect", 1.0))
		_pop_tween.tween_interval(0.35)
	_pop_tween.tween_callback(_pop_coins)
	if GameState.last_result.get("tip", 0) > 0:
		_pop_tween.tween_interval(0.3)
		_pop_tween.tween_callback(func(): _play("tip", 1.0))
	_pop_tween.tween_property(_earned, "scale", Vector2.ONE * 1.2, 0.08)
	_pop_tween.tween_property(_earned, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Session 71: the whole reveal is one tween (all steps side by side, each with its own start
## time), so custom_step() can jump straight to the end. Times in GameConfig (CARD_...).
func _start_reveal(stars: float) -> void:
	_stop_pops()
	reveal_log.clear()
	var job := GameState.last_result
	var quick := 0.5 if Settings.reduce_motion else 1.0
	var perfect: bool = job.get("perfect", false)
	_stars.stars = 0.0
	# The card slides in from the right (the whole layer moves, so the layout stays put).
	_play_ui("whoosh")
	if not Settings.reduce_motion:
		offset = Vector2(160, 0)
		_slide = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_slide.tween_property(self, "offset", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_card.modulate.a = 0.0
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_pop_tween = t
	t.tween_property(_card, "modulate:a", 1.0, 0.15)
	# The title: a pop for "Delivered!"; a perfect one waits for its stamp.
	_title.self_modulate.a = 0.0 if perfect else 1.0
	_stamp.visible = false
	# The three tiles flip in (they grow from a thin line), CARD_TILE_GAP apart.
	var at := 0.2 * quick
	var tiles := _tiles.get_children().filter(func(c): return not c.is_queued_for_deletion())
	for i in tiles.size():
		var tile: Control = tiles[i]
		tile.scale = Vector2(0.0 if quick == 1.0 else 1.0, 1.0)
		tile.modulate.a = 0.0
		t.tween_callback(_flip_start.bind(tile, i)).set_delay(at)
		t.tween_property(tile, "scale:x", 1.0, 0.2 * quick).set_delay(at).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(tile, "modulate:a", 1.0, 0.12 * quick).set_delay(at)
		at += GameConfig.CARD_TILE_GAP * quick
	# The stars, each ding a little higher.
	at += 0.2 * quick
	for i in ceili(stars):
		t.tween_callback(_pop_star.bind(i, stars)).set_delay(at)
		at += GameConfig.POP_STAR_GAP * 1.2 * quick
	# PERFECT!: the stamp slams in and the card gives a little jolt.
	if stars >= 5.0:
		t.tween_callback(func(): _play("perfect", 1.0)).set_delay(at)
	if perfect:
		t.tween_callback(_stamp_start).set_delay(at)
		t.tween_property(_stamp, "scale", Vector2.ONE, GameConfig.CARD_STAMP_TIME * quick).set_delay(at) \
				.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		t.tween_property(_stamp, "modulate:a", 1.0, GameConfig.CARD_STAMP_TIME * 0.5 * quick).set_delay(at)
		at += GameConfig.CARD_STAMP_TIME * quick
		t.tween_callback(_stamp_land).set_delay(at)
		at += 0.15 * quick
	elif stars >= 5.0:
		at += 0.2 * quick
	# "You earned" counts up with soft ticks, then the coins fly out of it.
	var earned: int = shown.get("earned", 0)
	_earned.text = "0 Dh"
	t.tween_callback(func(): reveal_log.append("count")).set_delay(at)
	t.tween_method(_count_earned, 0.0, float(earned), GameConfig.CARD_COUNT_TIME * quick).set_delay(at) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	at += GameConfig.CARD_COUNT_TIME * quick
	t.tween_callback(_pop_coins).set_delay(at)
	t.tween_property(_earned, "scale", Vector2.ONE * 1.2, 0.08).set_delay(at)
	t.tween_property(_earned, "scale", Vector2.ONE, 0.18).set_delay(at + 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# The tip drops in like a coin.
	if _tip_value != null:
		_tip_value.modulate.a = 0.0
		at += 0.1
		t.tween_callback(_tip_drop_start).set_delay(at)
		t.tween_property(_tip_value, "scale", Vector2.ONE, 0.35).set_delay(at).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		t.tween_property(_tip_value, "modulate:a", 1.0, 0.1).set_delay(at)
	# The XP bar fills (to the top and round again on a new level).
	at += 0.15
	var from := float(_xp_bar.get_meta("from", 0.0))
	var to := float(_xp_bar.get_meta("to", 0.0))
	var levelled: bool = _xp_bar.get_meta("levelled", false)
	_xp_bar.value = from
	t.tween_property(_xp_bar, "value", 100.0 if levelled else to, 0.45 * quick).from(from).set_delay(at)
	at += 0.45 * quick
	if levelled:
		t.tween_callback(_level_up_now).set_delay(at)
		t.tween_property(_xp_bar, "value", to, 0.3 * quick).from(0.0).set_delay(at)
		at += 0.3 * quick
	t.tween_callback(func(): reveal_log.append("end")).set_delay(at)


func _flip_start(tile: Control, index: int) -> void:
	tile.pivot_offset = tile.size * 0.5
	reveal_log.append("tile%d" % index)
	_play_ui("ui_hover", 1.0 + index * 0.12)


func _count_earned(value: float) -> void:
	var shown_now := roundi(value)
	var before := _earned.text
	_earned.text = "%d Dh" % shown_now
	# A soft tick each time the number moves on (at most one every few Dh, so it's not a buzz).
	if before != _earned.text and (shown_now % maxi(1, int(shown.get("earned", 0)) / 8) == 0):
		_play_ui("tick", 1.0 + 0.3 * value / maxf(1.0, float(shown.get("earned", 1))))


func _stamp_start() -> void:
	reveal_log.append("stamp")
	_stamp.visible = true
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.scale = Vector2.ONE * (1.0 if Settings.reduce_motion else 2.6)
	_stamp.modulate.a = 0.0


func _stamp_land() -> void:
	_play_ui("stamp")
	UiJuice.shake(_card, 6.0, 0.22)


func _tip_drop_start() -> void:
	reveal_log.append("tip")
	_tip_value.pivot_offset = _tip_value.size * 0.5
	_tip_value.scale = Vector2.ONE * 1.8
	_play("tip", 1.0)


func _level_up_now() -> void:
	reveal_log.append("level_up")
	_level_up.visible = true
	_level_text.text = "Lv %d" % GameState.level()
	UiJuice.pop_in(_level_up)
	_play_ui("level_up")


## The XP bar's start and end (in % of the level), and whether you went up a level.
func _fill_xp(job: Dictionary) -> void:
	if _xp_bar == null:
		return
	var now := GameState.xp
	var before := maxi(now - int(job.get("xp", 0)), 0)
	var level_before := GameState.level_for(before)
	var progress_before := _level_progress(before)
	var progress_now := _level_progress(now)
	_xp_bar.set_meta("from", 100.0 * progress_before.x / maxf(progress_before.y, 1))
	_xp_bar.set_meta("to", 100.0 * progress_now.x / maxf(progress_now.y, 1))
	_xp_bar.set_meta("levelled", GameState.level_for(now) > level_before)
	_xp_bar.value = _xp_bar.get_meta("to")
	_level_text.text = "Lv %d" % level_before
	_level_up.visible = false


## Like GameState.level_progress(), for any XP total.
static func _level_progress(total_xp: int) -> Vector2i:
	var left := total_xp
	var need := GameConfig.LEVEL_XP_FIRST
	while left >= need:
		left -= need
		need += GameConfig.LEVEL_XP_STEP
	return Vector2i(left, need)


func _play_ui(key: String, pitch := 1.0) -> void:
	var ui := get_tree().root.get_node_or_null("UiSounds") if is_inside_tree() else null
	if ui != null:
		ui.play(key, pitch)


func _pop_star(index: int, stars: float) -> void:
	_stars.stars = minf(index + 1.0, stars)
	var star_size := _stars.star_size
	var spot := _stars.global_position + Vector2(index * (star_size + StarRow.GAP) + star_size * 0.5, _stars.size.y * 0.5)
	for side in [-1.0, 1.0]:
		PopIcon.spawn(self, "star", spot, Vector2(side * randf_range(14.0, 26.0), -randf_range(26.0, 40.0)), star_size * 0.55)
	if GameConfig.CARD_V2:
		var pitches: Array = GameConfig.CARD_STAR_PITCHES
		_play("pop", pitches[mini(index, pitches.size() - 1)])  # Session 71: a semitone higher each
		reveal_log.append("star%d" % index)
	else:
		_play("pop", 1.0 + index * 0.08)  # each star a little higher
	pops += 1


func _pop_coins() -> void:
	_earned.pivot_offset = _earned.size * 0.5
	var spot := _earned.global_position + _earned.size * 0.5
	for i in GameConfig.POP_COINS:
		var angle := lerpf(-PI * 0.85, -PI * 0.15, i / maxf(GameConfig.POP_COINS - 1.0, 1.0))
		var move := Vector2(cos(angle), sin(angle)) * randf_range(70.0, 110.0)
		PopIcon.spawn(self, "coin", spot, move, randf_range(20.0, 26.0))
	_play("coins", 1.0)
	pops += 1


func _stop_pops() -> void:
	if _pop_tween != null:
		_pop_tween.kill()
		_pop_tween = null
	if _slide != null:
		_slide.kill()
		_slide = null
	offset = Vector2.ZERO
	if _earned != null:
		_earned.scale = Vector2.ONE
	for icon in get_children():
		if icon.is_in_group("pop_icon"):
			icon.queue_free()


func _play(sound: String, pitch: float) -> void:
	var sounds := get_parent().get_node_or_null("Sounds")
	if sounds != null:
		sounds.play(sound, pitch)


## Session 32: "♥ Regular: Auntie Mariam" for a regular, and a line for each shift goal
## this delivery finished.
func _extra_text(job: Dictionary) -> String:
	var lines: Array[String] = []
	if job.get("streak", 0) > 0:
		lines.append("%d in a row · +%d%% tip chance" % [job["streak"], roundi(minf(job["streak"] * GameConfig.STREAK_TIP_STEP, GameConfig.STREAK_TIP_MAX) * 100.0)])
	if job.get("new_route_best", false):
		lines.append("New personal best for this route!")
	if job.get("regular", "") != "":
		lines.append("♥ Regular: %s" % job["regular"])
	for id in GameState.last_goals_done:
		lines.append("✓ Goal done: %s  (+%d Dh at the end of the shift)" % [ShiftGoals.ALL.get(id, id), GameConfig.GOAL_BONUS])
	return "\n".join(lines)


## A shot of the door from the side, so you and the customer show on the left of the screen.
func _point_camera(villa_number: int) -> void:
	if delivery_manager == null or delivery_manager.place_builder == null:
		return
	var facing := 0.0
	for villa in delivery_manager.place_builder.villas:
		if villa["number"] == villa_number:
			facing = villa["facing"]
	var front := Vector3(sin(deg_to_rad(facing)), 0.0, cos(deg_to_rad(facing)))
	var side := Vector3(front.z, 0.0, -front.x)
	var door := delivery_manager.place_builder.villa_door(villa_number)
	var subject := door - front * 1.0 + Vector3.UP * 1.1  # between you and the customer
	_old_camera = get_viewport().get_camera_3d()
	_camera.global_position = subject + front * 5.0 + side * 5.0 + Vector3.UP * 1.2
	_camera.look_at(subject + side * 2.2, Vector3.UP)
	_camera.make_current()
	_add_depth_of_field(subject)


func _show_hud(on: bool) -> void:
	for panel_name in HIDDEN_WHILE_UP:
		var panel := get_parent().get_node_or_null(panel_name) as CanvasLayer
		if panel != null:
			panel.visible = on


func _tile(key: String, value: float) -> Control:
	var band := 0 if value > GameConfig.METER_GREEN_ABOVE else (1 if value >= GameConfig.METER_RED_BELOW else 2)
	var colour: Color = [GREEN, ORANGE, RED][band]
	if GameConfig.CARD_V2:
		colour = UiPalette.band_colour(band)  # Session 71: follows the Colour help setting
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colour, 0.14)
	style.border_color = colour
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel", style)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 0)
	box.add_child(inside)
	inside.add_child(_label(key.capitalize(), 14, SOFT))
	inside.add_child(_label(WORDS[key][band], 20, colour, "Heading"))
	inside.add_child(_label("%d%%" % roundi(value), 15, INK, "BigNumber"))
	return box


func _row(name_text: String, value: String, colour: Color) -> Label:
	var left := _label(name_text, 18, INK)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_child(left)
	var right := _label(value, 18, colour, "BigNumber")
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rows.add_child(right)
	return right


func _build() -> void:
	_card = PanelContainer.new()
	_card.visible = false
	_card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card.offset_right = -110
	_card.custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_corner_radius_all(28)
	style.set_content_margin_all(34)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 8)
	_card.add_theme_stylebox_override("panel", style)
	add_child(_card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	_card.add_child(rows)
	_title = _label("Delivered!", 46, TEAL, "Heading")
	rows.add_child(_title)
	if GameConfig.CARD_V2:
		_build_stamp()
		_card.gui_input.connect(_on_card_input)
	_stars = StarRow.new()
	_stars.star_size = 44.0
	rows.add_child(_stars)
	_what = _label("", 20, SOFT)
	rows.add_child(_what)
	_tiles = HBoxContainer.new()
	_tiles.add_theme_constant_override("separation", 10)
	rows.add_child(_tiles)
	var line := ColorRect.new()
	line.color = SAND
	line.custom_minimum_size = Vector2(0, 2)
	rows.add_child(line)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override("v_separation", 4)
	rows.add_child(_rows)
	var total := HBoxContainer.new()
	var total_name := _label("You earned", 26, INK, "Heading")
	total_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total.add_child(total_name)
	_earned = _label("", 30, TEAL, "BigNumber")
	total.add_child(_earned)
	rows.add_child(total)
	_xp = _label("", 18, ORANGE, "Heading")
	if GameConfig.CARD_V2:
		rows.add_child(_build_xp_row())
	else:
		rows.add_child(_xp)
	_extra = _label("", 16, TEAL)
	_extra.visible = false
	rows.add_child(_extra)
	var next := Button.new()
	next.text = "Next order  ·  E"
	next.add_theme_font_size_override("font_size", 24)
	next.custom_minimum_size = Vector2(0, 60)
	next.pressed.connect(close)
	rows.add_child(next)


## Session 71: the PERFECT! stamp, a tilted orange rubber stamp over the title.
func _build_stamp() -> void:
	_stamp = _label("PERFECT!", 46, UiPalette.ORANGE, "Heading")
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UiPalette.ORANGE, 0.1)
	box.border_color = UiPalette.ORANGE
	box.set_border_width_all(5)
	box.set_corner_radius_all(14)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = -4
	box.content_margin_bottom = 0
	_stamp.add_theme_stylebox_override("normal", box)
	_stamp.rotation = deg_to_rad(-8.0)
	_stamp.position = Vector2(-8, -8)
	_stamp.visible = false
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_child(_stamp)


## Session 71: "+40 XP", the level bar, "Lv 3" and the hidden "Level up!".
func _build_xp_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_xp)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size = Vector2(0, 14)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := StyleBoxFlat.new()
	back.bg_color = UiPalette.SAND
	back.set_corner_radius_all(7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiPalette.ORANGE
	fill.set_corner_radius_all(7)
	_xp_bar.add_theme_stylebox_override("background", back)
	_xp_bar.add_theme_stylebox_override("fill", fill)
	row.add_child(_xp_bar)
	_level_text = _label("Lv 1", 18, TEAL, "Heading")
	row.add_child(_level_text)
	_level_up = _label("Level up!", 18, Color.WHITE, "Heading")
	var pill := StyleBoxFlat.new()
	pill.bg_color = UiPalette.ORANGE
	pill.set_corner_radius_all(12)
	pill.content_margin_left = 10
	pill.content_margin_right = 10
	_level_up.add_theme_stylebox_override("normal", pill)
	_level_up.visible = false
	row.add_child(_level_up)
	return row


## Session 71: a click on the card (not its button) skips the reveal to the end.
func _on_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and revealing():
		skip()


## Session 71: on the Mac, the houses behind the door shot go softly out of focus.
func _add_depth_of_field(subject: Vector3) -> void:
	if not (GameConfig.CARD_V2 and GameConfig.CARD_DOF) or OS.has_feature("web") or Settings.graphics < 1:
		return
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return  # the Compatibility renderer has no depth of field
	var blur := CameraAttributesPractical.new()
	blur.dof_blur_far_enabled = true
	blur.dof_blur_far_distance = _camera.global_position.distance_to(subject) + 3.0
	blur.dof_blur_far_transition = GameConfig.CARD_DOF_TRANSITION
	blur.dof_blur_amount = GameConfig.CARD_DOF_AMOUNT
	_camera.attributes = blur


func _label(text: String, size: int, colour: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if variation != "":
		label.theme_type_variation = variation
	return label
