class_name InteriorVenues
extends RefCounted
## Session 58: the first 6 rooms, exactly as in Appendix B and the PRD's Interiors table,
## each based on how that kind of real place is laid out (PRD "Layouts"):
## - 1000 Pizza: a Neapolitan pizzeria, the mosaic dome oven in the back-left corner with
##   the pizza maker and his peel, a marble prep counter, black-and-white floor, red chairs.
## - Brain Freeze Gelato: the curved gelato case faces the door 2 m in, so you choose before
##   you reach the till at its end; seats round the sides and at the back.
## - Spill the Brew: a small specialty cafe; espresso machine, grinders and milk fridge
##   together as one station, the barista facing the customers, the pastry case by the till.
## - Shawarma Supreme: two spits in the front window (seen from outside) behind a long
##   counter down the right side, a lit picture menu across the back wall.
## - Bread & Zaatar: a manakish bakery round its stone oven, dough table, bread racks; no cakes.
## - Grand Groceries: built by InteriorMarket (a real supermarket layout).
## Room directions: x from -6 (left, seen from the door) to +6; z from +5 (glass) to -5.

const COUNTER_FRONT := -2.2   # Appendix B: the counter line 7.2 m in from the glass
const STAFF_Z := -3.15        # where the staff stand behind the counter
const WOOD := Color(0.55, 0.36, 0.22)
const LIGHT_WOOD := Color(0.78, 0.6, 0.4)
const STEEL := Color(0.72, 0.74, 0.77)
const WHITE := Color(0.97, 0.97, 0.95)


## Colours and finishes of each room (floor tiles, walls), plus where its queue stands.
static func style(id: String) -> Dictionary:
	match id:
		"pizza":
			return {"floor": [Color(0.08, 0.08, 0.09), Color(0.95, 0.95, 0.93)], "wall": Color(0.96, 0.93, 0.86),
					"band": Color(0.75, 0.15, 0.15), "back": Color(0.66, 0.33, 0.24)}
		"gelato":
			return {"floor": [Color(0.98, 0.86, 0.9), Color(0.98, 0.98, 0.97)], "wall": Color(0.99, 0.94, 0.96),
					"band": Color(0.95, 0.55, 0.7), "back": Color(0.97, 0.78, 0.86), "till": Vector3(1.9, 0, 3.7)}
		"boba":
			return {"floor": [Color(0.5, 0.34, 0.21), Color(0.68, 0.5, 0.32)], "pattern": "planks", "tile": 0.25,
					"wall": Color(0.95, 0.92, 0.86), "band": Color(0.5, 0.34, 0.21), "back": Color(0.4, 0.28, 0.19)}
		"shawarma":
			return {"floor": [Color(0.88, 0.83, 0.72), Color(0.6, 0.45, 0.3)], "pattern": "border",
					"wall": Color(0.98, 0.97, 0.94), "band": Color(0.12, 0.5, 0.55), "back": Color(0.15, 0.15, 0.17),
					"till": Vector3(1.9, 0, -1.2)}
		"bakery":
			return {"floor": [Color(0.9, 0.8, 0.58), Color(0.8, 0.68, 0.46)], "wall": Color(0.94, 0.88, 0.76),
					"band": Color(0.55, 0.38, 0.22), "back": Color(0.8, 0.72, 0.6)}
		"market":
			return {"floor": [Color(0.92, 0.92, 0.9), Color(0.85, 0.86, 0.85)], "tile": 0.6, "wall": Color(0.97, 0.97, 0.96),
					"band": Color(0.18, 0.62, 0.31), "back": Color(0.95, 0.96, 0.95), "cool": true, "till": Vector3(3.5, 0, 1.1)}
		"thai":
			return {"floor": [Color(0.3, 0.2, 0.13), Color(0.38, 0.26, 0.17)], "pattern": "planks", "tile": 0.25,
					"wall": Color(0.93, 0.85, 0.72), "band": Color(0.7, 0.12, 0.12), "back": Color(0.45, 0.12, 0.12)}
		"sushi":
			return {"floor": [Color(0.72, 0.62, 0.46), Color(0.62, 0.52, 0.38)], "pattern": "planks", "tile": 0.25,
					"wall": Color(0.95, 0.93, 0.88), "band": Color(0.12, 0.2, 0.38), "back": Color(0.12, 0.2, 0.38),
					"till": Vector3(4.8, 0, -1.5)}
		"tacos":
			return {"floor": [Color(0.86, 0.5, 0.32), Color(0.95, 0.9, 0.8)], "wall": Color(0.98, 0.93, 0.8),
					"band": Color(0.1, 0.55, 0.55), "back": Color(0.98, 0.75, 0.3)}
		"burger":
			return {"floor": [Color(0.15, 0.15, 0.16), Color(0.3, 0.3, 0.32)], "wall": Color(0.97, 0.97, 0.97),
					"band": Color(0.9, 0.35, 0.6), "back": Color(0.97, 0.97, 0.97)}
	return {"floor": [Color(0.8, 0.8, 0.8), Color(0.7, 0.7, 0.7)], "wall": Color(0.95, 0.9, 0.8)}


static func build(p: InteriorParts) -> void:
	match p.id:
		"pizza":
			_pizza(p)
		"gelato":
			_gelato(p)
		"boba":
			_brew(p)
		"shawarma":
			_shawarma(p)
		"bakery":
			_bakery(p)
		"market":
			InteriorMarket.build(p)


# ---------------------------------------------------------------- shared bits

## The usual counter along z = -2.2 from x0 to x1 (customers on the +z side), the till at
## till_x, a "Pick up" sign over the pickup end and the three people: the one who hands you
## the bag (CounterStaff), the cashier and the cook.
static func counter_line(p: InteriorParts, x0: float, x1: float, front: Color, top: Color, till_x: float, cook: Vector3, cook_facing := 180.0) -> void:
	p.counter(Rect2(x0, COUNTER_FRONT - GameConfig.INTERIOR_COUNTER_DEPTH, x1 - x0, GameConfig.INTERIOR_COUNTER_DEPTH), front, top)
	p.till(Vector3(till_x, GameConfig.INTERIOR_COUNTER_HEIGHT, COUNTER_FRONT - 0.3))
	var pickup := InteriorMenus.PICKUP[p.id] as Vector3
	pickup_sign(p, Vector3(pickup.x, 2.55, COUNTER_FRONT - 0.3))
	p.worker("CounterStaff", Vector3(pickup.x, 0, STAFF_Z), 0.0, 2, true)
	p.worker("Cashier", Vector3(till_x, 0, STAFF_Z), 0.0, 4)
	p.worker("Cook", cook, cook_facing, 0)


## A small sign hanging from the ceiling over the pickup spot.
static func pickup_sign(p: InteriorParts, at: Vector3, facing := 0.0) -> void:
	for dx in [-0.35, 0.35]:
		p.box(Vector3(0.015, p.size.y - at.y - 0.25, 0.015), Color(0.1, 0.1, 0.1),
				at + Vector3(dx, (p.size.y - at.y) * 0.5 + 0.12, 0).rotated(Vector3.UP, deg_to_rad(facing)))
	p.sign("استلام الطلبات", "Pick up", at, facing, Color.WHITE, p.brand.darkened(0.25), 24)


## Kitchen counters along the back wall from x0 to x1 (kit models, made 0.65 m deep).
static func back_counters(p: InteriorParts, x0: float, x1: float, sink_at := -1) -> void:
	var count := maxi(1, floori((x1 - x0) / 1.4))
	var each := (x1 - x0) / count
	var back := -p.size.z * 0.5 + 0.125
	for k in count:
		var model := "kaykit_restaurant/kitchencounter_sink" if k == sink_at else "kaykit_restaurant/kitchencounter_straight_A"
		var fit := Vector3(each, 0.92, 0.65) if k != sink_at else Vector3(each, 1.55, 0.65)
		p.prop(model, Vector3(x0 + (k + 0.5) * each, 0, back + 0.33), 0.0, "floor", fit)
	LowPoly.solid_box(p.body, Vector3(x1 - x0, 0.92, 0.65), Vector3((x0 + x1) * 0.5, 0.46, back + 0.33))
	p.counter_tops.append([Rect2(x0, back, x1 - x0, 0.66), 0.92])


## A tall kitchen fridge against the back wall.
static func kitchen_fridge(p: InteriorParts, x: float) -> void:
	var back := -p.size.z * 0.5 + 0.125
	p.prop("kaykit_restaurant/fridge_A", Vector3(x, 0, back + 0.36), 0.0, "floor", Vector3(0.8, 2.0, 0.7))
	LowPoly.solid_box(p.body, Vector3(0.8, 2.0, 0.7), Vector3(x, 1.0, back + 0.36))


## The extras every dining room has: a drinks fridge by the counter end, a bin by the door,
## plants in the corners and the hanging lamps.
static func extras(p: InteriorParts, fridge: Vector3, plants: Array, lamps: Array, shade: Color) -> void:
	p.drinks_fridge(fridge, 0.0)
	p.bin(Vector3(1.75, 0, 4.35))
	for spot: Vector3 in plants:
		p.plant(spot)
	for i in lamps.size():
		p.lamp(lamps[i], shade, i == 0)


# ---------------------------------------------------------------- 1000 Pizza

static func _pizza(p: InteriorParts) -> void:
	var red := Color(0.78, 0.13, 0.13)
	# Brick-look back wall.
	for row in 17:
		for k in 25:
			var x := -6.0 + k * 0.5 + (0.25 if row % 2 == 1 else 0.0)
			if x - 0.24 < -5.87 or x + 0.24 > 5.87:
				continue
			var shade := Color(0.7, 0.35, 0.25).darkened(float((k * 7 + row * 3) % 5) * 0.05)
			p.box(Vector3(0.47, 0.22, 0.02), shade, Vector3(x, 0.14 + row * 0.25, -4.865))
	# The dome oven in the back-left corner, turned so its fiery mouth looks at the door
	# over the counter; the pizza maker works beside it with his long peel.
	InteriorMachines.pizza_oven(p, Vector3(-4.95, 0, -3.95), 29.0)
	InteriorMachines.peel(p, Vector3(-3.45, 1.12, -3.1), Vector3(-4.42, 1.12, -3.3), 60.0, Color(0.95, 0.75, 0.35))
	# The counter: marble prep side (dough balls, topping tubs) and the till side.
	counter_line(p, -4.0, 4.0, red, Color(0.93, 0.93, 0.92), 2.8, Vector3(-3.55, 0, -3.6), -77.0)
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	for k in 6:
		p.kit.ball(0.07, Color(0.97, 0.93, 0.82), Vector3(-2.3 + (k % 3) * 0.17, top + 0.06, -2.62 + (k / 3) * 0.15), 0.7)
	for k in 5:
		var tub: Color = [Color(0.8, 0.15, 0.1), Color(0.98, 0.95, 0.85), Color(0.25, 0.55, 0.2), Color(0.55, 0.3, 0.2), Color(0.95, 0.8, 0.3)][k]
		p.box(Vector3(0.14, 0.08, 0.14), STEEL, Vector3(-1.4 + k * 0.17, top + 0.04, -2.65))
		p.box(Vector3(0.12, 0.02, 0.12), tub, Vector3(-1.4 + k * 0.17, top + 0.08, -2.65))
	p.food_on("kenney_food/pizza", Vector3(-0.3, 0, -2.5), top)
	for k in 7:   # a stack of pizza boxes by the till
		p.box(Vector3(0.36, 0.045, 0.36), Color(0.82, 0.68, 0.48), Vector3(1.9, top + 0.023 + k * 0.047, -2.5))
	p.box(Vector3(0.2, 0.002, 0.2), red, Vector3(1.9, top + 7 * 0.047 + 0.001, -2.5))
	# Kitchen: counters, a fridge and the menu board above.
	back_counters(p, -1.6, 4.6)
	kitchen_fridge(p, 5.3)
	for k in 4:
		p.box(Vector3(0.36, 0.045, 0.36), Color(0.82, 0.68, 0.48), Vector3(3.6, 0.92 + 0.023 + k * 0.047, -4.4))
	p.menu_board(Vector3(1.0, 3.2, -4.84), 4.0, InteriorMenus.MENUS["pizza"])
	# A framed photo of Italy and basil pots on the window bar.
	p.prop("kaykit_furniture/pictureframe_large_A", Vector3(5.875, 1.5, 1.2), -90.0, "wall")
	InteriorDining.standard(p, 1.0, Color(0.35, 0.22, 0.14), red, "kaykit_restaurant/chair_A", "kenney_food/pizza", "kenney_food/soda-can")
	for x in [-5.55, 5.55]:
		p.prop("kenney_furniture/plantSmall1", Vector3(x, 0, 4.66), 0.0, "counter")
	extras(p, Vector3(5.35, 0, -1.6), [Vector3(-5.45, 0, -1.6)], [Vector3(-3.6, 0, 1.2), Vector3(2.6, 0, 1.2), Vector3(-3.6, 0, -0.6), Vector3(2.6, 0, 3.0)], red)


# ---------------------------------------------------------------- Brain Freeze Gelato

static func _gelato(p: InteriorParts) -> void:
	var pink := Color(0.94, 0.44, 0.64)
	# Pink and white stripes on the side walls.
	for side in [-1.0, 1.0]:
		for k in 20:
			if k % 2 == 0:
				p.box(Vector3(0.02, 3.3, 0.5), pink.lightened(0.25), Vector3(side * 5.865, 2.75, -4.75 + k * 0.5))
	# The gelato case, 2 m in from the door and facing it; the till at its end.
	InteriorMachines.gelato_case(p, Vector3(0, 0, 2.5), 0.0, InteriorMenus.FLAVOURS)
	p.counter(Rect2(1.5, 2.0, 0.8, 1.0), pink, WHITE)
	p.till(Vector3(1.9, GameConfig.INTERIOR_COUNTER_HEIGHT, 2.5), 180.0)
	p.counter(Rect2(-2.3, 2.0, 0.8, 1.0), pink, WHITE)
	# The back counter behind the server: cones, cups and toppings jars.
	p.counter(Rect2(-2.3, 0.3, 4.6, 0.6), WHITE, Color(0.98, 0.9, 0.93))
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	for k in 3:
		for n in 6:
			p.cyl(0.035, 0.0, 0.14, Color(0.85, 0.62, 0.32), Vector3(-1.9 + k * 0.12, top + 0.07 + n * 0.035, 0.6), Basis(Vector3.RIGHT, PI), 8)
	for k in 6:
		p.prop("kaykit_restaurant/jar_A_large", Vector3(-0.8 + k * 0.22, 0, 0.6), 0.0, "counter")
	for k in 4:
		p.cyl(0.05, 0.04, 0.1, [WHITE, pink, Color(0.6, 0.85, 0.95), WHITE][k], Vector3(1.0 + k * 0.13, top + 0.05, 0.6), Basis(), 8)
	p.food_on("kenney_food/ice-cream", Vector3(-1.1, 0, 2.3), 1.21)
	p.food_on("kenney_food/ice-cream", Vector3(-0.9, 0, 2.3), 1.21)
	# The menu hangs from the ceiling over the back counter, facing the door.
	for dx in [-1.6, 1.6]:
		p.box(Vector3(0.015, 0.95, 0.015), Color(0.2, 0.2, 0.2), Vector3(dx, 4.02, 0.6))
	p.menu_board(Vector3(0, 3.0, 0.62), 3.6, InteriorMenus.MENUS["gelato"], 1.1, Color(0.99, 0.95, 0.97), Color(0.35, 0.15, 0.25))
	p.worker("CounterStaff", Vector3(-0.9, 0, 1.55), 0.0, 2, true)
	p.worker("Cashier", Vector3(1.85, 0, 1.55), 0.0, 4)
	# The server's scoop dips in and out of the tubs.
	var scoop := Node3D.new()
	scoop.position = Vector3(-0.55, 1.05, 2.35)
	scoop.set_meta("rest_y", 1.05)
	LowPoly.cylinder(scoop, 0.012, 0.012, 0.25, STEEL, Vector3(0, 0.15, -0.05))
	LowPoly.sphere(scoop, 0.04, 0.06, STEEL, Vector3.ZERO)
	p.inside.add_child(scoop)
	p.motion.knives.append(scoop)
	# The gelato lab at the back (where it's made) and a big cone sign.
	back_counters(p, -5.0, -0.6)
	p.solid(Vector3(0.8, 1.2, 0.7), STEEL, Vector3(0.0, 0.6, -4.45))   # the batch freezer
	p.cyl(0.18, 0.18, 0.06, Color(0.2, 0.2, 0.22), Vector3(0.0, 0.85, -4.08), Basis(Vector3.RIGHT, PI * 0.5), 12)
	p.counter_tops.append([Rect2(-0.4, -4.8, 0.8, 0.7), 1.2])
	p.worker("Cook", Vector3(-2.6, 0, -3.75), 180.0, 0)
	p.cyl(0.0, 0.32, 0.9, Color(0.85, 0.62, 0.32), Vector3(3.6, 2.4, -4.82), Basis(Vector3.RIGHT, PI) , 10)
	for k in 3:
		p.kit.ball(0.3, [pink, Color(0.98, 0.94, 0.8), Color(0.55, 0.35, 0.2)][k], Vector3(3.6 + (k - 1) * 0.28, 3.0 + (1 if k == 1 else 0) * 0.3, -4.75), 1.0)
	p.sign("برين فريز", "BRAIN FREEZE", Vector3(3.6, 1.6, -4.84), 0.0, pink.darkened(0.3), Color(0, 0, 0, 0), 34)
	# Seats: window stools, round tables at the sides, 4-seat tables at the back.
	var chair := "kenney_furniture/chair"
	InteriorDining.window_bar(p, -5.75, -2.7, Color(0.98, 0.9, 0.93), "kenney_furniture/stoolBar", "kenney_food/sundae")
	InteriorDining.window_bar(p, 2.7, 5.75, Color(0.98, 0.9, 0.93), "kenney_furniture/stoolBar", "kenney_food/sundae")
	for side in [-1.0, 1.0]:
		for z in [2.2, 0.6]:
			InteriorDining.two_table(p, Vector3(side * 4.3, 0, z), 90.0, chair, "kenney_food/ice-cream")
	for x in [-4.3, -1.45, 1.45, 4.3]:
		InteriorDining.four_table(p, Vector3(x, 0, -1.8), true, chair, "kenney_food/sundae")
	p.drinks_fridge(Vector3(5.4, 0, -4.3), 0.0)
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(-5.45, 0, -4.3))
	p.plant(Vector3(-2.9, 0, 3.6))
	for i in 4:
		p.lamp([Vector3(-4.3, 0, 1.4), Vector3(4.3, 0, 1.4), Vector3(-2.9, 0, -1.8), Vector3(2.9, 0, -1.8)][i], pink, i == 0)


# ---------------------------------------------------------------- Spill the Brew

static func _brew(p: InteriorParts) -> void:
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	var counter_top := Vector3(0, top, COUNTER_FRONT - 0.3)
	counter_line(p, -4.0, 4.0, WOOD, Color(0.9, 0.88, 0.84), 3.1, Vector3(-0.6, 0, STAFF_Z), 0.0)
	# One station: grinders, the espresso machine, the milk fridge under the counter.
	InteriorMachines.espresso_machine(p, counter_top + Vector3(-0.6, 0, 0), 0.0)
	InteriorMachines.grinder(p, counter_top + Vector3(0.05, 0, 0.0), 0.0)
	InteriorMachines.grinder(p, counter_top + Vector3(0.35, 0, 0.0), 0.0)
	p.box(Vector3(1.2, 0.8, 0.02), Color(0.85, 0.86, 0.88), Vector3(-0.6, 0.45, COUNTER_FRONT - 0.61))
	p.box(Vector3(0.02, 0.6, 0.04), Color(0.3, 0.3, 0.3), Vector3(-0.6, 0.5, COUNTER_FRONT - 0.63))
	# The pastry case by the till: croissants, cookies and 3 cakes on stands.
	InteriorMachines.pastry_case(p, counter_top + Vector3(1.75, 0, 0), 0.0)
	for k in 3:
		p.cyl(0.04, 0.035, 0.09, WHITE, Vector3(-2.2 + k * 0.1, top + 0.045, -2.5), Basis(), 8)
	p.food_on("kenney_food/cup-coffee", Vector3(-3.0, 0, -2.45), top)
	# Behind: bean bags on shelves, a sink counter, the fridge and the menu board.
	for y in [1.45, 2.0]:
		p.box(Vector3(3.6, 0.04, 0.3), LIGHT_WOOD, Vector3(-3.2, y, -4.72))
		for k in 9:
			p.box(Vector3(0.18, 0.28, 0.12), [Color(0.45, 0.3, 0.2), Color(0.85, 0.8, 0.7), Color(0.3, 0.2, 0.14)][k % 3], Vector3(-4.8 + k * 0.4, y + 0.16, -4.7))
	back_counters(p, 0.4, 4.6, 1)
	kitchen_fridge(p, 5.3)
	p.menu_board(Vector3(1.0, 3.2, -4.84), 4.0, InteriorMenus.MENUS["boba"], 1.2, Color(0.12, 0.12, 0.12))
	# Seats: window stools, a sofa corner with a rug, round tables, a plant wall.
	InteriorDining.window_bar(p, -5.75, -2.7, LIGHT_WOOD, "kenney_furniture/stoolBar", "kenney_food/cup-coffee")
	InteriorDining.window_bar(p, 2.7, 5.75, LIGHT_WOOD, "kenney_furniture/stoolBar", "kenney_food/cup-coffee")
	p.prop("kaykit_furniture/rug_rectangle_A", Vector3(-4.3, 0, 1.0), 90.0, "floor", Vector3(2.6, 0.02, 2.0))
	p.prop("kaykit_furniture/couch", Vector3(-5.2, 0, 1.0), 90.0, "floor", Vector3(2.3, 0.9, 1.0))
	LowPoly.solid_box(p.body, Vector3(0.9, 0.5, 2.2), Vector3(-5.3, 0.25, 1.0))
	for k in 3:
		p.seat(Vector3(-5.25, 0, 0.25 + k * 0.75), 90.0, 0.45, "kenney_food/mug")
	p.prop("kaykit_furniture/table_low", Vector3(-4.05, 0, 1.0), 90.0, "floor", Vector3(1.1, 0.42, 0.6))
	p.counter_tops.append([Rect2(-4.35, 0.45, 0.6, 1.1), 0.42])
	p.food_on("kenney_food/mug", Vector3(-4.05, 0, 0.8), 0.42)
	p.food_on("kenney_food/croissant", Vector3(-4.0, 0, 1.25), 0.42)
	for z in [2.55, -0.55]:
		p.prop("kaykit_furniture/armchair", Vector3(-3.15, 0, z), -90.0 + (45.0 if z > 1.0 else -45.0) * -1.0, "floor", Vector3(0.95, 0.9, 0.85))
		p.seat(Vector3(-3.15, 0, z), -90.0 + (45.0 if z > 1.0 else -45.0) * -1.0, 0.45, "kenney_food/mug")
	# The plant wall on the right, with round tables in front of it.
	p.box(Vector3(0.06, 2.6, 4.2), Color(0.2, 0.42, 0.2), Vector3(5.84, 2.2, 1.3))
	for k in 60:
		var leaf := Vector3(5.78, 1.0 + float((k * 37) % 23) / 23.0 * 2.4, -0.7 + float((k * 53) % 41) / 41.0 * 4.0)
		p.kit.ball(0.16 + float(k % 3) * 0.05, Color(0.25, 0.55 + float(k % 4) * 0.06, 0.25), leaf, 0.8)
	var chair := "kenney_furniture/chair"
	for z in [2.6, 1.2, -0.2]:
		InteriorDining.two_table(p, Vector3(4.6, 0, z), 90.0, chair, "kenney_food/cup-coffee")
	for z in [2.5, 0.3]:
		InteriorDining.two_table(p, Vector3(2.15, 0, z), 0.0, chair, "kenney_food/croissant")
	InteriorDining.two_table(p, Vector3(-1.8, 0, -0.3), 90.0, chair, "kenney_food/cup-coffee")
	extras(p, Vector3(5.35, 0, -1.6), [Vector3(-5.45, 0, -1.6), Vector3(-5.45, 0, 3.4)],
			[Vector3(-4.2, 0, 1.0), Vector3(3.4, 0, 1.6), Vector3(-1.8, 0, 2.6), Vector3(3.4, 0, -0.6)], Color(0.15, 0.15, 0.15))


# ---------------------------------------------------------------- Shawarma Supreme

static func _shawarma(p: InteriorParts) -> void:
	var orange := Color(0.91, 0.6, 0.18)
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	# The long counter down the right side; the kitchen strip behind it.
	p.counter(Rect2(2.55, -3.8, 0.6, 8.5), Color(0.96, 0.95, 0.92), Color(0.75, 0.73, 0.7))
	for k in 34:   # Arabic patterned tiles on the counter front
		for row in 3:
			var colour: Color = [Color(0.1, 0.45, 0.55), Color(0.95, 0.95, 0.9), Color(0.2, 0.3, 0.6)][(k + row) % 3]
			p.box(Vector3(0.02, 0.17, 0.17), colour, Vector3(2.535, 0.32 + row * 0.24, -3.65 + k * 0.245), Basis(Vector3.RIGHT, PI * 0.25))
	# Two spits in the front window, seen from outside, with the cook slicing.
	InteriorMachines.shawarma_spit(p, Vector3(4.3, 0, 4.25), -90.0, true)
	InteriorMachines.shawarma_spit(p, Vector3(4.3, 0, 3.25), -90.0, false)
	p.worker("Cook", Vector3(3.65, 0, 3.75), 90.0, 0)
	var knife := Node3D.new()
	knife.position = Vector3(3.95, 1.3, 3.75)
	knife.set_meta("rest_y", 1.3)
	LowPoly.box(knife, Vector3(0.02, 0.35, 0.05), STEEL, Vector3.ZERO)
	p.inside.add_child(knife)
	p.motion.knives.append(knife)
	# On the counter: bread stack, sauce bottles, wraps ready to go.
	for k in 8:
		p.cyl(0.15, 0.15, 0.008, Color(0.93, 0.85, 0.65), Vector3(2.85, top + 0.005 + k * 0.009, 0.3), Basis(), 12)
	for k in 6:
		p.cyl(0.035, 0.035, 0.2, [Color(0.95, 0.95, 0.9), Color(0.8, 0.15, 0.1)][k % 2], Vector3(2.75 + (k % 2) * 0.1, top + 0.1, -0.3 + (k / 2) * 0.1), Basis(), 8)
	for k in 3:
		p.cyl(0.035, 0.035, 0.22, Color(0.95, 0.85, 0.6), Vector3(2.9, top + 0.035, 1.9 + k * 0.1), Basis(Vector3.FORWARD, PI * 0.5), 8)
	p.till(Vector3(2.85, top, -1.2), 90.0)
	pickup_sign(p, Vector3(2.85, 2.55, 1.6), -90.0)
	p.worker("CounterStaff", Vector3(3.65, 0, 1.6), -90.0, 2, true)
	p.worker("Cashier", Vector3(3.65, 0, -1.2), -90.0, 4)
	# The fries station and a fridge at the back of the strip.
	p.solid(Vector3(0.7, 0.9, 0.9), STEEL, Vector3(5.45, 0.45, -2.4))
	for dz in [-0.2, 0.2]:
		p.box(Vector3(0.5, 0.02, 0.32), Color(0.75, 0.6, 0.2), Vector3(5.45, 0.88, -2.4 + dz))
		p.box(Vector3(0.3, 0.12, 0.25), Color(0.55, 0.55, 0.57), Vector3(5.3, 0.97, -2.4 + dz))
	p.counter_tops.append([Rect2(5.1, -2.85, 0.7, 0.9), 0.9])
	p.prop("kaykit_restaurant/kitchencounter_straight_A", Vector3(5.45, 0, -0.9), -90.0, "floor", Vector3(1.6, 0.92, 0.7))
	LowPoly.solid_box(p.body, Vector3(0.7, 0.92, 1.6), Vector3(5.45, 0.46, -0.9))
	p.counter_tops.append([Rect2(5.1, -1.7, 0.7, 1.6), 0.92])
	p.prop("kenney_furniture/kitchenBlender", Vector3(5.45, 0.92 - GameConfig.KIT_COUNTER_HEIGHT, -0.5), -90.0, "counter")
	p.worker("FriesCook", Vector3(4.5, 0, -2.4), 90.0, 1)
	p.prop("kaykit_restaurant/fridge_A", Vector3(5.45, 0, -4.35), -90.0, "floor", Vector3(0.8, 2.0, 0.7))
	LowPoly.solid_box(p.body, Vector3(0.7, 2.0, 0.8), Vector3(5.45, 1.0, -4.35))
	# The lit picture menu across the whole back wall.
	picture_menu(p, InteriorMenus.MENUS["shawarma"], [Color(0.9, 0.7, 0.4), Color(0.6, 0.35, 0.2), Color(0.85, 0.55, 0.3), Color(0.95, 0.8, 0.3), Color(0.95, 0.55, 0.2)])
	# Seats: window stools, six 4-seat tables, juice fridges.
	var chair := "kaykit_restaurant/chair_A"
	InteriorDining.window_bar(p, -5.75, -2.7, Color(0.35, 0.3, 0.25), "kenney_furniture/stoolBar", "kenney_food/soda-bottle")
	for z in [2.0, -0.4, -2.8]:
		InteriorDining.four_table(p, Vector3(-4.3, 0, z), false, chair, "kenney_food/sandwich")
		InteriorDining.four_table(p, Vector3(-1.45, 0, z), false, chair, "kenney_food/fries")
	p.drinks_fridge(Vector3(-5.4, 0, -4.45), 0.0, Color(0.9, 0.55, 0.15))
	p.drinks_fridge(Vector3(-4.6, 0, -4.45), 0.0, Color(0.9, 0.55, 0.15))
	p.bin(Vector3(-1.75, 0, 4.35))
	p.plant(Vector3(1.6, 0, -4.4))
	p.plant(Vector3(-2.3, 0, 3.75))
	for i in 4:
		p.lamp([Vector3(-2.9, 0, 0.8), Vector3(-2.9, 0, -2.0), Vector3(0.9, 0, -0.4), Vector3(-2.9, 0, 3.0)][i], orange, i == 0)


## A lit menu with pictures across the whole back wall (for the shawarma place).
static func picture_menu(p: InteriorParts, items: Array, food_colours: Array) -> void:
	var back := -p.size.z * 0.5 + 0.125
	var width := p.size.x - 0.5
	p.glow(Vector3(width, 1.3, 0.04), Color(1.0, 0.97, 0.9), Vector3(0, 3.1, back + 0.03), 0.6)
	var holder := Node3D.new()
	holder.name = "MenuBoard"
	holder.position = Vector3(0, 3.1, back + 0.07)
	holder.add_to_group("menu_board")
	holder.set_meta("items", items)
	p.body.add_child(holder)
	var each := width / items.size()
	for i in items.size():
		var x := -width * 0.5 + (i + 0.5) * each
		p.box(Vector3(each - 0.25, 0.75, 0.02), p.brand.lightened(0.2), Vector3(x, 3.3, back + 0.06))
		p.cyl(0.26, 0.26, 0.02, WHITE, Vector3(x, 3.3, back + 0.08), Basis(Vector3.RIGHT, PI * 0.5), 14)
		p.kit.ball(0.17, food_colours[i], Vector3(x, 3.3, back + 0.1), 0.5)
		var name_label := SignText.make_label(str(items[i][0]), 30, Color(0.15, 0.1, 0.05), Color(0, 0, 0, 0), 0)
		name_label.position = Vector3(x, -0.33, 0)
		holder.add_child(name_label)
		var price := SignText.make_label("%s Dh" % str(items[i][1]), 34, Color(0.8, 0.2, 0.1), Color(0, 0, 0, 0), 0)
		price.position = Vector3(x, -0.52, 0)
		holder.add_child(price)


# ---------------------------------------------------------------- Bread & Zaatar

static func _bakery(p: InteriorParts) -> void:
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	counter_line(p, -4.0, 4.0, LIGHT_WOOD, Color(0.62, 0.42, 0.26), 2.8, Vector3(-0.2, 0, -3.35), 180.0)
	# Baskets of khubz on the counter by the till, and a rack of bread behind.
	for k in 3:
		var basket := Vector3(0.9 + k * 0.45, top, -2.5)
		p.cyl(0.19, 0.15, 0.12, Color(0.7, 0.52, 0.3), basket + Vector3(0, 0.06, 0), Basis(), 10)
		for n in 4:
			p.cyl(0.14, 0.14, 0.012, Color(0.9, 0.75, 0.48), basket + Vector3(0, 0.12 + n * 0.014, 0), Basis(Vector3.RIGHT, 0.2), 10)
	# The stone manakish oven in the back middle, the baker and his peel.
	# The oven stands on a 0.35 m stone plinth, so its mouth is at working height and you
	# can see the fire over the counter.
	p.solid(Vector3(2.3, 0.35, 1.05), Color(0.55, 0.5, 0.44), Vector3(0, 0.175, -4.35))
	p.counter_tops.append([Rect2(-1.15, -4.875, 2.3, 1.05), 0.35])
	InteriorMachines.manakish_oven(p, Vector3(0, 0.35, -4.375), 0.0)
	InteriorMachines.peel(p, Vector3(-0.2, 1.35, -3.1), Vector3(0.0, 1.2, -3.95), 180.0, Color(0.85, 0.7, 0.4), false)
	# The dough table with rolled-out rounds and bowls of zaatar and cheese.
	back_counters(p, -5.0, -1.4)
	for k in 4:
		p.cyl(0.15, 0.15, 0.01, Color(0.96, 0.92, 0.82), Vector3(-4.6 + k * 0.4, 0.93, -4.45), Basis(), 12)
	for k in 3:
		p.cyl(0.11, 0.08, 0.08, WHITE, Vector3(-2.9 + k * 0.32, 0.96, -4.35), Basis(), 10)
		p.cyl(0.09, 0.09, 0.01, [Color(0.35, 0.45, 0.2), Color(0.98, 0.95, 0.85), Color(0.8, 0.2, 0.1)][k], Vector3(-2.9 + k * 0.32, 0.995, -4.35), Basis(), 10)
	p.worker("Baker2", Vector3(-3.3, 0, -3.75), 180.0, 3)
	# The bread rack: wooden shelves of khubz.
	p.solid(Vector3(2.6, 2.0, 0.5), LIGHT_WOOD.darkened(0.2), Vector3(3.2, 1.0, -4.62))
	for y in [0.45, 0.95, 1.45]:
		p.box(Vector3(2.5, 0.04, 0.42), LIGHT_WOOD, Vector3(3.2, y, -4.4))
		for k in 6:
			p.cyl(0.17, 0.17, 0.06, Color(0.9, 0.74, 0.46), Vector3(2.15 + k * 0.42, y + 0.05, -4.38), Basis(Vector3.RIGHT, 0.25), 10)
	p.menu_board(Vector3(3.2, 3.2, -4.84), 3.6, InteriorMenus.MENUS["bakery"], 1.2, Color(0.2, 0.14, 0.09))
	# Hanging bread baskets over the long shared table.
	for k in 3:
		var at := Vector3(-3.4, 3.4, 2.4 - k * 1.2)
		p.box(Vector3(0.015, p.size.y - at.y, 0.015), Color(0.3, 0.25, 0.2), at + Vector3(0, (p.size.y - at.y) * 0.5, 0))
		p.cyl(0.25, 0.2, 0.18, Color(0.7, 0.52, 0.3), at - Vector3(0, 0.09, 0), Basis(), 10)
	# Seats: window stools, the long shared table, a wall bench and 4-seat tables.
	var chair := "kenney_furniture/chair"
	InteriorDining.window_bar(p, -5.75, -2.7, LIGHT_WOOD, "kenney_furniture/stoolBar", "kenney_food/mug")
	InteriorDining.window_bar(p, 2.7, 5.75, LIGHT_WOOD, "kenney_furniture/stoolBar", "kenney_food/mug")
	_long_table(p, Vector3(-3.4, 0, 1.15), chair)
	InteriorDining.wall_bench(p, 1.0, 3.3, -0.85, 3, Color(0.6, 0.4, 0.25), chair, "kenney_food/bread")
	for z in [2.3, 0.05]:
		InteriorDining.four_table(p, Vector3(2.6, 0, z), false, chair, "kenney_food/bread")
	extras(p, Vector3(5.35, 0, -1.6), [Vector3(-5.45, 0, -1.6)],
			[Vector3(-1.6, 0, 1.2), Vector3(3.6, 0, 1.2), Vector3(-1.6, 0, -0.6), Vector3(3.6, 0, 3.0)], Color(0.7, 0.52, 0.3))


## A long shared wooden table (3.2 x 0.9 m) along z, with 4 chairs on each side.
static func _long_table(p: InteriorParts, at: Vector3, chair: String) -> void:
	p.box(Vector3(0.9, 0.06, 3.2), Color(0.5, 0.33, 0.2), at + Vector3(0, 0.72, 0))
	for dz in [-1.4, 1.4]:
		for dx in [-0.35, 0.35]:
			p.box(Vector3(0.07, 0.69, 0.07), Color(0.4, 0.26, 0.16), at + Vector3(dx, 0.345, dz))
	LowPoly.solid_box(p.body, Vector3(0.8, 0.75, 3.1), at + Vector3(0, 0.375, 0))
	p.counter_tops.append([Rect2(at.x - 0.45, at.z - 1.6, 0.9, 3.2), 0.75])
	var chairs: Array = []
	var turns: Array = []
	for side in [-1.0, 1.0]:
		for k in 4:
			var spot := at + Vector3(side * 0.72, 0, -1.2 + k * 0.8)
			chairs.append(spot)
			turns.append(-side * 90.0)
			if p.seat(spot, -side * 90.0, 0.46, "kenney_food/bread"):
				p.food_on("kenney_food/bread", at + Vector3(side * 0.22, 0, -1.2 + k * 0.8), 0.75)
	p.props(chair, chairs, turns)
