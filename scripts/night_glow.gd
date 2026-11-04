class_name NightGlow
extends Node
## Session 57: lights up the Plaza's sign bands and passage lamps after sunset.
## Sign bands (group "plaza_glow") glow more and more between the two hours in
## GameConfig.PLAZA_SIGN_GLOW_HOURS; passage lamps (group "plaza_night_light") switch on
## halfway. The letters on the signs always shine, so they're readable all day.

## 0 = daytime, 1 = fully lit. Tests read it.
var glow := -1.0
var _check_left := 0.0


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 0.5
	apply_hour(get_tree().root.get_node("GameState").clock_hours())


## Sets every sign and lamp for this in-game hour (8.0 = 08:00, 18.0 = 18:00).
func apply_hour(hour: float) -> void:
	var hours: Vector2 = GameConfig.PLAZA_SIGN_GLOW_HOURS
	var now := smoothstep(hours.x, hours.y, hour)
	if is_equal_approx(now, glow):
		return
	glow = now
	var seen := {}
	for node in get_tree().get_nodes_in_group("plaza_glow"):
		var part := node as GeometryInstance3D
		var lit := part.material_override as StandardMaterial3D if part != null else null
		if lit == null or seen.has(lit):
			continue
		seen[lit] = true
		lit.emission_energy_multiplier = glow * GameConfig.PLAZA_SIGN_GLOW_ENERGY
	for node in get_tree().get_nodes_in_group("plaza_night_light"):
		(node as Node3D).visible = glow > 0.5
