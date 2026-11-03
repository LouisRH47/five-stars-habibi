extends SceneTree
## Structural checks run headless; -- --visual also captures native before/after images.
const BATCH := preload("res://scripts/static_batch.gd")
var _failed := false
var _sources: Array[MeshInstance3D] = []
var _excluded: Array[MeshInstance3D] = []

class MovingProp extends Node3D:
	func _process(_delta: float) -> void:
		pass


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	root.add_child(world)
	var builder := Node3D.new()
	builder.name = "DecorBuilder"
	builder.position = Vector3(17, 0, -24)
	builder.rotation.y = 0.35
	world.add_child(builder)
	var body := StaticBody3D.new()
	body.name = "SolidScenery"
	body.set_meta("identity", 73)
	builder.add_child(body)
	var colours := [Color(0.8, 0.15, 0.1), Color(0.1, 0.35, 0.8), Color(0.2, 0.7, 0.3)]
	for i in 6:
		var view := LowPoly.box(body, Vector3(1.4, 1.5, 1.1), colours[i % 3], Vector3((i - 2.5) * 2.2, 0.75, 0))
		view.name = "Box%d" % i
		view.rotation.y = i * 0.15
		view.scale = Vector3(-1.2 if i == 0 else 1.0 + i * 0.08, 1.0, 0.8 + i * 0.1)
		_sources.append(view)
		LowPoly.solid_box(body, Vector3(1.4, 1.5, 1.1), view.position)
	for i in 2:
		var sphere := LowPoly.sphere(body, 0.65, 1.3, colours[i], Vector3(-2 + i * 4, 2.5, 0))
		var matte := LowPoly.material(colours[i]).duplicate() as StandardMaterial3D
		matte.roughness = 0.3
		sphere.material_override = matte
		_sources.append(sphere)
	# A second spatial chunk must stay separately culled.
	for i in 2:
		_sources.append(LowPoly.cylinder(builder, 0.45, 0.55, 1.0, colours[i], Vector3(100 + i * 2, 0.5, 0)))
	_exclusions(builder)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = builder.to_global(Vector3(9, 8, 18))
	camera.look_at(builder.to_global(Vector3(0, 1.1, 0)))
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	world.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.18, 0.22, 0.27)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.45
	world.add_child(environment)
	await physics_frame
	await physics_frame
	var shapes_before := world.find_children("*", "CollisionShape3D", true, false).size()
	var collider_before := _ray(world, body.to_global(Vector3(-5.5, 0, 0)))
	var expected := _bounds(_sources)
	var visual := OS.get_cmdline_user_args().has("--visual") and DisplayServer.get_name() != "headless"
	if visual:
		await _capture("before")
	var report: Dictionary = BATCH.bake(world, 48.0)
	_expect(report["source_meshes"] == _sources.size() and report["batches"] == 3,
			"plain colours merge by material settings into three spatial batches")
	_expect(report["draws_saved"] == 7, "draw savings count actual removed submissions")
	var retained := true
	for view in _sources:
		retained = retained and is_instance_valid(view) and not view.visible and view.mesh is PrimitiveMesh
	_expect(retained and body.get_node_or_null("Box0") != null and body.get_meta("identity") == 73,
			"original meshes, node paths and gameplay identity are retained")
	var excluded_ok := true
	for view in _excluded:
		excluded_ok = excluded_ok and not view.get_meta("static_batch_hidden", false)
	_expect(excluded_ok, "moving, graphics-controlled, textured, shader, transparent and prebatched views stay separate")
	var chunks: Array[MeshInstance3D] = []
	for chunk: MeshInstance3D in builder.get_node("_StaticBatches").get_children():
		chunks.append(chunk)
	var actual := _bounds(chunks)
	_expect(expected.position.is_equal_approx(actual.position) and expected.size.is_equal_approx(actual.size),
			"merged world bounds preserve translation, rotation, nonuniform scale and reflection")
	var seen := {}
	var normals_ok := true
	for chunk in chunks:
		var arrays := chunk.mesh.surface_get_arrays(0)
		for colour: Color in arrays[Mesh.ARRAY_COLOR]:
			seen[colour] = true
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0, indices.size(), 3):
			var a := indices[i]
			var b := indices[i + 1]
			var c := indices[i + 2]
			var cross := (positions[b] - positions[a]).cross(positions[c] - positions[a])
			if cross.length_squared() > 0.000001:
				normals_ok = normals_ok and cross.dot(normals[a] + normals[b] + normals[c]) < 0.0
	var colours_ok := true
	for colour: Color in colours:
		colours_ok = colours_ok and seen.keys().any(func(actual_colour: Color):
			# Godot stores vertex colours as RGBA8. Keep within one channel code value.
			return (absf(actual_colour.r - colour.r) <= 1.0 / 255.0
					and absf(actual_colour.g - colour.g) <= 1.0 / 255.0
					and absf(actual_colour.b - colour.b) <= 1.0 / 255.0))
	_expect(colours_ok, "original material tints survive as per-vertex colours")
	_expect(normals_ok, "reflected geometry keeps outward normals and front-face winding")
	await physics_frame
	_expect(shapes_before == world.find_children("*", "CollisionShape3D", true, false).size()
			and _ray(world, body.to_global(Vector3(-5.5, 0, 0))) == collider_before and collider_before == body,
			"the exact same solid body is hit before and after batching")
	_expect(BATCH.bake(world, 48.0) == report, "repeated baking is idempotent")
	if visual:
		await _capture("after")
	BATCH.restore(world)
	_expect(_sources.all(func(view: MeshInstance3D): return view.visible) and builder.get_node_or_null("_StaticBatches") == null,
			"restore removes outputs and re-enables the unchanged source views")
	world.queue_free()
	await process_frame
	print("RESULT: ", "FAIL static batching" if _failed else "PASS static batching")
	quit(1 if _failed else 0)


func _exclusions(builder: Node3D) -> void:
	for name in ["Crown", "Water", "Jet", "Stream", "Barrier"]:
		var holder := Node3D.new()
		holder.name = name
		holder.position.z = -6
		builder.add_child(holder)
		_excluded.append(LowPoly.box(holder, Vector3.ONE, Color.ORANGE, Vector3.ZERO))
	var moving := MovingProp.new()
	moving.position.z = -6
	builder.add_child(moving)
	_excluded.append(LowPoly.box(moving, Vector3.ONE, Color.RED, Vector3.ZERO))
	var controlled := Node3D.new()
	controlled.add_to_group("graphics")
	builder.add_child(controlled)
	_excluded.append(LowPoly.box(controlled, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6)))
	var marked := Node3D.new()
	marked.set_meta("static_batch_dynamic", true)
	builder.add_child(marked)
	_excluded.append(LowPoly.box(marked, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6)))
	var actor := CharacterBody3D.new()
	builder.add_child(actor)
	_excluded.append(LowPoly.box(actor, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6)))
	var skinned := LowPoly.box(builder, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6))
	skinned.skin = Skin.new()
	_excluded.append(skinned)
	var textured := LowPoly.box(builder, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6))
	var picture := Image.create(1, 1, false, Image.FORMAT_RGB8)
	picture.fill(Color.WHITE)
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(picture)
	textured.material_override = material
	_excluded.append(textured)
	var shaded := LowPoly.box(builder, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6))
	var shader := ShaderMaterial.new()
	shader.shader = Shader.new()
	shader.shader.code = "shader_type spatial; void fragment() { ALBEDO=vec3(0.2,0.4,0.8); }"
	shaded.material_override = shader
	_excluded.append(shaded)
	var transparent := LowPoly.box(builder, Vector3.ONE, Color.RED, Vector3(0, 0.5, -6))
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.3
	transparent.material_override = glass
	_excluded.append(transparent)
	var kit := MeshKit.new()
	kit.box(Vector3.ONE, Color.RED, Vector3(0, 0.5, -6))
	var prebatched := kit.finish("JoinedHomes")
	builder.add_child(prebatched)
	_excluded.append(prebatched)
	var label := Label3D.new()
	label.text = "Keep this label"
	builder.add_child(label)
	var large := LowPoly.box(builder, Vector3(150, 0.1, 150), Color.GRAY, Vector3(0, -0.1, 0))
	_excluded.append(large)


func _bounds(views: Array[MeshInstance3D]) -> AABB:
	var result := AABB()
	var first := true
	for view in views:
		# A rotated primitive's reported AABB is conservative. Measure its actual
		# world vertices, independently of the batching code's chunk-space bounds.
		var bounds := AABB()
		var first_vertex := true
		for surface in view.mesh.get_surface_count():
			for vertex: Vector3 in view.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var point := view.global_transform * vertex
				bounds = AABB(point, Vector3.ZERO) if first_vertex else bounds.expand(point)
				first_vertex = false
		result = bounds if first else result.merge(bounds)
		first = false
	return result


func _ray(world: Node3D, at: Vector3) -> Object:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 5, at - Vector3.UP)
	return world.get_world_3d().direct_space_state.intersect_ray(query).get("collider")


func _capture(name: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/habibi-static-%s.png" % name)
	print("CAPTURE static ", name)


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)
