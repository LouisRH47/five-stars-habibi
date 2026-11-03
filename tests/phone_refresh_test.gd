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
	state.save_path = "user://phone_refresh_finished.json"
	world.queue_free()
	places.free()
	await process_frame
	print("RESULT: ", "FAIL phone refresh" if _failed else "PASS phone refresh")
	quit(1 if _failed else 0)


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
