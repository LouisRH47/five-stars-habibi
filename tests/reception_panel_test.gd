extends SceneTree
## Exercise reception handoffs and modal cleanup on the production Wahat scene.
var _failed := false
var _world: Node
var _state: Node
var _delivery: Node
var _counter: Node
var _walker: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_path = "user://reception_panel_test.json"
	_state.reset()
	_state.tutorial_done = true
	_world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 4:
		await process_frame
	_delivery = _world.get_node("DeliveryManager")
	_counter = _world.get_node("CounterPanel")
	_walker = _world.get_node("Walker")
	_world.get_node("Bike").set_physics_process(false)
	_walker.set_physics_process(false)
	_delivery.set_physics_process(false)
	_world.get_node("ShiftManager").set_physics_process(false)
	for venue in [903, 904]:
		await _prepare_handoff(venue)
		var pause_menu: Node = _world.get_node("PauseMenu")
		pause_menu._pause()
		await process_frame
		await process_frame
		_expect(not _counter._panel.visible, "%d reception panel clears while paused" % venue)
		pause_menu._resume()
		await process_frame
		await process_frame
		_expect(_counter._panel.visible, "%d reception panel returns for the active handoff on resume" % venue)
		var profile: Node = _world.get_node("Phone/ProfilePage")
		profile.open()
		await process_frame
		await process_frame
		_expect(not _counter._panel.visible, "%d profile is not covered by a reception panel" % venue)
		profile.close()
		await process_frame
		await process_frame
		_expect(_counter._panel.visible, "%d closing profile restores valid handoff instructions" % venue)
		Input.action_press("interact")
		_delivery._update_hold(GameConfig.DROPOFF_HOLD_TIME)
		Input.action_release("interact")
		var delivered: Node = _world.get_node("DeliveredCard")
		_expect(delivered.showing and paused, "%d held interaction completed the delivery" % venue)
		_expect(not _counter._panel.visible, "%d handoff panel clears synchronously before the result card" % venue)
		await process_frame
		await process_frame
		_expect(not _counter._panel.visible, "%d reception instructions stay hidden throughout the paused result" % venue)
		delivered.close()
		_world.get_node("ShiftManager").end_shift()
		await process_frame
		_expect(not _counter._panel.visible, "%d no old reception panel remains over the shift summary" % venue)
		_world.get_node("ShiftScreen")._next_shift()
		await process_frame
		_expect(not _counter._panel.visible, "%d next shift does not restore a completed handoff" % venue)
	_world.queue_free()
	await process_frame
	SaveGame.delete(_state.save_path)
	print("RESULT: ", "FAIL reception panel" if _failed else "PASS reception panel")
	quit(1 if _failed else 0)


func _prepare_handoff(venue: int) -> void:
	_state.reset()
	_state.tutorial_done = true
	var order: Order = _delivery.make_order("pizza", venue)
	_state.offer_order(order)
	_state.accept_offer()
	_state.pick_up()
	_delivery.actor = _walker
	_delivery.on_foot = true
	_delivery._need_release = false
	_walker.global_position = _delivery.target_door()
	await physics_frame
	await process_frame
	await process_frame
	_expect(_delivery.is_near_target() and _counter._panel.visible, "%d shows a staffed reception panel at the live target" % venue)
