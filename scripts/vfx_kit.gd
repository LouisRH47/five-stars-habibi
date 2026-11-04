class_name VfxKit
extends RefCounted
## Session 68: small helpers to make particle effects (GPUParticles3D) the same way everywhere.
## The pictures are made by tools/make_vfx_textures.py (assets/textures/vfx/, ours, CC0).
## GPU particles work in the browser too (Compatibility), just without trails.

const DOT := preload("res://assets/textures/vfx/soft_dot.png")
const WISP := preload("res://assets/textures/vfx/wisp.png")
const LEAF := preload("res://assets/textures/vfx/leaf.png")
const DROPLET := preload("res://assets/textures/vfx/droplet.png")
const SPARKLE := preload("res://assets/textures/vfx/sparkle.png")

static var _quads := {}


## A flat square that always faces the camera, showing `picture` tinted by the particle colour.
## lit = true: the sun lights it (dust, steam); false: it glows (sparkles). add = add light.
static func quad(picture: Texture2D, size: float, lit := false, add := false) -> QuadMesh:
	var key := "%s|%.3f|%s|%s" % [picture.resource_path, size, lit, add]
	if _quads.has(key):
		return _quads[key]
	var look := StandardMaterial3D.new()
	look.albedo_texture = picture
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.disable_receive_shadows = true
	if add:
		look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	mesh.material = look
	_quads[key] = mesh
	return mesh


## A particle emitter with the usual settings: no shadows, a box it's drawn in, and switched
## off beyond `range_end` metres (the far ones cost nothing).
static func emitter(name: String, amount: int, lifetime: float, mesh: Mesh, stuff: ParticleProcessMaterial,
		box_size := 6.0, range_end := 50.0) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = name
	p.amount = maxi(1, amount)
	p.lifetime = lifetime
	p.draw_pass_1 = mesh
	p.process_material = stuff
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-box_size, -1.0, -box_size) * 0.5 + Vector3(0, -0.5, 0), Vector3(box_size, box_size, box_size))
	p.visibility_range_end = range_end
	p.visibility_range_end_margin = 5.0
	return p


## How particles move: the direction, spread, speed and gravity, plus a colour that fades
## from `colour` to see-through and a size that goes from `grow.x` to `grow.y` times.
static func motion(direction: Vector3, spread: float, speed: Vector2, gravity: Vector3, colour: Color,
		grow := Vector2(1, 1)) -> ParticleProcessMaterial:
	var stuff := ParticleProcessMaterial.new()
	stuff.direction = direction
	stuff.spread = spread
	stuff.initial_velocity_min = speed.x
	stuff.initial_velocity_max = speed.y
	stuff.gravity = gravity
	var fade := Gradient.new()
	fade.set_color(0, Color(colour, 0.0))
	fade.add_point(0.15, colour)
	fade.set_color(fade.get_point_count() - 1, Color(colour, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	stuff.color_ramp = fade_texture
	if grow != Vector2.ONE:
		var curve := Curve.new()
		curve.max_value = maxf(grow.x, grow.y)
		curve.add_point(Vector2(0, grow.x))
		curve.add_point(Vector2(1, grow.y))
		var curve_texture := CurveTexture.new()
		curve_texture.curve = curve
		stuff.scale_curve = curve_texture
	return stuff


## Emit from a box of this half-size round the emitter.
static func from_box(stuff: ParticleProcessMaterial, half: Vector3) -> ParticleProcessMaterial:
	stuff.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	stuff.emission_box_extents = half
	return stuff


## Emit from a flat ring (radius r) round the emitter.
static func from_ring(stuff: ParticleProcessMaterial, r: float, inner := 0.0) -> ParticleProcessMaterial:
	stuff.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	stuff.emission_ring_axis = Vector3.UP
	stuff.emission_ring_radius = r
	stuff.emission_ring_inner_radius = inner
	stuff.emission_ring_height = 0.05
	return stuff


## A one-shot burst: all particles at once, then it frees itself (keeps going while the game is
## paused, because the Delivered card pauses it).
static func one_shot(p: GPUParticles3D) -> GPUParticles3D:
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = true
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.set_meta("one_shot_done", false)
	p.ready.connect(func():
		var timer := p.get_tree().create_timer(p.lifetime + 0.3, true, false, true)
		timer.timeout.connect(func():
			if is_instance_valid(p):
				p.set_meta("one_shot_done", true)
				p.queue_free()))
	return p
