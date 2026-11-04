extends SceneTree
## Session 55: the Schedule I look and the real grass. Run:
## Godot --path . --headless -s tests/grass_test.gd

var _failures := 0
var _count := 0


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://grass_test_save.json"
	_run.call_deferred()


func _run() -> void:
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 6:
		await process_frame
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var field: GrassField = world.find_child("GrassField", true, false)
	_check("the grass field is built", field != null and not field.lawns.is_empty())
	if field == null:
		_finish()
		return
	_check("the old grass shapes are hidden", not world.find_child("SpineGrassTufts", true, false).visible)

	# Look at the look.
	var env: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	_check("soft tone mapping and a little more colour", env.tonemap_mode == Environment.TONE_MAPPER_AGX
			and env.adjustment_enabled and env.adjustment_saturation > 1.0)
	var lawn_material := TerrainMaterials.make("grass")
	_check("the ground uses the new painted textures", lawn_material.albedo_texture.resource_path.contains("stylized")
			and TerrainMaterials.make("road").albedo_texture.resource_path.contains("stylized"))
	var detail := world.find_child("DistrictDetail", true, false)
	_check("surfaces were made matte (%d materials)" % int(detail.get_meta("matte_materials", 0)), int(detail.get_meta("matte_materials", 0)) > 20)

	# Medium: grass near the middle of the spine.
	Settings.graphics = 1
	field.apply_graphics()
	var spot := Vector3(-40, 0, 0)
	field.fill_around(spot, -1)
	var medium := field.tuft_count
	_check("grass squares near the spine on Medium (%d squares, %d tufts)" % [field.chunk_count(), medium], field.chunk_count() > 10 and medium > 10000)
	var started := Time.get_ticks_usec()
	field.apply_graphics()
	field.fill_around(spot, GameConfig.GRASS_BUILD_MS)
	var took := (Time.get_ticks_usec() - started) / 1000.0
	_check("filling in grass takes only a little time per frame (%.1f ms, %d squares)" % [took, field.chunk_count()],
			took < GameConfig.GRASS_BUILD_MS + 6.0 and field.chunk_count() < 3)
	var frames := 1
	while field.chunk_count() < 30 and frames < 400:
		field.fill_around(spot, GameConfig.GRASS_BUILD_MS)
		frames += 1
	_check("bit by bit, all the grass near you fills in (%d frames)" % frames, field.chunk_count() >= 30 and frames < 400)
	field.fill_around(spot, -1)

	# No blade on a path, road, pool, court, bed or in the stream.
	var bad := 0
	var checked := 0
	var blocked: Array = []
	for road: Dictionary in map["ROADS"]:
		blocked.append(road)
	var rects: Array = [map["LAP_POOL"], map["COMMUNITY_POOL"], map["BASKETBALL_COURT"], map["PLAYGROUND"]]
	rects.append_array(map["FARM_BEDS"])
	var first_bad := ""
	for key: Vector2i in field.chunk_keys():
		var corner := Vector3(key.x, 0, key.y) * GameConfig.GRASS_CHUNK
		for place: Transform3D in field.make_spots(key):
			var at: Vector3 = corner + place.origin
			var flat := Vector2(at.x, at.z)
			checked += 1
			for road: Dictionary in blocked:
				var a: Vector2 = road["from"]
				var b: Vector2 = road["to"]
				var near := Geometry2D.get_closest_point_to_segment(flat, a, b)
				if flat.distance_to(near) < float(road.get("width", 6.0)) * 0.5 - 0.05:
					bad += 1
					if first_bad == "":
						first_bad = "%s at %s" % [road["name"], flat]
			for area: Rect2 in rects:
				if area.grow(-0.05).has_point(flat):
					bad += 1
					if first_bad == "":
						first_bad = "an area at %s" % flat
	_check("no grass on paths, roads, pools, courts or beds (%d checked, %d bad %s)" % [checked, bad, first_bad], bad == 0 and checked > 1000)

	# Blades sit on the ground (and on the hills).
	var hill: Dictionary = map["HILLS"][1]
	var top := field.ground_height(hill["position"].x, hill["position"].z)
	_check("grass grows over the hills (%.2f m up)" % top, top > float(hill["height"]) * 0.8)

	# Low: fewer blades and a shorter grass distance.
	Settings.graphics = 0
	field.apply_graphics()
	field.fill_around(spot, -1)
	var low := field.tuft_count
	_check("Low has fewer blades than Medium (%d vs %d)" % [low, medium], low > 0 and low < medium / 2)
	Settings.graphics = 2
	field.apply_graphics()
	field.fill_around(spot, -1)
	_check("High has more blades than Medium (%d)" % field.tuft_count, field.tuft_count > medium)
	Settings.graphics = 1
	field.apply_graphics()

	# Far away from every lawn there's no grass at all.
	# Session 57: the Plaza has grass beds now, so check the empty north-east corner instead.
	field.fill_around(Vector3(400, 0, -200), -1)
	_check("no grass far from the lawns (the north-east corner)", field.chunk_count() == 0 and field.tuft_count == 0)
	_finish()


func _finish() -> void:
	print("GRASS RESULT: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _count])
	quit(1 if _failures > 0 else 0)


func _check(what: String, ok: bool) -> void:
	_count += 1
	if not ok:
		_failures += 1
	print(("PASS: " if ok else "FAIL: ") + what)
