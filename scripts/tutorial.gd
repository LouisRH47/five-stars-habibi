extends CanvasLayer
## The first-order tutorial (PRD "Start of the game"). Right after you're hired, the boss
## sends an easy pizza order two streets away (TUTORIAL_ORDER in data/wahat_al_shams.gd).
## A message box at the bottom tells you what to do at each step, and at the end it
## points out that crash insurance is on. It runs once (GameState.tutorial_done).
## While it runs, no other orders pop up and the shift clock waits.

## Makes the tutorial order and knows when you're at the door.
@export var delivery_manager: DeliveryManager

const PANEL_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 0.92)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const TEXT := Color(1, 0.95, 0.87, 1)

## The tip on screen right now (the smoke test reads it).
var tip := ""

var _panel: PanelContainer
var _label: Label
var _ending := false
var _run_id := 0


func _ready() -> void:
	_build()
	GameState.order_delivered.connect(_on_delivered)
	GameState.order_skipped.connect(func(_order): if GameState.tutorial_running: _offer())
	GameState.shift_started.connect(_on_shift_started)
	if GameState.hired and not GameState.tutorial_done:
		start.call_deferred()


## Starts the tutorial: the boss's first order pops up on the phone.
func start() -> void:
	_run_id += 1
	GameState.tutorial_running = true
	_ending = false
	_panel.visible = true
	_offer()


func _on_shift_started() -> void:
	# A major crash cancels the first order, but the same scene remains loaded.
	# Give the rider another tutorial attempt after the clinic and shift summary.
	if GameState.hired and not GameState.tutorial_done:
		start()


func _process(_delta: float) -> void:
	if not GameState.tutorial_running or _ending:
		return
	var name := GameState.rider_name if GameState.rider_name != "" else GameConfig.DEFAULT_RIDER_NAME
	var near := delivery_manager != null and delivery_manager.is_near_target()
	var order := GameState.current_order
	match GameState.stage:
		GameState.Stage.OFFERED:
			_show("Boss: Welcome to %s, %s! Your first order is on your phone (top right). Press E to accept it." % [Companies.current()["name"], name])
		GameState.Stage.TO_RESTAURANT:
			if near:
				_show("You're there! Stop, press F to get off, walk to the door and hold E to pick up the pizza." if not delivery_manager.on_foot else "Hold E at the door to pick up the pizza. Then walk back to your bike and press F to ride.")
			else:
				_show("Ride to %s. Follow the orange pin on the mini-map (bottom left).\nW pedal, A / D steer, S brake, Space handbrake." % order.restaurant_name)
		GameState.Stage.TO_VILLA:
			if near:
				_show("Stop, press F to get off, walk to the door and hold E to hand over the pizza." if not delivery_manager.on_foot else "Hold E at the door to hand over the pizza.")
			else:
				_show("Take it to %s. Watch your meters (top left): be quick, and slow down for speed bumps! Hold Shift to sprint." % order.address)


func _offer() -> void:
	if delivery_manager == null or GameState.stage != GameState.Stage.NONE:
		return
	var first: Dictionary = delivery_manager.place_builder.data.get_script_constant_map().get(
			"TUTORIAL_ORDER", {"restaurant": "", "villa": 0})
	var order := delivery_manager.make_order(first["restaurant"], first["villa"])
	order.note = ""
	order.leave_at_door = false
	GameState.offer_order(order)


func _on_delivered(_order: Order) -> void:
	if not GameState.tutorial_running or _ending:
		return
	_ending = true
	var run_id := _run_id
	_show("Great first job! Your crash insurance is ON (%d Dh a job): if you crash hard, it pays the bills. Press I to switch it off or on." % GameConfig.INSURANCE_PER_DELIVERY)
	await get_tree().create_timer(GameConfig.TUTORIAL_LAST_TIPS_TIME).timeout
	if run_id != _run_id:
		return
	_show("That's it! More orders will pop up on your phone. Ride safe and have fun!")
	await get_tree().create_timer(GameConfig.TUTORIAL_LAST_TIPS_TIME).timeout
	if run_id != _run_id:
		return
	finish()


## Ends the tutorial: normal orders and the shift clock start.
func finish() -> void:
	_run_id += 1
	GameState.tutorial_running = false
	GameState.tutorial_done = true
	GameState.save_soon()
	_ending = false
	_panel.visible = false


func _show(text: String) -> void:
	tip = text
	_label.text = text


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -24
	_panel.custom_minimum_size = Vector2(720, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOUR
	style.border_color = ORANGE
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var rows := VBoxContainer.new()
	_panel.add_child(rows)
	var title := Label.new()
	title.text = "TIP"
	title.theme_type_variation = &"Heading"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", ORANGE)
	rows.add_child(title)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(684, 0)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", TEXT)
	rows.add_child(_label)
