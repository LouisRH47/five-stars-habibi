class_name ShopRoof
extends RefCounted
## Session 78: the roof of each shop (ShopExterior calls build()):
##   - a low wall (parapet) round the roof's edge, stepping up twice over the sign into a
##     crown with a round badge (a bike wheel for Pedal Point, a diamond for Dune Drip)
##   - a raised part at the back (a second storey over the storeroom) with windows, a band
##     in the shop's colour and little stepped battlements, like old Gulf houses
##   - a wind tower (barjeel) on the raised part, solar panels and AC units on the low roof
## Nobody can climb up here, so only the shop's walls below are solid.

const UPPER := Color(0.93, 0.87, 0.75)
const TERRACE := Color(0.8, 0.66, 0.53)
const PANEL := Color(0.18, 0.29, 0.42)
const METAL := Color(0.62, 0.64, 0.66)
const UPPER_X := 3.0    # the raised back part covers x from the left wall to here...
const UPPER_Z := -1.5   # ...and z from the back wall to here


static func build(shop: ShopExterior) -> void:
	var p: float = GameConfig.SHOP_PARAPET
	var up: float = shop.top + GameConfig.SHOP_UPPER_HEIGHT
	# The lower roof's tiles, just above the shop's ceiling slab (its top is 0.2 above the walls).
	shop.box(Vector3(shop.sx * 2 - 0.6, 0.04, shop.fz - shop.bz - 0.6), TERRACE, Vector3(0, shop.top + 0.22, 0))
	# Parapet: right side, left side up to the raised part, back beside it.
	_parapet(shop, Vector2(shop.sx - 0.13, shop.bz - 0.04), Vector2(shop.sx - 0.13, shop.fz + 0.04), shop.top, p)
	_parapet(shop, Vector2(-shop.sx + 0.13, UPPER_Z), Vector2(-shop.sx + 0.13, shop.fz + 0.04), shop.top, p)
	_parapet(shop, Vector2(UPPER_X, shop.bz + 0.13), Vector2(shop.sx + 0.04, shop.bz + 0.13), shop.top, p)
	# The front steps up twice over the sign: a crown in the middle.
	var steps: Array = GameConfig.SHOP_CROWN_STEPS
	var edges := [shop.sx + 0.04, 6.2, 3.4]
	var z := shop.fz - 0.13
	for i in edges.size():
		var lift: float = 0.0 if i == 0 else steps[i - 1]
		var outer: float = edges[i]
		var inner: float = edges[i + 1] if i + 1 < edges.size() else 0.0
		if inner == 0.0:
			_parapet(shop, Vector2(-outer, z), Vector2(outer, z), shop.top, p + lift)
		else:
			for s in [-1.0, 1.0]:
				_parapet(shop, Vector2(s * inner, z), Vector2(s * outer, z), shop.top, p + lift)
	_medallion(shop, Vector3(0, shop.top + p + steps[0] + 0.15, shop.fz + 0.06))
	shop.parts.append_array(["parapet", "stepped_roof"])
	_upper(shop, up)
	_wind_tower(shop, Vector3(-7.4, up, -5.4), GameConfig.SHOP_TOWER_HEIGHT)
	_solar_panels(shop)
	for z_ac in [-5.0, -3.5]:
		shop.box(Vector3(0.9, 0.6, 1.1), METAL, Vector3(7.0, shop.top + 0.54, z_ac))
		shop.kit.cylinder(0.3, 0.3, 0.04, WallTrim.DARK, Vector3(7.0, shop.top + 0.86, z_ac))


## A low wall from a to b (seen from above: x, z), with a light cap on top.
static func _parapet(shop: ShopExterior, a: Vector2, b: Vector2, base: float, height: float, thick := 0.34) -> void:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var length := absf(b.x - a.x) if along_x else absf(b.y - a.y)
	var middle := (a + b) * 0.5
	var size := Vector3(length, height, thick) if along_x else Vector3(thick, height, length)
	shop.box(size, WallTrim.WALL, Vector3(middle.x, base + height * 0.5, middle.y))
	var cap := Vector3(length + 0.08, 0.12, thick + 0.12) if along_x else Vector3(thick + 0.12, 0.12, length + 0.08)
	shop.box(cap, WallTrim.TRIM, Vector3(middle.x, base + height + 0.06, middle.y))


## The round badge on the crown: a bike wheel for Pedal Point, a diamond for Dune Drip.
static func _medallion(shop: ShopExterior, spot: Vector3) -> void:
	var face := Basis(Vector3.RIGHT, PI * 0.5)  # a cylinder turned to face the front
	shop.kit.cylinder(0.62, 0.62, 0.06, WallTrim.TRIM, spot, face, 16)
	shop.kit.cylinder(0.52, 0.52, 0.06, shop.tint, spot + Vector3(0, 0, 0.03), face, 16)
	if shop.room.get_meta("shop_id", "") == "bikes":
		shop.kit.cylinder(0.36, 0.36, 0.04, WallTrim.DARK, spot + Vector3(0, 0, 0.06), face, 16)
		shop.kit.cylinder(0.28, 0.28, 0.04, shop.tint, spot + Vector3(0, 0, 0.08), face, 16)
		for k in 4:
			shop.box(Vector3(0.6, 0.04, 0.03), WallTrim.TRIM, spot + Vector3(0, 0, 0.1), Basis(Vector3.BACK, k * PI * 0.25))
	else:
		shop.box(Vector3(0.5, 0.5, 0.04), WallTrim.TRIM, spot + Vector3(0, 0, 0.07), Basis(Vector3.BACK, PI * 0.25))
		shop.box(Vector3(0.28, 0.28, 0.04), shop.tint.darkened(0.25), spot + Vector3(0, 0, 0.09), Basis(Vector3.BACK, PI * 0.25))


## The raised back part (a second storey over the storeroom): windows, a colour band,
## a parapet and little stepped battlements, like old Gulf forts and houses.
static func _upper(shop: ShopExterior, up: float) -> void:
	var h := up - shop.top
	var x0 := -shop.sx
	var middle := Vector3((x0 + UPPER_X) * 0.5, shop.top + h * 0.5, (shop.bz + UPPER_Z) * 0.5)
	shop.box(Vector3(UPPER_X - x0, h, UPPER_Z - shop.bz), UPPER, middle)
	var y := shop.top + h * 0.5
	for x in [-7.6, -3.6, 0.4]:
		WallTrim.window(shop.kit, Vector3(x, y, UPPER_Z), Vector3(0, 0, 1), 1.2, 1.3)
		WallTrim.window(shop.kit, Vector3(x, y, shop.bz), Vector3(0, 0, -1), 1.2, 1.3)
	for z in [-7.0, -3.6]:
		WallTrim.window(shop.kit, Vector3(x0, y, z), Vector3(-1, 0, 0), 1.2, 1.3)
	WallTrim.window(shop.kit, Vector3(UPPER_X, y, -5.3), Vector3(1, 0, 0), 1.2, 1.3)
	# The colour band and cornice round the raised part.
	for band: Array in [[up - 0.75, up - 0.55, 0.05, shop.tint], [up - 0.25, up, 0.15, WallTrim.TRIM]]:
		var stick: float = band[2]
		var size := Vector3(UPPER_X - x0 + stick * 2, band[1] - band[0], UPPER_Z - shop.bz + stick * 2)
		shop.box(size, band[3], Vector3(middle.x, (band[0] + band[1]) * 0.5, middle.z))
	var p := 0.7
	var t := 0.13
	_parapet(shop, Vector2(x0 - 0.04, shop.bz + t), Vector2(UPPER_X + 0.04, shop.bz + t), up, p)
	_parapet(shop, Vector2(x0 - 0.04, UPPER_Z - t), Vector2(UPPER_X + 0.04, UPPER_Z - t), up, p)
	_parapet(shop, Vector2(x0 + t, shop.bz), Vector2(x0 + t, UPPER_Z), up, p)
	_parapet(shop, Vector2(UPPER_X - t, shop.bz), Vector2(UPPER_X - t, UPPER_Z), up, p)
	# Battlements: a small stepped block every metre along the front and back.
	var x := x0 + 0.6
	while x < UPPER_X - 0.4:
		for z in [UPPER_Z - t, shop.bz + t]:
			shop.box(Vector3(0.42, 0.3, 0.3), WallTrim.WALL, Vector3(x, up + p + 0.27, z))
			shop.box(Vector3(0.2, 0.2, 0.3), WallTrim.WALL, Vector3(x, up + p + 0.52, z))
		x += 1.0
	shop.parts.append("raised_back")


## The wind tower (barjeel): a tall square tower with slots near the top to catch the breeze.
static func _wind_tower(shop: ShopExterior, base: Vector3, height: float) -> void:
	var w := 2.0
	shop.box(Vector3(w, height, w), UPPER, base + Vector3(0, height * 0.5, 0))
	shop.box(Vector3(w + 0.08, 0.18, w + 0.08), shop.tint, base + Vector3(0, height - 1.9, 0))
	shop.box(Vector3(w + 0.3, 0.2, w + 0.3), WallTrim.TRIM, base + Vector3(0, height + 0.1, 0))
	shop.box(Vector3(w - 0.6, 0.25, w - 0.6), WallTrim.TRIM, base + Vector3(0, height + 0.32, 0))
	for out in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
		var turn := WallTrim.turn_for(out)
		for across in [-0.45, 0.0, 0.45]:
			var spot: Vector3 = base + Vector3(0, height - 0.9, 0) + turn * Vector3(across, 0, w * 0.5 + 0.01)
			shop.box(Vector3(0.24, 1.3, 0.04), WallTrim.RECESS, spot, turn)
	shop.parts.append("wind_tower")


## Tilted solar panels on short posts over the front half of the low roof.
static func _solar_panels(shop: ShopExterior) -> void:
	var z0 := 0.6
	var z1 := shop.fz - 1.6
	var low := shop.top + 0.55
	var high := shop.top + 1.25
	var tilt := Basis(Vector3.RIGHT, atan2(high - low, z1 - z0))
	var slope := Vector2(z1 - z0, high - low).length()
	for xs: Array in [[-8.4, -0.5], [0.5, 8.4]]:
		for x in xs:
			shop.box(Vector3(0.1, high - shop.top - 0.2, 0.1), WallTrim.DARK, Vector3(x, (shop.top + 0.2 + high) * 0.5, z0 + 0.1))
			shop.box(Vector3(0.1, low - shop.top - 0.2, 0.1), WallTrim.DARK, Vector3(x, (shop.top + 0.2 + low) * 0.5, z1 - 0.1))
		var middle := Vector3((xs[0] + xs[1]) * 0.5, (low + high) * 0.5 + 0.05, (z0 + z1) * 0.5)
		shop.box(Vector3(xs[1] - xs[0] + 0.2, 0.08, slope), PANEL, middle, tilt)
	shop.parts.append("solar_panels")
