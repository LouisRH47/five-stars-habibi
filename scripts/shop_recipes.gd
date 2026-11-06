class_name ShopRecipes
extends RefCounted
## Looks pass Session 57: what's inside the two shops (scripts/shop_interior.gd builds the room).
##   Pedal Point Bikes: bikes hanging on the left wall, a tool pegboard over the workbench,
##     a tyre rack, a repair stand with a bike, bikes on show by the window, helmets
##   Dune Drip: a caps and sunglasses wall, two clothes rails, a table of folded hoodies,
##     a rug and a big mirror, shelves of T-shirts, two mannequins in the window
## The camera line from the shop screen (local (1, 1.9, 3.2) to the preview at PREVIEW) and
## the walk from the door to COUNTER are kept clear.

const WOOD := Color(0.43, 0.3, 0.18)
const LIGHT_WOOD := Color(0.7, 0.52, 0.33)
const METAL := Color(0.3, 0.32, 0.33)
const STEEL := Color(0.7, 0.72, 0.74)
const RUBBER := Color(0.1, 0.1, 0.11)
const PAINTS := [Color(0.85, 0.2, 0.2), Color(0.15, 0.45, 0.8), Color(0.95, 0.75, 0.15),
		Color(0.2, 0.65, 0.4), Color(0.95, 0.95, 0.95), Color(0.1, 0.1, 0.12)]
const CLOTHES := [Color(0.9, 0.35, 0.25), Color(0.15, 0.4, 0.55), Color(0.95, 0.8, 0.55),
		Color(0.3, 0.3, 0.32), Color(0.55, 0.7, 0.45), Color(0.97, 0.97, 0.95), Color(0.6, 0.35, 0.6)]


# --- Pedal Point Bikes ---

static func bike_shop(room: StaticBody3D, half: Vector3) -> void:
	room.set_meta("interior_style", "bike_workshop")
	var preview := ShopInterior.PREVIEW
	# Bikes hanging by their front wheels along the left wall.
	var hanging := Node3D.new()
	hanging.name = "HangingBikes"
	room.add_child(hanging)
	for i in 5:
		var z := -7.2 + i * 2.9
		LowPoly.box(hanging, Vector3(0.4, 0.06, 0.06), METAL, Vector3(-half.x + 0.35, 2.95, z - 0.6))
		var bike := _bike(hanging, PAINTS[i])
		bike.position = Vector3(-half.x + 0.5, 2.0, z - 0.6)
		bike.rotation.x = PI * 0.5  # front wheel up
	# The tool pegboard over the workbench, behind the mechanic.
	var board := Node3D.new()
	board.name = "ToolPegboard"
	board.position = Vector3(4.8, 0, -half.z + 0.2)
	room.add_child(board)
	LowPoly.box(board, Vector3(6.6, 2.2, 0.05), Color(0.78, 0.7, 0.55), Vector3(0, 2.7, 0))
	for x in 12:
		for y in 4:
			var tool_x := -3.0 + x * 0.55
			var tool_y := 1.9 + y * 0.5
			match (x + y * 3) % 4:
				0:  # a spanner
					LowPoly.box(board, Vector3(0.05, 0.36, 0.02), STEEL, Vector3(tool_x, tool_y, 0.05))
				1:  # a screwdriver
					LowPoly.box(board, Vector3(0.04, 0.2, 0.02), STEEL, Vector3(tool_x, tool_y + 0.08, 0.05))
					LowPoly.box(board, Vector3(0.06, 0.14, 0.04), PAINTS[y % 3], Vector3(tool_x, tool_y - 0.08, 0.05))
				2:  # pliers
					LowPoly.box(board, Vector3(0.12, 0.3, 0.02), Color(0.85, 0.2, 0.2), Vector3(tool_x, tool_y, 0.05))
				_:  # a hex key set
					LowPoly.box(board, Vector3(0.16, 0.12, 0.03), Color(0.95, 0.75, 0.15), Vector3(tool_x, tool_y, 0.05))
	# The workbench with a vice, parts boxes and a wheel being trued.
	LowPoly.box(board, Vector3(6.6, 0.08, 0.8), LIGHT_WOOD, Vector3(0, 0.95, 0.4))
	for x in [-3.1, 3.1]:
		LowPoly.box(board, Vector3(0.08, 0.92, 0.7), METAL, Vector3(x, 0.46, 0.4))
	LowPoly.box(board, Vector3(6.4, 0.05, 0.7), METAL, Vector3(0, 0.25, 0.4))
	LowPoly.box(board, Vector3(0.3, 0.2, 0.25), METAL, Vector3(-2.7, 1.09, 0.5))
	for i in 6:
		LowPoly.box(board, Vector3(0.35, 0.18, 0.28), PAINTS[i % 4], Vector3(-1.8 + i * 0.45, 1.08, 0.3))
	var wheel := LowPoly.cylinder(board, 0.33, 0.33, 0.04, RUBBER, Vector3(2.2, 1.35, 0.45))
	wheel.rotation.x = PI * 0.5
	LowPoly.solid_box(room, Vector3(6.6, 1.0, 0.8), board.position + Vector3(0, 0.5, 0.4))
	# The tyre rack on the right wall.
	var tyres := Node3D.new()
	tyres.name = "TyreRack"
	tyres.position = Vector3(half.x - 0.5, 0, 4.0)
	room.add_child(tyres)
	for y in [0.8, 1.7]:
		LowPoly.box(tyres, Vector3(0.5, 0.05, 4.2), METAL, Vector3(0, y - 0.38, 0))
		for i in 8:
			var tyre := LowPoly.cylinder(tyres, 0.36, 0.36, 0.06, RUBBER, Vector3(0, y, -1.75 + i * 0.5))
			tyre.rotation.z = PI * 0.5
			var rim := LowPoly.cylinder(tyres, 0.28, 0.28, 0.065, Color(0.25, 0.25, 0.27), Vector3(0, y, -1.75 + i * 0.5))
			rim.rotation.z = PI * 0.5
	for z in [-2.1, 2.1]:
		LowPoly.box(tyres, Vector3(0.5, 2.2, 0.06), METAL, Vector3(0, 1.1, z))
	LowPoly.solid_box(room, Vector3(0.6, 2.2, 4.3), tyres.position + Vector3(0, 1.1, 0))
	# The repair stand with a bike clamped on it (your own bike turns on the other stand,
	# at PREVIEW, while you shop).
	var stand := Node3D.new()
	stand.name = "RepairStand"
	stand.position = Vector3(-5.5, 0, -5.2)
	room.add_child(stand)
	LowPoly.box(stand, Vector3(1.0, 0.05, 0.7), METAL, Vector3(0, 0.085, 0))
	LowPoly.box(stand, Vector3(0.07, 1.3, 0.07), METAL, Vector3(0, 0.75, 0))
	LowPoly.box(stand, Vector3(0.12, 0.12, 0.3), Color(0.85, 0.2, 0.2), Vector3(0, 1.4, 0))
	var fixing := _bike(stand, PAINTS[3])
	fixing.position = Vector3(0, 0.55, 0)
	fixing.rotation_degrees.y = 90.0
	LowPoly.solid_box(room, Vector3(2.0, 1.5, 0.8), stand.position + Vector3(0, 0.75, 0))
	# The preview stand.
	LowPoly.cylinder(room, 0.08, 0.08, 0.7, Color(0.3, 0.32, 0.32), preview + Vector3(0, 0.35, 0))
	LowPoly.box(room, Vector3(2.1, 0.06, 1.4), Color(0.3, 0.32, 0.32), preview + Vector3(0, 0.09, 0))
	# Bikes on show by the window, and a floor pump.
	for i in 2:
		var show := _bike(room, PAINTS[i + 1])
		show.position = Vector3(-7.2 + i * 2.6, 0.06, 6.6)
		show.rotation_degrees.y = 70.0
		var solid := LowPoly.solid_box(room, Vector3(1.0, 1.1, 1.9), show.position + Vector3(0, 0.55, 0))
		solid.rotation.y = show.rotation.y
	var pump := LowPoly.cylinder(room, 0.05, 0.05, 0.75, Color(0.85, 0.2, 0.2), Vector3(-4.3, 0.43, -4.2))
	pump.name = "FloorPump"
	LowPoly.box(room, Vector3(0.35, 0.03, 0.12), RUBBER, Vector3(-4.3, 0.075, -4.2))
	# Helmets on a shelf on the right wall, and a "Ride safe" poster.
	var shelf := Node3D.new()
	shelf.name = "HelmetShelf"
	shelf.position = Vector3(half.x - 0.35, 0, -3.0)
	room.add_child(shelf)
	for y in [1.0, 1.6, 2.2]:
		LowPoly.box(shelf, Vector3(0.5, 0.04, 2.6), LIGHT_WOOD, Vector3(0, y, 0))
		for i in 4:
			LowPoly.sphere(shelf, 0.15, 0.2, PAINTS[(i + int(y * 3)) % PAINTS.size()], Vector3(-0.05, y + 0.1, -0.9 + i * 0.6))
	var poster := SignText.make_face("قُد بأمان", "Ride safe", 48, Color.WHITE)
	LowPoly.box(room, Vector3(0.04, 1.2, 2.4), Color(0.1, 0.34, 0.39), Vector3(half.x - 0.17, 3.4, -3.0))
	poster.position = Vector3(half.x - 0.2, 3.4, -3.0)
	poster.rotation_degrees.y = -90.0
	room.add_child(poster)


## A bike without a rider, painted `paint` (for walls, stands and the window).
static func _bike(parent: Node3D, paint: Color) -> Node3D:
	var bike := Node3D.new()
	BikeModel.build(bike)
	bike.get_node("Rider").free()
	for part: MeshInstance3D in bike.find_children("*", "MeshInstance3D", true, false):
		if part.get_meta("bike_paint", false):
			part.material_override = LowPoly.material(paint)
	parent.add_child(bike)
	return bike


# --- Dune Drip ---

static func clothes_shop(room: StaticBody3D, half: Vector3) -> void:
	room.set_meta("interior_style", "clothes_mirror")
	var preview := ShopInterior.PREVIEW
	# The rug you stand on to try things, and the big mirror on the left wall.
	var rug := LowPoly.box(room, Vector3(4.2, 0.02, 4.2), Color(0.65, 0.25, 0.23), preview + Vector3(0, 0.07, 0))
	rug.name = "Rug"
	LowPoly.box(room, Vector3(3.6, 0.02, 3.6), Color(0.9, 0.75, 0.45), preview + Vector3(0, 0.072, 0))
	LowPoly.box(room, Vector3(3.2, 0.02, 3.2), Color(0.65, 0.25, 0.23), preview + Vector3(0, 0.074, 0))
	LowPoly.box(room, Vector3(0.16, 3.4, 4.4), WOOD, Vector3(-half.x + 0.4, 1.8, 0))
	var mirror := LowPoly.box(room, Vector3(0.04, 3.1, 4.0), Color.WHITE, Vector3(-half.x + 0.5, 1.8, 0))
	mirror.name = "BigMirror"
	var silver := StandardMaterial3D.new()
	silver.albedo_color = Color(0.72, 0.84, 0.88)
	silver.metallic = 1.0
	silver.roughness = 0.05
	mirror.material_override = silver
	# The caps and sunglasses wall (back wall, left side).
	var wall := Node3D.new()
	wall.name = "CapsWall"
	wall.position = Vector3(-4.6, 0, -half.z + 0.2)
	room.add_child(wall)
	LowPoly.box(wall, Vector3(7.6, 3.4, 0.05), Color(0.93, 0.85, 0.7), Vector3(0, 2.3, 0))
	for row in 2:
		for i in 8:
			var at := Vector3(-3.2 + i * 0.9, 3.3 - row * 0.75, 0.2)
			var colour: Color = CLOTHES[(i + row * 3) % CLOTHES.size()]
			LowPoly.sphere(wall, 0.16, 0.2, colour, at)
			LowPoly.box(wall, Vector3(0.24, 0.02, 0.18), colour.darkened(0.2), at + Vector3(0, -0.06, 0.16))
	LowPoly.box(wall, Vector3(7.2, 0.06, 0.12), Color.WHITE, Vector3(0, 1.75, 0.08))
	for row in 2:
		for i in 9:
			var at := Vector3(-3.4 + i * 0.85, 1.55 - row * 0.45, 0.07)
			for side in [-0.065, 0.065]:
				LowPoly.box(wall, Vector3(0.1, 0.06, 0.02), RUBBER if (i + row) % 3 else Color(0.6, 0.35, 0.1), at + Vector3(side, 0, 0))
			LowPoly.box(wall, Vector3(0.26, 0.015, 0.02), Color(0.8, 0.65, 0.2), at + Vector3(0, 0.03, 0))
	var label := SignText.make_face("قبعات ونظارات", "Caps & shades", 40, Color(0.35, 0.2, 0.1))
	label.position = Vector3(0, 4.2, 0.05)
	wall.add_child(label)
	# Two clothes rails, away from the walk to the till and the shop camera.
	_rail(room, "RailRight", Vector3(half.x - 1.2, 0, 2.5), 90.0, 6.0, 0)
	_rail(room, "RailFront", Vector3(5.5, 0, 5.0), 0.0, 3.6, 3)
	# A table of folded hoodies.
	var table := Node3D.new()
	table.name = "HoodieTable"
	table.position = Vector3(6.6, 0, 0.8)
	room.add_child(table)
	LowPoly.box(table, Vector3(2.0, 0.08, 1.1), LIGHT_WOOD, Vector3(0, 0.8, 0))
	for x in [-0.9, 0.9]:
		LowPoly.box(table, Vector3(0.08, 0.76, 1.0), WOOD, Vector3(x, 0.38, 0))
	for stack in 3:
		for k in 4:
			LowPoly.box(table, Vector3(0.5, 0.09, 0.4), CLOTHES[(stack * 2 + k) % CLOTHES.size()], Vector3(-0.6 + stack * 0.6, 0.89 + k * 0.095, 0))
	LowPoly.solid_box(room, Vector3(2.0, 0.9, 1.1), table.position + Vector3(0, 0.45, 0))
	# Shelves of folded T-shirts behind the till.
	for y in [1.1, 2.0, 2.9]:
		LowPoly.box(room, Vector3(5.2, 0.08, 0.6), WOOD, Vector3(5.0, y, -half.z + 0.5))
		for i in 7:
			LowPoly.box(room, Vector3(0.55, 0.22, 0.4), CLOTHES[(i + int(y)) % CLOTHES.size()], Vector3(2.8 + i * 0.73, y + 0.15, -half.z + 0.5))
	# Two mannequins in the window, in hoodies and caps.
	for i in 2:
		_mannequin(room, "Mannequin%d" % i, Vector3(-7.0 + i * 13.0, 0, 7.4), CLOTHES[i * 2 + 1])


## A clothes rail with shirts and hoodies on hangers. facing 0 = the rail runs along X.
static func _rail(room: StaticBody3D, name: String, at: Vector3, facing: float, length: float, start: int) -> void:
	var rail := Node3D.new()
	rail.name = name
	rail.position = at
	rail.rotation_degrees.y = facing
	room.add_child(rail)
	LowPoly.box(rail, Vector3(length, 0.06, 0.6), WOOD, Vector3(0, 0.1, 0))
	for x in [-length * 0.5 + 0.1, length * 0.5 - 0.1]:
		LowPoly.cylinder(rail, 0.04, 0.04, 1.75, STEEL, Vector3(x, 1.0, 0))
	var bar := LowPoly.cylinder(rail, 0.025, 0.025, length, STEEL, Vector3(0, 1.85, 0))
	bar.rotation.z = PI * 0.5
	var count := int(length / 0.32)
	for i in count:
		var x := -length * 0.5 + 0.3 + i * (length - 0.6) / maxf(1.0, count - 1)
		var colour: Color = CLOTHES[(start + i / 2) % CLOTHES.size()]
		LowPoly.box(rail, Vector3(0.08, 0.06, 0.4), STEEL, Vector3(x, 1.8, 0))
		LowPoly.box(rail, Vector3(0.07, 0.8 if i % 3 else 0.95, 0.5), colour, Vector3(x, 1.35 if i % 3 else 1.28, 0))
	var size := Vector3(length, 1.9, 0.7) if facing == 0.0 else Vector3(0.7, 1.9, length)
	LowPoly.solid_box(room, size, at + Vector3(0, 0.95, 0))


## A plain white mannequin wearing a hoodie, shorts and a cap.
static func _mannequin(room: StaticBody3D, name: String, at: Vector3, hoodie: Color) -> void:
	var figure := Node3D.new()
	figure.name = name
	figure.position = at
	figure.rotation_degrees.y = 180.0  # faces out of the window
	room.add_child(figure)
	var white := Color(0.94, 0.94, 0.92)
	LowPoly.box(figure, Vector3(0.5, 0.05, 0.5), METAL, Vector3(0, 0.085, 0))
	for x in [-0.1, 0.1]:
		LowPoly.cylinder(figure, 0.06, 0.05, 0.85, white, Vector3(x, 0.55, 0))
	LowPoly.box(figure, Vector3(0.36, 0.28, 0.2), Color(0.2, 0.2, 0.25), Vector3(0, 1.05, 0))
	LowPoly.box(figure, Vector3(0.44, 0.58, 0.26), hoodie, Vector3(0, 1.45, 0))
	for x in [-0.27, 0.27]:
		LowPoly.box(figure, Vector3(0.11, 0.55, 0.13), hoodie, Vector3(x, 1.42, 0))
	LowPoly.sphere(figure, 0.13, 0.28, white, Vector3(0, 1.92, 0))
	LowPoly.sphere(figure, 0.135, 0.15, hoodie.darkened(0.3), Vector3(0, 2.0, 0))
	LowPoly.box(figure, Vector3(0.2, 0.02, 0.16), hoodie.darkened(0.3), Vector3(0, 1.96, -0.17))
	LowPoly.solid_box(room, Vector3(0.6, 2.0, 0.6), at + Vector3(0, 1.0, 0))
