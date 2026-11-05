class_name SurfaceTextures
extends RefCounted
## Every ground surface's picture in one table (Session 82): which picture, how many metres
## one copy of it covers, and the colour it's tinted with. Change a size or tint here and
## every road, lawn, track and paver using that surface changes with it.
## The pictures are in assets/textures/ (real CC0 photos from Poly Haven, see CREDITS.md;
## tools/make_photo_textures.gd makes the recoloured ones). Each material lays its picture in
## world metres (triplanar), so it never stretches, whatever the size of the box.

## name: {file, metres (one picture covers this many metres), tint (optional),
##   no_repeat (optional): use assets/shaders/ground_photo.gdshader, which hides the repeats,
##   patches / patch_share (optional): a second surface laid in big soft patches over it}
const SURFACES := {
	# The lawns: the old aerial_grass_rock photo, with leafy_grass in big patches.
	"grass": {"file": "aerial_grass_rock_diff_1k.jpg", "metres": 5.0, "tint": Color(0.67, 0.92, 0.55),
			"no_repeat": true, "patches": "leafy_grass", "patch_share": 0.35},
	"leafy_grass": {"file": "leafy_grass_diff_1k.jpg", "metres": 2.6, "tint": Color(0.66, 0.84, 0.48)},
	# Sand at the stables, the jumping arena, the horse track and the desert past the fence.
	"sand": {"file": "sand_01_diff_1k.jpg", "metres": 3.0, "no_repeat": true},
	"horse_sand": {"file": "sand_01_diff_1k.jpg", "metres": 3.0, "no_repeat": true},
	# Pavers in the clusters, footpaths and paver lanes: brick_pavement_02, warm sandy grey.
	"paving": {"file": "paving_sandy_1k.jpg", "metres": 2.0},
	"pavers": {"file": "paving_sandy_1k.jpg", "metres": 2.0},
	# Asphalt boxes: the same crack-free asphalt as the road mesh (RoadMesh.asphalt_material()).
	"road": {"file": "asphalt_road_1k.jpg", "metres": 5.0},
	# The red walking tracks beside the spine road: one lane of running_track, recoloured red.
	"walking_track": {"file": "red_walking_track_1k.jpg", "metres": 2.5},
	# The blue track round the map: running_track with its lane lines. EdgeBuilder lays it
	# one picture across the 4 m track and 8 m along (the picture is twice as tall as wide).
	"blue_track": {"file": "blue_track_photo_1k.jpg", "metres": 4.0},
	# The school's running track and the playground floors (Session 70 pictures).
	"red_track": {"file": "red_track.png", "metres": 2.0},
	"play_surface": {"file": "play_surface.png", "metres": 2.0},
}
## How big the soft patches of the no-repeat ground are (metres).
const NOISE_METRES := 70.0

static var _cache := {}


## The picture of a surface.
static func picture(surface: String) -> Texture2D:
	return load("res://assets/textures/" + SURFACES[surface]["file"])


## How many metres one copy of a surface's picture covers.
static func metres(surface: String) -> float:
	return SURFACES[surface]["metres"]


## The material for a surface (made once, then shared).
static func make(surface: String) -> Material:
	if _cache.has(surface):
		return _cache[surface]
	var mat: Material = _no_repeat(surface) if SURFACES[surface].get("no_repeat", false) else _plain(surface)
	_cache[surface] = mat
	return mat


static func _plain(surface: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = picture(surface)
	mat.albedo_color = SURFACES[surface].get("tint", Color.WHITE)
	mat.roughness = 0.95
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / metres(surface)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


## A big ground surface that hides its repeats (see assets/shaders/ground_photo.gdshader).
static func _no_repeat(surface: String) -> ShaderMaterial:
	var spec: Dictionary = SURFACES[surface]
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/ground_photo.gdshader")
	mat.set_shader_parameter("main_photo", picture(surface))
	mat.set_shader_parameter("main_metres", metres(surface))
	mat.set_shader_parameter("main_tint", spec.get("tint", Color.WHITE))
	if spec.has("patches"):
		var other: String = spec["patches"]
		mat.set_shader_parameter("patch_photo", picture(other))
		mat.set_shader_parameter("patch_metres", metres(other))
		mat.set_shader_parameter("patch_tint", SURFACES[other].get("tint", Color.WHITE))
		mat.set_shader_parameter("patch_share", spec["patch_share"])
	mat.set_shader_parameter("noise_metres", NOISE_METRES)
	mat.set_shader_parameter("noise", _noise())
	return mat


## Soft random blobs in a small picture that tiles with no seam (made once).
static func _noise() -> Texture2D:
	if not _cache.has("_noise"):
		var noise := FastNoiseLite.new()
		noise.seed = 82
		noise.frequency = 0.02
		noise.fractal_octaves = 3
		var image := noise.get_seamless_image(256, 256)
		image.generate_mipmaps()
		_cache["_noise"] = ImageTexture.create_from_image(image)
	return _cache["_noise"]


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
