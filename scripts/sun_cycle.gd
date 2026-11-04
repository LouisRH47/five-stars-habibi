extends Node
## The sun follows the shift clock (Session 28): low and warm at 08:00, high and white at
## noon, golden from 17:00. It also moves the sky colours and the light in the shadows.
## And it switches the extras on and off for the Graphics setting (Low / Medium / High):
## soft corner shadows (SSAO), haze and glow.
## All the numbers are in scripts/game_config.gd ("Light and sky").

@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var use_smaller_sky_radiance := false

var _environment: Environment
var _sky: ProceduralSkyMaterial
var _sky_hour := -100.0  # the hour the sky colours were last set for


func _ready() -> void:
	add_to_group("graphics")  # Settings.apply() calls apply_graphics() on this group
	_environment = world_environment.environment
	if _environment.sky != null:
		_sky = _environment.sky.sky_material as ProceduralSkyMaterial
		# Spread sky updates over a few frames instead of all in one go.
		_environment.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_apply_look()
	Settings.load_once()
	apply_graphics()
	apply_hour(hour_now())


func _process(_delta: float) -> void:
	apply_hour(hour_now())


## The in-game time, 8.0 (08:00) to 18.0 (18:00).
func hour_now() -> float:
	return GameState.clock_hours()


## Puts the sun and sky where they should be at `hour`.
func apply_hour(hour: float) -> void:
	var look := light_at(hour).duplicate()
	# Session 52: the sun's direction moves in small steps (every few game minutes), not
	# every frame. A sun that moves every frame makes shadow edges on the ground crawl
	# and shimmer; a tiny step now and then is not noticeable.
	var step := GameConfig.SUN_STEP_HOURS
	var sun_hour := floorf(hour / step) * step if step > 0.0 else hour
	look["height"] = light_at(sun_hour)["height"]
	var turn := lerpf(GameConfig.SUN_TURN_MORNING, GameConfig.SUN_TURN_EVENING,
			inverse_lerp(GameConfig.SHIFT_START_HOUR, GameConfig.SHIFT_END_HOUR, sun_hour))
	sun.rotation = Vector3(-deg_to_rad(look["height"]), deg_to_rad(turn + GameConfig.SUN_TURN_TILT), 0.0)
	sun.light_color = look["sun"]
	sun.light_energy = look["energy"]
	if absf(hour - _sky_hour) >= GameConfig.SKY_UPDATE_HOURS:
		_sky_hour = hour
		_environment.ambient_light_energy = look["ambient"] * GameConfig.LOOK_AMBIENT_SCALE
		_environment.fog_light_color = look["horizon"]
		if _sky != null:
			_sky.sky_top_color = look["top"]
			_sky.sky_horizon_color = look["horizon"]
			_sky.ground_horizon_color = look["horizon"].lerp(Color(0.91, 0.83, 0.65), 0.5)


## Session 55, the Schedule I look: soft tone mapping, a little more colour, a little
## brighter, and shadows that aren't black. Numbers in game_config.gd ("The Schedule I look").
func _apply_look() -> void:
	if not GameConfig.STYLIZED_TEXTURES:
		return
	var env := _environment
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = GameConfig.LOOK_EXPOSURE
	env.tonemap_white = GameConfig.LOOK_WHITE
	env.adjustment_enabled = true
	env.adjustment_saturation = GameConfig.LOOK_SATURATION
	env.adjustment_contrast = GameConfig.LOOK_CONTRAST
	env.adjustment_brightness = 1.0
	sun.shadow_opacity = GameConfig.LOOK_SHADOW_OPACITY


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


## Switches the extras on or off for the Graphics setting (0 Low, 1 Medium, 2 High).
func apply_graphics() -> void:
	var level: int = Settings.graphics
	var env := _environment
	var forward_plus := not OS.has_feature("web")
	if use_smaller_sky_radiance and env.sky != null:
		# Keep the visible procedural sky and shadows while reducing the lighting texture.
		var size := Sky.RADIANCE_SIZE_256 if level == 2 else Sky.RADIANCE_SIZE_64
		if env.sky.radiance_size != size:
			env.sky.radiance_size = size
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
	if GameConfig.STYLIZED_TEXTURES:
		# Session 55: a gentle haze that only starts far away (the near world stays crisp).
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_depth_begin = GameConfig.LOOK_FOG_BEGIN
		env.fog_depth_end = GameConfig.LOOK_FOG_END
		env.fog_density = GameConfig.LOOK_FOG_AMOUNT
	env.fog_aerial_perspective = GameConfig.HAZE_SKY_MIX
	env.fog_sky_affect = 0.0
	env.glow_enabled = level > 0 and forward_plus
	env.glow_intensity = GameConfig.GLOW_STRENGTH
	env.glow_hdr_threshold = GameConfig.GLOW_THRESHOLD
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	sun.directional_shadow_max_distance = GameConfig.SHADOW_DISTANCE[level]
	# Session 52: 4 shadow cascades on Medium and High keep shadows near the rider sharp.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if level >= 1 \
			else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits = level == 2
	# A bigger shadow map on Medium and High (not in the browser, which keeps it small).
	if not OS.has_feature("web"):
		RenderingServer.directional_shadow_atlas_set_size(GameConfig.SHADOW_MAP_SIZE[level], true)
	sun.shadow_blur = 1.0 if level == 0 else 1.5
	RenderingServer.directional_soft_shadow_filter_set_quality(
			RenderingServer.SHADOW_QUALITY_SOFT_HIGH if level == 2 else RenderingServer.SHADOW_QUALITY_SOFT_LOW)
