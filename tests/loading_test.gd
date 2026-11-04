extends SceneTree
## Session 53: the loading screen. A click opens the game once (a second click is ignored),
## the bar only goes up and reaches 100%, and the game uses the homes the loading screen
## built row by row instead of building them again.
var _failed := false
var _values: Array[float] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var loader := root.get_node("Loader")
	_expect(loader.busy == false and loader.opened_count == 0, "the loader starts idle")
	var first: bool = loader.go_to_game(false)
	var second: bool = loader.go_to_game(false)
	_expect(first and not second, "a second click while loading is ignored")
	var screen: Control = loader.get_node("LoadingScreen")
	_expect(screen.visible, "the loading screen shows straight away, before any heavy work")
	var started := Time.get_ticks_msec()
	var waited := 0
	while loader.busy and Time.get_ticks_msec() - started < 180000:
		_values.append(loader.progress)
		await process_frame
		waited += 1
	_expect(not loader.busy, "loading finishes (%d frames, %.1f s)" % [waited, (Time.get_ticks_msec() - started) / 1000.0])
	var rising := true
	for i in range(1, _values.size()):
		rising = rising and _values[i] >= _values[i - 1]
	_expect(rising, "the bar never goes backwards")
	_expect(is_equal_approx(loader.progress, 1.0), "the bar reaches 100%")
	var steps := {}
	for v in _values:
		steps[snappedf(v, 0.01)] = true
	_expect(steps.size() >= 10, "the bar moves in many small steps (%d different values)" % steps.size())
	_expect(loader.opened_count == 1, "the game scene was opened exactly once")
	var world := current_scene
	_expect(world != null and world.name == "WahatAlShams", "the game is the current scene")
	if world == null:
		quit(1)
		return
	var rows: HousingRows = world.get_node("PlaceBuilder/HousingRows")
	_expect(rows.home_count == 500 and rows.rows_left() == 0, "all 500 homes are in the game")
	_expect(HousingRows.prebuilt == null, "the game took the homes the loading screen built")
	_expect(not screen.visible, "the loading screen is gone")
	quit(1 if _failed else 0)


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
