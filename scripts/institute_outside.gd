class_name InstituteOutside
extends RefCounted
## Session 91: the C Institute's modern outside (the big glass stays):
##   a thin white flat roof that reaches out past the walls
##   a sun shade (brise-soleil) over the glass front: white slats in a frame under the roof
##     edge, and a slatted shelf between the two storeys
##   vertical white fins on the sunny side (the south end, which faces the spine road;
##     the sun is in the south at noon in Al Sarab)
##   lit signs (Arabic on top, English below) on the front and on the south end: glowing
##     white light boxes with teal letters, so they shine at sunset
## Room metres: front (+Z) faces the spine (east); the south end is -X.

const WHITE := Color(0.97, 0.97, 0.96)
const TEAL := Color(0.1, 0.5, 0.56)
const DARK := Color(0.2, 0.22, 0.24)
const LIGHT_BOX := Color(1.0, 0.98, 0.93)
const ROOF_THICK := 0.36


static func build(body: StaticBody3D, place: Dictionary, size: Vector3) -> void:
	var outside := Node3D.new()
	outside.name = "Outside"
	body.add_child(outside)
	_roof(outside, size)
	_sun_shade(outside, size)
	_fins(outside, size)
	var arabic: String = place.get("arabic", "معهد سي")
	var english: String = place.get("name", "C Institute")
	# The signs stand on the roof's edge: one over the front, one over the south end.
	var roof_top := size.y + ROOF_THICK + 0.3
	var front := lit_sign(body, arabic, english, Vector2(13.0, 2.4))
	front.name = "BilingualSign"
	front.position = Vector3(0, roof_top + 1.3, size.z * 0.5 + GameConfig.INSTITUTE_SHADE_DEPTH - 0.6)
	var side := lit_sign(body, arabic, english, Vector2(10.0, 2.0))
	side.name = "SideSign"
	side.position = Vector3(-size.x * 0.5 - 0.4, roof_top + 1.1, 0)
	side.rotation_degrees.y = -90.0  # reads from the south (-X)


## The flat roof: a thin white slab that reaches out past the walls, on a dark band
## (a shadow line) on top of the walls, so it looks like it floats.
static func _roof(outside: Node3D, size: Vector3) -> void:
	var shade := GameConfig.INSTITUTE_SHADE_DEPTH
	var reach := 1.2
	var wide := size.x + reach * 2.0
	var deep := size.z + reach + shade
	var middle_z := (shade - reach) * 0.5
	var roof := LowPoly.box(outside, Vector3(wide, ROOF_THICK, deep), WHITE, Vector3(0, size.y + 0.3 + ROOF_THICK * 0.5, middle_z))
	roof.name = "FlatRoof"
	LowPoly.box(outside, Vector3(size.x + 0.1, 0.3, size.z + 0.1), DARK, Vector3(0, size.y + 0.15, 0))


## The sun shade over the front glass: slats under the roof's front edge, and a slatted
## shelf sticking out between the two storeys.
static func _sun_shade(outside: Node3D, size: Vector3) -> void:
	var shade := Node3D.new()
	shade.name = "BriseSoleil"
	outside.add_child(shade)
	var front := size.z * 0.5
	var depth := GameConfig.INSTITUTE_SHADE_DEPTH
	var width := size.x + 2.0
	# Under the roof: white slats across the front, every 0.4 m, in a white frame.
	var y := size.y + 0.05
	var z := front + 0.3
	var slats := 0
	while z < front + depth - 0.1:
		LowPoly.box(shade, Vector3(width, 0.08, 0.16), WHITE, Vector3(0, y, z))
		z += 0.4
		slats += 1
	for x: float in [-width * 0.5, width * 0.5]:
		LowPoly.box(shade, Vector3(0.2, 0.3, depth), WHITE, Vector3(x, y, front + depth * 0.5))
	# The shelf between the storeys: a frame with slats, held on slim brackets.
	var shelf := 1.6
	var low := InstituteRoom.FLOOR2 + 0.1
	LowPoly.box(shade, Vector3(size.x, 0.14, 0.14), WHITE, Vector3(0, low, front + shelf))
	z = front + 0.35
	while z < front + shelf:
		LowPoly.box(shade, Vector3(size.x, 0.05, 0.14), WHITE, Vector3(0, low, z))
		z += 0.3
		slats += 1
	var x := -size.x * 0.5 + 0.2
	while x <= size.x * 0.5:
		if absf(x) > RestaurantRoom.DOOR_HALF + 0.5:  # not in front of the doors
			LowPoly.box(shade, Vector3(0.08, 0.2, shelf), WHITE, Vector3(x, low - 0.03, front + shelf * 0.5 + 0.05))
		x += 3.8
	shade.set_meta("slats", slats)


## Tall white fins standing out from the south end wall, top to bottom.
static func _fins(outside: Node3D, size: Vector3) -> void:
	var fins := Node3D.new()
	fins.name = "SunFins"
	outside.add_child(fins)
	var depth := GameConfig.INSTITUTE_FIN_DEPTH
	var x := -size.x * 0.5 - 0.15 - depth * 0.5
	var z := -size.z * 0.5 + 0.9
	var count := 0
	while z < size.z * 0.5 - 0.5:
		LowPoly.box(fins, Vector3(depth, size.y - 0.3, 0.14), WHITE, Vector3(x, (size.y - 0.3) * 0.5 + 0.15, z))
		z += GameConfig.INSTITUTE_FIN_GAP
		count += 1
	# The end wall behind the fins is a warm sand colour, so the white fins stand out.
	LowPoly.box(fins, Vector3(0.04, size.y - 0.4, size.z - 0.4), Color(0.86, 0.78, 0.64), Vector3(-size.x * 0.5 - 0.17, size.y * 0.5, 0))
	fins.set_meta("fins", count)


## A lit sign: a glowing white light box with teal Arabic (top) and English (below) on it.
## size: the box's width and height in metres. It reads from its +Z side. Returns it.
static func lit_sign(body: Node3D, arabic: String, english: String, size: Vector2) -> Node3D:
	var sign := Node3D.new()
	body.add_child(sign)
	var frame := LowPoly.box(sign, Vector3(size.x + 0.2, size.y + 0.2, 0.2), DARK, Vector3(0, 0, -0.1))
	frame.name = "SignFrame"
	var glow := LowPoly.box(sign, Vector3(size.x, size.y, 0.04), LIGHT_BOX, Vector3(0, 0, 0.02))
	glow.name = "LightBox"
	glow.material_override = VenueParts.glow(LIGHT_BOX, GameConfig.INSTITUTE_SIGN_GLOW)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var font := SignText.fit_size(arabic, english, int(size.y * 75.0), size.x - 1.0)
	var face := SignText.make_face(arabic, english, font, TEAL)
	face.position = Vector3(0, 0, 0.05)
	sign.add_child(face)
	return sign
