class_name WaterLook
extends RefCounted
## Session 81: one place that makes the water materials, so every bit of water in the game
## looks the same way (assets/shaders/water.gdshader): the stream and the fountain, the
## ponds, and the pools (with their tiled floor and lane lines seen through the water).
## Colours and speeds are in GameConfig (Session 81 block).

const SHADER := preload("res://assets/shaders/water.gdshader")

static var _cache := {}


## The stream (and the Plaza fountain): the old moving ripples, with sun sparkle.
static func stream() -> ShaderMaterial:
	return _make("stream", GameConfig.STREAM_WATER_COLOUR, {})


## The ponds the stream runs into: a little darker and greener, calmer ripples.
static func pond() -> ShaderMaterial:
	return _make("pond", GameConfig.POND_WATER_COLOUR, {"wave_tilt": GameConfig.WATER_WAVE_TILT * 0.6})


## A swimming pool. lane_spacing: metres between the dark lane lines on the floor (0 = none),
## lane_origin: the pool's edge the lanes are counted from, along_x: lanes run along x.
static func pool(lane_spacing := 0.0, lane_origin := 0.0, along_x := true) -> ShaderMaterial:
	var key := "pool_%.2f_%.2f_%s" % [lane_spacing, lane_origin, along_x]
	return _make(key, GameConfig.POOL_WATER_COLOUR, {"pool_floor": 1.0, "lane_spacing": lane_spacing,
			"lane_origin": lane_origin, "lanes_along_x": along_x, "floor_depth": GameConfig.POOL_FLOOR_DEPTH})


## The shallow kids' area in the community pool: lighter, the floor looks close.
static func kids_pool() -> ShaderMaterial:
	return _make("kids", GameConfig.POOL_WATER_COLOUR.lightened(0.25), {"pool_floor": 1.0,
			"floor_depth": GameConfig.POOL_FLOOR_DEPTH * 0.3, "tile_size": 0.2})


static func _make(key: String, colour: Color, extra: Dictionary) -> ShaderMaterial:
	if _cache.has(key):
		return _cache[key]
	var water := ShaderMaterial.new()
	water.shader = SHADER
	water.set_shader_parameter("water_colour", colour)
	water.set_shader_parameter("flow_speed", GameConfig.WATER_FLOW_SPEED)
	water.set_shader_parameter("wave_tilt", GameConfig.WATER_WAVE_TILT)
	for name: String in extra:
		water.set_shader_parameter(name, extra[name])
	_cache[key] = water
	return water
