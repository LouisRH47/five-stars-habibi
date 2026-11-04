extends SceneTree
## Session 54: the rider goes floppy (a rag-doll) when they fall off, and always gets back
## up (small crash) or lies still for the clinic (big crash). Run:
## Godot --path . --headless -s tests/ragdoll_test.gd

var _failures := 0
var _count := 0
var _completed := 0


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://ragdoll_test_save.json"
	_run.call_deferred()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.reset()
	var wall := StaticBody3D.new()
	wall.name = "VillaWall"
	root.add_child(wall)
	var bike: Node3D = load("res://scenes/bike.tscn").instantiate()
	root.add_child(bike)
	bike.fall_completed.connect(func(_big, _impact): _completed += 1)
	await process_frame
	await process_frame
	_check("a person can go floppy", bike._rider.can_do("ragdoll"))

	var cases := [
		["tip", CrashImpact.capture(Vector3(0, 0, -3.2), Vector3.BACK, wall)],
		["skid", CrashImpact.capture(Vector3(0, 0, -8), Vector3(1, 0, 0.5).normalized(), wall)],
		["tumble", CrashImpact.capture(Vector3(0, 0, -8), Vector3.BACK, wall)],
	]
	for case in cases:
		var kind: String = case[0]
		var impact: Dictionary = case[1]
		if impact["fall"] != kind:
			_check("%s: the test impact makes a %s fall (got %s)" % [kind, kind, impact["fall"]], false)
			continue
		bike.reset_to_start()
		await process_frame
		_completed = 0
		bike._begin_fall(impact)
		var sim: RagdollSim = bike._ragdoll
		_check("%s: the rider goes floppy" % kind, sim != null and bike._rider.pose.mode == "ragdoll")
		if sim == null:
			continue
		var start_hips: Vector3 = sim.points["hips"]
		var ground: float = bike.global_position.y
		var normal: Vector3 = impact["normal"]
		normal.y = 0.0
		normal = normal.normalized()
		var wall_line: float = INF
		for name: String in sim.points:
			wall_line = minf(wall_line, (sim.points[name] as Vector3).dot(normal))
		var lowest := INF
		var furthest := 0.0
		var through_wall := 0.0
		var worst_stretch := 0.0
		var most_bend := 0.0
		var start_arm: Vector3 = sim.points["r_ha"] - sim.points["chest"]
		var frames := 0
		while bike._fall_active and frames < 600:
			frames += 1
			bike._step_fall(1.0 / 60.0)
			if bike._ragdoll == null:
				break
			for name: String in sim.points:
				var p: Vector3 = sim.points[name]
				lowest = minf(lowest, p.y - ground)
				furthest = maxf(furthest, p.distance_to(start_hips))
				through_wall = maxf(through_wall, wall_line - p.dot(normal) - 0.25)
			for pair in (RagdollSim.BONES if bike.fall_progress <= 0.8 or impact["big"] else []):
				var now := (sim.points[pair[0]] as Vector3).distance_to(sim.points[pair[1]])
				worst_stretch = maxf(worst_stretch, absf(now / float(sim._rest[pair]) - 1.0))
			var arm: Vector3 = sim.points["r_ha"] - sim.points["chest"]
			most_bend = maxf(most_bend, arm.angle_to(start_arm))
			if frames == 30 and kind != "tip":
				var rider_tilt: float = bike._rider.global_basis.y.normalized().angle_to(Vector3.UP)
				_check("%s: half a second in, the body has tipped over (%.0f degrees)" % [kind, rad_to_deg(rider_tilt)], rider_tilt > deg_to_rad(25.0))
		_check("%s: the fall always ends (%d frames)" % [kind, frames], not bike._fall_active and _completed == 1)
		_check("%s: nothing sinks into the ground (lowest %.2f m)" % [kind, lowest], lowest > -0.02)
		_check("%s: the body stays near the bike (furthest %.1f m)" % [kind, furthest], furthest < 10.0)
		_check("%s: nothing goes through the wall (%.2f m)" % [kind, through_wall], through_wall < 0.05)
		_check("%s: bones keep their length while falling (%.0f%% stretch)" % [kind, worst_stretch * 100.0], worst_stretch < 0.08)
		_check("%s: the arms flop about (%.0f degrees)" % [kind, rad_to_deg(most_bend)], most_bend > deg_to_rad(15.0))
		if impact["big"]:
			var chest_height: float = sim.points["chest"].y - ground
			_check("%s: a big crash leaves the rider lying down (chest %.2f m up)" % [kind, chest_height], chest_height < 0.55)
			_check("%s: the rider stays down for the clinic" % kind, bike._rider.pose.mode == "ragdoll" and bike.wrecked)
		else:
			_check("%s: after a small crash the rider is back on the bike" % kind,
					bike._ragdoll == null and bike._rider.get_parent() == bike._model and bike._rider.pose.mode == "pedal"
					and bike._rider.transform.is_equal_approx(bike._rider_home))

	# A huge pause (or a slow device) can't freeze the game.
	bike.reset_to_start()
	await process_frame
	bike._begin_fall(cases[2][1])
	var started := Time.get_ticks_msec()
	bike._ragdoll.step(30.0)
	_check("one giant step is cut short (%d ms)" % (Time.get_ticks_msec() - started), Time.get_ticks_msec() - started < 500)
	bike.reset_to_start()
	_check("starting a new shift puts the rider back on the bike", bike._ragdoll == null and bike._rider.pose.mode == "pedal")

	print("RAGDOLL RESULT: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _count])
	quit(1 if _failures > 0 else 0)


func _check(what: String, ok: bool) -> void:
	_count += 1
	if not ok:
		_failures += 1
	print(("PASS: " if ok else "FAIL: ") + what)
