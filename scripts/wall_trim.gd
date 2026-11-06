class_name WallTrim
extends RefCounted
## Session 78: small building parts that make a flat wall look like a real building, in the
## same Arabic-modern style as the houses (scripts/villa_builder.gd). Used by the two shops
## (scripts/shop_exterior.gd) and the walls round the Plaza (scripts/plaza_walls.gd).
##   window()  a window with a deep frame, a sill and a stepped top
##   screen()  a mashrabiya: a wooden lattice screen over a dark window
##   pier()    a flat column standing out from the wall (a "pilaster")
## Everything goes into a MeshKit, so a whole building is drawn as one mesh.
## spot: the middle of the part, ON the wall's outside face. out: which way the wall faces.

const WALL := Color(0.9, 0.86, 0.76)
const PIER := Color(0.94, 0.9, 0.81)
const TRIM := Color(0.97, 0.95, 0.9)
const PLINTH := Color(0.78, 0.71, 0.6)
const GLASS := Color(0.24, 0.36, 0.42)
const RECESS := Color(0.32, 0.29, 0.25)
const SCREEN_WOOD := Color(0.79, 0.64, 0.42)
const WOOD := Color(0.5, 0.33, 0.18)
const DARK := Color(0.15, 0.16, 0.17)


## Which way a part on this wall is turned (its local +Z points out of the wall).
static func turn_for(out: Vector3) -> Basis:
	return Basis(Vector3.UP, atan2(out.x, out.z))


## A window w wide and h tall: glass in a deep frame, a cross bar, a sill and a stepped top.
static func window(kit: MeshKit, spot: Vector3, out: Vector3, w: float, h: float, stepped := true) -> void:
	var turn := turn_for(out)
	var parts := [
		[Vector3(w + 0.1, h + 0.1, 0.03), RECESS, Vector3(0, 0, 0.015)],
		[Vector3(w, h, 0.03), GLASS, Vector3(0, 0, 0.035)],
		[Vector3(0.07, h, 0.05), TRIM, Vector3(0, 0, 0.06)],
		[Vector3(w, 0.07, 0.05), TRIM, Vector3(0, h * 0.15, 0.06)],
		[Vector3(0.16, h + 0.16, 0.18), TRIM, Vector3(-w * 0.5 - 0.08, 0, 0.09)],
		[Vector3(0.16, h + 0.16, 0.18), TRIM, Vector3(w * 0.5 + 0.08, 0, 0.09)],
		[Vector3(w + 0.5, 0.12, 0.3), TRIM, Vector3(0, -h * 0.5 - 0.06, 0.15)],
		[Vector3(w + 0.32, 0.16, 0.2), TRIM, Vector3(0, h * 0.5 + 0.08, 0.1)]]
	if stepped:  # the stepped top, like the crown on old Gulf houses
		parts.append([Vector3(w * 0.62, 0.16, 0.2), TRIM, Vector3(0, h * 0.5 + 0.24, 0.1)])
		parts.append([Vector3(w * 0.28, 0.16, 0.2), TRIM, Vector3(0, h * 0.5 + 0.4, 0.1)])
	for part: Array in parts:
		kit.box(part[0], part[1], spot + turn * (part[2] as Vector3), turn)


## A mashrabiya: a wooden lattice screen (4 by 4 bars) in a light frame over a dark window.
static func screen(kit: MeshKit, spot: Vector3, out: Vector3, w: float, h: float) -> void:
	var turn := turn_for(out)
	kit.box(Vector3(w, h, 0.03), RECESS, spot + turn * Vector3(0, 0, 0.015), turn)
	for i in range(1, 5):
		var x := -w * 0.5 + w * i / 5.0
		var y := -h * 0.5 + h * i / 5.0
		kit.box(Vector3(0.06, h, 0.06), SCREEN_WOOD, spot + turn * Vector3(x, 0, 0.06), turn)
		kit.box(Vector3(w, 0.06, 0.06), SCREEN_WOOD, spot + turn * Vector3(0, y, 0.06), turn)
	for y in [-1.0, 1.0]:
		kit.box(Vector3(w + 0.24, 0.12, 0.16), TRIM, spot + turn * Vector3(0, y * (h * 0.5 + 0.06), 0.08), turn)
	for x in [-1.0, 1.0]:
		kit.box(Vector3(0.12, h, 0.14), TRIM, spot + turn * Vector3(x * (w * 0.5 + 0.06), 0, 0.07), turn)


## A mashrabiya bay: a wooden box `deep` metres out from the wall with a lattice front,
## a light cap and stepped brackets underneath (like the bay windows on old Gulf houses).
static func bay(kit: MeshKit, spot: Vector3, out: Vector3, w: float, h: float, deep: float) -> void:
	var turn := turn_for(out)
	var wood := SCREEN_WOOD.darkened(0.2)
	kit.box(Vector3(w, h, deep), wood, spot + turn * Vector3(0, 0, deep * 0.5), turn)
	screen(kit, spot + turn * Vector3(0, 0, deep), out, w - 0.3, h - 0.3)
	kit.box(Vector3(w + 0.3, 0.16, deep + 0.2), TRIM, spot + turn * Vector3(0, h * 0.5 + 0.08, deep * 0.5 + 0.1), turn)
	kit.box(Vector3(w + 0.2, 0.14, deep + 0.1), TRIM, spot + turn * Vector3(0, -h * 0.5 - 0.07, deep * 0.5 + 0.05), turn)
	kit.box(Vector3(w * 0.7, 0.16, deep * 0.75), TRIM, spot + turn * Vector3(0, -h * 0.5 - 0.22, deep * 0.375), turn)
	kit.box(Vector3(w * 0.4, 0.16, deep * 0.45), TRIM, spot + turn * Vector3(0, -h * 0.5 - 0.38, deep * 0.225), turn)


## A striped cloth awning over a window: `top` is where it meets the wall, it slopes down
## and out. Stripes in `colour` and white, side by side (not stacked, so no flicker).
static func awning(kit: MeshKit, top: Vector3, out: Vector3, w: float, colour: Color) -> void:
	var turn := turn_for(out)
	var reach := 0.95
	var drop := 0.4
	var tilt := turn * Basis(Vector3.RIGHT, atan2(drop, reach))
	var slope := Vector2(reach, drop).length()
	var stripes := 7
	for i in stripes:
		var x := -w * 0.5 + w * (i + 0.5) / stripes
		var c := colour if i % 2 == 0 else TRIM
		kit.box(Vector3(w / stripes + 0.002, 0.05, slope), c, top + turn * Vector3(x, -drop * 0.5, reach * 0.5), tilt)
		kit.box(Vector3(w / stripes + 0.002, 0.2, 0.04), c, top + turn * Vector3(x, -drop - 0.1, reach + 0.01), turn)


## A flat column on the wall, w wide, from the ground up to `top`, standing `stick` out.
## It gets a little capital (a wider band) at the top.
static func pier(kit: MeshKit, spot: Vector3, out: Vector3, w: float, top: float, stick: float) -> void:
	var turn := turn_for(out)
	var base := Vector3(spot.x, 0, spot.z)
	kit.box(Vector3(w, top, stick + 0.04), PIER, base + turn * Vector3(0, top * 0.5, stick * 0.5 - 0.02), turn)
	kit.box(Vector3(w + 0.16, 0.22, stick + 0.1), TRIM, base + turn * Vector3(0, top - 0.11, stick * 0.5 + 0.01), turn)
	kit.box(Vector3(w + 0.12, 0.5, stick + 0.08), PLINTH, base + turn * Vector3(0, 0.25, stick * 0.5), turn)


## The solid shape for a pier made by pier() (the walls only turn by 90°).
static func pier_shape(body: StaticBody3D, spot: Vector3, out: Vector3, w: float, top: float, stick: float) -> void:
	var size := Vector3(stick + 0.04, top, w) if absf(out.x) > 0.5 else Vector3(w, top, stick + 0.04)
	LowPoly.solid_box(body, size, Vector3(spot.x, top * 0.5, spot.z) + out * (stick * 0.5 - 0.02))
