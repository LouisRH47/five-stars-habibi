class_name PlazaHomes
extends RefCounted
## Session 90: the homes (flats) above each Plaza restaurant row, in the house kit's style
## (scripts/villa_builder.gd): cream walls, windows in deep frames with sills and stepped
## tops, a trim band between the floors, a cornice and a parapet round the roof, AC units
## and water tanks on the roof, and a balcony with plants for every flat on the Plaza side.
## A thick trim band along the bottom sits right on the restaurant fronts, so there's no
## gap or step between the shops and the homes above them.
## One long block per row (it used to be two with a gap). The big wall box stays a plain
## box (PlazaWalls dresses its two ends); everything else is ONE mesh (MeshKit).

const WALL := Color(0.93, 0.87, 0.75)        # like the villas (VillaBuilder.WALLS)
const TRIM := Color(0.97, 0.95, 0.9)         # WallTrim.TRIM
const PIER := Color(0.94, 0.9, 0.81)         # WallTrim.PIER
const TERRACE := Color(0.82, 0.68, 0.55)     # VillaBuilder.TERRACE
const METAL := Color(0.75, 0.76, 0.78)       # AC units
const GRILLE := Color(0.3, 0.31, 0.33)
const TANK := Color(0.96, 0.96, 0.94)
const POT := Color(0.72, 0.42, 0.28)
const LEAF := Color(0.35, 0.58, 0.28)
const FLOWERS := [Color(0.93, 0.36, 0.62), Color(0.98, 0.78, 0.3), Color(0.96, 0.55, 0.3)]
const BOTTOM := 8.0          # the restaurants are 8 m tall; the homes start on top


## Builds one row of homes. middle: the row's middle on the ground. size: width, height,
## depth of the block. front: +1 if the Plaza side is +Z, -1 if it's -Z.
static func build(parent: Node3D, middle: Vector3, size: Vector3, front: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "PlazaHomes_%d" % int(absf(middle.z))
	body.position = middle
	parent.add_child(body)
	# The wall block (a plain box with real collision; PlazaWalls finds it by its size).
	var wall_at := Vector3(0, BOTTOM + size.y * 0.5, 0)
	var wall := LowPoly.box(body, size, WALL, wall_at)
	wall.name = "Walls"
	LowPoly.solid_box(body, size, wall_at)
	var kit := MeshKit.new()
	var counts := {"windows": 0, "frames": 0, "balconies": 0, "plants": 0, "ac_units": 0}
	_bands(kit, size, front)
	_roof(kit, size, counts)
	var bays := maxi(1, roundi(size.x / GameConfig.PLAZA_HOME_BAY))
	var bay := size.x / bays
	for i in bays:
		var x := -size.x * 0.5 + bay * (i + 0.5)
		_front_flat(kit, x, size, front, i, counts)
		_back_flat(kit, x, size, -front, i, counts)
		if i > 0:  # a flat column between two flats, on both sides
			for way in [front, -front]:
				var z: float = way * (size.z * 0.5 + 0.08)
				var tall := GameConfig.PLAZA_HOME_CORNICE - GameConfig.PLAZA_HOME_BASE_TOP
				kit.box(Vector3(0.5, tall, 0.16), PIER,
						Vector3(x - bay * 0.5, GameConfig.PLAZA_HOME_BASE_TOP + tall * 0.5, z))
	var look := kit.finish("HomesLook")
	look.position = Vector3.ZERO
	body.add_child(look)
	for key in counts:
		body.set_meta(key, counts[key])
	body.set_meta("flats", bays)
	body.set_meta("front", front)
	return body


## The thick band along the bottom (it covers the join with the shop fronts), the trim
## between the two floors and the cornice under the roof edge, on the front and back.
static func _bands(kit: MeshKit, size: Vector3, front: float) -> void:
	var base_top: float = GameConfig.PLAZA_HOME_BASE_TOP
	var base_low := BOTTOM - 0.14
	var stick: float = GameConfig.PLAZA_HOME_BASE_STICK
	var storey := BOTTOM + GameConfig.PLAZA_HOME_STOREY
	var cornice: float = GameConfig.PLAZA_HOME_CORNICE
	for way in [front, -front]:
		var face: float = way * size.z * 0.5
		kit.box(Vector3(size.x + stick * 2.0, base_top - base_low, stick + 0.1), TRIM,
				Vector3(0, (base_top + base_low) * 0.5, face + way * (stick * 0.5 - 0.05)))
		kit.box(Vector3(size.x + 0.1, 0.14, 0.13), TRIM, Vector3(0, storey, face + way * 0.045))
		kit.box(Vector3(size.x + 0.4, 0.27, 0.42), TRIM, Vector3(0, cornice + 0.135, face + way * 0.11))
	# The bottom band and the cornice round the two ends too (PlazaWalls puts windows there).
	for s in [-1.0, 1.0]:
		kit.box(Vector3(stick + 0.1, base_top - base_low, size.z + stick * 2.0), TRIM,
				Vector3(s * (size.x * 0.5 + stick * 0.5 - 0.05), (base_top + base_low) * 0.5, 0))
		kit.box(Vector3(0.42, 0.27, size.z + 0.4), TRIM, Vector3(s * (size.x * 0.5 + 0.11), cornice + 0.135, 0))


## The roof: a parapet (low wall) with a trim on top, terrace tiles, AC units and water tanks.
static func _roof(kit: MeshKit, size: Vector3, counts: Dictionary) -> void:
	var top := BOTTOM + size.y
	var p: float = GameConfig.HOUSE_PARAPET
	var t := 0.22
	for along_x in [true, false]:
		for end in [-1.0, 1.0]:
			var length: float = (size.x if along_x else size.z) + 0.04
			var wall_size := Vector3(length, p, t) if along_x else Vector3(t, p, length)
			var spot := Vector3(0, top + p * 0.5, end * ((size.z - t) * 0.5 + 0.02)) if along_x \
					else Vector3(end * ((size.x - t) * 0.5 + 0.02), top + p * 0.5, 0)
			kit.box(wall_size, WALL, spot)
			kit.box(wall_size + Vector3(0.08, 0.07 - p, 0.08), TRIM, spot + Vector3(0, p * 0.5 + 0.035, 0))
	kit.box(Vector3(size.x - 0.5, 0.04, size.z - 0.5), TERRACE, Vector3(0, top + 0.02, 0))
	var x := -size.x * 0.5 + 3.0
	var i := 0
	while x < size.x * 0.5 - 2.0:
		if i % 3 == 2:  # a white water tank on legs
			for leg in [-0.5, 0.5]:
				kit.box(Vector3(0.1, 0.5, 0.9), GRILLE, Vector3(x + leg, top + 0.29, -2.0))
			kit.cylinder(0.55, 0.55, 1.5, TANK, Vector3(x, top + 1.04, -2.0), Basis(Vector3.BACK, PI * 0.5), 10)
		else:  # an AC unit with a dark fan grille
			kit.box(Vector3(0.9, 0.62, 0.62), METAL, Vector3(x, top + 0.35, 1.6 - (i % 2) * 3.4))
			kit.box(Vector3(0.5, 0.42, 0.03), GRILLE, Vector3(x, top + 0.37, 1.6 - (i % 2) * 3.4 + 0.325))
			counts["ac_units"] += 1
		x += 5.2
		i += 1


## One flat on the Plaza side: a balcony with a glass door and plants downstairs, two
## framed windows upstairs and (on every other flat) an AC unit on the wall.
static func _front_flat(kit: MeshKit, x: float, size: Vector3, way: float, i: int, counts: Dictionary) -> void:
	var out := Vector3(0, 0, way)
	var face: float = way * size.z * 0.5
	var floor_y: float = GameConfig.PLAZA_HOME_BASE_TOP
	var reach: float = GameConfig.PLAZA_HOME_BALCONY_DEPTH
	var wide: float = GameConfig.PLAZA_HOME_BALCONY_WIDTH
	# The balcony door (tall glass in a deep frame) behind the balcony.
	WallTrim.window(kit, Vector3(x, floor_y + 1.12, face), out, 1.5, 2.0, false)
	counts["windows"] += 1
	counts["frames"] += 1
	# The balcony: a floor slab, a low wall round it with a trim on top.
	counts["balconies"] += 1
	var slab_top := floor_y + 0.17
	kit.box(Vector3(wide, 0.22, reach), TRIM, Vector3(x, slab_top - 0.11, face + way * (reach * 0.5 + 0.01)))
	var low := 0.95
	var wall_z := face + way * (reach - 0.07)
	kit.box(Vector3(wide - 0.02, low, 0.14), WALL, Vector3(x, slab_top + low * 0.5, wall_z))
	kit.box(Vector3(wide + 0.06, 0.07, 0.24), TRIM, Vector3(x, slab_top + low + 0.035, wall_z))
	for s in [-1.0, 1.0]:
		var side_x: float = x + s * (wide * 0.5 - 0.08)
		kit.box(Vector3(0.14, low, reach - 0.16), WALL, Vector3(side_x, slab_top + low * 0.5, face + way * (reach * 0.5 - 0.06)))
		kit.box(Vector3(0.22, 0.07, reach - 0.12), TRIM, Vector3(side_x, slab_top + low + 0.035, face + way * (reach * 0.5 - 0.05)))
	# Plants on the balcony (they show over the low wall) and flowers hanging over it.
	for k in 2:
		var spot := Vector3(x + (-0.9 if k == 0 else 0.95), slab_top, face + way * (reach - 0.42))
		kit.cylinder(0.2, 0.15, 0.42, POT, spot + Vector3(0, 0.21, 0))
		if (i + k) % 3 == 0:  # a little palm-like plant: a tall stem with a leafy top
			kit.cylinder(0.05, 0.06, 1.0, Color(0.45, 0.33, 0.2), spot + Vector3(0, 0.9, 0))
			kit.ball(0.42, LEAF.darkened(0.1), spot + Vector3(0, 1.5, 0), 0.6)
		else:
			kit.ball(0.4, LEAF, spot + Vector3(0, 0.95, 0), 0.9)
		counts["plants"] += 1
	if i % 2 == 0:  # bougainvillea spilling over the front of the balcony wall
		var colour: Color = FLOWERS[(i / 2) % FLOWERS.size()]
		for k in 3:
			kit.ball(0.26 - k * 0.03, colour, Vector3(x - 0.6 + k * 0.55, slab_top + low - 0.05 - k * 0.12, wall_z + way * 0.12), 0.8)
		counts["plants"] += 1
	# Upstairs: two windows in deep frames with the stepped tops, like the houses.
	var up := BOTTOM + GameConfig.PLAZA_HOME_STOREY + 1.45
	for s in [-1.0, 1.0]:
		WallTrim.window(kit, Vector3(x + s * 1.45, up, face), out, 1.1, 1.3)
		counts["windows"] += 1
		counts["frames"] += 1
	if i % 2 == 1:  # an AC unit under one of the upstairs windows
		_wall_ac(kit, Vector3(x + 1.45, BOTTOM + GameConfig.PLAZA_HOME_STOREY + 0.4, face), way)
		counts["ac_units"] += 1


## The same flat seen from the road behind: framed windows on both floors and an AC unit.
static func _back_flat(kit: MeshKit, x: float, size: Vector3, way: float, i: int, counts: Dictionary) -> void:
	var out := Vector3(0, 0, way)
	var face: float = way * size.z * 0.5
	for y in [BOTTOM + 1.5, BOTTOM + GameConfig.PLAZA_HOME_STOREY + 1.45]:
		for s in [-1.0, 1.0]:
			WallTrim.window(kit, Vector3(x + s * 1.45, y, face), out, 1.0, 1.2, y > BOTTOM + 2.0)
			counts["windows"] += 1
			counts["frames"] += 1
	if i % 2 == 0:
		_wall_ac(kit, Vector3(x, BOTTOM + 1.3, face), way)
		counts["ac_units"] += 1


## An AC unit hung on a wall (spot: the middle of its back, on the wall), with a dark grille.
static func _wall_ac(kit: MeshKit, spot: Vector3, way: float) -> void:
	kit.box(Vector3(0.78, 0.5, 0.32), METAL, spot + Vector3(0, 0, way * 0.17))
	kit.box(Vector3(0.44, 0.34, 0.03), GRILLE, spot + Vector3(-0.1, 0, way * 0.345))
	kit.box(Vector3(0.82, 0.05, 0.4), GRILLE, spot + Vector3(0, -0.27, way * 0.2))
