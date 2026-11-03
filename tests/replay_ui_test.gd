extends SceneTree
## Small UI contract check: no full-world rendering or real player save is required.
var state: Node
var failed := false


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
	print("PASS: " if ok else "FAIL: ", message)


func _run() -> void:
	state = root.get_node("GameState")
	state.save_path = "user://replay_ui_test.json"
	state.reset()
	var world := Node3D.new()
	root.add_child(world)
	var places := PlaceBuilder.new()
	places.restaurants = [{"id": "pizza", "name": "Test Pizza", "food": "pizza", "position": Vector3.ZERO, "facing": 0.0}]
	places.villas = [{"number": 101, "house": 1, "position": Vector3(0, 0, 50), "facing": 0.0, "cluster": "C1", "address": "Villa 1, Cluster 1"}, {"number": 102, "house": 2, "position": Vector3(0, 0, 200), "facing": 0.0, "cluster": "C1", "address": "Villa 2, Cluster 1"}]
	var bike := Node3D.new()
	world.add_child(bike)
	var dm = load("res://scripts/delivery_manager.gd").new()
	dm.bike = bike
	dm.place_builder = places
	world.add_child(dm)
	dm.set_physics_process(false)
	var phone = load("res://ui/phone.tscn").instantiate()
	phone.delivery_manager = dm
	world.add_child(phone)
	state.streak = 4
	var maker = load("res://scripts/order_maker.gd").new(places, 8.0)
	var first: Order = maker.make("pizza", 101)
	var second: Order = maker.better_than(first)
	var offers: Array[Order] = [first, second]
	state.offer_choices(offers)
	await process_frame
	await process_frame
	_expect(phone.get_node("Panel/Margin/Rows/OrderChoices").visible, "phone shows two side-by-side order cards")
	_expect(phone.get_node("Panel").custom_minimum_size.x > 330.0, "choice cards expand the phone for readable full addresses")
	_expect(phone._streak.text.begins_with("4 in a row"), "phone shows the current five-star streak")
	_expect(maker.is_better(second, first), "alternative order has a valid pay, distance or customer advantage")
	_expect("m route" in phone._choice_info[0].text, "order choices show route distance so the tradeoff can be compared")
	state.skip_offer()
	await process_frame
	_expect(not phone.get_node("Panel/Margin/Rows/OrderChoices").visible, "choice cards close when both orders are skipped")
	var profile = phone.get_node("ProfilePage")
	var homes: Array = []
	for cluster in range(1, 6):
		for house in range(1, 101):
			homes.append({"number": cluster * 100 + house, "cluster": "C%d" % cluster, "house": house, "address": "Villa %d, Cluster %d" % [house, cluster]})
	state.configure_collections(homes)
	state.note_animal_met("cat_lulu", "Lulu")
	state.personal_bests["routes"] = {"pizza>101:": 61.0}
	state.personal_bests["route_labels"] = {"pizza>101:": "1000 Pizza to Villa 1, Cluster 1"}
	profile.open()
	_expect(profile.showing and paused, "Profile opens and pauses the active shift")
	var grids: Array = profile._content.find_children("*", "GridContainer", true, false)
	var stamps := 0
	for grid in grids:
		stamps += grid.get_child_count()
	_expect(grids.size() == 5 and stamps == 500, "Profile shows all five clusters and all 500 home stamps")
	var route_button: Button = profile._content.find_children("*", "Button", true, false)[0]
	route_button.pressed.emit()
	var has_time: bool = profile._content.find_children("*", "Label", true, false).any(func(label): return "1:01" in label.text)
	_expect(has_time, "Profile can reveal a saved fastest ride with a friendly name and exact time")
	_expect("GPS route" in phone._gear_goal.text and phone._gear_progress != null, "phone shows the next upgrade goal and its progress")
	profile.close()
	_expect(not paused, "closing Profile resumes the active shift")
	var summary_screen = load("res://scripts/shift_screen.gd").new()
	world.add_child(summary_screen)
	var summary: Dictionary = state.end_shift()
	summary_screen.show_summary(summary)
	_expect(summary_screen.showing and summary_screen._day_note.text != "", "shift screen shows today's kind of day and the summary")
	summary_screen._next_shift()
	_expect(not paused, "summary can be closed after previewing tomorrow")
	var card = load("res://scripts/delivered_card.gd").new()
	world.add_child(card)
	var sounds = load("res://scripts/sounds.gd").new()
	sounds.name = "Sounds"
	world.add_child(sounds)
	state.start_shift()
	state.offer_order(first)
	state.accept_offer()
	state.pick_up()
	state.ride_time = 10.0
	state.deliver()
	_expect(card.showing and card._title.text == "PERFECT!", "all-green delivery opens the PERFECT card")
	await create_timer(2.0, true).timeout
	_expect(sounds.play_counts.get("perfect", 0) == 1, "PERFECT plays its own happy jingle")
	card.close()
	state.save_path = "user://replay_ui_finished.json"
	world.queue_free()
	places.free()
	await process_frame
	print("RESULT: ", "FAIL" if failed else "PASS", " replay UI")
	quit(1 if failed else 0)
