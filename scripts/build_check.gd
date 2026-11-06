class_name BuildCheck
extends RefCounted
## Session 85: a quick self-test for the exported game (Mac, Windows, Linux). Start the game
## with "-- --build-check" and it opens the map, plays one delivery, saves to its own test
## file (never your real save), prints "BUILD CHECK: PASS" or "FAIL" and quits.
## tools/build_desktop.py --verify-mac runs it on the Mac build.

const SAVE := "user://build_check_save.json"


static func wanted() -> bool:
	return "--build-check" in OS.get_cmdline_user_args()


static func run(tree: SceneTree) -> void:
	var state := tree.root.get_node("GameState")
	var real_save: String = state.save_path
	state.save_path = SAVE
	state.new_game()
	state.hire("Build Check", "UAE", 0)
	var world := (load("res://scenes/wahat_al_shams.tscn") as PackedScene).instantiate()
	tree.root.add_child(world)
	for i in 30:
		await tree.process_frame
	var manager := world.get_node("DeliveryManager")
	state.reset()  # clear the order the shift already offered
	var money: int = state.money
	var order: Order = manager.make_order("pizza", 101)
	var delivered: bool = state.offer_order(order) and state.accept_offer() and state.pick_up() and state.deliver()
	var saved: bool = state.save_game() and FileAccess.file_exists(SAVE)
	var earned: int = state.money
	var reloaded: bool = saved and state.load_game() and state.money == earned
	var paid: bool = state.money > money
	var ok := delivered and saved and reloaded and paid
	print("BUILD CHECK: %s (delivered %s, paid %d Dh, saved %s, %s)" % [
			"PASS" if ok else "FAIL", delivered, state.money - money, saved, OS.get_name()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	state.save_path = real_save
	world.queue_free()
	var until := Time.get_ticks_msec() + 400  # let sounds stop before quitting
	while Time.get_ticks_msec() < until:
		await tree.process_frame
	tree.quit(0 if ok else 1)
