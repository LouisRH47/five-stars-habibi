extends SceneTree
## Looks pass Sessions 56 to 58: the gym, the C Institute lobby, the shops and small
## drop-off buildings, and the details outside (Plaza, streets, spine).
## Run: Godot --path . --headless -s tests/venue_looks_test.gd   (prints RESULT: PASS)
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
	state.save_path = "user://venue_looks_test.json"
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 6:
		await physics_frame
	world.get_node("EventManager").enabled = false
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	await _check_gym(places)
	_check_institute(places)
	await _check_receptions(places)
	world.queue_free()
	await process_frame
	SaveGame.delete(state.save_path)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " venue looks · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func _count(room: Node, prefix: String) -> int:
	var found := 0
	for child in room.get_children():
		if str(child.name).begins_with(prefix):
			found += 1
	return found


## Session 56: the gym is a real gym, and its people move.
func _check_gym(places: PlaceBuilder) -> void:
	var gym: Node3D = places.get_node("Gym")
	_expect(gym.get_meta("interior_style", "") == "gym" and gym.get_meta("rounded_back", false) and gym.is_in_group("venue_room"),
			"the gym is its own room with the rounded back")
	_expect(_count(gym, "Treadmill") == 4 and _count(gym, "ExerciseBike") >= 3 and _count(gym, "RowingMachine") == 2,
			"4 treadmills, exercise bikes and 2 rowing machines")
	for part in ["SquatRack", "Barbell", "LiftingPlatform", "DumbbellRack", "MirrorWall", "TrainHard", "RubberFloor",
			"WaterFountain", "TowelStand", "SmoothieCooler", "CounterStaff", "RoomSound", "InteriorLight"]:
		_expect(gym.get_node_or_null(part) != null, "the gym has " + part)
	_expect(_count(gym, "YogaMat") >= 3 and _count(gym, "Kettlebell") >= 4, "yoga mats and kettlebells")
	var words: Label3D = gym.get_node("TrainHard").get_child(1)
	_expect(words.text == "Train hard" and (gym.get_node("TrainHard").get_child(0) as Label3D).text == "تمرّن بقوة",
			"the mirror wall says Train hard · تمرّن بقوة")
	# Treadmills face the glass front (+Z), and someone runs on three of them.
	var runners := 0
	var dressed := true
	for person in gym.get_children():
		if person is Person and str(person.name) != "CounterStaff":
			dressed = dressed and person.get_meta("outfit", "") == "gym"
			if str(person.name).begins_with("Runner") and person.action == "jog" and is_equal_approx(absf(person.rotation.y), PI):
				runners += 1
	_expect(runners == 3, "three people run on treadmills facing the glass", str(runners))
	_expect(dressed, "everyone working out wears gym clothes")
	# Glass on the front and on the pool side (local -X).
	var pool_glass := false
	for view in gym.get_children():
		if view is MeshInstance3D and view.material_override == RoomProps.glass() and view.position.x < -17.5 and (view.mesh as BoxMesh).size.z > 15.0:
			pool_glass = true
	_expect(pool_glass, "the pool side of the gym is a glass wall")
	var lap: Rect2 = WahatAlShams.LAP_POOL
	var pool_side := gym.to_global(Vector3(-18, 0, 0))
	_expect(Vector2(pool_side.x, pool_side.z).distance_to(lap.get_center()) < Vector2(gym.global_position.x, gym.global_position.z).distance_to(lap.get_center()),
			"the glass side faces the lap pool")
	# People move when you're close.
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = gym.global_position + Vector3(0, 3, 0)
	camera.make_current()
	var rower: Person = gym.get_node("Rower0")
	var bar: Node3D = gym.get_node("Barbell")
	var rower_start := rower.position
	var bar_ys: Array[float] = []
	var rower_moved := false
	for i in 90:
		await process_frame
		bar_ys.append(bar.position.y)
		rower_moved = rower_moved or rower.position.distance_to(rower_start) > 0.1
	_expect(rower_moved, "the rower slides back and forth")
	_expect(bar_ys.max() - bar_ys.min() > 0.1, "the lifter squats with the barbell")
	camera.queue_free()


## Session 56: the C Institute lobby is two storeys tall with glass on both long sides.
func _check_institute(places: PlaceBuilder) -> void:
	var lobby: Node3D = places.get_node("Institute")
	_expect(lobby.get_meta("interior_style", "") == "institute_lobby" and lobby.get_meta("ceiling", 0.0) > 12.0,
			"the lobby is two storeys tall")
	for part in ["Balcony", "Staircase", "TalkScreen", "CurvedDesk", "CLogo", "WoodSlatCeiling", "StoneFloor", "CounterStaff", "RoomSound"]:
		_expect(lobby.get_node_or_null(part) != null, "the lobby has " + part)
	_expect(lobby.get_meta("laptop_people", 0) >= 6 and _count(lobby, "Laptop") >= 6, "people on laptops on the stepped seats", str(lobby.get_meta("laptop_people", 0)))
	_expect(_count(lobby, "SeatStep") == 4, "four wide wooden steps")
	_expect(lobby.get_meta("hanging_plants", 0) >= 8, "hanging plants")
	_expect(lobby.get_node("WoodSlatCeiling").get_child_count() >= 40, "a wood-slat ceiling")
	var tall := {}
	for view in lobby.get_children():
		if view is MeshInstance3D and view.material_override == RoomProps.glass():
			var size: Vector3 = (view.mesh as BoxMesh).size
			if size.x > 20.0 and view.position.y > 8.0:
				tall[signf(view.position.z)] = true
	_expect(tall.has(1.0) and tall.has(-1.0), "upper-storey glass on both long sides", str(tall.keys()))
	var facing: float = WahatAlShams.INSTITUTE["facing"]
	var front := lobby.global_basis.z
	_expect(is_equal_approx(facing, 90.0) and front.x > 0.99, "the glass front faces the spine (east)")
	var screen: TalkScreen = lobby.get_node("TalkScreen")
	_expect(TalkScreen.slide_for(9.0) == 0 and TalkScreen.slide_for(13.0) == 1 and TalkScreen.slide_for(16.5) == 2,
			"the talk screen has three slides through the shift")
	screen.show_hour(9.0)
	var early := screen.title.text + screen.arabic.text
	screen.show_hour(13.0)
	var noon := screen.title.text
	screen.show_hour(16.5)
	_expect(early == "Welcomeأهلاً" and noon == "Talk today · 4 PM" and screen.title.text == "Solar cities of tomorrow",
			"the talk screen changes during the shift")


## Both receptions are inside, with a clear straight walk from the door.
func _check_receptions(places: PlaceBuilder) -> void:
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	for number in [903, 904]:
		var room: Node3D = places.get_node("Institute" if number == 903 else "Gym")
		var door := places.villa_door(number)
		var from := places.villa_approach(number)
		_expect(RestaurantRoom.is_inside(room, door), "reception %d is inside the room" % number)
		var blocked := false
		for height in [0.4, 1.2]:
			var ray := PhysicsRayQueryParameters3D.create(from + Vector3.UP * height, door + Vector3.UP * height)
			var hit := space.intersect_ray(ray)
			if not hit.is_empty():
				blocked = true
				print("  hit ", hit["collider"].name, " at ", hit["position"])
		_expect(not blocked, "a clear walk from the door to reception %d" % number)
