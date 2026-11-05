class_name InteriorVenuesB
extends RefCounted
## Session 59: the other 4 restaurants inside (Appendix B, PRD Interiors), on the Session 58
## room template (InteriorRoom), each laid out like the real kind of place:
## - Tok Tok Thai: Thai street food. An open kitchen with woks over flames, a decorated tuk-tuk
##   inside as a photo spot, red lanterns, bunting and fairy lights, a dark wood floor.
## - Sushi You: a conveyor-belt sushi bar (kaiten): the belt runs round a ring-shaped bar with
##   the chefs in the middle and stools all round, a glass fish case, a booth, paper lanterns,
##   bamboo, a navy curtain over the kitchen door and a separate pick-up counter.
## - Mario Bonito: a taco counter with a flat grill and salsa tubs, a colourful tile band,
##   paper bunting (papel picado) and cactus pots.
## - Burgerology: a flat grill with patties, a fryer, a heat-lamp pass, a pink neon sign and
##   white metro tiles, a stool ledge.
## Room directions: x from -6 (left, seen from the door) to +6; z from +5 (glass) to -5.

const WOOD := Color(0.3, 0.2, 0.13)
const WHITE := Color(0.97, 0.97, 0.95)


static func build(p: InteriorParts) -> void:
	match p.id:
		"thai":
			_thai(p)
		"sushi":
			_sushi(p)
		"tacos":
			_tacos(p)
		"burger":
			_burger(p)
		_:
			_plain(p)


## The plain Session 58 template (any other restaurant): counter, kitchen, menu, seats.
static func _plain(p: InteriorParts) -> void:
	InteriorVenues.counter_line(p, -4.0, 4.0, p.brand, Color(0.9, 0.9, 0.88), 2.8, Vector3(1.0, 0, -3.8))
	InteriorVenues.back_counters(p, -5.6, 4.4)
	InteriorVenues.kitchen_fridge(p, 5.3)
	p.menu_board(Vector3(0, 3.2, -4.84), 4.0, InteriorMenus.MENUS.get(p.id, []))
	InteriorDining.standard(p, 1.0, Color(0.4, 0.3, 0.2), p.brand, "kenney_furniture/chair", "kenney_food/plate")
	InteriorVenues.extras(p, Vector3(5.35, 0, -1.6), [Vector3(-5.45, 0, -1.6)],
			[Vector3(-3.6, 0, 1.2), Vector3(2.6, 0, 1.2), Vector3(-3.6, 0, -0.6), Vector3(2.6, 0, 3.0)], p.brand)


## Strings of little flags (bunting / papel picado) across the room at height y. The string
## sags in the middle and every flag hangs from it.
static func _bunting(p: InteriorParts, zs: Array, y: float, colours: Array, square := false) -> void:
	for z: float in zs:
		var points: Array = [Vector3(-5.87, y, z)]
		for k in 30:
			var x := -5.6 + k * 0.385
			var sag := 0.25 * (1.0 - pow((x / 5.85), 2.0))
			var colour: Color = colours[k % colours.size()]
			points.append(Vector3(x, y - sag, z))
			if square:
				p.box(Vector3(0.3, 0.24, 0.005), colour, Vector3(x, y - sag - 0.12, z))
			else:
				p.box(Vector3(0.18, 0.18, 0.005), colour, Vector3(x, y - sag - 0.1, z), Basis(Vector3.BACK, PI * 0.25))
		points.append(Vector3(5.87, y, z))
		_string(p, points, Color(0.9, 0.9, 0.85))


## A thin string or wire through the points, one straight piece between each two.
static func _string(p: InteriorParts, points: Array, colour: Color, thick := 0.008) -> void:
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var along := b - a
		p.box(Vector3(thick, thick, along.length() + thick), colour, (a + b) * 0.5, Basis.looking_at(along.normalized(), Vector3.UP))


# ---------------------------------------------------------------- Tok Tok Thai

static func _thai(p: InteriorParts) -> void:
	var red := Color(0.72, 0.12, 0.12)
	var gold := Color(0.95, 0.75, 0.2)
	InteriorVenues.counter_line(p, -4.0, 4.0, red, Color(0.25, 0.16, 0.1), 2.8, Vector3(-0.6, 0, -3.65), 180.0)
	# The open kitchen: woks over flames, a hood above, the cook tossing noodles.
	InteriorMachinesB.wok_range(p, Vector3(-0.6, 0, -4.5), 2.4, 3)
	p.prop("kaykit_restaurant/extractorhood", Vector3(-0.6, p.size.y, -4.4), 0.0, "hang", Vector3(2.4, 0.9, 0.9))
	InteriorVenues.back_counters(p, -5.6, -2.0)
	InteriorVenues.back_counters(p, 0.8, 4.6, 1)
	InteriorVenues.kitchen_fridge(p, 5.3)
	for k in 4:
		p.prop("kenney_food/bowl-soup", Vector3(-5.2 + k * 0.4, 0.92 - GameConfig.KIT_COUNTER_HEIGHT, -4.5), 0.0, "counter")
	p.food_on("kenney_food/chinese", Vector3(-3.0, 0, -2.45), GameConfig.INTERIOR_COUNTER_HEIGHT)
	p.food_on("kenney_food/chinese", Vector3(-2.75, 0, -2.45), GameConfig.INTERIOR_COUNTER_HEIGHT)
	p.menu_board(Vector3(2.8, 3.2, -4.84), 3.6, InteriorMenus.MENUS["thai"], 1.2, Color(0.12, 0.05, 0.05))
	# The tuk-tuk photo spot on the left, side-on so you see it from the door and the Plaza.
	var bench := InteriorMachinesB.tuk_tuk(p, Vector3(-4.0, 0, 1.75), 90.0)
	for dz in [-0.3, 0.3]:
		p.seat(bench + Vector3(0, 0, dz), 90.0, 0.67)
	# Seats: window stools, a wall bench, 4-seat tables.
	var chair := "kaykit_restaurant/chair_B"
	InteriorDining.window_bar(p, -5.75, -2.7, WOOD.lightened(0.2), "kenney_furniture/stoolBar", "kenney_food/soda-glass")
	InteriorDining.window_bar(p, 2.7, 5.75, WOOD.lightened(0.2), "kenney_furniture/stoolBar", "kenney_food/soda-glass")
	InteriorDining.wall_bench(p, 1.0, 3.3, -0.85, 3, red, chair, "kenney_food/bowl-soup")
	for z in [2.3, 0.05]:
		InteriorDining.four_table(p, Vector3(2.6, 0, z), false, chair, "kenney_food/skewer")
	InteriorDining.four_table(p, Vector3(-1.95, 0, 0.0), true, chair, "kenney_food/bowl-soup")
	# Red lanterns, bunting and fairy lights.
	for k in 8:
		var at := Vector3(-4.5 + (k % 4) * 3.0, 3.6, 2.8 - (k / 4) * 3.2)
		p.box(Vector3(0.01, p.size.y - at.y - 0.25, 0.01), Color(0.1, 0.1, 0.1), at + Vector3(0, (p.size.y - at.y) * 0.5 + 0.12, 0))
		p.kit.ball(0.25, red, at, 1.15)
		p.cyl(0.12, 0.12, 0.05, gold, at + Vector3(0, 0.29, 0), Basis(), 8)
		p.cyl(0.12, 0.12, 0.05, gold, at - Vector3(0, 0.29, 0), Basis(), 8)
	_bunting(p, [3.6, 0.6], 4.3, [red, gold, Color(0.2, 0.4, 0.8), Color(0.95, 0.95, 0.9)])
	for z in [2.1, -0.9]:
		var wire: Array = [Vector3(-5.87, 4.15, z)]
		for k in 24:
			var x := -5.6 + k * 0.487
			var bulb := Vector3(x, 4.15 - 0.2 * (1.0 - pow(x / 5.85, 2.0)), z)
			wire.append(bulb + Vector3(0, 0.03, 0))
			p.glow(Vector3(0.05, 0.05, 0.05), Color(1.0, 0.85, 0.45), bulb, 3.0)
		wire.append(Vector3(5.87, 4.15, z))
		_string(p, wire, Color(0.15, 0.15, 0.12), 0.006)
	for side in [-1.0, 1.0]:
		p.box(Vector3(0.02, 0.3, 9.7), gold, Vector3(side * 5.865, 2.6, 0))
	p.drinks_fridge(Vector3(5.35, 0, -1.6))
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(-5.45, 0, -1.6))
	p.plant(Vector3(-2.4, 0, 3.75))
	# Review fix: the middle lamp's shade hung inside a red lantern (0.45 m apart); moved over
	# the left end of its table.
	var middle := Vector3(-2.5, 0, 0.0) if GameConfig.INTERIOR_REVIEW_FIXES else Vector3(-1.95, 0, -0.35)
	for i in 3:
		p.lamp([Vector3(2.6, 0, 1.2), middle, Vector3(4.9, 0, 1.2)][i], red, i == 0)


# ---------------------------------------------------------------- Sushi You

static func _sushi(p: InteriorParts) -> void:
	var navy := Color(0.12, 0.2, 0.38)
	var wood := Color(0.78, 0.62, 0.42)
	# The ring-shaped sushi bar with the belt, the chefs in the middle, stools all round.
	var stools: Array = InteriorMachinesB.sushi_bar(p, Vector3(-1.6, 0, 0.75), Vector2(6.6, 2.9), 26)
	var spots: Array = []
	var turns: Array = []
	for stool: Array in stools:
		spots.append(stool[0])
		turns.append(stool[1])
		p.seat(stool[0], stool[1], 0.72, "kenney_food/maki-salmon")
	p.props("kenney_furniture/stoolBar", spots, turns)
	for k in 2:
		var chef := p.worker("Chef%d" % (k + 1), Vector3(-3.3 + k * 2.6, 0, 0.75), 180.0 if k == 0 else 0.0, k)
		chef.add_to_group("sushi_chef")
		var knife := Node3D.new()
		knife.position = Vector3(-3.3 + k * 2.6, 1.05, 0.75 + (-0.35 if k == 0 else 0.35))
		knife.set_meta("rest_y", 1.05)
		LowPoly.box(knife, Vector3(0.02, 0.03, 0.22), Color(0.8, 0.82, 0.85), Vector3.ZERO)
		p.inside.add_child(knife)
		p.motion.knives.append(knife)
	# The pick-up counter on the right, with the till; the kitchen behind a navy curtain.
	p.counter(Rect2(2.4, -2.8, 3.2, 0.6), navy, wood)
	p.till(Vector3(4.8, GameConfig.INTERIOR_COUNTER_HEIGHT, -2.5))
	InteriorVenues.pickup_sign(p, Vector3(3.6, 2.55, -2.5))
	p.worker("CounterStaff", Vector3(3.6, 0, InteriorVenues.STAFF_Z), 0.0, 2, true)
	p.worker("Cashier", Vector3(4.8, 0, InteriorVenues.STAFF_Z), 0.0, 4)
	for k in 3:
		p.box(Vector3(0.24, 0.08, 0.18), Color(0.95, 0.95, 0.92), Vector3(2.9 + k * 0.3, 1.09, -2.45))
		p.box(Vector3(0.25, 0.02, 0.19), Color(0.15, 0.15, 0.15), Vector3(2.9 + k * 0.3, 1.14, -2.45))
	var back := -p.size.z * 0.5 + 0.125
	p.box(Vector3(1.6, 2.3, 0.03), Color(0.08, 0.08, 0.09), Vector3(-1.0, 1.15, back + 0.015))   # the kitchen door
	p.box(Vector3(1.75, 0.03, 0.03), Color(0.3, 0.22, 0.15), Vector3(-1.0, 2.32, back + 0.06))      # the curtain rod
	p.box(Vector3(0.03, 0.03, 0.04), Color(0.3, 0.22, 0.15), Vector3(-1.86, 2.32, back + 0.025))
	p.box(Vector3(0.03, 0.03, 0.04), Color(0.3, 0.22, 0.15), Vector3(-0.14, 2.32, back + 0.025))
	for k in 4:
		p.box(Vector3(0.38, 1.1, 0.02), navy, Vector3(-1.57 + k * 0.38, 1.755, back + 0.06))
	p.sign("مطبخ", "Kitchen", Vector3(-1.0, 2.0, back + 0.08), 0.0, Color.WHITE, Color(0, 0, 0, 0), 24)
	InteriorVenues.back_counters(p, 0.6, 5.6)
	InteriorVenues.back_counters(p, -5.6, -2.2, 0)
	p.menu_board(Vector3(-3.9, 3.2, -4.84), 3.4, InteriorMenus.MENUS["sushi"], 1.2, navy.darkened(0.4))
	p.menu_board(Vector3(1.6, 3.2, -4.84), 2.8, InteriorMenus.MENUS["sushi"], 1.2, navy.darkened(0.4))   # clear of the Pick up sign
	# A booth by the right wall, paper lanterns, bamboo.
	_booth(p, Vector3(4.65, 0, 1.1), navy)
	InteriorDining.window_bar(p, -5.75, -2.7, wood, "kenney_furniture/stoolBar", "kenney_food/cup-tea")
	InteriorDining.window_bar(p, 2.7, 5.75, wood, "kenney_furniture/stoolBar", "kenney_food/cup-tea")
	for k in 6:
		var at := Vector3(-4.6 + (k % 3) * 2.7, 3.55, 0.75 + (1.5 if k < 3 else -1.5))
		p.box(Vector3(0.01, p.size.y - at.y - 0.3, 0.01), Color(0.1, 0.1, 0.1), at + Vector3(0, (p.size.y - at.y) * 0.5 + 0.15, 0))
		p.glow(Vector3(0.36, 0.5, 0.36), Color(1.0, 0.95, 0.85), at, 0.6)
		p.cyl(0.2, 0.2, 0.04, Color(0.1, 0.1, 0.1), at + Vector3(0, 0.27, 0), Basis(), 8)
	for spot in [Vector3(-5.6, 0, -1.7), Vector3(-5.6, 0, 3.6), Vector3(5.6, 0, -1.6)]:
		for k in 4:
			var stalk: Vector3 = spot + Vector3((k % 2) * 0.12 - 0.06, 0, (k / 2) * 0.12 - 0.06)
			p.cyl(0.035, 0.035, 2.6 + k * 0.3, Color(0.45, 0.65, 0.3), stalk + Vector3(0, (2.6 + k * 0.3) * 0.5, 0), Basis(), 6)
		p.cyl(0.2, 0.17, 0.35, Color(0.2, 0.2, 0.2), spot + Vector3(0, 0.175, 0), Basis(), 10)
	p.bin(Vector3(1.75, 0, 4.35))
	for i in 3:
		p.lamp([Vector3(4.65, 0, 1.1), Vector3(4.0, 0, -1.4), Vector3(-4.6, 0, 3.0)][i], navy, i == 0)


## A booth: two padded benches facing each other across a table, against the right wall.
static func _booth(p: InteriorParts, at: Vector3, colour: Color) -> void:
	for side in [-1.0, 1.0]:
		var bench := at + Vector3(0, 0, side * 0.85)
		p.solid(Vector3(1.6, 0.45, 0.5), colour, bench + Vector3(0, 0.225, 0))
		p.box(Vector3(1.6, 0.7, 0.12), colour.lightened(0.15), bench + Vector3(0, 0.8, side * 0.25))
		p.counter_tops.append([Rect2(bench.x - 0.8, bench.z - 0.25, 1.6, 0.5), 0.45])
		for dx in [-0.4, 0.4]:
			p.seat(bench + Vector3(dx, 0, 0), 180.0 if side > 0 else 0.0, 0.45, "kenney_food/sushi-salmon")
	p.box(Vector3(1.4, 0.05, 0.75), Color(0.25, 0.18, 0.12), at + Vector3(0, 0.725, 0))
	p.box(Vector3(0.12, 0.7, 0.12), Color(0.15, 0.15, 0.15), at + Vector3(0, 0.35, 0))
	LowPoly.solid_box(p.body, Vector3(1.3, 0.75, 0.7), at + Vector3(0, 0.375, 0))
	p.counter_tops.append([Rect2(at.x - 0.7, at.z - 0.375, 1.4, 0.75), 0.75])
	for dx in [-0.35, 0.35]:
		for dz in [-0.2, 0.2]:
			p.food_on("kenney_food/sushi-salmon", at + Vector3(dx, 0, dz), 0.75)


# ---------------------------------------------------------------- Mario Bonito

static func _tacos(p: InteriorParts) -> void:
	var teal := Color(0.1, 0.55, 0.55)
	var orange := Color(1.0, 0.44, 0.35)
	var colours := [Color(0.95, 0.3, 0.45), Color(0.98, 0.75, 0.15), teal, Color(0.55, 0.3, 0.75), Color(0.3, 0.7, 0.3), orange]
	InteriorVenues.counter_line(p, -4.0, 4.0, Color(0.98, 0.95, 0.88), Color(0.85, 0.5, 0.25), 2.8, Vector3(-1.2, 0, -3.65), 180.0)
	for k in 40:   # the colourful tile band on the counter front
		for row in 2:
			p.box(Vector3(0.19, 0.19, 0.02), colours[(k + row * 3) % colours.size()], Vector3(-3.9 + k * 0.2, 0.55 + row * 0.2, -2.19))
	# Salsa tubs in a cold well on the counter, the flat grill with tortillas behind.
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	p.box(Vector3(1.6, 0.03, 0.4), Color(0.75, 0.77, 0.8), Vector3(-0.6, top + 0.015, -2.5))
	for k in 6:
		p.box(Vector3(0.22, 0.08, 0.3), Color(0.8, 0.82, 0.85), Vector3(-1.3 + k * 0.27, top + 0.06, -2.5))
		p.box(Vector3(0.2, 0.02, 0.28), [Color(0.85, 0.15, 0.1), Color(0.3, 0.6, 0.25), Color(0.98, 0.95, 0.85), Color(0.95, 0.6, 0.1), Color(0.5, 0.75, 0.3), Color(0.6, 0.15, 0.1)][k], Vector3(-1.3 + k * 0.27, top + 0.1, -2.5))
	p.glass(Vector3(1.6, 0.25, 0.02), Vector3(-0.6, top + 0.2, -2.25), Basis(Vector3.RIGHT, -0.3))
	InteriorMachinesB.flat_grill(p, Vector3(-1.2, 0, -4.5), 0.0, "tortilla")
	InteriorVenues.back_counters(p, -5.6, -2.0)
	InteriorVenues.back_counters(p, -0.4, 4.6, 2)
	InteriorVenues.kitchen_fridge(p, 5.3)
	p.food_on("kenney_food/taco", Vector3(-3.0, 0, -2.45), top)
	p.food_on("kenney_food/taco", Vector3(-3.2, 0, -2.45), top)
	p.menu_board(Vector3(2.4, 3.2, -4.84), 4.0, InteriorMenus.MENUS["tacos"], 1.2, Color(0.15, 0.1, 0.08))
	# Paper bunting, cactus pots, colourful walls.
	_bunting(p, [3.4, 1.2, -0.9], 4.35, colours, true)
	for side in [-1.0, 1.0]:
		for k in 48:
			p.box(Vector3(0.02, 0.2, 0.2), colours[k % colours.size()], Vector3(side * 5.865, 1.25, -4.7 + k * 0.2))
	var chair := "kenney_furniture/chair"
	InteriorDining.standard(p, -1.0, Color(0.85, 0.5, 0.25), teal, chair, "kenney_food/taco", "kenney_food/soda-bottle")
	for spot in [Vector3(-5.45, 0, -1.6), Vector3(-2.35, 0, 3.75)]:
		p.prop("kaykit_furniture/cactus_medium_A", spot, 0.0, "floor")
	for x in [-2.9, 2.9]:
		p.prop("kaykit_furniture/cactus_medium_A", Vector3(x, 0, 4.66), 0.0, "counter", Vector3(0.35, 0.33, 0.33))
	p.drinks_fridge(Vector3(5.35, 0, -1.6), 0.0, orange)
	p.bin(Vector3(1.75, 0, 4.35))
	for i in 4:
		p.lamp([Vector3(-2.6, 0, 1.2), Vector3(3.6, 0, 1.2), Vector3(-2.6, 0, -0.6), Vector3(3.6, 0, -0.6)][i], colours[i], i == 0)


# ---------------------------------------------------------------- Burgerology

static func _burger(p: InteriorParts) -> void:
	var pink := Color(0.91, 0.33, 0.6)
	var back := -p.size.z * 0.5 + 0.125
	# White metro tiles on the back wall, on grey grout so the tiles show.
	p.box(Vector3(11.7, 2.45, 0.01), Color(0.62, 0.63, 0.65), Vector3(0, 1.225, back + 0.004))
	for row in 16:
		for k in 39:
			var x := -5.8 + k * 0.3 + (0.15 if row % 2 == 1 else 0.0)
			if x > 5.75:
				continue
			p.box(Vector3(0.28, 0.13, 0.015), Color(0.98, 0.98, 0.98), Vector3(x, 0.1 + row * 0.15, back + 0.01))
	InteriorVenues.counter_line(p, -4.0, 4.0, Color(0.15, 0.15, 0.16), Color(0.85, 0.85, 0.87), 2.8, Vector3(-1.0, 0, -3.65), 180.0)
	# The flat grill with patties, the fryer, the heat lamps over the pass.
	InteriorMachinesB.flat_grill(p, Vector3(-1.0, 0, -4.5), 0.0, "patty")
	InteriorMachinesB.fryer(p, Vector3(0.6, 0, -4.5))
	p.worker("FryCook", Vector3(0.6, 0, -3.7), 180.0, 1)
	p.prop("kaykit_restaurant/extractorhood", Vector3(-0.2, p.size.y, -4.4), 0.0, "hang", Vector3(2.6, 0.9, 0.9))
	InteriorVenues.back_counters(p, -5.6, -2.0)
	InteriorVenues.back_counters(p, 1.2, 4.6, 1)
	InteriorVenues.kitchen_fridge(p, 5.3)
	var top := GameConfig.INTERIOR_COUNTER_HEIGHT
	p.box(Vector3(2.0, 0.04, 0.3), Color(0.3, 0.3, 0.32), Vector3(-2.6, 1.75, -2.5))
	for dx in [-0.9, 0.9]:
		p.box(Vector3(0.04, 0.7, 0.04), Color(0.3, 0.3, 0.32), Vector3(-2.6 + dx, 1.4, -2.5))
	p.glow(Vector3(1.8, 0.03, 0.2), Color(1.0, 0.55, 0.25), Vector3(-2.6, 1.72, -2.5), 2.0)
	for k in 3:
		p.food_on("kenney_food/burger-cheese", Vector3(-3.2 + k * 0.35, 0, -2.5), top)
	p.food_on("kenney_food/fries", Vector3(-2.0, 0, -2.5), top)
	# The pink neon sign and the menu board.
	var neon := SignText.make_label("Burgerology", 90, Color(1.0, 0.45, 0.75), Color(1.0, 0.2, 0.6, 0.6), 6)
	neon.name = "NeonSign"
	neon.position = Vector3(-3.4, 3.8, back + 0.05)   # above the Pick up sign, seen from the door
	p.body.add_child(neon)
	var glow := OmniLight3D.new()
	glow.position = Vector3(-3.4, 3.8, back + 0.6)
	glow.light_color = Color(1.0, 0.4, 0.75)
	glow.light_energy = 0.8
	glow.omni_range = 3.5
	p.inside.add_child(glow)
	p.menu_board(Vector3(2.9, 3.2, -4.84), 3.6, InteriorMenus.MENUS["burger"], 1.2, Color(0.1, 0.1, 0.11))
	# Seats: a stool ledge on the left wall, window stools, booths of 4-seat tables.
	var ledge := Rect2(-5.875, -0.9, 0.35, 3.9)
	p.box(Vector3(ledge.size.x, 0.05, ledge.size.y), Color(0.85, 0.85, 0.87), Vector3(ledge.get_center().x, 1.05, ledge.get_center().y))
	LowPoly.solid_box(p.body, Vector3(ledge.size.x, 1.05, ledge.size.y), Vector3(ledge.get_center().x, 0.525, ledge.get_center().y))
	p.counter_tops.append([ledge, 1.075])
	var stools: Array = []
	for k in 5:
		var z := ledge.position.y + 0.4 + k * 0.78
		stools.append(Vector3(-5.1, 0, z))
		if p.seat(Vector3(-5.1, 0, z), -90.0, 0.75, "kenney_food/burger"):
			p.food_on("kenney_food/burger", Vector3(-5.72, 0, z), 1.075)
	p.props("kenney_furniture/stoolBar", stools, stools.map(func(_s): return 90.0))
	InteriorDining.window_bar(p, -5.75, -2.7, Color(0.85, 0.85, 0.87), "kenney_furniture/stoolBar", "kenney_food/soda-can")
	InteriorDining.window_bar(p, 2.7, 5.75, Color(0.85, 0.85, 0.87), "kenney_furniture/stoolBar", "kenney_food/soda-can")
	var chair := "kaykit_restaurant/chair_A"
	for z in [2.3, 0.05]:
		InteriorDining.four_table(p, Vector3(2.6, 0, z), false, chair, "kenney_food/burger-cheese")
		InteriorDining.four_table(p, Vector3(-2.7, 0, z), false, chair, "kenney_food/fries")
	InteriorDining.two_table(p, Vector3(4.95, 0, 1.2), 90.0, chair, "kenney_food/burger")
	p.drinks_fridge(Vector3(5.35, 0, -1.6), 0.0, pink)
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(-5.45, 0, -1.6))
	for i in 4:
		p.lamp([Vector3(-2.7, 0, 1.2), Vector3(2.6, 0, 1.2), Vector3(-2.7, 0, -0.6), Vector3(2.6, 0, -0.6)][i], pink, i == 0)
