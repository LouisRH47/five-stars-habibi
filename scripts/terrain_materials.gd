class_name TerrainMaterials
extends RefCounted
## Small shared CC0 textures in world metres, so road slabs never stretch a single pixel.
static var _cache: Dictionary = {}
const PHOTOS := {"grass": "aerial_grass_rock", "sand": "sand_01", "road": "asphalt_02", "paving": "pavement_02", "track": "pavement_02"}
const STYLIZED := {"grass": "grass", "sand": "sand", "road": "asphalt", "paving": "paving", "track": "track"}

static func make(kind: String) -> StandardMaterial3D:
	if _cache.has(kind):
		return _cache[kind]
	var mat := StandardMaterial3D.new()
	if GameConfig.STYLIZED_TEXTURES:
		# Session 55: clean, cartoony textures made by tools/make_textures.py.
		mat.albedo_texture = load("res://assets/textures/stylized/%s.png" % STYLIZED[kind])
		mat.metallic_specular = GameConfig.MATTE_SPECULAR
	else:
		# The old photo textures (Poly Haven, CC0), still here if we want them back.
		mat.albedo_texture = load("res://assets/textures/%s_diff_1k.jpg" % PHOTOS[kind])
		if kind == "grass":
			mat.albedo_color = Color(0.67, 0.92, 0.55)
	mat.roughness = 0.92
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	# How many times the picture repeats per metre (0.2 = once every 5 m).
	mat.uv1_scale = Vector3.ONE * (0.2 if kind in ["grass", "sand"] else 0.5)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[kind] = mat
	return mat


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
		if color.is_equal_approx(Color(0.91, 0.83, 0.65)) or color.is_equal_approx(Color(0.8, 0.68, 0.5)):
			part.material_override = make("sand")
		elif color.is_equal_approx(Color(0.47, 0.66, 0.34)):
			part.material_override = make("grass")
		elif color.is_equal_approx(Color(0.33, 0.34, 0.36)):
			part.material_override = make("road")
		elif color.is_equal_approx(Color(0.86, 0.79, 0.66)) or color.is_equal_approx(Color(0.78, 0.72, 0.62)):
			part.material_override = make("paving")


## Session 55, the Schedule I look: makes every surface under `root` matte (rough, with
## little shine), so things look clean and cartoony instead of plasticky. Glass, water,
## see-through things and anything meant to shine (roughness under 0.35, or metal) stay as
## they are. Returns how many materials changed.
static func make_matte(root: Node) -> int:
	var seen := {}
	for part: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var materials: Array = [part.material_override]
		if part.mesh != null:
			for i in part.mesh.get_surface_count():
				materials.append(part.get_surface_override_material(i))
				materials.append(part.mesh.surface_get_material(i))
		for material in materials:
			if material is StandardMaterial3D and not seen.has(material):
				seen[material] = _matte(material)
	return seen.values().count(true)


static func _matte(material: StandardMaterial3D) -> bool:
	if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.roughness < 0.35 \
			or material.metallic > 0.3:
		return false
	material.roughness = maxf(material.roughness, GameConfig.MATTE_MIN_ROUGHNESS)
	material.metallic_specular = minf(material.metallic_specular, GameConfig.MATTE_SPECULAR)
	return true
