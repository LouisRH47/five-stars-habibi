extends SceneTree
## Session 61: the C Institute lobby, the stable office, the farm stall's farmer and the
## school's glass security booth. Builds Wahat Al Shams and checks each one.
## Run it:  Godot --path . --headless -s tests/venues_test.gd
var _failed := false
var _map: Dictionary
var _world: Node3D
var _state: Node


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)


func _run() -> void:
	var state := root.get_node("GameState")
	_state = state
	state.save_path = "user://venues_test.json"
	state.reset()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	_map = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	_world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 4:
		await process_frame
	await physics_frame
	_institute()
	_stable_office()
	await _farm_stall()
	_booths()
	SaveGame.delete(state.save_path)
	print("RESULT: ", "FAIL venues" if _failed else "PASS venues")
	quit(1 if _failed else 0)


func _count(holder: Node, prefix: String) -> int:
	return holder.find_children(prefix + "*", "", true, false).size()


func _institute() -> void:
	var lobby: Node3D = _world.get_node("PlaceBuilder/Institute")
	_check(lobby.get_meta("lobby", false) and lobby.get_meta("walk_in", false), "the C Institute is the new two-storey lobby")
	var front := _count(lobby, "FrontGlass")
	var back := _count(lobby, "BackGlass")
	_check(front >= 2 and back >= 2, "glass on both long sides (%d front panes, %d back)" % [front, back])
	_check(_count(lobby, "GlassRailing") == 1 and lobby.find_children("*", "MeshInstance3D", true, false).size() > 200,
			"a balcony with a glass railing, stairs and a wood-slat ceiling")
	_check(_count(lobby, "SteppedSeat") == 4, "four steps of wooden seats")
	var laptops := lobby.find_children("LaptopPerson*", "Person", true, false)
	_check(laptops.size() >= 4 and laptops.all(func(p: Person) -> bool: return p.action == "laptop"),
			"%d people on laptops on the steps" % laptops.size())
	var facing_screen := laptops.all(func(p: Person) -> bool: return (-p.global_transform.basis.z).dot(-lobby.global_transform.basis.x) > 0.9)
	_check(facing_screen, "the laptop people face the talk screen")
	var screen: Node = lobby.find_child("TalkScreen", true, false)
	var first: String = screen.english_text()
	screen._process(GameConfig.INSTITUTE_SCREEN_SECONDS + 0.1)
	var second: String = screen.english_text()
	_check(first != second and first in ["Talk today · 4 PM", "Solar cities of tomorrow", "Welcome"],
			"the talk screen changes during the shift (%s, then %s)" % [first, second])
	_check(_count(lobby, "ReceptionDesk") >= 5 and _count(lobby, "LogoWall") == 1 and _count(lobby, "LogoC") >= 10
			and lobby.get_node_or_null("CounterStaff") != null, "a curved white reception desk with the C logo wall and staff")
	var places: PlaceBuilder = _world.get_node("PlaceBuilder")
	var from := places.villa_approach(903) + Vector3.UP * 0.8
	var to := places.villa_door(903) + Vector3.UP * 0.8
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	_check(hit.is_empty() and from.distance_to(to) < 16.0, "reception is just inside the door (%.1f m walk, clear)" % from.distance_to(to))
	if GameConfig.INTERIOR_REVIEW_FIXES:
		# Overnight review: from the door you can read the name under the C (it was behind the desk).
		var name_face: Node3D = lobby.find_child("LogoName", true, false)
		var pieces := lobby.find_children("LogoC*", "", true, false).map(func(n): return (n as Node3D).position.y)
		var lowest_c: float = pieces.min() - 0.21
		var low_text := 0.0
		if name_face != null:
			low_text = name_face.position.y - 0.32   # the English line's bottom (font 56)
		var desk_top := 1.125
		var eye := Vector3(0, 1.7, 16.5)   # standing in the doorway (building directions)
		var desk_z: float = places.villas.filter(func(v): return v["number"] == 903)[0]["counter"].z - 1.2
		var hidden_below := eye.y - (eye.y - desk_top) * (eye.z - (name_face.position.z if name_face else 0.0)) / (eye.z - desk_z) if name_face else 9.0
		_check(name_face != null and low_text > hidden_below and name_face.position.y + 0.37 < lowest_c,
				"the institute's name shows over the desk from the door, under the C (bottom %.2f m, desk hides below %.2f m)" % [low_text, hidden_below])


func _stable_office() -> void:
	var office: Node3D = _world.get_node("LandmarkBuilder/StableOffice")
	_check(office.get_meta("open_room", false), "the stable office is a room you can look into")
	var groom: Person = office.find_child("OfficeGroom", true, false)
	_check(groom != null and groom.action == "sit", "the groom sits at his desk")
	_check(_count(office, "RidingHelmet") == 3 and _count(office, "OfficeWindow") >= 2 and _count(office, "WoodenDoor") == 1,
			"helmets on hooks, windows and a wooden door")
	if GameConfig.INTERIOR_REVIEW_FIXES:
		# Overnight review: real triangle gables under the roof, no sky showing through steps.
		var gables := office.find_children("Gable*", "MeshInstance3D", true, false)
		_check(gables.size() == 2 and gables.all(func(g): return (g as MeshInstance3D).mesh is PrismMesh),
				"the office's gable ends are full triangles (no gaps under the roof)")
	var paddock: Node = _world.get_node_or_null("LandmarkBuilder/OfficePaddock")
	_check(paddock != null and paddock.get_child_count() > 4, "a little paddock with a horse outside the office window")
	var place: Dictionary = {}
	for villa: Dictionary in _map["VILLAS"]:
		if villa["number"] == 902:
			place = villa
	var back_edge: float = place["position"].z + place["size"].z * 0.5
	var road_edge := 0.0
	for road: Dictionary in _map["ROADS"]:
		if road["name"] == "Stables Road":
			road_edge = road["from"].y - road["width"] * 0.5
	_check(back_edge <= road_edge, "the office no longer pokes into Stables Road (%.1f vs %.1f)" % [back_edge, road_edge])


func _farm_stall() -> void:
	var stall: Node3D = _world.get_node("PlaceBuilder/Restaurant_farm")
	var farmer := stall.get_node_or_null("CounterStaff") as Farmer
	_check(farmer != null and stall.get_meta("counter_handoff", false), "the farm stall has a farmer behind the counter")
	if farmer == null:
		return
	var at := Vector2(farmer.global_position.x, farmer.global_position.z)
	_check(at.distance_to(Vector2(4, 17)) < 3.0, "the farmer stands at the stall in its new spot (%.1f, %.1f)" % [at.x, at.y])
	var board: Node = stall.find_child("ChalkboardMenu", true, false)
	var text := ""
	var labels: Array = board.find_children("*", "Label3D", true, false) if board != null else []
	for label: Label3D in labels:
		text += label.text + " "
	_check(text.contains("Farm juice") and text.contains("Salad box") and text.contains("Dates") and text.contains("القائمة"),
			"the chalkboard menu lists Farm juice, Salad box and Dates")
	# A pickup at the stall: the farmer hands it over with the side panel, like a restaurant.
	var delivery: Node = _world.get_node("DeliveryManager")
	var counter: Node = _world.get_node("CounterPanel")
	var walker: Node3D = _world.get_node("Walker")
	_world.get_node("Bike").set_physics_process(false)
	walker.set_physics_process(false)
	delivery.set_physics_process(false)
	var order: Order = delivery.make_order("farm", 101)
	_state.offer_order(order)
	_state.accept_offer()
	delivery.actor = walker
	delivery.on_foot = true
	walker.global_position = delivery.target_door()
	await physics_frame
	await process_frame
	await process_frame
	_check(delivery.is_near_target() and counter._panel.visible and counter._staff == farmer,
			"at the stall the farmer hands you the order with the side panel")
	_state.reset()
	await process_frame


func _booths() -> void:
	var booth: Node3D = _world.get_node("LandmarkBuilder/SchoolBooth")
	_check(_count(booth, "BoothGlass") == 4 and booth.find_child("BoothGuard", true, false) != null,
			"the school booth is glass all round with the guard inside")
	_check(_world.get_node_or_null("LandmarkBuilder/SchoolBarrier") != null, "a barrier arm by the school gate")
	var school: Dictionary = _map["SCHOOL"]
	var gap: float = school["gate_width"] * 0.5 + 0.5
	var x := booth.global_position.x
	_check(absf(x - float(school["gate_x"])) > gap + 1.6, "the booth stands beside the gateway, not in it (x %.1f)" % x)
	var in_road: Array = []
	var spot := Rect2(Vector2(booth.global_position.x, booth.global_position.z) - Vector2(1.6, 1.6), Vector2(3.2, 3.2))
	for road: Dictionary in _map["ROADS"]:
		if ClusterSigns.road_rect(road, _map["ROAD_WIDTH"]).intersects(spot):
			in_road.append(road["name"])
	_check(in_road.is_empty(), "the booth is not in a road %s" % [in_road])
	var checkpoint: Node = _world.get_node("DistrictDetail/NorthCheckpoint")
	_check(_count(checkpoint, "GlassBooth") == 1, "the community gate checkpoints have the same glass booth")
