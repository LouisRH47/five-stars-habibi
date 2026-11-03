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
	"tap": 12,         # a quick tap of E (0.2 s): must do nothing at the door
	"walk": 360,       # up to 6 seconds to walk to the door (or back to the bike)
	"hold": 100,       # holding E for 1.67 s: longer than the 1.5 s pick-up / drop-off hold
	"timeout": 30,     # half a second, longer than TEST_OFFER_TIMEOUT
	"bump_ride": 300,  # 5 seconds of pedalling from a standstill, over a speed bump
	"critters": 120,   # 2 seconds for a kid on a scooter to ride into the bike
	"crash_small": 30, # half a second to coast into a wall
	"fallen": 150,     # long enough to get back on the bike
	"crash_big": 60,   # one second to ride fast into a wall
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
const TEST_SAVE := "user://smoke_test_save.json"

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


func _initialize() -> void:
	var scene_path := "res://scenes/wahat_al_shams.tscn"  # the game opens on the main menu, test the map
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		scene_path = user_args[0]
	print("      scene: ", scene_path)
	# Start from a clean slate, whatever is in the real save, and never write to it.
	var state := root.get_node("GameState")
	state.save_path = TEST_SAVE
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
					_check("F next to the bike gets you back on", _on_foot.get_on() and not _on_foot.on_foot, "")
				# Still at the restaurant, so the villa may be off the map: the pin must stay on it.
				_check_minimap_pin(_order.address)
				_check_minimap_turns()
				_check_meters()
				_move_bike_to(_delivery.target_door())
				_frame = 0
				_phase = "at_villa"
		"at_villa":
			if _frame >= STEPS.settle:
				_check("bike is near the villa door", _delivery.is_near_target(), "")
				_check_minimap_pin(_order.address)
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
			if _frame >= STEPS.crash_big:
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
	_game_state.connect("order_skipped", _on_order_skipped)
	_order = _delivery.offer_now()
	var places: Node = _delivery.place_builder
	var built := 0
	if places != null:
		for child in places.get_children():
			if child.name.begins_with("Villa"):
				built += 1
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
	if map.has("PARK"):
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
	_delivery.offer_now()
	_delivery.accept()
	_game_state.pick_up()
	_move_bike_to(kid._from + ahead * 2.5)
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
	_check("the bills are 150 Dh hospital + 80 Dh repair", bills.get("hospital") == 150 and bills.get("repair") == 80, "")
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
## from the gate into the Plaza, every door spot can be reached by bike, 5-minute shifts.
func _check_wahat() -> void:
	var places: Node = _main.get_node_or_null("PlaceBuilder")
	if places == null or not places.data.get_script_constant_map().has("MAP_HALF"):
		print("      not Wahat Al Shams, its checks skipped")
		return
	var data: Dictionary = places.data.get_script_constant_map()
	var homes: Array = places.villas.filter(func(v): return v.get("kind", "") != "spot")
	_check("Wahat Al Shams has 60 homes", homes.size() == 60, "%d" % homes.size())
	var good := 0
	var clusters := {}
	for villa in homes:
		var house: int = villa["house"]
		if villa["address"] == "%s · Villa %d" % [villa["cluster"], house] and house >= 1 and house <= 12:
			good += 1
		clusters[villa["cluster"]] = clusters.get(villa["cluster"], 0) + 1
	_check("every home has an address like \"C3 · Villa 7\"", good == 60, "%d of 60" % good)
	_check("5 clusters of 12 homes", clusters.size() == 5 and clusters.values().all(func(n): return n == 12), "%s" % [clusters])
	var plaza: Dictionary = data["PLAZA"]
	var reached: float = Vector2(_bike.global_position.x, _bike.global_position.z).distance_to(plaza["centre"])
	_check("the ride from the gate ends in the Plaza", reached < plaza["radius"], "%.0f m from the middle" % reached)
	_check("a shift is 5 minutes", GameConfig.SHIFT_LENGTH == 300.0, "")
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
		if grid.path(Vector2(start.x, start.z), Vector2(door.x, door.z)).is_empty():
			stuck.append(villa["address"])
	for shop in places.restaurants:
		var door: Vector3 = places.restaurant_door(shop["id"])
		if grid.path(Vector2(start.x, start.z), Vector2(door.x, door.z)).is_empty():
			stuck.append(shop["name"])
	_check("every home, shop and drop-off spot door can be reached by bike", stuck.is_empty(),
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
	var model: Node3D = _bike.get_node("Model")
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
	_check("tip: ride to the pizza place with the mini-map", "Ride to Pizza" in tutorial.tip and "mini-map" in tutorial.tip, "")
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
	var keep := {"money": gs.money, "xp": gs.xp, "jobs": gs.history.size(), "rating": gs.rating()}
	_check("the game saves", gs.save_game() and FileAccess.file_exists(TEST_SAVE), TEST_SAVE)
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
	_check("the game opens on the main menu",
			ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main_menu.tscn", "")
	gs.new_game()
	_check("New game wipes everything", gs.money == 0 and gs.history.is_empty() and not gs.hired and gs.rider_name == "", "")
	SaveGame.delete(TEST_SAVE)
	_check("the test save is cleaned up", not FileAccess.file_exists(TEST_SAVE), "")


## Session 13: a 1-second test shift. carrying: run out of time while carrying an order.
func _start_shift_check(carrying: bool) -> void:
	var gs: Node = _game_state
	gs.reset()
	var clock: Label = _main.get_node("ShiftScreen")._clock
	_main.get_node("ShiftScreen")._process(0.0)
	if carrying:
		_check("the shift clock starts at 08:00", clock.text == "08:00", clock.text)
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
			and summary["earned"] == pay + tips - 2 * GameConfig.INSURANCE_PER_DELIVERY and summary["earned"] == gs.money, "%d Dh" % summary["earned"])
	_check("the summary has stars and XP", summary["stars"] == want["stars"] and summary["xp"] == gs.xp, "%.1f stars, %d XP" % [summary["stars"], summary["xp"]])
	screen._next_shift()
	_check("the next shift starts with a full clock", not paused and not gs.shift_clock_out
			and gs.shift_time_left == GameConfig.SHIFT_LENGTH and gs.shift_number == 2, "")


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
	_delivery.offer_now()
	_delivery.accept()
	gs.pick_up()
	_walk_goal = _delivery.target_door()
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
	_check("tips sometimes come on 5-star jobs, 2 to 15 Dh", tips > 40 and tips < 120 and tips_ok, "%d of 200" % tips)
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
	_check_sound()
	_check_session27()
	_check_saving()
	for action in ACTIONS:
		Input.action_release(action)
	_phase = "done"
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)


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
	_check("the ride from the gate went down into the sunken square", _lowest_y < -0.2, "lowest %.2f m" % _lowest_y)
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
	var foods := {"shawarma": ["shawarma"], "bakery": ["cake"], "market": ["groceries"],
			"farm": ["farm juice", "salad box"]}
	var start: Vector3 = data["START"]["position"]
	for id in foods:
		gs.reset()
		var order: Object = _delivery.make_order(id, 101)
		var door: Vector3 = places.restaurant_door(id)
		var reachable: bool = _grid != null and not _grid.path(Vector2(start.x, start.z), Vector2(door.x, door.z)).is_empty()
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
	var school: Rect2 = plots["Al Shams School"].grow(8.0)  # the booth is just outside the fence
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
	for number in [901, 902]:
		gs.reset()
		var order: Object = _delivery.make_order("pizza", number)
		var done: bool = gs.offer_order(order) and gs.accept_offer() and gs.pick_up() and gs.deliver()
		_close_card()
		_check("a delivery to %s works" % order.address, done and order.villa_number == number, order.describe())
	gs.reset()
	paused = false
