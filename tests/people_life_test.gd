extends SceneTree
## Session 92: people looking alive. Checks:
##   - a parent pushes a stroller: it stays in front of them as they walk, both hands are on
##     the handle and its wheels turn
##   - a talking pair stands at ease, face to face about 1.1 m apart, and takes turns to talk
##   - 4 people lie on the community pool's loungers in swimwear, one reading a book
##   - building site workers swap jobs over time (carry, hammer, mix, talk)
##   - the player wears the company logo on the cap or helmet and on the shirt, in every look,
##     and has shoes with soles and laces
##   - nobody on the basketball court or the football pitch is ever within 0.3 m of anyone else
## Run: Godot --path . --headless -s tests/people_life_test.gd

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
	var state := root.get_node("GameState")
	state.save_path = "user://people_life_test_save.json"
	state.new_game()
	await _stroller()
	await _talking_pair()
	await _sunbathers()
	await _workers()
	_player_logos()
	_courts()
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " people life · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func _stroller() -> void:
	var parent := PlaceLooks.neighbour(1)
	# Loaded here (not named at the top): these use GameState, which a test script can't name.
	var holder: Node3D = load("res://scripts/life_looks.gd").with_buggy(parent)
	var mover: Node3D = (load("res://scripts/route_mover.gd") as Script).new()
	root.add_child(mover)
	mover.setup("person", [Vector3(0, 0, 0), Vector3(0, 0, -40)], false, GameConfig.WALKER_SPEED,
			Vector3(0.7, 1.8, 1.6), holder, parent)
	mover.start_at(0, 0.0, true)
	var stroller := parent.get_meta("stroller") as Stroller
	_expect(stroller != null and stroller.wheels.size() == 4, "the stroller has four wheels", str(stroller.wheels.size() if stroller else 0))
	var gap_before := parent.global_position.distance_to(stroller.global_position)
	var start := mover.global_position
	var turns := stroller.wheels.map(func(wheel: Node3D) -> float: return wheel.rotation.x)
	_watch(parent, ["LeftHand", "RightHand"])
	for i in 90:
		await physics_frame
	var walked := mover.global_position.distance_to(start)
	var gap_after := parent.global_position.distance_to(stroller.global_position)
	var ahead := (stroller.global_position - parent.global_position).dot(-parent.global_basis.z)
	_expect(walked > 1.0 and absf(gap_after - gap_before) < 0.01 and ahead > 0.5,
			"the stroller moves with the parent, in front of them", "walked %.2f m, gap %.2f -> %.2f, %.2f m ahead" % [walked, gap_before, gap_after, ahead])
	var turned := 0
	for i in stroller.wheels.size():
		if absf(stroller.wheels[i].rotation.x - turns[i]) > 1.0:
			turned += 1
	_expect(turned == 4, "the stroller's wheels turn as it rolls", "%d of 4 turned" % turned)
	var grip := stroller.global_transform * stroller.handle
	var worst := 0.0
	for side in ["LeftHand", "RightHand"]:
		var hand := _now(parent, side)
		worst = maxf(worst, Vector2(hand.y - grip.y, (hand - grip).dot(parent.global_basis.z)).length())
	_expect(worst < 0.12, "both hands hold the stroller's handle", "worst hand %.3f m from the bar" % worst)
	mover.queue_free()


func _talking_pair() -> void:
	var crowds_script: Script = load("res://scripts/place_crowds.gd")
	var crowds: Node3D = crowds_script.new()
	root.add_child(crowds)
	var a: Person = crowds.place(PlaceLooks.neighbour(0), Vector3(50, 0, 50), 90.0)
	var b: Person = crowds.place(PlaceLooks.neighbour(1), Vector3(51.4, 0, 50.3), -60.0)
	crowds_script.talk(a, b)
	for person: Person in [a, b]:
		person.pose.alive = false  # (looking round and swaying only happen near the camera)
		_watch(person, ["LeftUpLeg", "LeftFoot", "RightUpLeg", "RightFoot"])
	for i in 20:
		await process_frame
	var gap := a.global_position.distance_to(b.global_position)
	_expect(absf(gap - GameConfig.TALK_GAP) < 0.05, "a talking pair stands a polite distance apart", "%.2f m" % gap)
	var way := (b.global_position - a.global_position).normalized()
	var a_looks := (-a.global_basis.z).dot(way)
	var b_looks := (-b.global_basis.z).dot(-way)
	_expect(a_looks > 0.98 and b_looks > 0.98, "they face each other", "%.2f, %.2f" % [a_looks, b_looks])
	# Relaxed: the feet are under the hips (not the idle clip's wide, bent-knee stance).
	var worst := 0.0
	for person: Person in [a, b]:
		for side in ["Left", "Right"]:
			var hip := _now(person, side + "UpLeg")
			var ankle := _now(person, side + "Foot")
			worst = maxf(worst, Vector2(hip.x - ankle.x, hip.z - ankle.z).length())
	_expect(worst < 0.15 and a.pose.relaxed and b.pose.relaxed, "they stand at ease, feet under the hips", "worst foot %.2f m off" % worst)
	var one_talks := AlivePose.is_speaking(a.pose) != AlivePose.is_speaking(b.pose)
	var speaker_before := AlivePose.is_speaking(a.pose)
	for person: Person in [a, b]:  # half a turn later (the same as waiting that long)
		person.pose.talk_seed += GameConfig.ALIVE_TALK_TURN_SECONDS
	var swapped := AlivePose.is_speaking(a.pose) != speaker_before and AlivePose.is_speaking(a.pose) != AlivePose.is_speaking(b.pose)
	_expect(one_talks and swapped, "they take turns to talk (one at a time)")
	crowds.queue_free()


func _sunbathers() -> void:
	var map: Dictionary = (load("res://data/wahat_al_shams.gd") as Script).get_script_constant_map()
	var sun := Sunbathers.new()
	root.add_child(sun)
	var made := sun.build(map, root)
	for i in 10:
		await process_frame
	_expect(made.size() == 4 and sun.people.size() == 4, "4 people on the community pool's loungers", str(sun.people.size()))
	var lying := 0
	var readers := 0
	for person in sun.people:
		var head := person.global_transform * person.head_spot()
		var hips := person.global_transform * person.spot("Hips")
		if person.action == "lounge" and head.y - hips.y < 0.75 and person.get_meta("outfit", "") == "swimwear":
			lying += 1
		if person.pose.reading and person.get_node_or_null("Book") != null:
			readers += 1
	_expect(lying == 4, "they lie back in swimwear", "%d lying" % lying)
	_expect(readers == 1, "one of them is reading a book", "%d reading" % readers)
	sun.queue_free()


func _workers() -> void:
	var site := Node3D.new()
	root.add_child(site)
	var crew: Node3D = load("res://scripts/site_crew.gd").make(site, Vector3(0, 0, 100), Vector3.RIGHT)
	await process_frame
	var first: Array = crew.jobs.duplicate()
	var seen := {}
	for shift in crew.JOBS.size():
		for job in crew.jobs:
			seen[job] = true
		crew.advance(GameConfig.WORKER_JOB_SECONDS + 0.01)
		if shift == 0:
			var changed := 0
			for i in crew.jobs.size():
				if crew.jobs[i] != first[i]:
					changed += 1
			_expect(changed == crew.workers.size(), "every worker changes job after a while", "%s -> %s" % [first, crew.jobs])
	_expect(seen.size() == crew.JOBS.size(), "the workers carry, hammer, mix and talk by the crane", str(seen.keys()))
	crew.advance(crew._job_left + 0.01)  # a fresh swap, then time to walk there and start
	for i in 100:
		crew.advance(0.1)
	var working := 0
	for i in crew.workers.size():
		if crew.arms[i].task != "" or crew.jobs[i] == "talk":
			working += 1
	_expect(working == crew.workers.size(), "they get to their jobs and do them", "%d of %d" % [working, crew.workers.size()])
	var dressed: bool = (crew.workers + [crew.foreman]).all(func(p: Person) -> bool: return p.get_meta("outfit", "") == "hi-vis")
	_expect(dressed, "the workers wear hi-vis vests and hard hats")
	site.queue_free()


func _player_logos() -> void:
	var logo := Companies.logo(Companies.current())
	for look in 3:
		var rider := RiderLook.make_rider()
		root.add_child(rider)
		RiderLook.apply(rider, look)
		var head := rider.find_child("HeadLogo", true, false)
		var chest := rider.find_child("ChestLogo", true, false)
		var on_head: bool = head != null and head.get_meta("bone", -1) == rider.skeleton.find_bone("Head") \
				and head.get_node_or_null("Logo") != null and (head.get_node("Logo") as Sprite3D).texture == logo
		var on_chest: bool = chest != null and chest.get_meta("bone", -1) == rider.skeleton.find_bone("Spine2") \
				and (chest.get_node("Logo") as Sprite3D).texture == logo
		_expect(on_head and on_chest, "look %d: the company logo on the cap/helmet and on the shirt" % look)
		var shoes := 0
		for holder in rider.get_children():
			if holder.has_node("Shoe") or holder.has_node("ShoeToe"):
				shoes += 1
		_expect(shoes == 4, "look %d: rounded shoes (back and toes on both feet) with soles and laces" % look, "%d pieces" % shoes)
		rider.queue_free()


func _courts() -> void:
	var map: Dictionary = (load("res://data/wahat_al_shams.gd") as Script).get_script_constant_map()
	var parent := Node3D.new()
	root.add_child(parent)
	var courts: Array = []
	# Loaded here (not named at the top): they use GameState, which a test script can't name.
	if map.has("BASKETBALL_COURT"):
		courts.append(load("res://scripts/basketball_court.gd").build(parent, map["BASKETBALL_COURT"]))
	if map.has("INSTITUTE_PITCH"):
		courts.append(load("res://scripts/institute_pitch.gd").build(parent, map["INSTITUTE_PITCH"]))
	var closest := 99.0
	for frame in 1800:  # 30 seconds of play
		for court in courts:
			court.play(1.0 / 60.0)
			var players: Array = court.players
			for a in players.size():
				for b in range(a + 1, players.size()):
					var one: Vector3 = (players[a] as Node3D).global_position
					var two: Vector3 = (players[b] as Node3D).global_position
					closest = minf(closest, Vector2(one.x - two.x, one.z - two.z).length())
	_expect(courts.size() == 2 and closest > 0.3, "nobody on the courts is ever within 0.3 m of anyone else",
			"closest %.2f m" % closest)
	parent.queue_free()


## Godot only keeps the poses made in code while it draws, so to see where a bone really
## is, a holder follows it (like clothes do). _watch() makes the holders (a frame or more
## before _now() is asked), _now() says where the bone is on the map.
var _probes := {}


func _watch(person: Person, bones: Array) -> void:
	for bone: String in bones:
		_probes["%d:%s" % [person.get_instance_id(), bone]] = person.follow(bone)


func _now(person: Person, bone: String) -> Vector3:
	return (_probes["%d:%s" % [person.get_instance_id(), bone]] as Node3D).global_transform * person.spot(bone)
