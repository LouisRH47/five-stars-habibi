extends SceneTree
## Crash recovery and coverage cross scene boundaries; run in an isolated validation copy.

var _failed := false
var _checks := 0
var _state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_path = "user://lifecycle_regression_test.json"
	for stage in ["offered", "accepted", "carrying"]:
		await _check_tutorial_recovery(stage)
	await _check_insurance_snapshot()
	_state._save_waiting = false
	SaveGame.delete(_state.save_path)
	print("RESULT: %s lifecycle regressions (%d checks)" % ["FAIL" if _failed else "PASS", _checks])
	quit(1 if _failed else 0)


func _check_tutorial_recovery(stage: String) -> void:
	_state.new_game()
	_state.hire("Safe Rider", "UAE", 0)
	var world: Node = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 3:
		await process_frame
	var bike = world.get_node("Bike")
	var delivery = world.get_node("DeliveryManager")
	var shift = world.get_node("ShiftManager")
	var tutorial = world.get_node("Tutorial")
	var clinic = world.get_node("ClinicScreen")
	var summary = world.get_node("ShiftScreen")
	bike.set_physics_process(false)
	delivery.set_physics_process(false)
	shift.set_physics_process(false)
	_check(_state.stage == _state.Stage.OFFERED and _state.tutorial_running, "%s: first tutorial offer starts" % stage)
	if stage != "offered":
		_state.accept_offer()
	if stage == "carrying":
		_state.pick_up()
	var wall := StaticBody3D.new()
	wall.name = "Wall"
	world.add_child(wall)
	bike.speed = 8.0
	_check(bike._check_crash(1.0, wall), "%s: major fall starts" % stage)
	bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["tumble"] + 0.1)
	_check(clinic.showing and _state.boss_paid_crash, "%s: clinic follows fall and first cover is consumed" % stage)
	clinic.close()
	_check(summary.showing, "%s: clinic closes into shift summary" % stage)
	summary._next_shift()
	_check(not paused and _state.stage == _state.Stage.OFFERED and _state.offered_order != null
			and _state.offered_order.restaurant_id == "pizza" and _state.tutorial_running and not _state.tutorial_done,
			"%s: next shift reoffers unfinished tutorial without falsely completing it" % stage)
	_check(_state.history.size() == (0 if stage == "offered" else 1)
			and _state.crash_shifts.size() == 1, "%s: recovery does not duplicate accident or cancellation" % stage)
	var before: float = _state.shift_time_left
	for i in 600:
		shift._physics_process(1.0 / 60.0)
		delivery._physics_process(1.0 / 60.0)
	_check(_state.stage == _state.Stage.OFFERED and _state.shift_time_left == before,
			"%s: replacement tutorial remains available while its clock waits" % stage)
	# Completing the replacement must release the tutorial clock and normal dispatch.
	if _state.stage == _state.Stage.OFFERED:
		_state.accept_offer()
		_state.pick_up()
		_state.deliver()
		world.get_node("DeliveredCard").close()
		await create_timer(GameConfig.TUTORIAL_LAST_TIPS_TIME * 2.0 + 0.1).timeout
		_check(_state.tutorial_done and not _state.tutorial_running, "%s: replacement tutorial can finish normally" % stage)
		shift._physics_process(1.0)
		_check(is_equal_approx(_state.shift_time_left, before - 1.0), "%s: clock resumes at one minute per active second" % stage)
		_check(delivery.offer_now() != null, "%s: normal orders resume after recovered tutorial" % stage)
	if stage == "carrying":
		await _check_stale_tutorial_callback(world, tutorial)
	world.queue_free()
	await process_frame


func _check_stale_tutorial_callback(world: Node, tutorial: Node) -> void:
	_state.tutorial_done = false
	_state.offered_order = null
	_state.offered_orders.clear()
	_state.current_order = null
	_state._set_stage(_state.Stage.NONE)
	tutorial.start()
	_state.accept_offer()
	_state.pick_up()
	_state.deliver()
	world.get_node("DeliveredCard").close()
	# Restart while the previous completion tips still have timers outstanding.
	_state.start_shift()
	await create_timer(GameConfig.TUTORIAL_LAST_TIPS_TIME * 2.0 + 0.1).timeout
	_check(_state.tutorial_running and not _state.tutorial_done and _state.stage == _state.Stage.OFFERED,
			"a restarted tutorial cannot be completed by a previous run's tips timer")
	tutorial.finish()


func _check_insurance_snapshot() -> void:
	_state.new_game()
	_state.tutorial_done = true
	var world: Node = load("res://scenes/test_area.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var bike = world.get_node("Bike")
	bike.set_physics_process(false)
	world.get_node("DeliveryManager").set_physics_process(false)
	world.get_node("ShiftManager").set_physics_process(false)
	var clinic = world.get_node("ClinicScreen")
	var wall := StaticBody3D.new()
	wall.name = "Wall"
	world.add_child(wall)
	for initially_insured in [false, true]:
		_state.boss_paid_crash = true
		_state.insurance_on = initially_insured
		_state.money = 500
		bike.speed = 8.0
		_check(bike._check_crash(1.0, wall), "coverage %s: fall begins" % initially_insured)
		var quote := CrashImpact.quote(bike.last_crash)
		var expected: int = quote["insured"] if initially_insured else quote["hospital"] + quote["repair"]
		var key := InputEventKey.new()
		key.physical_keycode = KEY_I
		key.pressed = true
		root.push_input(key)
		key = key.duplicate()
		key.pressed = false
		root.push_input(key)
		bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["tumble"] + 0.1)
		_check(clinic.showing and clinic.last_bills["paid"] == expected and _state.money == 500 - expected,
				"coverage %s: changing insurance during fall cannot change this accident's charge" % initially_insured)
		_check(clinic.last_bills["insured"] == initially_insured, "clinic explains the coverage held at impact")
		clinic.close()
		world.get_node("ShiftScreen")._next_shift()
	# First-major cover must win even when the collision is uninsured.
	_state.boss_paid_crash = false
	_state.insurance_on = false
	_state.money = 500
	bike.speed = 8.0
	bike._check_crash(1.0, wall)
	_state.set_insurance(true)
	bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["tumble"] + 0.1)
	_check(clinic.last_bills["boss"] and clinic.last_bills["paid"] == 0 and _state.money == 500,
			"collision-time coverage preserves the boss's first-crash payment")
	clinic.close()
	world.get_node("ShiftScreen")._next_shift()
	world.queue_free()
	await process_frame


func _check(good: bool, message: String) -> void:
	_checks += 1
	_failed = _failed or not good
	print("PASS: " if good else "FAIL: ", message)
