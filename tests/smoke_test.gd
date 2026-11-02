extends SceneTree
## Smoke test: loads the main scene (Palm Grove), pedals for a few seconds and checks
## the bike actually moves, sprints and stops. It checks the sign font and that the
## restaurants and street signs have Arabic + English text. Then it does one full delivery
## (offer, accept, pick up, drop off, get paid), skips an order and lets one run out of time.
## Run it with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s tests/smoke_test.gd
## To test another scene, add its path after "--", for example the old test area:
##   ... -s tests/smoke_test.gd -- res://scenes/test_area.tscn
## It prints PASS or FAIL lines and exits with code 1 on any failure.

const STEPS := {
	"pedal": 180,      # 3 seconds at 60 physics frames per second
	"sprint": 180,
	"brake": 240,
	"settle": 3,       # frames to wait after moving the bike to a door
	"timeout": 30,     # half a second, longer than TEST_OFFER_TIMEOUT
}
## A short offer timer for the test, so it doesn't have to wait 30 seconds.
const TEST_OFFER_TIMEOUT := 0.2
## Every action the test might press. All of them are let go at the end.
const ACTIONS := ["move_forward", "move_back", "sprint", "handbrake", "interact", "skip_order"]
const FONT_PATH := "res://assets/fonts/NotoSansArabic.ttf"

var _main: Node
var _bike: CharacterBody3D
var _game_state: Node
var _delivery: Node
var _order: Object
var _money_before := 0
var _skipped := 0
var _frame := 0
var _phase := "pedal"
var _failed := false
var _top_speed := 0.0


func _initialize() -> void:
	var scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		scene_path = user_args[0]
	print("      scene: ", scene_path)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		print("FAIL: could not load ", scene_path)
		print("RESULT: FAIL")
		_phase = "done"
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)
	_bike = _main.get_node("Bike")
	_delivery = _main.get_node_or_null("DeliveryManager")
	# GameState is an autoload, so it sits on the root next to the main scene.
	_game_state = root.get_node_or_null("GameState")
	Input.action_press("move_forward")


func _physics_process(_delta: float) -> bool:
	if _phase == "done":
		return false
	_frame += 1
	_top_speed = maxf(_top_speed, _bike.speed)
	match _phase:
		"pedal":
			if _frame >= STEPS.pedal:
				_check("bike moves when pedalling", _bike.speed > 3.0, "speed %.1f m/s" % _bike.speed)
				_check("bike stays on the ground", _bike.is_on_floor(), "")
				Input.action_press("sprint")
				_frame = 0
				_phase = "sprint"
		"sprint":
			if _frame >= STEPS.sprint:
				var sprint_kmh := _top_speed * 3.6
				_check("sprint goes faster than normal top speed", sprint_kmh > GameConfig.BIKE_MAX_SPEED_KMH + 2.0, "%.1f km/h" % sprint_kmh)
				_check("sprinting drains stamina", _bike.stamina < GameConfig.STAMINA_MAX, "stamina %.0f" % _bike.stamina)
				Input.action_release("sprint")
				Input.action_release("move_forward")
				Input.action_press("move_back")
				_frame = 0
				_phase = "brake"
		"brake":
			if _frame >= STEPS.brake:
				_check("brake stops the bike", _bike.speed <= 0.1, "speed %.1f m/s" % _bike.speed)
				_check("stamina refills", _bike.stamina > 30.0, "stamina %.0f" % _bike.stamina)
				Input.action_release("move_back")
				_start_delivery_check()
		"at_restaurant":
			if _frame >= STEPS.settle:
				_check("bike is near the restaurant door", _delivery.is_near_target(), "")
				_check("E at the restaurant picks up the food", _delivery.try_interact(), "")
				_check_stage("TO_VILLA")
				_move_bike_to(_delivery.target_door())
				_frame = 0
				_phase = "at_villa"
		"at_villa":
			if _frame >= STEPS.settle:
				_check("bike is near the villa door", _delivery.is_near_target(), "")
				_check("E at the villa delivers", _delivery.try_interact(), "")
				_check("money goes up by the order's pay", _game_state.money == _money_before + _order.pay, "Dh %d" % _game_state.money)
				_check("delivery is saved in the history", _game_state.history.size() == 1, "%d in history" % _game_state.history.size())
				_check_stage("NONE")
				_start_skip_check()
		"timeout":
			if _frame >= STEPS.timeout:
				_check("an ignored order counts as skipped", _skipped == 2, "%d skipped" % _skipped)
				_check_stage("NONE")
				_delivery.offer_timeout = GameConfig.ORDER_OFFER_TIMEOUT
				_finish()
	return false


## Fresh start, a new order pops up, accept it, then jump to the restaurant door.
func _start_delivery_check() -> void:
	_check_signs()
	if _game_state == null:
		_check("GameState autoload exists", false, "add scripts/game_state.gd as GameState in Project Settings > Globals")
		_finish()
		return
	if _delivery == null:
		_check("DeliveryManager node exists in the scene", false, "")
		_finish()
		return
	_game_state.reset()
	_game_state.connect("order_skipped", _on_order_skipped)
	_order = _delivery.offer_now()
	var places: Node = _delivery.place_builder
	var built := 0
	if places != null:
		for child in places.get_children():
			if child.name.begins_with("Villa"):
				built += 1
	var listed: int = 0 if places == null else places.villas.size()
	_check("every villa in the data list was built", listed > 0 and built == listed, "%d of %d" % [built, listed])
	_check("an order pops up", _order != null, "")
	if _order == null:
		_finish()
		return
	print("      order: ", _order.describe())
	_check_stage("OFFERED")
	_check("pay is between 8 and 15 Dh", _order.pay >= GameConfig.ORDER_PAY_MIN and _order.pay <= GameConfig.ORDER_PAY_MAX, "%d Dh" % _order.pay)
	_check("the order has a countdown", _delivery.time_left_on_offer() > 0.0, "%.0f s" % _delivery.time_left_on_offer())
	_check("pausing stops the delivery keys", _pause_blocks_delivery(), "")
	_check("E accepts the order", _delivery.accept(), "")
	_check_stage("TO_RESTAURANT")
	_money_before = _game_state.money
	_move_bike_to(_delivery.target_door())
	_frame = 0
	_phase = "at_restaurant"


## The sign font has Arabic and Latin letters, every restaurant has an Arabic and an
## English sign, and (on Palm Grove) every road end has a street sign, plus the welcome sign.
func _check_signs() -> void:
	var font := load(FONT_PATH) as Font
	_check("sign font loads", font != null, FONT_PATH)
	if font != null:
		_check("sign font has Arabic and Latin letters", font.has_char(0x0628) and font.has_char(0x41), "")
	var places := _main.get_node_or_null("PlaceBuilder")
	if places == null:
		_check("PlaceBuilder node exists in the scene", false, "")
		return
	for place in places.restaurants:
		var node_name: String = "Restaurant_" + place["id"]
		var restaurant := places.get_node_or_null(node_name)
		_check(node_name + " was built", restaurant != null, "")
		if restaurant != null:
			_check(node_name + " has an Arabic sign", _has_arabic_label(restaurant), "")
			_check(node_name + " has an English sign", _has_label_text(restaurant, place["name"]), place["name"])
	var signs := _main.get_node_or_null("SignBuilder")
	if signs == null:
		print("      no SignBuilder in this scene, street signs not checked")
		return
	var good := 0
	for i in signs.roads.size():
		for end in 2:
			var street_sign := signs.get_node_or_null("StreetSign_%d_%d" % [i, end])
			if street_sign != null and _has_arabic_label(street_sign):
				good += 1
	var wanted: int = signs.roads.size() * 2
	_check("every road end has a street sign with Arabic", wanted > 0 and good == wanted, "%d of %d" % [good, wanted])
	var welcome := signs.get_node_or_null("WelcomeSign")
	_check("the welcome sign has Arabic", welcome != null and _has_arabic_label(welcome), "")


func _labels_under(node: Node) -> Array[Node]:
	return node.find_children("*", "Label3D", true, false)


func _has_arabic_label(node: Node) -> bool:
	for label in _labels_under(node):
		for i in label.text.length():
			var code: int = label.text.unicode_at(i)
			if code >= 0x0600 and code <= 0x06FF:
				return true
	return false


func _has_label_text(node: Node, text: String) -> bool:
	for label in _labels_under(node):
		if label.text == text:
			return true
	return false


## Skip one order with Q, then let one run out of time.
func _start_skip_check() -> void:
	_check("a second order pops up", _delivery.offer_now() != null, "")
	_check("Q skips the order", _delivery.skip(), "")
	_check_stage("NONE")
	_check("skipping sends order_skipped", _skipped == 1, "%d skipped" % _skipped)
	var rate: float = _game_state.acceptance_rate()
	_check("skipping lowers the acceptance rate", rate < 1.0, "%.0f%%" % (rate * 100.0))
	# Shorten the timer on the DeliveryManager (not in GameConfig) for this test only.
	_delivery.offer_timeout = TEST_OFFER_TIMEOUT
	var boring: Object = _delivery.offer_now()
	_check("a third order pops up", boring != null, "")
	if boring != null:
		_check("low acceptance rate gives a boring order", boring.pay == GameConfig.ORDER_PAY_MIN, "%d Dh" % boring.pay)
	_frame = 0
	_phase = "timeout"


## While the game is paused, the DeliveryManager gets no keys and no timer ticks.
func _pause_blocks_delivery() -> bool:
	paused = true
	var blocked: bool = not _delivery.can_process()
	paused = false
	return blocked


func _move_bike_to(spot: Vector3) -> void:
	_bike.global_position = spot + Vector3.UP * 0.05
	_bike.velocity = Vector3.ZERO
	_bike.speed = 0.0


func _on_order_skipped(_skipped_order: Object) -> void:
	_skipped += 1


func _check_stage(expected: String) -> void:
	var actual: String = _game_state.stage_name()
	_check("order stage is " + expected, actual == expected, "stage " + actual)


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		print("PASS: ", label, "  ", detail)
	else:
		_failed = true
		print("FAIL: ", label, "  ", detail)


func _finish() -> void:
	for action in ACTIONS:
		Input.action_release(action)
	_phase = "done"
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)
