extends RefCounted
## Session 67: our own cartoon sky (assets/shaders/sky_stylized.gdshader), with soft clouds
## and a glowing sun disc. scripts/sun_cycle.gd swaps it in when GameConfig.SKY_STYLIZED is
## true and feeds it the colours for the time of day. The old ProceduralSkyMaterial is kept
## (on the Sky's "old_sky" meta), so SKY_STYLIZED = false brings the old sky straight back.
## Clouds: off on Low (the browser and iPad), on for Medium and High.

const SHADER := preload("res://assets/shaders/sky_stylized.gdshader")


## Makes the new sky material, using the old sky's ground colours.
static func make_material(old: ProceduralSkyMaterial) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	if old != null:
		mat.set_shader_parameter("ground_bottom", old.ground_bottom_color)
		mat.set_shader_parameter("ground_horizon", old.ground_horizon_color)
		mat.set_shader_parameter("sky_curve", old.sky_curve)
		mat.set_shader_parameter("ground_curve", old.ground_curve)
		mat.set_shader_parameter("energy", old.sky_energy_multiplier)
	mat.set_shader_parameter("sun_size", GameConfig.SKY_SUN_SIZE)
	mat.set_shader_parameter("halo_size", GameConfig.SKY_HALO_SIZE)
	mat.set_shader_parameter("halo_strength", GameConfig.SKY_HALO_STRENGTH)
	mat.set_shader_parameter("disc_energy", GameConfig.SKY_DISC_ENERGY)
	mat.set_shader_parameter("cloud_cover", GameConfig.CLOUD_COVER)
	mat.set_shader_parameter("cloud_scale", GameConfig.CLOUD_SCALE)
	mat.set_shader_parameter("cloud_opacity", GameConfig.CLOUD_OPACITY)
	return mat


## Clouds only from Medium up (GameConfig.CLOUDS_FROM_LEVEL).
static func set_level(mat: ShaderMaterial, level: int) -> void:
	mat.set_shader_parameter("clouds_on", level >= GameConfig.CLOUDS_FROM_LEVEL)


## The sky colours for this moment of the day (look = a blended line of LIGHT_KEYS).
static func set_colours(mat: ShaderMaterial, look: Dictionary, ground_horizon: Color, hour: float) -> void:
	mat.set_shader_parameter("top_color", look["top"])
	mat.set_shader_parameter("horizon_color", look["horizon"])
	mat.set_shader_parameter("ground_horizon", ground_horizon)
	mat.set_shader_parameter("cloud_light", cloud_light(look))
	mat.set_shader_parameter("cloud_shade", cloud_shade(look))
	mat.set_shader_parameter("cloud_shift", cloud_shift(hour))


## How warm the light is: 0 with the sun high (noon), 1 with the sun low (early and late).
static func warmth(look: Dictionary) -> float:
	return clampf(inverse_lerp(GameConfig.CLOUD_WARM_HEIGHTS.y, GameConfig.CLOUD_WARM_HEIGHTS.x, look["height"]), 0.0, 1.0)


## The sunny side of the clouds: white at noon, peach in the morning, gold at sunset.
static func cloud_light(look: Dictionary) -> Color:
	var sun: Color = look["sun"]
	return Color.WHITE.lerp(sun.lerp(Color.WHITE, 0.3), warmth(look))


## The shady bottoms: soft blue-grey at noon, pink with the sun low.
static func cloud_shade(look: Dictionary) -> Color:
	return GameConfig.CLOUD_SHADE_NOON.lerp(GameConfig.CLOUD_SHADE_LOW, warmth(look))


## The clouds drift slowly with the game clock (the same way as the cloud shadows).
static func cloud_shift(hour: float) -> Vector2:
	return GameConfig.CLOUD_WIND * hour
