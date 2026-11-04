class_name InteriorDining
extends RefCounted
## Session 58: the seats in a walk-in room (Appendix B). Order-at-the-counter places use
## most of the room for seating (about 75 to 80%): a window bar with stools along the glass,
## a wall bench with 2-seat tables, and 4-seat tables in the middle, with people eating.
## Sizes from Appendix H: tables 0.75 m high (2-seat 0.7 x 0.7, 4-seat 1.2 x 0.8), chair
## seats 0.45 m, bar stool seats 0.75 m, the window bar 1.05 m high and 0.4 m deep.

const TABLE_TOP := 0.75
const BAR_FRONT := 4.86          # the window bar stops just inside the glass (z = 5)


## The window bar along the glass from x0 to x1, with stools every 0.85 m looking out.
static func window_bar(p: InteriorParts, x0: float, x1: float, top: Color, stool := "kenney_furniture/stoolBar", food := "kenney_food/cup-coffee") -> void:
	var rect := Rect2(minf(x0, x1), BAR_FRONT - 0.4, absf(x1 - x0), 0.4)
	var mid := rect.get_center()
	p.box(Vector3(rect.size.x, 0.05, 0.4), top, Vector3(mid.x, 1.025, mid.y))
	p.box(Vector3(rect.size.x, 1.0, 0.06), top.darkened(0.3), Vector3(mid.x, 0.5, BAR_FRONT - 0.03))
	LowPoly.solid_box(p.body, Vector3(rect.size.x, 1.05, 0.4), Vector3(mid.x, 0.525, mid.y))
	p.counter_tops.append([rect.grow(0.02), 1.05])
	var count := int(rect.size.x / 0.85)
	var spots: Array = []
	for k in count:
		var x := rect.position.x + (k + 0.5) * rect.size.x / count
		spots.append(Vector3(x, 0, BAR_FRONT - 0.85))
		if p.seat(Vector3(x, 0, BAR_FRONT - 0.85), 0.0, 0.75, food) and food != "":
			p.food_on(food, Vector3(x, 0, BAR_FRONT - 0.25), 1.05)
	p.props(stool, spots, spots.map(func(_s): return 180.0))


## A wall bench along a side wall (side -1 = left, +1 = right) from z0 to z1, with 2-seat
## tables in front of it and a chair across each table.
static func wall_bench(p: InteriorParts, side: float, z0: float, z1: float, tables: int, colour: Color, chair: String, food: String) -> void:
	var wall := side * (p.size.x * 0.5 - 0.125)
	var length := absf(z1 - z0)
	var mid := (z0 + z1) * 0.5
	var seat_x := wall - side * 0.3
	p.solid(Vector3(0.55, 0.42, length), colour.darkened(0.2), Vector3(wall - side * 0.275, 0.21, mid))
	p.box(Vector3(0.5, 0.06, length), colour, Vector3(wall - side * 0.28, 0.45, mid))
	p.box(Vector3(0.12, 0.55, length), colour, Vector3(wall - side * 0.06, 0.75, mid))
	p.counter_tops.append([Rect2(minf(wall, wall - side * 0.55), minf(z0, z1), 0.55, length), 0.48])
	var chairs: Array = []
	var turns: Array = []
	for k in tables:
		var z := minf(z0, z1) + (k + 0.5) * length / tables
		var table := Vector3(wall - side * 0.95, 0, z)
		small_table(p, table)
		if p.seat(Vector3(seat_x, 0, z), -side * 90.0, 0.46, food):
			_plate(p, table + Vector3(side * 0.18, 0, 0), food)
		var across := Vector3(wall - side * 1.62, 0, z)
		chairs.append(across)
		turns.append(side * 90.0)
		if p.seat(across, side * 90.0, 0.46, food):
			_plate(p, table - Vector3(side * 0.18, 0, 0), food)
	p.props(chair, chairs, turns)


## A 4-seat table (1.2 x 0.8 m). along_x: its long side runs along x (chairs on the z sides).
static func four_table(p: InteriorParts, at: Vector3, along_x: bool, chair: String, food: String) -> void:
	var size := Vector3(1.2, TABLE_TOP, 0.8) if along_x else Vector3(0.8, TABLE_TOP, 1.2)
	p.prop("kenney_furniture/table", at, 0.0 if along_x else 90.0, "floor", Vector3(1.2, TABLE_TOP, 0.8))
	LowPoly.solid_box(p.body, Vector3(size.x - 0.1, TABLE_TOP, size.z - 0.1), at + Vector3(0, TABLE_TOP * 0.5, 0))
	p.counter_tops.append([Rect2(at.x - size.x * 0.5, at.z - size.z * 0.5, size.x, size.z), TABLE_TOP])
	var chairs: Array = []
	var turns: Array = []
	for side in [-1.0, 1.0]:
		for k in [-1.0, 1.0]:
			var offset := Vector3(k * 0.3, 0, side * 0.68) if along_x else Vector3(side * 0.68, 0, k * 0.3)
			var facing := (180.0 if side > 0 else 0.0) if along_x else (-90.0 if side > 0 else 90.0)
			chairs.append(at + offset)
			turns.append(facing)
			if p.seat(at + offset, facing, 0.46, food):
				_plate(p, at + offset * 0.45, food)
	p.props(chair, chairs, turns)


## A small round table for two (0.7 m across).
static func small_table(p: InteriorParts, at: Vector3) -> void:
	p.prop("kaykit_restaurant/table_round_A_small", at, 0.0, "floor", Vector3(0.7, TABLE_TOP, 0.7))
	LowPoly.solid_cylinder(p.body, 0.33, TABLE_TOP, at + Vector3(0, TABLE_TOP * 0.5, 0))
	p.counter_tops.append([Rect2(at.x - 0.36, at.z - 0.36, 0.72, 0.72), TABLE_TOP])


## A round 2-seat cafe table with two chairs across from each other (facing: the first
## chair's facing in degrees).
static func two_table(p: InteriorParts, at: Vector3, facing: float, chair: String, food: String) -> void:
	small_table(p, at)
	var chairs: Array = []
	var turns: Array = []
	for k in 2:
		var look := facing + k * 180.0
		var spot := at - Vector3(0, 0, 0.62).rotated(Vector3.UP, deg_to_rad(look))
		chairs.append(spot)
		turns.append(look)
		if p.seat(spot, look, 0.46, food):
			_plate(p, at - Vector3(0, 0, 0.17).rotated(Vector3.UP, deg_to_rad(look)), food)
	p.props(chair, chairs, turns)


## A plate with the shop's food on it (and nothing if there's no food model).
static func _plate(p: InteriorParts, at: Vector3, food: String) -> void:
	if food == "":
		return
	if not food.ends_with("cup-coffee") and not food.ends_with("mug"):
		p.cyl(0.13, 0.12, 0.015, Color(0.97, 0.97, 0.95), Vector3(at.x, TABLE_TOP + 0.008, at.z), Basis(), 10)
		p.food_on(food, at, TABLE_TOP + 0.015)
	else:
		p.food_on(food, at, TABLE_TOP)


## The usual dining room (Appendix B) for a 12 x 10 room with the counter at z = -2.2:
## 6 window stools, a wall bench with 3 two-seat tables on `bench_side`, and four 4-seat
## tables in two columns. 28 seats. Leaves the middle aisle (|x| < 1.1) and the aisle in
## front of the counter clear.
static func standard(p: InteriorParts, bench_side: float, wood: Color, bench: Color, chair: String, food: String, cup := "kenney_food/cup-coffee") -> void:
	window_bar(p, -5.75, -2.7, wood, "kenney_furniture/stoolBar", cup)
	window_bar(p, 2.7, 5.75, wood, "kenney_furniture/stoolBar", cup)
	wall_bench(p, bench_side, 3.3, -0.85, 3, bench, chair, food)
	for z in [2.3, 0.05]:
		four_table(p, Vector3(bench_side * 2.6, 0, z), false, chair, food)
		four_table(p, Vector3(-bench_side * 3.6, 0, z), false, chair, food)
