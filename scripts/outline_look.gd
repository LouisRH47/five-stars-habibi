extends MeshInstance3D
## Session 67: thin dark-teal comic outlines round buildings, props and people (polish plan
## L8). Off by default: only drawn when Settings.outlines is on (Louis decides). A full-screen
## square with assets/shaders/outline_post.gdshader, which finds edges from the depth only, so
## it works in the browser too. Added by scripts/polish/look_extras.gd.

const SHADER := preload("res://assets/shaders/outline_post.gdshader")


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mesh = quad
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.render_priority = 100  # after the other see-through things
	mat.set_shader_parameter("line_colour", GameConfig.OUTLINE_COLOUR)
	mat.set_shader_parameter("line_alpha", GameConfig.OUTLINE_ALPHA)
	mat.set_shader_parameter("jump", GameConfig.OUTLINE_DEPTH_JUMP)
	mat.set_shader_parameter("fade", GameConfig.OUTLINE_FADE)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# The shader puts it over the whole screen, so it must never be skipped as "off screen".
	custom_aabb = AABB(Vector3.ONE * -100000.0, Vector3.ONE * 200000.0)
	add_to_group("graphics")  # Settings.apply() calls apply_graphics()
	apply_graphics()


func apply_graphics() -> void:
	visible = Settings.outlines
