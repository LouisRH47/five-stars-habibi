class_name SunsetLights
extends Node
## Looks pass Session 58: lights that come on at sunset with the game clock: the street
## lamps, the Plaza string lights and the juice kiosk. The glowing parts all share a few
## materials (made here); this fades their glow in from GameConfig.LIGHTS_ON_HOUR, and on
## Medium and High also turns on a few real lights in the Plaza.
## One SunsetLights node per builder that has lamps; each registers its own parts.

## Warm bulbs (string lights) and street lamp heads.
static var bulb_glow: StandardMaterial3D
static var lamp_glow: StandardMaterial3D

## Real lights to switch on (Medium and High only).
var lights: Array[Light3D] = []
## 0 = off (daytime), 1 = fully on.
var amount := -1.0
var _check_left := 0.0


static func bulb_material() -> StandardMaterial3D:
	if bulb_glow == null:
		bulb_glow = _made(Color(1.0, 0.83, 0.5))
	return bulb_glow


static func lamp_material() -> StandardMaterial3D:
	if lamp_glow == null:
		lamp_glow = _made(Color(1.0, 0.93, 0.78))
	return lamp_glow


static func _made(colour: Color) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = colour.darkened(0.35)
	made.emission_enabled = true
	made.emission = colour
	made.emission_energy_multiplier = 0.0
	made.roughness = 0.4
	return made


## How much the lights are on at this hour (0 to 1).
static func amount_at(hour: float) -> float:
	var on: float = GameConfig.LIGHTS_ON_HOUR
	return smoothstep(on - GameConfig.LIGHTS_FADE_HOURS * 0.5, on + GameConfig.LIGHTS_FADE_HOURS * 0.5, hour)


func _ready() -> void:
	add_to_group("graphics")
	apply_hour(GameConfig.SHIFT_START_HOUR)


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 0.5
	var state := get_node_or_null("/root/GameState")
	if state != null:
		apply_hour(state.clock_hours())


## Sets every glow and light for this hour.
func apply_hour(hour: float) -> void:
	var now := amount_at(hour)
	if is_equal_approx(now, amount):
		return
	amount = now
	bulb_material().emission_energy_multiplier = now * GameConfig.LIGHTS_BULB_ENERGY
	lamp_material().emission_energy_multiplier = now * GameConfig.LIGHTS_LAMP_ENERGY
	bulb_material().albedo_color = Color(1.0, 0.83, 0.5).darkened(0.35 * (1.0 - now))
	lamp_material().albedo_color = Color(1.0, 0.93, 0.78).darkened(0.35 * (1.0 - now))
	_apply_lights()


## Settings.apply() calls this when the Graphics setting changes.
func apply_graphics() -> void:
	_apply_lights()


func _apply_lights() -> void:
	var show := amount > 0.01 and Settings.graphics >= 1
	for light in lights:
		if is_instance_valid(light):
			light.visible = show
			light.light_energy = light.get_meta("full_energy", 1.0) * maxf(amount, 0.0)
