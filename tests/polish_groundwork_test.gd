extends SceneTree
## Session 66: the polish groundwork. PolishHooks calls each part's attach(world) once when the
## world opens (and skips missing files), UiPalette has the PRD colours, UiJuice animations
## finish while the game is paused, the new settings save and load again, and UiSounds stays
## quiet for sounds that don't exist yet. Quick: it uses bare nodes, not the whole map.
const TEST_PART := "res://tests/polish_test_part.gd"
var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _check_hooks()
	_check_palette()
	await _check_juice()
	_check_settings()
	_check_sounds()
	_check_flags()
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)


func _check_hooks() -> void:
	var hooks := root.get_node_or_null("PolishHooks")
	_expect(hooks != null, "the PolishHooks autoload is there")
	if hooks == null:
		return
	var names: Array = hooks.PARTS.map(func(p: String): return p.get_file())
	_expect(names == ["look_extras.gd", "world_extras.gd", "hud_extras.gd", "phone_extras.gd", "screen_extras.gd"]
			and hooks.PARTS.all(func(p: String): return p.begins_with("res://scripts/polish/")),
			"the 5 reserved part files are in scripts/polish/")
	_expect(ResourceLoader.exists(TEST_PART), "ResourceLoader.exists finds a .gd file")
	_expect(not ResourceLoader.exists("res://scripts/polish/not_a_part.gd"), "a missing part is not found")
	# A world opening: a node from the world scene file is added to the tree.
	hooks.parts = [TEST_PART, "res://scripts/polish/not_a_part.gd"]
	var world := Node3D.new()
	world.scene_file_path = hooks.WORLD_SCENE
	root.add_child(world)
	await process_frame
	await process_frame
	_expect(hooks.last_world == world, "opening the world runs the hooks")
	_expect(world.get_meta("polish_test_calls", 0) == 1 and world.has_node("PolishTestPart"),
			"the part's attach(world) ran exactly once")
	_expect(hooks.attached == [TEST_PART], "only the part that exists is listed (%s)" % [hooks.attached])
	root.remove_child(world)
	root.add_child(world)
	await process_frame
	await process_frame
	_expect(world.get_meta("polish_test_calls", 0) == 1, "moving the world in the tree doesn't attach twice")
	# Something that isn't the world doesn't run them.
	var other := Node3D.new()
	other.scene_file_path = "res://scenes/test_area.tscn"
	root.add_child(other)
	await process_frame
	_expect(hooks.last_world == world and not other.has_meta("polish_test_calls"), "other scenes don't run the hooks")
	hooks.parts = hooks.PARTS
	world.queue_free()
	other.queue_free()
	await process_frame


func _check_palette() -> void:
	var got := [UiPalette.TEAL, UiPalette.ORANGE, UiPalette.SUN, UiPalette.SAND, UiPalette.INK]
	var want := ["0f4c5c", "f28c28", "f2b230", "f3e3c3", "1b1d22"]
	var ok := true
	for i in want.size():
		ok = ok and got[i].to_html(false) == want[i] and got[i].a == 1.0
	_expect(ok, "UiPalette has the PRD colours (teal, orange, sun, sand, ink)")
	_expect(UiPalette.PANEL.to_html(false) == "0f2026" and is_equal_approx(UiPalette.PANEL.a, 0.86), "HUD panels are #0F2026 at 86%")
	Settings.colour_assist = false
	var normal := UiPalette.band_colour(2)
	Settings.colour_assist = true
	var assist := UiPalette.band_colour(2)
	Settings.colour_assist = false
	_expect(normal.to_html(false) == "e5483a" and assist.to_html(false) == "d55e00", "bad band: red, or vermilion with colour help")
	_expect(UiPalette.band_colour(9) == UiPalette.band_colour(2) and UiPalette.band_colour(-1) == UiPalette.band_colour(0), "band numbers are clamped")
	_expect(UiPalette.FONT_BODY >= 18 and UiPalette.FONT_SMALL >= 16, "body text at least 18 px, nothing under 16 px")


func _check_juice() -> void:
	paused = true
	var box := Control.new()
	box.size = Vector2(200, 100)
	box.position = Vector2(300, 200)
	root.add_child(box)
	var label := Label.new()
	root.add_child(label)
	Settings.reduce_motion = false
	await _wait(UiJuice.pop_in(box))
	_expect(box.scale.is_equal_approx(Vector2.ONE) and box.pivot_offset == Vector2(100, 50), "pop_in ends at full size while paused")
	await _wait(UiJuice.press(box))
	_expect(box.scale.is_equal_approx(Vector2.ONE), "press squashes and comes back")
	await _wait(UiJuice.count_up(label, 0, 123, 0.3, "%d Dh"))
	_expect(label.text == "123 Dh", "count_up ends on the number (%s)" % label.text)
	var shake := UiJuice.shake(box, 6.0)
	await process_frame
	var moved := not is_equal_approx(box.position.x, 300.0)
	await _wait(shake)
	_expect(moved and box.position.is_equal_approx(Vector2(300, 200)), "shake moves and comes back")
	await _wait(UiJuice.slide_in(box, Vector2(320, 0)))
	_expect(box.position.is_equal_approx(Vector2(300, 200)), "slide_in ends where it started")
	Settings.reduce_motion = true
	UiJuice.shake(box, 6.0)
	await process_frame
	await process_frame
	_expect(box.position.is_equal_approx(Vector2(300, 200)), "Less motion: no shake")
	var frames := await _wait(UiJuice.pop_in(box, 0.4))
	_expect(box.scale.is_equal_approx(Vector2.ONE) and frames <= 20, "Less motion: pop_in is quicker (%d frames)" % frames)
	Settings.reduce_motion = false
	paused = false
	box.queue_free()
	label.queue_free()


## Waits for a tween to finish (at most 3 s of frames). Returns how many frames it took.
func _wait(t: Tween) -> int:
	var frames := 0
	while t.is_valid() and t.is_running() and frames < 180:
		await process_frame
		frames += 1
	return frames


func _check_settings() -> void:
	var had_file := FileAccess.file_exists(Settings.PATH)
	var old_file := FileAccess.get_file_as_bytes(Settings.PATH) if had_file else PackedByteArray()
	var keep := [Settings.text_size, Settings.colour_assist, Settings.reduce_motion, Settings.minimap_north_up, Settings.outlines]
	Settings.load_once()
	Settings.text_size = 2
	Settings.colour_assist = true
	Settings.reduce_motion = true
	Settings.minimap_north_up = true
	Settings.outlines = true
	Settings.save()
	# Like a restart: forget them, then load the file again.
	Settings.text_size = 0
	Settings.colour_assist = false
	Settings.reduce_motion = false
	Settings.minimap_north_up = false
	Settings.outlines = false
	Settings._loaded = false
	Settings.load_once()
	_expect(Settings.text_size == 2 and Settings.colour_assist and Settings.reduce_motion
			and Settings.minimap_north_up and Settings.outlines, "the 5 new settings load again after a restart")
	var file := ConfigFile.new()
	file.load(Settings.PATH)
	file.set_value("access", "text_size", 7)
	file.save(Settings.PATH)
	Settings._loaded = false
	Settings.load_once()
	_expect(Settings.text_size == 2, "a bad text size in the file is clamped")
	_expect(is_equal_approx(Settings.text_scale(), 1.3), "130% text is a 1.3 content scale")
	var window := Window.new()
	Settings.apply_text_size(window)
	_expect(is_equal_approx(window.content_scale_factor, 1.3), "the text size sets the window's content scale")
	window.free()
	# An old settings file (no "access" part) gives the defaults.
	var old := ConfigFile.new()
	old.set_value("video", "graphics", Settings.graphics)
	old.save(Settings.PATH)
	Settings.text_size = 1
	Settings.outlines = false
	Settings._loaded = false
	Settings.load_once()
	_expect(Settings.text_size == 1 and not Settings.outlines, "an old settings file keeps the defaults")
	# Put everything back as it was.
	if not had_file:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))
	else:
		var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		f.store_buffer(old_file)
		f.close()
	Settings.text_size = keep[0]
	Settings.colour_assist = keep[1]
	Settings.reduce_motion = keep[2]
	Settings.minimap_north_up = keep[3]
	Settings.outlines = keep[4]
	_expect(is_equal_approx(root.content_scale_factor, 1.0), "headless: the test window's content scale is untouched")


func _check_sounds() -> void:
	var sounds := root.get_node_or_null("UiSounds")
	_expect(sounds != null and sounds.process_mode == Node.PROCESS_MODE_ALWAYS, "the UiSounds autoload is there and works while paused")
	if sounds == null:
		return
	for key: String in sounds.KEYS:
		sounds.play(key)
	sounds.play("not_a_sound", 1.2)
	_expect(sounds.play_counts.get("ui_click", 0) == 1 and sounds.play_counts.get("not_a_sound", 0) == 1,
			"UiSounds counts plays and stays quiet for missing files")
	sounds.play_counts.clear()


func _check_flags() -> void:
	_expect(GameConfig.POLISH_HOOKS_ON and GameConfig.LOOK_LUT in ["golden", "fresh", "neutral"]
			and GameConfig.VIGNETTE_STRENGTH >= 0.0, "the polish flags are in GameConfig")


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
