extends CanvasLayer
## After a big crash (Session 23, like the mockup's "Big crash: clinic bills"): the screen
## waits for the visible fall, then fades to black and you wake up at the clinic.
## Behind everything a simple 3D clinic room
## (pale teal walls, your rider lying in a bed, a drip stand), filmed from the side.
## Left: a red BIG CRASH label, "You woke up at Wahat Al Shams Clinic", one sentence with
## what you hit and how fast, and a teal Arabic sign. Right: the white "Your bills" card
## (ORDER CANCELLED tag, clinic bill, bike repair, insurance, a red "You pay" total, a
## yellow tip when insurance was off, the "Big crashes this week" bar, and the buttons
## "Turn on insurance" (only when it's off) and "Shift summary"). The first big crash
## shows the boss-covered version. The game is paused while this shows. The money is done
## by GameState.big_crash(); this only shows it. Closing it ends the shift (ShiftManager).

## Sent when you close the clinic screen (the ShiftManager then ends the shift).
signal closed

## The bike: we listen for its big crashes and put it back at the start afterwards.
@export var bike: Node3D

const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const SAND := Color(0.9529412, 0.8901961, 0.7647059, 1)
const INK := Color(0.105882354, 0.11372549, 0.13333334, 1)
const SOFT := Color(0.36, 0.42, 0.44, 1)
const RED := Color(0.8, 0.22, 0.18, 1)
const WALL := Color(0.72, 0.87, 0.86, 1)

## True while the clinic screen is up.
var showing := false
## The last bills shown (for the smoke test).
var last_bills: Dictionary = {}

var _fade: ColorRect
var _room: Control
var _left: VBoxContainer
var _card: PanelContainer
var _story: Label
var _tag: Label
var _rows: GridContainer
var _total: Label
var _tip_box: PanelContainer
var _week_bar: ProgressBar
var _week_text: Label
var _insure_button: Button
var _transition: Tween
var _patient: Person
var _room_view: SubViewport


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # works while the game is paused
	layer = 20
	_room = _build_room()
	add_child(_room)
	_left = _build_left()
	add_child(_left)
	_card = _build_card()
	add_child(_card)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_set_visible(false)
	if bike != null:
		if bike.has_signal("fall_completed"):
			bike.fall_completed.connect(_on_fall_completed)
		else:
			bike.crashed.connect(_on_crashed)


func _unhandled_input(event: InputEvent) -> void:
	if showing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close()


## Shows the clinic with these bills (fades out first, unless instantly is true).
func open(bills: Dictionary, instantly := false) -> void:
	if _patient != null:
		RiderLook.apply(_patient, GameState.rider_look)
		_patient.play("lie")
	last_bills = bills
	showing = true
	get_tree().paused = true
	_fill(bills)
	if instantly:
		_set_visible(true)
		return
	if _transition != null:
		_transition.kill()
	_transition = create_tween()
	_transition.tween_property(_fade, "color:a", 1.0, GameConfig.CRASH_FADE_TIME)
	_transition.tween_callback(func(): _set_visible(true))
	_transition.tween_property(_fade, "color:a", 0.0, GameConfig.CRASH_FADE_TIME * 0.6)


## "Shift summary": back to the game world (the ShiftManager then shows the summary).
func close() -> void:
	if not showing:
		return
	showing = false
	if _transition != null:
		_transition.kill()
	_fade.color.a = 0.0
	_set_visible(false)
	if bike != null:
		bike.reset_to_start()
	get_tree().paused = false
	closed.emit()


## "Turn on insurance": switches it on and hides the button and the tip.
func turn_on_insurance() -> void:
	GameState.set_insurance(true)
	_insure_button.visible = false
	_tip_box.visible = false


func _on_crashed(big: bool) -> void:
	if big and not showing:
		open(GameState.big_crash(bike.last_crash if bike != null else {}))


## One clinic visit is resolved only after the rider and bike have completed their fall.
func _on_fall_completed(big: bool, impact: Dictionary) -> void:
	if big and not showing:
		open(GameState.big_crash(impact))


func _set_visible(on: bool) -> void:
	_room.visible = on
	if _room_view != null:
		_room_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	_left.visible = on
	_card.visible = on


func _fill(bills: Dictionary) -> void:
	var hit: Dictionary = bills.get("impact", {})
	if hit.is_empty():
		hit = bike.last_crash if bike != null else {"what": "a wall", "kmh": 25.0}
	var food: String = bills.get("food", "")
	var story := "You hit %s at %d km/h." % [hit["what"], roundi(hit["kmh"])]
	if food != "":
		story += " The %s didn't make it, and your shift is over for today." % food
	else:
		story += " Your shift is over for today."
	_story.text = story
	_tag.visible = bills["lost_order"]
	for child in _rows.get_children():
		child.queue_free()
	var full: int = bills["hospital"] + bills["repair"]
	_row("Impact severity", str(bills.get("severity", hit.get("severity", "severe"))).capitalize(), INK)
	_row("Clinic bill", "%d Dh" % bills["hospital"], INK)
	_row("Bike repair (Snackaroo)", "%d Dh" % bills["repair"], INK)
	if bills["boss"]:
		_row("Your boss covered it", "-%d Dh" % full, TEAL)
	elif bills["insured"]:
		_row("Insurance", "-%d Dh" % (full - bills["paid"]), TEAL)
		_row("Your insured cap", "%d Dh" % bills.get("insured_cap", bills["paid"]), TEAL)
	else:
		_row("Insurance", "off", RED)
	_total.text = "%d Dh" % bills["paid"]
	_tip_box.visible = not bills["insured"] and not bills["boss"]
	_insure_button.visible = not GameState.insurance_on
	var week := GameState.crashes_this_week()
	_week_bar.max_value = GameConfig.CRASH_WEEK_WARNING
	_week_bar.value = mini(week, GameConfig.CRASH_WEEK_WARNING)
	_week_text.text = "%d of %d" % [week, GameConfig.CRASH_WEEK_WARNING]


func _row(name_text: String, value: String, colour: Color) -> void:
	var left := _label(name_text, 19, INK)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_child(left)
	var right := _label(value, 19, colour, "BigNumber")
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rows.add_child(right)


# --- The 3D clinic room behind everything ---

func _build_room() -> Control:
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	_room_view = view
	view.own_world_3d = true
	frame.add_child(view)
	var room := Node3D.new()
	view.add_child(room)
	var light := WorldEnvironment.new()
	light.environment = Environment.new()
	light.environment.background_mode = Environment.BG_COLOR
	light.environment.background_color = WALL
	light.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	light.environment.ambient_light_color = Color(0.85, 0.9, 0.9)
	light.environment.ambient_light_energy = 0.8
	room.add_child(light)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-50, 30, 0)
	lamp.shadow_enabled = true
	room.add_child(lamp)
	LowPoly.box(room, Vector3(14, 0.2, 8), Color(0.88, 0.9, 0.88), Vector3(0, -0.1, 0))        # floor
	LowPoly.box(room, Vector3(14, 5, 0.2), WALL, Vector3(0, 2.5, -2.5))                        # back wall
	LowPoly.box(room, Vector3(14, 0.15, 0.25), Color(0.4, 0.7, 0.7), Vector3(0, 1.0, -2.35))   # wall stripe
	LowPoly.box(room, Vector3(1.6, 1.0, 0.1), Color(0.95, 0.97, 0.98), Vector3(-2.6, 2.6, -2.38))  # window
	# The bed, with you lying in it.
	LowPoly.box(room, Vector3(2.2, 0.45, 1.1), Color(0.9, 0.92, 0.94), Vector3(0.6, 0.55, -0.6))
	LowPoly.box(room, Vector3(0.12, 0.9, 1.1), Color(0.6, 0.7, 0.72), Vector3(-0.5, 0.75, -0.6))
	LowPoly.box(room, Vector3(0.12, 0.7, 1.1), Color(0.6, 0.7, 0.72), Vector3(1.7, 0.65, -0.6))
	for x in [-0.4, 1.6]:
		for z in [-1.1, -0.1]:
			LowPoly.cylinder(room, 0.04, 0.04, 0.35, Color(0.5, 0.55, 0.58), Vector3(x, 0.17, z))
	var patient := Walker.build_model()
	_patient = patient
	patient.name = "Patient"
	room.add_child(patient)
	RiderLook.apply(patient, GameState.rider_look)
	(patient as Person).play("lie")
	# Lying on their back, head on the pillow (-X), face up (Session 29: a real person now).
	patient.basis = Basis(Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, -1, 0))
	patient.position = Vector3(1.4, 0.85, -0.6)
	LowPoly.box(room, Vector3(1.4, 0.12, 1.05), Color(0.55, 0.78, 0.82), Vector3(0.95, 0.85, -0.6))  # blanket
	LowPoly.box(room, Vector3(0.35, 0.12, 0.6), Color(0.97, 0.98, 0.98), Vector3(-0.3, 0.84, -0.6))  # pillow
	# The drip stand.
	LowPoly.cylinder(room, 0.03, 0.03, 1.9, Color(0.7, 0.72, 0.75), Vector3(-1.1, 0.95, -1.4))
	LowPoly.cylinder(room, 0.25, 0.25, 0.04, Color(0.6, 0.62, 0.65), Vector3(-1.1, 0.02, -1.4))
	LowPoly.box(room, Vector3(0.18, 0.28, 0.06), Color(0.85, 0.95, 1.0), Vector3(-1.1, 1.75, -1.4))
	var camera := Camera3D.new()
	camera.fov = 45.0
	room.add_child(camera)
	camera.look_at_from_position(Vector3(0.9, 2.4, 5.2), Vector3(0.0, 0.7, -0.6))
	return frame


# --- Left: what happened ---

func _build_left() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.offset_left = 110
	column.offset_right = 860
	column.add_theme_constant_override("separation", 14)
	var label := _label("BIG CRASH", 18, Color(1, 1, 1, 1), "Heading")
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var pill := StyleBoxFlat.new()
	pill.bg_color = RED
	pill.set_corner_radius_all(12)
	pill.content_margin_left = 14
	pill.content_margin_right = 14
	label.add_theme_stylebox_override("normal", pill)
	column.add_child(label)
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", -40)
	for line_text in ["You woke up at", "Wahat Al Shams Clinic"]:
		title.add_child(_label(line_text, 60, TEAL, "Heading"))
	column.add_child(title)
	_story = _label("", 24, INK)
	_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story.custom_minimum_size = Vector2(640, 0)
	column.add_child(_story)
	var sign := _label("عيادة واحة الشمس", 30, Color(1, 1, 1, 1))
	sign.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var board := StyleBoxFlat.new()
	board.bg_color = Color(0.16470589, 0.5568628, 0.6117647, 1)
	board.set_corner_radius_all(10)
	board.content_margin_left = 18
	board.content_margin_right = 18
	board.content_margin_top = 4
	board.content_margin_bottom = 8
	sign.add_theme_stylebox_override("normal", board)
	column.add_child(sign)
	return column


# --- Right: the bills ---

func _build_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_right = -110
	card.custom_minimum_size = Vector2(540, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_corner_radius_all(28)
	style.set_content_margin_all(34)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", style)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	card.add_child(rows)
	rows.add_child(_label("Your bills", 40, TEAL, "Heading"))
	_tag = _label("ORDER CANCELLED  ·  0 STARS", 14, RED, "Heading")
	_tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = Color(RED, 0.12)
	tag_style.set_corner_radius_all(10)
	tag_style.content_margin_left = 12
	tag_style.content_margin_right = 12
	_tag.add_theme_stylebox_override("normal", tag_style)
	rows.add_child(_tag)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override("v_separation", 6)
	rows.add_child(_rows)
	var line := ColorRect.new()
	line.color = SAND
	line.custom_minimum_size = Vector2(0, 2)
	rows.add_child(line)
	var total := HBoxContainer.new()
	var total_name := _label("You pay", 28, INK, "Heading")
	total_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total.add_child(total_name)
	_total = _label("", 34, RED, "BigNumber")
	total.add_child(_total)
	rows.add_child(total)
	_tip_box = PanelContainer.new()
	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color = Color(0.9882353, 0.9372549, 0.78431374, 1)
	tip_style.set_corner_radius_all(14)
	tip_style.set_content_margin_all(12)
	_tip_box.add_theme_stylebox_override("panel", tip_style)
	var tip := _label("Insurance (2 Dh a delivery) reduces the bill. Your capped share depends on how hard you hit.", 16, Color(0.4, 0.3, 0.05, 1))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_box.add_child(tip)
	rows.add_child(_tip_box)
	var week_row := HBoxContainer.new()
	var week_name := _label("Big crashes this week", 16, SOFT)
	week_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	week_row.add_child(week_name)
	_week_text = _label("", 16, INK, "BigNumber")
	week_row.add_child(_week_text)
	rows.add_child(week_row)
	_week_bar = ProgressBar.new()
	_week_bar.show_percentage = false
	_week_bar.custom_minimum_size = Vector2(0, 10)
	var back := StyleBoxFlat.new()
	back.bg_color = SAND
	back.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = RED
	fill.set_corner_radius_all(5)
	_week_bar.add_theme_stylebox_override("background", back)
	_week_bar.add_theme_stylebox_override("fill", fill)
	rows.add_child(_week_bar)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	_insure_button = Button.new()
	_insure_button.text = "Turn on insurance"
	_insure_button.add_theme_font_size_override("font_size", 20)
	_insure_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insure_button.custom_minimum_size = Vector2(0, 56)
	_insure_button.pressed.connect(turn_on_insurance)
	buttons.add_child(_insure_button)
	var summary := Button.new()
	summary.text = "Shift summary  ·  E"
	summary.add_theme_font_size_override("font_size", 20)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.custom_minimum_size = Vector2(0, 56)
	summary.pressed.connect(close)
	buttons.add_child(summary)
	rows.add_child(buttons)
	return card


func _label(text: String, size: int, colour: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if variation != "":
		label.theme_type_variation = variation
	return label
