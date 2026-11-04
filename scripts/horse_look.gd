class_name HorseLook
extends RefCounted
## Session 63: better-looking horses (Louis: "horses: better textures"). Rounder body, neck
## and head, a long mane and a full tail, darker lower legs and hooves, a white blaze on the
## face, a saddle on a saddle cloth with stirrups, and a bridle with reins to the rider's
## hands. The coat has a soft hair texture (made from noise, no picture files needed).
## Coat colours: "brown" (bay: brown with a black mane), "chestnut" (copper), "grey" (dappled)
## and "black". LifeLooks.horse() uses this when GameConfig.HORSE_LOOK_V2 is on; it returns
## the same [model, rider] with the legs kept for the trot animation, like the old horse.

const SADDLE := Color(0.33, 0.19, 0.1)
const CLOTH := Color(0.15, 0.22, 0.42)
const STRAP := Color(0.2, 0.12, 0.07)
const METAL := Color(0.75, 0.75, 0.78)
const HOOF := Color(0.18, 0.15, 0.13)

static var _coat_material: StandardMaterial3D


## Which coat a data colour is, if the data doesn't say.
static func coat_of(colour: Color) -> String:
	if colour.get_luminance() > 0.5:
		return "grey"
	if colour.get_luminance() < 0.12:
		return "black"
	return "chestnut" if colour.r > 0.5 else "brown"


## [body colour, mane and tail, lower legs] for a coat.
static func palette(coat: String, colour: Color) -> Array:
	match coat:
		"grey":
			return [colour, colour.darkened(0.45), colour.darkened(0.3)]
		"black":
			return [Color(0.1, 0.09, 0.09), Color(0.05, 0.05, 0.05), Color(0.08, 0.07, 0.07)]
		"chestnut":
			return [colour, colour.lightened(0.12), colour.darkened(0.2)]
	return [colour, Color(0.07, 0.06, 0.06), Color(0.1, 0.08, 0.07)]


static func build(colour: Color, coat := "") -> Array:
	if coat == "":
		coat = coat_of(colour)
	var colours := palette(coat, colour)
	var body: Color = colours[0]
	var hair: Color = colours[1]
	var low: Color = colours[2]
	var kit := MeshKit.new()
	# Body: a barrel with a rounded chest and rump.
	kit.box(Vector3(0.58, 0.62, 1.3), body, Vector3(0, 1.36, 0))
	kit.ball(0.36, body, Vector3(0, 1.4, -0.62), 1.0)                 # chest
	kit.ball(0.37, body, Vector3(0, 1.42, 0.6), 1.0)                  # rump
	kit.ball(0.3, body.darkened(0.05), Vector3(0, 1.18, 0), 0.7)      # belly
	# Neck and head (the horse faces -Z).
	var neck := Basis(Vector3.RIGHT, -0.55)
	kit.box(Vector3(0.28, 0.85, 0.42), body, Vector3(0, 1.85, -0.88), neck)
	kit.ball(0.2, body, Vector3(0, 2.18, -1.08), 1.0)                 # poll
	var face := Basis(Vector3.RIGHT, 0.45)
	kit.box(Vector3(0.24, 0.26, 0.62), body, Vector3(0, 2.1, -1.32), face)
	kit.box(Vector3(0.2, 0.2, 0.18), body.darkened(0.15), Vector3(0, 1.93, -1.6), face)   # muzzle
	kit.box(Vector3(0.07, 0.02, 0.4), Color(0.95, 0.93, 0.9), Vector3(0, 2.2, -1.36), face)   # white blaze
	for x in [-0.08, 0.08]:
		kit.box(Vector3(0.06, 0.16, 0.05), body.darkened(0.1), Vector3(x, 2.4, -1.12))     # ears
		kit.ball(0.03, Color(0.05, 0.05, 0.05), Vector3(x * 1.55, 2.16, -1.28), 1.0)       # eyes
	# Mane: a row of hair tufts down the neck, and a forelock.
	for i in 6:
		var t := float(i) / 5.0
		kit.box(Vector3(0.1, 0.22, 0.16), hair, Vector3(0, 2.22 - t * 0.55, -1.05 + t * 0.38), neck)
	kit.box(Vector3(0.12, 0.14, 0.06), hair, Vector3(0, 2.32, -1.2))
	# Tail: thick at the top, hanging and swishing out a little.
	kit.box(Vector3(0.13, 0.25, 0.16), hair, Vector3(0, 1.62, 0.95), Basis(Vector3.RIGHT, 0.7))
	kit.box(Vector3(0.16, 0.7, 0.12), hair, Vector3(0, 1.22, 1.08), Basis(Vector3.RIGHT, 0.2))
	kit.box(Vector3(0.12, 0.25, 0.1), hair, Vector3(0, 0.82, 1.12))
	# Tack: saddle cloth, saddle with a raised back, stirrups, girth and a bridle.
	kit.box(Vector3(0.66, 0.36, 0.72), CLOTH, Vector3(0, 1.58, 0.05))
	kit.box(Vector3(0.5, 0.12, 0.6), SADDLE, Vector3(0, 1.73, 0.05))
	kit.box(Vector3(0.44, 0.12, 0.12), SADDLE, Vector3(0, 1.8, 0.32))
	kit.box(Vector3(0.36, 0.1, 0.1), SADDLE, Vector3(0, 1.79, -0.22))
	kit.box(Vector3(0.62, 0.08, 0.1), STRAP, Vector3(0, 1.08, -0.12))  # girth under the belly
	for x in [-0.34, 0.34]:
		kit.box(Vector3(0.025, 0.42, 0.04), STRAP, Vector3(x, 1.45, -0.05))
		kit.box(Vector3(0.1, 0.03, 0.08), METAL, Vector3(x, 1.22, -0.05))   # stirrup
		kit.box(Vector3(0.02, 0.05, 0.4), STRAP, Vector3(x * 0.38, 2.12, -1.36), face)   # cheek straps
	kit.box(Vector3(0.26, 0.04, 0.04), STRAP, Vector3(0, 1.98, -1.5), face)                # noseband
	for x in [-0.12, 0.12]:
		kit.box(Vector3(0.02, 0.02, 0.85), STRAP, Vector3(x, 1.92, -1.05), Basis(Vector3.RIGHT, -0.15))   # reins
	var model := Node3D.new()
	var view := kit.finish("Horse")
	view.material_override = coat_material()
	model.add_child(view)
	var legs: Array[Node3D] = []
	for z in [-0.55, 0.55]:
		for x in [-0.18, 0.18]:
			var hip := Node3D.new()
			hip.position = Vector3(x, 1.12, z)
			model.add_child(hip)
			var leg := MeshKit.new()
			leg.box(Vector3(0.16, 0.5, 0.18), body, Vector3(0, -0.22, 0))       # upper leg
			leg.box(Vector3(0.11, 0.5, 0.11), low, Vector3(0, -0.7, 0))         # lower leg
			leg.ball(0.075, low, Vector3(0, -0.47, 0.01), 1.0)                   # knee
			leg.box(Vector3(0.14, 0.12, 0.16), HOOF, Vector3(0, -1.06, -0.01))   # hoof
			var drawn := leg.finish("Leg")
			drawn.material_override = coat_material()
			hip.add_child(drawn)
			legs.append(hip)
	model.set_meta("legs", legs)
	model.set_meta("coat", coat)
	var rider := PeopleLooks.horse_rider()
	LifeLooks._sit(rider, model, Vector3(0, 1.8, 0.05), [Vector3(-0.36, 1.22, -0.1), Vector3(0.36, 1.22, -0.1)],
			[Vector3(-0.12, 1.95, -0.5), Vector3(0.12, 1.95, -0.5)], 8.0)
	return [model, rider]


## The coat material: the part colours times a soft, stretched noise, so the coat has hair
## and dapples instead of flat paint. One shared material for every horse.
static func coat_material() -> StandardMaterial3D:
	if _coat_material != null:
		return _coat_material
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	noise.fractal_octaves = 2
	var picture := NoiseTexture2D.new()
	picture.noise = noise
	picture.width = 128
	picture.height = 128
	picture.seamless = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.8, 0.8, 0.8))
	ramp.set_color(1, Color(1.0, 1.0, 1.0))
	picture.color_ramp = ramp
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.albedo_texture = picture
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(2.5, 2.5, 2.5)
	mat.roughness = 0.7
	_coat_material = mat
	return mat
