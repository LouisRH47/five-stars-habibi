extends SceneTree
## Smoke test: loads the main scene, pedals for a few seconds and checks the bike
## actually moves, sprints and stops. Then it does one full delivery (offer, accept,
## pick up, drop off, get paid), skips an order and lets one run out of time.
## Run it with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s tests/smoke_test.gd
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
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_bike = main.get_node("Bike")
	_delivery = main.get_node_or_null("DeliveryManager")
	# GameState is an autoload, so it sits on the root next to the main scene.
	_game_state = root.get_node_or_null("GameState")
	Input.action_press("move_forward")


func _physics_process(_delta: float) -> bool:
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
	if _game_state == null:
		_check("GameState autoload exists", false, "add scripts/game_state.gd as GameState in Project Settings > Globals")
		_finish()
		return
	if _delivery == null:
		_check("DeliveryManager node exists in main.tscn", false, "")
		_finish()
		return
	_game_state.reset()
	_game_state.connect("order_skipped", _on_order_skipped)
	_order = _delivery.offer_now()
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
