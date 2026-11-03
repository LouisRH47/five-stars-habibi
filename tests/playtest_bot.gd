extends SceneTree
## Play-test bot (Session 17): rides a whole shift in Palm Grove like a careful player and
## prints how it went. It really rides the bike (same physics and keys as a player):
## it plans a route along the roads, goes round the roundabout, slows down for corners and
## speed bumps, accepts every order, picks up and delivers. At the end it prints each
## delivery (ride time vs target, the three meters, stars, pay) and the shift summary.
## Use it to tune the numbers in scripts/game_config.gd. Run it with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless --fixed-fps 60 -s tests/playtest_bot.gd
## (--fixed-fps 60 makes it run faster than real time.) Add "-- careless" to ride flat out
## without slowing for bumps or corners, to see what a rushed rider gets.

const ROAD_NODES := {  # crossings, as (x, z)
	"gate": Vector2(0, 147), "dp_mid": Vector2(0, 90), "centre": Vector2(0, 0), "ghaf_mid": Vector2(0, -90),
	"dp_w": Vector2(-90, 90), "oasis_w": Vector2(-90, 0), "ghaf_w": Vector2(-90, -90),
	"dp_e": Vector2(90, 90), "oasis_e": Vector2(90, 0), "ghaf_e": Vector2(90, -90),
}
const ROAD_EDGES := [
	["gate", "dp_mid"], ["dp_mid", "centre"], ["centre", "ghaf_mid"],
	["dp_w", "dp_mid"], ["dp_mid", "dp_e"], ["oasis_w", "centre"], ["centre", "oasis_e"],
	["ghaf_w", "ghaf_mid"], ["ghaf_mid", "ghaf_e"],
	["ghaf_w", "oasis_w"], ["oasis_w", "dp_w"], ["ghaf_e", "oasis_e"], ["oasis_e", "dp_e"],
]
const RING := 12.0          # metres from the roundabout's middle the bot rides round
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
var _crashes := {"small": 0, "big": 0}
var _frames := 0


func _initialize() -> void:
	_careless = "careless" in OS.get_cmdline_user_args()
	_gs = root.get_node("GameState")
	_gs.save_path = "user://playtest_bot_save.json"
	_gs.new_game()
	_gs.hire("Bot", "Somewhere else", 0)
	_gs.tutorial_done = true
	_main = load("res://scenes/palm_grove.tscn").instantiate()
	root.add_child(_main)
	_bike = _main.get_node("Bike")
	_dm = _main.get_node("DeliveryManager")
	_gs.shift_ended.connect(_on_shift_ended)
	_gs.order_delivered.connect(func(_order): _rides.append([_gs.ride_time, _gs.target_time]))
	_bike.crashed.connect(func(big): _crashes["big" if big else "small"] += 1)
	print("Play-test bot: one full shift, %s rider" % ("careless" if _careless else "careful"))


func _physics_process(delta: float) -> bool:
	if _done:
		return false
	_frames += 1
	if _frames > 60 * 60 * 15:  # safety: never run longer than 15 game minutes
		print("Bot gave up: the shift never ended")
		_on_shift_ended(_gs.shift_summary())
		return false
	var clinic := _main.get_node("ClinicScreen")
	if clinic.showing:
		_let_go()
		clinic.close()  # OK, back to work (this ends the shift)
		return false
	if _bumps.is_empty():
		for bump in _main.get_node("DecorBuilder").speed_bumps:
			_bumps.append(Vector2(bump["position"].x, bump["position"].z))
	match _gs.stage_name():
		"OFFERED":
			_dm.accept()
		"TO_RESTAURANT", "TO_VILLA":
			_ride(delta)
		_:
			_let_go()
	return false


func _ride(delta: float) -> void:
	var door: Vector3 = _dm.target_door()
	var key: String = "%s %s" % [_gs.stage_name(), door]
	if key != _route_for:
		_route_for = key
		_route = _plan(Vector2(_bike.global_position.x, _bike.global_position.z), Vector2(door.x, door.z))
	if _dm.is_near_target():
		_let_go()
		if absf(_bike.speed) < 0.5:
			_dm.try_interact()
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
	var kmh := absf(_bike.speed) * 3.6
	if kmh < limit:
		Input.action_press("move_forward")
	elif kmh > limit + 6.0:
		Input.action_press("move_back")  # brake only when much too fast; otherwise just coast
	# Got stuck against something? Back up and try again; after a long time, press R.
	_stuck_time = _stuck_time + delta if _bike.global_position.distance_to(_last_spot) < 0.02 else 0.0
	_last_spot = _bike.global_position
	if _stuck_time > 6.0:
		_bike.reset_to_start()
		_resets += 1
		_route_for = ""
		_stuck_time = 0.0


func _sharp_next() -> bool:
	if _route.size() < 2:
		return false
	var here := _flat(_bike.global_position)
	var a := (_route[0] - here).normalized()
	var b := (_route[1] - _route[0]).normalized()
	return absf(a.angle_to(b)) > 0.6


## Route from here to a door: onto the nearest road, along the roads (round the
## roundabout), off the road to the door.
func _plan(from: Vector2, door: Vector2) -> Array[Vector2]:
	var start := _on_road(from)
	var finish := _on_road(door)
	var graph := {}
	for node in ROAD_NODES:
		graph[node] = {}
	for edge in ROAD_EDGES:
		var d: float = ROAD_NODES[edge[0]].distance_to(ROAD_NODES[edge[1]])
		graph[edge[0]][edge[1]] = d
		graph[edge[1]][edge[0]] = d
	var spots := ROAD_NODES.duplicate()
	for pair in [["S", start], ["F", finish]]:
		spots[pair[0]] = pair[1]["spot"]
		graph[pair[0]] = {}
		for end in pair[1]["edge"]:
			var d: float = pair[1]["spot"].distance_to(ROAD_NODES[end])
			graph[pair[0]][end] = d
			graph[end][pair[0]] = d
	if start["edge"] == finish["edge"]:
		var d: float = start["spot"].distance_to(finish["spot"])
		graph["S"]["F"] = d
		graph["F"]["S"] = d
	var names := _shortest(graph, "S", "F")
	var points: Array[Vector2] = []
	for i in names.size():
		var name: String = names[i]
		if name == "centre" and i > 0 and i < names.size() - 1:
			points.append_array(_round_about(spots[names[i - 1]], spots[names[i + 1]]))
		else:
			points.append(spots[name])
	points.append(door)
	return points


func _round_about(from: Vector2, to: Vector2) -> Array[Vector2]:
	var a_in := from.angle()
	var a_out := to.angle()
	var gap := wrapf(a_out - a_in, -PI, PI)
	var points: Array[Vector2] = []
	var steps := maxi(2, ceili(absf(gap) / (PI / 4.0)))
	for k in steps + 1:
		points.append(Vector2.from_angle(a_in + gap * float(k) / steps) * RING)
	return points


## The closest point on any road, and which crossing-to-crossing road it's on.
func _on_road(p: Vector2) -> Dictionary:
	var best := {"spot": p, "edge": ROAD_EDGES[0], "gap": INF}
	for edge in ROAD_EDGES:
		var a: Vector2 = ROAD_NODES[edge[0]]
		var b: Vector2 = ROAD_NODES[edge[1]]
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var spot := a.lerp(b, t)
		if spot.distance_to(p) < best["gap"]:
			best = {"spot": spot, "edge": edge, "gap": spot.distance_to(p)}
	return best


func _shortest(graph: Dictionary, from: String, to: String) -> Array:
	var dist := {from: 0.0}
	var back := {}
	var open := [from]
	while not open.is_empty():
		open.sort_custom(func(x, y): return dist[x] < dist[y])
		var node: String = open.pop_front()
		if node == to:
			break
		for next in graph[node]:
			var d: float = dist[node] + graph[node][next]
			if d < dist.get(next, INF):
				dist[next] = d
				back[next] = node
				if not next in open:
					open.append(next)
	var path := [to]
	while path[0] != from and back.has(path[0]):
		path.push_front(back[path[0]])
	return path


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _let_go() -> void:
	for action in ["move_forward", "move_back", "steer_left", "steer_right", "sprint", "handbrake"]:
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
	print("Crashes: %d small, %d big. Times stuck and reset: %d" % [_crashes["small"], _crashes["big"], _resets])
	SaveGame.delete("user://playtest_bot_save.json")
	_gs.save_path = "user://none/never.json"
	quit()
