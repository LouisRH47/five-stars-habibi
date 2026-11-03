extends SceneTree
## Play-test bot (Session 17, map-agnostic since Session 25): rides a whole shift like a
## careful player and prints how it went. It really rides the bike (same physics and keys as
## a player): it finds a route with tests/grid_path.gd, slows down for corners and speed
## bumps, accepts every order, gets off at the door, walks over, holds E, walks back, gets
## on. At the end it prints each delivery (ride time vs target, the three meters, stars, pay)
## and the shift summary. Use it to tune the numbers in scripts/game_config.gd. Run it with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless --fixed-fps 60 -s tests/playtest_bot.gd
## (--fixed-fps 60 makes it run faster than real time.) Add "-- careless" to ride flat out
## without slowing for bumps or corners, and/or a scene path ("-- res://scenes/palm_grove.tscn").

const GRID := preload("res://tests/grid_path.gd")
const REACHED := 3.0        # metres: close enough to a waypoint
const CORNER_KMH := 11.0    # slow to this for sharp turns
const BUMP_KMH := 9.0       # slow to this for speed bumps (careful rider)

var _main: Node
var _bike: CharacterBody3D
var _gs: Node
var _dm: Node
var _route: Array[Vector2] = []
var _route_for := ""
var _bumps: Array = []
var _careless := false
var _stuck_time := 0.0
var _last_spot := Vector3.ZERO
var _resets := 0
var _done := false
var _rides: Array = []  # [ride seconds, target seconds] per delivery
var _on_foot: Node
var _walk_time := 0.0  # seconds spent walking (Session 19)
var _walked_for := ""  # the stage the last walk to a door was for (done once it changes)
var _crashes := {"small": 0, "big": 0}
var _frames := 0
var _grid: RefCounted


func _initialize() -> void:
	_careless = "careless" in OS.get_cmdline_user_args()
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
	_gs.order_delivered.connect(func(_order): _rides.append([_gs.ride_time, _gs.target_time]))
	_bike.crashed.connect(func(big):
		_crashes["big" if big else "small"] += 1
		print("  crash (%s): %s at %.0f km/h, at %s" % ["big" if big else "small", _bike.last_crash["what"], _bike.last_crash["kmh"], _bike.global_position]))
	print("Play-test bot: one full shift, %s rider" % ("careless" if _careless else "careful"))


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
	if _grid == null or _grid.solid_count == 0:
		if _frames < 10:
			return false  # let the map build and get into the physics world first
		_grid = GRID.new()
		_grid.clearance = 1.0  # ride down the middle of lanes, not along the walls
		_grid.build(_bike.get_world_3d(), _map_half(), [_bike, _on_foot.walker])
		print("Map scanned: %d blocked squares" % _grid.solid_count)
		if _grid.solid_count == 0:
			return false  # not ready yet: try again next frame
	if _bumps.is_empty():
		for bump in _main.get_node("DecorBuilder").speed_bumps:
			_bumps.append(Vector2(bump["position"].x, bump["position"].z))
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
	var goal: Vector3 = _dm.target_door() if going_to_door else _bike.global_position
	var walker: Node3D = _on_foot.walker
	var forward := -walker.global_basis.z
	var turn := Vector2(forward.x, forward.z).normalized().angle_to(Vector2(goal.x - walker.global_position.x, goal.z - walker.global_position.z).normalized())
	if turn > 0.1:
		Input.action_press("steer_right")
	elif turn < -0.1:
		Input.action_press("steer_left")
	if absf(turn) < 0.6:
		Input.action_press("move_forward")


func _ride(delta: float) -> void:
	var door: Vector3 = _dm.target_door()
	var key: String = "%s %s" % [_gs.stage_name(), door]
	if key != _route_for:
		_route_for = key
		_route = _plan(Vector2(_bike.global_position.x, _bike.global_position.z), Vector2(door.x, door.z))
	if _dm.is_near_target():
		_let_go()
		if absf(_bike.speed) < 0.5:
			_walked_for = ""
			_on_foot.toggle()  # F: get off and walk to the door (Session 19)
		else:
			Input.action_press("move_back")
		return
	while _route.size() > 1 and _flat(_bike.global_position).distance_to(_route[0]) < REACHED:
		_route.pop_front()
	_steer_to(_route[0], delta)


func _steer_to(goal: Vector2, delta: float) -> void:
	var here := _flat(_bike.global_position)
	var forward := -_bike.global_basis.z
	var heading := Vector2(forward.x, forward.z).normalized()
	var want := (goal - here).normalized()
	var turn := heading.angle_to(want)  # + means turn right (towards +x from -z)
	_let_go()
	if turn > 0.05:
		Input.action_press("steer_right", clampf(turn * 2.0, 0.2, 1.0))
	elif turn < -0.05:
		Input.action_press("steer_left", clampf(-turn * 2.0, 0.2, 1.0))
	var limit := GameConfig.BIKE_MAX_SPEED_KMH
	if not _careless:
		if absf(turn) > 0.6 or (_route.size() > 1 and here.distance_to(goal) < 8.0 and _sharp_next()):
			limit = CORNER_KMH
		for bump in _bumps:
			var ahead: Vector2 = bump - here
			if ahead.length() < 9.0 and ahead.dot(heading) > 0.0:
				limit = BUMP_KMH
	if _route.size() == 1 and here.distance_to(goal) < 10.0:
		limit = minf(limit, 9.0)
	if not _careless:
		var gap := _space_ahead()
		if gap < 7.0:
			limit = minf(limit, 10.0 if gap > 3.0 else 5.0)  # something solid ahead: slow down
	var kmh := absf(_bike.speed) * 3.6
	if kmh < limit:
		Input.action_press("move_forward")
	elif kmh > limit + 6.0:
		Input.action_press("move_back")  # brake only when much too fast; otherwise just coast
	# Got stuck against something? Back up and try again; after a long time, press R.
	_stuck_time = _stuck_time + delta if _bike.global_position.distance_to(_last_spot) < 0.02 else 0.0
	_last_spot = _bike.global_position
	if _stuck_time > 6.0:
		if _resets < 3:
			print("  stuck at %s, next waypoint %s, %d left, space ahead %.1f, stage %s" % [_bike.global_position, _route[0] if not _route.is_empty() else Vector2.ZERO, _route.size(), _space_ahead(), _gs.stage_name()])
		_bike.reset_to_start()
		_resets += 1
		_route_for = ""
		_stuck_time = 0.0


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


func _sharp_next() -> bool:
	if _route.size() < 2:
		return false
	var here := _flat(_bike.global_position)
	var a := (_route[0] - here).normalized()
	var b := (_route[1] - _route[0]).normalized()
	return absf(a.angle_to(b)) > 0.6


## Route from here to a door, from the grid (tests/grid_path.gd).
func _plan(from: Vector2, door: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = _grid.path(from, door)
	if points.is_empty():
		points.append(door)
	if points.size() > 1:
		points.pop_front()  # that's where we are
	points.append(door)
	return points


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
	print("\n#  food        villa  ride s  target s  time%  fresh%  damage%  stars  pay  tip")
	var i := 0
	var late := 0
	for job in _gs.history:
		var ride: Array = _rides[i] if i < _rides.size() else [0.0, 0.0]
		i += 1
		late += 1 if ride[0] > ride[1] else 0
		print("%-2d %-11s %5d  %6.0f  %8.0f  %5.0f  %6.0f  %7.0f  %5.1f  %3d  %3d" % [i, job["food"], job["villa"],
				ride[0], ride[1], job["time"], job["freshness"], job["damage"], job["stars"], job["pay"], job["tip"]])
	print("Rides slower than the target time: %d of %d" % [late, i])
	print("\nShift summary: %d deliveries, %d cancelled, %.2f average stars" % [summary["deliveries"], summary["cancelled"], summary["stars"]])
	print("Pay %d + tips %d - insurance %d - bills %d = earned %d Dh, %d XP (Rider Level %d)" % [
			summary["pay"], summary["tips"], summary["insurance"], summary["bills"], summary["earned"], summary["xp"], _gs.level()])
	print("Crashes: %d small, %d big. Times stuck and reset: %d. Time spent walking: %.0f s" % [_crashes["small"], _crashes["big"], _resets, _walk_time])
	SaveGame.delete("user://playtest_bot_save.json")
	_gs.save_path = "user://none/never.json"
	quit()
