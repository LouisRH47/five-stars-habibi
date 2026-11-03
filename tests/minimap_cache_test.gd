extends SceneTree
## Run in the same isolated project used for the other gameplay smoke checks.
var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var mini := world.get_node("Minimap")
	var bike: Node3D = world.get_node("Bike")
	var view := mini.get_node("Panel/Margin/Window/View") as SubViewport
	_expect(view.disable_3d and view.render_target_update_mode == SubViewport.UPDATE_WHEN_VISIBLE,
			"mini-map is a 2D-only viewport that stops rendering while hidden")
	_expect(mini._home_labels.size() == 500 and mini._target_buildings.size() == 504,
			"all home labels and venue targets are cached with their stable identities")
	var polygons := 0
	var chunks := 0
	for child in mini._static_root.get_children():
		if child.get("polygons") != null:
			polygons += child.polygons.size()
			chunks += 1
	var places := world.get_node("PlaceBuilder")
	_expect(polygons == places.villas.size() + places.restaurants.size() + 1 and chunks > 1,
			"every building is retained once in spatially culled static chunks")
	var exact := true
	var reduced := true
	for cluster: Dictionary in WahatAlShams.CLUSTERS:
		for angle in [0.0, 0.7, PI * 0.5, PI]:
			var centre: Vector2 = cluster["centre"]
			bike.global_transform = Transform3D(Basis(Vector3.UP, angle), Vector3(centre.x, 0.03, centre.y))
			bike.reset_physics_interpolation()
			mini._process(0.0)
			var revision: int = mini._candidate_revision
			mini._process(0.0)
			exact = exact and mini._candidate_revision == revision
			# Move inside the five-metre reuse window and rotate: no visible label may
			# disappear merely because its candidate list was cached at the old point.
			bike.global_position.x += 4.9
			bike.reset_physics_interpolation()
			mini._process(0.0)
			var xform: Transform2D = mini._map_xform
			var bounds := Rect2(Vector2.ZERO, mini._view.size).grow(-6.0)
			var expected := {}
			var actual := {}
			for entry: Array in mini._home_labels:
				if bounds.has_point(xform * entry[0]):
					expected[entry[0]] = entry[1]
			for entry: Array in mini._number_candidates:
				if bounds.has_point(xform * entry[0]):
					actual[entry[0]] = entry[1]
			exact = exact and actual == expected
			reduced = reduced and mini._number_candidates.size() < mini._home_labels.size()
	_expect(exact, "cached label candidates match all visible homes at five clusters and four headings")
	_expect(reduced, "dynamic labels consider nearby homes rather than all 500 entries")
	var revision: int = mini._candidate_revision
	bike.global_position.x += 6.0
	bike.reset_physics_interpolation()
	mini._process(0.0)
	_expect(mini._candidate_revision == revision + 1, "moving beyond five metres refreshes nearby label candidates")
	var order := Order.new()
	order.villa_number = 345
	order.address = "Villa 45, Cluster 3"
	order.map_address = "C3 · Villa 45"
	order.restaurant_id = "pizza"
	order.restaurant_name = "1000 Pizza"
	order.food = "pizza"
	state.offer_order(order)
	state.accept_offer()
	state.pick_up()
	_expect(mini.target_label() == "C3 · Villa 45" and mini._house_number() == "45",
			"compact target addresses and explicit house numbers remain unchanged")
	mini.visible = false
	revision = mini._candidate_revision
	bike.global_position.x += 20
	mini._process(0.0)
	_expect(mini._candidate_revision == revision, "hidden mini-map does no candidate or draw rebuilding")
	mini.visible = true
	mini._process(0.0)
	_expect(mini._candidate_revision == revision + 1, "showing the mini-map refreshes its current position")
	world.queue_free()
	await process_frame
	print("RESULT: ", "FAIL mini-map cache" if _failed else "PASS mini-map cache")
	quit(1 if _failed else 0)


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
