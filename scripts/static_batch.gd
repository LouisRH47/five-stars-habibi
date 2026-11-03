class_name StaticBatch
extends RefCounted
## Bakes plain static primitive views into spatial meshes without moving gameplay nodes.
## Call bake(world) after every builder and AmbientMotion have completed their setup.
## Use static_batch_dynamic metadata/group to opt any future moving subtree out.

const BUILDERS := ["WahatBuilder", "PlazaBuilder", "SpineBuilder", "LandmarkBuilder",
		"DecorBuilder", "PlaceBuilder", "DistrictDetail", "DistrictTraffic"]
const MOVING_NAMES := ["Crown", "Water", "BowlWater", "Jet", "Stream", "Barrier",
		"ShopPreview", "Swimmer"]
const MOVING_SCRIPTS := ["person.gd", "route_mover.gd", "critter.gd", "ambient_motion.gd",
		"bike.gd", "walker.gd", "traffic_vehicle.gd", "checkpoint.gd", "arena_horse.gd"]
const OUTPUT_NAME := "_StaticBatches"


## Return draw-submission savings, not a claim about measured frame rate.
static func bake(world: Node3D, chunk_size := 48.0) -> Dictionary:
	var total := {"source_meshes": 0, "batches": 0, "draws_saved": 0, "vertices": 0}
	for name: String in BUILDERS:
		var builder := world.get_node_or_null(NodePath(name)) as Node3D
		if builder == null:
			continue
		var report := bake_builder(builder, chunk_size)
		for key in total:
			total[key] += report[key]
	return total


## Also useful for a small standalone scene. A builder is baked at most once; restore
## it before a deliberate rebake. Children keep the builder's visibility/transform.
static func bake_builder(builder: Node3D, chunk_size := 48.0) -> Dictionary:
	var existing := builder.get_node_or_null(OUTPUT_NAME)
	if existing != null:
		return existing.get_meta("report").duplicate()
	var report := {"source_meshes": 0, "batches": 0, "draws_saved": 0, "vertices": 0}
	if not builder.is_inside_tree() or chunk_size <= 0.0:
		return report
	var groups := {}
	var material_keys := {}
	var material_states := {}
	var plain_materials := {}
	for view: MeshInstance3D in builder.find_children("*", "MeshInstance3D", true, false):
		if not _eligible(view, builder, chunk_size):
			continue
		var material := _material(view)
		if not plain_materials.has(material):
			plain_materials[material] = _plain_material(material)
		if not plain_materials[material]:
			continue
		var key := _material_key(material, material_keys, material_states)
		var centre: Vector3 = view.global_transform * view.mesh.get_aabb().get_center()
		var cell := Vector2i(floori(centre.x / chunk_size), floori(centre.z / chunk_size))
		key += "|%s|%s" % [cell, _render_key(view)]
		if not groups.has(key):
			groups[key] = {"views": [], "cell": cell, "material": material}
		groups[key]["views"].append(view)
	var output := Node3D.new()
	output.name = OUTPUT_NAME
	output.set_meta("static_batch_output", true)
	builder.add_child(output)
	var originals: Array[MeshInstance3D] = []
	for group: Dictionary in groups.values():
		var views: Array = group["views"]
		if views.size() < 2:
			continue
		var first := views[0] as MeshInstance3D
		var cell: Vector2i = group["cell"]
		var origin := Vector3((cell.x + 0.5) * chunk_size, 0, (cell.y + 0.5) * chunk_size)
		var chunk_transform := Transform3D(Basis(), origin)
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var source_bounds := AABB()
		var has_bounds := false
		for source: MeshInstance3D in views:
			var transform := chunk_transform.affine_inverse() * source.global_transform
			_append(tool, source.mesh, transform, _material(source).albedo_color)
			var bounds: AABB = transform * source.mesh.get_aabb()
			source_bounds = source_bounds.merge(bounds) if has_bounds else bounds
			has_bounds = true
		tool.index()
		var mesh := tool.commit()
		if mesh == null:
			continue
		var merged := MeshInstance3D.new()
		merged.name = "Chunk_%d_%d_%d" % [cell.x, cell.y, report["batches"]]
		merged.mesh = mesh
		var material: StandardMaterial3D = group["material"].duplicate()
		material.albedo_color = Color.WHITE
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		merged.material_override = material
		merged.layers = first.layers
		merged.cast_shadow = first.cast_shadow
		merged.gi_mode = first.gi_mode
		merged.lod_bias = first.lod_bias
		merged.extra_cull_margin = first.extra_cull_margin
		merged.ignore_occlusion_culling = first.ignore_occlusion_culling
		output.add_child(merged)
		merged.global_transform = chunk_transform
		merged.set_meta("source_count", views.size())
		merged.set_meta("source_bounds", source_bounds)
		# Hide only after a successful commit. Mesh resources and their node paths stay
		# intact for the smoke tests, collision code and any read-only world queries.
		for source: MeshInstance3D in views:
			source.visible = false
			source.set_meta("static_batch_hidden", true)
			originals.append(source)
		report["source_meshes"] += views.size()
		report["batches"] += 1
		report["vertices"] += mesh.surface_get_array_len(0)
	report["draws_saved"] = report["source_meshes"] - report["batches"]
	output.set_meta("originals", originals)
	output.set_meta("report", report)
	return report


static func restore(world: Node3D) -> void:
	for output: Node in world.find_children(OUTPUT_NAME, "Node3D", true, false):
		if output.get_meta("static_batch_output", false):
			_restore_output(output)


static func _restore_output(output: Node) -> void:
	for source: MeshInstance3D in output.get_meta("originals", []):
		if is_instance_valid(source):
			source.visible = true
			source.remove_meta("static_batch_hidden")
	output.get_parent().remove_child(output)
	output.queue_free()


static func _eligible(view: MeshInstance3D, builder: Node3D, chunk_size: float) -> bool:
	if not view.is_visible_in_tree() or not view.mesh is PrimitiveMesh or view.mesh.get_surface_count() != 1:
		return false
	if view.skin != null or view.material_overlay != null or view.transparency > 0.0:
		return false
	if view.visibility_range_begin != 0.0 or view.visibility_range_end != 0.0 or not view.visibility_parent.is_empty():
		return false
	if view.custom_aabb != AABB() or view.top_level:
		return false
	# A large existing slab is already one draw. Do not give a small chunk its huge
	# culling bounds merely to save that one submission.
	var bounds: AABB = view.global_transform * view.mesh.get_aabb()
	if maxf(bounds.size.x, bounds.size.z) > chunk_size * 2.0:
		return false
	var ancestor: Node = view
	while ancestor != null:
		if ancestor.get_meta("static_batch_dynamic", false) or ancestor.is_in_group("static_batch_dynamic"):
			return false
		if str(ancestor.name) in MOVING_NAMES:
			return false
		for group in ["graphics", "bike", "traffic_vehicle", "critter", "hears_bell"]:
			if ancestor.is_in_group(group):
				return false
		if ancestor == builder:
			break
		if ancestor is Skeleton3D or ancestor is AnimationPlayer or ancestor is AnimationTree:
			return false
		if ancestor is PhysicsBody3D and not ancestor is StaticBody3D:
			return false
		if ancestor.is_processing() or ancestor.is_physics_processing():
			return false
		var script := ancestor.get_script() as Script
		if script != null and script.resource_path.get_file() in MOVING_SCRIPTS:
			return false
		ancestor = ancestor.get_parent()
	return ancestor == builder


static func _material(view: MeshInstance3D) -> StandardMaterial3D:
	var material: Material = view.material_override
	if material == null:
		material = view.get_surface_override_material(0)
	if material == null:
		material = view.mesh.surface_get_material(0)
	return material as StandardMaterial3D


static func _plain_material(material: StandardMaterial3D) -> bool:
	if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return false
	if material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or material.grow:
		return false  # these depend on each primitive's original object transform
	if material.albedo_color.a < 1.0 or material.vertex_color_use_as_albedo or material.next_pass != null:
		return false
	for channel in [material.albedo_color.r, material.albedo_color.g, material.albedo_color.b]:
		if channel < 0.0 or channel > 1.0:
			return false  # vertex colours use normalized channels; preserve HDR uniforms
	for property: Dictionary in material.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE:
			var value = material.get(property["name"])
			if value is Texture or value is Shader:
				return false
	return true


static func _material_key(material: StandardMaterial3D, cache: Dictionary, states: Dictionary) -> String:
	if cache.has(material):
		return cache[material]
	# Group by every stored material setting except its tint. This retains differing
	# roughness, shading, emission, culling and depth settings without a fragile list.
	var settings := {}
	for property: Dictionary in material.get_property_list():
		var name: String = property["name"]
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE and not name in ["albedo_color", "resource_name", "resource_local_to_scene"]:
			settings[name] = material.get(name)
	var signature := var_to_str(settings)
	if not states.has(signature):
		states[signature] = states.size()
	var key := str(states[signature])
	cache[material] = key
	return key


static func _render_key(view: MeshInstance3D) -> String:
	return str([view.layers, view.cast_shadow, view.gi_mode, view.lod_bias,
			view.extra_cull_margin, view.ignore_occlusion_culling])


static func _append(tool: SurfaceTool, mesh: Mesh, transform: Transform3D, colour: Color) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count := indices.size() if not indices.is_empty() else vertices.size()
	var normal_basis := transform.basis.inverse().transposed()
	var flipped := transform.basis.determinant() < 0.0
	for triangle in range(0, count, 3):
		for offset in ([0, 2, 1] if flipped else [0, 1, 2]):
			var index: int = indices[triangle + offset] if not indices.is_empty() else triangle + offset
			tool.set_color(colour)
			var normal := (normal_basis * normals[index]).normalized()
			tool.set_normal(normal)
			if not uvs.is_empty():
				tool.set_uv(uvs[index])
			if not uv2s.is_empty():
				tool.set_uv2(uv2s[index])
			if not tangents.is_empty():
				var tangent := transform.basis * Vector3(tangents[index * 4], tangents[index * 4 + 1], tangents[index * 4 + 2])
				tangent = (tangent - normal * normal.dot(tangent)).normalized()
				tool.set_tangent(Plane(tangent, tangents[index * 4 + 3] * (-1.0 if flipped else 1.0)))
			tool.add_vertex(transform * vertices[index])
