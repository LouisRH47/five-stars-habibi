extends SceneTree
## Focused Session 36 checks. Run in the same isolated project used for smoke tests.

const CAMERA := preload("res://scripts/follow_camera.gd")
var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var homes := _sample_homes()
	var housing := HousingRows.build(homes, Vector3(9, 8.5, 8))
	root.add_child(housing)
	_check("500 stable home bodies in 20 double rows", housing.home_count == 500 and housing.row_count == 20)
	_check("one detailed and one far mesh per double row", housing.near_meshes.size() == 20 and housing.far_meshes.size() == 20)
	var near_vertices := 0
	var far_vertices := 0
	for view in housing.near_meshes:
		near_vertices += view.mesh.surface_get_array_len(0)
		_check("detailed row has a distance cutoff", view.visibility_range_end == GameConfig.HOUSING_DETAIL_DISTANCE)
	for view in housing.far_meshes:
		far_vertices += view.mesh.surface_get_array_len(0)
		_check("distant row starts at that cutoff", view.visibility_range_begin == GameConfig.HOUSING_DETAIL_DISTANCE)
	_check("distant houses use substantially fewer vertices", far_vertices * 4 < near_vertices)
	var kinds := {"courtyard": 0, "garden": 0, "signature": 0}
	var identity_ok := true
	var shape_ok := true
	var batched_ok := true
	for home: Dictionary in homes:
		var body := housing.get_node("%s/Villa%d" % [home["row"], home["number"]]) as StaticBody3D
		identity_ok = identity_ok and body != null and body.global_position.is_equal_approx(home["position"])
		if body == null:
			continue
		kinds[body.get_meta("kind")] += 1
		var number := body.get_node_or_null("Number") as Label3D
		identity_ok = identity_ok and number != null and number.text == str(home["house"])
		shape_ok = shape_ok and body.find_children("*", "CollisionShape3D", false, false).size() >= 2
		batched_ok = batched_ok and body.get_node_or_null("House") == null
	_check("home identities and door numbers survive batching", identity_ok)
	_check("all homes keep solid collisions", shape_ok)
	_check("home visuals are actually batched", batched_ok)
	_check("exact 90/8/2 mix in each 100-home cluster", kinds == {"courtyard": 450, "garden": 40, "signature": 10})
	await _check_camera()
	for person in [PeopleLooks.resident(0), PeopleLooks.resident(1), PeopleLooks.resident(2),
			PeopleLooks.resident(3), PeopleLooks.resident(4), PeopleLooks.teacher(),
			PeopleLooks.school_kid(), PeopleLooks.horse_rider(), PeopleLooks.groom()]:
		root.add_child(person)
		_check("outfit retains an actual skinned head", person.has_head_geometry())
		person.queue_free()
	housing.queue_free()
	await process_frame
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)


func _check_camera() -> void:
	var world := Node3D.new()
	world.position = Vector3(0, 0, -500)
	root.add_child(world)
	var rider := CharacterBody3D.new()
	world.add_child(rider)
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 3, 3)
	LowPoly.solid_box(wall, Vector3(12, 6, 1), Vector3.ZERO)
	world.add_child(wall)
	var camera: Camera3D = CAMERA.new()
	camera.target = rider
	world.add_child(camera)
	await physics_frame
	await physics_frame
	var anchor := rider.global_position + Vector3(0, GameConfig.CAMERA_LOOK_HEIGHT, 0)
	var desired := rider.global_position + Vector3(0, GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_DISTANCE)
	var safe: Vector3 = camera.collision_safe_position(anchor, desired)
	_check("camera sphere stops before a building wall", safe.z < wall.global_position.z - 0.5 and safe.z > anchor.z)
	camera.global_position = safe
	var before := camera.global_position
	wall.queue_free()
	await physics_frame
	await physics_frame
	camera._process(1.0 / 60.0)
	_check("camera eases back out after an obstruction clears", camera.global_position.z > before.z
			and camera.global_position.z < desired.z)
	var walker := CharacterBody3D.new()
	walker.position = Vector3(20, 0, 0)
	world.add_child(walker)
	var indoor_wall := StaticBody3D.new()
	indoor_wall.position = Vector3(20, 3, 2)
	LowPoly.solid_box(indoor_wall, Vector3(6, 6, 0.4), Vector3.ZERO)
	world.add_child(indoor_wall)
	camera.target = walker
	await physics_frame
	await physics_frame
	anchor = walker.global_position + Vector3(0, GameConfig.CAMERA_LOOK_HEIGHT, 0)
	desired = walker.global_position + Vector3(0, GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_DISTANCE)
	safe = camera.collision_safe_position(anchor, desired)
	_check("walking camera also stops before an indoor wall", safe.z < indoor_wall.global_position.z - 0.2)
	world.queue_free()
	await process_frame


func _sample_homes() -> Array:
	var homes: Array = []
	for cluster in range(1, 6):
		var number := 0
		for row in range(4):
			var count: int = [13, 12, 13, 12][row]
			for side in [-1, 1]:
				for along in count:
					number += 1
					var kind := "signature" if number in [1, 100] else ("garden" if number in [12, 25, 37, 49, 62, 75, 87, 99] else "courtyard")
					homes.append({"number": cluster * 100 + number, "house": number,
							"cluster": "C%d" % cluster, "row": "C%d_R%d" % [cluster, row + 1],
							"row_mode": true, "kind": kind, "facing": 90.0 * side,
							"position": Vector3((cluster - 3) * 150 + row * 30 + side * 4, 0, (along - (count - 1) * 0.5) * 9)})
	return homes


func _check(label: String, good: bool) -> void:
	print("PASS: " if good else "FAIL: ", label)
	_failed = _failed or not good
