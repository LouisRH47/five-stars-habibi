extends SceneTree
## An unchanged phone frame must not emit style/theme invalidations or rebuild layout.
var _failed := false
var _style_changes := 0
var _theme_changes := 0

class TestBike extends Node3D:
	var speed := 0.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "user://phone_refresh_test.json"
	state.reset()
	var world := Node3D.new()
	root.add_child(world)
	var places := PlaceBuilder.new()
	places.restaurants = [{"id": "pizza", "name": "Test Pizza", "food": "pizza", "position": Vector3.ZERO, "facing": 0.0}]
	places.villas = [{"number": 101, "house": 1, "position": Vector3(0, 0, 50), "facing": 0.0, "cluster": "C1", "address": "Villa 1, Cluster 1"}]
	var bike := TestBike.new()
	world.add_child(bike)
	var delivery = load("res://scripts/delivery_manager.gd").new()
	delivery.bike = bike
	delivery.place_builder = places
	world.add_child(delivery)
	delivery.set_physics_process(false)
	var phone = load("res://ui/phone.tscn").instantiate()
	phone.delivery_manager = delivery
	world.add_child(phone)
	phone.set_process(false)
	var order: Order = load("res://scripts/order_maker.gd").new(places, 8.0).make("pizza", 101)
	state.offer_order(order)
	delivery._offer_left = 30.0
	phone._process(0.0)
	await process_frame
	for label: Label in [phone._pill] + phone._chips.values():
		label.get_theme_stylebox("normal").changed.connect(func(): _style_changes += 1)
	for label: Label in [phone._pick_up, phone._drop_off, phone._hint]:
		label.theme_changed.connect(func(): _theme_changes += 1)
	for i in 8:
		phone._process(0.0)
	await process_frame
	print("PHONE_INVALIDATIONS: styles=", _style_changes, " themes=", _theme_changes)
	_expect(_style_changes == 0 and _theme_changes == 0, "unchanged offer frames emit no style or theme invalidations")
	_expect(phone._chips["time"].text == "30 s" and phone._pill.text == "NEW ORDER", "steady phone retains the offered order and countdown")
	delivery._offer_left = 29.0
	phone._process(0.0)
	_expect(phone._chips["time"].text == "29 s", "countdown still updates when its displayed second changes")
	state.accept_offer()
	phone._process(0.0)
	_expect(phone._pill.text == "PICK UP" and phone._pick_up.get_theme_color("font_color") == phone.ORANGE,
			"accepting an offer still changes the pill and highlights the pickup stop")
	_style_changes = 0
	_theme_changes = 0
	await process_frame
	_style_changes = 0
	_theme_changes = 0
	for i in 8:
		phone._process(0.0)
	await process_frame
	_expect(_style_changes == 0 and _theme_changes == 0, "unchanged pickup frames also preserve cached styles")
	_check_shift_end(world, state, delivery, phone, order)
	state.save_path = "user://phone_refresh_finished.json"
	world.queue_free()
	places.free()
	await process_frame
	print("RESULT: ", "FAIL phone refresh" if _failed else "PASS phone refresh")
	quit(1 if _failed else 0)


func _check_shift_end(world: Node3D, state: Node, delivery, phone, order: Order) -> void:
	var screen = load("res://scripts/shift_screen.gd").new()
	world.add_child(screen)
	var shift = load("res://scripts/shift_manager.gd").new()
	shift.shift_screen = screen
	world.add_child(shift)
	shift.set_physics_process(false)

	state.pick_up()
	state.shift_time_left = 0.0
	shift._physics_process(0.0)
	phone._process(0.0)
	_expect(not paused and not screen.showing and state.current_order == order and phone._pill.text == "DROP OFF",
			"an accepted delivery remains on the phone after the shift clock runs out")
	state.deliver()
	_expect(paused and screen.showing and phone._status.text == "Shift over" and not phone._result.visible,
			"the phone shows the shift is over behind the summary after the last delivery")
	screen._next_shift()
	phone._process(0.0)
	_expect(not paused and phone._pill.text == "WAITING", "the next shift restores the idle phone")

	order.note = "Leave by the gate"
	state.offer_order(order)
	phone._process(0.0)
	_expect(phone._stops.visible and phone._chip_row.visible and phone._note.visible,
			"the pending offer is visible before the shift closes")
	state.shift_time_left = 0.0
	shift._physics_process(0.0)
	_expect(paused and screen.showing and state.offered_order == null and phone._status.text == "Shift over"
			and not phone._stops.visible and not phone._chip_row.visible and not phone._note.visible
			and not phone._hint.visible, "the paused summary shows no expired offer or accept hint")
	screen._next_shift()

	var another_order: Order = load("res://scripts/order_maker.gd").new(delivery.place_builder, 8.0).make("pizza", 101)
	var choices: Array[Order] = [order, another_order]
	state.offer_choices(choices)
	phone._process(0.0)
	_expect(phone._choices_box.visible, "the two choices are visible before the offer expires")
	delivery._offer_left = 0.0
	delivery._physics_process(0.0)
	state.shift_time_left = 0.0
	shift._physics_process(0.0)
	_expect(paused and screen.showing and state.offered_orders.is_empty() and phone._status.text == "Shift over"
			and not phone._choices_box.visible and not phone._hint.visible,
			"the paused summary clears choices that expired earlier in the same physics frame")
	screen._next_shift()


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
