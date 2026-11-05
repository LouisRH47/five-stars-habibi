extends SceneTree
## Session 71: screens, menus, sounds and accessibility. The Delivered card's reveal runs in
## order (tiles, stars, stamp, count-up, end) and E skips it, closing emits `closed` once and
## leaves no depth of field behind; the Accessibility settings save and load again and the text
## size changes the window's content scale (and the panel fits at 130% on a 1024x768 screen);
## the start screen builds with and without the 3D scene and its buttons tick and click; every
## UiSounds key has a small sound file; the pause blur shows only while paused; the clinic
## bills count up to the real bill; the side panel slides in; the loading rider moves along
## the bar; and screen_extras gives buttons in the world their feel.
## Quick: bare nodes and the start screen only, never the whole map.
var _failed := false
var _state: Node
var _closed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_path = "user://screens_polish_test.json"
	_state.reset()
	Settings.load_once()
	Settings.graphics = 1
	_check_sounds()
	await _check_card()
	await _check_settings()
	await _check_start_screen()
	await _check_pause_blur()
	await _check_clinic()
	await _check_side_panel()
	_check_loader()
	await _check_extras()
	SaveGame.delete(_state.save_path)
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)


func _check_sounds() -> void:
	var ui := root.get_node("UiSounds")
	var missing: Array = []
	var big: Array = []
	for key in ui.KEYS:
		var path := "res://assets/audio/%s.wav" % key
		if not ResourceLoader.exists(path):
			missing.append(key)
		elif FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path).size() > 40 * 1024:
			big.append(key)
	_expect(missing.is_empty(), "every UiSounds key has a sound file %s" % [missing])
	_expect(big.is_empty(), "each UI sound is under 40 KB %s" % [big])


# --- The Delivered card ---

func _card_world() -> Array:
	var world := Node3D.new()
	root.add_child(world)
	var places := PlaceBuilder.new()
	places.restaurants = [{"id": "pizza", "name": "Test Pizza", "food": "pizza", "position": Vector3.ZERO, "facing": 0.0}]
	places.villas = [{"number": 101, "house": 1, "position": Vector3(0, 0, 50), "facing": 0.0, "cluster": "C1", "address": "Villa 1, Cluster 1"}]
	var bike := Node3D.new()
	world.add_child(bike)
	var dm = load("res://scripts/delivery_manager.gd").new()
	dm.bike = bike
	dm.place_builder = places
	world.add_child(dm)
	dm.set_physics_process(false)
	var sounds = load("res://scripts/sounds.gd").new()
	sounds.name = "Sounds"
	world.add_child(sounds)
	var card = load("res://scripts/delivered_card.gd").new()
	card.name = "DeliveredCard"
	card.delivery_manager = dm
	world.add_child(card)
	var view_camera := Camera3D.new()
	world.add_child(view_camera)
	view_camera.make_current()
	var maker = load("res://scripts/order_maker.gd").new(places, 8.0)
	return [world, card, maker, sounds]


func _deliver(maker: Object, meters: float) -> void:
	_state.start_shift()
	_state.offer_order(maker.make("pizza", 101))
	_state.accept_offer()
	_state.pick_up()
	_state.set_meters(meters, meters, meters)
	_state.ride_time = 30.0
	_state.deliver()


func _check_card() -> void:
	var made := _card_world()
	var world: Node3D = made[0]
	var card = made[1]
	var maker = made[2]
	var sounds = made[3]
	card.closed.connect(func(): _closed += 1)
	var ui := root.get_node("UiSounds")
	var ticks: int = ui.play_counts.get("tick", 0)
	var stamps: int = ui.play_counts.get("stamp", 0)
	# A perfect delivery, played through in small steps.
	_deliver(maker, 100.0)
	await process_frame
	_expect(card.showing and paused and card.revealing(), "a delivery opens the card and starts the reveal")
	_expect(card._stars.stars == 0.0 and card._earned.text == "0 Dh", "the stars and the money start empty")
	var dof_ok: bool = RenderingServer.get_current_rendering_method() == "gl_compatibility" \
			or (card._camera.attributes is CameraAttributesPractical and card._camera.attributes.dof_blur_far_enabled)
	_expect(dof_ok, "the world behind the card goes soft (depth of field) on the desktop renderer")
	var steps := 0
	while card.revealing() and steps < 200:
		card._pop_tween.custom_step(0.05)
		steps += 1
	var log: Array = card.reveal_log
	var order := ["tile0", "tile1", "tile2", "star0", "star1", "star2", "star3", "star4", "stamp", "count"]
	var in_order := true
	var last := -1
	for item in order:
		var at := log.find(item)
		in_order = in_order and at > last
		last = at
	_expect(in_order and log.back() == "end", "tiles, then rising stars, then the stamp, then the count-up: %s" % [log])
	_expect(steps * 0.05 < 5.0, "the whole reveal takes under 5 s (%.2f s)" % (steps * 0.05))
	_expect(card._earned.text == "%d Dh" % card.shown["earned"], "the count-up ends on the money you earned (%s)" % card._earned.text)
	_expect(card._stamp.visible and is_equal_approx(card._stamp.scale.x, 1.0) and card._title.text == "PERFECT!",
			"the PERFECT! stamp has landed")
	_expect(ui.play_counts.get("tick", 0) > ticks and ui.play_counts.get("stamp", 0) == stamps + 1,
			"the count-up ticks and the stamp thunks")
	var pitches: Array = GameConfig.CARD_STAR_PITCHES
	_expect(sounds.play_counts.get("pop", 0) == 5 and pitches.size() == 5 and pitches[4] > pitches[0], "five star dings, each higher")
	var tiles_done: bool = card._tiles.get_children().all(func(t): return t.is_queued_for_deletion() or is_equal_approx(t.scale.x, 1.0))
	_expect(tiles_done, "all three tiles have flipped in")
	card.close()
	_expect(_closed == 1 and not card.showing and not paused, "closing emits closed once and the game carries on")
	_expect(card._camera.attributes == null, "no depth of field left on the camera after closing")
	card.close()
	_expect(_closed == 1, "closing again does nothing")
	# E in the middle of the reveal jumps to the end (and, by default, carries on).
	_deliver(maker, 60.0)
	await process_frame
	card._pop_tween.custom_step(0.3)
	var key := InputEventAction.new()
	key.action = "interact"
	key.pressed = true
	card._unhandled_input(key)
	_expect(card.reveal_log.back() == "end", "E skips the reveal to the end")
	var expect_open: bool = GameConfig.CARD_E_SKIPS_FIRST
	_expect(card.showing == expect_open and _closed == (1 if expect_open else 2), "E then %s" % ("waits for a second E" if expect_open else "closes the card, once"))
	if expect_open:
		card._unhandled_input(key)
		_expect(not card.showing and _closed == 2, "the second E closes it")
	# A click on the card only skips.
	_deliver(maker, 80.0)
	await process_frame
	card.skip()
	_expect(card.showing and not card.revealing() and card._earned.text == "%d Dh" % card.shown["earned"],
			"skip() shows the end and leaves the card up")
	card.close()
	_expect(_closed == 3 and card._pop_tween == null and card.offset == Vector2.ZERO, "close stops the reveal")
	world.queue_free()
	await process_frame


# --- Settings: Accessibility ---

func _check_settings() -> void:
	var keep := [Settings.text_size, Settings.colour_assist, Settings.reduce_motion, Settings.minimap_north_up]
	var panel := SettingsPanel.new()
	root.add_child(panel)
	_expect(panel.text_size_option != null and panel.text_size_option.item_count == 3
			and panel.colour_box != null and panel.motion_box != null
			and panel.minimap_option != null and panel.minimap_option.item_count == 2,
			"Settings has Text size, Colour help, Less motion and Mini-map")
	_expect(panel.volume_sliders.size() == 4 and panel.graphics_option != null and panel.fullscreen_box != null,
			"the old settings are all still there")
	panel._on_text_size(2)
	_expect(Settings.text_size == 2 and is_equal_approx(root.content_scale_factor, 1.3), "Text size 130%% scales the window (%.2f)" % root.content_scale_factor)
	panel.colour_box.button_pressed = true
	panel.motion_box.button_pressed = true
	panel._on_minimap(1)
	_expect(Settings.colour_assist and Settings.reduce_motion and Settings.minimap_north_up, "the switches change the settings")
	_expect(UiPalette.band_colour(0) == UiPalette.BAND_ASSIST[0] and panel._swatches[0].color == UiPalette.BAND_ASSIST[0],
			"Colour help swaps the meter colours (and the preview)")
	# Read the file again.
	Settings._loaded = false
	Settings.text_size = 0
	Settings.colour_assist = false
	Settings.reduce_motion = false
	Settings.minimap_north_up = false
	Settings.load_once()
	_expect(Settings.text_size == 2 and Settings.colour_assist and Settings.reduce_motion and Settings.minimap_north_up,
			"they're saved and load again")
	panel._on_text_size(0)
	_expect(is_equal_approx(root.content_scale_factor, 1.0), "Text size 100% puts the scale back")
	panel.free()
	# At 130% on a 1024x768 screen the whole Settings box still fits.
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(1024, 768)
	Settings.text_size = 2
	Settings.reduce_motion = false
	Settings.apply_text_size(root)
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	menu.use_diorama = false
	root.add_child(menu)
	menu._open_settings()
	for i in 3:
		await process_frame
	menu.settings_panel.scale = Vector2.ONE
	menu.settings_panel.modulate.a = 1.0
	await process_frame
	var box: Rect2 = menu.settings_panel.get_global_rect()
	var screen := root.get_visible_rect()
	_expect(screen.grow(0.5).encloses(box), "at 130%% on 1024x768 the Settings box fits: %s in %s" % [box, screen])
	menu.free()
	Settings.text_size = keep[0]
	Settings.colour_assist = keep[1]
	Settings.reduce_motion = keep[2]
	Settings.minimap_north_up = keep[3]
	Settings.save()
	Settings.apply_text_size(root)
	root.size = Vector2i(1920, 1080)


# --- Start screen ---

func _check_start_screen() -> void:
	var ui := root.get_node("UiSounds")
	for with_scene in [true, false]:
		var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
		menu.use_diorama = with_scene
		root.add_child(menu)
		await process_frame
		if with_scene:
			var d = menu.diorama
			_expect(d != null and d.bike != null and d.bike.get_node_or_null("DeliveryBox") != null and d.rider != null
					and d.bike.get_node_or_null("Rider") == null, "the 3D start scene has the bike with its box and you standing by it")
			var meshes: int = d.view.find_children("*", "MeshInstance3D", true, false).size()
			_expect(meshes > 10 and meshes < 400, "the start scene is small (%d meshes)" % meshes)
			menu._pick_look(2)
			_expect(d.get_meta("look") == 2, "picking a look dresses the rider in the scene")
			await create_timer(1.2).timeout
			_expect(is_equal_approx(menu._title_column.modulate.a, 1.0) and is_equal_approx(menu._phone.modulate.a, 1.0),
					"the title and the phone have come in")
		else:
			_expect(menu.diorama == null and menu._desert_camera != null, "with START_DIORAMA off it's the old desert")
		# Buttons answer: a tick on hover, a click and an open sound for Settings.
		var hovers: int = ui.play_counts.get("ui_hover", 0)
		var clicks: int = ui.play_counts.get("ui_click", 0)
		var opens: int = ui.play_counts.get("ui_open", 0)
		var settings_button: Button = menu.find_children("*", "Button", true, false).filter(func(b): return b.text == "Settings")[0]
		settings_button.mouse_entered.emit()
		settings_button.pressed.emit()
		await process_frame
		_expect(ui.play_counts.get("ui_hover", 0) == hovers + 1 and ui.play_counts.get("ui_click", 0) == clicks + 1
				and ui.play_counts.get("ui_open", 0) == opens + 1 and menu.settings_panel.visible,
				"start screen (%s): hover ticks, click clicks, Settings opens with a sound" % ("3D" if with_scene else "desert"))
		var closes: int = ui.play_counts.get("ui_close", 0)
		menu.settings_panel._on_back()
		_expect(ui.play_counts.get("ui_close", 0) == closes + 1, "Back plays the close sound")
		menu.free()
		await process_frame


# --- Pause blur ---

func _check_pause_blur() -> void:
	var pause: CanvasLayer = load("res://ui/pause_menu.tscn").instantiate()
	root.add_child(pause)
	var blur: ColorRect = pause.get_node("Blur")
	_expect(not blur.is_visible_in_tree(), "no blur before pausing")
	pause._pause()
	await process_frame
	_expect(paused and blur.is_visible_in_tree() and blur.material is ShaderMaterial, "the game behind goes blurry while paused")
	pause._resume()
	_expect(not paused and not blur.is_visible_in_tree(), "the blur goes when you carry on")
	pause.free()


# --- Clinic ---

func _check_clinic() -> void:
	var clinic: CanvasLayer = load("res://scripts/clinic_screen.gd").new()
	root.add_child(clinic)
	var bills := {"hospital": 120, "repair": 60, "boss": false, "insured": false, "paid": 180, "lost_order": true,
			"severity": "severe", "impact": {"what": "a wall", "kmh": 30.0}}
	clinic.open(bills, true)
	await process_frame
	_expect(clinic.showing and clinic._total.text != "180 Dh", "the clinic bill starts counting (%s)" % clinic._total.text)
	clinic._count.custom_step(5.0)
	_expect(clinic._total.text == "180 Dh", "the count-up ends on the bill (%s)" % clinic._total.text)
	clinic.close()
	_expect(not paused and not clinic.showing, "closing the clinic carries on")
	clinic.free()


# --- Side panel ---

func _check_side_panel() -> void:
	var panel := SidePanel.new()
	root.add_child(panel)
	panel.show_counter("Test Pizza", "Pizza\nHold E", 0.3)
	_expect(panel.visible and panel._panel.position.x < panel.HOME.x, "the counter panel starts off to the left")
	panel._slide.custom_step(1.0)
	_expect(panel._panel.position == panel.HOME and is_equal_approx(panel._panel.modulate.a, 1.0), "and slides into place")
	panel.show_counter("Test Pizza", "Pizza\nHold E", 0.5)
	_expect(panel._panel.position == panel.HOME, "staying open doesn't slide it again")
	panel.free()


# --- Loading screen ---

func _check_loader() -> void:
	var loader := root.get_node("Loader")
	_expect(loader.rider_icon != null and loader.rider_icon.get_parent() == loader._track, "the loading bar has its little rider")
	loader.progress = 0.0
	loader._set_progress(0.1)
	var x1: float = loader.rider_icon.position.x
	loader._set_progress(0.6)
	_expect(loader.rider_icon.position.x > x1 + 200.0, "the rider pedals along as the bar fills")
	loader.progress = 0.0
	loader._set_progress(0.0)


# --- screen_extras in the world ---

func _check_extras() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var early := Button.new()
	world.add_child(early)
	root.get_node("PolishHooks").attach_parts(world, ["res://scripts/polish/screen_extras.gd"])
	await process_frame
	var later := Button.new()
	world.add_child(later)
	_expect(world.get_node_or_null("ScreenExtras") != null and early.has_meta("ui_feel") and later.has_meta("ui_feel"),
			"screen_extras gives buttons in the world (now and later) their hover and click")
	var ui := root.get_node("UiSounds")
	var clicks: int = ui.play_counts.get("ui_click", 0)
	later.pressed.emit()
	_expect(ui.play_counts.get("ui_click", 0) == clicks + 1, "a button in the world clicks")
	world.free()


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
