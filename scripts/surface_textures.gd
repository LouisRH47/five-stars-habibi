class_name SurfaceTextures
extends RefCounted
## Session 70: the ground textures made by tools/blender/make_textures.py (blue_track,
## red_track, horse_sand, pavers, play_surface in assets/textures/). Each material maps the
## picture in world metres (triplanar), so it never stretches, whatever the size of the box.

## Picture name -> how many metres one picture covers.
const METRES := {"blue_track": 2.0, "red_track": 2.0, "horse_sand": 4.0, "pavers": 1.6, "play_surface": 2.0}

static var _cache := {}


static func make(texture: String) -> StandardMaterial3D:
	if _cache.has(texture):
		return _cache[texture]
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/%s.png" % texture)
	mat.roughness = 0.95
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / METRES.get(texture, 2.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[texture] = mat
	return mat


## A flat textured slab (just to look at). size: x and z; centre: the middle of its top.
static func slab(parent: Node3D, texture: String, size: Vector2, centre: Vector3, thickness := 0.04) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, thickness, size.y)
	view.mesh = box
	view.material_override = make(texture)
	view.position = centre - Vector3(0, thickness * 0.5, 0)
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	return view
