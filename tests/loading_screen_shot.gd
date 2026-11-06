extends SceneTree
## Takes a picture of the loading screen (Session 86), to check how it looks.
## Run it with a window (not headless), and give the PNG path after --:
##   Godot --path . -s tests/loading_screen_shot.gd -- /private/tmp/loading_shot.png


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else "user://loading_shot.png"
	# Loaded here, not named at the top: the game's autoloads (GameState) only exist once
	# the tree is running, and the bike on the screen dresses the rider from GameState.
	var screen = load("res://scripts/loading_screen.gd").make()
	get_root().add_child(screen)
	screen.set_progress(14, 40, "Building the homes...")
	await create_timer(1.5).timeout
	await process_frame
	get_root().get_texture().get_image().save_png(path)
	print("Saved ", path, " (bar at ", snappedf(screen.shown_fraction, 0.01), ")")
	quit()
