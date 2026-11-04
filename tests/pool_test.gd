extends SceneTree
## Session 60: the gym and the pools. Builds Wahat Al Shams and checks:
##   - the gym is smaller and real (machines, weights, mirror, reception), with its glass wall
##     right on the lap pool, which sits in front of it
##   - both pools have a fence that's closed all round except ONE gate you can walk through
##   - swimmers really swim: they stay in their lanes, move at least 5 m in 20 s, turn at the
##     walls, and lie face down (not on their side) while swimming
##   - the community pool has its kids' pool, loungers, umbrellas, lifeguard and so on
##   - no hill within 4 m of the pools or the gym, and no grass inside them
## Run it:  Godot --path . --headless -s tests/pool_test.gd
var _failed := false
var _map: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	_map = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 4:
		await process_frame
	await physics_frame
	await physics_frame
	var detail: Node = world.get_node("DistrictDetail")
	var lap: Pool = detail.get_node_or_null("LapPool") as Pool
	var community: Pool = detail.get_node_or_null("CommunityPool") as Pool
	_check(lap != null and community != null, "both pools are real fenced pools (scripts/pool.gd)")
	if lap == null or community == null:
		_finish()
		return
	_check_gym(world, lap)
	for pool in [lap, community]:
		_check_fence(world, pool)
	_check_community(community)
	_check_swimmers(lap, 3, 4)
	_check_swimmers(community, 4, 4)
	_check_hills_and_grass(world)
	_finish()


func _finish() -> void:
	print("RESULT: ", "FAIL pool" if _failed else "PASS pool")
	quit(1 if _failed else 0)


## The gym: smaller, real inside, and the lap pool right in front of its glass wall.
func _check_gym(world: Node3D, lap: Pool) -> void:
	var gym: Node3D = world.get_node("PlaceBuilder/Gym")
	var info: Dictionary = _map["GYM"]
	var size: Vector3 = info["size"]
	_check(size.x <= 24.5 and size.z <= 14.5 and size.y <= 6.5 and gym.get_meta("real_gym", false),
			"the gym is smaller (%s m, was 36 x 8 x 22) and built as a real gym" % size)
	var counts := {}
	for node in gym.find_children("*", "", true, false):
		var key := String(node.name).rstrip("0123456789")
		counts[key] = int(counts.get(key, 0)) + 1
	var wanted := {"Treadmill": 4, "ExerciseBike": 3, "Rower": 2, "MirrorWall": 1, "TrainHard": 1, "DumbbellRack": 1,
			"WeightBench": 2, "SmoothieCooler": 1, "WaterFountain": 1, "TowelStand": 1, "CounterStaff": 1}
	var missing: Array = []
	for key in wanted:
		if int(counts.get(key, 0)) < wanted[key]:
			missing.append("%s (%d of %d)" % [key, counts.get(key, 0), wanted[key]])
	_check(missing.is_empty(), "the gym has its machines, weights, mirror, reception and smoothie cooler %s" % [missing])
	var moves := {}
	for person: Person in gym.find_children("*", "Person", true, false):
		moves[person.action] = true
	_check(["jog", "pedal", "row", "squat", "stretch"].all(func(a): return moves.has(a)),
			"people run, cycle, row, squat and stretch in the gym %s" % [moves.keys()])
	# The pool is in front of the glass: its north edge is the gym's glass wall.
	var glass: Node3D = gym.find_child("PoolGlass", true, false)
	var pool_edge: float = lap.area.position.y
	var footprint := _footprint(info["position"], size, info["facing"])
	_check(glass != null and absf(glass.global_position.z - pool_edge) < 0.2
			and lap.area.position.x <= footprint.position.x and lap.area.end.x >= footprint.end.x,
			"the lap pool sits right in front of the gym's glass wall (glass z %.1f, pool edge %.1f)" % [glass.global_position.z if glass else 0.0, pool_edge])
	_check(lap.water.size == Vector2(25, 7) and lap.find_children("LaneRope*", "", true, false).size() > 100,
			"the lap pool is 25 m long with lane ropes (%s)" % lap.water.size)
	# You can walk straight from the bike spot in through the door to the reception desk.
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	var from := places.villa_approach(904) + Vector3.UP * 0.8
	var to := places.villa_door(904) + Vector3.UP * 0.8
	var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	_check(hit.is_empty() and footprint.has_point(Vector2(to.x, to.z)),
			"the walk from the bike to the gym reception is clear and ends inside the gym %s" % [hit.get("collider")])


## Walks round the fence line: every spot is blocked except the one gate, which is open.
func _check_fence(world: Node3D, pool: Pool) -> void:
	var space := world.get_world_3d().direct_space_state
	var area := pool.area
	var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	var gaps: Array[Vector2] = []
	var checked := 0
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var way := (b - a).normalized()
		var out := Vector2(way.y, -way.x)   # sides go clockwise on screen, so this points outwards
		if (a + out - area.get_center()).length() < (a - area.get_center()).length():
			out = -out
		var t := 0.4
		while t < a.distance_to(b) - 0.3:
			var p := a + way * t
			var open := true
			for y in [0.4, 0.9]:
				var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x + out.x * 0.6, y, p.y + out.y * 0.6),
						Vector3(p.x - out.x * 0.6, y, p.y - out.y * 0.6))
				open = open and space.intersect_ray(ray).is_empty()
			if open:
				gaps.append(p)
			checked += 1
			t += 0.25
	var stray: Array = []
	for p in gaps:
		if p.distance_to(pool.gate) > pool.gate_width * 0.5 + 0.15:
			stray.append("(%.1f, %.1f)" % [p.x, p.y])
	_check(checked > 100 and stray.is_empty() and not gaps.is_empty(),
			"%s: the fence is closed all round (%d spots) except the gate %s" % [pool.name, checked, stray.slice(0, 6)])
	_check(pool.gate_width >= 0.95 and pool.gate_width <= 1.2,
			"%s: the gate is a small one (%.1f m)" % [pool.name, pool.gate_width])
	# The gate is walkable: three lines through it (left, middle, right) at knee and chest height.
	var inward := 1.0 if pool.gate.y < area.get_center().y else -1.0
	var clear := true
	for x in [-0.3, 0.0, 0.3]:
		for y in [0.3, 1.1]:
			var ray := PhysicsRayQueryParameters3D.create(Vector3(pool.gate.x + x, y, pool.gate.y - inward * 1.5),
					Vector3(pool.gate.x + x, y, pool.gate.y + inward * 1.5))
			clear = clear and space.intersect_ray(ray).is_empty()
	_check(clear, "%s: you can walk in through the gate" % pool.name)
	var fence_height: float = (_map["LAP_POOL_DETAIL"] if pool.name == "LapPool" else _map["COMMUNITY_POOL_DETAIL"])["fence_height"]
	_check(is_equal_approx(fence_height, 1.2 if pool.name == "LapPool" else 1.4),
			"%s: the fence is %.1f m high" % [pool.name, fence_height])


func _check_community(pool: Pool) -> void:
	var counts := {}
	for node in pool.find_children("*", "", true, false):
		var key := String(node.name).rstrip("0123456789")
		counts[key] = int(counts.get(key, 0)) + 1
	var wanted := {"KidsWater": 1, "Lounger": 10, "Umbrella": 4, "ShadeSail": 2, "LifeguardChair": 1, "Lifeguard": 1,
			"OutdoorShower": 1, "ChangingHut": 1, "PoolRulesSign": 1, "PalmPlanter": 2, "Sunbather": 5}
	var missing: Array = []
	for key in wanted:
		if int(counts.get(key, 0)) != wanted[key]:
			missing.append("%s (%d, want %d)" % [key, counts.get(key, 0), wanted[key]])
	_check(missing.is_empty(), "the community pool has its kids' pool, 10 loungers, 4 umbrellas, sails, lifeguard, shower, hut and sign %s" % [missing])
	var detail: Dictionary = _map["COMMUNITY_POOL_DETAIL"]
	var water: Rect2 = detail["water"]
	var kids: Rect2 = detail["kids"]
	_check(water.size == Vector2(25, 12) and kids.size == Vector2(8, 6) and pool.area.encloses(water) and pool.area.encloses(kids)
			and not water.intersects(kids), "main pool 25 x 12 m and kids' pool 8 x 6 m, both inside the fence")
	var sign: Node = pool.find_child("PoolRulesSign*", true, false)
	var arabic := false
	for label: Label3D in sign.find_children("*", "Label3D", true, false):
		arabic = arabic or label.text.contains("قواعد")
	_check(arabic, "the pool rules sign is in Arabic and English")
	# Nothing stands in the water (posts, chairs, loungers, the hut).
	var wet: Array = []
	for body: StaticBody3D in pool.find_children("*", "StaticBody3D", true, false):
		if body.name == "PoolFence":
			continue
		var spot := Vector2(body.global_position.x, body.global_position.z)
		if water.grow(0.2).has_point(spot) or kids.grow(0.2).has_point(spot):
			wet.append(String(body.name))
	_check(wet.is_empty(), "nothing on the deck stands in the water %s" % [wet])
	# The roads and paths stay outside the pool's fence.
	var crossed: Array = []
	for road: Dictionary in _map["ROADS"]:
		if ClusterSigns.road_rect(road, _map["ROAD_WIDTH"]).intersects(pool.area.grow(-0.05)):
			crossed.append(road["name"])
	_check(crossed.is_empty(), "no road or path runs through the community pool %s" % [crossed])


## Steps every swimmer 60 seconds and watches them.
func _check_swimmers(pool: Pool, lap_count: int, lanes: int) -> void:
	var laps: Array[Swimmer] = []
	for swimmer in pool.swimmers:
		if swimmer.kind == "lap":
			laps.append(swimmer)
	_check(laps.size() == lap_count, "%s: %d swimmers doing lengths" % [pool.name, laps.size()])
	var lane_width := pool.water.size.y / float(lanes)
	var start_z := {}
	var turns := {}
	var after_20 := {}
	var out_of_lane: Array = []
	var sideways: Array = []
	var last_state := {}
	for swimmer in laps:
		start_z[swimmer] = swimmer.position.z
		turns[swimmer] = 0
		last_state[swimmer] = swimmer.state
	var step := 1.0 / 30.0
	for frame in 60 * 30:
		for swimmer in pool.swimmers:
			swimmer.step(step)
		for swimmer in laps:
			if absf(swimmer.position.z - start_z[swimmer]) > lane_width * 0.5 - 0.2 or not pool.water.has_point(Vector2(swimmer.position.x, swimmer.position.z)):
				out_of_lane.append(swimmer.name)
			if swimmer.state == "turn" and last_state[swimmer] != "turn":
				turns[swimmer] += 1
			last_state[swimmer] = swimmer.state
			if swimmer.state == "swim" and frame % 30 == 0:
				var body := swimmer.person.global_transform.basis
				if body.z.normalized().y < 0.9 or absf(body.x.normalized().y) > 0.2:
					sideways.append(swimmer.name)
		if frame == 20 * 30:
			for swimmer in laps:
				after_20[swimmer] = swimmer.travelled
	var slow: Array = []
	var no_turn: Array = []
	for swimmer in laps:
		if after_20.get(swimmer, 0.0) < 5.0:
			slow.append("%.1f m" % after_20.get(swimmer, 0.0))
		if turns[swimmer] < 1:
			no_turn.append(swimmer.name)
	_check(slow.is_empty(), "%s: every swimmer moves at least 5 m in 20 s %s" % [pool.name, slow])
	_check(out_of_lane.is_empty(), "%s: swimmers stay in their own lane and in the water (60 s)" % pool.name)
	_check(no_turn.is_empty(), "%s: every swimmer turns round at the wall" % pool.name)
	_check(sideways.is_empty(), "%s: swimmers swim face down, nobody lies on their side" % pool.name)
	var strokes := laps.all(func(s: Swimmer) -> bool: return s.person.action in ["swim", "idle"])
	_check(strokes, "%s: swimmers do the crawl (or rest at the wall)" % pool.name)
	var others := pool.swimmers.filter(func(s: Swimmer) -> bool: return s.kind != "lap")
	var still: Array = others.filter(func(s: Swimmer) -> bool: return s.travelled < 0.3 and s.kind == "deck")
	if pool.name == "CommunityPool":
		var kids := others.filter(func(s: Swimmer) -> bool: return s.kind == "kid")
		var walkers := others.filter(func(s: Swimmer) -> bool: return s.kind == "deck")
		var kids_area: Rect2 = _map["COMMUNITY_POOL_DETAIL"]["kids"]
		var kids_in := kids.all(func(s: Swimmer) -> bool: return kids_area.has_point(Vector2(s.position.x, s.position.z)) and s.person.action == "splash")
		_check(kids.size() == 3 and kids_in, "3 kids splash in the kids' pool")
		_check(walkers.size() == 2 and still.is_empty(), "2 people stroll round the deck")


## No hill near the pools or the gym, and no grass blades inside them.
func _check_hills_and_grass(world: Node3D) -> void:
	var gym: Dictionary = _map["GYM"]
	var keep := {"lap pool": _map["LAP_POOL"], "community pool": _map["COMMUNITY_POOL"],
			"gym": _footprint(gym["position"], gym["size"], gym["facing"])}
	var near: Array = []
	for hill: Dictionary in _map["HILLS"]:
		var c := Vector2(hill["position"].x, hill["position"].z)
		for name in keep:
			var rect: Rect2 = keep[name]
			var closest := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
			if closest.distance_to(c) < float(hill.get("radius", GameConfig.HILL_RADIUS)) + GameConfig.HILL_CLEARANCE:   # Session 63: hills have their own size
				near.append("hill (%d, %d) and %s" % [c.x, c.y, name])
	_check(near.is_empty(), "no hill within 4 m of the pools or the gym %s" % [near])
	var field: GrassField = world.get_node("DistrictDetail").get_node_or_null("GrassField")
	if field == null:
		for i in 8:
			await process_frame
		field = world.get_node("DistrictDetail").get_node_or_null("GrassField")
	if field == null:
		_check(not GameConfig.GRASS_BLADES_ON, "grass blades are off, nothing to check")
		return
	var bad := 0
	var checked := 0
	for name in keep:
		var rect: Rect2 = keep[name]
		field.fill_around(Vector3(rect.get_center().x, 0, rect.get_center().y), -1)
		for key: Vector2i in field.chunk_keys():
			var corner := Vector3(key.x, 0, key.y) * GameConfig.GRASS_CHUNK
			for place: Transform3D in field.make_spots(key):
				var at: Vector3 = corner + place.origin
				checked += 1
				for other in keep:
					if (keep[other] as Rect2).grow(-0.1).has_point(Vector2(at.x, at.z)):
						bad += 1
	_check(checked > 500 and bad == 0, "no grass inside the pools or the gym (%d blades checked, %d inside)" % [checked, bad])


static func _footprint(at: Vector3, size: Vector3, facing: float) -> Rect2:
	var turned := absf(sin(deg_to_rad(facing))) > 0.5
	var w := size.z if turned else size.x
	var d := size.x if turned else size.z
	return Rect2(at.x - w * 0.5, at.z - d * 0.5, w, d)
