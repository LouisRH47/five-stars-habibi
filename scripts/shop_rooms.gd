class_name ShopRooms
extends RefCounted
## Session 59: the insides of Pedal Point Bikes and Dune Drip, rebuilt for their 12 x 10 m
## rooms in the Plaza rows (Session 57 only squeezed the old ones in). ShopInterior still
## builds the walls, the counter at ShopInterior.COUNTER and the staff; this adds the rest.
## The spot where your bike (or you) stands in the shop screen, ShopInterior.PREVIEW, and
## the view to it from the shop camera (1, 1.9, 3.2) are kept clear.
## - Pedal Point Bikes, like a real bike shop: bikes for sale along the wall in the paint
##   colours with price tags and more hanging on hooks above, a workbench with the tool
##   pegboard and the mechanic, a repair stand with a bike, a tyre rack, helmets and bits on
##   shelves, boxes of parts behind the till, a bike in the window and the round stand your
##   bike turns on when you shop (with a bike on it the rest of the time).
## - Dune Drip, like a real streetwear shop: a caps wall behind the till, a sunglasses wall,
##   a trainers wall, clothes rails, folded hoodies on a table, shelves of tops and backpacks,
##   two dressed mannequins in the window, a rug and a big mirror, a changing room.
## Room directions: x from -6 (left, seen from the door) to +6; z from +5 (glass) to -5.

const STEEL := Color(0.72, 0.74, 0.77)
const DARK := Color(0.15, 0.16, 0.17)
const WOOD := Color(0.62, 0.45, 0.28)
const WHITE := Color(0.96, 0.96, 0.94)


## Floor tiles over the room's floor, the lamps and the sound. p: the room's parts.
static func _room(p: InteriorParts, a: Color, b: Color, planks: bool, lamp: Color, cool: bool) -> void:
	var half := p.size * 0.5
	var tile := 0.25 if planks else 0.6
	for i in roundi(p.size.x / tile):
		for k in roundi(p.size.z / tile):
			var colour := a.lerp(b, float((i * 7 + (k / 4) * 3) % 5) / 4.0) if planks else (a if (i + k) % 2 == 0 else b)
			p.box(Vector3(tile * (1.0 if planks else 0.98), 0.02, tile * 0.98), colour, Vector3(-half.x + (i + 0.5) * tile, 0.0, -half.z + (k + 0.5) * tile))
	# A ceiling panel just under the room's ceiling (the flats' floor above sits at the same
	# height, and the two flickered against each other).
	p.box(Vector3(p.size.x - 0.3, 0.01, p.size.z - 0.1), Color(0.93, 0.91, 0.86), Vector3(0, p.size.y - 0.006, 0))
	var c := ShopInterior.COUNTER
	p.counter_tops.append([Rect2(c.x - 2.0, c.z - 0.7, 4.0, 1.2), 1.05])
	for i in 4:
		p.lamp([Vector3(-3.0, 0, 1.5), Vector3(3.0, 0, 1.5), Vector3(-3.0, 0, -2.0), Vector3(1.0, 0, -0.5)][i], lamp, i == 3, cool)
	var fill := OmniLight3D.new()
	fill.name = "InteriorLight"
	fill.position = Vector3(0, p.size.y - 0.5, 0.5)
	fill.light_color = Color(1.0, 0.95, 0.88)
	fill.light_energy = 0.8
	fill.omni_range = 10.0
	p.body.add_child(fill)
	var file := "res://assets/audio/%s.wav" % InteriorMenus.SOUNDS.get(p.id, "")
	if ResourceLoader.exists(file):
		var player := AudioStreamPlayer3D.new()
		player.name = "RoomSound"
		var stream := load(file) as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		player.stream = stream
		player.bus = "Ambience"
		player.volume_db = GameConfig.INTERIOR_SOUND_DB
		player.unit_size = 3.0
		player.max_distance = GameConfig.INTERIOR_SOUND_RANGE
		player.position = Vector3(0, 2.0, -2.0)
		player.autoplay = true
		p.body.add_child(player)
		p.motion.sound = player


## A price tag: a little white card with the price on it, facing `facing` degrees
## (0 = towards +z, the door). It's in the group "price_tag" (the test counts them).
static func _tag(p: InteriorParts, text: String, at: Vector3, facing: float) -> void:
	var turn := Basis(Vector3.UP, deg_to_rad(facing))
	var width := SignText.text_width(text, 12) + 0.06
	p.box(Vector3(width, 0.1, 0.01), WHITE, at, turn)
	var label := SignText.make_label(text, 12, Color(0.1, 0.1, 0.1), Color(0, 0, 0, 0), 0)
	label.name = "PriceTag"
	label.add_to_group("price_tag")
	label.position = at + turn * Vector3(0, 0, 0.007)
	label.rotation.y = deg_to_rad(facing)
	p.body.add_child(label)


## Open shelves on a wall: boards from x0 to x1 (or along z on a side wall), `depth` deep,
## at the heights in `levels`. side: "back", "left" or "right". The boards' tops go in
## counter_tops so things put on them are checked like things on a counter.
static func _shelves(p: InteriorParts, side: String, from: float, to: float, depth: float, levels: Array, colour: Color) -> void:
	var half := p.size * 0.5
	for y: float in levels:
		var rect: Rect2
		if side == "back":
			rect = Rect2(from, -half.z + 0.125, to - from, depth)
		elif side == "left":
			rect = Rect2(-half.x + 0.125, from, depth, to - from)
		else:
			rect = Rect2(half.x - 0.125 - depth, from, depth, to - from)
		var mid := rect.get_center()
		p.box(Vector3(rect.size.x, 0.04, rect.size.y), colour, Vector3(mid.x, y - 0.02, mid.y))
		p.counter_tops.append([rect, y])
	var top: float = levels.max() + 0.02
	for end in [from + 0.03, to - 0.03]:   # the two upright sides
		var spot: Vector3
		if side == "back":
			spot = Vector3(end, top * 0.5, -half.z + 0.125 + depth * 0.5)
			p.box(Vector3(0.04, top, depth), colour.darkened(0.2), spot)
		else:
			var x := (-half.x + 0.125 + depth * 0.5) if side == "left" else (half.x - 0.125 - depth * 0.5)
			p.box(Vector3(depth, top, 0.04), colour.darkened(0.2), Vector3(x, top * 0.5, end))


# ---------------------------------------------------------------- Pedal Point Bikes

static func bikes(p: InteriorParts) -> void:
	var half := p.size * 0.5
	var teal := p.brand
	_room(p, Color(0.62, 0.59, 0.55), Color(0.55, 0.52, 0.48), false, teal, false)
	var back := -half.z + 0.125
	# The workbench along the back wall, the tool pegboard above it, the mechanic.
	p.solid(Vector3(4.6, 0.92, 0.7), WOOD.darkened(0.2), Vector3(-3.0, 0.46, back + 0.35))
	p.box(Vector3(4.64, 0.06, 0.74), WOOD, Vector3(-3.0, 0.95, back + 0.35))
	p.counter_tops.append([Rect2(-5.3, back, 4.6, 0.72), 0.98])
	p.box(Vector3(0.2, 0.14, 0.18), Color(0.25, 0.45, 0.6), Vector3(-4.8, 1.05, back + 0.5))   # the vice
	p.box(Vector3(0.06, 0.06, 0.24), DARK, Vector3(-4.8, 1.05, back + 0.66))
	p.box(Vector3(4.6, 1.6, 0.05), Color(0.82, 0.74, 0.58), Vector3(-3.0, 2.2, back + 0.03))
	for k in 18:   # tools on the pegboard
		var x := -5.1 + (k % 9) * 0.52
		var y := 1.75 + (k / 9) * 0.75
		match k % 3:
			0:
				p.box(Vector3(0.04, 0.42, 0.02), DARK, Vector3(x, y + 0.1, back + 0.065))   # spanner
				p.box(Vector3(0.1, 0.06, 0.02), DARK, Vector3(x, y + 0.33, back + 0.065))
			1:
				p.box(Vector3(0.05, 0.32, 0.03), Color(0.75, 0.2, 0.15), Vector3(x, y + 0.05, back + 0.07))   # screwdriver
				p.box(Vector3(0.015, 0.2, 0.015), STEEL, Vector3(x, y + 0.3, back + 0.065))
			2:
				p.box(Vector3(0.24, 0.05, 0.03), Color(0.95, 0.75, 0.15), Vector3(x, y + 0.2, back + 0.07))   # tyre levers
				p.box(Vector3(0.22, 0.05, 0.03), Color(0.2, 0.45, 0.8), Vector3(x, y + 0.08, back + 0.07))
	p.sign("ورشة", "Workshop", Vector3(-3.0, 3.25, back + 0.045), 0.0, Color.WHITE, teal.darkened(0.2), 26)
	p.worker("Mechanic2", Vector3(-3.6, 0, -3.95), 180.0, 1)
	# The repair stand with a bike up on it.
	var stand := Vector3(-4.2, 0, -2.75)
	p.box(Vector3(0.7, 0.04, 0.06), DARK, stand + Vector3(0, 0.02, 0))
	p.box(Vector3(0.06, 0.04, 0.7), DARK, stand + Vector3(0, 0.02, 0))
	p.box(Vector3(0.06, 1.25, 0.06), Color(0.85, 0.2, 0.2), stand + Vector3(0, 0.66, 0))
	p.box(Vector3(0.06, 0.06, 0.35), DARK, stand + Vector3(0, 1.28, 0.15))
	_bike(p, stand + Vector3(0, 0.55, 0.3), 90.0, BikeModel.FRAME)
	LowPoly.solid_box(p.body, Vector3(1.8, 1.6, 0.6), stand + Vector3(0, 0.8, 0.3))
	# Bikes for sale standing along the left wall, one in each paint colour with its price
	# tag, and more hanging on hooks above them.
	var paints: Array = GearCatalog.items("bikes").filter(func(item): return item["category"] == "paint")
	for i in 3:
		var z := 3.45 - i * 1.95
		var item: Dictionary = paints[i % paints.size()]
		_bike(p, Vector3(-half.x + 0.5, 0, z), 0.0, item["colour"])
		# Its price card on a little stand in front of it.
		var card := Vector3(-half.x + 1.05, 0, z + 0.55)
		p.box(Vector3(0.2, 0.02, 0.2), DARK, card + Vector3(0, 0.01, 0))
		p.box(Vector3(0.025, 0.9, 0.025), DARK, card + Vector3(0, 0.47, 0))
		_tag(p, "%s · %d Dh" % [item["name"], GearCatalog.price(item)], card + Vector3(0.0, 0.95, 0.018), 0.0)
	LowPoly.solid_box(p.body, Vector3(0.65, 1.1, 5.7), Vector3(-half.x + 0.5, 0.55, 1.5))
	for i in 3:
		var z := 2.5 - i * 1.95
		for dz in [-0.55, 0.55]:   # a hook over each wheel
			p.box(Vector3(0.4, 0.04, 0.04), DARK, Vector3(-half.x + 0.32, 3.5, z + dz))
			p.box(Vector3(0.03, 0.46, 0.03), DARK, Vector3(-half.x + 0.5, 3.29, z + dz))
		_bike(p, Vector3(-half.x + 0.5, 2.4, z), 0.0, [Color(0.15, 0.15, 0.16), Color(0.85, 0.85, 0.85), Color(0.2, 0.35, 0.7)][i])
	# The tyre rack on the right wall.
	var rack_x := half.x - 0.35
	p.box(Vector3(0.08, 2.0, 0.08), DARK, Vector3(rack_x, 1.0, 0.8))
	p.box(Vector3(0.08, 2.0, 0.08), DARK, Vector3(rack_x, 1.0, 3.6))
	for y in [0.75, 1.65]:
		p.box(Vector3(0.06, 0.06, 2.8), DARK, Vector3(rack_x, y, 2.2))
		for k in 5:
			var at := Vector3(rack_x - 0.05, y - 0.3, 1.1 + k * 0.55)
			p.cyl(0.33, 0.33, 0.05, Color(0.1, 0.1, 0.1), at, Basis(Vector3.FORWARD, PI * 0.5), 14)
			p.cyl(0.22, 0.22, 0.06, Color(0.55, 0.57, 0.6), at, Basis(Vector3.FORWARD, PI * 0.5), 12)
	p.box(Vector3(0.06, 0.06, 2.88), DARK, Vector3(rack_x, 1.97, 2.2))
	LowPoly.solid_box(p.body, Vector3(0.5, 2.0, 2.9), Vector3(rack_x, 1.0, 2.2))
	_tag(p, "Comfy tyres · %d Dh" % int(GameConfig.GEAR_PRICES["tyres"]), Vector3(rack_x - 0.035, 2.05, 2.2), -90.0)
	# Helmets, lights and bottles on shelves on the right wall.
	_shelves(p, "right", -1.7, 0.4, 0.4, [1.1, 1.6, 2.1], WOOD)
	for k in 4:
		p.kit.ball(0.15, [teal, Color(0.95, 0.4, 0.2), Color(0.95, 0.95, 0.9), DARK][k], Vector3(half.x - 0.33, 1.6 + 0.11, -1.45 + k * 0.5), 0.75)
		p.box(Vector3(0.02, 0.03, 0.2), DARK, Vector3(half.x - 0.33, 1.63, -1.45 + k * 0.5))
	for k in 8:
		var colour: Color = [teal, Color(0.95, 0.75, 0.2), Color(0.9, 0.3, 0.3), WHITE][k % 4]
		p.cyl(0.035, 0.035, 0.22, colour, Vector3(half.x - 0.33, 1.1 + 0.11, -1.55 + k * 0.25), Basis(), 8)   # bottles
		p.box(Vector3(0.08, 0.06, 0.12), [DARK, Color(0.9, 0.2, 0.2)][k % 2], Vector3(half.x - 0.33, 2.1 + 0.03, -1.55 + k * 0.25))   # lights
	_tag(p, "Helmets · %d Dh" % int(GameConfig.COSMETIC_PRICES["helmets"]), Vector3(half.x - 0.53, 1.53, -0.65), -90.0)
	# Boxes of parts on shelves behind the till.
	_shelves(p, "back", 0.7, 5.6, 0.45, [0.45, 1.15, 1.85], WOOD.darkened(0.1))
	for y in [0.45, 1.15, 1.85]:
		for k in 6:
			var x := 1.05 + k * 0.78
			if (k + int(y * 10)) % 4 == 0:
				continue
			p.prop("kenney_furniture/cardboardBoxClosed", Vector3(x, y, back + 0.24), (k * 17) % 30 - 15.0, "floor", Vector3(0.45, 0.3, 0.35))
	for k in 5:   # inner tubes hanging on hooks above the shelves
		p.cyl(0.2, 0.2, 0.04, DARK, Vector3(1.4 + k * 0.95, 2.6, back + 0.02), Basis(Vector3.RIGHT, PI * 0.5), 12)
		p.cyl(0.16, 0.16, 0.042, ShopInterior.CREAM, Vector3(1.4 + k * 0.95, 2.6, back + 0.02), Basis(Vector3.RIGHT, PI * 0.5), 12)   # the hole
	p.sign(str(p.place.get("arabic", "")), str(p.place.get("name", "Pedal Point Bikes")), Vector3(3.1, 3.45, back + 0.045), 0.0, Color.WHITE, teal.darkened(0.2), 30)
	# A bike on show in the window, on a low stand, for people walking past.
	p.box(Vector3(2.0, 0.15, 0.7), DARK, Vector3(3.6, 0.075, 4.15))
	p.counter_tops.append([Rect2(2.6, 3.8, 2.0, 0.7), 0.15])
	_bike(p, Vector3(3.6, 0.15, 4.15), 90.0, Color(0.9, 0.27, 0.16))
	LowPoly.solid_box(p.body, Vector3(2.0, 1.1, 0.7), Vector3(3.6, 0.55, 4.15))
	# The round stand your bike turns on in the shop screen (a bike stands on it until then).
	var spot := ShopInterior.PREVIEW
	p.cyl(0.95, 0.95, 0.56, Color(0.3, 0.32, 0.33), spot + Vector3(0, 0.28, 0), Basis(), 24)
	p.cyl(0.97, 0.97, 0.04, teal, spot + Vector3(0, 0.58, 0), Basis(), 24)
	LowPoly.solid_cylinder(p.body, 0.95, 0.6, spot + Vector3(0, 0.3, 0))
	p.counter_tops.append([Rect2(spot.x - 0.95, spot.z - 0.95, 1.9, 1.9), 0.6])
	var display := _bike(p, spot + Vector3(0, 0.6, 0), 90.0, BikeModel.FRAME)
	display.name = "StandBike"
	display.add_to_group("shop_stand_bike")
	# On the counter: the till, a pump, bottles of chain oil.
	var c := ShopInterior.COUNTER
	p.till(Vector3(c.x + 1.2, 1.05, c.z - 0.3))
	p.box(Vector3(0.12, 0.05, 0.2), DARK, Vector3(c.x - 1.4, 1.075, c.z - 0.2))
	p.box(Vector3(0.04, 0.6, 0.04), Color(0.85, 0.2, 0.2), Vector3(c.x - 1.4, 1.38, c.z - 0.2))
	for k in 4:
		p.cyl(0.03, 0.03, 0.16, [Color(0.2, 0.6, 0.3), Color(0.95, 0.75, 0.2)][k % 2], Vector3(c.x - 0.6 + k * 0.09, 1.13, c.z - 0.5), Basis(), 8)
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(half.x - 0.5, 0, -2.4))
	p.plant(Vector3(-2.0, 0, 4.4), false)
	p.body.set_meta("interior_style", "bike_workshop")


## A bike model (the same one you ride) with no rider and no delivery box, at `at`, turned
## `facing` degrees, its frame painted `paint`.
static func _bike(p: InteriorParts, at: Vector3, facing: float, paint: Color) -> Node3D:
	var bike := Node3D.new()
	bike.name = "ShopBike"
	bike.add_to_group("shop_bike")
	BikeModel.build(bike)
	for part_name in ["Rider", "DeliveryBox"]:
		var part := bike.get_node_or_null(part_name)
		if part != null:
			part.free()
	for mesh: MeshInstance3D in bike.find_children("*", "MeshInstance3D", true, false):
		if mesh.get_meta("bike_paint", false):
			mesh.material_override = LowPoly.material(paint)
	bike.position = at
	bike.rotation.y = deg_to_rad(facing)
	p.body.add_child(bike)
	return bike


# ---------------------------------------------------------------- Dune Drip

static func clothes(p: InteriorParts) -> void:
	var half := p.size * 0.5
	var orange := p.brand
	_room(p, Color(0.78, 0.62, 0.45), Color(0.7, 0.55, 0.38), true, orange, false)
	var back := -half.z + 0.125
	# The big mirror on the left wall (you see yourself in it in the shop screen).
	p.box(Vector3(0.12, 2.9, 2.6), WOOD, Vector3(-half.x + 0.18, 1.6, 0.0))
	p.glow(Vector3(0.02, 2.7, 2.4), Color(0.75, 0.85, 0.88), Vector3(-half.x + 0.25, 1.6, 0.0), 0.15)
	# The rug where you stand when you try things on.
	var spot := ShopInterior.PREVIEW
	p.box(Vector3(3.2, 0.015, 2.4), Color(0.65, 0.25, 0.23), spot + Vector3(-0.3, 0.012, 0))
	p.box(Vector3(2.8, 0.016, 2.0), Color(0.9, 0.75, 0.45), spot + Vector3(-0.3, 0.013, 0))
	# The caps wall behind the till: rows of caps on pegs in every colour.
	var cap_price := int(GameConfig.COSMETIC_PRICES["caps"])
	p.box(Vector3(5.0, 1.8, 0.05), Color(0.25, 0.25, 0.27), Vector3(3.0, 2.3, back + 0.03))
	for row in 3:
		for k in 8:
			var at := Vector3(0.9 + k * 0.6, 1.75 + row * 0.55, back + 0.18)
			var colour: Color = GearCatalog.COLOURS[(k + row) % 3]["colour"]
			p.box(Vector3(0.02, 0.02, 0.12), STEEL, at + Vector3(0, -0.02, -0.08))
			p.kit.ball(0.14, colour, at, 0.7)
			p.box(Vector3(0.22, 0.02, 0.14), colour.darkened(0.2), at + Vector3(0, -0.05, 0.14))
	p.sign("قبعات", "Caps", Vector3(3.0, 3.45, back + 0.045), 0.0, Color.WHITE, orange.darkened(0.2), 26)
	_tag(p, "Caps · %d Dh" % cap_price, Vector3(1.4, 3.12, back + 0.06), 0.0)
	# On the counter: the till and the sunglasses stand.
	var c := ShopInterior.COUNTER
	p.till(Vector3(c.x + 1.2, 1.05, c.z - 0.3))
	for step in 3:   # three steps, each standing on the counter top
		var tall := 0.06 + step * 0.1
		p.box(Vector3(1.0, tall, 0.15), WHITE, Vector3(c.x - 1.1, 1.05 + tall * 0.5, c.z + 0.35 - step * 0.15))
		for k in 4:
			p.box(Vector3(0.17, 0.05, 0.02), [DARK, Color(0.3, 0.2, 0.1), Color(0.6, 0.15, 0.15), Color(0.15, 0.3, 0.6)][(k + step) % 4],
					Vector3(c.x - 1.45 + k * 0.23, 1.05 + tall + 0.025, c.z + 0.38 - step * 0.15))
	# The sunglasses wall on the right, by the counter.
	p.box(Vector3(0.05, 1.6, 2.0), Color(0.95, 0.93, 0.9), Vector3(half.x - 0.15, 1.8, -0.75))
	for row in 5:
		for k in 6:
			var colour: Color = [DARK, Color(0.3, 0.2, 0.1), Color(0.6, 0.15, 0.15), Color(0.15, 0.3, 0.6), Color(0.85, 0.65, 0.2)][(k + row) % 5]
			var at := Vector3(half.x - 0.185, 1.2 + row * 0.28, -1.45 + k * 0.28)
			p.box(Vector3(0.02, 0.06, 0.2), colour, at)
			p.box(Vector3(0.03, 0.01, 0.2), DARK, at + Vector3(0, 0.035, 0))
	_tag(p, "Glasses · %d Dh" % int(GameConfig.COSMETIC_PRICES["glasses"]), Vector3(half.x - 0.18, 2.54, -0.75), -90.0)
	# The trainers wall on the right: shoes on little shelves, one of each colour.
	var shoe_levels := [0.35, 0.8, 1.25, 1.7]
	_shelves(p, "right", 0.6, 3.8, 0.35, shoe_levels, WHITE)
	for y: float in shoe_levels:
		for k in 5:
			var colour: Color = GearCatalog.COLOURS[(k + int(y * 4)) % 3]["colour"]
			var at := Vector3(half.x - 0.3, y, 0.95 + k * 0.62)
			p.box(Vector3(0.28, 0.04, 0.11), WHITE, at + Vector3(0, 0.02, 0), Basis(Vector3.UP, PI * 0.5))   # the sole
			p.box(Vector3(0.24, 0.08, 0.1), colour, at + Vector3(0.02, 0.08, 0), Basis(Vector3.UP, PI * 0.5))
	_tag(p, "Trainers · %d Dh" % int(GameConfig.COSMETIC_PRICES["shoes"]), Vector3(half.x - 0.48, 1.66, 2.2), -90.0)
	# Two clothes rails with tops on hangers.
	for z in [0.9, 2.9]:
		for x in [1.9, 4.5]:
			p.box(Vector3(0.05, 1.7, 0.05), STEEL, Vector3(x, 0.85, z))
			p.box(Vector3(0.5, 0.02, 0.5), STEEL, Vector3(x, 0.01, z))
		p.box(Vector3(2.7, 0.04, 0.04), STEEL, Vector3(3.2, 1.7, z))
		for k in 8:
			var colour: Color = GearCatalog.COLOURS[k % 3]["colour"]
			p.box(Vector3(0.05, 0.75, 0.55), colour if k % 2 == 0 else colour.lightened(0.3), Vector3(2.15 + k * 0.3, 1.25, z))
			p.box(Vector3(0.012, 0.08, 0.012), STEEL, Vector3(2.15 + k * 0.3, 1.66, z))   # its hanger hook
		LowPoly.solid_box(p.body, Vector3(2.8, 1.7, 0.6), Vector3(3.2, 0.85, z))
	_tag(p, "Tops · %d Dh" % int(GameConfig.COSMETIC_PRICES["tops"]), Vector3(4.66, 1.45, 2.932), 0.0)
	# Folded hoodies on a table.
	var table := Vector3(-3.4, 0, 2.9)
	p.prop("kenney_furniture/table", table, 0.0, "floor", Vector3(1.6, 0.75, 0.8))
	LowPoly.solid_box(p.body, Vector3(1.5, 0.75, 0.7), table + Vector3(0, 0.375, 0))
	p.counter_tops.append([Rect2(table.x - 0.8, table.z - 0.4, 1.6, 0.8), 0.75])
	for k in 4:
		for n in 3 + k % 2:
			p.box(Vector3(0.32, 0.07, 0.28), GearCatalog.COLOURS[(k + n) % 3]["colour"].darkened(0.1 * (n % 2)), table + Vector3(-0.55 + k * 0.37, 0.785 + n * 0.07, 0))
	_tag(p, "Hoodies · %d Dh" % int(GameConfig.COSMETIC_PRICES["tops"]), table + Vector3(0, 0.69, 0.406), 0.0)
	# The changing room in the back-left corner.
	var room := Vector3(-half.x + 0.125 + 0.9, 0, back + 0.8)   # 1.8 x 1.6 m, against both walls
	p.box(Vector3(1.8, 0.05, 1.6), STEEL, room + Vector3(0, 2.3, 0))
	p.box(Vector3(0.04, 2.3, 1.6), Color(0.95, 0.93, 0.9), room + Vector3(0.9, 1.15, 0))
	p.box(Vector3(1.84, 0.3, 0.03), Color(0.95, 0.93, 0.9), room + Vector3(0.02, 2.45, 0.8))      # the board over the front
	p.box(Vector3(1.76, 0.03, 0.03), STEEL, room + Vector3(0, 2.22, 0.8))                           # the curtain rail
	for k in 6:
		p.box(Vector3(0.3, 1.96, 0.03), orange.darkened(0.15 * (k % 2)), room + Vector3(-0.75 + k * 0.3, 1.225, 0.8))
	LowPoly.solid_box(p.body, Vector3(1.8, 2.3, 1.6), room + Vector3(0, 1.15, 0))
	p.sign("غرفة القياس", "Fitting room", room + Vector3(0.02, 2.45, 0.84), 0.0, orange.darkened(0.35), Color(0, 0, 0, 0), 20)
	# Shelves of folded tops and backpacks along the back wall, beside the changing room.
	var levels := [0.5, 1.1, 1.7, 2.3]
	_shelves(p, "back", -3.8, -0.2, 0.45, levels, WOOD)
	for y: float in levels:
		for k in 5:
			var x := -3.45 + k * 0.7
			var colour: Color = GearCatalog.COLOURS[(k + int(y * 3)) % 3]["colour"]
			if y > 2.0:
				p.box(Vector3(0.3, 0.36, 0.2), colour.darkened(0.15), Vector3(x, y + 0.18, back + 0.22))   # a backpack
				p.box(Vector3(0.22, 0.14, 0.04), colour, Vector3(x, y + 0.12, back + 0.34))
			else:
				for n in 3:
					p.box(Vector3(0.34, 0.07, 0.3), colour.darkened(0.08 * n), Vector3(x, y + 0.035 + n * 0.072, back + 0.24))
	_tag(p, "Backpacks · %d Dh" % int(GameConfig.COSMETIC_PRICES["bags"]), Vector3(-2.0, 2.95, back + 0.006), 0.0)
	# Two mannequins in the window, dressed in the shop's clothes.
	for i in 2:
		var at := Vector3([-4.6, 4.6][i], 0, 4.25)
		p.cyl(0.35, 0.35, 0.08, DARK, at + Vector3(0, 0.04, 0), Basis(), 16)
		_mannequin(p, at + Vector3(0, 0.08, 0), [Color(0.12, 0.53, 0.59), Color(0.9, 0.27, 0.16)][i], i)
		LowPoly.solid_cylinder(p.body, 0.35, 1.8, at + Vector3(0, 0.9, 0))
	p.prop("kenney_furniture/benchCushionLow", Vector3(-half.x + 0.45, 0, 2.6), 90.0, "floor")
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(-half.x + 0.5, 0, 4.4))
	p.plant(Vector3(2.6, 0, 4.4), false)
	p.body.set_meta("interior_style", "clothes_mirror")


## A shop dummy: a person painted pale grey, standing still, wearing a top, a cap and
## sunglasses from the shop.
static func _mannequin(p: InteriorParts, at: Vector3, top: Color, look: int) -> void:
	var dummy := PeopleLooks.resident(2)
	var pale := Color(0.9, 0.9, 0.88)
	dummy.paint({"skin": pale, "eyes": pale, "hair": pale, "shirt": top, "pants": Color(0.2, 0.22, 0.28)})
	PeopleLooks.cap(dummy, GearCatalog.COLOURS[(look + 2) % 3]["colour"], dummy)
	if look == 1:
		PeopleLooks.sunglasses(dummy, Color(0.1, 0.1, 0.1), dummy)
	dummy.name = "Mannequin%d" % (look + 1)
	dummy.position = at
	dummy.rotation.y = PI   # our people face -Z: turn them to look out of the window
	p.inside.add_child(dummy)
	dummy.play("idle", 0.0)
