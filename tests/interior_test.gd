extends SceneTree
## Sessions 58-59: the walk-in rooms (docs/looks_pass_detailed_plan.md, Appendix B and J).
## Builds every Plaza restaurant (and the two shops) where it really is, then checks: each
## room fits 12 x 10 m (Grand Groceries 24 x 10) with a 4.5 m ceiling, nothing pokes through
## a wall, nothing floats (every kit model and machine sits on the floor or a counter top
## within 2 cm, except things that hang), enough seats with people eating, a menu board with
## prices, the pickup spot can be walked to from the door with a clear 1.2 m way, nothing
## blocks the door, and the food changes (Appendix F), including old saves.
## Run: godot --path . --headless -s tests/interior_test.gd

const SNAP_TOLERANCE := 0.02
var _failed := 0
var _rooms := {}   # id -> the room node
var _map: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		_failed += 1


func _run() -> void:
	_map = WahatAlShams.new().get_script().get_script_constant_map()
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	for place: Dictionary in _map["RESTAURANTS"]:
		if not place.has("row"):
			continue
		var size: Vector3 = place.get("size", _map["RESTAURANT_SIZE"])
		var room := VenueBuilder.build(place, size)
		room.name = "Restaurant_" + str(place["id"])
		room.position = place["position"]
		room.rotation_degrees.y = place["facing"]
		world.add_child(room)
		_rooms[place["id"]] = room
	for shop: Dictionary in _map["SHOPS"]:
		var room := ShopInterior.build(shop)
		world.add_child(room)
		_rooms[shop["id"]] = room
	for i in 3:
		await physics_frame
	camera.global_position = Vector3(-200, 2, -145)
	for id in _rooms:
		var room: Node3D = _rooms[id]
		if room.get_meta("interior_looks", false):
			_check_room(id, room)
	_check_food_changes()
	await _check_queue()
	await _check_old_save()
	print("RESULT: %s" % ("PASS" if _failed == 0 else "FAIL (%d)" % _failed))
	quit(0 if _failed == 0 else 1)


## Everything about one restaurant room.
func _check_room(id: String, room: Node3D) -> void:
	var size: Vector3 = room.get_meta("room_size")
	var half := size * 0.5
	var expected := Vector3(24, 4.5, 10) if id == "market" else Vector3(12, 4.5, 10)
	_expect(size.is_equal_approx(expected), "%s: the room is %.0f x %.0f m with a %.1f m ceiling" % [id, size.x, size.z, size.y])
	# The ceiling's underside is at 4.5 m.
	var hit := room.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			room.to_global(Vector3(0, 2.0, 0)), room.to_global(Vector3(0, 6.0, 0))))
	_expect(not hit.is_empty() and absf(hit["position"].y - 4.5) < 0.02, "%s: the ceiling is at 4.5 m" % id)
	# Kit models: inside the walls and sitting on their surface.
	var tops: Array = room.get_meta("counter_tops", [])
	var floating: Array[String] = []
	var poking: Array[String] = []
	var count := 0
	for prop: Node3D in room.find_children("*", "Node3D", true, false):
		if not (prop.is_in_group("kit_prop") or prop.is_in_group("kit_prop_many")):
			continue
		if _under_person(prop) or _under(prop, "ShopFront"):
			continue
		count += 1
		var boxes := _instance_boxes(prop, room)
		for box: AABB in boxes:
			var snap: String = prop.get_meta("kit_snap", "floor")
			if not _inside(box, half, snap):
				poking.append("%s at %s" % [prop.get_meta("kit_id"), box.get_center()])
			if snap == "hang":
				if absf(box.end.y - size.y) > SNAP_TOLERANCE:
					floating.append("%s hangs at %.2f" % [prop.get_meta("kit_id"), box.end.y])
			elif snap != "wall" and snap != "origin" and not _on_surface(box, tops):
				floating.append("%s bottom %.3f at (%.1f, %.1f)" % [prop.get_meta("kit_id"), box.position.y, box.get_center().x, box.get_center().z])
	_expect(count >= 10, "%s: furnished with free kit models (%d)" % [id, count])
	_expect(poking.is_empty(), "%s: no model pokes through a wall, the floor or the ceiling %s" % [id, poking.slice(0, 4)])
	_expect(floating.is_empty(), "%s: every model sits on the floor or a counter top, none floats %s" % [id, floating.slice(0, 4)])
	var machines: Array = room.get_meta("machines", [])
	var bad: Array[String] = []
	for machine: Array in machines:
		var base: Vector3 = machine[1]
		var box := AABB(base - Vector3(0.05, 0, 0.05), Vector3(0.1, 0.1, 0.1))
		if not _on_surface(box, tops) or absf(base.x) > half.x or absf(base.z) > half.z:
			bad.append(str(machine[0]))
	_expect(bad.is_empty(), "%s: machines (%d) stand on the floor or a counter, never in the air %s" % [id, machines.size(), bad])
	# Seats and people eating.
	var seats := room.find_children("Seat*", "Marker3D", true, false).size()
	var diners := room.find_children("Diner*", "Node3D", true, false).size()
	var need: int = InteriorMenus.MIN_SEATS.get(id, 20)
	_expect(seats >= need and (need == 0 or diners * 3 >= seats), "%s: %d seats (need %d) and %d people eating" % [id, seats, need, diners])
	# The menu board with prices.
	var boards := room.find_children("MenuBoard", "Node3D", true, false)
	var priced := 0
	for board in boards:
		var items: Array = board.get_meta("items", [])
		var dh := board.find_children("*", "Label3D", true, false).filter(func(l): return "Dh" in l.text).size()
		if items.size() >= (2 if id == "market" else 4) and dh >= items.size() - 1:
			priced += 1
	_expect(priced >= 1, "%s: a menu board with items and Dh prices" % id)
	# The staff who hands you the bag, the queue, the sound.
	_expect(room.get_node_or_null("CounterStaff") is Person, "%s: someone stands at the pickup spot (CounterStaff)" % id)
	var queue := room.get_node_or_null("CounterQueue")
	_expect(queue != null and room.find_children("Queue*", "Node3D", true, false).size() == 2
			and GameConfig.QUEUE_WAIT.x >= 2.0 and GameConfig.QUEUE_WAIT.y <= 4.0, "%s: a short queue (1 or 2 people, 2 to 4 s)" % id)
	var sound := room.get_node_or_null("RoomSound") as AudioStreamPlayer3D
	_expect(sound != null and sound.stream != null, "%s: its own room sound" % id)
	_check_walk(id, room, half)


## The pickup spot can be reached on foot from the door, with a 1.2 m clear way most of it,
## and nothing stands in the doorway.
func _check_walk(id: String, room: Node3D, half: Vector3) -> void:
	var pickup: Vector3 = room.get_meta("pickup")
	var door := Vector3(0, 0, half.z - 0.4)
	var blocked := _solid_at(room, door, 0.45) or _solid_at(room, door + Vector3(0, 0, -0.6), 0.45)
	_expect(not blocked, "%s: nothing blocks the door" % id)
	var near := _walk(room, half, door, pickup, 0.6, 0.75)
	var exact := _walk(room, half, door, pickup, 0.3, 0.15)
	_expect(near and exact, "%s: the pickup spot is reachable from the door on foot (1.2 m wide way: %s, last step: %s)" % [id, near, exact])
	var space := room.get_world_3d().direct_space_state
	var feet := room.to_global(pickup + Vector3(0, 0.8, 0))
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.25
	query.shape = ball
	query.transform = Transform3D(Basis(), feet)
	_expect(space.intersect_shape(query, 1).is_empty(), "%s: you can stand on the pickup spot" % id)


## Grid search (0.25 m squares) in the room from `from` until within `reach` of `to`.
func _walk(room: Node3D, half: Vector3, from: Vector3, to: Vector3, radius: float, reach: float) -> bool:
	var step := 0.25
	var seen := {}
	var queue: Array[Vector2i] = [Vector2i(roundi(from.x / step), roundi(from.z / step))]
	seen[queue[0]] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var spot := Vector3(cell.x * step, 0, cell.y * step)
		if Vector2(spot.x - to.x, spot.z - to.z).length() <= reach:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + d
			var at := Vector3(next.x * step, 0, next.y * step)
			if seen.has(next) or absf(at.x) > half.x or absf(at.z) > half.z - 0.2:
				continue
			seen[next] = true
			if not _solid_at(room, at, radius):
				queue.append(next)
	return false


func _solid_at(room: Node3D, local: Vector3, radius: float) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = radius
	query.shape = ball
	query.transform = Transform3D(Basis(), room.to_global(local + Vector3(0, maxf(0.9, radius + 0.12), 0)))
	return not room.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## The boxes (in room space) of a kit model, one per copy for a MultiMesh group.
func _instance_boxes(prop: Node3D, room: Node3D) -> Array:
	var to_room := room.global_transform.affine_inverse()
	var boxes: Array = []
	if prop.is_in_group("kit_prop_many"):
		var parts := prop.get_children().filter(func(c): return c is MultiMeshInstance3D)
		if parts.is_empty():
			return boxes
		var copies: int = (parts[0] as MultiMeshInstance3D).multimesh.instance_count
		for i in copies:
			var box := AABB()
			var first := true
			for part: MultiMeshInstance3D in parts:
				var t := to_room * part.global_transform * part.multimesh.get_instance_transform(i)
				var b := t * part.multimesh.mesh.get_aabb()
				box = b if first else box.merge(b)
				first = false
			boxes.append(box)
		return boxes
	var box := AABB()
	var first := true
	for view: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
		var b := (to_room * view.global_transform) * view.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if not first:
		boxes.append(box)
	return boxes


func _inside(box: AABB, half: Vector3, snap: String) -> bool:
	var wall := 0.125 - 0.03
	return box.position.x >= -half.x + wall and box.end.x <= half.x - wall and box.position.z >= -half.z + wall \
			and box.end.z <= half.z + 0.05 and box.position.y >= -0.03 and box.end.y <= half.y * 2.0 + 0.01


## True if the bottom of the box is on the floor or on a counter top under it.
func _on_surface(box: AABB, tops: Array) -> bool:
	var bottom := box.position.y
	if absf(bottom) <= SNAP_TOLERANCE:
		return true
	var centre := Vector2(box.get_center().x, box.get_center().z)
	for top: Array in tops:
		var rect: Rect2 = top[0]
		if rect.grow(0.05).has_point(centre) and absf(float(top[1]) - bottom) <= SNAP_TOLERANCE:
			return true
	return false


func _under_person(node: Node) -> bool:
	var at := node.get_parent()
	while at != null:
		if at is Person:
			return true
		at = at.get_parent()
	return false


func _under(node: Node, name: String) -> bool:
	var at := node.get_parent()
	while at != null:
		if at.name == name:
			return true
		at = at.get_parent()
	return false


## Appendix F: what each shop sells, the regulars, the fragile cake.
func _check_food_changes() -> void:
	var foods := {}
	for place: Dictionary in _map["RESTAURANTS"]:
		foods[place["id"]] = place.get("foods", [place["food"]])
	_expect(not "cake" in foods["bakery"] and "manakish" in foods["bakery"] and "khubz bread" in foods["bakery"] and "fatayer" in foods["bakery"],
			"Bread & Zaatar sells bread, manakish and fatayer, no cakes %s" % [foods["bakery"]])
	_expect(foods["boba"] == ["iced latte", "flat white", "croissant", "cake"], "Spill the Brew sells coffee, pastries and cake %s" % [foods["boba"]])
	var cakes: Array = _rooms["bakery"].find_children("*", "Node3D", true, false).filter(func(n): return str(n.get_meta("kit_id", "")).contains("cake"))
	var brew_cakes: Array = _rooms["boba"].find_children("*", "Node3D", true, false).filter(func(n): return str(n.get_meta("kit_id", "")).contains("cake"))
	_expect(cakes.is_empty() and brew_cakes.size() >= 3, "no cake display at the bakery; 3 cakes in Spill the Brew's pastry case (%d)" % brew_cakes.size())
	_expect(_rooms["gelato"].find_children("*", "Label3D", true, false).filter(func(l): return l.is_in_group("flavour_tag")).size() == 12, "Brain Freeze: 12 flavour tags on the gelato case")
	var regulars := {}
	for regular: Dictionary in _map["REGULARS"]:
		regulars[regular["id"]] = regular
	_expect(regulars["mariam"]["food"] == "iced latte" and regulars["mariam"]["shop"] == "boba", "Auntie Mariam's order is an iced latte from Spill the Brew")
	_expect(regulars["dana"]["food"] == "cake" and regulars["dana"]["shop"] == "boba", "Ms Dana's cake comes from Spill the Brew")
	_expect(GameConfig.FRAGILE_SHOP == "boba" and GameConfig.FRAGILE_FOOD == "cake", "fragile cakes come from Spill the Brew")
	var tables := [GameConfig.FRESHNESS_DRAIN, GameConfig.DAMAGE_SPEED_BUMP, GameConfig.DAMAGE_HARD_BRAKE, GameConfig.DAMAGE_COLLISION, GameConfig.DAMAGE_CRITTER]
	var missing: Array = []
	for id in ["boba", "bakery"]:
		for food in foods[id]:
			if not tables.all(func(t): return t.has(food)):
				missing.append(food)
	_expect(missing.is_empty(), "every new food has meter numbers %s" % [missing])
	_expect(GameConfig.DAMAGE_SPEED_BUMP["iced latte"] == GameConfig.DAMAGE_SPEED_BUMP["bubble tea"]
			and GameConfig.FRESHNESS_DRAIN["iced latte"] == GameConfig.FRESHNESS_DRAIN["bubble tea"], "the iced latte spills like bubble tea did")
	var lines := str(CustomerLines.REGULAR_LINES) + str(CustomerLines.REGULAR_STAGES)
	_expect(not "pearl" in lines.to_lower() and not "boba" in lines.to_lower(), "no customer line mentions pearls or boba")


## The short queue: sometimes 1 or 2 people at the till, and you wait 2 to 4 seconds.
func _check_queue() -> void:
	var state := root.get_node("GameState")
	var room: Node3D = _rooms["pizza"]
	var walker := Node3D.new()
	walker.name = "Walker"
	root.add_child(walker)
	walker.global_position = room.to_global(room.get_meta("pickup"))
	var order = load("res://scripts/order.gd").new()
	order.restaurant_id = "pizza"
	order.restaurant_name = "1000 Pizza"
	order.food = "pizza"
	order.villa_number = 101
	state.reset()
	var started: bool = state.offer_order(order) and state.accept_offer()
	var queue := room.get_node("CounterQueue")
	var queue_class = queue.get_script()
	seed(5)
	for attempt in 40:
		queue._checked_order = null
		queue._check_left = 0.0
		queue._process(0.0)
		if queue_class.ahead > 0:
			break
	var wait: float = queue_class.wait_left
	var shown := room.find_children("Queue*", "Node3D", true, false).filter(func(q): return q.visible).size()
	_expect(started and queue_class.ahead in [1, 2] and shown == queue_class.ahead and wait >= 2.0 and wait <= 4.0,
			"a queue of %d at the pizza counter, waiting %.1f s" % [queue_class.ahead, wait])
	queue._process(4.1)
	_expect(queue_class.wait_left == 0.0 and queue_class.ahead == 0, "after at most 4 seconds it's your turn")
	state.reset()
	walker.free()
	await process_frame


## An old save with "bubble tea" in its history still loads, as an iced latte.
func _check_old_save() -> void:
	var path := "user://interior_test_old_save.json"
	var old := {"version": 2, "money": 120, "xp": 300, "history": [
		{"restaurant": "boba", "villa": 207, "food": "bubble tea", "pay": 12, "tip": 3, "stars": 5.0, "regular_id": "mariam"},
		{"restaurant": "bakery", "villa": 901, "food": "cake", "pay": 10, "tip": 0, "stars": 4.0}],
		"regular_visits": {"mariam": 4, "dana": 2}}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var state := root.get_node("GameState")
	var loaded := SaveGame.load_into(state, path)
	_expect(loaded and state.history.size() == 2 and state.history[0]["food"] == "iced latte" and state.history[1]["food"] == "cake",
			"an old save with bubble tea loads, read as an iced latte")
	_expect(int(state.regular_visits.get("mariam", 0)) == 4 and int(state.regular_visits.get("dana", 0)) == 2, "regular visit counts are kept")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	state.reset()
	await process_frame
