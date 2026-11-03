class_name VillaExtras
## The little things that make every Wahat Al Shams home different (Session 26): a golf
## buggy or bikes beside the house, AC units, a satellite dish, pot plants by the door,
## flowers on the courtyard wall, a courtyard tree, kids' toys, and on garden and signature
## villas a small pool or a trampoline. scripts/villa_builder.gd calls add_all().
## Everything is picked with the home's own random numbers (seeded by its number), so the
## same home always gets the same things. Everything stays inside the home's plot: the
## side yard (the side without the courtyard), the courtyard or lawn, and a thin strip by the
## door. Nothing goes on the lane or on the door spot.

const DARK := Color(0.15, 0.15, 0.16)
const SEAT := Color(0.76, 0.62, 0.45)
const METAL := Color(0.75, 0.76, 0.78)
const POT := Color(0.72, 0.42, 0.28)
const LEAF := Color(0.32, 0.56, 0.28)
const FLOWER := Color(0.88, 0.3, 0.6)
const WATER := Color(0.35, 0.72, 0.88)
const WHITE := Color(0.96, 0.96, 0.94)
const BUGGY_COLOURS := [Color(0.96, 0.96, 0.94), Color(0.9, 0.85, 0.7), Color(0.45, 0.55, 0.38), Color(0.3, 0.4, 0.55)]
const BRIGHT := [Color(0.9, 0.25, 0.2), Color(0.2, 0.5, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.75, 0.4), Color(0.9, 0.45, 0.7)]


## Adds this home's extras. home: the VillaBuilder building it.
static func add_all(home: VillaBuilder) -> void:
	var rng := home.rng
	var x := home.main.position.x   # the wall on the side-yard side
	if rng.randf() < GameConfig.HOUSE_BUGGY_CHANCE:
		_buggy(home, Vector3(x - 1.4, 0, 1.5))
	elif rng.randf() < GameConfig.HOUSE_BIKES_CHANCE:
		_bikes(home, x, 1 + rng.randi() % 2)
	_ac_units(home, x, 1 + rng.randi() % 3)
	if rng.randf() < GameConfig.HOUSE_DISH_CHANCE:
		_dish(home, Vector3(x - 0.15, home.roof - 0.5, -3.8))
	_door_plants(home, rng.randi() % 3)
	if rng.randf() < GameConfig.HOUSE_TOYS_CHANCE:
		_toys(home, Vector3(x - 1.5, 0, -3.0))
	if home.kind != "garden":
		_yard_tree(home)
	if home.kind == "garden" or home.kind == "signature":
		var spot := Vector3(home.yard.get_center().x, 0, home.yard.get_center().y + 0.3)
		if home.kind == "garden":
			spot = Vector3(home.yard.position.x + 2.5, 0, home.yard.end.y - 2.9)
		if rng.randf() < GameConfig.HOUSE_POOL_CHANCE:
			_pool(home, spot)
		else:
			_trampoline(home, spot)


## A golf buggy parked beside the house, pointing at the lane.
static func _buggy(home: VillaBuilder, spot: Vector3) -> void:
	var colour: Color = BUGGY_COLOURS[home.rng.randi() % BUGGY_COLOURS.size()]
	home.extras.append("buggy")
	home.box(Vector3(1.2, 0.5, 2.3), colour, spot + Vector3(0, 0.55, 0))
	home.box(Vector3(1.1, 0.45, 0.5), SEAT, spot + Vector3(0, 0.95, -0.2))
	home.box(Vector3(1.1, 0.6, 0.12), SEAT, spot + Vector3(0, 1.2, -0.5))
	home.box(Vector3(1.3, 0.06, 1.9), colour, spot + Vector3(0, 1.95, -0.1))
	for corner in [Vector3(-0.55, 0, 0.75), Vector3(0.55, 0, 0.75), Vector3(-0.55, 0, -0.95), Vector3(0.55, 0, -0.95)]:
		home.box(Vector3(0.05, 1.15, 0.05), DARK, spot + corner + Vector3(0, 1.4, 0))
	var wheel := Basis(Vector3.BACK, PI * 0.5)
	for corner in [Vector3(-0.62, 0.28, 0.75), Vector3(0.62, 0.28, 0.75), Vector3(-0.62, 0.28, -0.75), Vector3(0.62, 0.28, -0.75)]:
		home.kit_cylinder(0.28, 0.28, 0.18, DARK, spot + corner, wheel)
	home.solid(Vector3(1.3, 1.9, 2.4), spot + Vector3(0, 0.95, 0))


## One or two bikes leaning by the side wall.
static func _bikes(home: VillaBuilder, wall_x: float, count: int) -> void:
	home.extras.append("bikes%d" % count)
	var wheel := Basis(Vector3.BACK, PI * 0.5)
	for i in count:
		var colour: Color = BRIGHT[home.rng.randi() % BRIGHT.size()]
		var spot := Vector3(wall_x - 0.5 - i * 0.6, 0, 2.6)
		for z in [-0.55, 0.55]:
			home.kit_cylinder(0.33, 0.33, 0.05, DARK, spot + Vector3(0, 0.34, z), wheel)
		home.box(Vector3(0.05, 0.05, 1.1), colour, spot + Vector3(0, 0.62, 0))
		home.box(Vector3(0.05, 0.5, 0.05), colour, spot + Vector3(0, 0.6, -0.2))
		home.box(Vector3(0.12, 0.05, 0.25), DARK, spot + Vector3(0, 0.88, -0.2))
		home.box(Vector3(0.45, 0.04, 0.04), DARK, spot + Vector3(0, 0.95, 0.45))


## Grey air-conditioning boxes on the side wall, or on the roof.
static func _ac_units(home: VillaBuilder, wall_x: float, count: int) -> void:
	var on_roof := home.rng.randf() < 0.4
	home.extras.append(("ac_roof%d" if on_roof else "ac_wall%d") % count)
	for i in count:
		if on_roof:
			var z := home.main.get_center().y + (i - 1) * 1.3
			home.box(Vector3(0.8, 0.6, 0.6), METAL, Vector3(wall_x + 0.7, home.roof + 0.3, z))
		else:
			var z := -3.6 + i * 1.2
			home.box(Vector3(0.38, 0.6, 0.8), METAL, Vector3(wall_x - 0.19, 0.3, z))
			home.box(Vector3(0.02, 0.4, 0.4), DARK, Vector3(wall_x - 0.39, 0.3, z))


## A white satellite dish on a bracket near the top of the side wall.
static func _dish(home: VillaBuilder, spot: Vector3) -> void:
	home.extras.append("dish")
	home.box(Vector3(0.3, 0.08, 0.08), METAL, spot)
	var tilt := Basis(Vector3.BACK, -0.9)
	home.kit_cylinder(0.45, 0.3, 0.08, WHITE, spot + Vector3(-0.35, 0.25, 0), tilt)
	home.box(Vector3(0.04, 0.04, 0.5), METAL, spot + Vector3(-0.6, 0.45, 0), tilt)


## Pot plants on each side of the door (none, one or two).
static func _door_plants(home: VillaBuilder, count: int) -> void:
	home.extras.append("pots%d" % count)
	var front := home.main.end.y
	var sides := [1.0, -1.0] if home.rng.randf() < 0.5 else [-1.0, 1.0]
	for i in count:
		var spot := Vector3(sides[i] * 1.6, 0, front + 0.35)
		home.kit_cylinder(0.25, 0.18, 0.45, POT, spot + Vector3(0, 0.22, 0))
		if home.rng.randf() < 0.5:
			home.kit_ball(0.38, LEAF, spot + Vector3(0, 0.7, 0))
		else:  # a little cactus
			home.kit_cylinder(0.1, 0.12, 0.8, LEAF.darkened(0.15), spot + Vector3(0, 0.85, 0))


## A tree in the courtyard (an olive tree or a little palm), sometimes with pink flowers
## spilling over the courtyard wall.
static func _yard_tree(home: VillaBuilder) -> void:
	var spot := Vector3(home.yard.end.x - 1.1, 0, home.yard.position.y + 1.1)
	if home.rng.randf() < 0.5:
		home.extras.append("olive")
		home.box(Vector3(0.22, 1.8, 0.22), VillaBuilder.WOOD, spot + Vector3(0, 0.9, 0))
		home.kit_ball(1.0, LEAF.lightened(0.1), spot + Vector3(0, 2.3, 0), 0.75)
	else:
		home.extras.append("palm")
		home.kit_cylinder(0.12, 0.18, 3.4, VillaBuilder.WOOD, spot + Vector3(0, 1.7, 0))
		for i in 6:
			var turn := Basis(Vector3.UP, TAU * i / 6.0) * Basis(Vector3.RIGHT, 0.35)
			home.box(Vector3(0.35, 0.05, 1.5), LEAF, spot + Vector3(0, 3.4, 0) + turn * Vector3(0, 0, 0.7), turn)
	if home.rng.randf() < 0.5:
		home.extras.append("flowers")
		var wall := GameConfig.HOUSE_COURTYARD_WALL
		var z := home.yard.end.y - 0.15
		var x := home.yard.end.x - 0.5
		while x > home.yard.position.x + 2.0:
			home.kit_ball(0.25, FLOWER, Vector3(x, wall + 0.12, z), 0.7)
			x -= 0.45


## Kids' toys in the side yard: a ball and a little slide or a toy car.
static func _toys(home: VillaBuilder, spot: Vector3) -> void:
	var colour: Color = BRIGHT[home.rng.randi() % BRIGHT.size()]
	home.kit_ball(0.18, colour, spot + Vector3(0.3, 0.18, 1.0))
	if home.rng.randf() < 0.5:
		home.extras.append("slide")
		home.box(Vector3(0.5, 0.06, 1.5), colour, spot + Vector3(0, 0.5, 0), Basis(Vector3.RIGHT, -0.55))
		home.box(Vector3(0.6, 1.0, 0.3), BRIGHT[(BRIGHT.find(colour) + 1) % BRIGHT.size()], spot + Vector3(0, 0.5, -0.75))
	else:
		home.extras.append("toycar")
		home.box(Vector3(0.5, 0.3, 0.8), colour, spot + Vector3(0, 0.25, 0))
		home.box(Vector3(0.4, 0.2, 0.35), WHITE, spot + Vector3(0, 0.5, -0.1))


## A small pool with a white edge.
static func _pool(home: VillaBuilder, spot: Vector3) -> void:
	home.extras.append("pool")
	var size := Vector2(2.2, 2.6)
	home.box(Vector3(size.x + 0.5, 0.12, size.y + 0.5), WHITE, spot + Vector3(0, 0.06, 0))
	home.box(Vector3(size.x, 0.04, size.y), WATER, spot + Vector3(0, 0.13, 0))


## A round trampoline on four legs.
static func _trampoline(home: VillaBuilder, spot: Vector3) -> void:
	home.extras.append("trampoline")
	var colour: Color = BRIGHT[home.rng.randi() % BRIGHT.size()]
	home.kit_cylinder(1.2, 1.2, 0.1, colour, spot + Vector3(0, 0.75, 0), Basis(), 12)
	home.kit_cylinder(1.02, 1.02, 0.12, DARK, spot + Vector3(0, 0.76, 0), Basis(), 12)
	for i in 4:
		var leg := Basis(Vector3.UP, TAU * i / 4.0 + 0.4) * Vector3(1.0, 0, 0)
		home.box(Vector3(0.06, 0.75, 0.06), DARK, spot + leg + Vector3(0, 0.37, 0))
	LowPoly.solid_cylinder(home.body, 1.2, 0.8, home._mirror(spot + Vector3(0, 0.4, 0)))
