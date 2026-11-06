extends SceneTree
## Session 90 (restaurants): the Plaza restaurant fronts.
##   - the homes above the restaurants look like the house kit (framed windows, balconies
##     with plants, AC units) and sit right on the shop fronts (no gap, nothing floating)
##   - every bench outside a restaurant faces out, away from the building
##   - the pizza oven's flue touches the dome and goes up into the ceiling
##   - the waiter outside each restaurant keeps doing different things (~20 s watched)
## Run: Godot --path . --headless -s tests/restaurant_fronts_test.gd   (prints RESULT: PASS)
var failures: Array[String] = []
var checks := 0
var world: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://restaurant_fronts_test.json"
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 10:
		await physics_frame
	world.get_node("EventManager").enabled = false
	var map: Dictionary = (load("res://data/wahat_al_shams.gd") as Script).get_script_constant_map()
	var rooms := _restaurant_rooms()
	_expect(rooms.size() >= 9, "the Plaza restaurants are walk-in rooms", str(rooms.size()))
	_check_homes(rooms, map)
	_check_benches(rooms)
	_check_flue(rooms)
	await _check_waiters(rooms)
	world.queue_free()
	await process_frame
	SaveGame.delete(state.save_path)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " restaurant fronts · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


## The walk-in restaurants with a restaurant room (not the supermarket).
func _restaurant_rooms() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for node in world.get_tree().get_nodes_in_group("venue_room"):
		if node.get_meta("interior_style", "") == "restaurant_room" and str(node.name).begins_with("Restaurant_"):
			found.append(node)
	return found


## The homes: one block per row, house-kit details, and the block sits right on the shop
## fronts: same bottom as the shop tops, front face level with the shop front, and the
## bottom band covers the join and reaches past the shop front.
func _check_homes(rooms: Array[Node3D], map: Dictionary) -> void:
	var floors := world.get_node_or_null("DistrictDetail/PlazaUpperFloors")
	_expect(floors != null, "the homes above the restaurants exist")
	if floors == null:
		return
	var homes: Array[Node3D] = []
	for child in floors.get_children():
		if str(child.name).begins_with("PlazaHomes_"):
			homes.append(child)
	_expect(homes.size() == 2, "one long block of homes over each restaurant row (no gap in the middle)", str(homes.size()))
	for home in homes:
		var ok: bool = home.get_meta("frames", 0) >= 60 and home.get_meta("balconies", 0) >= 15 \
				and home.get_meta("plants", 0) >= 30 and home.get_meta("ac_units", 0) >= 10
		_expect(ok, "%s has framed windows, balconies with plants and AC units" % home.name,
				"frames %d balconies %d plants %d ac %d" % [home.get_meta("frames", 0), home.get_meta("balconies", 0),
				home.get_meta("plants", 0), home.get_meta("ac_units", 0)])
	var size: Vector3 = map.get("RESTAURANT_SIZE", Vector3(18, 8, 16))
	for room in rooms:
		var front := room.global_transform.basis.z.normalized()
		var front_face := room.global_position + front * size.z * 0.5
		var home := _home_over(homes, room.global_position)
		if home == null:
			_expect(false, "%s has homes above it" % room.name)
			continue
		var walls := home.get_node("Walls") as MeshInstance3D
		var box := walls.global_transform * walls.get_aabb()
		var x_inside := box.position.x <= room.global_position.x - size.x * 0.5 and box.end.x >= room.global_position.x + size.x * 0.5
		var plaza_face := box.end.z if front.z > 0.0 else box.position.z
		var flush := absf(plaza_face - front_face.z) < 0.15 and absf(box.position.y - size.y) < 0.01
		var look := home.get_node("HomesLook") as MeshInstance3D
		var band := look.global_transform * look.get_aabb()
		var band_reach := (band.end.z - front_face.z) if front.z > 0.0 else (front_face.z - band.position.z)
		_expect(x_inside and flush and band.position.y < size.y - 0.1 and band_reach > 0.25,
				"%s: the homes sit right on the shop front (no gap, nothing floating)" % room.name,
				"x inside %s, face %.2f vs %.2f, bottom %.2f, band reaches %.2f" % [x_inside, plaza_face, front_face.z, box.position.y, band_reach])


func _home_over(homes: Array[Node3D], spot: Vector3) -> Node3D:
	for home in homes:
		if absf(home.global_position.z - spot.z) < 1.0:
			return home
	return null


## Every bench outside a restaurant: you sit looking out, your back to the shop.
func _check_benches(rooms: Array[Node3D]) -> void:
	var benches := 0
	var wrong: Array[String] = []
	for room in rooms:
		var out := room.global_transform.basis.z.normalized()
		for child in room.get_children():
			if child is StaticBody3D and str(child.name).begins_with("OutsideBench"):
				benches += 1
				var looks := (child as Node3D).global_transform.basis.z.normalized()  # sitting looks along +Z
				var away := ((child as Node3D).global_position - room.global_position).dot(out) > 0.0
				if looks.dot(out) < 0.95 or not away:
					wrong.append("%s/%s" % [room.name, child.name])
	_expect(benches >= rooms.size() * 2 and wrong.is_empty(), "every bench outside a restaurant faces out, towards the Plaza",
			"%d benches, wrong: %s" % [benches, wrong])


## The pizza oven's flue starts inside the dome and goes up into the ceiling.
func _check_flue(rooms: Array[Node3D]) -> void:
	var pizza: Node3D = null
	for room in rooms:
		if room.get_meta("venue_type", "") == "pizza":
			pizza = room
	var flue := pizza.get_node_or_null("OvenFlue") as MeshInstance3D if pizza else null
	var dome := pizza.get_node_or_null("BrickOven") as MeshInstance3D if pizza else null
	_expect(flue != null and dome != null, "the pizza oven has a dome and a flue")
	if flue == null or dome == null:
		return
	var pipe := flue.mesh as CylinderMesh
	var ball := dome.mesh as SphereMesh
	var bottom := flue.position.y - pipe.height * 0.5
	var top := flue.position.y + pipe.height * 0.5
	var off := Vector2(flue.position.x - dome.position.x, flue.position.z - dome.position.z).length()
	# The low-poly dome's surface right under the flue (a cone from the top down to the
	# first ring of the sphere), so the flue really goes into it.
	var ring_r := ball.radius * sin(PI / ball.rings)
	var ring_y := ball.height * 0.5 * cos(PI / ball.rings)
	var surface := dome.position.y + lerpf(ball.height * 0.5, ring_y, clampf(off / ring_r, 0.0, 1.0))
	_expect(bottom < surface - 0.02 and off + pipe.bottom_radius < ball.radius and top >= RestaurantRoom.CEILING,
			"the pizza oven's flue goes from inside the dome up into the ceiling",
			"flue %.2f to %.2f, dome surface %.2f, ceiling %.2f" % [bottom, top, surface, RestaurantRoom.CEILING])


## Every restaurant has a waiter outside, and over 20 seconds each one changes what
## they're doing and moves about; nobody stands still for more than a moment.
func _check_waiters(rooms: Array[Node3D]) -> void:
	var waiters: Array[Node3D] = []  # RestaurantWaiter (not named here: it needs the autoloads)
	for node in world.find_children("Waiter_*", "Node3D", true, false):
		if "tasks_seen" in node:
			waiters.append(node)
	_expect(waiters.size() == rooms.size(), "a waiter outside every restaurant", "%d waiters, %d restaurants" % [waiters.size(), rooms.size()])
	if waiters.is_empty():
		return
	# Keep them all awake (PlaceCrowds only wakes people near the camera).
	waiters[0].get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	var start := {}
	var still := {}
	var longest_still := {}
	var travelled := {}
	for w in waiters:
		w.process_mode = Node.PROCESS_MODE_ALWAYS  # their parent is switched off above
		w.person.visible = true
		w.person.process_mode = Node.PROCESS_MODE_INHERIT
		w.tasks_seen.clear()
		start[w] = w.person.position
		still[w] = 0.0
		longest_still[w] = 0.0
		travelled[w] = 0.0
	var time := 0.0
	var last := {}
	for w in waiters:
		last[w] = w.person.position
	while time < 22.0:
		await process_frame
		var delta := root.get_process_delta_time()
		time += delta
		for w in waiters:
			var moved: float = (w.person.position - last[w]).length()
			travelled[w] += moved
			last[w] = w.person.position
			var busy: bool = w.task in ["wipe", "chat", "inside", "serve"]
			still[w] = 0.0 if (moved > 0.0001 or busy) else still[w] + delta
			longest_still[w] = maxf(longest_still[w], still[w])
	var all_tasks := {}
	for w in waiters:
		for task in w.tasks_seen:
			all_tasks[task] = true
		var kinds: Array = w.tasks_seen.keys()
		_expect(kinds.size() >= 2 and travelled[w] > 3.0 and longest_still[w] < GameConfig.WAITER_PAUSE_SECONDS + 0.4 and w.tables.size() >= 1,
				"%s keeps busy (changing what they do, never just standing)" % w.name,
				"did %s, walked %.1f m, longest stood still %.1f s, tables %d" % [kinds, travelled[w], longest_still[w], w.tables.size()])
	for task in ["walk", "wipe", "inside", "serve"]:
		_expect(all_tasks.has(task), "some waiter did '%s' in 20 s" % task, str(all_tasks.keys()))
	_expect(all_tasks.has("chat"), "some waiter chatted to a diner in 20 s", str(all_tasks.keys()))
