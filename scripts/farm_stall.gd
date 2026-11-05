extends StaticBody3D
## The Wahat Farm Stall (Session 27): a little wooden market stall by the greenhouse domes,
## with a counter, crates of fruit and veg, juice bottles, a green and white striped roof
## and a bilingual sign board. The front is the +Z side. PlaceBuilder makes one for a shop
## with "style": "stall" and calls setup(). The whole stall is solid.
## Session 69: the beekeeper's stall ("goods": "honey") has honey jars and wax candles instead.

const WOOD := Color(0.62, 0.43, 0.26, 1)
const DARK_WOOD := Color(0.45, 0.3, 0.18, 1)
const WHITE := Color(0.97, 0.96, 0.92, 1)
const TEXT_COLOUR := Color(1, 1, 1, 1)
const FRUIT := [Color(0.95, 0.55, 0.1, 1), Color(0.85, 0.15, 0.15, 1), Color(0.45, 0.7, 0.2, 1),
		Color(0.98, 0.85, 0.2, 1)]
const ROOF_STRIPES := 6
const BOARD_HEIGHT := 0.9
const BOARD_FONT_SIZE := 64
const HONEY := Color(0.92, 0.6, 0.1, 1)
const WAX := Color(0.98, 0.9, 0.62, 1)

## What's on the counter: "farm" (fruit, veg and juice) or "honey" (jars and candles).
var goods := "farm"


## Builds the stall. size: width, height, depth. colour: the farm green.
func setup(english: String, arabic: String, colour: Color, size: Vector3) -> void:
	var front := size.z * 0.5
	LowPoly.solid_box(self, Vector3(size.x, 1.6, size.z), Vector3(0, 0.8, 0))
	# The back wall and the counter at the front.
	LowPoly.box(self, Vector3(size.x, 2.6, 0.2), WOOD, Vector3(0, 1.3, -front + 0.1))
	LowPoly.box(self, Vector3(size.x, 1.0, 0.8), WOOD, Vector3(0, 0.5, front - 0.4))
	LowPoly.box(self, Vector3(size.x + 0.2, 0.08, 1.0), DARK_WOOD, Vector3(0, 1.04, front - 0.4))
	# Corner posts holding up the roof.
	for x in [-size.x * 0.5 + 0.15, size.x * 0.5 - 0.15]:
		for z in [-front + 0.15, front - 0.15]:
			LowPoly.box(self, Vector3(0.15, size.y - 0.3, 0.15), DARK_WOOD, Vector3(x, (size.y - 0.3) * 0.5, z))
	if goods == "honey":
		_honey_counter(size, front)
	else:
		_farm_counter(size, front)
		_farm_extras(colour, size, front)  # looks pass Session 57
	_roof_and_sign(english, arabic, colour, size)
	Props.bake_kits(self)


## Crates of fruit and veg on the counter, and juice bottles.
func _farm_counter(size: Vector3, front: float) -> void:
	for i in 4:
		var x := -size.x * 0.5 + 0.8 + i * (size.x - 1.6) / 3.0
		LowPoly.box(self, Vector3(0.9, 0.3, 0.6), DARK_WOOD, Vector3(x, 1.23, front - 0.4))
		for j in 3:
			LowPoly.sphere(self, 0.13, 0.26, FRUIT[i], Vector3(x - 0.25 + j * 0.25, 1.45, front - 0.4))
	for i in 5:
		LowPoly.cylinder(self, 0.06, 0.07, 0.3, Color(0.98, 0.6, 0.15, 1),
				Vector3(-0.6 + i * 0.3, 1.2, front - 0.15))


## Looks pass Session 57: a striped awning, the farmer, a juice press and a cooler behind the
## counter, kit crates of veg in front and a chalkboard menu by the stall.
func _farm_extras(colour: Color, size: Vector3, front: float) -> void:
	set_meta("interior_style", "farm_stall")
	var awning := Node3D.new()
	awning.name = "Awning"
	awning.position = Vector3(0, size.y - 0.55, front + 0.2)
	awning.rotation.x = deg_to_rad(22.0)
	add_child(awning)
	var stripe := size.x / (ROOF_STRIPES * 2)
	for i in ROOF_STRIPES * 2:
		var x := -size.x * 0.5 + stripe * (i + 0.5)
		var shade: Color = colour if i % 2 == 0 else WHITE
		LowPoly.box(awning, Vector3(stripe, 0.04, 1.6), shade, Vector3(x, 0, 0.8))
		LowPoly.box(awning, Vector3(stripe, 0.22, 0.03), shade, Vector3(x, -0.1, 1.6))  # the frill
	# The farmer behind the counter, in a straw sun hat.
	var farmer := Person.new()
	farmer.paint({"skin": PeopleLooks.SKINS[2], "shirt": Color(0.35, 0.55, 0.3), "pants": Color(0.4, 0.33, 0.25)})
	PlaceLooks.sun_hat(farmer)
	PeopleLooks.shoes(farmer, Color(0.3, 0.22, 0.15))
	farmer.name = "Farmer"
	farmer.set_meta("outfit", "sun hat")
	farmer.position = Vector3(-1.2, 0, front - 1.3)
	farmer.rotation.y = PI  # faces the customers (+Z)
	add_child(farmer)
	for part: MeshInstance3D in farmer.find_children("*", "MeshInstance3D", true, false):
		part.visibility_range_end = GameConfig.ROOM_PEOPLE_DRAW_DISTANCE
	# The juice press on a back table, and a glass cooler of juice bottles.
	var press := Node3D.new()
	press.name = "JuicePress"
	press.position = Vector3(2.2, 0, -front + 0.7)
	add_child(press)
	LowPoly.box(press, Vector3(1.6, 0.06, 0.8), DARK_WOOD, Vector3(0, 0.9, 0))
	for x in [-0.7, 0.7]:
		LowPoly.box(press, Vector3(0.08, 0.88, 0.7), DARK_WOOD, Vector3(x, 0.44, 0))
	LowPoly.cylinder(press, 0.18, 0.2, 0.45, Color(0.75, 0.77, 0.8), Vector3(-0.2, 1.16, 0))
	LowPoly.cylinder(press, 0.05, 0.05, 0.5, Color(0.3, 0.3, 0.32), Vector3(-0.2, 1.6, 0))
	var lever := LowPoly.box(press, Vector3(0.5, 0.04, 0.04), Color(0.3, 0.3, 0.32), Vector3(0.0, 1.8, 0))
	lever.rotation.z = -0.4
	var jug := LowPoly.cylinder(press, 0.1, 0.12, 0.28, Color(0.98, 0.6, 0.15), Vector3(0.35, 1.07, 0.1))
	jug.name = "JuiceJug"
	for i in 6:
		LowPoly.sphere(press, 0.08, 0.16, FRUIT[i % 2], Vector3(0.45 + (i % 3) * 0.15, 0.98, -0.2 + (i / 3) * 0.14))
	var cooler := RoomProps.drinks_fridge(self, Vector3(-3.1, 0, -front + 0.55), 0.0)
	cooler.name = "JuiceCooler"
	# Crates of veg from the kit, in front of the counter.
	var crates := ["restaurant/crate_carrots", "restaurant/crate_tomatoes", "restaurant/crate_lettuce",
			"restaurant/crate_onions", "restaurant/crate_potatoes"]
	for i in crates.size():
		Props.kit(crates[i], self, Vector3(-size.x * 0.5 + 0.9 + i * (size.x - 1.8) / 4.0, 0, front + 0.25), Vector3(-10, 0, 0), 0.42)
	# The chalkboard menu: an A-frame beside the stall.
	var board := Node3D.new()
	board.name = "ChalkboardMenu"
	board.position = Vector3(size.x * 0.5 + 0.9, 0, front + 0.6)
	add_child(board)
	for side in [-1.0, 1.0]:
		var panel := LowPoly.box(board, Vector3(0.8, 1.1, 0.04), Color(0.12, 0.16, 0.14), Vector3(0, 0.55, side * 0.18))
		panel.rotation.x = side * 0.18
		LowPoly.box(board, Vector3(0.9, 0.05, 0.06), DARK_WOOD, Vector3(0, 1.1, side * 0.1))
	var words := SignText.make_label("القائمة · Menu\nFarm juice  12 Dh\nSalad box  18 Dh\nDates  10 Dh", 18, Color(0.96, 0.95, 0.9), Color(0, 0, 0, 0), 0)
	words.position = Vector3(0, 0.62, 0.25)
	words.rotation.x = -0.18
	board.add_child(words)
	LowPoly.solid_box(self, Vector3(0.9, 1.2, 0.5), board.position + Vector3(0, 0.6, 0))


## Session 69: two rows of honey jars with wooden lids, and wax candles at the front.
func _honey_counter(size: Vector3, front: float) -> void:
	for i in 7:
		var x := -size.x * 0.5 + 0.7 + i * (size.x - 1.4) / 6.0
		for row in 2:
			var z := front - 0.6 + row * 0.35
			LowPoly.cylinder(self, 0.1, 0.1, 0.22, HONEY, Vector3(x, 1.19, z))
			LowPoly.cylinder(self, 0.105, 0.105, 0.04, DARK_WOOD, Vector3(x, 1.32, z))  # lid
	for i in 6:
		var x := -1.0 + i * 0.4
		LowPoly.cylinder(self, 0.06, 0.06, 0.3 + (i % 3) * 0.08, WAX, Vector3(x, 1.25 + (i % 3) * 0.04, front - 0.12))


## A striped roof, tilted down to the front, and the sign board on top.
func _roof_and_sign(english: String, arabic: String, colour: Color, size: Vector3) -> void:
	var stripe := size.x / ROOF_STRIPES
	for i in ROOF_STRIPES:
		var part := LowPoly.box(self, Vector3(stripe, 0.1, size.z + 0.8), colour if i % 2 == 0 else WHITE,
				Vector3(-size.x * 0.5 + stripe * (i + 0.5), size.y - 0.15, 0.2))
		part.rotation.x = deg_to_rad(8.0)
	# The sign board on top of the roof, facing the path.
	var board_y := size.y + BOARD_HEIGHT * 0.5 + 0.05
	LowPoly.box(self, Vector3(size.x - 0.6, BOARD_HEIGHT, 0.12), colour, Vector3(0, board_y, -0.4))
	var font_size := SignText.fit_size(arabic, english, BOARD_FONT_SIZE, size.x - 1.2)
	var face := SignText.make_face(arabic, english, font_size, TEXT_COLOUR)
	face.name = "Sign"
	face.position = Vector3(0, board_y, -0.4 + 0.07)
	add_child(face)
