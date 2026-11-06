extends SceneTree
## Session 91: the C Institute's second floor, its lift, and the big pond by the Institute.
##   - on foot you can walk up the stairs to the second floor (and you end up standing there)
##   - pressing E at the lift takes you down, and up again
##   - 6 people in the meeting room, people typing at office desks
##   - the pond has ducks, stones, reeds and a deck with two benches
##   - the pond, its deck and the Institute's new outside don't overlap the football pitch,
##     the roads, the paths (the spine's walking tracks, paved areas, the basketball court)
##     or the Institute steps, and nothing else stands in the pond
## Run: Godot --path . --headless --fixed-fps 60 -s tests/institute_upstairs_test.gd
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
	state.save_path = "user://institute_upstairs_test.json"
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
	var lobby: Node3D = world.get_node("PlaceBuilder/Institute")
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = lobby.to_global(Vector3(0, 9, 12))
	camera.make_current()
	_check_people(lobby)
	await _check_stairs(lobby)
	await _check_lift(lobby)
	_check_pond()
	_check_footprints(lobby)
	world.queue_free()
	await process_frame
	SaveGame.delete(state.save_path)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " institute upstairs · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


## The meeting room has 6 people; the offices have people sitting at desks with laptops.
func _check_people(lobby: Node3D) -> void:
	var meeting := 0
	var desk := 0
	var laptops := 0
	var floor2 := InstituteUpstairs.FLOOR2
	for child in lobby.get_children():
		if child is Person:
			var at: Vector3 = (child as Person).position
			if str(child.name).begins_with("MeetingPerson") and at.x < -12.5 and at.z < InstituteOffices.FRONT and at.y > floor2 - 1.0:
				meeting += 1
			if str(child.name).begins_with("DeskPerson") and at.y > floor2 - 1.0 and (child as Person).pose.mode == "pedal":
				desk += 1
		if str(child.name).begins_with("DeskLaptop") and (child as Node3D).position.y > floor2:
			laptops += 1
	_expect(meeting >= 6, "6 people in the meeting room", str(meeting))
	_expect(desk >= 4 and laptops >= desk, "people sit typing at office desks upstairs", "%d people, %d laptops" % [desk, laptops])
	_expect(lobby.get_node_or_null("MeetingRoom/MeetingScreen") != null, "the meeting room has a screen")
	_expect(lobby.get_node_or_null("TypingMotion") != null and (lobby.get_node("TypingMotion") as TypingMotion).people.size() >= desk,
			"the typists' hands move")
	_expect(lobby.get_node_or_null("TalkScreen") != null, "the talk screen is still downstairs")
	_expect(lobby.get_meta("upstairs_plants", 0) >= 8, "plants upstairs", str(lobby.get_meta("upstairs_plants", 0)))


## Walk the rider (on foot) from the lobby floor up the staircase.
func _check_stairs(lobby: Node3D) -> void:
	var bike: Node3D = world.get_node("Bike")
	bike.global_position = lobby.to_global(Vector3(8, 0.05, 12))  # parked in the lobby
	bike.set("speed", 0.0)
	for i in 5:
		await physics_frame
	_expect(world.get_node("OnFoot").get_off(), "get off the bike in the lobby")
	var walker = world.get_node("Walker")  # a Walker (not named here, like the other tests)
	walker.global_position = lobby.to_global(Vector3(InstituteUpstairs.STAIR_X, 0.1, InstituteUpstairs.STAIR_BOTTOM + 2.5))
	walker.global_rotation = Vector3(0, lobby.global_rotation.y, 0)  # facing up the stairs (-Z)
	for i in 10:
		await physics_frame
	var highest := -10.0
	Input.action_press("move_forward")
	for i in 60 * 16:
		await physics_frame
		highest = maxf(highest, lobby.to_local(walker.global_position).y)
		if lobby.to_local(walker.global_position).z < InstituteUpstairs.STAIR_TOP - 2.0:
			break
	Input.action_release("move_forward")
	for i in 30:
		await physics_frame
	var local := lobby.to_local(walker.global_position)
	_expect(highest > InstituteUpstairs.FLOOR2 - 0.2, "you can walk up the stairs to the second floor", "highest %.2f m" % highest)
	_expect(absf(local.y - InstituteUpstairs.FLOOR2) < 0.25 and walker.is_on_floor() and local.z < InstituteUpstairs.STAIR_TOP,
			"you stand on the upstairs landing", str(local))


## Press E at the lift upstairs: down you go. Then up again.
func _check_lift(lobby: Node3D) -> void:
	var lift: InstituteLift = lobby.get_node("Lift")
	var walker = world.get_node("Walker")  # a Walker (not named here, like the other tests)
	for trip in [[1, 0], [0, 1]]:
		walker.global_position = lift.call_spot(trip[0]) + Vector3(0, 0.05, 0)
		walker.velocity = Vector3.ZERO
		for i in 10:
			await physics_frame
		_expect(lift.door_near(walker) == trip[0], "standing at the lift door on floor %d" % trip[0])
		_expect(not paused, "the game isn't paused", _who_paused())
		await _press_e()
		var started := lift.busy
		var frames := 0
		while lift.busy and frames < 60 * 20:
			await process_frame
			frames += 1
		for i in 20:
			await physics_frame
		var local := lobby.to_local(walker.global_position)
		var floor_y := lift.floor_height(trip[1])
		_expect(started and not lift.busy and absf(local.y - floor_y) < 0.3 and lift.floor_now == trip[1],
				"E at the lift takes you %s" % ("down" if trip[1] == 0 else "up"), "y %.2f after %d frames" % [local.y, frames])
		_expect(walker.is_physics_processing() and lift.door_near(walker) == trip[1], "you step out of the lift and can walk again")
	world.get_node("OnFoot").get_on(true)


## The pond by the Institute: ducks, stones, reeds and a deck with two benches.
func _check_pond() -> void:
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var ponds: Array = map["STREAM"]["ponds"]
	var index := -1
	for i in ponds.size():
		if (ponds[i] as Dictionary).has("deck"):
			index = i
	_expect(index >= 0, "a pond with a deck in the data")
	if index < 0:
		return
	var pond: Dictionary = ponds[index]
	var holder := world.get_node("WahatBuilder/StreamPonds")
	var stones := holder.get_node_or_null("PondStones_%d" % index)
	var deck := holder.get_node_or_null("PondDeck_%d" % index)
	var ducks: Node3D = holder.get_node_or_null("PondDucks_%d" % index)  # PondDucks (not named: see _pond_edge)
	_expect(stones != null and stones.get_meta("stones", 0) >= 40 and stones.get_meta("reeds", 0) >= 30,
			"stones round the edge and reeds", "%d stones, %d reeds" % [stones.get_meta("stones", 0), stones.get_meta("reeds", 0)] if stones != null else "")
	_expect(deck != null and deck.get_node_or_null("DeckBench0") != null and deck.get_node_or_null("DeckBench1") != null,
			"a wooden deck with two benches")
	var centre: Vector2 = pond["centre"]
	var on_water := ducks != null and (ducks.get("ducks") as Array).size() >= 3
	if ducks != null:
		root.get_viewport().get_camera_3d().global_position = Vector3(centre.x, 5, centre.y + 12)  # ducks only move near the camera
		var before: Array = []
		for entry: Array in ducks.get("ducks"):
			before.append((entry[0] as Node3D).global_position)
		ducks.call("_process", 1.0)
		for k in (ducks.get("ducks") as Array).size():
			var duck := (ducks.get("ducks")[k][0]) as Node3D
			var p := Vector2(duck.global_position.x, duck.global_position.z)
			var a := (p - centre).angle()
			on_water = on_water and p.distance_to(centre) < _pond_edge(pond["radius"], a, index) - 0.4
			on_water = on_water and duck.global_position.distance_to(before[k]) > 0.05
	_expect(on_water, "ducks paddle about on the water", "%d ducks" % ((ducks.get("ducks") as Array).size() if ducks != null else 0))
	# The stream runs into the pond (its west end is inside the water).
	var stream: Dictionary = map["STREAM"]
	var end := Vector2(stream["from_x"], stream["z"] + sin(stream["from_x"] * 0.06) * 3.0)
	_expect(end.distance_to(centre) < pond["radius"] * 0.85, "the stream starts inside the pond", "%.1f m from the middle" % end.distance_to(centre))


## Footprints: nothing new sits on the pitch, roads, paths or the Institute steps.
func _check_footprints(lobby: Node3D) -> void:
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var stream: Dictionary = map["STREAM"]
	var pond: Dictionary = {}
	var index := 0
	for i in (stream["ponds"] as Array).size():
		if (stream["ponds"][i] as Dictionary).has("deck"):
			pond = stream["ponds"][i]
			index = i
	# Points all over the pond (out to its biggest stones) and its deck and stepping stones.
	var spots: Array[Vector2] = []
	var centre: Vector2 = pond["centre"]
	for k in 72:
		var a := TAU * k / 72.0
		for r in [0.0, 0.5, 1.0]:
			spots.append(centre + Vector2(cos(a), sin(a)) * (_pond_edge(pond["radius"], a, index) + 1.3) * r)
	var deck: Dictionary = pond["deck"]
	var deck_rect := Rect2(deck["centre"] - deck["size"] * 0.5, deck["size"]).grow_individual(0, 3.2, 0, 0)  # + stepping stones
	for i in 5:
		for j in 9:
			spots.append(deck_rect.position + deck_rect.size * Vector2(i / 4.0, j / 8.0))
	_expect(_clear(spots, map, true).is_empty(), "the pond and its deck don't overlap the pitch, roads, paths or steps", str(_clear(spots, map, true).slice(0, 3)))
	# The Institute's new outside: everything near the ground (fins, the end wall skin).
	var outside_spots: Array[Vector2] = []
	for view: MeshInstance3D in lobby.get_node("Outside").find_children("*", "MeshInstance3D", true, false):
		var box := view.global_transform * view.get_aabb()
		if box.position.y > 3.0:
			continue  # up on the roof or the sun shade: nothing on the ground to bump into
		for i in 3:
			for j in 3:
				outside_spots.append(Vector2(box.position.x, box.position.z) + Vector2(box.size.x, box.size.z) * Vector2(i / 2.0, j / 2.0))
	_expect(outside_spots.size() > 10 and _clear(outside_spots, map, false).is_empty(),
			"the Institute's fins don't overlap the pitch, roads, paths or steps", str(_clear(outside_spots, map, false).slice(0, 3)))
	# Nothing else (lamps, trees, bins, people...) stands in the pond.
	var r := (pond["radius"] as float) * 1.15
	var inside: Array = []
	for node: Node in world.find_children("*", "Node3D", true, false):
		var thing := node as Node3D
		if thing == null or str(thing.get_path()).contains("StreamPonds") or str(thing.get_path()).contains("_StaticBatches"):
			continue
		var p := Vector2(thing.global_position.x, thing.global_position.z)
		if p.distance_to(centre) > r or thing.global_position.y > 3.0:
			continue
		if thing is MeshInstance3D and (thing as MeshInstance3D).mesh != null:
			var box := (thing as MeshInstance3D).global_transform * (thing as MeshInstance3D).get_aabb()
			if maxf(box.size.x, box.size.z) > 30.0:
				continue  # the ground, roads and big lawns run under everything
		if thing is MeshInstance3D or thing is StaticBody3D or thing is CollisionShape3D:
			if not str(thing.get_path()).contains("/Stream/") and thing.name != "Stream":
				inside.append(str(thing.get_path()).replace("/root/WahatAlShams/", ""))
	_expect(inside.is_empty(), "nothing else stands in the pond", str(inside.slice(0, 5)))


## The spots in `spots` (x, z) that sit on the pitch, a road, a path or the Institute steps.
func _clear(spots: Array[Vector2], map: Dictionary, check_institute: bool) -> Array:
	var bad: Array = []
	var pitch: Rect2 = map["INSTITUTE_PITCH"]["area"]
	var tracks: Dictionary = map["SPINE_TRACKS"]
	var band: float = tracks["road_half"] + tracks["planter"] + tracks["track"]
	var areas: Array = [pitch.grow(0.5), (map["BASKETBALL_COURT"] as Rect2).grow(0.5)]
	areas.append_array(map["PAVED_AREAS"])
	var institute: Dictionary = map["INSTITUTE"]
	var size: Vector3 = institute["size"]
	var at: Vector3 = institute["position"]
	# The steps are in front (east) of the building: x from the glass out 7 m, z the building's width.
	var steps := Rect2(at.x + size.z * 0.5, at.z - size.x * 0.5, 7.0, size.x)
	areas.append(steps)
	if check_institute:
		areas.append(Rect2(at.x - size.z * 0.5, at.z - size.x * 0.5, size.z, size.x).grow(1.5))
	for p: Vector2 in spots:
		for area: Rect2 in areas:
			if area.has_point(p):
				bad.append([p, area])
		if p.x > tracks["from_x"] and p.x < tracks["to_x"] and absf(p.y) < band + 0.3:
			bad.append([p, "spine road or its walking tracks"])
		for road: Dictionary in map["ROADS"]:
			var gap := Geometry2D.get_closest_point_to_segment(p, road["from"], road["to"]).distance_to(p)
			if gap < float(road["width"]) * 0.5 + 0.5:
				bad.append([p, road["name"]])
	return bad


## StreamPond.edge(), loaded by path: naming StreamPond in a test script makes Godot compile
## the ducks and life scripts before GameState exists, which breaks the walker in tests.
func _pond_edge(radius: float, angle: float, seed: int) -> float:
	return load("res://scripts/stream_pond.gd").edge(radius, angle, seed)


## Presses and lets go of E (like the other tests: the game reads the key each frame).
func _press_e() -> void:
	Input.action_press("interact")
	await process_frame
	await process_frame
	Input.action_release("interact")


## Which screen paused the game (for the message when something went wrong).
func _who_paused() -> String:
	for path in ["ClinicScreen", "DeliveredCard", "ShiftScreen", "PauseMenu", "PhoneApp"]:
		var screen := world.get_node_or_null(path)
		if screen != null and (screen.get("showing") == true or (screen is CanvasItem and screen.visible)):
			return path
	return ""
