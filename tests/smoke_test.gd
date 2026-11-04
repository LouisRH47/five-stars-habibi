extends SceneTree
## Smoke test: loads Wahat Al Shams (or the scene after "--"), pedals for a few seconds and checks
## the bike actually moves, sprints and stops. It checks the sign font and that the
## restaurants have Arabic + English text. Then it does one full delivery
## (offer, accept, pick up, drop off, get paid), skips an order and lets one run out of time.
## It then checks the decorations (mosque, mini market, palms, parked cars,
## speed bumps) were built and rides over the first speed bump.
## It also checks the mini-map (Session 7): it turns with the bike, and its pin shows the
## restaurant, then the villa number, and stays on the map when the stop is far away.
## And that some orders (not all) come with a customer note.
## Run it with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s tests/smoke_test.gd
## To test another scene, add its path after "--", for example the old test area:
##   ... -s tests/smoke_test.gd -- res://scenes/test_area.tscn
## Pass --save-dir=<directory> after "--" to keep the test save outside user://.
## It prints PASS or FAIL lines and exits with code 1 on any failure.

const STEPS := {
	"pedal": 180,      # 3 seconds at 60 physics frames per second
	"sprint": 180,
	"brake": 240,
	"settle": 3,       # frames to wait after moving the bike to a door
	"tap": 12,         # a quick tap of E (0.2 s): must do nothing at the door
	"walk": 360,       # up to 6 seconds to walk to the door (or back to the bike)
	"hold": 100,       # holding E for 1.67 s: longer than the 1.5 s pick-up / drop-off hold
	"timeout": 30,     # half a second, longer than TEST_OFFER_TIMEOUT
	"bump_ride": 300,  # 5 seconds of pedalling from a standstill, over a speed bump
	"critters": 120,   # 2 seconds for a kid on a scooter to ride into the bike
	"crash_small": 30, # half a second to coast into a wall
	"fallen": 150,     # long enough to get back on the bike
	"crash_big": 240,   # one second to ride fast into a wall
	"shift": 90,       # 1.5 seconds, longer than the test's 1-second shift
}
## How far before the speed bump the bike starts its ride, in metres.
const BUMP_RUN_UP := 6.0
## A short offer timer for the test, so it doesn't have to wait 30 seconds.
const TEST_OFFER_TIMEOUT := 0.2
## Every action the test might press. All of them are let go at the end.
const ACTIONS := ["move_forward", "move_back", "sprint", "handbrake", "interact", "skip_order", "toggle_bike"]
const FONT_PATH := "res://assets/fonts/NotoSansArabic.ttf"
const GRID := preload("res://tests/grid_path.gd")
## The test saves here, never over the real save (user://save.json).
var _test_save: String

var _main: Node
var _bike: CharacterBody3D
var _game_state: Node
var _delivery: Node
var _minimap: Node
var _meters: Node
var _order: Object
var _money_before := 0
var _skipped := 0
var _frame := 0
var _phase := "pedal"
var _failed := false
var _top_speed := 0.0
var _bumps_before := 0
var _bump_spot := Vector3.ZERO
var _bump_direction := Vector3.FORWARD
var _kid_hits := 0
var _riding_crashes := 0
var _on_foot: Node
var _walk_goal := Vector3.ZERO
var _parked_at := Vector3.ZERO
var _kid_start := Vector3.ZERO
var _lowest_y := 0.0       # the lowest the bike got while riding in from the gate (Session 27)
var _grid: RefCounted      # the map scan from _check_wahat, reused by _check_session27
var _saw_major_fall := false
var _clock_before := 0.0  # Session 35A: check pause/tutorial behaviour over real frames


func _initialize() -> void:
	CounterQueue.enabled = false  # Session 58: the short counter queue would change the exact E-hold timings checked here
	var scene_path := "res://scenes/wahat_al_shams.tscn"  # the game opens on the main menu, test the map
	var save_dir := "user://"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="):
			save_dir = arg.trim_prefix("--save-dir=")
		else:
			scene_path = arg
	_test_save = save_dir.path_join("smoke_%s_save.json" % scene_path.get_file().get_basename())
	print("      scene: ", scene_path)
	# Start from a clean slate, whatever is in the real save, and never write to it.
	var state := root.get_node("GameState")
	state.save_path = _test_save
	state.new_game()
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
	_minimap = _main.get_node_or_null("Minimap")
	_meters = _main.get_node_or_null("Meters")
	_on_foot = _main.get_node_or_null("OnFoot")
	# Session 33: no random events during the test's own rides (_check_session33 starts them).
	var events := _main.get_node_or_null("EventManager")
	if events != null:
		events.enabled = false
	# The old test area has boxes straight ahead of the start, and riding into one at sprint
	# speed is a big crash (Session 12). Do the riding checks in a clear lane instead.
	if scene_path.ends_with("test_area.tscn"):
		_bike.position = Vector3(60.0, 0.05, 0.0)  # the bike sits right under the scene root
	_bike.crashed.connect(func(big): if _phase in ["pedal", "sprint", "brake"]: _riding_crashes += 1)
	# GameState is an autoload, so it sits on the root next to the main scene.
	_game_state = root.get_node_or_null("GameState")
	Input.action_press("move_forward")


func _physics_process(_delta: float) -> bool:
	if _phase == "done":
		return false
	_frame += 1
	_top_speed = maxf(_top_speed, _bike.speed)
	if _phase in ["pedal", "sprint", "brake"]:
		_lowest_y = minf(_lowest_y, _bike.global_position.y)
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
				_check("no crash while testing the riding", _riding_crashes == 0, "")
				_check("stamina refills", _bike.stamina > 30.0, "stamina %.0f" % _bike.stamina)
				Input.action_release("move_back")
				_start_clock_check()
		"clock_paused":
			if _frame >= 30:
				_check("pausing freezes the shift over actual physics frames", _game_state.shift_time_left == _clock_before, "")
				paused = false
				_game_state.tutorial_running = true
				_frame = 0
				_phase = "clock_tutorial"
		"clock_tutorial":
			if _frame >= 30:
				_check("the tutorial freezes the shift over actual physics frames", _game_state.shift_time_left == _clock_before, "")
				_game_state.tutorial_running = false
				_frame = 0
				_phase = "clock_running"
		"clock_running":
			if _frame >= 60:
				var elapsed: float = _clock_before - _game_state.shift_time_left
				_check("resuming advances one shift second per real second", elapsed > 0.9 and elapsed < 1.1, "%.3f s" % elapsed)
				_check("resuming advances one game minute per active second",
						absf((_game_state.clock_hours() - 8.0) * 60.0 - elapsed) < 0.000001, "%.6f hours" % _game_state.clock_hours())
				_bike.set_parked(false)
				_start_delivery_check()
		"at_restaurant":
			if _frame >= STEPS.settle:
				_check("bike is near the restaurant door", _delivery.is_near_target(), "")
				_check_minimap_pin(_order.restaurant_name)
				_check_get_off()
				Input.action_press("interact")
				_frame = 0
				_phase = "pickup_tap"
		"pickup_tap":
			if _frame == STEPS.tap - 2:
				_check("the orange bar fills while E is held", _delivery.hold_progress() > 0.0
						and _main.get_node("Phone/Panel/Margin/Rows/HoldBar").visible, "%.0f%%" % (_delivery.hold_progress() * 100.0))
			if _frame >= STEPS.tap:
				Input.action_release("interact")
				_check("a quick tap of E at the restaurant does nothing", _game_state.stage_name() == "TO_RESTAURANT", "")
				Input.action_press("interact")
				_frame = 0
				_phase = "pickup_hold"
		"pickup_hold":
			if _frame >= STEPS.hold:
				Input.action_release("interact")
				_check("holding E for 1.5 s at the restaurant picks up the food", _game_state.stage_name() == "TO_VILLA", "")
				_check_stage("TO_VILLA")
				if _on_foot != null:
					_on_foot.walker.global_position = _bike.global_position + Vector3.UP * 0.05
					_check("F next to the bike gets you back on", _on_foot.get_on() and not _on_foot.on_foot, "")
				# Still at the restaurant, so the villa may be off the map: the pin must stay on it.
				_check_minimap_pin(_order.map_address if _order.map_address != "" else _order.address)
				_check_minimap_turns()
				_check_meters()
				_move_bike_to(_delivery.target_door())
				_frame = 0
				_phase = "at_villa"
		"at_villa":
			if _frame >= STEPS.settle:
				_check("bike is near the villa door", _delivery.is_near_target(), "")
				_check_minimap_pin(_order.map_address if _order.map_address != "" else _order.address)
				var spot: Vector2 = _minimap.world_to_map(_delivery.target_door())
				var middle: Vector2 = _minimap._view.size * 0.5
				_check("at the villa the pin is right next to you", spot.distance_to(middle) < 10.0,
						"%.1f px from the middle" % spot.distance_to(middle))
				_order.leave_at_door = false  # this one: the customer comes out
				_check_get_off()
				Input.action_press("interact")
				_frame = 0
				_phase = "dropoff_tap"
		"dropoff_tap":
			if _frame >= STEPS.tap:
				Input.action_release("interact")
				_check("a quick tap of E at the villa does nothing", _game_state.stage_name() == "TO_VILLA", "")
				Input.action_press("interact")
				_frame = 0
				_phase = "dropoff_hold"
		"dropoff_hold":
			if _frame >= STEPS.hold:
				Input.action_release("interact")
				_check("holding E for 1.5 s at the villa delivers", _game_state.stage_name() == "NONE", "")
				_check_delivered_card()
				if _on_foot != null:
					_on_foot.walker.global_position = _bike.global_position + Vector3.UP * 0.05
					_on_foot.walker.velocity = Vector3.ZERO
					_on_foot.get_on()
				_check_customer()
				_check("money goes up by the pay, minus 2 Dh insurance", _game_state.money == _money_before + _order.pay - GameConfig.INSURANCE_PER_DELIVERY, "Dh %d" % _game_state.money)
				_check("delivery is saved in the history", _game_state.history.size() == 1, "%d in history" % _game_state.history.size())
				_check("an all-red order can still be delivered", _game_state.history.size() == 1 and _game_state.history[0]["damage"] == 0.0, "")
				_check_stage("NONE")
				_start_skip_check()
		"timeout":
			if _frame >= STEPS.timeout:
				_check("an ignored order counts as skipped", _skipped == 2, "%d skipped" % _skipped)
				_check_stage("NONE")
				_delivery.offer_timeout = GameConfig.ORDER_OFFER_TIMEOUT
				_check_scoring()
				_start_walk_check()
		"walk_to_door":
			if _delivery.is_near_target() or _frame >= STEPS.walk:
				Input.action_release("move_forward")
				_check("you can walk from the bike to the door", _delivery.is_near_target(), "%.1f m to go" % _flat(_walk_goal - _on_foot.walker.global_position).length())
				_check("the parked bike stays where it is", _bike.global_position.distance_to(_parked_at) < 0.1, "")
				Input.action_press("interact")
				_frame = 0
				_phase = "walk_hold"
		"walk_hold":
			if _frame >= STEPS.hold:
				Input.action_release("interact")
				_check("on foot, holding E at the door delivers", _game_state.stage_name() == "NONE", "")
				_close_card()
				_face(_on_foot.walker, _bike.global_position)
				Input.action_press("move_forward")
				_frame = 0
				_phase = "walk_back"
		"walk_back":
			if _on_foot.near_bike() or _frame >= STEPS.walk:
				Input.action_release("move_forward")
				_check("you can walk back to the bike", _on_foot.near_bike(), "")
				Input.action_press("toggle_bike")
				_frame = 0
				_phase = "press_f"
		"press_f":
			if _frame == 2:
				Input.action_release("toggle_bike")
				_check("F next to the bike gets you riding again", not _on_foot.on_foot and not _bike.parked, "")
				_parked_at = _bike.global_position
				Input.action_press("move_forward")
			if _frame >= 60:
				Input.action_release("move_forward")
				_check("and you can ride away", _bike.global_position.distance_to(_parked_at) > 1.0, "%.1f m" % _bike.global_position.distance_to(_parked_at))
				_start_crash(false)
		"crash_small":
			if _frame >= STEPS.crash_small:
				_check("a slow hit is a small crash: you fall off", _bike.fallen_left > 0.0 and not _bike.wrecked, "")
				_check("a small crash knocks the food hard", _game_state.meter_damage <= 100.0 - GameConfig.CRASH_SMALL_DAMAGE, "%.0f%%" % _game_state.meter_damage)
				_check("no clinic after a small crash", not _main.get_node("ClinicScreen").showing, "")
				_frame = 0
				_phase = "fallen"
		"fallen":
			if _frame >= STEPS.fallen:
				_check("back on the bike after the small crash", _bike.fallen_left == 0.0, "")
				_start_crash(true)
		"crash_big":
			if _bike.fallen_left > 0.0 and _bike.wrecked and not _main.get_node("ClinicScreen").showing:
				_saw_major_fall = true
			if _main.get_node("ClinicScreen").showing or _frame >= STEPS.crash_big:
				Input.action_release("move_forward")
				_check_big_crash()
				_start_shift_check(true)
		"shift_carrying":
			if _frame >= STEPS.shift:
				_check_shift_carrying()
				_start_shift_check(false)
		"shift_empty":
			if _frame >= STEPS.shift:
				_check_shift_empty()
				_check_tutorial()
				_start_decor_check()
		"bump_ride":
			if _frame >= STEPS.bump_ride:
				_check_bump_ride()
				_start_critter_check()
		"critters":
			if _frame >= STEPS.critters:
				_check_critters()
				_finish()
	return false


## Session 35A correction: one active second is one game minute. The minute display
## must not quantize simulation time or depend on the size of individual frames.
## Run on every test map, before any delivery changes the clock or pauses the game.
func _start_clock_check() -> void:
	var gs: Node = _game_state
	var manager: Node = _main.get_node("ShiftManager")
	var screen: Node = _main.get_node("ShiftScreen")
	gs.reset()
	_check("a normal 8 AM to 6 PM shift lasts ten real minutes", GameConfig.SHIFT_LENGTH == 600.0
			and manager.shift_length == 600.0 and gs.shift_time_left == 600.0, "%.0f s" % gs.shift_time_left)
	var examples := [
		[0.0, "12:00 AM"],
		[8.0, "8:00 AM"],
		[8.0 + 0.99 / 60.0, "8:00 AM"],
		[8.0 + 1.0 / 60.0, "8:01 AM"],
		[8.0 + 10.0 / 60.0, "8:10 AM"],
		[11.0 + 59.0 / 60.0, "11:59 AM"],
		[12.0, "12:00 PM"],
		[13.5, "1:30 PM"],
		[18.0, "6:00 PM"],
		[23.0 + 59.0 / 60.0, "11:59 PM"],
	]
	for example in examples:
		var shown: String = GameClock.format_time(example[0])
		_check("clock format at %.5f hours is %s" % [example[0], example[1]], shown == example[1], shown)
	screen._process(0.0)
	_check("the live HUD starts at 8:00 AM with a sun icon", screen._clock.text == "8:00 AM"
			and screen._sun_icon != null and screen._sun_icon.is_visible_in_tree(), screen._clock.text)
	manager._physics_process(0.99)
	screen._process(0.0)
	_check("the clock display waits one second before its next minute", screen._clock.text == "8:00 AM", screen._clock.text)
	_check("simulation time advances between displayed minutes", gs.clock_hours() > 8.016
			and gs.clock_hours() < 8.0 + 1.0 / 60.0, "%.6f hours" % gs.clock_hours())
	manager._physics_process(0.01)
	screen._process(0.0)
	_check("one real second advances the live display to 8:01 AM", screen._clock.text == "8:01 AM", screen._clock.text)
	manager._physics_process(59.0)
	screen._process(0.0)
	_check("one game hour takes 60 real seconds", absf(gs.clock_hours() - 9.0) < 0.000001
			and screen._clock.text == "9:00 AM", "%.6f hours, %s" % [gs.clock_hours(), screen._clock.text])
	var one_step_clock: float = gs.clock_hours()
	gs.reset()
	for step in [0.125, 0.375, 4.5, 15.0, 40.0]:  # 60 seconds in differently-sized frames
		manager._physics_process(step)
	_check("mixed frame durations preserve the one-second-to-one-minute rate", absf(gs.clock_hours() - one_step_clock) < 0.000001
			and absf(gs.shift_time_left - 540.0) < 0.000001, "%.6f hours, %.6f s left" % [gs.clock_hours(), gs.shift_time_left])
	gs.reset()
	manager._physics_process(209.99)
	_check("lunch is not active before 11:30 AM", not OrderMaker.is_lunch(gs.clock_hours()), "")
	manager._physics_process(0.01)
	_check("lunch starts 210 seconds into the ten-minute shift", absf(gs.clock_hours() - 11.5) < 0.000001
			and OrderMaker.is_lunch(gs.clock_hours()), "%.6f hours" % gs.clock_hours())
	manager._physics_process(30.0)
	screen._process(0.0)
	_check("the live clock reaches noon after 240 real seconds", absf(gs.clock_hours() - 12.0) < 0.000001
			and screen._clock.text == "12:00 PM", screen._clock.text)
	manager._physics_process(29.99)
	_check("lunch remains active just before its 60-second window ends", OrderMaker.is_lunch(gs.clock_hours()), "")
	manager._physics_process(0.01)
	_check("lunch ends after 60 real seconds", absf(gs.clock_hours() - 12.5) < 0.000001
			and not OrderMaker.is_lunch(gs.clock_hours()), "%.6f hours" % gs.clock_hours())
	manager._physics_process(149.99)
	_check("the school still takes orders just before 3:00 PM", OrderMaker.school_open(gs.clock_hours()), "")
	manager._physics_process(0.01)
	_check("school orders close 420 seconds into the shift", absf(gs.clock_hours() - 15.0) < 0.000001
			and not OrderMaker.school_open(gs.clock_hours()), "%.6f hours" % gs.clock_hours())
	_set_hour(11.0 + 50.0 / 60.0)
	screen._process(0.0)
	_check("the live clock displays 11:50 AM before noon", screen._clock.text == "11:50 AM", screen._clock.text)
	_set_hour(12.0)
	screen._process(0.0)
	_check("the live clock changes to 12:00 PM at noon", screen._clock.text == "12:00 PM", screen._clock.text)
	_set_hour(18.0)
	screen._process(0.0)
	_check("the live clock ends at 6:00 PM", screen._clock.text == "6:00 PM", screen._clock.text)
	var events: Node = _main.get_node_or_null("EventManager")
	if events != null:
		_check("event times use the same AM/PM display", events._clock_text(13.5) == "1:30 PM"
				and events._clock_text(22.0) == "6:00 PM", events._clock_text(13.5))
	# Exercise the full default duration as well as the accelerated final-delivery checks.
	var bike_pose: Transform3D = _bike.global_transform
	gs.reset()
	manager._physics_process(599.0)
	screen._process(0.0)
	_check("a normal shift is still open at 5:59 PM", not gs.shift_clock_out and not screen.showing
			and screen._clock.text == "5:59 PM", screen._clock.text)
	manager._physics_process(1.0)
	screen._process(0.0)
	_check("a normal shift clocks out at 6:00 PM after 600 seconds", gs.shift_clock_out and screen.showing
			and paused and screen._clock.text == "6:00 PM", screen._clock.text)
	_check("a completed ten-minute shift cannot offer another job", _delivery.offer_now() == null, "")
	screen._next_shift()
	_bike.global_transform = bike_pose  # next-shift reset must not undo the map's initial riding check
	gs.reset()
	_clock_before = gs.shift_time_left
	_bike.set_parked(true)
	paused = true
	_frame = 0
	_phase = "clock_paused"


## Fresh start, a new order pops up, accept it, then jump to the restaurant door.
func _start_delivery_check() -> void:
	_check_wahat()
	_check_application()
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
	_game_state.shift_goals.clear()  # this phase isolates the plain delivery loop
	# The older checks want plain orders (a neighbour order would send them next door, a rush
	# order changes the target time). _check_session32 turns specials and regulars back on.
	_delivery.special_chance = 0.0
	_delivery.regular_chance = 0.0
	_game_state.connect("order_skipped", _on_order_skipped)
	_order = _delivery.offer_now()
	var places: Node = _delivery.place_builder
	var built := 0
	if places != null:
		built = places.find_children("Villa*", "StaticBody3D", true, false).size()
	# Drop-off spots that aren't homes (the school booth, the stable office) get no villa.
	var listed: int = 0 if places == null else places.villas.filter(func(v): return v.get("kind", "") != "spot").size()
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
## English sign.
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
	_check_notes()
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


## Session 6: every palm, parked car and speed bump in the data list was built, the mosque
## and mini market have Arabic + English signs. Then the bike rides over the first speed bump.
func _start_decor_check() -> void:
	var decor := _main.get_node_or_null("DecorBuilder")
	if decor == null:
		print("      no DecorBuilder in this scene, decorations and speed bumps not checked")
		_finish()
		return
	var lists := [["Palm_", decor.palms], ["ParkedCar_", decor.parked_cars], ["SpeedBump_", decor.speed_bumps]]
	for pair in lists:
		var prefix: String = pair[0]
		var listed: Array = pair[1]
		var built := 0
		for i in listed.size():
			if decor.get_node_or_null(prefix + str(i)) != null:
				built += 1
		_check("every %s* in the data list was built" % prefix, listed.size() > 0 and built == listed.size(),
				"%d of %d" % [built, listed.size()])
	var map: Dictionary = decor.data.get_script_constant_map()
	for pair in [["Mosque", "MOSQUE"], ["Supermarket", "SUPERMARKET"]]:
		if not map.has(pair[1]):
			continue
		var node_name: String = pair[0]
		var place: Dictionary = map[pair[1]]
		var english: String = place["name"]
		var building := decor.get_node_or_null(node_name)
		_check(node_name + " was built", building != null, "")
		if building != null:
			_check(node_name + " has an Arabic sign", _has_arabic_label(building), "")
			_check(node_name + " has an English sign", _has_label_text(building, english), english)
	if decor.speed_bumps.is_empty():
		_finish()
		return
	# Put the bike, standing still, a few metres before the first bump, facing across it.
	var bump: Dictionary = decor.speed_bumps[0]
	var facing: float = bump["facing"]
	_bump_spot = bump["position"]
	_bump_direction = Vector3(sin(deg_to_rad(facing)), 0.0, cos(deg_to_rad(facing)))
	_move_bike_to(_bump_spot - _bump_direction * BUMP_RUN_UP)
	# The bike rides towards its -Z side, so turn it to face the bump.
	_bike.rotation = Vector3(0.0, atan2(-_bump_direction.x, -_bump_direction.z), 0.0)
	_bumps_before = _bike.bumps_taken
	Input.action_press("move_forward")
	_frame = 0
	_phase = "bump_ride"


## Riding over a speed bump counts exactly once, and the bike doesn't get stuck on it.
func _check_bump_ride() -> void:
	Input.action_release("move_forward")
	var taken: int = _bike.bumps_taken - _bumps_before
	_check("riding over a speed bump counts once", taken == 1, "%d bumps" % taken)
	var past: float = (_bike.global_position - _bump_spot).dot(_bump_direction)
	var moving: bool = _bike.speed > 1.0 or past > 1.0
	_check("the bike rides on over the speed bump", moving,
			"%.1f m past it, %.1f m/s" % [past, _bike.speed])
	_check("the bike is still on the ground after the bump", _bike.is_on_floor(), "")


## Session 9: cats and kids were built. Pick up an order, then park the bike in front of
## a kid on a scooter and let them ride into it.
func _start_critter_check() -> void:
	var obstacles := _main.get_node_or_null("ObstacleBuilder")
	if obstacles == null:
		_check("ObstacleBuilder node exists in the scene", false, "")
		_finish()
		return
	for pair in [["Cat_", obstacles.cats], ["ScooterKid_", obstacles.kids]]:
		var listed: Array = pair[1]
		var built := 0
		for i in listed.size():
			if obstacles.get_node_or_null(pair[0] + str(i)) != null:
				built += 1
		_check("every %s* in the data list was built" % pair[0], listed.size() > 0 and built == listed.size(),
				"%d of %d" % [built, listed.size()])
	var kid: Node3D = obstacles.get_node("ScooterKid_0")
	kid.position = kid._from
	kid._going_to_end = true
	kid._pause_left = 0.0
	kid.scared_left = 0.0
	_kid_start = kid.position
	kid.hit_by_bike.connect(func(): _kid_hits += 1)
	var ahead: Vector3 = (kid._to - kid._from).normalized()
	_game_state.reset()
	_game_state.shift_goals.clear()  # isolate ordinary food damage from a forced fragile-goal offer
	_delivery.offer_now()
	_delivery.accept()
	_game_state.pick_up()
	_move_bike_to(kid._from + ahead * 3.5)  # far enough for a clear run, close enough to hit in 2 s
	_frame = 0
	_phase = "critters"


func _check_critters() -> void:
	var obstacles := _main.get_node("ObstacleBuilder")
	var kid: Node3D = obstacles.get_node("ScooterKid_0")
	_check("kids on scooters move", kid.position.distance_to(_kid_start) > 0.5, "%.1f m" % kid.position.distance_to(_kid_start))
	_check("a kid riding into the bike counts once", _kid_hits == 1, "%d hits" % _kid_hits)
	_check("bumping a kid hurts the damage meter", _game_state.meter_damage < 100.0, "%.0f%%" % _game_state.meter_damage)
	var cats_home := true
	for i in obstacles.cats.size():
		var cat: Node3D = obstacles.get_node("Cat_%d" % i)
		var patch: Rect2 = cat.area().grow(1.0)
		cats_home = cats_home and patch.has_point(Vector2(cat.position.x, cat.position.z))
	_check("cats stay on their own patch", cats_home, "")
	var cat: Node3D = obstacles.get_node("Cat_0")
	cat.scared_left = 0.0  # begin the explicit cooldown check with a calm cat
	var before: float = _game_state.meter_damage
	cat.bumped_by(_bike)
	cat.bumped_by(_bike)
	var lost: float = before - _game_state.meter_damage
	_check("bumping a cat hurts the food once", absf(lost - GameConfig.DAMAGE_CRITTER[_order_food()]) < 0.01, "%.0f%% lost" % lost)


func _order_food() -> String:
	return _game_state.current_order.food


## Session 11: a customer came out of the delivered villa with a line from the list,
## and a leave-at-the-door order leaves a bag and nobody comes out.
func _check_customer() -> void:
	var spawner := _main.get_node_or_null("CustomerSpawner")
	if spawner == null:
		_check("CustomerSpawner node exists in the scene", false, "")
		return
	var customer: Node3D = spawner.last_spawned
	var door: Vector3 = _delivery.place_builder.villa_door(_order.villa_number)
	_check("a customer comes out at the villa", customer != null and customer.name.begins_with("Customer")
			and customer.global_position.distance_to(door) < 4.0, "")
	if customer == null or not customer.name.begins_with("Customer"):
		return
	var lines: Array = load("res://data/customer_lines.gd").LINES
	_check("there are at least 15 customer lines", lines.size() >= 15, "%d lines" % lines.size())
	# Session 32: at the school or the stables a teacher, kid, rider or groom says one of theirs.
	var spot_lines: Dictionary = load("res://data/customer_lines.gd").SPOT_LINES
	if spot_lines.has(_order.who):
		lines = spot_lines[_order.who]
	var said: String = customer.line
	print("      customer says: ", said)
	var known := false
	for line in lines:
		known = known or spawner.fill_line(line, _game_state.rider_name) == said
	_check("the customer says a line from the list", known, "")
	var different := {}
	for i in 60:
		different[spawner.pick_line("Sam")] = true
	_check("customers say different lines", different.size() >= 10, "%d different" % different.size())
	_check("customers use the rider's name", lines.any(func(l): return "{name}" in l), "")
	var left: Object = _delivery.make_order()
	left.villa_number = _order.villa_number
	left.leave_at_door = true
	spawner._on_order_delivered(left)
	_check("leave-at-the-door: nobody comes out, a bag is left", spawner.last_spawned.name.begins_with("LeftBag"), "")
	var leaves := 0
	for i in 300:
		if _delivery.make_order().leave_at_door:
			leaves += 1
	_check("some orders say leave it at the door", leaves > 15 and leaves < 90, "%d of 300" % leaves)


## Session 12: park the bike in front of villa 1's wall with an order on board and let it
## hit the wall: slowly (small crash) or fast (big crash).
func _start_crash(big: bool) -> void:
	var gs: Node = _game_state
	gs.reset()
	_delivery.offer_now()
	_delivery.accept()
	gs.pick_up()
	var villa: Dictionary = _delivery.place_builder.villas[0]
	var angle := deg_to_rad(villa["facing"])
	var front := Vector3(sin(angle), 0.0, cos(angle))
	_move_bike_to(_delivery.place_builder.villa_door(villa["number"]))
	_bike.rotation = Vector3(0.0, atan2(front.x, front.z), 0.0)  # facing the wall
	_bike.speed = 7.5 if big else 4.2  # 27 km/h or 15 km/h
	if big:
		_saw_major_fall = false
		_money_before = gs.money
		Input.action_press("move_forward")
	_frame = 0
	_phase = "crash_big" if big else "crash_small"


func _check_big_crash() -> void:
	var gs: Node = _game_state
	var clinic: Node = _main.get_node("ClinicScreen")
	_check("a fast hit into a wall is a big crash", _bike.wrecked or clinic.showing, "")
	_check("the clinic screen shows and the game pauses", clinic.showing and paused, "")
	var bills: Dictionary = clinic.last_bills
	var expected: Dictionary = load("res://scripts/crash_impact.gd").quote(bills.get("impact", {}))
	_check("a major fall animates before the hospital cut", _saw_major_fall, "")
	_check("clinic bills match the captured impact severity", bills.get("hospital") == expected["hospital"] and bills.get("repair") == expected["repair"], str(bills))
	_check("the boss pays the first big crash", bills.get("boss", false) and gs.money == _money_before, "Dh %d" % gs.money)
	_check("the order is cancelled with 0 stars", gs.stage_name() == "NONE" and gs.history.size() == 1
			and gs.history[0]["cancelled"] and gs.history[0]["stars"] == 0.0, "")
	clinic.close()
	var shift_screen: Node = _main.get_node("ShiftScreen")
	_check("a big crash ends the shift: the summary shows", shift_screen.showing and paused
			and shift_screen.last_summary.get("cancelled") == 1, "")
	shift_screen._next_shift()
	_check("next shift: game runs, bike back at the start", not paused and not _bike.wrecked
			and not gs.shift_clock_out, "shift %d" % gs.shift_number)
	var before: int = gs.money
	var insured: Dictionary = gs.big_crash()
	_check("with insurance a big crash costs 20 Dh", insured["paid"] == 20 and gs.money == before - 20, "Dh %d" % gs.money)
	gs.set_insurance(false)
	before = gs.money
	var uninsured: Dictionary = gs.big_crash()
	_check("without insurance a big crash costs 230 Dh", uninsured["paid"] == 230 and gs.money == before - 230, "Dh %d" % gs.money)
	clinic.open(uninsured, true)
	_check("the clinic says what you hit and how fast", "You hit a villa wall at" in clinic._story.text and "km/h" in clinic._story.text, clinic._story.text)
	_check("the clinic counts this week's big crashes", gs.crashes_this_week() == 3 and clinic._week_text.text == "3 of 3", clinic._week_text.text)
	_check("uninsured: the tip and Turn on insurance show", clinic._tip_box.visible and clinic._insure_button.visible, "")
	clinic.turn_on_insurance()
	_check("Turn on insurance switches it on", gs.insurance_on and not clinic._insure_button.visible, "")
	clinic.close()
	var summary_screen: Node = _main.get_node("ShiftScreen")
	if summary_screen.showing:
		summary_screen._next_shift()
	gs.set_insurance(true)
	_check("insurance starts switched on", true, "")
	var phone := _main.get_node("Phone")
	var key := InputEventAction.new()
	key.action = "toggle_insurance"
	key.pressed = true
	phone._unhandled_input(key)
	_check("I switches insurance off on the phone", not gs.insurance_on
			and "OFF" in phone.get_node("Panel/Margin/Rows/Insurance").text, "")
	gs.reset()
	_check("a fresh game starts with insurance on", gs.insurance_on, "")


## Session 25: Wahat Al Shams. 60 homes with addresses like "C3 · Villa 7", the bike rode
## from the gate into the Plaza, every door spot can be reached by bike.
func _check_wahat() -> void:
	var places: Node = _main.get_node_or_null("PlaceBuilder")
	if places == null or not places.data.get_script_constant_map().has("MAP_HALF"):
		print("      not Wahat Al Shams, its checks skipped")
		return
	var data: Dictionary = places.data.get_script_constant_map()
	var homes: Array = places.villas.filter(func(v): return v.get("kind", "") != "spot")
	_check("Wahat Al Shams has 500 homes", homes.size() == 500, "%d" % homes.size())
	var good := 0
	var clusters := {}
	for villa in homes:
		var house: int = villa["house"]
		if villa["address"] == "Villa %d, Cluster %s" % [house, str(villa["cluster"]).substr(1)] and villa.get("map_address", "") == "%s · Villa %d" % [villa["cluster"], house] and house >= 1 and house <= 100:
			good += 1
		clusters[villa["cluster"]] = clusters.get(villa["cluster"], 0) + 1
	_check("every home has a full phone address and compact cluster map address", good == 500, "%d of 500" % good)
	_check("5 clusters of 100 homes", clusters.size() == 5 and clusters.values().all(func(n): return n == 100), "%s" % [clusters])
	var plaza: Dictionary = data["PLAZA"]
	var reached: float = Vector2(_bike.global_position.x, _bike.global_position.z).distance_to(plaza["centre"])
	_check("the bus-stop ride reaches the Plaza neighbourhood", reached < plaza["radius"] + 12.0, "%.0f m from the middle" % reached)
	var started := Time.get_ticks_msec()
	var grid: RefCounted = GRID.new()
	_grid = grid
	grid.build(_bike.get_world_3d(), data["MAP_HALF"], [_bike, _on_foot.walker if _on_foot != null else null])
	var house: Vector3 = places.villas[0]["position"]
	_check("the map scan sees houses as solid and lanes as free", not grid.is_free(Vector2(house.x, house.z))
			and grid.is_free(Vector2(data["START"]["position"].x, data["START"]["position"].z)), "")
	var start: Vector3 = data["START"]["position"]
	var stuck := []
	for villa in places.villas:
		var door: Vector3 = places.villa_door(villa["number"])
		if not grid.can_reach(Vector2(start.x, start.z), Vector2(door.x, door.z)):
			stuck.append(villa["address"])
	for shop in places.restaurants:
		var door: Vector3 = places.restaurant_door(shop["id"])
		if not grid.can_reach(Vector2(start.x, start.z), Vector2(door.x, door.z)):
			stuck.append(shop["name"])
	_check("every home, shop and reception can be reached through the collision map", stuck.is_empty(),
			"%s (%.1f s)" % [stuck, (Time.get_ticks_msec() - started) / 1000.0])
	_check("bollards stop cars at the lane entrances", data["BOLLARDS"].size() >= 20, "%d" % data["BOLLARDS"].size())


## Session 14: fill in the rider application and get hired. Runs before the map loads.
func _check_application() -> void:
	var gs: Node = root.get_node("GameState")
	var app: Control = load("res://scenes/application.tscn").instantiate()
	root.add_child(app)
	_check("the application can't be sent without a name", not app.submit(), "")
	app.name_box.text = "  Sam "
	app.country_box.select(6)
	app._pick_look(2)
	_check("the application is sent", app.submit() and app.page == "reviewing", app.page)
	app.finish_review()
	_check("you're hired", app.page == "hired" and "Sam" in app._hired_text.text, app._hired_text.text)
	_check("the application keeps name, country and look", gs.rider_name == "Sam" and gs.rider_country == "Egypt"
			and gs.rider_look == 2 and gs.hired, "%s from %s, look %d" % [gs.rider_name, gs.rider_country, gs.rider_look])
	app.free()
	gs.hired = false  # so the tutorial doesn't start by itself; _check_tutorial() runs it


## Session 14: the tutorial's first order, its tips, and the look on the bike.
func _check_tutorial() -> void:
	var gs: Node = _game_state
	var tutorial := _main.get_node_or_null("Tutorial")
	var model: Node3D = _bike.get_node("Model/Rider")  # the rider on the bike (Session 29)
	var parts := []
	for number in 3:
		RiderLook.apply(model, number)
		parts.append(model.get_node("Look").get_child_count())
		if number == 1:
			_check("Sporty keeps the helmet (with stickers)", model.get_node("Helmet").visible, "")
		else:
			_check("look %d swaps the helmet for a hat" % number, not model.get_node("Helmet").visible, "")
	_check("the 3 looks are different", parts[0] != parts[1] and parts[1] != parts[2], "%s parts" % [parts])
	RiderLook.apply(model, gs.rider_look)
	var spawner := _main.get_node("CustomerSpawner")
	var named: String = spawner.fill_line("Thanks, {name}!", gs.rider_name)
	_check("customers use your name", named == "Thanks, Sam!", named)
	if tutorial == null:
		print("      no Tutorial in this scene, tutorial not checked")
		return
	gs.reset()
	gs.hired = true
	gs.tutorial_done = false
	tutorial.start()
	var first: Object = gs.offered_order
	var tutorial_villa: int = _delivery.place_builder.data.get_script_constant_map()["TUTORIAL_ORDER"]["villa"]
	_check("the tutorial's first order is the easy pizza", first != null and first.restaurant_id == "pizza"
			and first.villa_number == tutorial_villa, "" if first == null else first.describe())
	tutorial._process(0.0)
	_check("tip: press E to accept", "Press E to accept" in tutorial.tip, tutorial.tip)
	_delivery.skip()
	_check("skipping the tutorial order brings it back", gs.stage_name() == "OFFERED" and gs.offered_order.villa_number == tutorial_villa, "")
	var clock: float = gs.shift_time_left
	_main.get_node("ShiftManager")._physics_process(5.0)
	_delivery._physics_process(100.0)
	_check("during the tutorial the clock waits and the order never runs out", gs.shift_time_left == clock
			and gs.stage_name() == "OFFERED", "")
	_delivery.accept()
	tutorial._process(0.0)
	_check("tip: ride to the pizza place with the mini-map", gs.current_order.restaurant_name in tutorial.tip and "mini-map" in tutorial.tip, "")
	_move_bike_to(_delivery.target_door())
	tutorial._process(0.0)
	_check("tip at the door: get off and hold E to pick up", "press F to get off" in tutorial.tip and "hold E" in tutorial.tip, tutorial.tip)
	gs.pick_up()
	_move_bike_to(Vector3(2.0, 0.05, 140.0))
	tutorial._process(0.0)
	_check("tip: take it to the tutorial address, watch the meters", gs.current_order.address in tutorial.tip and "meters" in tutorial.tip, tutorial.tip)
	gs.deliver()
	_close_card()
	_check("after the first delivery: a tip that insurance is on", "insurance is ON" in tutorial.tip, tutorial.tip)
	tutorial.finish()
	_check("the tutorial finishes and normal orders start", gs.tutorial_done and not gs.tutorial_running, "")
	gs.reset()


## Session 16: every sound file loads, the buses and sliders work, and the right sound
## plays for each event. (Headless has no speakers, so it checks which sound was chosen.)
func _check_sound() -> void:
	var gs: Node = _game_state
	if gs == null:
		return
	paused = false
	var files := ["bell", "cash", "crash", "ping", "bump", "roll_loop", "ambience_loop", "music_loop"]
	var loaded := 0
	for file in files:
		var stream := load("res://assets/audio/%s.wav" % file) as AudioStreamWAV
		if stream != null and stream.get_length() > 0.1:
			loaded += 1
	_check("all 8 sound files load", loaded == files.size(), "%d of %d" % [loaded, files.size()])
	var buses := 0
	for bus in ["Music", "Effects", "Ambience"]:
		if AudioServer.get_bus_index(bus) >= 0:
			buses += 1
	_check("the Music, Effects and Ambience buses exist", buses == 3, "")
	var music_player: AudioStreamPlayer = root.get_node("Music").player
	_check("the music loops on the Music bus", music_player.bus == "Music"
			and (music_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "")
	var before: float = Settings.volumes["Music"]
	Settings.volumes["Music"] = 0.5
	Settings.apply()
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	_check("the Music volume reaches the bus", absf(db - linear_to_db(0.5)) < 0.01, "%.1f dB" % db)
	Settings.volumes["Music"] = before
	Settings.apply()
	var panel := SettingsPanel.new()
	root.add_child(panel)
	_check("Settings has 4 volume sliders", panel.volume_sliders.size() == 4, "")
	panel.free()
	var sounds := _main.get_node_or_null("Sounds")
	if sounds == null:
		_check("Sounds node exists in the scene", false, "")
		return
	gs.reset()
	_delivery.offer_now()
	_check("a new order goes ping", sounds.last_played == "ping", sounds.last_played)
	_delivery.accept()
	gs.pick_up()
	_check("picking up rings the bike bell", sounds.last_played == "bell", sounds.last_played)
	gs.deliver()
	_close_card()
	_check("delivering goes ka-ching", sounds.last_played == "cash", sounds.last_played)
	_bike.went_over_bump.emit(0.5)
	_check("a speed bump goes thump", sounds.last_played == "bump", sounds.last_played)
	gs.reset()


## Reopening the game halfway through a shift plays that same shift again (it doesn't count
## a new one, or move on the day); a finished shift does count; skips are remembered.
func _check_reopening(gs: Node) -> void:
	gs.reset()
	gs._remember_choice(true)
	gs._remember_choice(false)
	var number: int = gs.shift_number
	var day: String = gs.day_kind
	gs.save_game()
	gs.load_game()
	_check("reopening mid-shift keeps the same shift and day", gs.shift_number == number and gs.day_kind == day,
			"%d, was %d" % [gs.shift_number, number])
	_check("accept / skip choices come back after reopening", absf(gs.acceptance_rate() - 0.5) < 0.001,
			"%.2f" % gs.acceptance_rate())
	gs.end_shift()
	gs.save_game()
	gs.load_game()
	_check("reopening after a finished shift starts the next one", gs.shift_number == number + 1,
			"%d" % gs.shift_number)


## Session 15: save and load keep your progress, the menus have their buttons.
## Runs last (from _finish), on the test's own save file.
func _check_saving() -> void:
	var gs: Node = _game_state
	if gs == null:
		return
	paused = false
	gs.reset()
	gs.hire("Lina", "Oman", 1)
	_quick_delivery(100.0, false)
	_quick_delivery(50.0, false)
	gs.set_insurance(false)
	gs.regular_visits = {"mariam": 3, "rashid": 1}
	var keep := {"money": gs.money, "xp": gs.xp, "jobs": gs.history.size(), "rating": gs.rating()}
	_check("the game saves", gs.save_game() and FileAccess.file_exists(_test_save), _test_save)
	gs.reset()
	gs.rider_name = ""
	gs.hired = false
	gs.insurance_on = true
	_check("loading finds the save", gs.load_game(), "")
	_check("money, XP and history come back", gs.money == keep["money"] and gs.xp == keep["xp"]
			and gs.history.size() == keep["jobs"] and absf(gs.rating() - keep["rating"]) < 0.001,
			"Dh %d, %d XP, %d jobs" % [gs.money, gs.xp, gs.history.size()])
	_check("name, country, look and insurance come back", gs.rider_name == "Lina" and gs.rider_country == "Oman"
			and gs.rider_look == 1 and gs.hired and not gs.insurance_on, "")
	_check("loading keeps existing regular-customer visits", gs.regular_visits == {"mariam": 3, "rashid": 1}, str(gs.regular_visits))
	_check("saved numbers stay whole numbers", typeof(gs.money) == TYPE_INT and typeof(gs.history[0]["pay"]) == TYPE_INT, "")
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	_check("main menu: Continue goes to Wahat Al Shams once hired", menu.play_button.text == "Continue"
			and menu.play_scene() == "res://scenes/wahat_al_shams.tscn", menu.play_button.text)
	gs.hired = false
	_check("main menu: Play opens the application on the phone the first time", menu.play_scene() == "form", "")
	menu.play()
	_check("the phone turns into the rider application", menu.page == "form" and menu.name_box.is_visible_in_tree(), menu.page)
	_check("the start screen has a 3D look card for each look", menu._look_cards.size() == 3 and menu._look_riders.size() == 3, "")
	menu._open_settings()
	_check("main menu: Settings opens", menu.settings_panel.visible and menu.settings_panel.fullscreen_box != null, "")
	menu.free()
	var pause_menu: Node = _main.get_node("PauseMenu")
	pause_menu._pause()
	var names := []
	for button in pause_menu.get_node("Panel/Margin/Rows/Buttons").get_children():
		names.append(button.text)
	_check("pause menu: Resume, Settings, Main menu, Quit", names == ["Resume", "Settings", "Main menu", "Quit game"], "%s" % [names])
	pause_menu._resume()
	_check_reopening(gs)
	_check("the game opens on the main menu",
			ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main_menu.tscn", "")
	gs.new_game()
	_check("New game wipes everything", gs.money == 0 and gs.history.is_empty() and not gs.hired and gs.rider_name == "", "")
	SaveGame.delete(_test_save)
	_check("the test save is cleaned up", not FileAccess.file_exists(_test_save), "")


## Session 13: a 1-second test shift. carrying: run out of time while carrying an order.
func _start_shift_check(carrying: bool) -> void:
	var gs: Node = _game_state
	gs.reset()
	var clock: Label = _main.get_node("ShiftScreen")._clock
	_main.get_node("ShiftScreen")._process(0.0)
	if carrying:
		_check("the shift clock starts at 8:00 AM", clock.text == "8:00 AM", clock.text)
		_quick_delivery(100.0, false)  # one finished job this shift
		_delivery.offer_now()
		_delivery.accept()
		gs.pick_up()
	_main.get_node("ShiftManager").shift_length = 1.0
	_frame = 0
	_phase = "shift_carrying" if carrying else "shift_empty"


func _check_shift_carrying() -> void:
	var gs: Node = _game_state
	var screen: Node = _main.get_node("ShiftScreen")
	_check("the shift clock runs out", gs.shift_clock_out and gs.clock_hours() == GameConfig.SHIFT_END_HOUR, "")
	_check("carrying an order: you can still finish it", not screen.showing and gs.stage_name() == "TO_VILLA", "")
	_check("no new orders once the clock is out", _delivery.offer_now() == null, "")
	if _on_foot != null:
		_on_foot.get_off()
		_on_foot.walker.global_position += Vector3(0, 0, 20)
	gs.deliver()
	_check("the Delivered card shows first", _main.get_node("DeliveredCard").showing and not screen.showing, "")
	_close_card()
	_check("the shift ends right after the last delivery", screen.showing and paused, "")
	var summary: Dictionary = screen.last_summary
	var want: Dictionary = gs.shift_summary()
	_check("the summary counts both deliveries", summary.get("deliveries") == 2, "%s" % summary.get("deliveries"))
	var pay: int = gs.history[0]["pay"] + gs.history[1]["pay"]
	var tips: int = gs.history[0]["tip"] + gs.history[1]["tip"]
	_check("the summary money adds up", summary["pay"] == pay and summary["tips"] == tips
			and summary["earned"] == pay + tips + summary["goal_bonus"] - 2 * GameConfig.INSURANCE_PER_DELIVERY  # Session 32: + shift goals
			and summary["earned"] == gs.money, "%d Dh (goal bonus %d)" % [summary["earned"], summary["goal_bonus"]])
	_check("the summary has stars and XP", summary["stars"] == want["stars"] and summary["xp"] == gs.xp, "%.1f stars, %d XP" % [summary["stars"], summary["xp"]])
	screen._next_shift()
	_check("the next shift starts with a full clock", not paused and not gs.shift_clock_out
			and gs.shift_time_left == GameConfig.SHIFT_LENGTH and gs.shift_number == 2, "")
	if _on_foot != null:
		_check("a shift finished on foot starts the next shift riding the reset bike", not _on_foot.on_foot and _delivery.actor == _bike and _main.get_node("FollowCamera").target == _bike, "")


func _check_shift_empty() -> void:
	var gs: Node = _game_state
	var screen: Node = _main.get_node("ShiftScreen")
	_check("with no order, the shift ends as soon as the clock runs out", screen.showing and paused, "")
	_check("an empty shift's summary shows 0 deliveries", screen.last_summary.get("deliveries") == 0, "")
	screen._next_shift()
	_main.get_node("ShiftManager").shift_length = GameConfig.SHIFT_LENGTH
	gs.reset()


## Session 22: after the delivery the Delivered card is up, the game is paused, its numbers
## are the real ones, the camera shows the door, and E closes it.
func _check_delivered_card() -> void:
	var card := _main.get_node_or_null("DeliveredCard")
	if card == null:
		_check("DeliveredCard node exists in the scene", false, "")
		return
	var earned: int = _game_state.money - _money_before
	_check("the Delivered card shows after a delivery", card.showing and paused, "")
	_check("the card's total is the money you got", card.shown.get("earned") == earned, "%s Dh" % card.shown.get("earned"))
	_check("the card shows the stars and the villa", card.shown.get("stars") == _game_state.last_result["stars"]
			and card.shown.get("villa") == _order.villa_number, "")
	_check("the camera cuts to the door", get_root_camera() == card._camera, "")
	var key := InputEventAction.new()
	key.action = "interact"
	key.pressed = true
	card._unhandled_input(key)
	_check("E closes the card and the game carries on", not card.showing and not paused
			and get_root_camera() != card._camera, "")


func get_root_camera() -> Camera3D:
	return root.get_camera_3d()


## Closes the Delivered card if it's up (the checks that deliver many orders at once).
func _close_card() -> void:
	var card := _main.get_node_or_null("DeliveredCard")
	if card != null and card.showing:
		card.close()


## Session 19: F gets you off the bike only when it's nearly stopped, and you can only pick up
## and drop off on foot. Called with the bike parked at a door.
func _check_get_off() -> void:
	if _on_foot == null:
		return
	_bike.speed = 5.0  # 18 km/h: too fast to get off
	_check("F doesn't get you off while moving fast", not _on_foot.get_off(), "")
	_bike.speed = 0.0
	_check("on the bike, holding E at the door does nothing", not _delivery._slow_enough() or _delivery.needs_walking, "")
	_check("F gets you off when you're stopped", _on_foot.get_off() and _on_foot.on_foot and _bike.parked, "")
	# This basic hold test skips the walk; the dedicated walk phase exercises movement.
	_on_foot.walker.global_position = _delivery.target_door() + Vector3.UP * 0.05
	_on_foot.walker.velocity = Vector3.ZERO
	_check("the camera and the mini-map follow you on foot", _main.get_node("FollowCamera").target == _on_foot.walker
			and _minimap.bike == _on_foot.walker and _minimap.parked_bike == _bike, "")


## Session 19: the full run. Park 6 m from a villa door, F, walk to the door, hold E, walk
## back, F, ride away.
func _start_walk_check() -> void:
	if _on_foot == null:
		print("      no OnFoot in this scene, walking not checked")
		_start_crash(false)
		return
	var gs: Node = _game_state
	gs.reset()
	var home: int = _delivery.place_builder.villas.filter(func(v): return not PlaceBuilder.is_spot(v))[0]["number"]
	gs.offer_order(_delivery.make_order("pizza", home))
	_delivery.accept()
	gs.pick_up()
	_walk_goal = _delivery.place_builder.villa_door(gs.current_order.villa_number)
	print("      walk check order: ", gs.current_order.describe())
	var villa: Dictionary = {}
	for place in _delivery.place_builder.villas:
		if place["number"] == gs.current_order.villa_number:
			villa = place
	var angle := deg_to_rad(villa["facing"])
	var front := Vector3(sin(angle), 0.0, cos(angle))
	var along := Vector3(front.z, 0.0, -front.x)  # along the street or lane
	_move_bike_to(_walk_goal + along * 6.0)  # 6 m down the street from the door spot
	_bike.rotation = Vector3(0.0, atan2(along.x, along.z), 0.0)
	var phone := _main.get_node("Phone")
	phone._process(0.0)
	var hint: String = phone.get_node("Panel/Margin/Rows/Hint").text
	_check("on the bike 6 m from the door the phone says park near the door", hint == "Park near the door", hint)
	_on_foot.get_off()
	_parked_at = _bike.global_position
	_face(_on_foot.walker, _walk_goal)
	Input.action_press("move_forward")
	_frame = 0
	_phase = "walk_to_door"


## Turns a body so its front (-Z) points at a spot.
func _face(body: Node3D, spot: Vector3) -> void:
	var way := spot - body.global_position
	body.rotation = Vector3(0.0, atan2(-way.x, -way.z), 0.0)


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Session 10: stars from the meters, tips only on 5-star jobs, XP and Rider Level, and a
## rating that averages the last 50 deliveries.
func _check_scoring() -> void:
	var gs: Node = _game_state
	var ok: bool = gs.stars_for(100, 100, 100) == 5.0 and gs.stars_for(50, 100, 100) == 4.5 \
			and gs.stars_for(10, 100, 100) == 3.5 and gs.stars_for(10, 10, 10) == 1.0 and gs.stars_for(50, 50, 10) == 2.5
	_check("star formula matches the PRD examples", ok, "")
	gs.reset()
	var clean := _quick_delivery(100.0, false)
	_check("a clean delivery gets 5 stars", clean["stars"] == 5.0, "%.1f" % clean["stars"])
	var messy := _quick_delivery(20.0, false)
	_check("a messy delivery gets fewer stars", messy["stars"] < 5.0, "%.1f" % messy["stars"])
	var money_before: int = gs.money
	var tips := 0
	var tips_ok := true
	for i in 200:
		var job := _quick_delivery(100.0, false)
		if job["tip"] > 0:
			tips += 1
			tips_ok = tips_ok and job["tip"] >= GameConfig.TIP_MIN and job["tip"] <= GameConfig.TIP_MAX
	_check("streak-boosted tips sometimes come on 5-star jobs, 2 to 15 Dh", tips > 100 and tips < 180 and tips_ok, "%d of 200" % tips)
	var low_tips := 0
	for i in 100:
		low_tips += _quick_delivery(50.0, false)["tip"] + _quick_delivery(100.0, true)["tip"]
	_check("never a tip under 5 stars or on a boring order", low_tips == 0, "")
	_check("tips go into the wallet", gs.money > money_before, "Dh %d" % gs.money)
	_check("Rider Level follows the XP rule", gs.level_for(0) == 1 and gs.level_for(49) == 1 and gs.level_for(50) == 2
			and gs.level_for(124) == 2 and gs.level_for(125) == 3, "level %d with %d XP" % [gs.level(), gs.xp])
	var xp_before: int = gs.xp
	var five := _quick_delivery(100.0, false)
	_check("XP goes up after a delivery", gs.xp == xp_before + five["xp"] and five["xp"] == 20, "+%d XP" % five["xp"])
	gs.reset()
	for i in 10:
		_quick_delivery(10.0, false)  # ten 1-star jobs...
	for i in GameConfig.RATING_WINDOW:
		_quick_delivery(100.0, false)  # ...then 50 five-star jobs push them out of the window
	_check("rating averages the last 50 deliveries", absf(gs.rating() - 5.0) < 0.001, "%.2f" % gs.rating())
	_quick_delivery(10.0, false)
	var want := (49.0 * 5.0 + 1.0) / 50.0
	_check("one bad job only dents the rating", absf(gs.rating() - want) < 0.001, "%.2f" % gs.rating())
	var phone := _main.get_node("Phone")
	phone._on_order_delivered(null)
	phone._process(0.0)
	_check("the phone shows the stars after a delivery", phone.get_node("Panel/Margin/Rows/Result").visible, "")
	_check("the phone shows rating and level", phone.get_node("Panel/Margin/Rows/Profile/Rating").text == "%.1f" % gs.rating()
			and phone.get_node("Panel/Margin/Rows/Profile/Level").text == "Lv %d" % gs.level(), "")
	gs.reset()


## Offers, accepts, picks up and delivers an order at once, with all three meters at
## `meters`. Returns the delivery's result (stars, tip, xp...).
func _quick_delivery(meters: float, boring: bool) -> Dictionary:
	var gs: Node = _game_state
	var order: Object = _delivery.make_order()
	order.boring = boring
	gs.offer_order(order)
	gs.accept_offer()
	gs.pick_up()
	gs.set_meters(meters, meters, meters)
	gs.deliver()
	_close_card()
	return gs.last_result


## Session 8: the meters fill at pickup and drop with time, bumps and hard braking.
## Ends with every meter at 0, so the delivery after it checks a red order can still be delivered.
func _check_meters() -> void:
	if _meters == null:
		_check("Meters node exists in the scene", false, "")
		return
	var gs: Node = _game_state
	var places: Node = _delivery.place_builder
	var want: float = _meters.target_time_for(places.restaurant_door(_order.restaurant_id), places.villa_door(_order.villa_number))
	_check("meters are full at pickup", gs.meter_time >= 99.0 and gs.meter_freshness >= 99.0 and gs.meter_damage == 100.0, "%.1f / %.1f / %.1f" % [gs.meter_time, gs.meter_freshness, gs.meter_damage])
	_check("the target time follows the PRD rule", absf(gs.target_time - want) < 0.01 and gs.target_time > GameConfig.TIME_TARGET_EXTRA,
			"%.0f s" % gs.target_time)
	var panel: Control = _main.get_node("MetersPanel/Panel")
	_check("the meters panel shows while carrying food", panel.visible, "")
	_meters._physics_process(gs.target_time * 0.5)
	var half: float = _meters.time_meter_for(gs.target_time * 0.5, gs.target_time)
	_check("the time meter drains", absf(gs.meter_time - half) < 1.0 and gs.meter_time < 100.0, "%.0f%%" % gs.meter_time)
	_check("on time is green, twice the target is empty", _meters.time_meter_for(10.0, 10.0) == GameConfig.TIME_METER_AT_TARGET
			and _meters.time_meter_for(20.0, 10.0) == 0.0 and _meters.time_meter_for(0.0, 10.0) == 100.0, "")
	_check("freshness drains over time", gs.meter_freshness < 100.0, "%.0f%%" % gs.meter_freshness)
	var damage: float = gs.meter_damage
	_bike.went_over_bump.emit(1.0)
	_check("a speed bump hurts the damage meter", gs.meter_damage < damage, "%.0f%%" % gs.meter_damage)
	damage = gs.meter_damage
	var brakes := [0]
	_bike.hard_braked.connect(func(): brakes[0] += 1)
	_bike.speed = 7.0
	Input.action_press("move_back")
	_bike._update_stamina_and_speed(1.0 / 60.0)
	_bike._update_stamina_and_speed(1.0 / 60.0)
	Input.action_release("move_back")
	_bike._update_stamina_and_speed(1.0 / 60.0)
	_bike.speed = 0.0
	_check("hard braking counts once per press", brakes[0] == 1, "%d" % brakes[0])
	_check("hard braking hurts the damage meter", gs.meter_damage < damage, "%.0f%%" % gs.meter_damage)
	var drain: Dictionary = GameConfig.FRESHNESS_DRAIN
	_check("ice cream melts faster than pizza", drain["ice cream"] > drain["pizza"], "")
	var bump: Dictionary = GameConfig.DAMAGE_SPEED_BUMP
	_check("bubble tea hates speed bumps most", bump["bubble tea"] > bump["pizza"] and bump["bubble tea"] > bump["ice cream"], "")
	_check("meter bands: green, orange, red", _meters.band(61.0) == _meters.Band.GREEN
			and _meters.band(45.0) == _meters.Band.ORANGE and _meters.band(29.0) == _meters.Band.RED, "")
	_meters._physics_process(gs.target_time * 3.0)
	_check("the time meter stops at 0 and the order goes on", gs.meter_time == 0.0 and gs.stage_name() == "TO_VILLA", "")
	gs.set_meters(0.0, 0.0, 0.0)


## The mini-map's pin shows the right text and is drawn inside the map.
func _check_minimap_pin(expected: String) -> void:
	if _minimap == null:
		_check("Minimap node exists in the scene", false, "add ui/minimap.tscn to the scene")
		return
	var view: Control = _minimap._view
	_check("the mini-map is on screen", view.is_visible_in_tree() and view.size.x > 100.0, "%.0f px wide" % view.size.x)
	_check("the mini-map has a pin during the order", _minimap.has_target(), "")
	_check("the pin says " + expected, _minimap.target_label() == expected, _minimap.target_label())
	var pin: Vector2 = _minimap.target_on_map()
	_check("the pin is inside the mini-map", Rect2(Vector2.ZERO, view.size).has_point(pin), "at %s" % pin)


## The mini-map turns with the bike: straight ahead is always up, your right is right.
func _check_minimap_turns() -> void:
	if _minimap == null:
		return
	var middle: Vector2 = _minimap._view.size * 0.5
	var old_turn := _bike.rotation.y
	var ok := true
	for turn in [0.0, 1.2, -2.5]:
		_bike.rotation.y = turn
		var ahead: Vector2 = _minimap.world_to_map(_bike.global_position - _bike.global_basis.z * 20.0) - middle
		var right: Vector2 = _minimap.world_to_map(_bike.global_position + _bike.global_basis.x * 20.0) - middle
		ok = ok and ahead.y < -10.0 and absf(ahead.x) < 0.5 and right.x > 10.0 and absf(right.y) < 0.5
	_bike.rotation.y = old_turn
	_check("the mini-map turns with the bike (ahead is up)", ok, "")
	var far: Vector2 = _minimap.pin_spot(middle + Vector2(5000.0, -3000.0))
	var inset := GameConfig.MINIMAP_EDGE_INSET
	_check("a stop far away is pinned to the round mini-map's edge",
			absf(far.distance_to(middle) - (middle.x - inset)) < 0.5, "at %s" % far)


## Some orders come with a note from the customer, most don't, and every note is from the list.
func _check_notes() -> void:
	var with_note := 0
	var all_listed := true
	for i in 200:
		var note: String = _delivery.make_order().note
		if note != "":
			with_note += 1
			all_listed = all_listed and (GameConfig.ORDER_NOTES.has(note) or note == GameConfig.ORDER_LEAVE_AT_DOOR_NOTE)
	_check("some orders have a note, not all", with_note > 20 and with_note < 180, "%d of 200" % with_note)
	_check("every note comes from the list in game_config.gd", all_listed, "")


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
	# Session 33's check waits a few physics frames: nothing else runs meanwhile.
	_phase = "finishing"
	for action in ACTIONS:
		Input.action_release(action)
	_check_sound()
	_check_session28()
	_check_session26()
	_check_session27()
	_check_session29()
	_check_session31()
	_check_session30()
	await _check_session33()
	await _check_life_meets_events()
	_check_session32()
	await _check_venue_handoffs()
	_check_shop_buys()
	_check_saving()
	_check_polish_hooks()
	_check_look_polish()
	for action in ACTIONS:
		Input.action_release(action)
	_phase = "done"
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)


## Session 59: buy one thing in each shop from their new insides (Pedal Point Bikes and Dune
## Drip): the shop screen opens (the bike on Pedal Point's round stand makes way for yours),
## the item goes in the cart, checkout pays for it and puts it on, and leaving brings it back.
func _check_shop_buys() -> void:
	var shops: Node = _main.get_node_or_null("ShopController")
	if shops == null:
		return
	var gs: Node = _game_state
	for want in [["bikes", "paint_sunset"], ["clothes", "caps_teal"]]:
		gs.reset()
		gs.money = 200
		var price: int = GearCatalog.price(GearCatalog.find(want[1]))
		var opened: bool = shops.open_shop(want[0])
		var stands := get_nodes_in_group("shop_stand_bike")
		var made_way: bool = want[0] != "bikes" or (not stands.is_empty() and stands.all(func(n): return not n.visible))
		var added: bool = opened and shops.cart.add(want[1])["ok"]
		var bought: bool = added and shops.checkout()["ok"]
		shops.close_shop()
		var back: bool = stands.all(func(n): return n.visible)
		_check("buy one thing at %s" % want[0], opened and made_way and bought and back and not paused
				and gs.money == 200 - price and want[1] in gs.equipped_cosmetics.values(),
				"opened %s, stand bike made way %s, bought %s, money %d, equipped %s" % [opened, made_way, bought, gs.money, gs.equipped_cosmetics])
	gs.reset()


## Sessions 41–42: drive the real on-foot handoff at the school gate and both receptions.
## The normal delivery test already exercises accepting an offer and holding E at pickup.
func _check_venue_handoffs() -> void:
	var places: PlaceBuilder = _delivery.place_builder
	if not places.data.get_script_constant_map().has("INSTITUTE"):
		return
	var gs: Node = _game_state
	var card: Node = _main.get_node("DeliveredCard")
	var counter: Node = _main.get_node("CounterPanel")
	seed(41042)
	for number in [903, 904]:
		var doorstep := 0
		for sample in 80:
			var order: Order = _delivery.make_order("pizza", number)
			if order.leave_at_door:
				doorstep += 1
		_check("indoor reception orders always hand over to staff at %s" % number, doorstep == 0,
				"%d doorstep orders out of 80" % doorstep)
	for number in [GameConfig.SCHOOL_SPOT, 903, 904]:
		gs.reset()
		var order: Order = _delivery.make_order("pizza", number)
		if number == GameConfig.SCHOOL_SPOT:
			order.leave_at_door = false  # exercise the outdoor gate with a recipient present
		_check("start a delivery to " + order.address,
				order.villa_number == number and gs.offer_order(order) and _delivery.accept() and gs.pick_up(), "")
		_move_bike_to(places.villa_approach(number))
		var target: Vector3 = places.villa_door(number)
		_face(_bike, target)
		await physics_frame
		Input.action_press("interact")
		for frame in STEPS.hold:
			await physics_frame
		Input.action_release("interact")
		await physics_frame
		_check("the bike approach does not complete the handoff at " + order.address,
				gs.stage_name() == "TO_VILLA", "")
		var dismounted: bool = _on_foot.get_off()
		var distance: float = _on_foot.walker.global_position.distance_to(target)
		var walk_frames := ceili((distance / (GameConfig.WALK_SPEED_KMH / 3.6) + 2.0) * Engine.physics_ticks_per_second)
		_face(_on_foot.walker, target)
		Input.action_press("move_forward")
		for frame in walk_frames:
			if _delivery.is_near_target():
				break
			await physics_frame
		Input.action_release("move_forward")
		_check("the rider can reach the handoff point on foot at " + order.address,
				dismounted and _delivery.target_door() == target and _delivery.is_near_target(),
				"%.1f m from target" % _on_foot.walker.global_position.distance_to(target))
		if number != GameConfig.SCHOOL_SPOT:
			# Session 65: give the panel a few frames when the machine is busy (it was flaky).
			for wait in 10:
				await process_frame
				if counter != null and counter._panel.visible:
					break
			_check("the staffed counter panel opens at " + order.address,
					counter != null and counter._panel.visible and counter._panel.heading.text == order.address
					and counter._staff != null, "")
		Input.action_press("interact")
		for frame in STEPS.hold:
			await physics_frame
		Input.action_release("interact")
		_check("holding E delivers and stamps " + order.address,
				card.showing and card.shown.get("villa") == number and gs.history.size() == 1
				and gs.money > 0 and gs.visited_venues.get(str(number)) == order.address, "")
		_close_card()
		_on_foot.get_on(true)
	gs.reset()


## Session 28: the sun follows the clock (morning, noon and sunset differ, sunset is the
## lowest and warmest), and the Graphics setting (Low / Medium / High) switches SSAO, haze
## and shimmer. It never saves the settings file: it sets the values, calls Settings.apply()
## and puts them back afterwards.
func _check_session28() -> void:
	var cycle := _main.get_node_or_null("SunCycle")
	_check("the map has a SunCycle node", cycle != null, "")
	if cycle == null:
		return
	var sun: DirectionalLight3D = cycle.sun
	var env: Environment = cycle.world_environment.environment
	var looks := {}
	for hour in [8.0, 12.0, 18.0]:
		cycle.apply_hour(hour)
		looks[hour] = {"height": rad_to_deg(-sun.rotation.x), "turn": rad_to_deg(sun.rotation.y),
				"blue": sun.light_color.b, "sky": cycle._sky.sky_horizon_color if cycle._sky else Color.BLACK}
	var detail := "height 08:00 %.0f, 12:00 %.0f, 18:00 %.0f degrees" % [looks[8.0]["height"], looks[12.0]["height"], looks[18.0]["height"]]
	_check("the sun is highest at noon and lowest at sunset",
			looks[12.0]["height"] > looks[8.0]["height"] and looks[8.0]["height"] > looks[18.0]["height"], detail)
	_check("the sun moves from east to west", looks[8.0]["turn"] > looks[18.0]["turn"], "")
	_check("sunset is the warmest light, noon the whitest",
			looks[18.0]["blue"] < looks[8.0]["blue"] and looks[8.0]["blue"] < looks[12.0]["blue"],
			"blue 08:00 %.2f, 12:00 %.2f, 18:00 %.2f" % [looks[8.0]["blue"], looks[12.0]["blue"], looks[18.0]["blue"]])
	_check("the sky colour changes from noon to sunset", looks[12.0]["sky"] != looks[18.0]["sky"], "")
	var before: int = Settings.graphics
	var seen := {}
	for level in [0, 1, 2]:
		Settings.graphics = level
		Settings.apply()  # applies straight away, without saving the settings file
		cycle.apply_hour(12.5)
		seen[level] = {"ssao": env.ssao_enabled, "haze": env.fog_enabled, "glow": env.glow_enabled,
				"shimmer": cycle.get_node_or_null("HeatShimmer") != null, "shadows": sun.directional_shadow_max_distance,
				"msaa": get_root().msaa_3d, "fxaa": get_root().screen_space_aa, "splits": sun.directional_shadow_mode}
	_check("Low: no SSAO, haze or shimmer",
			not seen[0]["ssao"] and not seen[0]["haze"] and not seen[0]["shimmer"], str(seen[0]))
	_check("Medium: SSAO, haze and glow on, shimmer removed",
			seen[1]["ssao"] and seen[1]["haze"] and seen[1]["glow"] and not seen[1]["shimmer"], str(seen[1]))
	_check("High: visual effects on without heat shimmer", seen[2]["ssao"] and seen[2]["haze"] and not seen[2]["shimmer"], str(seen[2]))
	_check("shadows reach further on higher settings",
			seen[0]["shadows"] < seen[1]["shadows"] and seen[1]["shadows"] < seen[2]["shadows"], "")
	_check("Session 52: Low uses FXAA, Medium and High use MSAA 4x",
			seen[0]["fxaa"] == Viewport.SCREEN_SPACE_AA_FXAA and seen[1]["msaa"] == Viewport.MSAA_4X
			and seen[2]["msaa"] == Viewport.MSAA_4X, "")
	_check("Session 52: 4 shadow cascades on Medium and High",
			seen[1]["splits"] == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			and seen[2]["splits"] == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "")
	_check("Session 52: a graphics level is picked on first start", Settings.detect_graphics() in [0, 1, 2], "")
	cycle.apply_hour(8.0)
	_check("no heat shimmer in the morning", cycle.get_node_or_null("HeatShimmer") == null, "")
	Settings.graphics = before
	Settings.apply()
	cycle.apply_hour(cycle.hour_now())
	var panel := SettingsPanel.new()
	root.add_child(panel)
	_check("Settings has the Graphics option (Low / Medium / High)", panel.graphics_option != null
			and panel.graphics_option.item_count == 3 and panel.graphics_option.selected == Settings.graphics, "")
	panel.free()


## Session 26: the house kit. Every Wahat home is a built house of its kind (10 courtyard,
## 1 garden and 1 signature villa per cluster) showing its door number, homes look different
## but the same every time, each is one merged mesh, nothing from a house stands on a door
## spot or a lane, and the bilingual cluster signs are up. Other maps: skipped.
func _check_session26() -> void:
	var places: Node = _main.get_node_or_null("PlaceBuilder") if is_instance_valid(_main) else null
	if places == null or not places.data.get_script_constant_map().has("CLUSTER_NAMES"):
		print("      not Wahat Al Shams, the house checks skipped")
		return
	var data: Dictionary = places.data.get_script_constant_map()
	var homes: Array = places.villas.filter(func(v): return v.get("kind", "") != "spot")
	var kinds := {}
	var looks := {}
	var good := 0
	var most_meshes := 0
	for villa in homes:
		var home: Node = places.find_child("Villa%d" % villa["number"], true, false)
		if home == null:
			continue
		var number: Node = home.get_node_or_null("Number")
		if home.get_meta("kind", "") == villa["kind"] and home.get_meta("batched", false) and home.get_node_or_null("House") == null \
				and number is Label3D and number.text == str(villa["house"]):
			good += 1
		var key: String = "%s %s" % [villa["cluster"], villa["kind"]]
		kinds[key] = kinds.get(key, 0) + 1
		looks[home.get_meta("extras", "")] = true
		most_meshes = maxi(most_meshes, home.find_children("*", "MeshInstance3D", true, false).size())
	_check("every home is a house of its kind with its door number", good == homes.size() and good > 0,
			"%d of %d" % [good, homes.size()])
	var split_ok := true
	for cluster in data["CLUSTER_NAMES"]:
		if kinds.get(cluster + " courtyard", 0) != 90 or kinds.get(cluster + " garden", 0) != 8 \
				or kinds.get(cluster + " signature", 0) != 2:
			split_ok = false
	_check("each cluster: 90 courtyard, 8 garden, 2 signature villas", split_ok, "%s" % [kinds])
	_check("homes look different from each other", looks.size() >= 80, "%d looks" % looks.size())
	var first: Node = places.find_child("Villa%d" % homes[0]["number"], true, false)
	var again: Node = load("res://scripts/villa_builder.gd").build(homes[0], places.villa_size)
	_check("a home looks the same every time it's built", again.get_meta("extras") == first.get_meta("extras"),
			again.get_meta("extras"))
	again.free()
	var housing := places.get_node_or_null("HousingRows")
	_check("500 homes share 20 detailed row meshes and 20 distant meshes", most_meshes == 0 and housing != null and housing.near_meshes.size() == 20 and housing.far_meshes.size() == 20 and housing.home_count == 500, "row batching")
	# Nothing solid from a house may stand on a door spot or on a road or lane.
	var space := _bike.get_world_3d().direct_space_state
	var ball := SphereShape3D.new()
	ball.radius = 1.0
	var in_the_way := []
	for villa in homes:
		var door: Vector3 = places.villa_door(villa["number"])
		if _house_hits(space, ball, Transform3D(Basis(), door + Vector3.UP * 0.9)) > 0:
			in_the_way.append(villa["address"])
	for road in data["ROADS"]:
		var strip := BoxShape3D.new()
		var width: float = road.get("width", data["ROAD_WIDTH"])
		strip.size = Vector3(width, 1.0, road["from"].distance_to(road["to"]) + width)
		var way: Vector2 = road["to"] - road["from"]
		var middle: Vector2 = (road["from"] + road["to"]) * 0.5
		var spot := Transform3D(Basis(Vector3.UP, atan2(way.x, way.y)), Vector3(middle.x, 0.9, middle.y))
		if _house_hits(space, strip, spot) > 0:
			in_the_way.append(road["name"])
	_check("no house part on a door spot or a lane", in_the_way.is_empty(), "%s" % [in_the_way])
	var signs: Node = _main.get_node_or_null("WahatBuilder/ClusterSigns")
	var signed := {}
	if signs != null:
		for board in signs.get_children():
			var id: String = String(board.name).get_slice("_", 1)
			if _has_arabic_label(board) and _has_label_text(board, data["CLUSTER_NAMES"].get(id, "?")) \
					and _has_label_text(board, "Cluster " + id.substr(1)):
				signed[id] = signed.get(id, 0) + 1
	_check("bilingual cluster signs at the lane ends of every cluster",
			signed.size() == data["CLUSTER_NAMES"].size() and signed.values().all(func(n): return n >= 2), "%s" % [signed])
	# Session 53: the layout check (nothing in a road, on a bed or a pool, lanes stop at the
	# ring road, bridges over the stream, benches facing the right way).
	for line in preload("res://tests/layout_test.gd").check_map(data, _main):
		_check("layout: " + line[1], line[0], "")
	# Session 57: the Plaza checks (shop order, low shops with joined flats, passages,
	# logos and bilingual signs, nothing overlapping). Full version: tests/plaza_test.gd.
	if data.has("PLAZA_ROWS"):
		for line in preload("res://tests/plaza_test.gd").check_world(data, _main):
			_check("plaza: " + line[1], line[0], "")

	# Session 62: the car parks (rows, solar roofs, kerbs). tests/carpark_test.gd checks the rest.
	var parks: Node = _main.get_node_or_null("DistrictTraffic/CarParks")
	if data.has("CAR_PARKS") and GameConfig.CARPARK_ROWS:
		var roofs := 0
		for park: Dictionary in data["CAR_PARKS"]:
			roofs += park["roofs"].size()
		var built := 0
		if parks != null:
			for child in parks.get_children():
				built += 1 if String(child.name).begins_with("SolarRoof_") else 0
		_check("every car park row has a solar roof, with kerbs round the car parks and the ring road",
				built == roofs and roofs > 0 and parks.get_node_or_null("RingRoadKerbs") != null, "%d of %d roofs" % [built, roofs])


## How many house parts (bodies called Villa...) a shape at this spot touches.
func _house_hits(space: PhysicsDirectSpaceState3D, shape: Shape3D, spot: Transform3D) -> int:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = spot
	var count := 0
	for hit in space.intersect_shape(query, 32):
		if String((hit["collider"] as Node).name).begins_with("Villa"):
			count += 1
	return count


## Session 27: the Plaza, the spine and the landmarks. The bike rode down into the sunken
## square, the new shops and the farm stall each give a working order (to a reachable door),
## the mosque never gets an order, and the school and stables only use their one spot.
func _check_session27() -> void:
	var places: Node = _main.get_node_or_null("PlaceBuilder")
	if places == null or not places.data.get_script_constant_map().has("SCHOOL"):
		print("      not Wahat Al Shams, Session 27 checks skipped")
		return
	var data: Dictionary = places.data.get_script_constant_map()
	paused = false
	_check("the bus-stop ride stays supported by the world", _lowest_y > -1.0, "lowest %.2f m" % _lowest_y)
	var plaza: Dictionary = data["PLAZA"]
	var floor_spot := Vector3(plaza["centre"].x + plaza["floor_radius"] - 2.0, 5.0, plaza["centre"].y)
	var hit := _bike.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(floor_spot, floor_spot + Vector3.DOWN * 10.0, 1, [_bike.get_rid()]))
	_check("the Plaza floor is sunken (lower than the street)", not hit.is_empty() and hit["position"].y < -0.3,
			"%s" % [hit.get("position", "nothing hit")])
	var built := ["PlazaBuilder/Fountain", "LandmarkBuilder/School", "LandmarkBuilder/SchoolBooth",
			"LandmarkBuilder/StableOffice", "LandmarkBuilder/Stables", "LandmarkBuilder/BuildingSite/Crane",
			"DecorBuilder/Mosque"]
	for path in built:
		_check(path.get_file() + " was built", _main.get_node_or_null(path) != null, path)
	var domes := _main.get_node("SpineBuilder").get_children().filter(func(n): return n.name.begins_with("Dome"))
	_check("the spine has 6 greenhouse domes", domes.size() == 6, "%d" % domes.size())
	var site_sign: Node = _main.get_node("LandmarkBuilder/BuildingSite")
	_check("the building site sign says Phase 2 coming soon in Arabic and English",
			_has_arabic_label(site_sign) and _has_label_text(site_sign, "Phase 2 coming soon"), "")
	# One order from each new pickup spot, delivered: the food has numbers in game_config.gd.
	var gs: Node = _game_state
	# Session 58: Bread & Zaatar sells bread, manakish and fatayer; Spill the Brew coffee, pastries and cake.
	var foods := {"shawarma": ["shawarma"], "bakery": ["manakish", "khubz bread", "fatayer"] if GameConfig.FOOD_CHANGES_ON else ["cake", "manakish"],
			"boba": ["iced latte", "flat white", "croissant", "cake"] if GameConfig.FOOD_CHANGES_ON else ["bubble tea", "coffee"], "market": ["groceries"],
			"farm": ["farm juice", "salad box"], "thai": ["pad thai"], "sushi": ["sushi"],
			"tacos": ["tacos"], "burger": ["burgers"]}
	var start: Vector3 = data["START"]["position"]
	for id in foods:
		gs.reset()
		var order: Object = _delivery.make_order(id, 101)
		var door: Vector3 = places.restaurant_door(id)
		var reachable: bool = _grid != null and _grid.can_reach(Vector2(start.x, start.z), Vector2(door.x, door.z))
		var tables := [GameConfig.FRESHNESS_DRAIN, GameConfig.DAMAGE_SPEED_BUMP, GameConfig.DAMAGE_HARD_BRAKE,
				GameConfig.DAMAGE_COLLISION, GameConfig.DAMAGE_CRITTER]
		var tuned := tables.all(func(t): return t.has(order.food))
		var money: int = gs.money
		var done: bool = gs.offer_order(order) and gs.accept_offer() and gs.pick_up() and gs.deliver()
		_close_card()
		_check("an order from %s works" % order.restaurant_name, order.restaurant_id == id and order.food in foods[id]
				and reachable and tuned and done and gs.money > money, "%s, door reachable %s" % [order.describe(), reachable])
	# Lots of random orders: never to or from the mosque; the school and stables only use their spot.
	var plots := {}
	for plot in data["PLOTS"]:
		plots[plot["name"]] = plot["area"]
	var mosque: Rect2 = plots["Mosque"]
	var school: Rect2 = data["SCHOOL"]["area"].grow(8.0)  # the booth is just outside the fence
	var stables: Rect2 = plots["Stables"].grow(2.0)
	var to_mosque := 0
	var wrong_spot := 0
	var spots := {}
	gs.reset()
	for i in 300:
		var order: Object = _delivery.make_order()
		var to: Vector3 = places.villa_door(order.villa_number)
		var from: Vector3 = places.restaurant_door(order.restaurant_id)
		if mosque.grow(3.0).has_point(Vector2(to.x, to.z)) or mosque.grow(3.0).has_point(Vector2(from.x, from.z)):
			to_mosque += 1
		if school.has_point(Vector2(to.x, to.z)) and order.villa_number != 901:
			wrong_spot += 1
		if stables.has_point(Vector2(to.x, to.z)) and order.villa_number != 902:
			wrong_spot += 1
		if order.villa_number >= 900:
			spots[order.villa_number] = true
	_check("300 orders: the mosque never gets one", to_mosque == 0, "%d" % to_mosque)
	_check("school orders only go to the gate booth, stables orders only to the office", wrong_spot == 0
			and spots.has(901) and spots.has(902), "%d wrong, spots used %s" % [wrong_spot, spots.keys()])
	for number in [901, 902, 903, 904]:
		gs.reset()
		var order: Object = _delivery.make_order("pizza", number)
		var done: bool = gs.offer_order(order) and gs.accept_offer() and gs.pick_up() and gs.deliver()
		_close_card()
		_check("a delivery to %s works" % order.address, done and order.villa_number == number, order.describe())
	gs.reset()
	paused = false


## Session 29: animated people, the real bike (pedals, handlebars, kickstand) and the bell.
func _check_session29() -> void:
	var rider: Node3D = _bike.get_node("Model/Rider")
	var all_moves := true
	for action in ["idle", "walk", "jog", "wave", "pedal", "lie"]:
		all_moves = all_moves and rider.can_do(action)
	_check("the rider has idle, walk, jog, wave, pedal and lie", all_moves, "")
	_check("the rider pedals on the bike", rider.action == "pedal", rider.action)
	var walker_model: Node3D = _main.get_node("Walker/Model")
	_check("the rider on foot is an animated person", walker_model.can_do("walk") and walker_model.can_do("jog"), "")
	# Customers in all 5 outfits, and the new types for later sessions.
	var looks: Script = load("res://scripts/people_looks.gd")
	var made := 0
	var folks: Array = []
	for outfit in 5:
		folks.append(looks.resident(outfit))
	folks.append_array([looks.teacher(), looks.school_kid(), looks.horse_rider(), looks.groom()])
	for person: Node3D in folks:
		if person.can_do("walk") and person.can_do("wave") and person.can_do("idle"):
			made += 1
		person.free()
	_check("residents, teachers, kids, riders and grooms walk, wave and stand", made == 9, "%d of 9" % made)
	var customer: Node3D = load("res://scripts/customer.gd").new()
	_main.add_child(customer)
	customer.setup("Shukran!")
	_check("a customer is an animated person who can wave", customer.person != null and customer.person.can_do("wave"), "")
	customer.free()
	# The pedals turn faster at higher speed.
	var keep := _bike.global_transform
	_bike.set_parked(false)
	_bike.speed = 2.0
	var before: float = _bike.crank_angle
	_bike._spin_wheels(0.1)
	var slow: float = absf(_bike.crank_angle - before)
	_bike.speed = 6.0
	before = _bike.crank_angle
	_bike._spin_wheels(0.1)
	var fast: float = absf(_bike.crank_angle - before)
	_check("the pedals turn faster at higher speed", slow > 0.0 and fast > slow * 2.5, "%.2f then %.2f rad" % [slow, fast])
	_bike.speed = 0.0
	# The handlebars turn when you steer.
	_bike._steer = 1.0
	_bike._move_parts(1.0)
	var turned: float = _bike.get_node("Model/Fork").rotation.y
	_bike._steer = 0.0
	_bike._move_parts(1.0)
	_check("the handlebars turn when you steer", turned > 0.2, "%.0f degrees" % rad_to_deg(turned))
	# The kickstand drops when you get off, and folds up when you ride.
	_bike.set_parked(true)
	_bike._move_parts(1.0)
	var down: float = _bike.kickstand_down
	var stand_angle: float = _bike.get_node("Model/Kickstand").rotation.x
	_check("the kickstand is down when parked, and the rider is off", down == 1.0 and stand_angle > 0.0 and not rider.visible,
			"%.1f, %.0f degrees" % [down, rad_to_deg(stand_angle)])
	_bike.set_parked(false)
	_bike._move_parts(1.0)
	_check("the kickstand folds up when riding", _bike.kickstand_down == 0.0 and rider.visible, "")
	# B rings the bell: the ring plays, and a cat nearby gets out of the way.
	var b_key := false
	for event in InputMap.action_get_events("ring_bell"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_B:
			b_key = true
	_check("B is the bell key", b_key, "")
	var sounds := _main.get_node("Sounds")
	var cat: Node3D = null
	for critter in get_nodes_in_group("critter"):
		if String(critter.name).begins_with("Cat"):
			cat = critter
			break
	if cat != null:
		cat.scared_left = 0.0
		_bike.global_position = cat.global_position + Vector3(3, 0, 0)
	_bike.ring_bell()
	_check("B plays the bell", sounds.last_played == "ring", sounds.last_played)
	if cat != null:
		_check("a cat near the bell moves aside", cat.scared_left > 0.0, "%.1f s" % cat.scared_left)
	else:
		print("      no cats in this scene, bell scare not checked")
	_bike.global_transform = keep
	# Parked cars are the CC0 models.
	var car := _main.find_child("ParkedCar_0", true, false)
	if car != null:
		# Session 62: car park cars are drawn together by CarParkCars (same CC0 models).
		var batched: bool = car.get_meta("drawn_by", "") == "CarParkCars" and _main.find_child("ParkedCarLooks", true, false) != null
		_check("parked cars use the CC0 car models", car.get_node_or_null("Model") != null or batched, "")
	var credits := FileAccess.get_file_as_string("res://CREDITS.md")
	_check("the people and car packs are credited", "Quaternius" in credits and "Car Kit" in credits, "")


## Session 31: juice. Sprinting widens the camera and shows speed lines, and both go back
## afterwards; a new order makes the phone buzz (with the buzz sound); a delivery pops the
## stars and coins on the Delivered card; the tyre dust shows on sand and when braking hard,
## not on the road; Low graphics has fewer dust puffs than High.
func _check_session31() -> void:
	var gs: Node = _game_state
	# Sprinting: a wider camera and speed lines.
	var camera: Camera3D = _main.get_node("FollowCamera")
	var keep_target: Node3D = camera.target
	camera.target = _bike
	_bike.sprinting = true
	for i in 30:
		camera._process(0.05)
	var wide: float = camera.fov
	var lines: float = camera.speed_lines.strength
	_bike.sprinting = false
	for i in 60:
		camera._process(0.05)
	_check("sprinting widens the camera and shows speed lines", wide > camera.base_fov + 4.0 and lines > 0.8,
			"%.1f degrees (normal %.1f), lines %.2f" % [wide, camera.base_fov, lines])
	_check("the camera and the speed lines go back after sprinting",
			absf(camera.fov - camera.base_fov) < 0.3 and camera.speed_lines.strength < 0.05,
			"%.1f degrees, lines %.2f" % [camera.fov, camera.speed_lines.strength])
	camera.target = keep_target
	# A new order: the phone shakes and buzzes.
	var phone: Node = _main.get_node("Phone")
	var sounds: Node = _main.get_node("Sounds")
	gs.reset()
	var buzzes: int = phone.buzzes
	var buzz_sounds: int = sounds.play_counts.get("buzz", 0)
	_delivery.offer_now()
	_check("a new order makes the phone buzz", phone.buzzes == buzzes + 1 and phone._buzz_tween != null
			and phone._buzz_tween.is_valid(), "%d buzz" % (phone.buzzes - buzzes))
	_check("the buzz sound plays (and the ping)", sounds.play_counts.get("buzz", 0) == buzz_sounds + 1
			and sounds.last_played == "ping", sounds.last_played)
	# A delivery: the stars pop in one by one, then the coins fly out.
	var card: Node = _main.get_node("DeliveredCard")
	_delivery.accept()
	gs.pick_up()
	var pops: int = card.pops
	var pop_sounds: int = sounds.play_counts.get("pop", 0)
	var coin_sounds: int = sounds.play_counts.get("coins", 0)
	gs.deliver()
	var stars: float = gs.last_result["stars"]
	var stars_at_start: float = card._stars.stars
	if card._pop_tween != null:
		card._pop_tween.custom_step(5.0)  # skip ahead to the end of the pops
	var icons := get_nodes_in_group("pop_icon").size()
	_check("the Delivered card pops the stars and the coins", card.showing and stars_at_start == 0.0
			and card._stars.stars == stars and card.pops == pops + ceili(stars) + 1 and icons > 0,
			"%.1f stars, %d pops, %d icons" % [stars, card.pops - pops, icons])
	_check("the pops play their sounds", sounds.play_counts.get("pop", 0) == pop_sounds + ceili(stars)
			and sounds.play_counts.get("coins", 0) == coin_sounds + 1, "")
	_close_card()
	_check("closing the card stops the pops", card._pop_tween == null, "")
	gs.reset()
	# Tyre dust: on sand when riding, on any ground when braking hard, not on the road.
	var dust: GPUParticles3D = _bike.get_node("TyreDust")
	var keep := _bike.global_transform
	var keep_parked: bool = _bike.parked
	_bike.set_parked(false)
	_bike.fallen_left = 0.0
	_bike.wrecked = false
	_bike.speed = 6.0
	var ground: Script = load("res://scripts/ground_type.gd")
	var sand := Vector3.INF
	var road := Vector3.INF
	for x in range(-180, 181, 6):
		for z in range(-140, 141, 6):
			var on_sand: bool = ground.is_sand(dust._map, Vector2(x, z))
			if on_sand and sand == Vector3.INF:
				sand = Vector3(x, keep.origin.y, z)
			if not on_sand and road == Vector3.INF:
				road = Vector3(x, keep.origin.y, z)
	dust._brake_left = 0.0
	if sand != Vector3.INF:
		_bike.global_position = sand
		dust._check_left = 0.0
		dust._physics_process(0.016)
		_check("dust puffs from the tyre when riding on sand", dust.on_sand and dust.emitting, "at %s" % sand)
	else:
		print("      no sand on this map, sand dust not checked")
	if road != Vector3.INF:
		_bike.global_position = road
		dust._check_left = 0.0
		dust._physics_process(0.016)
		_check("no dust when riding on the road", not dust.on_sand and not dust.emitting, "at %s" % road)
	else:
		print("      no roads on this map (all sand), road check skipped")
	_bike.hard_braked.emit()
	dust._physics_process(0.016)
	_check("braking hard makes a dust puff", dust.emitting and dust.amount_ratio == 1.0, "")
	_bike.speed = 0.0
	dust._brake_left = 0.0
	dust._physics_process(0.016)
	_bike.global_transform = keep
	if keep_parked:
		_bike.set_parked(true)
	# Fewer puffs on Low graphics (never saves the settings file).
	var keep_graphics := Settings.graphics
	Settings.graphics = 0
	Settings.apply()
	var low: int = dust.amount
	Settings.graphics = 2
	Settings.apply()
	var high: int = dust.amount
	Settings.graphics = keep_graphics
	Settings.apply()
	_check("Low graphics has fewer dust puffs than High", low < high, "%d vs %d" % [low, high])
	var files := 0
	for file in ["buzz", "pop", "coins"]:
		var stream := load("res://assets/audio/%s.wav" % file) as AudioStreamWAV
		if stream != null and stream.get_length() > 0.1:
			files += 1
	_check("the buzz, pop and coins sounds load", files == 3, "%d of 3" % files)


## Session 30: life on the map. Everything in the data lists was built, nothing's route goes
## through a wall, buggies drive along their route and stop for the bike (without pushing
## it), then turn round if it stays; horses, walkers, ducks and donkeys move; palms sway and
## the water moves; Low shows fewer things than High. Other maps: skipped.
func _check_session30() -> void:
	var life: Node = _main.get_node_or_null("LifeBuilder")
	if life == null:
		print("      no LifeBuilder on this map, Session 30 checks skipped")
		return
	var data: Dictionary = life.data.get_script_constant_map()
	var want := 0
	for list in ["BUGGIES", "HORSE_RIDERS", "PEOPLE_ROUTES", "GARDENERS", "PLAY_KIDS", "DUCKS"]:
		want += data[list].size()
	_check("every buggy, horse, person, kid and duck in the data was built", life.movers.size() == want,
			"%d of %d" % [life.movers.size(), want])
	# Nothing walks through walls: every route, sampled each metre, is clear on the map scan.
	if _grid != null:
		var inside := {}
		for mover in life.movers:
			var pts: Array = mover.points
			if pts.size() == 1:
				pts = [pts[0], pts[0]]
			for i in pts.size() - (0 if mover.loop else 1):
				var a: Vector3 = pts[i]
				var b: Vector3 = pts[(i + 1) % pts.size()]
				for k in int(a.distance_to(b)) + 1:
					var spot := a.move_toward(b, float(k))
					if not _grid.is_free(Vector2(spot.x, spot.z)) and not inside.has(mover.name):
						inside[mover.name] = spot
		_check("no buggy, horse or walker route goes through a wall or building", inside.is_empty(), str(inside))
	var keep := _bike.global_transform
	var was_parked: bool = _bike.parked
	_bike.set_parked(true)
	_move_bike_to(data["START"]["position"])
	# A buggy drives along its route.
	var buggy: Node3D = life.get_node("Buggy_0")
	# Live traffic starts at random points. A buggy near an endpoint can correctly
	# spend this whole two-second probe in LIFE_END_PAUSE. Start on a long straight,
	# and test only the bike obstacle we place, not unrelated random traffic/walkers.
	var keep_watch: Array[Node3D] = buggy.watch.duplicate()
	var probe_watch: Array[Node3D] = [_bike]
	var keep_exclude: Array[RID] = buggy._ahead.exclude.duplicate()
	var probe_exclude: Array[RID] = keep_exclude.duplicate()
	for other in get_nodes_in_group("critter") + get_nodes_in_group("road_works"):
		if other is CollisionObject3D and other != buggy:
			probe_exclude.append(other.get_rid())
	buggy.watch = probe_watch
	buggy._ahead.exclude = probe_exclude
	buggy.scared_left = 0.0
	buggy._pause_left = 0.0
	buggy._blocked = 0.0
	if buggy.has_method("drive_route"):  # Session 64: roaming buggies get a long straight lane for this probe
		buggy.drive_route(_long_buggy_stretch(life.buggy_roads, 30.0))
	buggy.start_at(0, 0.35, true)  # start mid-segment, not at a random endpoint pause
	var start: Vector3 = buggy.position
	for i in 60:
		buggy._physics_process(1.0 / 30.0)
	var moved: float = buggy.position.distance_to(start)
	_check("a golf buggy drives along its route", moved > 2.0 and buggy.distance_to_route() < 0.2,
			"%.1f m, %.2f m off the route" % [moved, buggy.distance_to_route()])
	# It stops for the bike parked in front of it, and doesn't push it.
	buggy._pause_left = 0.0
	var ahead: Vector3 = buggy.heading()
	_move_bike_to(buggy.position + ahead * (buggy.size.z * 0.5 + 2.0))
	var bike_spot := _bike.global_position
	var at: Vector3 = buggy.position
	for i in 30:
		buggy._physics_process(1.0 / 30.0)
	_check("a buggy stops and waits when the bike is in the way", buggy.position.distance_to(at) < 0.01
			and _bike.global_position.distance_to(bike_spot) < 0.01, "moved %.2f m" % buggy.position.distance_to(at))
	for i in int(GameConfig.LIFE_GIVE_UP_TIME * 30.0) + 90:
		buggy._physics_process(1.0 / 30.0)
	_check("if the bike stays, the buggy turns round and drives off", buggy.position.distance_to(_bike.global_position) > at.distance_to(bike_spot) + 1.0
			and _bike.global_position.distance_to(bike_spot) < 0.01, "%.1f m away" % buggy.position.distance_to(_bike.global_position))
	buggy.watch = keep_watch
	buggy._ahead.exclude = keep_exclude
	_move_bike_to(data["START"]["position"])
	# Horses, walkers, kids and ducks move too.
	var still := []
	for name in ["Horse_0", "Person_0", "Person_2", "Kid_0", "Duck_0"]:
		var thing: Node3D = life.get_node(name)
		thing.start_at(0, 0.5, true)  # halfway along the first leg, so it can't reach an end and pause
		thing.scared_left = 0.0
		thing._pause_left = 0.0
		var from: Vector3 = thing.position
		for i in 60:
			thing._physics_process(1.0 / 30.0)
		if thing.position.distance_to(from) < 0.3:
			still.append(name)
	_check("horses, joggers, walkers, kids and ducks move along their routes", still.is_empty(), str(still))
	# Palms sway, the stream has moving water, the donkeys stroll.
	var ambient: Node = life.ambient
	var crown: Node3D = ambient._crowns[0][0]
	var tilt := crown.rotation
	var donkey: Node3D = ambient._donkeys[0]["node"]
	ambient._donkeys[0]["pause"] = 0.0
	var pen: Rect2 = ambient._pen
	ambient._donkeys[0]["target"] = Vector3(pen.end.x - 0.5 if donkey.position.x < pen.get_center().x else pen.position.x + 0.5, 0, pen.get_center().y)
	var donkey_from := donkey.position
	for i in 30:
		ambient._process(1.0 / 30.0)
	_check("palm tops sway in the breeze", crown.rotation.distance_to(tilt) > 0.001, "")
	_check("the donkeys stroll round their pen", donkey.position.distance_to(donkey_from) > 0.1 and pen.has_point(Vector2(donkey.position.x, donkey.position.z)), "")
	var stream := _main.get_node("WahatBuilder/Stream").get_child(0) as MeshInstance3D
	_check("the stream has moving water", stream.material_override is ShaderMaterial, "")
	# Fewer things on Low than on High (sets the setting without saving it).
	var before: int = Settings.graphics
	Settings.graphics = 0
	Settings.apply()
	var low: int = life.shown_count()
	var low_off := true
	for node in life.levels:
		if life.levels[node] > 0:
			low_off = low_off and not node.visible and node.process_mode == Node.PROCESS_MODE_DISABLED
	Settings.graphics = 2
	Settings.apply()
	var high: int = life.shown_count()
	Settings.graphics = before
	Settings.apply()
	_check("Low shows fewer moving things than High", low > 0 and low < high and low_off, "Low %d, High %d" % [low, high])
	_bike.global_transform = keep
	_bike.set_parked(was_parked)


## Session 33: random events. Each shift plans 1 or 2 (never more), the phone warns
## before each one, only one runs at a time, road works go up with a cone on the mini-map
## and come down after 1 to 2 in-game hours, the horses cross and go, riding into a horse
## is only a small crash, and with each possible road works closure every home and shop
## door can still be reached. Maps without events: skipped.
func _check_session33() -> void:
	var events: Node = _main.get_node_or_null("EventManager") if is_instance_valid(_main) else null
	if events == null or not events.has_events():
		print("      no random events on this map, Session 33 checks skipped")
		return
	var gs: Node = root.get_node("GameState")
	var phone: Node = _main.get_node("Phone")
	var places: Node = _main.get_node("PlaceBuilder")
	var data: Dictionary = places.data.get_script_constant_map()
	var keep_bike := _bike.global_transform
	var keep_clock: float = gs.shift_time_left
	var keep_out: bool = gs.shift_clock_out
	var start: Vector3 = data["START"]["position"]
	_move_bike_to(start)
	events.clear_all()
	events.started_this_shift = 0
	# The plan: 1 or 2 events, different kinds, in order, inside the shift.
	var plans_ok := true
	for i in 30:
		var plan: Array = events.make_plan()
		plans_ok = plans_ok and plan.size() >= 1 and plan.size() <= GameConfig.EVENTS_PER_SHIFT_MAX
		if plan.size() == 2:
			plans_ok = plans_ok and plan[0]["kind"] != plan[1]["kind"] \
					and plan[1]["hour"] >= plan[0]["hour"] + GameConfig.EVENT_GAP_HOURS
		for step in plan:
			plans_ok = plans_ok and step["hour"] >= GameConfig.SHIFT_START_HOUR and step["hour"] < GameConfig.SHIFT_END_HOUR
	_check("each shift plans 1 or 2 events, one after the other", plans_ok, "")
	_check("events never start during the smoke test's rides", events.started_this_shift == 0 and not events.busy(), "")
	# Road works: the phone warns first, then they go up.
	gs.shift_clock_out = true  # the shift clock stands still while this runs
	gs.shift_time_left = GameConfig.SHIFT_LENGTH * 0.5  # 13:00
	var warned: bool = events.warn("road_works", 0)
	_check("the phone warns before road works start", warned and events.active_kind == ""
			and "Road works" in phone.event_text() and "Heads up" in phone.event_text(), phone.event_text())
	_check("only one event at a time", not events.warn("horses", 0), "")
	var waited := 0.0
	while events.active_kind == "" and waited < 30.0:
		events.tick(1.0 / 60.0)
		waited += 1.0 / 60.0
	var works: Node3D = events.road_works
	_check("road works start after the warning", events.active_kind == "road_works" and works != null
			and waited >= GameConfig.EVENT_WARNING_TIME - 0.1, "after %.1f s" % waited)
	_check("the road works have a digger, barriers and cones", works != null and works.get_child_count() > 30, "")
	_check("the mini-map shows a cone at the road works", _minimap.road_works_at.size() == 1, "")
	_check("the phone says how long the road is closed", "closed till" in phone.event_text(), phone.event_text())
	var hours: float = events.road_works_end_hour - gs.clock_hours()
	_check("road works last 1 to 2 in-game hours", hours >= 1.0 and hours <= 2.0, "%.2f hours" % hours)
	# They come down when the time is up.
	gs.shift_time_left = GameConfig.SHIFT_LENGTH * (1.0 - (events.road_works_end_hour + 0.01 - GameConfig.SHIFT_START_HOUR)
			/ (GameConfig.SHIFT_END_HOUR - GameConfig.SHIFT_START_HOUR))
	events.tick(1.0 / 60.0)
	_check("road works end after their time", events.active_kind == "" and events.road_works == null
			and _minimap.road_works_at.is_empty() and phone.event_text() == "", "")
	# Every place on the road works list leaves every home and shop door reachable.
	var stuck := []
	var not_solid := []
	var started := Time.get_ticks_msec()
	var list: Array = events.road_works_places()
	await physics_frame
	await physics_frame
	var grid: RefCounted = GRID.new()
	grid.build(_bike.get_world_3d(), data["MAP_HALF"], [_bike, _on_foot.walker])
	var previous_area := Rect2()
	for i in list.size():
		events.clear_all()
		events.started_this_shift = 0
		events.warn("road_works", i)
		events._warn_left = 0.0
		events.tick(0.0)
		if events.road_works == null:
			stuck.append("%d not built" % i)
			continue
		for frame in 2:
			await physics_frame  # the physics world takes the new barriers in on its next step
		var centre: Vector2 = list[i]["centre"]
		var footprint := Vector2(list[i]["width"], list[i]["length"])
		if list[i]["along"] == "x":
			footprint = Vector2(footprint.y, footprint.x)
		var area := Rect2(centre - footprint * 0.5, footprint).grow(4.0)
		grid.refresh_region(_bike.get_world_3d(), area.merge(previous_area) if previous_area.size != Vector2.ZERO else area, [_bike, _on_foot.walker])
		previous_area = area
		var along := Vector2(1, 0) if list[i]["along"] == "x" else Vector2(0, 1)
		if grid.is_free(centre + along * list[i]["length"] * 0.5):
			not_solid.append(i)
		for villa in places.villas:
			var door: Vector3 = places.villa_door(villa["number"])
			if not grid.can_reach(Vector2(start.x, start.z), Vector2(door.x, door.z)):
				stuck.append("%s (works %d)" % [villa["address"], i])
		for shop in places.restaurants:
			var door: Vector3 = places.restaurant_door(shop["id"])
			if not grid.can_reach(Vector2(start.x, start.z), Vector2(door.x, door.z)):
				stuck.append("%s (works %d)" % [shop["name"], i])
	events.clear_all()
	_check("the road works barriers are solid", not_solid.is_empty(), "not solid: %s" % [not_solid])
	_check("with each of the %d possible road works, every home and shop can still be reached" % list.size(),
			stuck.is_empty(), "%s (%.1f s)" % [stuck, (Time.get_ticks_msec() - started) / 1000.0])
	# Horses crossing: warned, then a groom and 2 or 3 horses cross and go.
	events.started_this_shift = 1
	warned = events.warn("horses", 0)
	_check("the phone warns before the horses cross", warned and "Horses" in phone.event_text(), phone.event_text())
	waited = 0.0
	while events.active_kind == "" and waited < 30.0:
		events.tick(1.0 / 60.0)
		waited += 1.0 / 60.0
	var crossing: Node = events.crossing
	_check("horses start crossing after the warning", events.active_kind == "horses" and crossing != null, "")
	var horses := 0
	var soft := true
	if crossing != null:
		for member in crossing.members:
			horses += 1 if String(member.name).begins_with("Horse") else 0
			soft = soft and member.is_in_group("critter")
		_check("a groom leads 2 or 3 horses", horses >= 2 and horses <= 3 and crossing.get_node_or_null("Groom") != null, "%d horses" % horses)
		var horse: Node = crossing.get_node("Horse_1")
		_check("horses only ever cause a small crash", soft and _bike.what_is(horse) == "a horse", _bike.what_is(horse))
	var across := 0.0
	while events.active_kind == "horses" and across < 60.0:
		events.tick(1.0 / 60.0)
		across += 1.0 / 60.0
	_check("the horses cross and go", events.active_kind == "" and events.crossing == null, "%.1f s" % across)
	_check("no more than 2 events in a shift", events.started_this_shift == 2 and not events.warn("road_works", 0), "")
	# Road works never go up right next to you: they pick another place.
	events.started_this_shift = 0
	var first: Vector2 = list[0]["centre"]
	_move_bike_to(Vector3(first.x, 0, first.y))
	events.warn("road_works", 0)
	events._warn_left = 0.0
	events.tick(0.0)
	var put: Vector3 = events.road_works.position if events.road_works != null else Vector3(first.x, 0, first.y)
	_check("road works never go up next to you or your bike", Vector2(put.x, put.z).distance_to(first) > 1.0, "")
	events.clear_all()
	# The horses wait for you if you're in their way (they never shove the parked bike).
	events.started_this_shift = 0
	var line: Dictionary = data["HORSE_CROSSINGS"][0]
	_move_bike_to(start)
	events.warn("horses", 0)
	events._warn_left = 0.0
	events.tick(0.0)
	var in_way: Vector3 = line["from"].lerp(line["to"], 0.4)
	_move_bike_to(in_way)
	_bike.look_at(in_way + Vector3(0, 0.05, -1))
	_bike.set_parked(true)
	for frame in 240:
		await physics_frame
	var groom: Node3D = events.crossing.get_node("Groom") if events.crossing != null else null
	var groom_gap := 0.0 if groom == null else groom.global_position.distance_to(line["from"])
	var bike_moved := Vector2(_bike.global_position.x - in_way.x, _bike.global_position.z - in_way.z).length()
	_check("the horses wait for the parked bike and don't push it", groom != null
			and groom_gap < line["from"].distance_to(in_way) and bike_moved < 0.1,
			"groom %.1f m along, bike moved %.2f m" % [groom_gap, bike_moved])
	_bike.set_parked(false)
	events.clear_all()
	# Riding into a horse at speed is a small crash, never a big one.
	events.started_this_shift = 0
	events.warn("horses", 0)
	events._warn_left = 0.0
	events.tick(0.0)
	if events.crossing != null:
		_bike.speed = (GameConfig.CRASH_BIG_KMH + 5.0) / 3.6
		var crashed: bool = _bike._check_crash(1.0, events.crossing.get_node("Groom"))
		_check("riding fast into the horses is a small crash", crashed and not _bike.wrecked and _bike.fallen_left > 0.0, "")
		_check("Session 54: the rider goes floppy (rag-doll) when they fall off", _bike._ragdoll != null
				and _bike._rider.pose.mode == "ragdoll", "")
		_bike.fallen_left = 0.0
		_bike.speed = 0.0
	events.clear_all()
	events.started_this_shift = 0
	gs.shift_time_left = keep_clock
	gs.shift_clock_out = keep_out
	_bike.global_transform = keep_bike


## Session 64: a long straight stretch of a lane on the buggy road map: [from node, to node].
func _long_buggy_stretch(roads: Object, length: float) -> Array[int]:
	for a in roads.node_count():
		for b: int in roads.links[a]:
			if roads.nodes[a].distance_to(roads.nodes[b]) >= length and roads.road_of[roads.key(a, b)].contains("Lane"):
				return [a, b] as Array[int]
	return [] as Array[int]


## Sessions 30 + 33 together: a golf buggy stops at road works instead of driving through.
func _check_life_meets_events() -> void:
	var life: Node = _main.get_node_or_null("LifeBuilder")
	var events: Node = _main.get_node_or_null("EventManager")
	if life != null and events != null and life.get_node_or_null("Buggy_0") != null and life.get_node("Buggy_0").has_method("drive_route"):
		await _check_roaming_buggy_meets_works(life, events)
		return
	if life == null or events == null or events._works_list.size() < 11:
		print("      no buggies or road works on this map, buggy-meets-road-works check skipped")
		return
	# Road works on the north ring road (x 134 to 146), where Buggy_0 drives east at z -128.5.
	var works: Node3D = load("res://scripts/road_works.gd").build(events, events._works_list[10])
	await physics_frame
	await physics_frame
	var buggy: Node3D = life.get_node("Buggy_0")
	buggy.scared_left = 0.0
	buggy._pause_left = 0.0
	buggy._blocked = 0.0
	buggy.start_at(0, (125.0 + 150.0) / 328.5, true)  # x 125, heading east to the works
	var furthest := buggy.position.x
	for i in 90:  # 3 seconds: long enough to reach the barrier, not to give up and turn round
		buggy._physics_process(1.0 / 30.0)
		furthest = maxf(furthest, buggy.position.x)
	_check("a golf buggy stops at road works instead of driving through", furthest > 127.0 and furthest < 134.0,
			"got to x %.1f (barrier starts at 134)" % furthest)
	events.remove_child(works)
	works.queue_free()
	await physics_frame

## Session 64: the same check for the roaming buggies. Buggies don't use the ring road any
## more, so the road works go on a cluster lane from ROAD_WORKS that's on the buggy road
## map; the buggy drives at it and must stop before the barrier.
func _check_roaming_buggy_meets_works(life: Node, events: Node) -> void:
	var roads: Object = life.buggy_roads
	var pick := {}
	for works: Dictionary in events._works_list:
		var centre: Vector2 = works["centre"]
		for a in roads.node_count():
			for b: int in roads.links[a]:
				var near := Geometry2D.get_closest_point_to_segment(centre, roads.nodes[a], roads.nodes[b])
				if pick.is_empty() and near.distance_to(centre) < 0.5 and roads.nodes[a].distance_to(centre) >= 20.0:
					pick = {"works": works, "from": a, "to": b}
	_check("a cluster lane with road works is on the buggy road map", not pick.is_empty(), "")
	if pick.is_empty():
		return
	var works: Node3D = load("res://scripts/road_works.gd").build(events, pick["works"])
	await physics_frame
	await physics_frame
	var buggy: Node3D = life.get_node("Buggy_0")
	var keep_exclude: Array[RID] = buggy._ahead.exclude.duplicate()
	var keep_watch: Array[Node3D] = buggy.watch.duplicate()
	var probe_exclude: Array[RID] = keep_exclude.duplicate()
	for other in get_nodes_in_group("critter"):   # only the road works may stop it here
		if other is CollisionObject3D and other != buggy:
			probe_exclude.append(other.get_rid())
	buggy._ahead.exclude = probe_exclude
	buggy.watch = [] as Array[Node3D]
	var a: Vector2 = roads.nodes[pick["from"]]
	var b: Vector2 = roads.nodes[pick["to"]]
	var way := (b - a).normalized()
	var barrier: float = a.distance_to(pick["works"]["centre"]) - float(pick["works"]["length"]) * 0.5
	buggy.drive_route([pick["from"], pick["to"]] as Array[int])
	buggy.start_at(0, (barrier - 12.0) / a.distance_to(b), true)   # 12 m before the barrier
	buggy.scared_left = 0.0
	buggy._pause_left = 0.0
	buggy._blocked = 0.0
	var start := (Vector2(buggy.position.x, buggy.position.z) - a).dot(way)
	var furthest := start
	for i in 120:  # 4 seconds: long enough to drive through, not to give up and turn round
		buggy._physics_process(1.0 / 30.0)
		furthest = maxf(furthest, (Vector2(buggy.position.x, buggy.position.z) - a).dot(way))
	_check("a golf buggy stops at road works instead of driving through", furthest > start + 2.0 and furthest + buggy.size.z * 0.5 < barrier,
			"got %.1f m along, barrier at %.1f m" % [furthest, barrier])
	buggy._ahead.exclude = keep_exclude
	buggy.watch = keep_watch
	events.remove_child(works)
	works.queue_free()
	buggy.replan()
	await physics_frame


## Session 32: special orders (rush, fragile cake, neighbour, big family) each with their rule
## and reward, school orders only 08:00 to 15:00 and more at lunch, stables and farm orders,
## the regulars (heart on the phone, your name, saved), and the shift goals (a done goal adds
## its 15 Dh to the summary). Maps without a school, Sunrise Bakery or regulars skip those parts.
func _check_session32() -> void:
	if _delivery == null or _game_state == null or not is_instance_valid(_main):
		return
	paused = false
	var gs: Node = _game_state
	var dm: Node = _delivery
	var places: Node = dm.place_builder
	dm.special_chance = GameConfig.SPECIAL_ORDER_CHANCE
	dm.regular_chance = GameConfig.REGULAR_ORDER_CHANCE
	if _on_foot != null and _on_foot.on_foot:
		_on_foot.get_on()
	gs.reset()
	var homes: Array = places.villas.filter(func(v): return v.get("kind", "") != "spot")
	var home: int = homes[0]["number"]
	# About 1 in 6 orders is special, and never more than one kind at once.
	dm.regular_chance = 0.0
	var specials := 0
	var kinds_ok := true
	for i in 600:
		var order: Object = dm.make_order()
		if order.special != "":
			specials += 1
			kinds_ok = kinds_ok and order.special in GameConfig.SPECIAL_KINDS
	dm.regular_chance = GameConfig.REGULAR_ORDER_CHANCE
	_check("about 1 in 6 orders is special", specials > 60 and specials < 150 and kinds_ok, "%d of 600" % specials)
	# Rush: 70% of the target time, 50% more pay.
	var plain: Object = dm.make_order("pizza", home)
	var rush: Object = dm.make_order("pizza", home, "rush")
	_check("a rush order pays 50% more", rush.pay == roundi(rush.base_pay * GameConfig.RUSH_PAY_SHARE)
			and rush.base_pay == plain.base_pay and rush.base_pay >= GameConfig.ORDER_PAY_MIN, "%d Dh (normal %d)" % [rush.pay, rush.base_pay])
	var normal_target: float = _meters.target_time_for(places.restaurant_door("pizza"), places.villa_door(home))
	_start_order(rush)
	_check("a rush order has 70% of the normal time", absf(gs.target_time - normal_target * GameConfig.RUSH_TIME_SHARE) < 0.01,
			"%.0f s instead of %.0f s" % [gs.target_time, normal_target])
	var phone := _main.get_node("Phone")
	phone._process(0.0)
	var chip: Label = phone._chips["special"]
	_check("the phone shows a coloured Rush chip", chip.visible and chip.text == "Rush", chip.text)
	var money: int = gs.money
	gs.deliver()
	var got: int = gs.money - money - gs.last_result["tip"]
	_check("a rush delivery pays the extra", got == rush.pay - GameConfig.INSURANCE_PER_DELIVERY
			and gs.last_result["special"] == "rush", "+%d Dh" % got)
	_close_card()
	# Fragile cake: from Sunrise Bakery, double damage, 60% tip chance.
	if places.restaurants.any(func(r): return r["id"] == GameConfig.FRAGILE_SHOP):
		gs.streak = 0  # isolate the base fragile tip chance from the preceding clean delivery
		var cake: Object = dm.make_order("", 0, "fragile")
		_check("a fragile order is a cake from the cake shop (%s)" % GameConfig.FRAGILE_SHOP, cake.restaurant_id == GameConfig.FRAGILE_SHOP and cake.food == "cake", cake.describe())
		_start_order(cake)
		_meters.hurt_food(10.0)
		_check("bumps do double damage to a fragile cake", absf(gs.meter_damage - (100.0 - 10.0 * GameConfig.FRAGILE_DAMAGE_TIMES)) < 0.01, "%.0f%%" % gs.meter_damage)
		_check("a fragile cake tips more often (60%)", gs.tip_chance(cake) == GameConfig.FRAGILE_TIP_CHANCE and gs.tip_chance(plain) == GameConfig.TIP_CHANCE, "")
		gs.deliver()
		_close_card()
	else:
		print("      no Sunrise Bakery here, fragile cakes skipped")
	# Neighbour: at the door "Not home!", on to another home in the same cluster, clock running, +5 Dh.
	var next_door: Object = dm.make_order("", home, "neighbour")
	_check("a neighbour order pays 5 Dh extra", next_door.pay == next_door.base_pay + GameConfig.NEIGHBOUR_BONUS, "%d Dh" % next_door.pay)
	_start_order(next_door)
	gs.ride_time = 12.0
	_put_actor_at(dm.target_door())
	var first_cluster: String = next_door.cluster
	var sent: bool = dm.try_interact()
	_check("at the door: not home, take it to the neighbour", sent and gs.stage_name() == "TO_VILLA" and next_door.villa_number != home
			and next_door.cluster == first_cluster and "Not home!" in next_door.note, "%s: %s" % [next_door.address, next_door.note])
	_check("the clock keeps running for the neighbour", gs.ride_time == 12.0 and gs.target_time > 0.0, "%.0f s" % gs.ride_time)
	_check("the beam moves to the neighbour's door", dm.target_door().distance_to(places.villa_door(next_door.villa_number) if dm.on_foot else places.villa_approach(next_door.villa_number)) < 0.01, "")
	_put_actor_at(dm.target_door())
	money = gs.money
	_check("then you can deliver to the neighbour", dm.try_interact() and gs.stage_name() == "NONE"
			and gs.money - money - gs.last_result["tip"] == next_door.pay - GameConfig.INSURANCE_PER_DELIVERY, "")
	_close_card()
	# Big family: two bags (slower, wobblier), double pay.
	var family: Object = dm.make_order("", home, "family")
	_check("a big family order pays double", family.pay == family.base_pay * GameConfig.FAMILY_PAY_TIMES, "%d Dh" % family.pay)
	_start_order(family)
	var bag: Node3D = _bike.get_node_or_null("Model/Fork/ExtraBag")
	_check("big family: two bags on the bike", _bike.heavy_load and bag != null and bag.visible, "")
	_check("big family: lower top speed", _top_speed_ridden(true) < _top_speed_ridden(false) * 0.9, "")
	_put_actor_at(dm.target_door())
	dm.try_interact()
	_close_card()
	_check("the second bag comes off after the delivery", not _bike.heavy_load and not bag.visible, "")
	_check_school_orders()
	_check_regulars()
	_check_goals()
	dm.special_chance = GameConfig.SPECIAL_ORDER_CHANCE
	dm.regular_chance = GameConfig.REGULAR_ORDER_CHANCE
	gs.rider_name = ""
	gs.reset()
	paused = false


## Offers, accepts and picks up an order (the meters start, the bags go on the bike).
func _start_order(order: Object) -> void:
	_game_state.offer_order(order)
	_game_state.accept_offer()
	_game_state.pick_up()


## Puts you (on the bike or on foot) right at a door.
func _put_actor_at(spot: Vector3) -> void:
	var who: Node3D = _delivery.actor if _delivery.actor != null else _bike
	who.global_position = spot + Vector3.UP * 0.05
	if who == _bike:
		_bike.velocity = Vector3.ZERO
		_bike.speed = 0.0


## Pedals the bike for 4 seconds of physics (by hand, on the spot) and returns the top speed.
func _top_speed_ridden(heavy: bool) -> float:
	var keep: Transform3D = _bike.global_transform
	var was: bool = _bike.heavy_load
	_bike.heavy_load = heavy
	_bike.speed = 0.0
	Input.action_press("move_forward")
	for i in 240:
		_bike._update_stamina_and_speed(1.0 / 60.0)
	Input.action_release("move_forward")
	var top: float = _bike.speed
	_bike.speed = 0.0
	_bike.heavy_load = was
	_bike.global_transform = keep
	return top


## The shift clock at a given hour (11.5 = 11:30).
func _set_hour(hour: float) -> void:
	var share := (hour - GameConfig.SHIFT_START_HOUR) / (GameConfig.SHIFT_END_HOUR - GameConfig.SHIFT_START_HOUR)
	_game_state.shift_time_left = GameConfig.SHIFT_LENGTH * (1.0 - share)


## School orders: never after 15:00, about 1 in 3 at lunch, teachers and kids at the door.
## Stables orders: riders and grooms. Farm stall: about 1 in 8 pickups.
func _check_school_orders() -> void:
	var dm: Node = _delivery
	var places: Node = dm.place_builder
	if not places.villas.any(func(v): return v["number"] == GameConfig.SCHOOL_SPOT):
		print("      no school here, school, stables and farm checks skipped")
		return
	var share := func(hour: float) -> float:
		_set_hour(hour)
		var count := 0
		for i in 600:
			if dm.make_order().villa_number == GameConfig.SCHOOL_SPOT:
				count += 1
		return count / 600.0
	var morning: float = share.call(9.0)
	var lunch: float = share.call(12.0)
	var late: float = share.call(15.5)
	_check("a school order never comes after 15:00", late == 0.0, "%.0f%% at 15:30" % (late * 100.0))
	_check("lunch rush: about 1 in 3 orders is for the school", lunch > 0.2 and lunch < 0.45 and lunch > morning * 2.0,
			"%.0f%% at 12:00, %.0f%% at 09:00" % [lunch * 100.0, morning * 100.0])
	_set_hour(12.0)
	var who_ok := true
	var lunch_flag := true
	var farm := 0
	for i in 800:
		var order: Object = dm.make_order()
		if order.villa_number == GameConfig.SCHOOL_SPOT:
			who_ok = who_ok and order.who in ["teacher", "kid"]
			lunch_flag = lunch_flag and order.lunch
		elif order.villa_number == GameConfig.STABLES_SPOT:
			who_ok = who_ok and order.who in ["rider", "groom"]
		if order.restaurant_id == GameConfig.FARM_SHOP:
			farm += 1
	_check("teachers and kids order to the school, riders and grooms to the stables", who_ok, "")
	_check("school orders at lunch count as lunch orders", lunch_flag, "")
	_check("about 1 in 8 orders is picked up at the farm stall", farm > 60 and farm < 170, "%d of 800" % farm)
	# Deliver one to the stables: a rider or a groom comes out.
	var order: Object = dm.make_order("pizza", GameConfig.STABLES_SPOT)
	order.leave_at_door = false  # this one: someone comes out (not a bag on the step)
	_start_order(order)
	_game_state.deliver()
	var spawner := _main.get_node_or_null("CustomerSpawner")
	var customer: Node = spawner.last_spawned if spawner != null else null
	_check("a rider or groom comes out at the stable office", customer != null and order.who in ["rider", "groom"]
			and customer.get("person") != null, order.who)
	_close_card()
	_set_hour(8.0)


## The regulars: heart on the phone, their own lines with your name, 60% tips, saved visits.
func _check_regulars() -> void:
	var gs: Node = _game_state
	var dm: Node = _delivery
	var regulars: Array = dm.place_builder.regulars
	gs.reset()
	if regulars.is_empty():
		print("      no regulars on this map, regular checks skipped")
		return
	_check("4 regular customers", regulars.size() == 4, "%d" % regulars.size())
	gs.rider_name = "Louis"
	var maker: Object = dm.order_maker()
	var mariam: Object = maker.make_regular(regulars[0])
	# Session 58: Spill the Brew is a coffee shop now, so Auntie Mariam has an iced latte.
	var usual := "iced latte" if GameConfig.FOOD_CHANGES_ON else "bubble tea"
	_check("Auntie Mariam orders an %s to Villa 7, Cluster 2" % usual, mariam.food == usual and mariam.address == "Villa 7, Cluster 2", mariam.describe())
	gs.offer_order(mariam)
	var phone := _main.get_node("Phone")
	phone._process(0.0)
	var heart: Label = phone._chips["regular"]
	_check("a regular has a heart on the phone", heart.visible and "♥" in heart.text and "Mariam" in heart.text, heart.text)
	gs.accept_offer()
	gs.pick_up()
	_check("regulars tip more often (60%)", gs.tip_chance(mariam) == GameConfig.REGULAR_TIP_CHANCE, "")
	gs.deliver()
	var customer: Node = _main.get_node("CustomerSpawner").last_spawned
	var lines: Array = load("res://data/customer_lines.gd").REGULAR_STAGES["mariam"]["first"]
	var said: String = customer.get("line") if customer != null else ""
	var own := lines.any(func(l): return l.replace("{name}", "Louis") == said)
	_check("Auntie Mariam says one of her own lines with your name", own and "Louis" in said, said)
	_close_card()
	_check("the regular's visit is counted", gs.regular_visits.get("mariam", 0) == 1, str(gs.regular_visits))
	gs.save_game()
	gs.regular_visits.clear()
	gs.load_game()
	_check("regulars' visits are saved", gs.regular_visits.get("mariam", 0) == 1, str(gs.regular_visits))
	# Regulars order more often than anyone else; Ms Dana only while the school is open.
	var to_mariam := 0
	var regular_orders := 0
	for i in 1000:
		var order: Object = dm.make_order()
		if order.regular != "":
			regular_orders += 1
		if order.villa_number == regulars[0]["villa"]:
			to_mariam += 1
	var homes: int = dm.place_builder.villas.size()
	_check("regulars order more often than anyone else", to_mariam > 1000.0 / homes * 1.5 and regular_orders > 80,
			"%d to Mariam, %d from regulars" % [to_mariam, regular_orders])
	_set_hour(16.0)
	var dana_late := 0
	for i in 300:
		if dm.order_maker().pick_regular().get("id", "") == "dana":
			dana_late += 1
	_check("Ms Dana (school) never orders after 15:00", dana_late == 0, "%d" % dana_late)
	_set_hour(8.0)


## Shift goals: 2 on the phone, a done goal adds its 15 Dh to the summary and the wallet.
func _check_goals() -> void:
	var gs: Node = _game_state
	var dm: Node = _delivery
	gs.reset()
	_check("2 shift goals at the start of the shift", gs.shift_goals.size() == GameConfig.GOALS_PER_SHIFT
			and gs.shift_goals[0] != gs.shift_goals[1] and gs.shift_goals.all(func(g): return g in gs.goal_pool), str(gs.shift_goals))
	var phone := _main.get_node("Phone")
	phone._process(0.0)
	var goals: Label = phone.get_node("Panel/Margin/Rows/Goals")
	_check("the phone shows the shift goals", goals.visible and goals.text.count("\n") == GameConfig.GOALS_PER_SHIFT, goals.text.replace("\n", " | "))
	var places: Node = dm.place_builder
	var has_school: bool = places.villas.any(func(v): return v["number"] == GameConfig.SCHOOL_SPOT)
	_check("goals fit the map (no lunch goal without a school)", ("lunch" in gs.goal_pool) == has_school, str(gs.goal_pool))
	gs.shift_goals.clear()
	gs.shift_goals.append("streak")
	gs.shift_goals.append("deliveries")
	var home: int = places.villas.filter(func(v): return v.get("kind", "") != "spot")[0]["number"]
	for i in GameConfig.GOAL_FIVE_STAR_STREAK:
		_start_order(dm.make_order("pizza", home))
		gs.set_meters(100.0, 100.0, 100.0)
		gs.deliver()
		_close_card()
	_check("the Delivered card says when a goal is done", gs.last_goals_done.size() == 1 and gs.last_goals_done[0] == "streak", str(gs.last_goals_done))
	_check("No crashes is done until you crash", _goal_done("no_crashes"), "")
	gs.note_crash()
	_check("a crash breaks the No crashes goal", not _goal_done("no_crashes"), "")
	var summary: Dictionary = gs.shift_summary()
	var want: int = summary["pay"] + summary["tips"] + GameConfig.GOAL_BONUS - summary["insurance"] - summary["bills"]
	_check("a done goal adds 15 Dh to the summary", summary["goal_bonus"] == GameConfig.GOAL_BONUS and summary["earned"] == want
			and summary["goals"][0]["done"] and not summary["goals"][1]["done"], "bonus %d, earned %d" % [summary["goal_bonus"], summary["earned"]])
	var money: int = gs.money
	var ended: Dictionary = gs.end_shift()
	_check("the goal bonus goes into the wallet once", gs.money == money + GameConfig.GOAL_BONUS and ended["goal_bonus"] == GameConfig.GOAL_BONUS, "Dh %d" % gs.money)
	var screen := _main.get_node_or_null("ShiftScreen")
	if screen != null:
		screen.show_summary(ended)
		var texts: Array = screen._table.get_children().map(func(n): return n.text)
		_check("the shift summary lists the goals", texts.any(func(t): return "in a row" in t), "")
		screen._next_shift()


## ShiftGoals.is_done for this shift (reached through a script load, not the class name).
func _goal_done(id: String) -> bool:
	var goals: Script = load("res://scripts/shift_goals.gd")
	return goals.is_done(id, _game_state.history.slice(_game_state.shift_start_index), _game_state.shift_crashes)


## Session 66: the PolishHooks autoload saw the world open and ran the polish parts that exist
## (none until Sessions 67 to 71 add theirs to scripts/polish/).
func _check_polish_hooks() -> void:
	var hooks := root.get_node_or_null("PolishHooks")
	var ok: bool = hooks != null and (hooks.last_world == _main or not GameConfig.POLISH_HOOKS_ON)
	var expected: Array[String] = []
	if hooks != null and GameConfig.POLISH_HOOKS_ON:
		for path: String in hooks.PARTS:
			if ResourceLoader.exists(path):
				expected.append(path)
	_check("the polish hooks ran for the world", ok and hooks.attached == expected,
			"%d parts: %s" % [expected.size(), expected])


## Session 67: the sky, light and colour extras are on in the real game world (the cartoon
## sky, the colour grade, the vignette under the HUD and the light shafts).
func _check_look_polish() -> void:
	var env: Environment = (_main.get_node("WorldEnvironment") as WorldEnvironment).environment
	var sky_ok: bool = (env.sky.sky_material is ShaderMaterial) == GameConfig.SKY_STYLIZED
	var lut_ok: bool = (env.adjustment_color_correction != null) == (GameConfig.LOOK_LUT != "neutral")
	var vignette := _main.get_node_or_null("Vignette")
	var shafts := _main.get_node_or_null("LightShafts")
	_check("the sky, colour grade, vignette and light shafts are on", sky_ok and lut_ok
			and (vignette != null) == (GameConfig.VIGNETTE_STRENGTH > 0.0)
			and (shafts != null) == GameConfig.LIGHT_SHAFTS_ON,
			"sky %s, LUT %s, vignette %s, %d shafts" % [sky_ok, lut_ok, vignette != null,
			shafts.shafts.size() if shafts != null else 0])
