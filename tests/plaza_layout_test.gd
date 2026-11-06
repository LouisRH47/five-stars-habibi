extends SceneTree
## Session 90 (layout): checks the Plaza paving, the buggy park, the gym and the Majlis path.
##   1) The Plaza paving runs along the Dune Drip side of the Plaza road to within 15 m of the
##      roundabout; the other side stays grass; it never lies on a road, a kerb or other paving.
##   2) The buggy park has at least 15 bays and sits right behind Dune Drip.
##   3) The gym clears every road, has two doors you can walk through (both slide open), and
##      outside: glass, a colour band, a bilingual sign over each door, planters by each door.
##   4) Majlis Gardens' south path ends square on the spine loop road's edge, with a zebra
##      crossing over the road.
## Run: Godot --path . --headless -s tests/plaza_layout_test.gd   (prints RESULT: PASS)

const KERB := 0.25    # metres a kerb reaches out from the road's edge (GameConfig.KERB_WIDTH)

var failures: Array[String] = []
var checks := 0
var world: Node3D
var area: RoadArea


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://plaza_layout_test.json"
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
	var roads: RoadMesh = world.get_node("WahatBuilder/Roads")
	area = roads.area
	var map: Dictionary = (world.get_node("PlaceBuilder") as PlaceBuilder).data.get_script_constant_map()
	_check_paving(map)
	_check_buggy_park(map)
	await _check_gym(map)
	_check_majlis(map, roads)
	world.queue_free()
	await process_frame
	SaveGame.delete(state.save_path)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " plaza layout · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


## True if p is on asphalt or on a kerb (within KERB of a road's edge or a curved corner).
func _on_road_or_kerb(p: Vector2) -> bool:
	return area.road_at(p, -KERB) >= 0 or area.fillet_at(p, KERB) >= 0


## Points every `step` metres inside a polygon.
func _inside(poly: PackedVector2Array, step: float) -> Array[Vector2]:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	var out: Array[Vector2] = []
	var x := box.position.x + step * 0.5
	while x < box.end.x:
		var z := box.position.y + step * 0.5
		while z < box.end.y:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), poly):
				out.append(Vector2(x, z))
			z += step
		x += step
	return out


## The Plaza road's middle line, from the roundabout to the buggy park.
func _plaza_road(map: Dictionary) -> Array[Vector2]:
	var line: Array[Vector2] = []
	for road: Dictionary in map["ROADS"]:
		if road["name"] == "Plaza Road":
			if line.is_empty():
				line.append(road["from"])
			line.append(road["to"])
	return line


func _check_paving(map: Dictionary) -> void:
	var plaza: Dictionary = map["PLAZA"]
	var walks := PlazaFloor.walks(plaza)
	_expect(walks.size() >= 1, "the Plaza paving has a walk along the Plaza road")
	if walks.is_empty():
		return
	var roundabout: Vector2 = map["ROUNDABOUTS"][0]["centre"]
	var nearest := INF
	for walk in walks:
		for q in walk:
			nearest = minf(nearest, q.distance_to(roundabout))
	_expect(nearest <= 15.0, "the paving reaches within 15 m of the roundabout's middle", "%.1f m" % nearest)
	# The one Plaza mesh covers the walks too (same mesh, same height as the Plaza floor).
	var floor_view := world.get_node("PlazaBuilder/Plaza") as MeshInstance3D
	var box := floor_view.get_aabb()
	_expect(box.end.z >= -76.5 and box.size.y < 0.6, "the walk is part of the one Plaza floor mesh", str(box))
	# Left of the road (going from the roundabout) is paved, right of it stays grass.
	var line := _plaza_road(map)
	var paved_left := 0
	var left_points := 0
	var paved_right: Array = []
	for k in line.size() - 1:
		var a := line[k]
		var b := line[k + 1]
		var way := (b - a).normalized()
		var left := Vector2(way.y, -way.x)
		for t in [0.25, 0.5, 0.75]:
			var p := a.lerp(b, t)
			if p.distance_to(roundabout) < 15.0:
				continue
			left_points += 1
			if PlazaFloor.is_paved(map, p + left * 4.0):
				paved_left += 1
			for out in [4.0, 8.0]:
				if PlazaFloor.is_paved(map, p - left * out):
					paved_right.append(p - left * out)
	_expect(paved_left == left_points, "the Dune Drip side of the Plaza road is paved", "%d of %d" % [paved_left, left_points])
	_expect(paved_right.is_empty(), "the other side of the Plaza road stays grass", str(paved_right.slice(0, 4)))
	# Never on a road, a kerb, the Plaza floor, an apron or a car park.
	var on_road: Array = []
	var on_paving: Array = []
	for walk in walks:
		var edge: Array[Vector2] = []  # the outline too, every 10 cm (just inside it)
		var middle := Vector2.ZERO
		for q in walk:
			middle += q / walk.size()
		for k in walk.size():
			var a := walk[k]
			var b := walk[(k + 1) % walk.size()]
			for t in range(0, 10 * ceili(a.distance_to(b)) + 1):
				var q := a.lerp(b, t / (10.0 * ceili(a.distance_to(b))))
				edge.append(q.move_toward(middle, 0.01))
		for p in _inside(walk, 0.25) + edge:
			if _on_road_or_kerb(p):
				on_road.append(p)
			var others: Array = [(plaza["floor"] as Rect2).grow(-0.01)]
			for apron: Rect2 in plaza.get("aprons", []):
				others.append(apron.grow(-0.01))
			for lot: Dictionary in map["PARKING_LOTS"]:
				others.append((lot["area"] as Rect2).grow(-0.01))
			for other: Rect2 in others:
				if other.has_point(p):
					on_paving.append(p)
					break
	_expect(on_road.is_empty(), "the walk never lies on a road or a kerb", "%d points, e.g. %s" % [on_road.size(), on_road.slice(0, 3)])
	_expect(on_paving.is_empty(), "the walk never lies on other paving", "%d points, e.g. %s" % [on_paving.size(), on_paving.slice(0, 3)])
	# It joins the Plaza floor and the apron (no grass gap between them).
	var floor_rect: Rect2 = plaza["floor"]
	var joins := PlazaFloor.is_paved(map, Vector2(floor_rect.end.x + 0.05, floor_rect.end.y - 0.05)) \
			and PlazaFloor.is_paved(map, Vector2(floor_rect.end.x + 0.05, floor_rect.end.y + 0.05))
	_expect(joins, "the walk joins the Plaza floor")


func _check_buggy_park(map: Dictionary) -> void:
	var park: Dictionary = {}
	for lot: Dictionary in map["PARKING_LOTS"]:
		if lot["kind"] == "buggies":
			park = lot
	var bays := 0
	for row: Dictionary in park.get("rows", []):
		bays += (row["bays"] as Array).size()
	_expect(bays >= 15, "the buggy park has at least 15 bays (3 times the old 6)", str(bays))
	var dune_drip: Dictionary = map["SHOPS"][1]
	var p: Vector3 = dune_drip["position"]
	var size: Vector3 = dune_drip["size"]
	var back_x := p.x + size.z * 0.5   # Dune Drip faces west (-X): its back wall is east
	var spot: Rect2 = park.get("area", Rect2())
	var shop_z := Vector2(p.z - size.x * 0.5, p.z + size.x * 0.5)
	var overlap := minf(spot.end.y, shop_z.y) - maxf(spot.position.y, shop_z.x)
	_expect(spot.position.x >= back_x and spot.position.x - back_x < 5.0 and overlap >= size.x * 0.8,
			"the buggy park sits right behind Dune Drip", "%s, back wall x %.1f" % [spot, back_x])
	var parked := world.find_children("ParkedBuggy_*", "StaticBody3D", true, false).size()
	_expect(parked >= 6, "six buggies are parked there", str(parked))


## The gym's outline (its straight part and rounded back) as world (x, z) points.
func _gym_outline(gym: Node3D, size: Vector3) -> PackedVector2Array:
	var half := size.x * 0.5
	var front := size.z * 0.5
	var arc := -front + 4.0
	var local: Array[Vector3] = [Vector3(-half, 0, front), Vector3(half, 0, front)]
	for i in 25:
		var a := PI * i / 24.0
		local.append(Vector3(cos(a) * half, 0, arc - sin(a) * 4.0))
	var out := PackedVector2Array()
	for q in local:
		var w := gym.to_global(q)
		out.append(Vector2(w.x, w.z))
	return out


func _check_gym(map: Dictionary) -> void:
	var places: PlaceBuilder = world.get_node("PlaceBuilder")
	var gym: Node3D = places.get_node("Gym")
	var size: Vector3 = map["GYM"]["size"]
	_expect(is_equal_approx(size.x, 30.6) and is_equal_approx(size.z, 18.7), "the gym is 15% smaller (30.6 x 18.7 m)", str(size))
	var outline := _gym_outline(gym, size)
	var hits: Array = []
	for p in _inside(outline, 0.5) + Array(outline):
		if _on_road_or_kerb(p):
			hits.append(p)
	_expect(hits.is_empty(), "the gym's footprint clears every road and kerb", "%d points, e.g. %s" % [hits.size(), hits.slice(0, 3)])
	# Two doors you can walk through: nothing solid from outside each door to reception.
	var doors := [gym.get_node_or_null("SlidingDoor"), gym.get_node_or_null("SideDoor")]
	_expect(doors[0] != null and doors[1] != null, "the gym has two entrances (front and pool side)")
	if doors.has(null):
		return
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	var reception := places.villa_door(904)
	for door: Node3D in doors:
		var outside := door.global_position + door.global_basis.z * 2.5
		var blocked := ""
		for height in [0.4, 1.2]:
			for target in [door.global_position - door.global_basis.z * 1.5, reception]:
				var ray := PhysicsRayQueryParameters3D.create(outside + Vector3.UP * height, target + Vector3.UP * height)
				var hit := space.intersect_ray(ray)
				if not hit.is_empty():
					blocked = "%s at %s" % [hit["collider"].name, hit["position"]]
		_expect(blocked == "", "you can walk in through the gym's " + str(door.name) + " to reception", blocked)
	# Both sets of doors slide open as someone walks up.
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = gym.global_position + Vector3(0, 3, 0)
	camera.make_current()
	var walker := Node3D.new()
	walker.add_to_group("opens_doors")
	world.add_child(walker)
	for pair in [["SlidingDoor", "Motion"], ["SideDoor", "SideDoorMotion"]]:
		var door := gym.get_node(pair[0]) as Node3D
		walker.global_position = door.global_position + door.global_basis.z * 1.5
		var opened := false
		for i in 20:
			await process_frame
			opened = opened or (gym.get_node(pair[1]) as VenueMotion).doors_open
		_expect(opened, "the gym's %s slides open as you walk up" % pair[0])
	walker.queue_free()
	camera.queue_free()
	# Outside like the restaurants: glass on the front and pool side, a colour band, a
	# bilingual sign over each door, a canopy and two planters by each door.
	for sign_name in ["BilingualSign", "SideSign"]:
		var sign := gym.get_node_or_null(sign_name)
		var arabic := false
		var english := false
		if sign != null:
			for label in sign.find_children("*", "Label3D", true, false):
				arabic = arabic or (label as Label3D).text == map["GYM"]["arabic"]
				english = english or (label as Label3D).text == "Wahat Gym"
		_expect(arabic and english, "the gym's %s says Wahat Gym in Arabic and English" % sign_name)
	_expect(_count(gym, "DoorPlanter") == 2 and _count(gym, "SideDoorPlanter") == 2, "two planters by each gym door")
	_expect(gym.get_node_or_null("DoorCanopy") != null and gym.get_node_or_null("SideDoorCanopy") != null, "a canopy over each gym door")
	var bands := 0
	var tint: Color = map["GYM"].get("colour", GymRoom.TEAL)
	for view in gym.get_children():
		if view is MeshInstance3D and (view as MeshInstance3D).position.y > GymRoom.CEILING:
			var look := (view as MeshInstance3D).get_active_material(0) as StandardMaterial3D
			if look != null and look.albedo_color.is_equal_approx(tint):
				bands += 1
	_expect(bands >= 2, "a colour band over the glass on the front and the pool side", str(bands))


func _count(room: Node, prefix: String) -> int:
	var found := 0
	for child in room.get_children():
		if str(child.name).begins_with(prefix):
			found += 1
	return found


func _check_majlis(map: Dictionary, roads: RoadMesh) -> void:
	var path: Array = map["MAJLIS_GARDENS"]["paths"][0]
	var end: Vector2 = path[0]
	var next: Vector2 = path[1]
	var road: Dictionary = {}
	for each: Dictionary in map["ROADS"]:
		var a: Vector2 = each["from"]
		var b: Vector2 = each["to"]
		if Geometry2D.get_closest_point_to_segment(end, a, b).distance_to(end) < 4.0:
			road = each
	_expect(not road.is_empty(), "the Majlis south path ends at a road")
	if road.is_empty():
		return
	var a: Vector2 = road["from"]
	var b: Vector2 = road["to"]
	var gap: float = Geometry2D.get_closest_point_to_segment(end, a, b).distance_to(end) - float(road["width"]) * 0.5
	_expect(absf(gap) < 0.05, "the path's last piece touches the road's edge (no grass gap, no overlap)", "%.2f m" % gap)
	var square := absf((next - end).normalized().dot((b - a).normalized()))
	_expect(square < 0.05 and end.distance_to(next) > 0.4, "the last piece runs square to the road", "%.2f" % square)
	var half: float = map["MAJLIS_GARDENS"]["path_width"] * 0.5
	var over: Array = []
	for k in path.size() - 1:
		var p: Vector2 = path[k]
		var q: Vector2 = path[k + 1]
		var side := (q - p).normalized().orthogonal() * half
		for t in [0.0, 0.5, 1.0]:
			for s in [-1.0, 0.0, 1.0]:
				var spot: Vector2 = p.lerp(q, t) + side * s * 0.98 + (q - p).normalized() * 0.02
				if area.on_asphalt(spot):
					over.append(spot)
	_expect(over.is_empty(), "the path never lies on the road", str(over.slice(0, 3)))
	_expect(area.in_gap(end) and area.in_gap(end + (end - next).normalized() * 6.0), "no kerb across the path or the far end of the crossing")
	var zebra: Dictionary = {}
	for each: Dictionary in map.get("ZEBRA_CROSSINGS", []):
		if (each["from"] as Vector2).distance_to(end) < 0.05:
			zebra = each
	_expect(not zebra.is_empty() and roads.stats["zebras"] >= 1 and roads.stats["zebra_stripes"] >= 5,
			"a zebra crossing takes the path over the road", "%d stripes" % roads.stats["zebra_stripes"])
