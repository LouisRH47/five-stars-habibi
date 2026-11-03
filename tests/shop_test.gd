extends SceneTree
## Run only in an isolated source snapshot with redirected user:// paths.

const TEST_SAVE := "user://shop_test_save.json"
var _failed := false
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	state = root.get_node("GameState")
	state.save_path = TEST_SAVE
	state.reset()
	state.shift_goals.clear()
	state.goal_pool.clear()
	var cart := ShopCart.new(state)
	state.money = 100
	_expect(not cart.add("gps")["ok"] and cart.entries.is_empty(), "locked upgrades cannot enter the cart")
	state.xp = 100000
	_expect(cart.add("gps")["ok"] and cart.add("bell")["ok"], "two different upgrades can share one cart")
	_expect(cart.quote()["total"] == 75 and state.upgrade_levels.is_empty(), "quoting the cart changes no ownership or money")
	_expect(cart.checkout()["ok"] and state.money == 25 and state.upgrade_level("gps") == 1 and state.upgrade_level("bell") == 1,
			"checkout charges once and commits both upgrades")
	_expect(not cart.add("gps")["ok"], "single-purchase upgrades cannot be bought twice")
	cart.add("insulated_bag")
	cart.add("anti_spill")
	_expect(not cart.checkout()["ok"] and state.money == 25 and state.upgrade_level("insulated_bag") == 0,
			"insufficient funds leave the entire cart unbought")
	cart.clear()
	state.money = 5000
	cart.add("stamina")
	cart.add("stamina")
	_expect(cart.quote()["total"] == 100 and cart.checkout()["ok"] and state.upgrade_level("stamina") == 2,
			"repeatable stamina prices rise for each copy in the same cart")
	for i in 8:
		cart.add("stamina")
	_expect(cart.checkout()["ok"] and state.upgrade_level("stamina") == 10 and not cart.add("stamina")["ok"],
			"stamina is capped at ten purchases")
	_expect(not cart.add("carbon")["ok"], "carbon frame requires the aluminium frame")
	cart.add("aluminium")
	cart.add("carbon")
	_expect(cart.quote()["total"] == 290 and cart.checkout()["ok"], "a prerequisite and its upgrade can be checked out together")
	cart.add("rocket")
	state.xp = 0
	state.money = 20000
	_expect(not cart.checkout()["ok"] and state.upgrade_level("rocket") == 0 and state.money == 20000,
			"checkout rechecks level before any wallet or ownership change")
	cart.clear()
	state.xp = 100000
	_expect(not cart.add("box_gold")["ok"], "gold delivery box stays locked until a cluster is complete")
	state.owned_collection_rewards["C1"] = "gold_C1"
	_expect(cart.add("box_gold")["ok"] and cart.quote()["total"] == 0 and cart.checkout()["ok"],
			"a completed cluster unlocks the free gold box")
	cart.add("paint_sunset")
	cart.add("box_teal")
	_expect(cart.checkout()["ok"] and state.equipped_cosmetics["paint"] == "paint_sunset", "bike paint and box colours are bought and equipped together")
	var wallet: int = state.money
	cart.add("paint_sunset")
	_expect(cart.quote()["total"] == 0 and cart.checkout()["ok"] and state.money == wallet,
			"equipping an owned cosmetic is free")
	_expect(state.save_game(), "shop progress writes to the isolated save")
	var expected: Dictionary = state.upgrade_levels.duplicate()
	state.upgrade_levels.clear()
	state.owned_items.clear()
	state.equipped_cosmetics.clear()
	var loaded := SaveGame.load_into(state, TEST_SAVE)
	var levels_ok := true
	for id in expected:
		levels_ok = levels_ok and state.upgrade_level(id) == expected[id]
	_expect(loaded and levels_ok
			and state.equipped_cosmetics.get("paint") == "paint_sunset" and state.owned_items.has("box_teal"),
			"upgrades, owned items and equipped colours survive save/load")
	var goal := GearCatalog.next_goal(state)
	_expect(goal.has("description") and goal["progress"] >= 0.0 and goal["progress"] <= 1.0,
			"phone/summary next goal has a bounded progress bar")
	var saved_levels: Dictionary = state.upgrade_levels.duplicate()
	state.upgrade_levels = {"gps": 1, "bell": 1, "insulated_bag": 1, "anti_spill": 1, "stamina": 1}
	_expect(GearCatalog.next_goal(state)["id"] == "brakes", "next goal introduces new equipment before repeat stamina purchases")
	state.upgrade_levels = saved_levels
	await _check_shop_view()
	SaveGame.delete(TEST_SAVE)
	state.save_path = "user://shop_test_finished.json"
	print("RESULT: ", "FAIL shops" if _failed else "PASS shops")
	quit(1 if _failed else 0)


func _check_shop_view() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var places: Array = [
		{"id": "bikes", "name": "Pedal Point Bikes", "arabic": "بيدال بوينت", "position": Vector3.ZERO, "facing": 0.0},
		{"id": "clothes", "name": "Dune Drip", "arabic": "ديون دريب", "position": Vector3(30, 0, 0), "facing": 0.0}]
	for place: Dictionary in places:
		var room := ShopInterior.build(place)
		world.add_child(room)
		_expect(room.get_meta("walk_in") and room.find_children("*", "CollisionShape3D", false, false).size() >= 8,
				"shop has an open entrance and solid room/counter")
	var bike: Node3D = load("res://scenes/bike.tscn").instantiate()
	world.add_child(bike)
	# Resolve scripts that read autoloads after the autoloads exist, not while Godot
	# is compiling this standalone SceneTree entry point.
	var walker: Node3D = load("res://scripts/walker.gd").new()
	walker.name = "Walker"
	world.add_child(walker)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	var shop := ShopController.new()
	shop.bike = bike
	shop.walker = walker
	shop.camera = camera
	shop.configure(places)
	world.add_child(shop)
	_expect(bike.upgrade_levels == state.upgrade_levels and is_equal_approx(bike.stamina_capacity(), GameConfig.STAMINA_MAX * 2),
			"loaded shop upgrades are applied to the actual bicycle")
	var frame: MeshInstance3D
	for mesh: MeshInstance3D in bike.get_node("Model").find_children("*", "MeshInstance3D", true, false):
		if mesh.get_meta("bike_paint", false):
			frame = mesh
			break
	_expect(frame != null and frame.material_override.albedo_color == GearCatalog.find("paint_sunset")["colour"],
			"saved paint appears on real frame geometry")
	var old_look: Dictionary = state.equipped_cosmetics.duplicate()
	_expect(shop.open_shop("clothes") and paused, "opening the shop keeps the 3D view and suspends gameplay input")
	shop.select_item(1)
	_expect(state.equipped_cosmetics == old_look and not state.owned_items.has("caps_sunset"), "trying an unbought item changes only the preview")
	shop.close_shop()
	_expect(not paused and camera.current and state.equipped_cosmetics == old_look, "Esc restores the camera and original unbought outfit")
	shop.open_shop("clothes")
	shop.select_item(1)
	shop.add_selected()
	_expect(shop.checkout()["ok"] and state.equipped_cosmetics.get("head") == "caps_sunset", "clothes preview becomes the saved outfit after checkout")
	shop.close_shop()
	_expect(walker.get_node("Model/Wardrobe").get_child_count() > 0, "purchased clothes are applied to the walker")
	for look in 3:
		var rider := RiderLook.make_rider()
		world.add_child(rider)
		RiderLook.apply(rider, look)
		_expect(rider.has_head_geometry() and rider.get_node("Wardrobe").get_child_count() > 0,
				"fresh rider/card/clinic models retain the purchased look and a head")
		rider.free()
	var seated := PeopleLooks.resident(3)
	world.add_child(seated)
	seated.play("sit")
	await process_frame
	await process_frame
	var knee := seated.skeleton.find_bone("LeftLeg")
	var foot := seated.skeleton.find_bone("LeftFoot")
	var hip := seated.skeleton.find_bone("LeftUpLeg")
	var hip_at := seated.skeleton_to_me * seated.skeleton.get_bone_global_pose(hip).origin
	var knee_at := seated.skeleton_to_me * seated.skeleton.get_bone_global_pose(knee).origin
	var foot_at := seated.skeleton_to_me * seated.skeleton.get_bone_global_pose(foot).origin
	_expect(seated.can_do("sit") and knee_at.z < hip_at.z - 0.15 and foot_at.y < knee_at.y - 0.15,
			"seated customers have bent knees and feet below their lap")
	_expect(shop.open_shop("bikes") and world.get_node_or_null("ShopPreview/DeliveryBox") != null, "bike shop previews a real bicycle on its stand")
	shop.select_item(4)
	await process_frame
	await process_frame
	await process_frame
	_expect(shop.panel._panel.size.y < 1000 and shop.panel._scroll.size.y <= 341,
			"long upgrade list stays inside the screen with a bounded scroller")
	shop.close_shop()
	var counter := SidePanel.new()
	world.add_child(counter)
	counter.show_counter("Reception", "Hold E to hand over food", 0.5)
	await process_frame
	await process_frame
	_expect(not counter._scroll.visible and counter._panel.size.y < 350,
			"counter uses a compact handoff panel without empty shop rows")
	world.queue_free()
	await process_frame


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
