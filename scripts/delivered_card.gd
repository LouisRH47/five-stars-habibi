class_name DeliveredCard
extends CanvasLayer
## The Delivered card (Session 22, PRD "Screens", like the mockup's "Delivery complete").
## After every delivery the game pauses (the shift clock too), the camera cuts to a 3D shot
## of you and the customer at the door (or the bag on the doorstep), and a white card on the
## right shows: "Delivered!", the stars, "Ice cream to Villa 14 · 1:58", three tiles (Time,
## Freshness, Damage) with a word and a colour each, then Delivery pay, 5-star tip (if you
## got one), Insurance, a bold "You earned" total and the XP. "Next order · E" carries on.
## The numbers come from GameState.last_result.

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
var _extra: Label  # Session 32: the regular's name, and any shift goal this delivery finished


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
		close()


## "Next order · E": the game carries on.
func close() -> void:
	if not showing:
		return
	showing = false
	_card.visible = false
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
	var earned: int = job["pay"] + job["tip"] - job["insurance"]
	shown = {"earned": earned, "stars": job["stars"], "tip": job["tip"], "food": job["food"], "villa": job["villa"]}
	_title.text = "Left at the door!" if job["left_at_door"] else "Delivered!"
	_stars.stars = job["stars"]
	var ride := int(GameState.ride_time)
	_what.text = "%s to %s  ·  %d:%02d" % [str(job["food"]).capitalize(), job.get("address", "Villa %d" % job["villa"]), ride / 60, ride % 60]
	for child in _tiles.get_children():
		child.queue_free()
	for key in ["time", "freshness", "damage"]:
		_tiles.add_child(_tile(key, job[key]))
	for child in _rows.get_children():
		child.queue_free()
	# Session 32: a special order shows its extra pay on its own row.
	var extra_pay: int = job["pay"] - job.get("base_pay", job["pay"])
	if job.get("special", "") != "" and extra_pay > 0:
		_row("Delivery pay", "+%d Dh" % job["base_pay"], INK)
		_row(GameConfig.SPECIAL_NAMES[job["special"]] + " extra", "+%d Dh" % extra_pay, GameConfig.SPECIAL_COLOURS[job["special"]])
	else:
		_row("Delivery pay", "+%d Dh" % job["pay"], INK)
	if job["tip"] > 0:
		_row("5-star tip", "+%d Dh" % job["tip"], GREEN)
	if job["insurance"] > 0:
		_row("Insurance", "-%d Dh" % job["insurance"], SOFT)
	_earned.text = "%d Dh" % earned
	_xp.text = "+%d XP" % job["xp"]
	_extra.text = _extra_text(job)
	_extra.visible = _extra.text != ""
	showing = true
	_card.visible = true
	_show_hud(false)
	_point_camera(job["villa"])
	if customer_spawner != null and customer_spawner.last_spawned != null:
		customer_spawner.last_spawned.set("held", true)  # stay at the door while the card is up
	get_tree().paused = true


## Session 32: "♥ Regular: Auntie Mariam" for a regular, and a line for each shift goal
## this delivery finished.
func _extra_text(job: Dictionary) -> String:
	var lines: Array[String] = []
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


func _show_hud(on: bool) -> void:
	for panel_name in HIDDEN_WHILE_UP:
		var panel := get_parent().get_node_or_null(panel_name) as CanvasLayer
		if panel != null:
			panel.visible = on


func _tile(key: String, value: float) -> Control:
	var band := 0 if value > GameConfig.METER_GREEN_ABOVE else (1 if value >= GameConfig.METER_RED_BELOW else 2)
	var colour: Color = [GREEN, ORANGE, RED][band]
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


func _row(name_text: String, value: String, colour: Color) -> void:
	var left := _label(name_text, 18, INK)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_child(left)
	var right := _label(value, 18, colour, "BigNumber")
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rows.add_child(right)


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


func _label(text: String, size: int, colour: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if variation != "":
		label.theme_type_variation = variation
	return label
