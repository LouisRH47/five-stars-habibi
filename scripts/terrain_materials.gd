class_name TerrainMaterials
extends RefCounted
## The ground boxes' materials. Session 82: the pictures, sizes and tints all come from the
## one table in SurfaceTextures (grass, sand, road, paving).


static func make(kind: String) -> Material:
	return SurfaceTextures.make(kind)


static func dress_ground(root: Node3D) -> void:
	for part: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if part.mesh == null or not part.mesh is BoxMesh:
			continue
		var box := part.mesh as BoxMesh
		if box.size.y > 1.05 or box.size.x < 3 or box.size.z < 3:
			continue
		var material := box.material as StandardMaterial3D
		if material == null:
			continue
		var color := material.albedo_color
		# Session 63: the stables and jumping arena plots are sand too.
		if color.is_equal_approx(Color(0.91, 0.83, 0.65)) or color.is_equal_approx(Color(0.8, 0.68, 0.5)) \
				or color.is_equal_approx(Color(0.86, 0.75, 0.55)) or color.is_equal_approx(Color(0.82, 0.7, 0.5)):
			part.material_override = make("sand")
		elif color.is_equal_approx(Color(0.47, 0.66, 0.34)):
			part.material_override = make("grass")
		elif color.is_equal_approx(Color(0.33, 0.34, 0.36)):
			part.material_override = make("road")
		elif color.is_equal_approx(Color(0.86, 0.79, 0.66)) or color.is_equal_approx(Color(0.78, 0.72, 0.62)):
			part.material_override = make("paving")
