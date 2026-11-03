extends Node
## The sun follows the shift clock (Session 28): low and warm at 08:00, high and white at
## noon, golden from 17:00. It also moves the sky colours and the light in the shadows.
## And it switches the extras on and off for the Graphics setting (Low / Medium / High):
## soft corner shadows (SSAO), haze, glow and heat shimmer above the roads at noon.
## All the numbers are in scripts/game_config.gd ("Light and sky").

@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

const SHIMMER_SHADER := preload("res://assets/shaders/heat_shimmer.gdshader")

var _environment: Environment
var _sky: ProceduralSkyMaterial
var _shimmer: MeshInstance3D
var _shimmer_material: ShaderMaterial
var _sky_hour := -100.0  # the hour the sky colours were last set for


func _ready() -> void:
	add_to_group("graphics")  # Settings.apply() calls apply_graphics() on this group
	_environment = world_environment.environment
	if _environment.sky != null:
		_sky = _environment.sky.sky_material as ProceduralSkyMaterial
		# Spread sky updates over a few frames instead of all in one go.
		_environment.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_make_shimmer()
	Settings.load_once()
	apply_graphics()
	apply_hour(hour_now())


func _process(_delta: float) -> void:
	apply_hour(hour_now())


## The in-game time, 8.0 (08:00) to 18.0 (18:00).
func hour_now() -> float:
	return GameState.clock_hours()


## Puts the sun, sky and shimmer where they should be at `hour`.
func apply_hour(hour: float) -> void:
	var look := light_at(hour)
	var turn := lerpf(GameConfig.SUN_TURN_MORNING, GameConfig.SUN_TURN_EVENING,
			inverse_lerp(GameConfig.SHIFT_START_HOUR, GameConfig.SHIFT_END_HOUR, hour))
	sun.rotation = Vector3(-deg_to_rad(look["height"]), deg_to_rad(turn + GameConfig.SUN_TURN_TILT), 0.0)
	sun.light_color = look["sun"]
	sun.light_energy = look["energy"]
	if absf(hour - _sky_hour) >= GameConfig.SKY_UPDATE_HOURS:
		_sky_hour = hour
		_environment.ambient_light_energy = look["ambient"]
		_environment.fog_light_color = look["horizon"]
		if _sky != null:
			_sky.sky_top_color = look["top"]
			_sky.sky_horizon_color = look["horizon"]
			_sky.ground_horizon_color = look["horizon"].lerp(Color(0.91, 0.83, 0.65), 0.5)
	var heat := shimmer_at(hour)
	_shimmer_material.set_shader_parameter("strength", heat)
	_shimmer.visible = heat > 0.01 and Settings.graphics > 0 and not OS.has_feature("web")


## Blends the two nearest lines of GameConfig.LIGHT_KEYS for this hour.
func light_at(hour: float) -> Dictionary:
	var keys: Array = GameConfig.LIGHT_KEYS
	if hour <= keys[0]["hour"]:
		return keys[0]
	for i in range(1, keys.size()):
		var after: Dictionary = keys[i]
		if hour <= after["hour"]:
			var before: Dictionary = keys[i - 1]
			var t := smoothstep(before["hour"], after["hour"], hour)
			var mixed := {}
			for key in before:
				mixed[key] = lerp(before[key], after[key], t)
			return mixed
	return keys[keys.size() - 1]


## How strong the heat shimmer is at this hour: 0 (none) to 1 (full, around noon).
func shimmer_at(hour: float) -> float:
	var peak: Vector2 = GameConfig.SHIMMER_PEAK_HOURS
	if hour < peak.x:
		return smoothstep(GameConfig.SHIMMER_START_HOUR, peak.x, hour)
	return 1.0 - smoothstep(peak.y, GameConfig.SHIMMER_END_HOUR, hour)


## Switches the extras on or off for the Graphics setting (0 Low, 1 Medium, 2 High).
func apply_graphics() -> void:
	var level: int = Settings.graphics
	var env := _environment
	var forward_plus := not OS.has_feature("web")
	env.ssao_enabled = level > 0 and forward_plus
	env.ssao_radius = GameConfig.SSAO_RADIUS
	env.ssao_intensity = GameConfig.SSAO_INTENSITY
	# Medium does the corner shadows at half size, High at full size and better quality.
	if forward_plus:
		RenderingServer.environment_set_ssao_quality(
				RenderingServer.ENV_SSAO_QUALITY_HIGH if level == 2 else RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
				level < 2, 0.5, 2, 50.0, 300.0)
	env.fog_enabled = level > 0
	env.fog_density = GameConfig.HAZE_DENSITY
	env.fog_aerial_perspective = GameConfig.HAZE_SKY_MIX
	env.fog_sky_affect = 0.0
	env.glow_enabled = level > 0 and forward_plus
	env.glow_intensity = GameConfig.GLOW_STRENGTH
	env.glow_hdr_threshold = GameConfig.GLOW_THRESHOLD
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	sun.directional_shadow_max_distance = GameConfig.SHADOW_DISTANCE[level]
	sun.shadow_blur = 1.0 if level == 0 else 1.5
	RenderingServer.directional_soft_shadow_filter_set_quality(
			RenderingServer.SHADOW_QUALITY_SOFT_HIGH if level == 2 else RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	_shimmer.visible = level > 0 and shimmer_at(hour_now()) > 0.01 and not OS.has_feature("web")


## The see-through sheet over the screen that wobbles the far-away ground (heat shimmer).
func _make_shimmer() -> void:
	var sheet := QuadMesh.new()
	sheet.size = Vector2(2.0, 2.0)
	_shimmer_material = ShaderMaterial.new()
	_shimmer_material.shader = SHIMMER_SHADER
	_shimmer_material.set_shader_parameter("near_distance", GameConfig.SHIMMER_NEAR)
	_shimmer_material.set_shader_parameter("full_distance", GameConfig.SHIMMER_FULL)
	_shimmer_material.set_shader_parameter("amount", GameConfig.SHIMMER_AMOUNT)
	sheet.material = _shimmer_material
	_shimmer = MeshInstance3D.new()
	_shimmer.name = "HeatShimmer"
	_shimmer.mesh = sheet
	_shimmer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shimmer.extra_cull_margin = 16384.0  # never hide it: it always covers the screen
	_shimmer.visible = false
	add_child(_shimmer)
