class_name ShopRooms
extends RefCounted
## Session 59: the insides of Pedal Point Bikes and Dune Drip, rebuilt for their 12 x 10 m
## rooms in the Plaza rows (Session 57 only squeezed the old ones in). ShopInterior still
## builds the walls, the counter at ShopInterior.COUNTER and the staff; this adds the rest.
## The spot where your bike (or you) stands in the shop screen, ShopInterior.PREVIEW, and
## the view to it from the shop camera (1, 1.9, 3.2) are kept clear.
## - Pedal Point Bikes, like a real bike shop: bikes hanging on the walls with price tags,
##   a workbench with the tool pegboard and the mechanic, a repair stand with a bike, a tyre
##   rack, helmets on a shelf, and the turntable your bike stands on when you shop.
## - Dune Drip, like a real streetwear shop: a caps wall behind the till, sunglasses on the
##   counter, clothes rails, folded hoodies on a table, a rug, a big mirror, a changing room.

const STEEL := Color(0.72, 0.74, 0.77)
const DARK := Color(0.15, 0.16, 0.17)
const WOOD := Color(0.62, 0.45, 0.28)


## Floor tiles over the room's floor, the lamps and the sound. p: the room's parts.
static func _room(p: InteriorParts, a: Color, b: Color, planks: bool, lamp: Color) -> void:
	var half := p.size * 0.5
	var tile := 0.25 if planks else 0.6
	for i in roundi(p.size.x / tile):
		for k in roundi(p.size.z / tile):
			var colour := a.lerp(b, float((i * 7 + (k / 4) * 3) % 5) / 4.0) if planks else (a if (i + k) % 2 == 0 else b)
			p.box(Vector3(tile * (1.0 if planks else 0.98), 0.02, tile * 0.98), colour, Vector3(-half.x + (i + 0.5) * tile, 0.0, -half.z + (k + 0.5) * tile))
	var c := ShopInterior.COUNTER
	p.counter_tops.append([Rect2(c.x - 2.0, c.z - 0.7, 4.0, 1.2), 1.05])
	for i in 4:
		p.lamp([Vector3(-3.0, 0, 1.5), Vector3(3.0, 0, 1.5), Vector3(-3.0, 0, -2.0), Vector3(1.0, 0, -0.5)][i], lamp, i == 3, true)
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


# ---------------------------------------------------------------- Pedal Point Bikes

static func bikes(p: InteriorParts) -> void:
	var half := p.size * 0.5
	var teal := p.brand
	_room(p, Color(0.62, 0.63, 0.62), Color(0.55, 0.56, 0.56), false, teal)
	var back := -half.z + 0.125
	# The workbench along the back wall, the tool pegboard above it, the mechanic.
	p.solid(Vector3(4.6, 0.92, 0.7), WOOD.darkened(0.2), Vector3(-3.0, 0.46, back + 0.35))
	p.box(Vector3(4.64, 0.06, 0.74), WOOD, Vector3(-3.0, 0.95, back + 0.35))
	p.counter_tops.append([Rect2(-5.3, back, 4.6, 0.72), 0.98])
	p.box(Vector3(0.2, 0.14, 0.18), Color(0.25, 0.45, 0.6), Vector3(-4.8, 1.05, back + 0.5))   # the vice
	p.box(Vector3(0.06, 0.06, 0.24), DARK, Vector3(-4.8, 1.05, back + 0.66))
	p.box(Vector3(4.6, 1.6, 0.05), Color(0.82, 0.74, 0.58), Vector3(-3.0, 2.2, back + 0.03))
	for k in 18:   # holes and tools on the pegboard
		var x := -5.1 + (k % 9) * 0.52
		var y := 1.75 + (k / 9) * 0.75
		match k % 3:
			0:
				p.box(Vector3(0.04, 0.42, 0.02), DARK, Vector3(x, y + 0.1, back + 0.07))   # spanner
				p.box(Vector3(0.1, 0.06, 0.02), DARK, Vector3(x, y + 0.33, back + 0.07))
			1:
				p.box(Vector3(0.05, 0.32, 0.03), Color(0.75, 0.2, 0.15), Vector3(x, y + 0.05, back + 0.07))   # screwdriver
				p.box(Vector3(0.015, 0.2, 0.015), STEEL, Vector3(x, y + 0.3, back + 0.07))
			2:
				p.box(Vector3(0.24, 0.05, 0.03), Color(0.95, 0.75, 0.15), Vector3(x, y + 0.2, back + 0.07))   # tyre levers
				p.box(Vector3(0.22, 0.05, 0.03), Color(0.2, 0.45, 0.8), Vector3(x, y + 0.08, back + 0.07))
	p.sign("ورشة", "Workshop", Vector3(-3.0, 3.25, back + 0.06), 0.0, Color.WHITE, teal.darkened(0.2), 26)
	p.worker("Mechanic2", Vector3(-3.6, 0, -3.95), 180.0, 1)
	# The repair stand with a bike up on it.
	var stand := Vector3(-4.2, 0, -2.75)
	p.box(Vector3(0.7, 0.04, 0.06), DARK, stand + Vector3(0, 0.02, 0))
	p.box(Vector3(0.06, 0.04, 0.7), DARK, stand + Vector3(0, 0.02, 0))
	p.box(Vector3(0.06, 1.25, 0.06), Color(0.85, 0.2, 0.2), stand + Vector3(0, 0.66, 0))
	p.box(Vector3(0.06, 0.06, 0.35), DARK, stand + Vector3(0, 1.28, 0.15))
	_bike(p, stand + Vector3(0, 0.55, 0.3), 90.0)
	# Bikes hanging on the left wall on hooks, with price tags.
	var tags: Array = []
	for item: Dictionary in GearCatalog.items("bikes"):
		if item.get("slot", "") == "upgrade" and tags.size() < 3:
			tags.append("%s · %d Dh" % [item["name"], GearCatalog.price(item)])
	for i in 3:
		var z := 3.4 - i * 1.9
		for dz in [-0.45, 0.45]:
			p.box(Vector3(0.35, 0.04, 0.04), DARK, Vector3(-half.x + 0.3, 2.65, z + dz))
		_bike(p, Vector3(-half.x + 0.42, 2.05, z), 0.0)
		p.box(Vector3(0.02, 0.18, 0.5), Color(0.98, 0.98, 0.95), Vector3(-half.x + 0.6, 2.4, z))
		var tag := SignText.make_label(tags[i % tags.size()], 10, Color(0.1, 0.1, 0.1), Color(0, 0, 0, 0), 0)
		tag.position = Vector3(-half.x + 0.62, 2.4, z)
		tag.rotation.y = PI * 0.5
		p.body.add_child(tag)
	# The tyre rack on the right wall and helmets on a shelf.
	var rack_x := half.x - 0.35
	p.box(Vector3(0.08, 2.0, 0.08), DARK, Vector3(rack_x, 1.0, 0.8))
	p.box(Vector3(0.08, 2.0, 0.08), DARK, Vector3(rack_x, 1.0, 3.6))
	for y in [0.75, 1.65]:
		p.box(Vector3(0.06, 0.06, 2.8), DARK, Vector3(rack_x, y, 2.2))
		for k in 5:
			var at := Vector3(rack_x - 0.05, y - 0.3, 1.1 + k * 0.55)
			p.cyl(0.33, 0.33, 0.05, Color(0.1, 0.1, 0.1), at, Basis(Vector3.FORWARD, PI * 0.5), 14)
			p.cyl(0.22, 0.22, 0.06, Color(0.55, 0.57, 0.6), at, Basis(Vector3.FORWARD, PI * 0.5), 12)
	LowPoly.solid_box(p.body, Vector3(0.5, 2.0, 2.9), Vector3(rack_x, 1.0, 2.2))
	p.box(Vector3(0.35, 0.04, 2.0), WOOD, Vector3(half.x - 0.3, 1.6, -0.5))
	for k in 4:
		p.kit.ball(0.15, [teal, Color(0.95, 0.4, 0.2), Color(0.95, 0.95, 0.9), DARK][k], Vector3(half.x - 0.3, 1.64, -1.25 + k * 0.5), 0.75)
	# The turntable your bike stands on in the shop screen.
	var spot := ShopInterior.PREVIEW
	p.cyl(1.0, 1.0, 0.08, Color(0.3, 0.32, 0.33), spot + Vector3(0, 0.04, 0), Basis(), 24)
	p.cyl(1.02, 1.02, 0.05, teal, spot + Vector3(0, 0.03, 0), Basis(), 24)
	p.cyl(0.06, 0.08, 0.6, Color(0.3, 0.32, 0.32), spot + Vector3(0, 0.38, 0), Basis(), 8)
	# On the counter: the till, a pump, bottles of chain oil.
	var c := ShopInterior.COUNTER
	p.till(Vector3(c.x + 1.2, 1.05, c.z - 0.3))
	p.box(Vector3(0.12, 0.05, 0.2), DARK, Vector3(c.x - 1.4, 1.075, c.z - 0.2))
	p.box(Vector3(0.04, 0.6, 0.04), Color(0.85, 0.2, 0.2), Vector3(c.x - 1.4, 1.38, c.z - 0.2))
	for k in 4:
		p.cyl(0.03, 0.03, 0.16, [Color(0.2, 0.6, 0.3), Color(0.95, 0.75, 0.2)][k % 2], Vector3(c.x - 0.6 + k * 0.09, 1.13, c.z - 0.5), Basis(), 8)
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(half.x - 0.5, 0, 4.3))
	p.body.set_meta("interior_style", "bike_workshop")


## A bike model (the same one you ride) with no rider, at `at`, turned `facing` degrees.
static func _bike(p: InteriorParts, at: Vector3, facing: float) -> void:
	var bike := Node3D.new()
	BikeModel.build(bike)
	var rider := bike.get_node_or_null("Rider")
	if rider != null:
		rider.free()
	bike.position = at
	bike.rotation.y = deg_to_rad(facing)
	p.body.add_child(bike)


# ---------------------------------------------------------------- Dune Drip

static func clothes(p: InteriorParts) -> void:
	var half := p.size * 0.5
	var orange := p.brand
	_room(p, Color(0.78, 0.62, 0.45), Color(0.7, 0.55, 0.38), true, orange)
	var back := -half.z + 0.125
	# The big mirror on the left wall (you see yourself in it in the shop screen).
	p.box(Vector3(0.12, 2.9, 2.6), WOOD, Vector3(-half.x + 0.18, 1.6, 0.0))
	p.glow(Vector3(0.02, 2.7, 2.4), Color(0.75, 0.85, 0.88), Vector3(-half.x + 0.25, 1.6, 0.0), 0.15)
	# The rug where you stand when you try things on.
	var spot := ShopInterior.PREVIEW
	p.box(Vector3(3.2, 0.015, 2.4), Color(0.65, 0.25, 0.23), spot + Vector3(-0.3, 0.012, 0))
	p.box(Vector3(2.8, 0.016, 2.0), Color(0.9, 0.75, 0.45), spot + Vector3(-0.3, 0.013, 0))
	# The caps wall behind the till: rows of caps on pegs in every colour.
	p.box(Vector3(5.0, 1.8, 0.05), Color(0.25, 0.25, 0.27), Vector3(3.0, 2.3, back + 0.03))
	for row in 3:
		for k in 8:
			var at := Vector3(0.9 + k * 0.6, 1.75 + row * 0.55, back + 0.18)
			var colour: Color = GearCatalog.COLOURS[(k + row) % 3]["colour"]
			p.box(Vector3(0.02, 0.02, 0.12), STEEL, at + Vector3(0, -0.02, -0.08))
			p.kit.ball(0.14, colour, at, 0.7)
			p.box(Vector3(0.22, 0.02, 0.14), colour.darkened(0.2), at + Vector3(0, -0.05, 0.14))
	p.sign("قبعات", "Caps", Vector3(3.0, 3.45, back + 0.06), 0.0, Color.WHITE, orange.darkened(0.2), 26)
	# Sunglasses on a stepped stand on the counter.
	var c := ShopInterior.COUNTER
	p.till(Vector3(c.x + 1.2, 1.05, c.z - 0.3))
	for step in 3:
		p.box(Vector3(1.0, 0.06, 0.15), Color(0.95, 0.95, 0.93), Vector3(c.x - 0.9, 1.08 + step * 0.1, c.z + 0.1 - step * 0.15))
		for k in 4:
			p.box(Vector3(0.17, 0.05, 0.02), [DARK, Color(0.3, 0.2, 0.1), Color(0.6, 0.15, 0.15), Color(0.15, 0.3, 0.6)][(k + step) % 4],
					Vector3(c.x - 1.25 + k * 0.23, 1.14 + step * 0.1, c.z + 0.13 - step * 0.15))
	# Two clothes rails with tops on hangers.
	for z in [0.6, 2.7]:
		for x in [2.7, 5.3]:
			p.box(Vector3(0.05, 1.7, 0.05), STEEL, Vector3(x, 0.85, z))
			p.box(Vector3(0.5, 0.04, 0.5), STEEL, Vector3(x, 0.02, z))
		p.box(Vector3(2.7, 0.04, 0.04), STEEL, Vector3(4.0, 1.7, z))
		for k in 8:
			var colour: Color = GearCatalog.COLOURS[k % 3]["colour"]
			p.box(Vector3(0.05, 0.75, 0.55), colour if k % 2 == 0 else colour.lightened(0.3), Vector3(2.95 + k * 0.3, 1.25, z))
		LowPoly.solid_box(p.body, Vector3(2.8, 1.7, 0.6), Vector3(4.0, 0.85, z))
	# Folded hoodies on a table.
	var table := Vector3(-3.6, 0, 3.1)
	p.prop("kenney_furniture/table", table, 0.0, "floor", Vector3(1.6, 0.75, 0.8))
	LowPoly.solid_box(p.body, Vector3(1.5, 0.75, 0.7), table + Vector3(0, 0.375, 0))
	for k in 4:
		for n in 3 + k % 2:
			p.box(Vector3(0.32, 0.07, 0.28), GearCatalog.COLOURS[(k + n) % 3]["colour"].darkened(0.1 * (n % 2)), table + Vector3(-0.55 + k * 0.37, 0.79 + n * 0.072, 0))
	# The changing room in the back-left corner.
	var room := Vector3(-4.9, 0, -4.0)
	p.box(Vector3(1.8, 0.05, 1.6), STEEL, room + Vector3(0, 2.3, 0))
	p.box(Vector3(0.04, 2.3, 1.6), Color(0.95, 0.93, 0.9), room + Vector3(0.9, 1.15, 0))
	for k in 6:
		p.box(Vector3(0.3, 2.0, 0.03), orange.darkened(0.15 * (k % 2)), room + Vector3(-0.75 + k * 0.3, 1.2, 0.8))
	LowPoly.solid_box(p.body, Vector3(1.8, 2.3, 1.6), room + Vector3(0, 1.15, 0))
	p.bin(Vector3(1.75, 0, 4.35))
	p.plant(Vector3(-half.x + 0.5, 0, 4.3))
	p.plant(Vector3(half.x - 0.5, 0, -1.2))
	p.body.set_meta("interior_style", "clothes_mirror")
