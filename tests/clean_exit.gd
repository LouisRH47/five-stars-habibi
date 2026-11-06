extends RefCounted
## Stops every sound, frees what's left of the game and waits a few frames, so nothing is
## still playing when a test quits. Godot reports a sound still in use at exit as an
## error, and GitHub's check fails on any error line.
##   await preload("res://tests/clean_exit.gd").run(self)


static func run(tree: SceneTree, world: Node = null) -> void:
	for player in tree.root.find_children("*", "", true, false):
		if player is AudioStreamPlayer or player is AudioStreamPlayer2D or player is AudioStreamPlayer3D:
			player.stop()
	if world != null and is_instance_valid(world) and not world.is_queued_for_deletion():
		world.queue_free()
	# The sound system lets go of stopped sounds on its own thread, in real time, and a
	# headless test can run many frames in a millisecond: wait real time, not frames.
	var until := Time.get_ticks_msec() + 400
	while Time.get_ticks_msec() < until:
		await tree.process_frame
