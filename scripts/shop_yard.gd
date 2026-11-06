class_name ShopYard
extends RefCounted
## Session 78: the things round the outside of the two shops (ShopExterior calls this).
##   Pedal Point Bikes: a bike rack with bikes on the right side, a pump and repair stand
##   on the left side, planters at the front corners.
##   Dune Drip: planters at the front corners and along both sides, a bench under the
##   arcade and one on the right side between two planters.
## Everything goes into the shop's one exterior mesh; each thing you can bump into gets a
## solid box the same size. Local axes like the shop (+Z is the front).

const BIKE_PAINT := [Color(0.85, 0.25, 0.2), Color(0.16, 0.45, 0.48), Color(0.95, 0.75, 0.2),
		Color(0.25, 0.35, 0.6), Color(0.3, 0.55, 0.3)]
const LEAF := Color(0.3, 0.52, 0.25)
const SOIL := Color(0.36, 0.27, 0.19)
const STONE := Color(0.84, 0.77, 0.64)
const TRUNK := Color(0.52, 0.4, 0.27)
const RACK := Color(0.55, 0.57, 0.6)


static func build(shop: ShopExterior, bikes: bool) -> void:
	var corner := shop.fz + GameConfig.SHOP_ARCADE_DEPTH + 1.0
	for s in [-1.0, 1.0]:  # planters at both front corners, just past the end columns
		_planter(shop, Vector3(s * (shop.sx + 0.4), 0, corner), s > 0)
	if bikes:
		_bike_rack(shop, shop.sx + 1.4)
		_pump_stand(shop, Vector3(-shop.sx - 0.9, 0, shop.fz - 2.2))
		shop.parts.append_array(["bike_rack", "pump_stand", "planters"])
		return
	for s in [-1.0, 1.0]:
		for z in [-3.0, 3.0]:
			_planter(shop, Vector3(s * (shop.sx + 1.0), 0, z), z > 0)
	_bench(shop, Vector3(shop.sx + 0.75, 0, 0), Vector3(1, 0, 0))
	_bench(shop, Vector3(6.2, 0, shop.fz + 0.55), Vector3(0, 0, 1))
	shop.parts.append_array(["planters", "bench"])


## A stone planter with a small palm (palm = true) or round bushes.
static func _planter(shop: ShopExterior, at: Vector3, palm: bool) -> void:
	shop.block(Vector3(1.3, 0.6, 1.3), STONE, at + Vector3(0, 0.3, 0))
	shop.box(Vector3(1.45, 0.1, 1.45), WallTrim.TRIM, at + Vector3(0, 0.65, 0))
	shop.box(Vector3(1.15, 0.03, 1.15), SOIL, at + Vector3(0, 0.715, 0))
	if palm:
		var top := at + Vector3(0, 2.4, 0)
		shop.kit.cylinder(0.08, 0.12, 1.7, TRUNK, at + Vector3(0, 1.55, 0))
		for k in 7:
			var around := Basis(Vector3.UP, k * TAU / 7.0)
			shop.box(Vector3(1.2, 0.04, 0.3), LEAF, top + around * Vector3(0.5, -0.15, 0), around * Basis(Vector3.BACK, -0.35))
	else:
		shop.kit.ball(0.45, LEAF, at + Vector3(0, 1.05, 0), 0.85)
		shop.kit.ball(0.32, LEAF.lightened(0.1), at + Vector3(0.3, 0.95, 0.25), 0.85)
		shop.kit.ball(0.3, LEAF.darkened(0.1), at + Vector3(-0.3, 0.92, -0.2), 0.85)


## A wooden bench on stone legs, its back to the wall. out: the way you face when sitting.
static func _bench(shop: ShopExterior, at: Vector3, out: Vector3) -> void:
	var turn := WallTrim.turn_for(out)
	shop.box(Vector3(1.8, 0.08, 0.5), WallTrim.WOOD, at + turn * Vector3(0, 0.45, 0), turn)
	shop.box(Vector3(1.8, 0.4, 0.06), WallTrim.WOOD, at + turn * Vector3(0, 0.72, -0.24), turn)
	for x in [-0.75, 0.75]:
		shop.box(Vector3(0.12, 0.45, 0.45), STONE, at + turn * Vector3(x, 0.22, 0), turn)
	var size := Vector3(0.5, 0.9, 1.8) if absf(out.x) > 0.5 else Vector3(1.8, 0.9, 0.5)
	LowPoly.solid_box(shop.room, size, at + Vector3(0, 0.45, 0))


## A rack of steel hoops along the side wall, with four bikes parked in it.
static func _bike_rack(shop: ShopExterior, x: float) -> void:
	shop.box(Vector3(0.1, 0.05, 6.2), RACK, Vector3(x, 0.025, 4.0))
	for i in 6:
		var z := 1.0 + i * 1.2
		for side in [-0.35, 0.35]:
			shop.box(Vector3(0.05, 0.75, 0.05), RACK, Vector3(x + side, 0.4, z))
		shop.box(Vector3(0.75, 0.05, 0.05), RACK, Vector3(x, 0.78, z))
	for i in 5:
		if i == 3:
			continue  # one empty space
		_bike(shop, Vector3(x, 0, 1.6 + i * 1.2), BIKE_PAINT[i])
	LowPoly.solid_box(shop.room, Vector3(2.0, 1.0, 6.4), Vector3(x, 0.5, 4.0))


## A parked bike pointing along x: two wheels, frame, seat and handlebars.
static func _bike(shop: ShopExterior, at: Vector3, paint: Color) -> void:
	var wheel := Basis(Vector3.RIGHT, PI * 0.5)
	for dx in [-0.55, 0.55]:
		shop.kit.cylinder(0.33, 0.33, 0.05, WallTrim.DARK, at + Vector3(dx, 0.34, 0), wheel, 12)
		shop.kit.cylinder(0.06, 0.06, 0.07, RACK, at + Vector3(dx, 0.34, 0), wheel)
	shop.box(Vector3(1.0, 0.05, 0.05), paint, at + Vector3(0, 0.64, 0))
	shop.box(Vector3(0.62, 0.05, 0.05), paint, at + Vector3(0.2, 0.5, 0), Basis(Vector3.BACK, 0.6))
	shop.box(Vector3(0.05, 0.5, 0.05), paint, at + Vector3(-0.2, 0.6, 0))
	shop.box(Vector3(0.26, 0.05, 0.13), WallTrim.DARK, at + Vector3(-0.22, 0.88, 0))
	shop.box(Vector3(0.05, 0.36, 0.05), paint, at + Vector3(0.45, 0.8, 0))
	shop.box(Vector3(0.04, 0.04, 0.5), WallTrim.DARK, at + Vector3(0.45, 0.98, 0))


## A pump and repair stand: a post in the shop's colour with a gauge and a hose, and a
## second post with an arm where tools hang.
static func _pump_stand(shop: ShopExterior, at: Vector3) -> void:
	shop.box(Vector3(0.6, 0.06, 1.3), WallTrim.DARK, at + Vector3(0, 0.03, 0.3))
	shop.box(Vector3(0.2, 1.0, 0.2), shop.tint, at + Vector3(0, 0.56, 0))
	shop.box(Vector3(0.34, 0.36, 0.26), shop.tint.darkened(0.25), at + Vector3(0, 1.22, 0))
	shop.kit.cylinder(0.11, 0.11, 0.03, WallTrim.TRIM, at + Vector3(-0.18, 1.26, 0), Basis(Vector3.BACK, PI * 0.5), 12)
	shop.box(Vector3(0.04, 0.75, 0.04), WallTrim.DARK, at + Vector3(-0.14, 0.75, 0.14), Basis(Vector3.RIGHT, 0.25))
	shop.box(Vector3(0.07, 0.07, 0.16), WallTrim.DARK, at + Vector3(-0.14, 0.38, 0.26))
	var arm := at + Vector3(0, 0, 0.8)
	shop.box(Vector3(0.12, 1.5, 0.12), RACK, arm + Vector3(0, 0.75, 0))
	shop.box(Vector3(0.1, 0.08, 0.6), RACK, arm + Vector3(0, 1.5, -0.2))
	for k in 3:  # spanners hanging from the arm
		shop.box(Vector3(0.03, 0.26, 0.05), WallTrim.DARK, arm + Vector3(0, 1.33, -0.38 + k * 0.14))
	LowPoly.solid_box(shop.room, Vector3(0.6, 1.5, 1.3), at + Vector3(0, 0.75, 0.3))
