class_name ShopExterior
extends RefCounted
## Session 78: the outside of Pedal Point Bikes and Dune Drip, so they look like real
## buildings and not plain boxes. ShopInterior (scripts/shop_interior.gd) still builds the
## walls, the glass front and everything inside; this adds round the outside:
##   - a shaded arcade (columns with pointed arches) along the front: scripts/shop_arcade.gd
##   - a stepped roofline, a wind tower, solar panels: scripts/shop_roof.gd
##   - flat columns, window bays with striped awnings, mashrabiya screens and bays and a band
##     in the shop's colour on the side and back walls, and a back door
##   - the things outside (bike rack, pump stand, planters, bench): scripts/shop_yard.gd
## Everything you see is merged into ONE mesh (MeshKit), so it's cheap to draw. What you can
## bump into (columns, piers, the rack, planters, bench) gets real collision; the arcade is
## open at the front and both ends, so you can walk or ride through it.
## Local axes like the shop: +Z is the front, x runs across it.

var kit := MeshKit.new()
var room: StaticBody3D
var tint := Color.WHITE
var sx := 10.15   # the outside face of the side walls (x)
var fz := 9.15    # the outside face of the front (z)
var bz := -9.15   # the outside face of the back (z)
var top := 8.0    # the top of the walls
## Short words for what was built, for the smoke test (room meta "exterior").
var parts: PackedStringArray = []
var columns := 0


## Adds the outside to a shop room made by ShopInterior. size: the shop's size.
static func dress(shop: StaticBody3D, place: Dictionary, size: Vector3, colour: Color) -> void:
	var maker := ShopExterior.new()
	maker.room = shop
	maker.tint = colour
	maker.sx = size.x * 0.5 + 0.15
	maker.fz = size.z * 0.5 + 0.15
	maker.bz = -maker.fz
	maker.top = size.y
	maker._walls()
	ShopRoof.build(maker)
	ShopArcade.build(maker)
	ShopYard.build(maker, place["id"] == "bikes")
	shop.add_child(maker.kit.finish("Exterior"))
	shop.set_meta("exterior", maker.parts)
	shop.set_meta("exterior_parts", maker.kit.part_count())
	shop.set_meta("arcade_columns", maker.columns)


func box(size: Vector3, colour: Color, spot: Vector3, turn := Basis()) -> void:
	kit.box(size, colour, spot, turn)


## A visible box that you also bump into.
func block(size: Vector3, colour: Color, spot: Vector3) -> void:
	kit.box(size, colour, spot)
	LowPoly.solid_box(room, size, spot)


## A band round the sides and back, from y0 to y1, standing `stick` out of the wall.
func _wrap(y0: float, y1: float, stick: float, colour: Color) -> void:
	var h := y1 - y0
	var mid := (y0 + y1) * 0.5
	for s in [-1.0, 1.0]:
		box(Vector3(stick + 0.04, h, fz - bz + stick * 2), colour, Vector3(s * (sx + stick * 0.5 - 0.02), mid, 0))
	box(Vector3(sx * 2 + stick * 2, h, stick + 0.04), colour, Vector3(0, mid, bz - stick * 0.5 + 0.02))


# --- The walls ---

func _walls() -> void:
	_wrap(0.0, 0.55, 0.08, WallTrim.PLINTH)
	_wrap(4.4, 4.9, 0.06, tint)  # the band in the shop's colour
	_wrap(top - 0.45, top - 0.2, 0.22, WallTrim.TRIM)  # the cornice under the roof
	_wrap(top - 0.2, top, 0.12, WallTrim.TRIM)
	parts.append_array(["colour_band", "cornice"])
	var pier_top := top - 0.45
	for s in [-1.0, 1.0]:
		var out := Vector3(s, 0, 0)
		for z in [-3.0, 3.0]:
			_pier(Vector3(s * sx, 0, z), out, pier_top)
		for z in [-6.0, 0.0, 6.0]:
			WallTrim.window(kit, Vector3(s * sx, 2.2, z), out, 1.5, 2.2)
			WallTrim.awning(kit, Vector3(s * sx, 4.05, z), out, 2.2, tint)
			if z == 0.0:  # the middle one sticks out: a wooden mashrabiya bay
				WallTrim.bay(kit, Vector3(s * sx, 6.3, z), out, 1.8, 1.7, 0.55)
			else:
				WallTrim.screen(kit, Vector3(s * sx, 6.3, z), out, 1.2, 1.3)
		# Thick corner piers, front and back.
		for z in [fz - 0.1, bz + 0.1]:
			block(Vector3(0.6, pier_top, 0.6), WallTrim.PIER, Vector3(s * (sx - 0.1), pier_top * 0.5, z))
			box(Vector3(0.76, 0.22, 0.76), WallTrim.TRIM, Vector3(s * (sx - 0.1), pier_top - 0.11, z))
	var back := Vector3(0, 0, -1)
	for x in [-3.4, 3.4]:
		_pier(Vector3(x, 0, bz), back, pier_top)
	for x in [-6.8, 6.8]:
		WallTrim.window(kit, Vector3(x, 2.2, bz), back, 1.5, 2.2)
		WallTrim.screen(kit, Vector3(x, 6.3, bz), back, 1.2, 1.3)
	WallTrim.bay(kit, Vector3(0, 6.3, bz), back, 1.8, 1.7, 0.55)
	_back_door()
	parts.append("window_bays")


func _pier(spot: Vector3, out: Vector3, height: float) -> void:
	WallTrim.pier(kit, spot, out, 0.6, height, 0.2)
	WallTrim.pier_shape(room, spot, out, 0.6, height, 0.2)


## A wooden service door in the back wall, with a small canopy over it.
func _back_door() -> void:
	box(Vector3(1.7, 2.6, 0.08), WallTrim.WOOD, Vector3(0, 1.3, bz - 0.04))
	box(Vector3(0.05, 2.4, 0.1), WallTrim.WOOD.darkened(0.3), Vector3(0, 1.25, bz - 0.06))
	for x in [-1.0, 1.0]:
		box(Vector3(0.2, 2.8, 0.16), WallTrim.TRIM, Vector3(x * 0.95, 1.4, bz - 0.08))
	box(Vector3(2.6, 0.14, 1.0), tint, Vector3(0, 3.0, bz - 0.5))
	box(Vector3(2.7, 0.06, 1.06), WallTrim.TRIM, Vector3(0, 2.9, bz - 0.5))
	parts.append("back_door")
