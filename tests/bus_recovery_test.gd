extends SceneTree
## Exercise the real traffic physics after a rider delays the station departure.
## Run with --fixed-fps 60 in an isolated validation snapshot.

var _failed := false
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "user://bus_recovery_test.json"
	state.reset()
	state.tutorial_done = true
	var world := Node3D.new()
	root.add_child(world)
	var bike := Node3D.new()
	bike.name = "Bike"
	bike.add_to_group("bike")
	bike.position = Vector3(-332, 0, -176)  # on the bus loop, just past the bay
	world.add_child(bike)
	var traffic: Node3D = load("res://scripts/district_traffic.gd").new()
	traffic.data = WahatAlShams
	world.add_child(traffic)
	var initial_bus: TrafficVehicle = traffic.buses[0]
	var visits := {}
	var left_spur := {}
	var overlapping := false
	var spawned_on_blocked_spur := false
	var hourly_slot_still_pending := false
	# Hold the initial departure past two due arrivals, then clear the rider.
	# This also catches multiple delayed buses spawning on top of one another.
	for tick in range(60 * 240):
		var elapsed := float(tick) / 60.0
		state.shift_time_left = GameConfig.SHIFT_LENGTH - elapsed
		if tick == 60 * 125:
			hourly_slot_still_pending = traffic.bus_arrivals == 1
			bike.position = Vector3(-1000, 0, -1000)
		await physics_frame
		if elapsed < 125.0 and traffic.bus_arrivals > 1:
			spawned_on_blocked_spur = true
		var live: Array[TrafficVehicle] = []
		for bus in traffic.buses:
			if not is_instance_valid(bus) or bus.is_queued_for_deletion():
				continue
			live.append(bus)
			if bus.visits > 0:
				visits[bus.name] = true
			if bus._next >= 3 and bus.position.distance_to(traffic._bus_entry) > 15.0:
				left_spur[bus.name] = true
		for i in live.size():
			for j in range(i + 1, live.size()):
				# Same-route buses must retain longitudinal separation, including at spawn.
				if live[i].position.distance_to(live[j].position) < 8.2:
					overlapping = true
	_check("an obstructed departure keeps pending arrivals off the single access road", not spawned_on_blocked_spur)
	_check("missed hourly slots wait instead of being discarded", hourly_slot_still_pending and traffic.bus_arrivals >= 4)
	_check("the original bus leaves once the rider clears the road", left_spur.has("CommunityBus_0"))
	_check("delayed incoming buses reach the bay after the obstruction clears", visits.size() >= 3)
	_check("delayed buses also leave the station instead of blocking each other", left_spur.has("CommunityBus_1") and left_spur.has("CommunityBus_2"))
	_check("buses never spawn or queue on top of each other", not overlapping)
	_check("the initial bus retains its normal departure without a duplicate station visit", is_instance_valid(initial_bus) and initial_bus.visits == 0)
	world.queue_free()
	await process_frame
	state._save_waiting = false
	SaveGame.delete(state.save_path)
	print("RESULT: %s bus recovery (%d checks)" % ["FAIL" if _failed else "PASS", _checks])
	quit(1 if _failed else 0)


func _check(message: String, ok: bool) -> void:
	_checks += 1
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
