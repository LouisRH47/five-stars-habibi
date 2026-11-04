class_name InteriorMarket
extends RefCounted
## Session 58: Grand Groceries inside, laid out like a real supermarket (PRD "Layouts"):
## fruit and veg straight inside the door, drinks fridges along the back wall, the bread
## shelf along the side wall, 3 shelf aisles in a grid in the middle (2.2 m wide, enough
## for two trolleys) with hanging bilingual aisle signs and yellow price strips, and 2
## checkouts at the front by the exit door, with sweets and drinks beside them. You pick up
## at checkout 1. Shoppers push trolleys round the aisles. The room is 24 x 10 m
## (x from -12 to 12; the doors are at x = 0, the entrance, and x = 8, the exit).

const GREEN := Color(0.18, 0.62, 0.31)
const YELLOW := Color(0.98, 0.85, 0.15)
const WHITE := Color(0.97, 0.97, 0.96)
const UNITS := [-9.0, -5.8, -2.6]                 # the 3 shelf units (their middle, x)
const UNIT_FROM := -2.6                           # each unit runs along z from here...
const UNIT_TO := 0.6                              # ...to here (2 sections of 1.6 m)
const AISLES := [["١ وجبات خفيفة", "1 Snacks"], ["٢ أرز ومعكرونة", "2 Rice and pasta"], ["٣ المنزل", "3 Home"]]


static func build(p: InteriorParts) -> void:
	var half := p.size * 0.5
	var back := -half.z + 0.125
	# Drinks fridges along the back wall.
	for k in 10:
		p.prop("kenney_mini_market/freezers-standing", Vector3(-10.0 + k * 2.0, 0, back + 0.42), 0.0, "floor", Vector3(1.98, 1.9, 0.8))
	LowPoly.solid_box(p.body, Vector3(20.0, 1.9, 0.8), Vector3(-1.0, 0.95, back + 0.42))
	p.glow(Vector3(19.8, 0.08, 0.04), Color(0.85, 0.95, 1.0), Vector3(-1.0, 1.95, back + 0.85), 1.2)
	p.sign("مشروبات باردة", "Cold drinks", Vector3(-6.0, 2.35, back + 0.02), 0.0, WHITE, GREEN, 28)
	p.sign("ألبان", "Dairy", Vector3(4.0, 2.35, back + 0.02), 0.0, WHITE, GREEN, 28)
	# The offer boards instead of a menu (Appendix B).
	p.menu_board(Vector3(-1.0, 3.25, back + 0.03), 3.4, InteriorMenus.MENUS["market"], 1.0, YELLOW, Color(0.15, 0.12, 0.1))
	# The bread shelf along the left wall.
	for z in [-1.6, 0.0, 1.6]:
		p.prop("kenney_mini_market/display-bread", Vector3(-half.x + 0.125 + 0.35, 0, z), 90.0, "floor", Vector3(1.5, 1.1, 0.7))
	LowPoly.solid_box(p.body, Vector3(0.7, 1.1, 4.6), Vector3(-half.x + 0.475, 0.55, 0.0))
	p.sign("خبز", "Bread", Vector3(-half.x + 0.14, 2.0, 0.0), 90.0, WHITE, GREEN, 26)
	# The 3 shelf units with yellow price strips and hanging aisle signs.
	for i in UNITS.size():
		var x: float = UNITS[i]
		for k in 2:
			var z := UNIT_FROM + 0.8 + k * 1.6
			p.prop("kenney_mini_market/shelf-boxes" if (i + k) % 2 == 0 else "kenney_mini_market/shelf-bags", Vector3(x, 0, z), 90.0, "floor", Vector3(1.6, 1.8, 1.0))
		p.prop("kenney_mini_market/shelf-end", Vector3(x, 0, UNIT_TO + 0.2), 0.0, "floor", Vector3(1.0, 1.9, 0.4))
		LowPoly.solid_box(p.body, Vector3(1.0, 1.8, UNIT_TO - UNIT_FROM + 0.4), Vector3(x, 0.9, (UNIT_FROM + UNIT_TO + 0.4) * 0.5))
		for side in [-1.0, 1.0]:
			for y in [0.42, 0.92, 1.42]:
				p.box(Vector3(0.02, 0.05, UNIT_TO - UNIT_FROM), YELLOW, Vector3(x + side * 0.51, y, (UNIT_FROM + UNIT_TO) * 0.5))
		var aisle_x := x + 1.6
		for dx in [-0.6, 0.6]:
			if GameConfig.INTERIOR_REVIEW_FIXES:
				p.cord(Vector3(aisle_x + dx, InteriorParts.sign_top(3.35, 26), -1.025))   # down to the sign's top (there was a 5 cm gap)
			else:
				p.box(Vector3(0.015, 0.9, 0.015), Color(0.3, 0.3, 0.3), Vector3(aisle_x + dx, 4.05, -1.0))
		p.sign(AISLES[i][0], AISLES[i][1], Vector3(aisle_x, 3.35, -1.0), 0.0, WHITE, GREEN, 26)
	# Fruit and veg straight inside the entrance (with room to walk in between).
	for x in [-2.6, 2.0]:
		p.prop("kenney_mini_market/display-fruit", Vector3(x, 0, 2.6), 0.0, "floor", Vector3(1.2, 1.0, 1.2))
		LowPoly.solid_box(p.body, Vector3(1.2, 1.0, 1.2), Vector3(x, 0.5, 2.6))
	for k in 3:
		p.prop(["kaykit_restaurant/crate_tomatoes", "kaykit_restaurant/crate_carrots", "kaykit_restaurant/crate_tomatoes"][k], Vector3(-4.4 + k * 0.55, 0, 2.9), 0.0, "floor")
	p.sign("فواكه وخضار", "Fruit and veg", Vector3(-0.3, 2.6, 2.6), 0.0, WHITE, GREEN, 26)
	if GameConfig.INTERIOR_REVIEW_FIXES:
		# Review fix: the sign floated in the air; now it hangs from the ceiling on two cords.
		for dx in [-0.9, 0.9]:
			p.cord(Vector3(-0.3 + dx, InteriorParts.sign_top(2.6, 26), 2.575))
	p.box(Vector3(0.5, 0.05, 0.4), Color(0.6, 0.62, 0.64), Vector3(-1.75, 0.025, 4.3))   # a stack of baskets
	for k in 6:
		p.box(Vector3(0.46, 0.09, 0.36), GREEN, Vector3(-1.75, 0.1 + k * 0.1, 4.3))
	# Two checkouts at the front by the exit, with sweets racks and a drinks cooler.
	_checkout(p, 4.5, true)
	_checkout(p, 7.3, false)
	p.drinks_fridge(Vector3(10.6, 0, 1.4), -90.0, GREEN)
	p.drinks_fridge(Vector3(10.6, 0, 0.6), -90.0, GREEN)
	p.bin(Vector3(10.4, 0, 4.3))
	# A staff door in the back corner, bright white panel lights.
	p.box(Vector3(1.0, 2.1, 0.04), Color(0.6, 0.62, 0.64), Vector3(10.8, 1.05, back + 0.02))
	for x in [-8.0, -2.7, 2.6, 8.0]:
		for z in [-1.8, 2.0]:
			p.glow(Vector3(1.2, 0.03, 0.6), Color(1, 1, 1), Vector3(x, p.size.y - 0.02, z), 1.0)
	for i in 4:
		p.lamp(Vector3([-8.0, -2.7, 2.6, 8.0][i], 0, 0.0), WHITE, i == 1, true)
	# Review fix: the stacker stood in the middle of aisle 1, where a shopper pushes a trolley
	# right through him; now he stands at the shelf he's filling.
	p.worker("Stacker", Vector3(-8.1, 0, -1.2) if GameConfig.INTERIOR_REVIEW_FIXES else Vector3(-7.4, 0, -1.2), -90.0, 4)
	_shoppers(p)


## One checkout (2.5 m long, 0.9 m high) running along z, the cashier on its +x side, the
## lane on its -x side. The first one's cashier hands you the order (CounterStaff).
static func _checkout(p: InteriorParts, x: float, first: bool) -> void:
	var rect := Rect2(x - 0.35, 0.0, 0.7, 2.5)
	p.counter(rect, Color(0.85, 0.86, 0.87), Color(0.3, 0.3, 0.32), 0.9)
	p.box(Vector3(0.45, 0.02, 1.8), Color(0.08, 0.08, 0.09), Vector3(x, 0.91, 0.95))   # the belt
	p.till(Vector3(x + 0.1, 0.9, 2.2), -90.0)
	p.box(Vector3(0.5, 0.5, 0.04), GREEN, Vector3(x, 2.4, 1.2))
	p.sign("", "1" if first else "2", Vector3(x, 2.4, 1.23), 0.0, WHITE, Color(0, 0, 0, 0), 60)
	p.box(Vector3(0.015, 1.8, 0.015), Color(0.3, 0.3, 0.3), Vector3(x, 3.55, 1.2))
	# Sweets on a slim rack beside the lane (not solid: the lane stays clear).
	p.box(Vector3(0.18, 1.2, 0.9), Color(0.8, 0.8, 0.82), Vector3(x - 0.44, 0.6, 0.6))
	for row in 4:
		for k in 5:
			p.box(Vector3(0.05, 0.12, 0.14), [Color(0.9, 0.2, 0.2), YELLOW, Color(0.3, 0.5, 0.9), Color(0.6, 0.3, 0.7)][(row + k) % 4], Vector3(x - 0.54, 0.35 + row * 0.25, 0.25 + k * 0.17))
	p.worker("CounterStaff" if first else "Cashier2", Vector3(x + 0.75, 0, 1.9), -90.0, 2 if first else 4, first)


## Shoppers pushing trolleys round the aisles (VenueMotion walks them).
static func _shoppers(p: InteriorParts) -> void:
	var routes := [[Vector3(-7.4, 0, -3.3), Vector3(-7.4, 0, 1.4), Vector3(-4.2, 0, 1.4), Vector3(-4.2, 0, -3.3)],
			[Vector3(-1.0, 0, -3.3), Vector3(-1.0, 0, 1.2), Vector3(1.2, 0, 1.2), Vector3(1.2, 0, -3.3)],
			[Vector3(-10.4, 0, -3.3), Vector3(-10.4, 0, 1.6)]]
	for i in routes.size():
		var shopper := PeopleLooks.resident(i + 1, i)
		shopper.name = "Shopper%d" % (i + 1)
		shopper.position = routes[i][0]
		p.inside.add_child(shopper)
		shopper.play("walk", 0.7)
		var cart := KitProps.place(shopper, "kenney_mini_market/shopping-cart" if i < 2 else "kenney_mini_market/shopping-basket", Vector3(0, 0, -0.75) if i < 2 else Vector3(0.25, 0.55, 0), 180.0, 1.0, "origin" if i == 2 else "floor")
		if cart != null and i < 2:
			cart.scale = Vector3.ONE * 0.9
		p.motion.walkers.append({"person": shopper, "points": routes[i], "speed": 0.75, "index": 1})
