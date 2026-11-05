class_name ShopArcade
extends RefCounted
## Session 78: the shaded arcade along the front of each shop (the Plaza side): columns
## with pointed arches, a beam and a roof with a band in the shop's colour, a tiled floor
## and three warm lanterns. It's open at the front and at both ends, so you can walk or
## ride through it to the door. Columns and beams are solid; the gaps are free.
## Built into the shop's one exterior mesh (ShopExterior). Numbers: GameConfig SHOP_ARCADE_*.

const TILE_A := Color(0.9, 0.8, 0.64)
const TILE_B := Color(0.76, 0.6, 0.46)


static func build(shop: ShopExterior) -> void:
	var depth: float = GameConfig.SHOP_ARCADE_DEPTH
	var roof_top: float = GameConfig.SHOP_ARCADE_TOP
	var spring: float = GameConfig.SHOP_ARCH_SPRING
	var arch_top: float = GameConfig.SHOP_ARCH_TOP
	var edge := shop.sx + 0.25         # the arcade is a little wider than the shop
	var cz := shop.fz + depth - 0.35   # the middle of the columns and the front beam
	var beam := roof_top - arch_top
	var xs: Array[float] = []
	for x: float in GameConfig.SHOP_COLUMN_XS:
		xs.append_array([-x, x])
	xs.sort()
	for x in xs:
		_column(shop, Vector3(x, 0, cz), spring, arch_top)
	for i in xs.size() - 1:
		_arch(shop, Vector3(xs[i] + 0.3, 0, cz), Vector3(xs[i + 1] - 0.3, 0, cz), spring, arch_top)
	# The front beam over the arches, with a band in the shop's colour and a lip on top.
	shop.block(Vector3(edge * 2, beam, 0.7), WallTrim.WALL, Vector3(0, arch_top + beam * 0.5, cz))
	shop.box(Vector3(edge * 2, 0.16, 0.06), shop.tint, Vector3(0, roof_top - 0.3, cz + 0.37))
	shop.box(Vector3(edge * 2, 0.22, 0.3), shop.tint, Vector3(0, roof_top + 0.11, shop.fz + depth - 0.15))
	# Each open end: a beam from the shop's corner pier to the end column, with an arch.
	for s in [-1.0, 1.0]:
		var bx: float = s * (edge - 0.425)
		shop.block(Vector3(0.85, beam, cz - shop.fz), WallTrim.WALL, Vector3(bx, arch_top + beam * 0.5, (shop.fz + cz) * 0.5))
		shop.box(Vector3(0.3, 0.22, depth), shop.tint, Vector3(s * (edge - 0.15), roof_top + 0.11, shop.fz + depth * 0.5))
		_arch(shop, Vector3(s * xs[-1], 0, shop.fz + 0.2), Vector3(s * xs[-1], 0, cz - 0.3), spring, arch_top)
	# The roof between the beams, and the tiled floor underneath.
	shop.block(Vector3((edge - 0.85) * 2, 0.3, cz - 0.35 - shop.fz), WallTrim.WALL,
			Vector3(0, roof_top - 0.15, (shop.fz + cz - 0.35) * 0.5))
	var across := ceili(edge * 2)
	var deep := ceili(depth)
	for i in across:
		for j in deep:
			var tile := Vector3(edge * 2 / across, 0.05, depth / deep)
			var spot := Vector3(-edge + tile.x * (i + 0.5), 0.025, shop.fz + tile.z * (j + 0.5))
			shop.box(tile, TILE_A if (i + j) % 2 == 0 else TILE_B, spot)
	# Three warm lanterns hanging under the roof.
	for x in [-4.65, 0.0, 4.65]:
		var hang := Vector3(x, roof_top - 0.3, shop.fz + depth * 0.45)
		shop.box(Vector3(0.03, 0.3, 0.03), WallTrim.DARK, hang + Vector3(0, -0.15, 0))
		shop.box(Vector3(0.42, 0.08, 0.42), WallTrim.DARK, hang + Vector3(0, -0.34, 0))
		var lamp := LowPoly.box(shop.room, Vector3(0.3, 0.42, 0.3), Color.WHITE, hang + Vector3(0, -0.59, 0))
		lamp.material_override = VenueParts.glow(Color(1.0, 0.82, 0.5), 1.4)
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shop.parts.append("arcade")


## One column: a base, a square shaft, a capital, and a short pier up to the beam.
static func _column(shop: ShopExterior, at: Vector3, spring: float, arch_top: float) -> void:
	shop.box(Vector3(0.85, 0.35, 0.85), WallTrim.TRIM, at + Vector3(0, 0.175, 0))
	shop.box(Vector3(0.6, spring - 0.65, 0.6), WallTrim.PIER, at + Vector3(0, 0.35 + (spring - 0.65) * 0.5, 0))
	shop.box(Vector3(0.85, 0.3, 0.85), WallTrim.TRIM, at + Vector3(0, spring - 0.15, 0))
	shop.box(Vector3(0.6, arch_top - spring, 0.6), WallTrim.WALL, at + Vector3(0, (spring + arch_top) * 0.5, 0))
	LowPoly.solid_box(shop.room, Vector3(0.7, arch_top, 0.7), at + Vector3(0, arch_top * 0.5, 0))
	shop.columns += 1


## A pointed arch from a to b (on the ground, along x or z): thin slices of wall that fill
## the space between the curve and the beam, so the opening looks arched.
static func _arch(shop: ShopExterior, a: Vector3, b: Vector3, spring: float, arch_top: float) -> void:
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var length := a.distance_to(b)
	var slices := 14
	var rise := arch_top - spring
	var r := 1.3  # bigger than 1 makes the arch pointed at the top
	for i in slices:
		var t := (i + 0.5) / slices
		var s := absf(t * 2.0 - 1.0)  # 0 in the middle, 1 at the columns
		var curve := sqrt(maxf(0.0, r * r - pow(s + r - 1.0, 2))) / sqrt(r * r - pow(r - 1.0, 2))
		var y := spring + rise * curve
		var tall := arch_top - y
		if tall < 0.03:
			continue
		var w := length / slices + 0.004
		var size := Vector3(w, tall, 0.56) if along_x else Vector3(0.56, tall, w)
		shop.box(size, WallTrim.WALL, a.lerp(b, t) + Vector3(0, y + tall * 0.5, 0))
