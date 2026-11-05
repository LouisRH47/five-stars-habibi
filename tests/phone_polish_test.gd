extends SceneTree
## Session 70: the clearer phone, the offer card with its countdown ring, and the nicer
## mini-map (docs/polish_plan.md P1 to P5). Bare UI nodes on a tiny test map, no world.
var _failed := false

class TestBike extends Node3D:
	var speed := 0.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "user://phone_polish_test.json"
	state.reset()
	state.tutorial_running = false
	var world := Node3D.new()
	root.add_child(world)
	var places := PlaceBuilder.new()
	places.restaurants = [{"id": "pizza", "name": "1000 Pizza", "food": "pizza", "position": Vector3.ZERO, "facing": 0.0, "colour": Color.RED}]
	places.villas = [{"number": 101, "house": 7, "position": Vector3(0, 0, 400), "facing": 0.0, "cluster": "C1", "address": "Villa 7, Cluster 1"},
			{"number": 102, "house": 8, "position": Vector3(0, 0, 900), "facing": 0.0, "cluster": "C1", "address": "Villa 8, Cluster 1"}]
	var bike := TestBike.new()
	world.add_child(bike)
	var dm = load("res://scripts/delivery_manager.gd").new()
	dm.bike = bike
	dm.place_builder = places
	world.add_child(dm)
	dm.set_physics_process(false)
	var phone = load("res://ui/phone.tscn").instantiate()
	phone.delivery_manager = dm
	world.add_child(phone)
	phone.set_process(false)
	var mini = load("res://ui/minimap.tscn").instantiate()
	mini.bike = bike
	mini.delivery_manager = dm
	mini.place_builder = places
	world.add_child(mini)
	await process_frame
	_expect(GameConfig.PHONE_V2 and phone._v2 != null and GameConfig.MINIMAP_V2 and mini.look != null, "the Session 70 phone and mini-map are on")

	# P1: readable text and a lighter phone.
	phone._process(0.0)
	_expect(phone.mode == "waiting" and phone._status.text == "Waiting for orders" and phone._v2._wait_dots.visible,
			"waiting mode: 'Waiting for orders' with the bouncing dots")
	var small: Array[String] = []
	for label: Label in phone.get_node("Panel").find_children("*", "Label", true, false):
		var font_size: int = label.get_theme_font_size("font_size")
		if font_size < 16:
			small.append("%s %d" % [label.name, font_size])
	_expect(small.is_empty(), "no phone label under 16 px (%s)" % ", ".join(small))
	var header_hidden: bool = not phone.get_node("Panel/Margin/Rows/Header/Wallet").visible \
			and not phone.get_node("Panel/Margin/Rows/Profile").visible and not phone.get_node("Panel/Margin/Rows/XP").visible
	_expect(header_hidden == GameConfig.HUD_TOP_CHIPS, "money, stars and level leave the phone when the HUD chips show them")
	_expect(phone.get_node("Panel/Margin/Rows/Goals").visible, "goals are open while you wait")
	_expect(phone._pill.get_parent().name == "Header", "the status pill sits in the header")

	# P2: the offer card.
	var maker = load("res://scripts/order_maker.gd").new(places, 8.0)
	var order: Order = maker.make("pizza", 101)
	order.note = "Ring twice please"
	state.offer_order(order)
	_expect(phone.offset.x > 300.0, "a new order starts the phone off to the right")
	phone._process(0.0)
	var card: PhoneOfferCard = phone._v2.offer
	_expect(phone.mode == "offer" and card.top.visible and card.actions.visible and card.pay.text == "%d Dh" % order.pay,
			"offer mode: the pay big (%s)" % card.pay.text)
	var trip := PhoneOfferCard.trip_text(PhoneOfferCard.route_metres(places, order, bike.global_position))
	_expect(card.trip.text == trip and "min" in trip and phone._stops.visible and phone._note.visible,
			"offer card: distance and minutes, the route line and the note (%s)" % card.trip.text)
	_expect(not phone._hint.visible and not phone._chips["time"].visible and not phone._chips["pay"].visible,
			"the ring and the big pay replace the 'E accept' line and the time and pay chips")
	_expect(is_equal_approx(card.ring.value, 1.0) and card.time_left.text == "30 s left", "the ring starts full at 30 s")
	for i in 30:
		dm._physics_process(0.5)
	phone._process(0.0)
	_expect(absf(card.ring.value - 0.5) < 0.02 and card.time_left.text == "15 s left", "after 15 s the ring is half way (%.2f)" % card.ring.value)
	dm.set_physics_process(true)
	paused = true
	for i in 20:
		await physics_frame
	paused = false
	dm.set_physics_process(false)
	phone._process(0.0)
	_expect(absf(card.ring.value - 0.5) < 0.02, "paused time doesn't run the ring down (%.2f)" % card.ring.value)
	card.set_time(4.0, 30.0, false)
	_expect(card.ring.ring_colour() == UiPalette.band_colour(2), "the ring turns red in the last 5 seconds")
	await create_timer(0.8).timeout
	_expect(phone.offset == Vector2.ZERO, "the slide-in ends at offset 0")

	# P3: the job view.
	state.accept_offer()
	bike.global_position = Vector3(0, 0, -183)  # 183 m from the pizza place (rounded: 180 m)
	phone._process(0.3)
	var near: Vector3 = places.restaurant_approach("pizza")
	var expected := PhoneOfferCard.distance_text(Vector2(near.x, near.z).distance_to(Vector2(0, -183)))
	_expect(phone.mode == "to_restaurant" and phone._status.text == "1000 Pizza" and phone._v2.distance.visible
			and phone._v2.distance.text == expected + " away", "to_restaurant: the place name big and the live distance (%s)" % phone._v2.distance.text)
	_expect(phone._pill.text == "PICK UP" and not phone.get_node("Panel/Margin/Rows/Goals").visible, "on a job the goals fold away")
	phone._v2.toggle_goals()
	phone._process(0.0)
	_expect(phone.get_node("Panel/Margin/Rows/Goals").visible, "G opens the goals on a job")
	phone._v2.toggle_goals()
	_expect(phone._v2._hint_key.visible and phone._v2._hint_key.key_text == "E" and phone._hint.text == "Hold E to pick up",
			"the 'what now' line shows the E key as a keycap")
	state.pick_up()
	phone._process(0.3)
	_expect(phone.mode == "to_villa" and phone._status.text == order.address and phone._pick_up.text.begins_with("Picked up"),
			"to_villa: the address big and the pick-up ticked off")
	_expect(PhoneOfferCard.distance_text(176.0) == "180 m" and PhoneOfferCard.distance_text(1234.0) == "1.2 km", "distances round to 10 m and 0.1 km")

	# Fits on the iPad-sized window at 130% text.
	await process_frame
	var visible_area := Vector2(1024, 768) / (minf(1024.0 / 1920.0, 768.0 / 1080.0) * 1.3)
	var job_height: float = phone.get_node("Panel").get_combined_minimum_size().y

	# Two orders: two cards.
	state.current_order = null
	state._set_stage(state.Stage.NONE)
	var other: Order = maker.make("pizza", 102)
	var offers: Array[Order] = [order, other]
	state.offer_choices(offers)
	phone._process(0.0)
	await process_frame
	var cards: int = phone._choices_box.get_child_count()
	_expect(phone._choices_box.visible and cards == 2 and phone._v2.choice_pay[1].text == "%d Dh" % other.pay
			and "m route" in phone._choice_info[0].text, "two-order mode shows 2 cards with their pay")
	_expect(card.actions.visible and card.ring.key_text == "" and not card.top.visible, "two orders: the ring shows the seconds, no single pay")
	var choice_size: Vector2 = phone.get_node("Panel").get_combined_minimum_size()
	_expect(maxf(job_height, choice_size.y) + 48.0 < visible_area.y - 200.0 and choice_size.x + 48.0 < visible_area.x - 320.0,
			"the phone fits at 1024x768 with 130%% text (%.0f x %.0f in %.0f x %.0f)" % [choice_size.x, maxf(job_height, choice_size.y), visible_area.x, visible_area.y])
	state.skip_offer()

	# P4: the mini-map.
	mini._process(0.0)
	_expect(is_equal_approx(mini.radius, GameConfig.MINIMAP_RADIUS_SLOW), "mini-map: 60 m radius standing still (%.0f)" % mini.radius)
	bike.speed = GameConfig.BIKE_SPRINT_MAX_SPEED_KMH / 3.6
	for i in 10:
		mini._process(0.5)
	_expect(absf(mini.radius - GameConfig.MINIMAP_RADIUS_FAST) < 0.5, "mini-map: 90 m radius at 36 km/h (%.1f)" % mini.radius)
	bike.speed = 0.0
	for i in 10:
		mini._process(0.5)
	_expect(absf(mini.radius - GameConfig.MINIMAP_RADIUS_SLOW) < 0.5, "and back to 60 m when you stop")
	var target: Order = maker.make("pizza", 102)
	state.offer_order(target)
	state.accept_offer()
	state.pick_up()
	bike.global_position = Vector3.ZERO
	bike.rotation = Vector3.ZERO
	mini._process(0.0)
	var centre: Vector2 = mini._view.size * 0.5
	var door: Vector3 = dm.target_door()
	var exact: Vector2 = mini.world_to_map(door)
	var arrow: Vector2 = mini.look.arrow_spot(exact)
	var reach: float = centre.x - GameConfig.MINIMAP_RING_WIDTH * 0.5 - 4.0
	_expect(exact.distance_to(centre) > centre.x and absf(arrow.distance_to(centre) - reach) < 0.5
			and (arrow - centre).normalized().dot((exact - centre).normalized()) > 0.999,
			"a far stop gets an arrow on the ring pointing its way (at %s)" % arrow)
	_expect(mini.target_label() == "Villa 8, Cluster 1", "the pill under the map names the stop")
	var keep: bool = Settings.minimap_north_up
	var up_ok := true
	var turn_ok := true
	for turn in [0.0, 1.2, -2.5]:
		bike.rotation.y = turn
		Settings.minimap_north_up = true
		var north: Vector2 = mini.world_to_map(Vector3(0, 0, -20)) - centre
		up_ok = up_ok and north.y < -10.0 and absf(north.x) < 0.5
		Settings.minimap_north_up = false
		var ahead: Vector2 = mini.world_to_map(bike.global_position - bike.global_basis.z * 20.0) - centre
		turn_ok = turn_ok and ahead.y < -10.0 and absf(ahead.x) < 0.5
	Settings.minimap_north_up = keep
	_expect(up_ok, "North up keeps north at the top while the bike turns")
	_expect(turn_ok, "the default still turns with you (ahead is up)")

	world.queue_free()
	places.free()
	await process_frame
	print("RESULT: ", "FAIL phone polish" if _failed else "PASS phone polish")
	quit(1 if _failed else 0)


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
