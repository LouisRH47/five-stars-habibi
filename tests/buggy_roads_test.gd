extends SceneTree
## Session 75: golf buggies only drive on roads. Runs every buggy for a whole shift (600 s of
## driving, stepped quickly) and checks, all the way: the buggy's whole footprint stays on
## asphalt, it keeps to its side of the yellow line (the right), and it slows down at the
## junctions and the roundabout.
## Run: godot --path . --headless --fixed-fps 60 -s tests/buggy_roads_test.gd

const STEP := 0.1          # seconds per step
const SIDE_SLACK := 0.3    # metres right of the middle line it must at least be

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = OS.get_cache_dir().path_join("buggy_roads_test.json")
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	for frame in 8:
		await physics_frame
	world.get_node("EventManager").enabled = false
	world.get_node("DeliveryManager").set_physics_process(false)  # the bike waits at the bus station
	var roads: RoadMesh = world.get_node("WahatBuilder/Roads")
	var area: RoadArea = roads.area
	var life: Node = world.get_node("LifeBuilder")
	var buggies: Array = life.movers.filter(func(m): return m.kind == "buggy")
	_expect(buggies.size() == WahatAlShams.BUGGIES.size(), "every buggy was built", str(buggies.size()))
	for mover in life.movers + life.extra_movers:
		mover.set_physics_process(false)  # we drive them by hand, quickly
	var steps := int(GameConfig.SHIFT_LENGTH / STEP)
	for buggy in buggies:  # (untyped: a SceneTree script can't name classes that need autoloads)
		var off_road := 0
		var wrong_side := 0
		var first_off := ""
		var slow_metres := 0.0
		var slow_time := 0.0
		var fast_metres := 0.0
		var fast_time := 0.0
		var last: Vector3 = buggy.position
		var route_start: Vector3 = buggy.points[0]
		var turning_left := 0   # steps left of a U-turn (something blocked it: it crosses over)
		var u_turns := 0
		var u_turn_next := -1  # the point it's heading for just after a U-turn
		for i in steps:
			buggy._physics_process(STEP)
			if buggy.points[0] != route_start:
				route_start = buggy.points[0]
				turning_left = 60
				u_turn_next = buggy._next
				u_turns += 1
			turning_left -= 1
			# After a U-turn it crosses over to its own side on the way to the next point.
			if u_turn_next >= 0 and buggy._next == u_turn_next:
				turning_left = maxi(turning_left, 1)
			else:
				u_turn_next = -1
			var moved: Vector3 = buggy.position - last
			last = buggy.position
			var flat := Vector2(buggy.position.x, buggy.position.z)
			# The whole footprint (its four corners) on asphalt.
			var ahead := Vector2(-sin(buggy.rotation.y), -cos(buggy.rotation.y))
			var right := Vector2(-ahead.y, ahead.x)
			for corner in [ahead * 1.2 + right * 0.65, ahead * 1.2 - right * 0.65, -ahead * 1.2 + right * 0.65, -ahead * 1.2 - right * 0.65]:
				if not area.on_asphalt(flat + corner, -0.1):
					off_road += 1
					if first_off == "":
						first_off = "%s" % (flat + corner)
					break
			var slow: bool = buggy.pace_share() < 0.99
			if slow:
				slow_metres += moved.length()
				slow_time += STEP
			else:
				fast_metres += moved.length()
				fast_time += STEP
			# Its side of the yellow line, away from junctions (where it turns across).
			if not slow and moved.length() > 0.05 and turning_left <= 0:
				var travel := Vector2(moved.x, moved.z).normalized()
				var side := _side_of_middle(roads, flat, travel)
				if side < SIDE_SLACK:
					wrong_side += 1
					if wrong_side <= 3:
						print("      %s on the wrong side at %s (%.2f m) way %d next %s %s step %d" % [buggy.name, flat, side, buggy._way, buggy._next, buggy.points[buggy._next], i])
		var name := String(buggy.name)
		_expect(off_road == 0, name + " stays on asphalt for a whole shift", "%d of %d steps off, first at %s" % [off_road, steps, first_off])
		_expect(wrong_side == 0, name + " keeps to its side of the yellow line",
				"%d steps on the wrong side, %d U-turns when blocked" % [wrong_side, u_turns])
		var slow_speed := slow_metres / maxf(slow_time, 0.001)
		var fast_speed := fast_metres / maxf(fast_time, 0.001)
		_expect(slow_time > 5.0 and slow_speed < fast_speed * 0.75, name + " slows down at junctions",
				"%.1f m/s at junctions, %.1f m/s elsewhere" % [slow_speed, fast_speed])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " buggies on roads · ", checks, " checks · ", failures.size(), " failures")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


## How far right of the nearest road's middle line p is, going the way `travel` points.
func _side_of_middle(roads: RoadMesh, p: Vector2, travel: Vector2) -> float:
	var best_d := INF
	var best := 0.0
	for chain: Dictionary in roads.chains:
		if not chain["asphalt"]:
			continue
		var hit: Array = roads._closest_on(chain, p)
		var d := (hit[0] as Vector2).distance_to(p)
		if d < best_d:
			best_d = d
			var right := Vector2(-travel.y, travel.x)
			best = (p - hit[0]).dot(right)
	return best
