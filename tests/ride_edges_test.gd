extends SceneTree
## Session 75: no invisible walls. Walks the bike's shape along and across every road edge,
## the red walking tracks, the blue track and the car park edges, and lists anything solid
## it bumps into. Each thing it bumps must be something you can see (a lamp, a tree, a house
## wall...): an invisible one is a failure. Then it really rides the bike over kerbs (the
## spine planter and red track, the roundabout island, a cluster entrance island): a small
## bump and a little speed lost, never a crash and never stopped.
## Run: godot --path . --headless --fixed-fps 60 -s tests/ride_edges_test.gd

const STEP := 2.0             # metres between probes along each edge
const ACROSS := [-1.0, 0.6, 2.0, 3.5]  # probes this far out from a road edge (- = on the road)
const PROBE := Vector3(0.6, 1.5, 1.7)  # the bike's box (a little shorter, clear of the ground)
## Solid things that count as seen: the walls inside the tree belt round the map (meant to be
## invisible), and the edge palms, trees and hedges (drawn as MultiMeshes, which a headless
## run can't look inside; EdgeBuilder puts a plant on every one).
const ALLOWED := ["EdgeWalls", "EdgeGreenerySolid"]

var failures: Array[String] = []
var checks := 0
var world: Node3D
var _space: PhysicsDirectSpaceState3D
var _query := PhysicsShapeQueryParameters3D.new()
var _hits := {}      # CollisionShape3D -> a spot where the bike's shape touched it
var _probes := 0
var _visuals: Array = []
var _faces := {}


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = OS.get_cache_dir().path_join("ride_edges_test.json")
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	for frame in 8:
		await physics_frame
	for frame in 20:
		if world.get_node("DistrictDetail").has_meta("static_batch_report"):
			break
		await process_frame
	world.get_node("EventManager").enabled = false
	world.get_node("DeliveryManager").set_physics_process(false)
	var bike: CharacterBody3D = world.get_node("Bike")
	bike.global_position = Vector3(0, 0.05, -1000)  # out of the way while probing
	await physics_frame
	_space = bike.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = PROBE
	_query.shape = box
	_query.collide_with_areas = false
	_query.exclude = [bike.get_rid()]
	var roads: RoadMesh = world.get_node("WahatBuilder/Roads")
	var map: Dictionary = (load("res://data/wahat_al_shams.gd") as Script).get_script_constant_map()
	# A test wall nobody can see, to show the walk finds such things.
	var trap := StaticBody3D.new()
	trap.name = "TestInvisibleWall"
	world.add_child(trap)
	LowPoly.solid_box(trap, Vector3(2.0, 0.6, 0.2), Vector3(100, 0.3, 3.5))
	await physics_frame
	_walk_road_edges(roads)
	_walk_spine_tracks(map["SPINE_TRACKS"])
	_walk_blue_track(map["BIKE_TRACK"])
	_walk_car_parks(map["PARKING_AREAS"])
	print("probed %d spots, touched %d solid shapes" % [_probes, _hits.size()])
	_collect_visuals()
	var invisible: Array = []
	var trap_found := false
	for shape: CollisionShape3D in _hits:
		var body := shape.get_parent()
		if body.name in ALLOWED or body.is_in_group("critter"):  # moving life comes and goes
			continue
		if not _visible_at(shape):
			if body == trap:
				trap_found = true
			else:
				invisible.append("%s at %s" % [body.get_path(), _hits[shape]])
	trap.queue_free()
	_expect(trap_found, "the edge walk finds a test wall nobody can see")
	_expect(invisible.is_empty(), "no invisible walls along roads, tracks and car parks (%d found)" % invisible.size())
	for line in invisible.slice(0, 20):
		print("      invisible: ", line)
	_expect(world.find_children("SpineKerb*", "", true, false).is_empty(), "the spine's solid kerbs are gone")
	# Buggies, walkers and animals move about: a buggy on the roundabout once stopped the test
	# ride. Switching them off also takes them out of the physics world for the rides.
	for moving in ["LifeBuilder", "DistrictTraffic"]:
		var node := world.get_node_or_null(moving)
		if node != null:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	for critter in get_nodes_in_group("critter"):
		(critter as Node).process_mode = Node.PROCESS_MODE_DISABLED
	await physics_frame
	await _ride(bike, roads, Vector3(70, 0.05, -0.5), Vector3(0, 0, 1), 10.0, 2, "over the spine planter and the red track")
	await _ride(bike, roads, Vector3(-132, 0.05, -76), Vector3(0, 0, 1), 22.0, 2, "across the roundabout island")
	await _ride(bike, roads, Vector3(30, 0.05, -49), Vector3(0, 0, 1), 9.0, 1, "over the island at a cluster entrance")
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " ride edges · ", checks, " checks · ", failures.size(), " failures")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


# --- Walking the bike's shape along the edges ---------------------------------------------

func _walk_road_edges(roads: RoadMesh) -> void:
	for chain: Dictionary in roads.chains:
		if not chain.has("drawn"):
			continue
		var pts: Array = chain["drawn"]
		var sides: Array = chain["sides"]
		var half: float = chain["width"] * 0.5
		var along := 0.0
		for k in pts.size() - 1:
			along += (pts[k + 1] as Vector2).distance_to(pts[k])
			if along < STEP:
				continue
			along = 0.0
			var dir: Vector2 = ((pts[k + 1] as Vector2) - pts[k]).normalized()
			for side in [-1.0, 1.0]:
				for out: float in ACROSS:
					_probe(pts[k] + sides[k] * (half + out) * side, dir)


func _walk_spine_tracks(spec: Dictionary) -> void:
	var x: float = spec["from_x"]
	while x < spec["to_x"]:
		for z in [3.6, 4.4, 5.2, 6.2, 7.2, 8.2]:
			_probe(Vector2(x, z), Vector2.RIGHT)
			_probe(Vector2(x, -z), Vector2.RIGHT)
		x += STEP


func _walk_blue_track(track: Dictionary) -> void:
	var loop := EdgeBuilder.rounded_rect(track["half"], track.get("radius", 0.0))
	for k in loop.size():
		var a: Vector2 = loop[k]
		var b: Vector2 = loop[(k + 1) % loop.size()]
		var dir := (b - a).normalized()
		var out := Vector2(dir.y, -dir.x)
		var s := 0.0
		while s < a.distance_to(b):
			for across in [-2.5, -1.0, 0.0, 1.0, 2.5]:
				_probe(a + dir * s + out * across, dir)
			s += STEP


func _walk_car_parks(areas: Array) -> void:
	for area: Rect2 in areas:
		var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
		for k in 4:
			var a: Vector2 = corners[k]
			var b: Vector2 = corners[(k + 1) % 4]
			var dir := (b - a).normalized()
			var out := Vector2(dir.y, -dir.x)
			var s := 0.0
			while s < a.distance_to(b):
				for across in [-1.5, 0.0, 1.5]:
					_probe(a + dir * s + out * across, dir)
				s += STEP


## Puts the bike's shape at p (facing dir) and remembers every solid shape it touches.
func _probe(p: Vector2, dir: Vector2) -> void:
	_probes += 1
	var basis := Basis.looking_at(Vector3(dir.x, 0, dir.y))
	_query.transform = Transform3D(basis, Vector3(p.x, 0.15 + PROBE.y * 0.5, p.y))
	for hit in _space.intersect_shape(_query, 8):
		var body := hit["collider"] as CollisionObject3D
		if body == null:
			continue
		var owner_id := body.shape_find_owner(hit["shape"])
		var shape := body.shape_owner_get_owner(owner_id) as CollisionShape3D
		if shape != null and not _hits.has(shape):
			_hits[shape] = p


# --- Is there something to see where it bumped? --------------------------------------------

func _collect_visuals() -> void:
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var view := node as GeometryInstance3D
		if view.is_visible_in_tree() and (view is MeshInstance3D or view is MultiMeshInstance3D):
			_visuals.append(view)


## True if some drawn triangle (standing above the ground) is inside the shape's box.
func _visible_at(shape: CollisionShape3D) -> bool:
	var box := shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
	# What you see must stand nearly as tall as the solid part (a low kerb drawn under a
	# tall invisible wall doesn't count).
	var tall := minf(box.end.y, 1.2) - 0.3
	box = box.grow(0.15)
	for view: GeometryInstance3D in _visuals:
		if view is MultiMeshInstance3D:
			var many: MultiMesh = (view as MultiMeshInstance3D).multimesh
			if many == null or many.mesh == null:
				continue
			for i in many.instance_count:
				var placed := view.global_transform * many.get_instance_transform(i) * many.mesh.get_aabb()
				if placed.intersects(box) and placed.end.y > tall:
					return true
			continue
		var mesh := (view as MeshInstance3D).mesh
		if mesh == null or not (view.global_transform * mesh.get_aabb()).intersects(box):
			continue
		if _mesh_touches(view as MeshInstance3D, box, tall):
			return true
	return false


func _mesh_touches(view: MeshInstance3D, box: AABB, tall: float) -> bool:
	if not _faces.has(view):
		_faces[view] = view.mesh.get_faces()
	var faces: PackedVector3Array = _faces[view]
	var to_world := view.global_transform
	for i in range(0, faces.size(), 3):
		var a := to_world * faces[i]
		var b := to_world * faces[i + 1]
		var c := to_world * faces[i + 2]
		if maxf(a.y, maxf(b.y, c.y)) < tall:
			continue  # flat on the ground: a road or a lawn, not a wall
		var tri_box := AABB(a, Vector3.ZERO).expand(b).expand(c)
		if not tri_box.intersects(box):
			continue
		if box.has_point(a) or box.has_point(b) or box.has_point(c):
			return true
		if box.intersects_segment(a, b) or box.intersects_segment(b, c) or box.intersects_segment(c, a):
			return true
		if _box_edges_hit(box, a, b, c):
			return true
	return false


## True if one of the box's 12 edges goes through the triangle.
func _box_edges_hit(box: AABB, a: Vector3, b: Vector3, c: Vector3) -> bool:
	for i in 8:
		var p := box.get_endpoint(i)
		for axis in 3:
			if (i >> axis) & 1 == 0:
				var q := box.get_endpoint(i | (1 << axis))
				if Geometry3D.segment_intersects_triangle(p, q, a, b, c) != null:
					return true
	return false


# --- Really riding over kerbs ----------------------------------------------------------------

func _ride(bike: CharacterBody3D, roads: RoadMesh, from: Vector3, way: Vector3, distance: float, kerbs: int, label: String) -> void:
	bike.global_position = from
	bike.rotation = Vector3(0, atan2(-way.x, -way.z), 0)
	bike.velocity = Vector3.ZERO
	bike.speed = 0.0
	bike.fallen_left = 0.0
	await physics_frame
	await physics_frame
	var crossings_before := roads.bumps.crossings
	var crash_before: Dictionary = bike.last_crash.duplicate()
	var top_speed := 0.0
	var slowest_after_start := INF
	Input.action_press("move_forward")
	var frames := 0
	while frames < 600 and Vector3(bike.global_position - from).dot(way) < distance:
		await physics_frame
		frames += 1
		top_speed = maxf(top_speed, bike.speed)
		if frames > 90:
			slowest_after_start = minf(slowest_after_start, bike.speed)
	Input.action_release("move_forward")
	var went := Vector3(bike.global_position - from).dot(way)
	var bumps := roads.bumps.crossings - crossings_before
	_expect(went >= distance and bumps >= kerbs and bike.fallen_left <= 0.0 and bike.last_crash == crash_before,
			"the bike rides " + label + " with small bumps, no crash",
			"%.1f m, %d kerbs, top %.1f m/s, slowest %.1f m/s" % [went, bumps, top_speed, slowest_after_start])
