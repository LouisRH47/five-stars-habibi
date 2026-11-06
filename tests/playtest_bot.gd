extends SceneTree
## Play-test bot (Session 17, map-agnostic since Session 25): rides a whole shift like a
## careful player and prints how it went. It really rides the bike (same physics and keys as
## a player): it finds a route with tests/grid_path.gd (down the middle of lanes, away from
## walls), aims at a spot a few metres ahead on the route ("pure pursuit", so it rounds
## corners smoothly), slows down in time for corners, speed bumps, cats, kids and the door
## (coasting first, never a hard brake), rides round cats and kids, and backs up (S) when
## it bumps into something. It accepts every order, gets off at the door, walks over,
## holds E, walks back, gets on. At the end it prints each delivery (ride time vs target,
## the three meters, stars, pay) and the shift summary. Use it to tune the numbers in
## scripts/game_config.gd. Run it with (Wahat Al Shams by default):
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless --fixed-fps 60 -s tests/playtest_bot.gd
## (--fixed-fps 60 makes it run faster than real time.) Add "-- careless" to ride flat out
## without slowing for bumps, corners or critters, "-- timeline" to print each stage change
## and back-up, and/or a scene path ("-- res://scenes/test_area.tscn").

const GRID := preload("res://tests/grid_path.gd")
const BUMP_KMH := 9.0       # slow to this for speed bumps (careful rider)
const RIDE_INSTEAD_M := 12.0  # a door further than this from where we got off: ride there
const CRITTER_KMH := 7.0    # slow to this near cats and kids (under CRASH_SMALL_KMH)
const LOOK_AHEAD := 2.5     # metres: aim this far ahead on the route (more when faster)
const CORNER_ROOM := 4.0    # metres of route a corner is spread over (bigger = faster corners)
const COAST_SLOW := 0.9     # m/s lost per second when coasting (planning, a bit under BIKE_COAST_DRAG)
const BRAKE_SLOW := 2.5     # m/s lost per second when braking gently (planning)
const BACK_UP_TIME := 1.2   # seconds to roll backwards after bumping into something

var _main: Node
var _bike: CharacterBody3D
var _gs: Node
var _dm: Node
var _pts: Array[Vector2] = []  # the route, a point every half metre
var _cum: Array[float] = []    # metres along the route to each point
var _corners: Array = []       # [metres along the route, fastest speed round it in m/s]
var _idx := 0                  # the route point the bike is at
var _route_for := ""
var _back_left := 0.0          # seconds of backing up still to do
var _backups := 0              # times backed up without getting closer to the door
var _best_left := INF          # closest we've been to the door on this leg (metres)
var _backed_up := 0            # times backed up this shift
var _bumps: Array = []
var _careless := false
var _stuck_time := 0.0
var _resets := 0
var _done := false
var _rides: Array = []  # [ride seconds, target seconds] per delivery
var _on_foot: Node
var _walk_time := 0.0  # seconds spent walking (Session 19)
var _walked_for := ""  # the stage the last walk to a door was for (done once it changes)
var _walk_route: Array[Vector2] = []
var _walk_last := Vector2.ZERO
var _walk_stuck := 0.0
var _this_walk := 0.0   # seconds this walk has taken (to say when one takes too long)
var _door_when_parked := Vector2.ZERO  # where the door was when we got off (did it move?)
var _walk_best := INF    # closest we've got to where we're walking on this walk (metres)
var _walk_no_gain := 0.0  # seconds without getting closer
var _exit_left := 0.0  # seconds left following the way out of a building by its door
var _repark_left := 0.0  # seconds of rolling back after parking in our own way
var _walk_goal := Vector2.INF  # what _walk_best is measured to
var _trail: Array[Vector2] = []  # the way we walked to the door (to walk back out the same way)
var _crashes := {"small": 0, "big": 0}
var _frames := 0
var _grid: RefCounted
var _timeline := false  # "-- timeline": print each stage change and each back-up
var _stage_was := ""
var _rescan_at := -1          # Session 33: scan the map again at this frame (road works)
var _shift_count := 1
var _completed_shifts := 0
var _balance: Array[Dictionary] = []


func _initialize() -> void:
	_careless = "careless" in OS.get_cmdline_user_args()
	_timeline = "timeline" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shifts="):
			_shift_count = clampi(arg.get_slice("=", 1).to_int(), 1, 5)
	_gs = root.get_node("GameState")
	_gs.save_path = "user://playtest_bot_save.json"
	_gs.new_game()
	_gs.hire("Bot", "Somewhere else", 0)
	_gs.tutorial_done = true
	var scene := "res://scenes/wahat_al_shams.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("res://"):
			scene = arg
	_main = load(scene).instantiate()
	root.add_child(_main)
	_bike = _main.get_node("Bike")
	_dm = _main.get_node("DeliveryManager")
	_on_foot = _main.get_node("OnFoot")
	_gs.shift_ended.connect(_on_shift_ended)
	# Session 33: random events. Print them, and scan the map again when road works go up or
	# come down (a couple of frames later, once the physics world has them), then re-plan.
	var events := _main.get_node_or_null("EventManager")
	if events != null:
		events.warned.connect(func(kind, place): print("  event warning: %s at %s" % [kind, place]))
		events.event_started.connect(func(kind, place): print("  event started: %s at %s, %.1f s into the shift" % [kind, place, GameConfig.SHIFT_LENGTH - _gs.shift_time_left]))
		events.event_ended.connect(func(kind): print("  event ended: %s" % kind))
		events.road_works_changed.connect(func(): _rescan_at = _frames + 2)
	_gs.order_delivered.connect(func(_order): _rides.append([_gs.ride_time, _gs.target_time]))
	_bike.crashed.connect(func(big):
		_crashes["big" if big else "small"] += 1
		print("  crash (%s): %s at %.0f km/h, at %s" % ["big" if big else "small", _bike.last_crash["what"], _bike.last_crash["kmh"], _bike.global_position]))
	print("Play-test bot: %d consecutive full shifts, %s rider" % [_shift_count, "careless" if _careless else "careful"])


func _physics_process(delta: float) -> bool:
	if _done:
		return false
	_frames += 1
	if _frames > 60 * 60 * 15:  # safety: never run longer than 15 game minutes
		print("Bot gave up: the shift never ended")
		_on_shift_ended(_gs.shift_summary())
		return false
	var card := _main.get_node_or_null("DeliveredCard")
	if card != null and card.showing:
		card.close()  # Next order · E
		return false
	var clinic := _main.get_node("ClinicScreen")
	if clinic.showing:
		_let_go()
		clinic.close()  # OK, back to work (this ends the shift)
		return false
	if _rescan_at >= 0 and _frames >= _rescan_at:
		_rescan_at = -1
		_grid = null
		_route_for = ""
	if _grid == null or _grid.solid_count == 0:
		if _frames < 10:
			return false  # let the map build and get into the physics world first
		_grid = GRID.new()
		_grid.clearance = 1.0  # ride down the middle of lanes, not along the walls
		_grid.wall_cost = 4.0  # and keep away from walls where there's room
		_grid.build(_bike.get_world_3d(), _map_half(), [_bike, _on_foot.walker])
		print("Map scanned: %d blocked squares" % _grid.solid_count)
		if _grid.solid_count == 0:
			return false  # not ready yet: try again next frame
	if _bumps.is_empty():
		for bump in _main.get_node("DecorBuilder").speed_bumps:
			_bumps.append(Vector2(bump["position"].x, bump["position"].z))
	var now := "%s%s" % [_gs.stage_name(), " on foot" if _on_foot.on_foot else ""]
	if _timeline and now != _stage_was:
		_stage_was = now
		print("    %5.1f s  %s" % [GameConfig.SHIFT_LENGTH - _gs.shift_time_left, now])
	if _on_foot.on_foot:
		_walk(delta)
		return false
	match _gs.stage_name():
		"OFFERED":
			_dm.accept()
		"TO_RESTAURANT", "TO_VILLA":
			_ride(delta)
		_:
			_let_go()
	return false


## On foot (Session 19): walk to the door and hold E; once that's done, walk back and F.
func _walk(delta: float) -> void:
	_walk_time += delta
	_let_go()
	var going_to_door: bool = _gs.stage_name() in ["TO_RESTAURANT", "TO_VILLA"] and _walked_for != _gs.stage_name()
	if _walked_for == "":
		_walked_for = "pending " + _gs.stage_name()
	if _walked_for.begins_with("pending ") and _gs.stage_name() != _walked_for.substr(8):
		_walked_for = _gs.stage_name()  # picked up or delivered: walk back now
	going_to_door = _walked_for.begins_with("pending ")
	if going_to_door and _dm.is_near_target():
		Input.action_press("interact")  # hold E until the bar is full
		return
	if not going_to_door and _on_foot.near_bike():
		_on_foot.toggle()  # F: back on the bike
		return
	var walker: Node3D = _on_foot.walker
	var here := _flat(walker.global_position)
	var goal := _flat(_dm.target_door() if going_to_door else _bike.global_position)
	var door_moved := goal.distance_to(_door_when_parked) > 3.0
	if going_to_door and door_moved and here.distance_to(goal) > RIDE_INSTEAD_M and not _inside_delivery():
		# The door moved far away ("leave it with the neighbour"): ride there, like a player.
		if _on_foot.near_bike():
			_on_foot.toggle()
			return
		goal = _flat(_bike.global_position)
	_this_walk += delta
	if going_to_door and (_trail.is_empty() or _trail[_trail.size() - 1].distance_to(here) > 0.5):
		_trail.append(here)
	if goal.distance_to(_walk_goal) > 0.5:  # a new goal (the door, then the bike): start counting again
		_walk_goal = goal
		_walk_best = INF
		_walk_no_gain = 0.0
	if here.distance_to(goal) < _walk_best - 0.3:
		_walk_best = here.distance_to(goal)
		_walk_no_gain = 0.0
	else:
		_walk_no_gain += delta
	if going_to_door and _walk_no_gain > 6.0 and _on_foot.near_bike():
		# Not getting any closer and the bike is right here: it's probably parked in the way
		# (like in the gym's doorway). Get on, roll back a bit and try again, like a player.
		print("  parked in the way at %s: rolling back" % here)
		_walk_no_gain = 0.0
		_repark_left = 1.5
		_on_foot.toggle()
		return
	if not going_to_door and _walk_no_gain > 6.0 and _trail.size() > 1:
		# Not getting any closer to the bike (stuck inside a doorway): walk back out the way
		# we came in.
		_walk_no_gain = 0.0
		_walk_route = _trail.duplicate()
		_walk_route.reverse()
		_walk_route.append(goal)
		_trail.clear()
	elif not going_to_door and _walk_no_gain > 12.0:
		# Still stuck and no trail left (inside a restaurant, behind its glass front): walk to
		# the nearest restaurant's own door first, then out to the bike, like a player would.
		_walk_no_gain = 0.0
		var exit := _nearest_restaurant_exit(here)
		if not exit.is_empty():
			_walk_route.assign(exit)
			_walk_route.append(goal)
			_exit_left = 15.0  # follow it; don't plan a new route through the glass straight away
			print("  stuck inside at %s: walking out by the door" % here)
	if int(_this_walk / 20.0) != int((_this_walk - delta) / 20.0):
		_say_walk_trouble(here, goal, going_to_door)
	# Walk round things too: a route from the grid, found again if we stop moving.
	_walk_stuck = _walk_stuck + delta if here.distance_to(_walk_last) < 0.01 else 0.0
	_walk_last = here
	_exit_left = maxf(_exit_left - delta, 0.0)
	if _walk_route.is_empty() or _walk_route[_walk_route.size() - 1].distance_to(goal) > 0.5 or (_walk_stuck > 1.0 and _exit_left <= 0.0):
		var from := _reachable_start(here)
		if _walk_stuck > 1.0:
			# Bumped into something the map scan doesn't know (like the parked bike):
			# step sideways first, on the side away from the bike, if we can get there.
			var side := (goal - here).normalized().orthogonal() * 1.6
			if (here + side).distance_to(_flat(_bike.global_position)) < (here - side).distance_to(_flat(_bike.global_position)):
				side = -side
			for step in [side, -side]:
				if _grid.is_free(here + step) and _can_walk(here, here + step):
					from = here + step
					break
		_walk_stuck = 0.0
		_walk_route = _grid.path(from, goal)
		if _walk_route.is_empty() and not going_to_door and _trail.size() > 1:
			# No way out on the map (restaurant doorways are too narrow for its squares):
			# walk back out the way we came in.
			_walk_route = _trail.duplicate()
			_walk_route.reverse()
			_trail.clear()
		if not _walk_route.is_empty():
			_walk_route.pop_front()  # that's where we are
		if from != here:
			_walk_route.push_front(from)
		_walk_route.append(goal)
	while _walk_route.size() > 1 and here.distance_to(_walk_route[0]) < 0.8:
		_walk_route.pop_front()
	var forward := -walker.global_basis.z
	var turn := Vector2(forward.x, forward.z).normalized().angle_to((_walk_route[0] - here).normalized())
	if turn > 0.1:
		Input.action_press("steer_right")
	elif turn < -0.1:
		Input.action_press("steer_left")
	if absf(turn) < 0.6:
		Input.action_press("move_forward")


## Receptions are deliberately a longer walk from the parked bike. A neighbour's
## doorstep still uses the bike when it moves away; an indoor counter stays on foot.
func _inside_delivery() -> bool:
	if _gs.current_order == null:
		return false
	var order: Order = _gs.current_order
	var places: Node = _dm.place_builder
	var entries: Array = places.restaurants if _gs.stage_name() == "TO_RESTAURANT" else places.villas
	for place: Dictionary in entries:
		if (_gs.stage_name() == "TO_RESTAURANT" and place.get("id", "") == order.restaurant_id) \
				or (_gs.stage_name() == "TO_VILLA" and place.get("number", 0) == order.villa_number):
			return place.get("interior", false)
	return false


func _ride(delta: float) -> void:
	var door: Vector3 = _dm.target_door()
	var key: String = "%s %s" % [_gs.stage_name(), door]
	if key != _route_for:
		_route_for = key
		_backups = 0
		_best_left = INF
		_plan(_flat(_bike.global_position), _flat(door))
	if _bike.fallen_left > 0.0 or _bike.wrecked:
		_let_go()  # lying on the ground after a crash: wait, then back away from what we hit
		_back_left = BACK_UP_TIME
		_stuck_time = 0.0
		return
	if _repark_left > 0.0:
		# We parked in our own way (in a narrow doorway): roll back a little, then get off again.
		_repark_left -= delta
		_let_go()
		Input.action_press("move_back")
		return
	if _dm.is_near_target():
		_let_go()
		if absf(_bike.speed) < 0.5:
			_walked_for = ""
			_this_walk = 0.0
			_walk_best = INF
			_walk_no_gain = 0.0
			_door_when_parked = _flat(door)
			_trail.clear()
			_on_foot.toggle()  # F: get off and walk to the door (Session 19)
		else:
			Input.action_press("move_back")
		return
	if _back_left > 0.0:
		_back_up(delta)
		return
	_follow(delta)


## Backing up (S) after bumping into something, steering so the nose swings towards the
## route. Rolling backwards flips the steering (scripts/bike.gd), so press the other way.
func _back_up(delta: float) -> void:
	_back_left -= delta
	_let_go()
	if _bike.speed > 0.3:
		Input.action_press("move_back")  # still rolling forwards: brake first
		return
	Input.action_press("move_back")
	var turn := _aim_angle(3.0)
	if turn > 0.1:
		Input.action_press("steer_left")
	elif turn < -0.1:
		Input.action_press("steer_right")
	if _back_left <= 0.0:
		_route_for = ""  # find a fresh route from here


## Follows the route like a careful rider: aims at a spot a little way ahead on the route
## (further ahead when going faster), and picks a speed that leaves room to slow down for
## the next corner, speed bump or the door.
func _follow(delta: float) -> void:
	var here := _flat(_bike.global_position)
	var v: float = maxf(_bike.speed, 0.0)
	_advance(here)
	var look := clampf(LOOK_AHEAD + 0.45 * v, LOOK_AHEAD, 5.5)
	if _grid.wall_distance(here) < 3:
		look = minf(look, 2.0)  # tight shop/row exits need a sharper, slower turn
	var turn := _aim_angle(look, _careless)
	_let_go()
	# Pure pursuit: the curve that reaches the aim spot needs this much turning.
	var need := 2.0 * sin(turn) / look * maxf(v, 0.5)  # radians per second
	var steer := clampf(need / maxf(_turn_rate(v), 0.2), -1.0, 1.0)
	if absf(turn) > 0.9:
		steer = signf(turn)
	if steer > 0.03:
		Input.action_press("steer_right", steer)
	elif steer < -0.03:
		Input.action_press("steer_left", -steer)
	var left := _cum[_cum.size() - 1] - _cum[_idx]
	# The door: stop about 2 m before it (E works from INTERACT_RADIUS).
	var limit := _entry_speed(0.0, left - 2.0)
	limit = maxf(limit, 1.2)  # always creep the last bit
	var max_speed := GameConfig.BIKE_MAX_SPEED_KMH / 3.6
	if _careless:
		limit = minf(limit if left < 12.0 else max_speed, max_speed)
	else:
		limit = minf(limit, _corner_limit())
		for bump in _bumps:
			var ahead: Vector2 = bump - here
			if ahead.length() < 20.0 and ahead.normalized().dot(_heading()) > 0.7:
				limit = minf(limit, _entry_speed(BUMP_KMH / 3.6, ahead.length() - 2.0))
		if absf(turn) > 0.9:
			limit = minf(limit, 6.0 / 3.6)  # the route is behind us: turn round slowly
		for critter in get_nodes_in_group("critter"):  # cats and kids: slow right down
			var ahead: Vector2 = _flat((critter as Node3D).global_position) - here
			var along := ahead.dot(_heading())
			if along > -1.0 and along < 14.0 and absf(ahead.cross(_heading())) < 3.0:
				limit = minf(limit, _entry_speed(CRITTER_KMH / 3.6, along - 2.5))
		if _critter_in_way(here):
			limit = 0.0  # right in front of us: stop and let it move (cats run, kids turn back)
		var gap := _space_ahead()
		if gap < 7.0:
			limit = minf(limit, _entry_speed(0.8, gap - 1.5))  # something solid ahead
	_set_speed(minf(limit, max_speed))
	_check_stuck(delta, here, turn)


## Pedal, coast or brake to ride at about this speed (m/s). A careful rider never brakes
## hard at full speed (that's a "hard brake" that spills drinks): he coasts down first.
func _set_speed(want: float) -> void:
	var v: float = _bike.speed
	if v < want - 0.15:
		Input.action_press("move_forward")
	elif v > want + 0.25:
		if _careless or v * 3.6 < GameConfig.HARD_BRAKE_MIN_KMH - 1.0:
			Input.action_press("move_back", clampf((v - want) * 0.5, 0.25, 1.0))


## Nothing moved for a while although we want to go: back up a bit and find a new route.
## After too many tries, press R (back to the start) as a last resort.
func _check_stuck(delta: float, here: Vector2, turn: float) -> void:
	var left := here.distance_to(_pts[_pts.size() - 1])
	if left < _best_left - 4.0:
		_best_left = left
		_backups = 0
	var blocked: bool = absf(_bike.speed) < 0.3 or (_space_ahead() < 1.3 and absf(turn) > 0.5 and _bike.speed < 1.5)
	_stuck_time = _stuck_time + delta if blocked else 0.0
	if _stuck_time < 0.8 or (_stuck_time < 6.0 and not _careless and _critter_in_way(here)):
		return
	_stuck_time = 0.0
	_backups += 1
	if _backups <= 5:
		_back_left = BACK_UP_TIME
		_backed_up += 1
		if _timeline:
			print("    backing up at %s, %.0f m from the door, space ahead %.1f, turn %.1f" % [_bike.global_position, left, _space_ahead(), turn])
		return
	print("  stuck at %s, %.0f m from the door, space ahead %.1f, stage %s: reset" % [_bike.global_position, left, _space_ahead(), _gs.stage_name()])
	_bike.reset_to_start()
	_resets += 1
	_route_for = ""


## Moves our place on the route on to the route point closest to the bike.
func _advance(here: Vector2) -> void:
	var best := here.distance_squared_to(_pts[_idx])
	var i := _idx + 1
	while i < _pts.size() and i < _idx + 30:
		var d := here.distance_squared_to(_pts[i])
		if d < best:
			best = d
			_idx = i
		i += 1


## The angle from where the bike points to the spot this far ahead on the route
## (+ means turn right).
func _aim_angle(look: float, careless := true) -> float:
	var goal_s := _cum[_idx] + look
	var j := _idx
	while j < _pts.size() - 1 and _cum[j] < goal_s:
		j += 1
	var here := _flat(_bike.global_position)
	var want := _pts[j] + (Vector2.ZERO if careless else _dodge(here, _pts[j])) - here
	if want.length() < 0.3:
		return 0.0
	return _heading().angle_to(want.normalized())


## A careful rider rides round a cat or kid on the route ahead: this moves the aim spot
## sideways, to whichever side has more room.
func _dodge(here: Vector2, aim: Vector2) -> Vector2:
	var along_route := (aim - here).normalized()
	var side := Vector2(-along_route.y, along_route.x)
	for critter in get_nodes_in_group("critter"):
		var ahead: Vector2 = _flat((critter as Node3D).global_position) - here
		var along := ahead.dot(along_route)
		var beside := ahead.dot(side)
		if along < 0.0 or along > 14.0 or absf(beside) > 2.6:
			continue
		var way := -signf(beside) if absf(beside) > 0.4 else 1.0
		if absf(beside) <= 0.4 and _grid.wall_distance(here + ahead - side * 2.0) > _grid.wall_distance(here + ahead + side * 2.0):
			way = -1.0
		return side * way * (2.6 - absf(beside))
	return Vector2.ZERO


## True if a cat or kid is just in front of the bike.
func _critter_in_way(here: Vector2) -> bool:
	for critter in get_nodes_in_group("critter"):
		var ahead: Vector2 = _flat((critter as Node3D).global_position) - here
		var along := ahead.dot(_heading())
		if along > 0.0 and along < 3.2 and absf(ahead.cross(_heading())) < 1.3:
			return true
	return false


## The slowest speed (m/s) any corner ahead asks for, allowing room to slow down for it.
func _corner_limit() -> float:
	var limit := INF
	for corner in _corners:
		var ahead: float = corner[0] - _cum[_idx]
		if ahead < -1.5 or ahead > 30.0:
			continue
		limit = minf(limit, _entry_speed(corner[1], ahead - 1.0))
	return limit


## How fast you can be going now to get down to `target` (m/s) within `room` metres:
## coasting above HARD_BRAKE_MIN_KMH (about 1 m/s per second), gentle braking below it.
func _entry_speed(target: float, room: float) -> float:
	room = maxf(room, 0.0)
	var brake_from := (GameConfig.HARD_BRAKE_MIN_KMH - 2.0) / 3.6
	if target >= brake_from:
		return sqrt(target * target + 2.0 * COAST_SLOW * room)
	var braking := (brake_from * brake_from - target * target) / (2.0 * BRAKE_SLOW)
	if room <= braking:
		return sqrt(target * target + 2.0 * BRAKE_SLOW * room)
	return sqrt(brake_from * brake_from + 2.0 * COAST_SLOW * (room - braking))


## How fast the bike can turn at this speed (radians per second, full steering),
## the same sum as scripts/bike.gd _update_steering.
func _turn_rate(v: float) -> float:
	var ratio := clampf(absf(v) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
	var grip := clampf(ratio * 3.0, 0.0, 1.0) * lerpf(1.0, 0.6, ratio)
	return deg_to_rad(GameConfig.BIKE_STEER_DEG_PER_SEC) * grip


## The fastest speed (m/s) for a corner that turns this many radians: a sharp corner in a
## narrow lane needs a tight circle, and the bike turns tighter when it goes slower.
func _corner_speed(angle: float) -> float:
	if angle < 0.2:
		return INF
	# The circle round a corner is about CORNER_ROOM / angle metres wide; going round it
	# at speed v needs v / radius radians per second, which must stay under 70% of the
	# bike's turning rate at that speed. Try speeds from fast to slow.
	var radius := CORNER_ROOM / angle
	var v := GameConfig.BIKE_MAX_SPEED_KMH / 3.6
	while v > 1.0 and v / radius > 0.7 * _turn_rate(v):
		v -= 0.1
	return v


func _heading() -> Vector2:
	var forward := -_bike.global_basis.z
	return Vector2(forward.x, forward.z).normalized()


## Metres of free space straight ahead (up to 7), like a careful rider looking ahead.
func _space_ahead() -> float:
	var from := _bike.global_position + Vector3.UP * 0.9
	var ahead := -_bike.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(from, from + ahead * 7.0)
	query.exclude = [_bike.get_rid()]
	var hit := _bike.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["collider"] is Node and (hit["collider"] as Node).is_in_group("critter")):
		return 99.0
	return from.distance_to(hit["position"])


## Route from here to a door, from the grid (tests/grid_path.gd), turned into points every
## half metre (_pts, with the distance along the route in _cum) and the corners on it
## (_corners: [distance along the route, fastest speed round it]).
func _plan(from: Vector2, door: Vector2) -> void:
	var points: Array[Vector2] = _grid.path(from, door)
	if points.is_empty():
		points.append(from)
	points[0] = from
	if points[points.size() - 1].distance_to(door) > 0.3:
		points.append(door)
	_pts = [from]
	_cum = [0.0]
	_corners = []
	for k in range(1, points.size()):
		var a: Vector2 = points[k - 1]
		var b: Vector2 = points[k]
		var steps := maxi(ceili(a.distance_to(b) / 0.5), 1)
		for n in range(1, steps + 1):
			var spot := a.lerp(b, float(n) / steps)
			_cum.append(_cum[_cum.size() - 1] + _pts[_pts.size() - 1].distance_to(spot))
			_pts.append(spot)
		if k < points.size() - 1:
			var angle := absf((b - a).angle_to(points[k + 1] - b))
			_corners.append([_cum[_cum.size() - 1], _corner_speed(angle)])
	_idx = 0


## Half the map size, from the map's data list.
func _map_half() -> Vector2:
	var places: Node = _main.get_node("PlaceBuilder")
	var data: Dictionary = places.data.get_script_constant_map()
	if data.has("MAP_HALF"):
		return data["MAP_HALF"]
	if data.has("HALF_SIZE"):
		return Vector2.ONE * float(data["HALF_SIZE"])
	return Vector2(100, 100)


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _let_go() -> void:
	for action in ["move_forward", "move_back", "steer_left", "steer_right", "sprint", "handbrake", "interact"]:
		Input.action_release(action)


func _on_shift_ended(summary: Dictionary) -> void:
	_done = true
	_let_go()
	print("\n#  food        villa  ride s  target s  time%  fresh%  damage%  stars  pay  tip  special / regular")
	var i := 0
	var late := 0
	for job in _gs.history.slice(_gs.shift_start_index):
		var ride: Array = _rides[i] if i < _rides.size() else [0.0, 0.0]
		i += 1
		late += 1 if ride[0] > ride[1] else 0
		print("%-2d %-11s %5d  %6.0f  %8.0f  %5.0f  %6.0f  %7.0f  %5.1f  %3d  %3d  %s" % [i, job["food"], job["villa"],
				ride[0], ride[1], job["time"], job["freshness"], job["damage"], job["stars"], job["pay"], job["tip"],
				(job.get("special", "") + " " + job.get("regular", "")).strip_edges()])
	print("Rides slower than the target time: %d of %d" % [late, i])
	for goal in summary.get("goals", []):  # Session 32
		print("Goal: %s  %s" % [goal["text"], "DONE +%d Dh" % GameConfig.GOAL_BONUS if goal["done"] else "not done"])
	print("\nShift summary: %d deliveries, %d cancelled, %.2f average stars" % [summary["deliveries"], summary["cancelled"], summary["stars"]])
	print("Pay %d + tips %d + goals %d - insurance %d - bills %d = earned %d Dh, %d XP (Rider Level %d)" % [
			summary["pay"], summary["tips"], summary.get("goal_bonus", 0), summary["insurance"], summary["bills"], summary["earned"], summary["xp"], _gs.level()])
	print("Crashes: %d small, %d big. Times backed up: %d. Times stuck and reset: %d. Time spent walking: %.0f s" % [
			_crashes["small"], _crashes["big"], _backed_up, _resets, _walk_time])
	_completed_shifts += 1
	_balance.append({"shift":_completed_shifts,"day":_gs.day_kind,"deliveries":summary["deliveries"],
		"earned":summary["earned"],"stars":summary["stars"],"wallet":_gs.money,"xp":_gs.xp,"level":_gs.level(),
		"small_crashes":_crashes["small"],"major_crashes":_crashes["big"],"resets":_resets,
		"next_upgrade":GearCatalog.next_goal(_gs)})
	if _completed_shifts < _shift_count:
		_start_next_bot_shift.call_deferred()
		return
	print("BOT_BALANCE: ", JSON.stringify(_balance))
	FileAccess.open("user://bot_balance.json", FileAccess.WRITE).store_string(JSON.stringify(_balance, "  "))
	# Flush the pending end-of-shift save before deleting only this bot's fixture.
	_gs.save_game()
	SaveGame.delete("user://playtest_bot_save.json")
	quit()


func _start_next_bot_shift() -> void:
	# Buy the first attainable upgrade through the same atomic cart players use.
	if _gs.upgrade_level("gps") == 0 and _gs.level() >= 2 and _gs.money >= GameConfig.GEAR_PRICES["gps"]:
		var cart := ShopCart.new(_gs)
		cart.add("gps")
		var purchase := cart.checkout()
		print("BOT_PURCHASE: ", JSON.stringify(purchase))
		var shop := _main.get_node_or_null("ShopController")
		if shop != null:
			shop.apply_equipment()
	_main.get_node("ShiftScreen")._next_shift()
	_frames = 0
	_pts.clear()
	_cum.clear()
	_corners.clear()
	_route_for = ""
	_back_left = 0.0
	_backups = 0
	_best_left = INF
	_backed_up = 0
	_stuck_time = 0.0
	_resets = 0
	_rides.clear()
	_walk_time = 0.0
	_walked_for = ""
	_walk_route.clear()
	_walk_stuck = 0.0
	_this_walk = 0.0
	_crashes = {"small":0,"big":0}
	_grid = null
	_rescan_at = -1
	_done = false
	print("BOT_SHIFT_STARTED: ", _completed_shifts + 1, " · ", _gs.day_kind)


## A walk is taking long (every 20 s of it): say where we are, where to, and what's close by.
func _say_walk_trouble(here: Vector2, goal: Vector2, to_door: bool) -> void:
	var near := []
	for node in get_nodes_in_group("critter"):
		var n := node as Node3D
		if n != null and _flat(n.global_position).distance_to(here) < 4.0:
			near.append("%s %.1f m" % [n.name, _flat(n.global_position).distance_to(here)])
	print("  walk taking long: %.0f s at %s, going to %s (%s, %.1f m away), near: %s" % [_this_walk, here,
			"the door" if to_door else "the bike", goal, here.distance_to(goal), ", ".join(near)])



## The inside and outside of the nearest walk-in building's door (a restaurant, the gym or the
## C Institute), for walking out of it.
func _nearest_restaurant_exit(here: Vector2) -> Array:
	var places: Node = _dm.place_builder
	var best: Array = []
	var best_gap := 40.0
	for place: Dictionary in places.restaurants:
		var inside := _flat(places.restaurant_entrance(place["id"]))
		var outside := _flat(places.restaurant_approach(place["id"]))
		var gap := here.distance_to(inside)
		if gap < best_gap:
			best_gap = gap
			best = [inside + (inside - outside).normalized() * 1.5, inside, outside]
	for place: Dictionary in places.villas:
		if not place.get("interior", false):
			continue
		var outside := _flat(places.villa_approach(place["number"]))
		var middle := _flat(place["position"])
		var gap := here.distance_to(middle)
		if gap < best_gap:
			best_gap = gap
			var inward := (middle - outside).normalized()
			best = [outside + inward * 4.0, outside + inward * 1.0, outside]
	return best


## Where to plan a walk from. Pressed against a wall (like the C Institute's glass front), the
## map square we stand on counts as the wall, and the nearest free square can be on the far
## side of it (inside the building), so a route from there goes straight through the glass.
## Pick a free square nearby that we can actually walk to (nothing solid in between).
func _reachable_start(spot: Vector2) -> Vector2:
	if _grid.is_free(spot):
		return spot
	for reach in [0.8, 1.5, 2.2]:
		for i in 8:
			var way := Vector2.RIGHT.rotated(TAU * i / 8.0)
			var spot2: Vector2 = spot + way * reach
			if _grid.is_free(spot2) and _can_walk(spot, spot2):
				return spot2
	return spot


## True if nothing solid (but us and the bike) stands between two spots, at waist height.
func _can_walk(from: Vector2, to: Vector2) -> bool:
	var space := (_main as Node3D).get_world_3d().direct_space_state
	var look := PhysicsRayQueryParameters3D.create(Vector3(from.x, 0.9, from.y), Vector3(to.x, 0.9, to.y))
	look.exclude = [(_on_foot.walker as CollisionObject3D).get_rid(), _bike.get_rid()]
	return space.intersect_ray(look).is_empty()
