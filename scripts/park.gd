extends Node3D
## Palm Grove Park: flat grass, paving paths, a small fountain in the middle, benches,
## round shade trees and a bilingual sign at the entrance by Ghaf Street.
## The grass and paths are flat (you ride over them); the fountain, benches, tree trunks
## and the sign posts are solid. The park's palms are in the PALM_TREES list with the
## other palms. DecorBuilder places scenes/park.tscn and calls setup().

const GRASS_COLOUR := Color(0.45, 0.65, 0.35, 1)
const PATH_COLOUR := Color(0.88, 0.8, 0.64, 1)
const STONE_COLOUR := Color(0.9, 0.87, 0.8, 1)
const WATER_COLOUR := Color(0.35, 0.7, 0.85, 1)
const WOOD_COLOUR := Color(0.6, 0.4, 0.22, 1)
const METAL_COLOUR := Color(0.25, 0.25, 0.27, 1)
const TRUNK_COLOUR := Color(0.45, 0.33, 0.22, 1)
const LEAF_COLOURS := [Color(0.3, 0.55, 0.25, 1), Color(0.36, 0.6, 0.28, 1)]
const SIGN_COLOUR := Color(0.2, 0.5, 0.25, 1)
const TEXT_COLOUR := Color(1, 1, 1, 1)

const TREE_TRUNK_RADIUS := 0.25
const TREE_SOLID_RADIUS := 0.4
const TREE_TRUNK_HEIGHT := 2.6
const TREE_CROWN_RADIUS := 2.0
const FOUNTAIN_HEIGHT := 0.6
const SIGN_SIZE := Vector3(4.2, 1.3, 0.12)
const SIGN_BOTTOM := 1.0
const SIGN_FONT_SIZE := 72


## Builds the park from the map data (the constants of data/palm_grove.gd).
func setup(map: Dictionary) -> void:
	var park: Dictionary = map["PARK"]
	var area: Rect2 = park["area"]
	_add_flat(area, GRASS_COLOUR, 0.02)
	for path: Rect2 in map["PARK_PATHS"]:
		_add_flat(path, PATH_COLOUR, 0.03)
	var fountain: Vector3 = park["fountain"]
	var fountain_radius: float = map["FOUNTAIN_RADIUS"]
	_build_fountain(fountain, fountain_radius)
	var bench_size: Vector3 = map["BENCH_SIZE"]
	var benches: Array = map["PARK_BENCHES"]
	for i in benches.size():
		var bench: Dictionary = benches[i]
		var spot: Vector3 = bench["position"]
		var facing: float = bench["facing"]
		_build_bench(i, spot, facing, bench_size)
	var trees: Array = map["PARK_TREES"]
	for i in trees.size():
		var spot: Vector3 = trees[i]
		_build_tree(i, spot)
	var sign_spot: Vector3 = park["sign"]
	var sign_facing: float = park["sign_facing"]
	var english: String = park["name"]
	var arabic: String = park["arabic"]
	_build_sign(sign_spot, sign_facing, english, arabic)


## A flat coloured patch on the ground. area: Rect2(x, z, width, depth).
func _add_flat(area: Rect2, colour: Color, thickness: float) -> void:
	var middle := area.get_center()
	LowPoly.box(self, Vector3(area.size.x, thickness, area.size.y), colour,
			Vector3(middle.x, thickness * 0.5, middle.y))


func _build_fountain(spot: Vector3, radius: float) -> void:
	var fountain := StaticBody3D.new()
	fountain.name = "Fountain"
	fountain.position = spot
	add_child(fountain)
	# Solid a bit higher than the stone rim, so the bike hits it like a wall.
	LowPoly.solid_cylinder(fountain, radius, 1.2, Vector3(0, 0.6, 0))
	LowPoly.cylinder(fountain, radius, radius, FOUNTAIN_HEIGHT, STONE_COLOUR,
			Vector3(0, FOUNTAIN_HEIGHT * 0.5, 0))
	LowPoly.cylinder(fountain, radius - 0.3, radius - 0.3, 0.05, WATER_COLOUR,
			Vector3(0, FOUNTAIN_HEIGHT + 0.01, 0))
	LowPoly.cylinder(fountain, 0.3, 0.3, 1.6, STONE_COLOUR, Vector3(0, 0.8, 0))
	LowPoly.cylinder(fountain, 0.9, 0.5, 0.25, STONE_COLOUR, Vector3(0, 1.6, 0))
	LowPoly.sphere(fountain, 0.45, 0.6, WATER_COLOUR, Vector3(0, 1.8, 0))


## A park bench: a wooden seat and back on two dark metal legs. It looks out
## along "facing" (the seat's front is its +Z side). number: for its name, Bench_<number>.
func _build_bench(number: int, spot: Vector3, facing: float, size: Vector3) -> void:
	var bench := StaticBody3D.new()
	bench.name = "Bench_%d" % number
	bench.position = spot
	bench.rotation_degrees.y = facing
	add_child(bench)
	LowPoly.solid_box(bench, Vector3(size.x, 1.0, size.z), Vector3(0, 0.5, 0))
	var seat_y := 0.45
	LowPoly.box(bench, Vector3(size.x, 0.08, size.z * 0.6), WOOD_COLOUR,
			Vector3(0, seat_y, size.z * 0.1))
	LowPoly.box(bench, Vector3(size.x, 0.4, 0.08), WOOD_COLOUR,
			Vector3(0, size.y - 0.2, -size.z * 0.35))
	for x: float in [-size.x * 0.4, size.x * 0.4]:
		LowPoly.box(bench, Vector3(0.08, size.y, 0.08), METAL_COLOUR,
				Vector3(x, size.y * 0.5, -size.z * 0.35))
		LowPoly.box(bench, Vector3(0.08, seat_y, 0.08), METAL_COLOUR,
				Vector3(x, seat_y * 0.5, size.z * 0.3))


## A round shade tree: a trunk with two leafy balls. number: for its name,
## ShadeTree_<number>, and it changes the tree's look a little.
func _build_tree(number: int, spot: Vector3) -> void:
	var tree := StaticBody3D.new()
	tree.name = "ShadeTree_%d" % number
	tree.position = spot
	add_child(tree)
	LowPoly.solid_cylinder(tree, TREE_SOLID_RADIUS, 2.0, Vector3(0, 1.0, 0))
	LowPoly.cylinder(tree, TREE_TRUNK_RADIUS * 0.7, TREE_TRUNK_RADIUS, TREE_TRUNK_HEIGHT,
			TRUNK_COLOUR, Vector3(0, TREE_TRUNK_HEIGHT * 0.5, 0))
	var leaves: Color = LEAF_COLOURS[number % LEAF_COLOURS.size()]
	var crown := TREE_CROWN_RADIUS + float(number % 3) * 0.3
	LowPoly.sphere(tree, crown, crown * 1.6, leaves, Vector3(0, TREE_TRUNK_HEIGHT + crown * 0.6, 0))
	LowPoly.sphere(tree, crown * 0.6, crown * 1.0, leaves,
			Vector3(crown * 0.5, TREE_TRUNK_HEIGHT + crown * 1.2, crown * 0.3))


## The park's entrance sign: a green board on two posts, readable from both sides.
func _build_sign(spot: Vector3, facing: float, english: String, arabic: String) -> void:
	var holder := StaticBody3D.new()
	holder.name = "ParkSign"
	holder.position = spot
	holder.rotation_degrees.y = facing
	add_child(holder)
	var board_y := SIGN_BOTTOM + SIGN_SIZE.y * 0.5
	var post_x := SIGN_SIZE.x * 0.5 - 0.3
	var post_height := SIGN_BOTTOM + SIGN_SIZE.y + 0.1
	for x: float in [-post_x, post_x]:
		LowPoly.cylinder(holder, 0.06, 0.06, post_height, METAL_COLOUR, Vector3(x, post_height * 0.5, 0))
		LowPoly.solid_cylinder(holder, 0.12, post_height, Vector3(x, post_height * 0.5, 0))
	LowPoly.box(holder, SIGN_SIZE, SIGN_COLOUR, Vector3(0, board_y, 0))
	var font_size := SignText.fit_size(arabic, english, SIGN_FONT_SIZE, SIGN_SIZE.x - 0.4)
	var faces := SignText.make_two_faces(arabic, english, font_size, TEXT_COLOUR, SIGN_SIZE.z)
	faces.position.y = board_y
	holder.add_child(faces)
