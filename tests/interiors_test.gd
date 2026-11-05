extends SceneTree
## Looks pass interiors (Sessions 54 and 55): the restaurant room template, every
## restaurant's own things, sliding doors, the short queue and the indoor camera.
## (The free kits themselves are checked by tests/kit_props_test.gd.)
## Run: Godot --path . --headless -s tests/interiors_test.gd
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://interiors_test.json"
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 6:
		await physics_frame
	world.get_node("EventManager").enabled = false
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	_check_rooms(places)
	await _check_doors_queue_camera(world, places)
	world.queue_free()
	await process_frame
	SaveGame.delete(state.save_path)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " interiors · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func _check_rooms(places: PlaceBuilder) -> void:
	var signatures := {}
	for shop: Dictionary in places.restaurants:
		var kind: String = shop.get("venue_type", "")
		if not RestaurantStyles.has_room(kind):
			continue
		var room: Node3D = places.get_node("Restaurant_" + shop["id"])
		var name: String = shop["name"]
		var rect: Rect2 = room.get_meta("room_rect", Rect2())
		_expect(rect.size.is_equal_approx(Vector2(12, 10)) and is_equal_approx(room.get_meta("ceiling", 0.0), 4.5),
				name + " is a cosy 12 x 10 m room with a 4.5 m ceiling")
		var people := {}
		for person in room.get_children():
			if person is Person:
				people[person.name.rstrip("0123456789")] = people.get(person.name.rstrip("0123456789"), 0) + 1
		_expect(people.get("CounterStaff", 0) == 1 and people.get("Cook", 0) >= 1 and people.get("SeatedCustomer", 0) >= 3,
				name + " has staff at the counter, a cook and people eating", str(people))
		for part in ["MenuBoard", "TiledFloor", "DrinksFridge", "Bin", "Plant", "SlidingDoor", "InteriorLight", "KitchenLight", "RoomSound", "KitBatch_restaurant"]:
			_expect(room.find_child(part, false, false) != null, name + " has " + part)
		var lamps := room.find_children("Lamp*", "Node3D", false, false).size() + room.find_children("Lantern*", "Node3D", true, false).size()
		_expect(lamps >= 4 and (room.get_node("InteriorLight") as OmniLight3D).shadow_enabled, name + " has warm hanging lamps and soft shadows", str(lamps))
		_expect(room.get_meta("kit_props", 0) >= 10, name + " is furnished from the free kits", str(room.get_meta("kit_props", 0)))
		_expect(ResourceLoader.exists("res://assets/audio/" + str(room.get_meta("room_sound", "none"))), name + " has its own background sound")
		signatures[room.get_meta("signature", "")] = true
	_expect(signatures.size() >= 5 and not signatures.has(""), "no two restaurant rooms have the same signature", str(signatures.keys()))
	var pizza: Node3D = places.get_node("Restaurant_pizza")
	_expect(pizza.find_child("BrickOven", false, false) != null and pizza.find_children("Flame*", "Node3D", false, false).size() >= 3, "1000 Pizza has a brick dome oven with flames")
	var gelato: Node3D = places.get_node("Restaurant_gelato")
	_expect(gelato.get_node("GelatoFreezer").get_child_count() >= 16, "Brain Freeze has a glass freezer of 8 tubs")
	var shawarma: Node3D = places.get_node("Restaurant_shawarma")
	_expect(shawarma.find_children("ShawarmaSpit*", "Node3D", false, false).size() == 2, "Shawarma Supreme has two shawarma grills")
	_expect(places.get_node("Restaurant_bakery").get_node("CakeDisplay").get_child_count() >= 16, "Bread & Zaatar has a glass cake display")


func _check_doors_queue_camera(world: Node3D, places: PlaceBuilder) -> void:
	var walker: Node3D = world.get_node("Walker")
	var bike: Node3D = world.get_node("Bike")
	var on_foot: Node = world.get_node("OnFoot")
	var delivery: Node = world.get_node("DeliveryManager")
	var queue: Node = world.get_node("VenueQueue")
	var camera: Node = world.get_node("FollowCamera")
	var state: Node = root.get_node("GameState")
	var room: Node3D = places.get_node("Restaurant_shawarma")
	var motion: VenueMotion = room.get_node("Motion")
	var spit: Node3D = room.get_node("ShawarmaSpit1")
	var turn := spit.rotation.y
	bike.global_position = places.restaurant_approach("shawarma") + Vector3.UP * 0.05
	bike.speed = 0.0
	_expect(on_foot.get_off(), "get off at Shawarma Supreme")
	var front := (places.restaurant_entrance("shawarma") - room.global_position)
	front.y = 0
	front = front.normalized()
	walker.global_position = places.restaurant_entrance("shawarma") + front * 6.0
	for i in 60:
		await physics_frame
	_expect(not motion.doors_open, "the sliding doors are shut when nobody is near")
	_expect(absf(spit.rotation.y - turn) > 0.01, "the shawarma grills spin")
	# An order from here with two people already in the queue.
	var order: Order = delivery.make_order("shawarma", 0)
	_expect(state.offer_order(order) and delivery.accept(), "take an order from Shawarma Supreme")
	await process_frame
	queue.start("shawarma", 2)
	_expect(queue.ahead == 2 and room.get_node("QueuePerson1").visible and room.get_node("QueuePerson2").visible, "two people wait at the counter")
	walker.global_position = places.restaurant_entrance("shawarma") + front * 1.0
	await process_frame
	var counter := places.restaurant_counter("shawarma")
	walker.rotation = Vector3(0, atan2(-(counter - walker.global_position).x, -(counter - walker.global_position).z), 0)
	Input.action_press("move_forward")
	var opened := false
	for i in 400:
		await physics_frame
		opened = opened or motion.doors_open
		if delivery.is_near_target():
			break
	Input.action_release("move_forward")
	await process_frame
	await process_frame
	_expect(opened, "the glass doors slide open as you walk up")
	_expect(delivery.is_near_target() and RestaurantRoom.is_inside(room, walker.global_position), "you can walk in to the counter")
	_expect(queue.waiting(), "you wait your turn in the queue", "%.1f s" % queue.wait_left)
	Input.action_press("interact")
	for i in 30:
		await physics_frame
	_expect(delivery.hold_progress() == 0.0 and state.stage_name() == "TO_RESTAURANT", "holding E does nothing while someone is served")
	var waited := 0.5
	while queue.waiting() and waited < 6.0:
		await physics_frame
		waited += 1.0 / Engine.physics_ticks_per_second
	Input.action_release("interact")
	_expect(waited >= GameConfig.QUEUE_WAIT_MIN - 0.1 and waited <= GameConfig.QUEUE_WAIT_MAX + 0.3, "the queue takes 2 to 4 seconds", "%.1f s" % waited)
	_expect(camera.indoor > 0.5 and camera.target_indoors(), "the camera comes closer indoors", "%.2f" % camera.indoor)
	await physics_frame
	Input.action_press("interact")
	for i in 110:
		await physics_frame
	Input.action_release("interact")
	_expect(state.stage_name() == "TO_VILLA", "holding E after the queue collects the food")
	for i in 480:
		await physics_frame
	_expect(not room.get_node("QueuePerson1").visible and not room.get_node("QueuePerson2").visible, "the queue people walk out and leave")
	state.reset()
