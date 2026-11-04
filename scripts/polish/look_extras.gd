extends RefCounted
## Session 67 (polish pass, "Sky, light and colour"): the look extras that live in the game
## world. scripts/polish_hooks.gd calls attach(world) once when the world opens.
## - a soft vignette (darker screen corners) under the HUD (GameConfig.VIGNETTE_STRENGTH, 0 = off)
## - light shafts through the shop glass (scripts/light_shafts.gd, Medium and High)
## - thin comic outlines (scripts/outline_look.gd, only with Settings.outlines on)
## - cloud shadows on the ground (scripts/cloud_shadows.gd, only with GameConfig.CLOUD_SHADOWS)
## The sky, colour grade, texture filtering and bounce light are in scripts/sun_cycle.gd.

const VIGNETTE_SHADER := preload("res://assets/shaders/screen_grade.gdshader")
const VIGNETTE_LAYER := -1  # over the 3D world, under the HUD (layer 0 and up)


static func attach(world: Node) -> void:
	if GameConfig.VIGNETTE_STRENGTH > 0.0:
		world.add_child(make_vignette(GameConfig.VIGNETTE_STRENGTH))
	var sun := world.get_node_or_null("Sun") as DirectionalLight3D
	if GameConfig.LIGHT_SHAFTS_ON and sun != null:
		var shafts: Node3D = load("res://scripts/light_shafts.gd").new()
		shafts.name = "LightShafts"
		world.add_child(shafts)
		shafts.setup(world, sun)
	var outlines: MeshInstance3D = load("res://scripts/outline_look.gd").new()
	outlines.name = "Outlines"
	world.add_child(outlines)
	if GameConfig.CLOUD_SHADOWS:
		var shadows: Node3D = load("res://scripts/cloud_shadows.gd").new()
		shadows.name = "CloudShadows"
		world.add_child(shadows)


## A see-through layer with darker corners. strength 0.22 = the corners 22% darker.
static func make_vignette(strength: float) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = VIGNETTE_LAYER
	var rect := ColorRect.new()
	rect.name = "Shade"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	mat.set_shader_parameter("strength", strength)
	rect.material = mat
	layer.add_child(rect)
	return layer
