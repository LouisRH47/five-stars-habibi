extends SceneTree
## Smoke test: loads the main scene (Palm Grove), pedals for a few seconds and checks
## the bike actually moves, sprints and stops. It checks the sign font and that the
## restaurants and street signs have Arabic + English text. Then it does one full delivery
## (offer, accept, pick up, drop off, get paid), skips an order and lets one run out of time.
## On Palm Grove it then checks the decorations (mosque, mini market, palms, parked cars,
## speed bumps) were built and rides over the first speed bump.
## It also checks the mini-map (Session 7): it turns with the bike, and its pin shows the
## restaurant, then the villa number, and stays on the map when the stop is far away.
## And that some orders (not all) come with a customer note.
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
	"bump_ride": 300,  # 5 seconds of pedalling from a standstill, over a speed bump
}
## How far before the speed bump the bike starts its ride, in metres.
const BUMP_RUN_UP := 6.0
## A short offer timer for the test, so it doesn't have to wait 30 seconds.
const TEST_OFFER_TIMEOUT := 0.2
## Every action the test might press. All of them are let go at the end.
const ACTIONS := ["move_forward", "move_back", "sprint", "handbrake", "interact", "skip_order"]
const FONT_PATH := "res://assets/fonts/NotoSansArabic.ttf"

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
	_minimap = _main.get_node_or_null("Minimap")
	_meters = _main.get_node_or_null("Meters")
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
				_check_minimap_pin(_order.restaurant_name)
				_check("E at the restaurant picks up the food", _delivery.try_interact(), "")
				_check_stage("TO_VILLA")
				# Still at the restaurant, so the villa may be off the map: the pin must stay on it.
				_check_minimap_pin(str(_order.villa_number))
				_check_minimap_turns()
				_check_meters()
				_move_bike_to(_delivery.target_door())
				_frame = 0
				_phase = "at_villa"
		"at_villa":
			if _frame >= STEPS.settle:
				_check("bike is near the villa door", _delivery.is_near_target(), "")
				_check_minimap_pin(str(_order.villa_number))
				var spot: Vector2 = _minimap.world_to_map(_delivery.target_door())
				var middle: Vector2 = _minimap.get_node("Panel/Margin/Map").size * 0.5
				_check("at the villa the pin is right next to you", spot.distance_to(middle) < 10.0,
						"%.1f px from the middle" % spot.distance_to(middle))
				_check("E at the villa delivers", _delivery.try_interact(), "")
				_check("money goes up by the order's pay", _game_state.money == _money_before + _order.pay, "Dh %d" % _game_state.money)
				_check("delivery is saved in the history", _game_state.history.size() == 1, "%d in history" % _game_state.history.size())
				_check("an all-red order can still be delivered", _game_state.history.size() == 1 and _game_state.history[0]["damage"] == 0.0, "")
				_check_stage("NONE")
				_start_skip_check()
		"timeout":
			if _frame >= STEPS.timeout:
				_check("an ignored order counts as skipped", _skipped == 2, "%d skipped" % _skipped)
				_check_stage("NONE")
				_delivery.offer_timeout = GameConfig.ORDER_OFFER_TIMEOUT
				_start_decor_check()
		"bump_ride":
			if _frame >= STEPS.bump_ride:
				_check_bump_ride()
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
		var node_name: String = pair[0]
		var place: Dictionary = map[pair[1]]
		var english: String = place["name"]
		var building := decor.get_node_or_null(node_name)
		_check(node_name + " was built", building != null, "")
		if building != null:
			_check(node_name + " has an Arabic sign", _has_arabic_label(building), "")
			_check(node_name + " has an English sign", _has_label_text(building, english), english)
	var park := decor.get_node_or_null("Park")
	_check("the park sign has Arabic", park != null and _has_arabic_label(park), "")
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


## Session 8: the meters fill at pickup and drop with time, bumps and hard braking.
## Ends with every meter at 0, so the delivery after it checks a red order can still be delivered.
func _check_meters() -> void:
	if _meters == null:
		_check("Meters node exists in the scene", false, "")
		return
	var gs := _game_state
	var places: Node = _delivery.place_builder
	var want: float = _meters.target_time_for(places.restaurant_door(_order.restaurant_id), places.villa_door(_order.villa_number))
	_check("meters are full at pickup", gs.meter_time == 100.0 and gs.meter_freshness == 100.0 and gs.meter_damage == 100.0, "")
	_check("the target time follows the PRD rule", absf(gs.target_time - want) < 0.01 and gs.target_time > GameConfig.TIME_TARGET_EXTRA,
			"%.0f s" % gs.target_time)
	var panel: Control = _main.get_node("MetersPanel/Panel")
	_check("the meters panel shows while carrying food", panel.visible, "")
	_meters._physics_process(gs.target_time * 0.5)
	_check("the time meter drains", absf(gs.meter_time - 50.0) < 1.0, "%.0f%%" % gs.meter_time)
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
	var view: Control = _minimap.get_node("Panel/Margin/Map")
	_check("the mini-map is on screen", view.is_visible_in_tree() and view.size.x > 100.0, "%.0f px wide" % view.size.x)
	_check("the mini-map has a pin during the order", _minimap.has_target(), "")
	_check("the pin says " + expected, _minimap.target_label() == expected, _minimap.target_label())
	var pin: Vector2 = _minimap.target_on_map()
	_check("the pin is inside the mini-map", Rect2(Vector2.ZERO, view.size).has_point(pin), "at %s" % pin)


## The mini-map turns with the bike: straight ahead is always up, your right is right.
func _check_minimap_turns() -> void:
	if _minimap == null:
		return
	var middle: Vector2 = _minimap.get_node("Panel/Margin/Map").size * 0.5
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
	_check("a stop far away is pinned to the mini-map's edge",
			Rect2(Vector2.ZERO, middle * 2.0).has_point(far) and absf(far.x - (middle.x * 2.0 - inset)) < 0.5,
			"at %s" % far)


## Some orders come with a note from the customer, most don't, and every note is from the list.
func _check_notes() -> void:
	var with_note := 0
	var all_listed := true
	for i in 200:
		var note: String = _delivery.make_order().note
		if note != "":
			with_note += 1
			all_listed = all_listed and GameConfig.ORDER_NOTES.has(note)
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
	for action in ACTIONS:
		Input.action_release(action)
	_phase = "done"
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)
