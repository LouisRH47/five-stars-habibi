extends GPUParticles3D
## Dust puffs from the back tyre (Session 31, PRD "Juice"): a trail of little sand clouds
## while you ride on sand, and a short puff when you brake hard (on any ground).
## Fewer puffs on Graphics Low, more on High. The bike adds this in its _ready().
## The numbers are in scripts/game_config.gd ("Juice").

const SAND_COLOUR := Color(0.7, 0.58, 0.42, 1)

## True while the back tyre is on sand (the smoke test reads it).
var on_sand := false

var _bike: Node3D
var _map: Dictionary = {}
var _brake_left := 0.0
var _check_left := 0.0


func _ready() -> void:
	add_to_group("graphics")  # Settings.apply() calls apply_graphics() on this group
	_bike = get_parent()
	position = Vector3(0, 0.08, 0.62)  # just behind the back wheel, near the ground
	lifetime = GameConfig.DUST_LIFETIME
	emitting = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 4, 8))
	process_material = _make_material()
	draw_pass_1 = _make_puff()
	if _bike.has_signal("hard_braked"):
		_bike.hard_braked.connect(func(): _brake_left = GameConfig.DUST_BRAKE_TIME)
	# The map's data list says where the sand is (PlaceBuilder knows which list it is).
	var places := _bike.get_parent().get_node_or_null("PlaceBuilder")
	if places != null and places.get("data") != null:
		_map = (places.data as Script).get_script_constant_map()
	Settings.load_once()
	apply_graphics()


## Graphics Low / Medium / High: fewer or more puffs.
func apply_graphics() -> void:
	var wanted: int = GameConfig.DUST_AMOUNT[clampi(Settings.graphics, 0, 2)]
	if amount != wanted:
		amount = wanted


func _physics_process(delta: float) -> void:
	_brake_left = maxf(_brake_left - delta, 0.0)
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.1  # no need to look at the map every frame
		on_sand = GroundType.is_sand(_map, Vector2(global_position.x, global_position.z))
	var kmh := absf(_bike.speed) * 3.6
	var riding: bool = not _bike.parked and _bike.fallen_left <= 0.0 and not _bike.wrecked
	var sand_dust := riding and on_sand and kmh > GameConfig.DUST_MIN_KMH
	var brake_dust := riding and _brake_left > 0.0 and kmh > 2.0
	emitting = sand_dust or brake_dust
	# Faster = more dust. Braking hard always gives a full puff.
	amount_ratio = 1.0 if brake_dust else clampf(kmh / GameConfig.BIKE_MAX_SPEED_KMH, 0.35, 1.0)


func _make_material() -> ParticleProcessMaterial:
	var stuff := ParticleProcessMaterial.new()
	stuff.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	stuff.emission_sphere_radius = 0.12
	stuff.direction = Vector3(0, 1, 0.6)  # up and out the back
	stuff.spread = 35.0
	stuff.initial_velocity_min = 0.4
	stuff.initial_velocity_max = 1.3
	stuff.gravity = Vector3(0, -0.6, 0)
	stuff.damping_min = 1.5
	stuff.damping_max = 2.5
	stuff.scale_min = 0.8
	stuff.scale_max = 1.4
	# Each puff grows as it floats away...
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 2.2))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow
	stuff.scale_curve = grow_texture
	# ...and fades out.
	var fade := Gradient.new()
	fade.set_color(0, Color(SAND_COLOUR, 0.7))
	fade.set_color(1, Color(SAND_COLOUR, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	stuff.color_ramp = fade_texture
	return stuff


## One puff: a little low-poly ball, soft and see-through.
func _make_puff() -> Mesh:
	var ball := SphereMesh.new()
	ball.radius = GameConfig.DUST_PUFF_SIZE * 0.5
	ball.height = GameConfig.DUST_PUFF_SIZE
	ball.radial_segments = 8
	ball.rings = 4
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.vertex_color_use_as_albedo = true
	look.albedo_color = Color(1, 1, 1, 1)
	ball.material = look
	return ball
