extends SceneTree
## Session 86: builds Wahat Al Shams the normal way, then again through the loading screen
## (WorldLoader), and checks: the steps ran in order with names, "step X of N" counted every
## step, the step-by-step world has the same buildings as the normal one, the shops were set
## up, the game is unpaused and the screen closed. Prints the longest frame while loading.
##   Godot --path . --headless --fixed-fps 60 -s tests/loading_screen_test.gd

const MAP := "res://scenes/wahat_al_shams.tscn"
const BUILDERS := ["WahatBuilder", "PlazaBuilder", "PlaceBuilder", "DistrictDetail"]
var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "user://loading_screen_test_save.json"
	state.new_game()
	# 1) The normal build (all at once), to compare against.
	var normal: Node = load(MAP).instantiate()
	root.add_child(normal)
	for i in 3:
		await process_frame
	var normal_counts := _counts(normal)
	normal.free()
	await process_frame
	# 2) The step-by-step build behind the loading screen.
	var loader := WorldLoader.open(self, MAP)
	var screen_seen := false
	var screen_ref: Array = [null]
	var paused_while_building := false
	var finished := [false]
	var got := {}
	loader.finished.connect(func(_world: Node):
		finished[0] = true
		got["world"] = loader.world
		got["names"] = loader.done_names.duplicate()
		got["total"] = loader.total_steps
		got["longest"] = loader.longest_frame_ms
		got["step_ms"] = loader.step_ms.duplicate())
	var started := Time.get_ticks_msec()
	while not finished[0] and Time.get_ticks_msec() - started < 90000:
		await process_frame
		if finished[0]:
			break
		if screen_ref[0] == null and loader.screen != null:
			screen_ref[0] = loader.screen
		screen_seen = screen_seen or is_instance_valid(loader.screen) and loader.screen.is_inside_tree()
		if loader.world != null and loader.world.is_inside_tree() and not finished[0]:
			paused_while_building = paused_while_building or paused
	if not finished[0] and is_instance_valid(loader):
		print("      stuck at step %d of %d, bar %.2f" % [loader.done_names.size(), loader.total_steps,
				loader.screen.shown_fraction if is_instance_valid(loader.screen) else -1.0])
	_check(finished[0], "the loader finished")
	if not finished[0]:
		_end()
		return
	var world: Node = got["world"]
	var names: Array = got["names"]
	var step_ms: Dictionary = got["step_ms"]
	print("      steps: %d, longest frame while building: %d ms" % [names.size(), got["longest"]])
	var slow: Array = step_ms.keys()
	slow.sort_custom(func(a, b): return step_ms[a] > step_ms[b])
	for step_name in slow.slice(0, 4):
		print("      slow step: %s %d ms" % [step_name, step_ms[step_name]])
	_check(screen_seen, "the loading screen was on screen")
	_check(paused_while_building, "the game waited (paused) while the world was built")
	_check(not paused, "the game runs again after loading")
	_check(names.size() == got["total"], "step X of N counted every step (%d of %d)" % [names.size(), got["total"]])
	_check(names.size() >= 40, "the build is split into many steps (%d)" % names.size())
	_check(names[0] == "Unrolling the desert...", "the first step is making the map (%s)" % names[0])
	_check(names[-1] == "Polishing everything...", "the last step merges the scenery (%s)" % names[-1])
	var roads := names.find("Laying the roads...")
	var first_shop := -1
	for i in names.size():
		if names[i].begins_with("Opening ") and names[i] != "Opening the petrol station...":
			first_shop = i
			break
	_check(roads > 0 and first_shop > roads, "roads are laid before the restaurants open (%d, %d)" % [roads, first_shop])
	_check(names.find("Building the town houses...") > first_shop, "homes come after the restaurants")
	_check(world.get_node_or_null("ShopController") != null, "the shops were set up after everything was in")
	_check(world.get_node("DistrictDetail").has_meta("static_batch_report"), "the scenery was merged at the end")
	_check(world.get_node("Bike").is_inside_tree() and world.get_node("EventManager").is_inside_tree(), "every part is in the game")
	_check(not world.has_meta(WorldLoader.STAGED_META), "the world no longer says it is being built")
	_check(current_scene == world, "the new world is the current scene")
	var staged_counts := _counts(world)
	for builder in BUILDERS:
		_check(staged_counts[builder] == normal_counts[builder], "%s has the same parts both ways (%d vs %d)"
				% [builder, staged_counts[builder], normal_counts[builder]])
	_check(not is_instance_valid(screen_ref[0]) or screen_ref[0].is_queued_for_deletion(), "the loading screen closed before the game started")
	# The short screen at the start of a new shift.
	world.get_node("ShiftScreen")._next_shift()
	var short_screen: Node = null
	for child in root.get_children():
		if child is LoadingScreen:
			short_screen = child
	_check(short_screen != null, "a new shift shows the short loading screen")
	started = Time.get_ticks_msec()
	while is_instance_valid(short_screen) and Time.get_ticks_msec() - started < 10000:
		await process_frame
	_check(not is_instance_valid(short_screen), "the short loading screen closed")
	await preload("res://tests/clean_exit.gd").run(self, world)
	_end()


## How many nodes each builder ended up with.
func _counts(world: Node) -> Dictionary:
	var counts := {}
	for builder in BUILDERS:
		counts[builder] = _descendants(world.get_node(builder))
	return counts


func _descendants(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		total += 1 + _descendants(child)
	return total


func _check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		_failed = true


func _end() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://loading_screen_test_save.json"))
	print("RESULT: " + ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)
