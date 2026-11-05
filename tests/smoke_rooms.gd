extends RefCounted
## Looks pass smoke check (Sessions 54 and 55), run by tests/smoke_test.gd: for every
## restaurant room, take an order, get off, walk in through the sliding doors, wait in the
## short queue, hold E at the counter, and walk back out. Runs at double speed to stay quick.


func run(t: SceneTree) -> void:
	var main: Node = t.get("_main")
	var queue: Node = main.get_node_or_null("VenueQueue")
	if queue == null:
		print("      no VenueQueue in this scene, restaurant rooms not checked")
		return
	var delivery: Node = t.get("_delivery")
	var on_foot: Node = t.get("_on_foot")
	var gs: Node = t.get("_game_state")
	var bike: Node3D = t.get("_bike")
	var places: PlaceBuilder = delivery.place_builder
	var walker: Node3D = on_foot.walker
	var camera: Node = main.get_node("FollowCamera")
	var steps_hold := 110  # a bit longer than the 1.5 s hold
	Engine.time_scale = 2.0
	var count := 0
	for shop: Dictionary in places.restaurants:
		if not RestaurantStyles.has_room(shop.get("venue_type", "")):
			continue
		var id: String = shop["id"]
		var room: Node3D = places.get_node("Restaurant_" + id)
		var motion: Node = room.get_node("Motion")
		gs.reset()
		var order: Order = delivery.make_order(id, 0)
		var took: bool = gs.offer_order(order) and delivery.accept()
		await t.process_frame
		var people := 1 + count % 2
		queue.start(id, people)
		bike.global_position = places.restaurant_approach(id) + Vector3.UP * 0.05
		bike.velocity = Vector3.ZERO
		bike.speed = 0.0
		await t.physics_frame
		var off: bool = on_foot.get_off()
		var front := places.restaurant_entrance(id) - room.global_position
		front.y = 0.0
		front = front.normalized()
		walker.global_position = places.restaurant_entrance(id) + front * 1.0 + Vector3.UP * 0.05
		walker.velocity = Vector3.ZERO
		await t.process_frame
		_face(walker, places.restaurant_counter(id))
		Input.action_press("move_forward")
		var opened := false
		for frame in 600:
			await t.physics_frame
			opened = opened or motion.doors_open
			if delivery.is_near_target():
				break
		Input.action_release("move_forward")
		await t.process_frame
		await t.process_frame
		var name: String = shop["name"]
		t.call("_check", "walk in through the sliding doors of " + name + " (you can't collect from outside)",
				took and off and opened and delivery.is_near_target() and RestaurantRoom.is_inside(room, walker.global_position), "")
		t.call("_check", "%d in the queue at %s, so you wait" % [people, name], queue.waiting(), "%.1f s" % queue.wait_left)
		var waited := 0
		while queue.waiting() and waited < 600:
			await t.physics_frame
			waited += 1
		t.call("_check", "the queue at " + name + " is short", not queue.waiting(), "%.1f s" % (waited * Engine.time_scale / Engine.physics_ticks_per_second))
		Input.action_press("interact")
		for frame in steps_hold:
			await t.physics_frame
		Input.action_release("interact")
		t.call("_check", "holding E at the counter collects from " + name, gs.stage_name() == "TO_VILLA" and camera.indoor > 0.5, "")
		_face(walker, places.restaurant_entrance(id) + front * 3.0)
		Input.action_press("move_forward")
		for frame in 600:
			await t.physics_frame
			if not RestaurantRoom.is_inside(room, walker.global_position):
				break
		Input.action_release("move_forward")
		t.call("_check", "walk back out of " + name, not RestaurantRoom.is_inside(room, walker.global_position), "")
		on_foot.get_on(true)
		count += 1
	Engine.time_scale = 1.0
	gs.reset()


func _face(body: Node3D, spot: Vector3) -> void:
	var way := spot - body.global_position
	body.rotation = Vector3(0.0, atan2(-way.x, -way.z), 0.0)
