class_name VenueParts
## Building bits shared by the big walk-in places (looks pass Sessions 56 and 57): the gym,
## the C Institute, the two shops and the small drop-off buildings.
##   glass_run()   a solid glass wall along X or Z, with thin dark posts
##   arc_cap()     a flat floor or ceiling that fills the gym's rounded back
##   block()       a coloured solid box
##   glow()        a glowing (emissive) material, for lamps and screens
##   ceiling_light() a flat glowing light panel under a ceiling

const POST := Color(0.16, 0.17, 0.19)


## A solid glass wall from `a` to `b` (on the floor, along X or along Z), `height` tall,
## starting `base` metres up. Thin dark posts every `post_every` metres. Returns the glass.
## Session 91: post_colour (the C Institute has slim white frames).
static func glass_run(body: StaticBody3D, a: Vector3, b: Vector3, height: float,
		post_every := 3.0, base := 0.0, solid := true, post_colour := POST) -> MeshInstance3D:
	var along_x := absf(b.x - a.x) >= absf(b.z - a.z)
	var length := absf(b.x - a.x) if along_x else absf(b.z - a.z)
	var middle := (a + b) * 0.5 + Vector3(0, base + height * 0.5, 0)
	var size := Vector3(length, height, 0.06) if along_x else Vector3(0.06, height, length)
	var glass := RoomProps.pane(body, size, middle)
	if solid:
		LowPoly.solid_box(body, Vector3(size.x if along_x else 0.2, height, 0.2 if along_x else size.z), middle)
	var posts := maxi(1, roundi(length / post_every))
	for i in posts + 1:
		var t := float(i) / posts
		var at := a.lerp(b, t) + Vector3(0, base + height * 0.5, 0)
		LowPoly.box(body, Vector3(0.1, height, 0.14) if along_x else Vector3(0.14, height, 0.1), post_colour, at)
	return glass


## A flat floor (or ceiling) in the rounded back of a building: a half-ellipse behind the
## line z = `start`, half as wide as `half_x` and `deep` metres deep, at height y.
static func arc_cap(body: Node3D, half_x: float, start: float, deep: float, y: float, colour: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre := Vector3(0, y, start)
	for i in 24:
		var a := PI * i / 24
		var b := PI * (i + 1) / 24
		var p := Vector3(cos(a) * half_x, y, start - sin(a) * deep)
		var q := Vector3(cos(b) * half_x, y, start - sin(b) * deep)
		for corner in [centre, q, p]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corner)
	var cap := MeshInstance3D.new()
	cap.mesh = tool.commit()
	var made := LowPoly.material(colour).duplicate() as StandardMaterial3D
	made.cull_mode = BaseMaterial3D.CULL_DISABLED  # seen from above (floor) or below (ceiling)
	cap.material_override = made
	body.add_child(cap)
	return cap


## A coloured solid box.
static func block(body: StaticBody3D, size: Vector3, colour: Color, at: Vector3) -> MeshInstance3D:
	var view := LowPoly.box(body, size, colour, at)
	LowPoly.solid_box(body, size, at)
	return view


static var _glows: Dictionary = {}


## A glowing material in this colour (shared per colour and strength).
static func glow(colour: Color, energy := 2.0) -> StandardMaterial3D:
	var key := "%s|%s" % [colour, energy]
	if not _glows.has(key):
		var made := StandardMaterial3D.new()
		made.albedo_color = colour
		made.emission_enabled = true
		made.emission = colour
		made.emission_energy_multiplier = energy
		_glows[key] = made
	return _glows[key]


## A flat glowing light panel just under a ceiling at `top`.
static func ceiling_light(parent: Node3D, spot: Vector3, size: Vector2, top: float) -> MeshInstance3D:
	var panel := LowPoly.box(parent, Vector3(size.x, 0.05, size.y), Color(1, 0.97, 0.9), Vector3(spot.x, top - 0.035, spot.z))
	panel.material_override = glow(Color(1, 0.97, 0.9), 1.6)
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return panel


## A room light (OmniLight3D) that fades out far away. shadows: soft shadows on.
static func room_light(parent: Node3D, name: String, spot: Vector3, energy: float, reach: float,
		shadows := false, colour := Color(1.0, 0.92, 0.8)) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = name
	light.position = spot
	light.light_color = colour
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = shadows
	light.shadow_blur = 2.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 45.0
	light.distance_fade_shadow = 20.0
	light.distance_fade_length = 10.0
	parent.add_child(light)
	return light
