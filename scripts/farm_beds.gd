class_name FarmBeds
extends RefCounted
## Session 63: farm beds that look like a real farm (Louis: "make the watermelons and pumpkins
## more detailed"). Each FARM_BEDS area gets 3 raised beds with wooden sides and dark soil,
## with bark paths between them. The rows: watermelon vines with striped melons lying by
## them, pumpkin vines with orange pumpkins, and tomato plants tied to sticks, at mixed growth
## stages (Quaternius Ultimate Crops, CC0). A black drip pipe runs along every row. Each farm
## has a wheelbarrow, a watering can and a scarecrow. The farmer who walks the rows is made
## by LifeBuilder (scripts/beekeeper.gd, the "farmer" job).
## Flat and not solid, like the old beds: the bike can roll over them.
## The browser version has no model packs: then the crops are simple shapes made here.

const WOOD := Color(0.55, 0.38, 0.22, 1)
const WOOD_DARK := Color(0.42, 0.28, 0.16, 1)
const SOIL := Color(0.3, 0.2, 0.13, 1)
const BARK := Color(0.52, 0.4, 0.28, 1)
const PIPE := Color(0.08, 0.08, 0.09, 1)
const STAKE := Color(0.62, 0.5, 0.32, 1)
const ROWS := 3
const BED_DEPTH := 1.6
const MARGIN := 0.4      # from the area's edge to the first bed
## The crops in each row, for each farm (they take turns, so the farms look different).
const PLAN := [["melon", "pumpkin", "tomato"], ["tomato", "melon", "pumpkin"], ["pumpkin", "tomato", "melon"]]
## Plant models by growth stage, and the fruit that lies next to the vines.
const STAGES := {"melon": ["quaternius_crops/Watermelon_2", "quaternius_crops/Watermelon_3", "quaternius_crops/Watermelon_4", "quaternius_crops/Watermelon_4"],
		"pumpkin": ["quaternius_crops/Pumpkin_2", "quaternius_crops/Pumpkin_3", "quaternius_crops/Pumpkin_4", "quaternius_crops/Pumpkin_4"],
		"tomato": ["quaternius_crops/Tomato_3", "quaternius_crops/Tomato_4", "quaternius_crops/Tomato_4"]}
const FRUIT := {"melon": "quaternius_crops/Watermelon_Crop", "pumpkin": "quaternius_crops/Pumpkin_Crop"}


## Where the middle of each raised bed is, across the area (z), and the paths between (z).
static func bed_lines(area: Rect2) -> Array:
	var out: Array = []
	for row in ROWS:
		out.append(area.position.y + MARGIN + BED_DEPTH * 0.5 + row * (BED_DEPTH + walkway(area)))
	return out


static func walk_lines(area: Rect2) -> Array:
	var beds := bed_lines(area)
	var out: Array = []
	for i in beds.size() - 1:
		out.append((beds[i] + beds[i + 1]) * 0.5)
	return out


## The path between two beds (metres).
static func walkway(area: Rect2) -> float:
	return (area.size.y - MARGIN * 2.0 - BED_DEPTH * ROWS) / float(ROWS - 1)


## Builds every farm. Returns {"plants": count, "props": [...]} for the tests.
static func build(parent: Node3D, map: Dictionary) -> Dictionary:
	var holder := Node3D.new()
	holder.name = "FarmBeds"
	parent.add_child(holder)
	var report := {"plants": 0, "fruit": 0, "beds": 0, "areas": []}
	var rng := RandomNumberGenerator.new()
	rng.seed = 6331
	for f in map["FARM_BEDS"].size():
		var area: Rect2 = map["FARM_BEDS"][f]
		var farm := Node3D.new()
		farm.name = "Farm_%d" % f
		holder.add_child(farm)
		var x0 := area.position.x + 0.5
		var x1 := area.end.x - 0.5
		var kit := MeshKit.new()
		# Bark paths between the beds (under everything).
		for z: float in walk_lines(area):
			kit.box(Vector3(x1 - x0, 0.02, walkway(area)), BARK, Vector3((x0 + x1) * 0.5, 0.016, z))
		var scarecrow := Vector3((x0 + x1) * 0.5, 0, bed_lines(area)[1])
		var groups := {}
		for row in ROWS:
			var z: float = bed_lines(area)[row]
			_bed_frame(kit, x0, x1, z)
			report["beds"] += 1
			var crop: String = PLAN[f % PLAN.size()][row]
			var x := x0 + 0.55
			var i := 0
			while x < x1 - 0.4:
				if Vector2(x - scarecrow.x, z - scarecrow.z).length() > 0.9:
					var stages: Array = STAGES[crop]
					var id: String = stages[rng.randi() % stages.size()]
					var spot := Vector3(x, GameConfig.FARM_BED_HEIGHT - 0.04, z + rng.randf_range(-0.12, 0.12))
					_add(groups, id, spot, rng.randf() * 360.0)
					report["plants"] += 1
					if crop == "tomato":
						kit.cylinder(0.018, 0.022, 1.25, STAKE, Vector3(x + 0.12, GameConfig.FARM_BED_HEIGHT + 0.55, z - 0.18))
					elif FRUIT.has(crop) and rng.randf() < 0.75:
						var side := 0.42 if i % 2 == 0 else -0.42
						_add(groups, FRUIT[crop], Vector3(x + 0.3, GameConfig.FARM_BED_HEIGHT - 0.02, z + side), rng.randf() * 360.0)
						report["fruit"] += 1
				x += GameConfig.FARM_PLANT_SPACING
				i += 1
			# The drip pipe along the row, with a little dripper at every plant.
			kit.box(Vector3(x1 - x0 - 0.3, 0.025, 0.025), PIPE, Vector3((x0 + x1) * 0.5, GameConfig.FARM_BED_HEIGHT - 0.025, z + 0.3))
			kit.box(Vector3(0.025, 0.03, 0.6), PIPE, Vector3(x0 + 0.1, GameConfig.FARM_BED_HEIGHT - 0.02, z + 0.55))
		var view := kit.finish("BedFrames")
		farm.add_child(view)
		for id: String in groups:
			if SpinePlanting.has_kit(id):
				KitProps.place_many(farm, id, groups[id][0], groups[id][1], GameConfig.FARM_CROP_SCALE)
			else:
				_plain_crops(farm, id, groups[id][0])
		_scarecrow(farm, scarecrow + Vector3(0, GameConfig.FARM_BED_HEIGHT - 0.04, 0), f)
		var lanes := walk_lines(area)
		_wheelbarrow(farm, Vector3(area.position.x + 1.1, 0.02, lanes[0]), 90.0 + f * 20.0)
		_watering_can(farm, Vector3(area.end.x - 0.9, 0.02, lanes[lanes.size() - 1] + 0.2), f * 50.0)
		report["areas"].append(area)
	holder.set_meta("report", report)
	return report


static func _add(groups: Dictionary, id: String, spot: Vector3, turn: float) -> void:
	if not groups.has(id):
		groups[id] = [[], []]
	groups[id][0].append(spot)
	groups[id][1].append(turn)


## One raised bed: four wooden sides, corner posts and the soil on top.
static func _bed_frame(kit: MeshKit, x0: float, x1: float, z: float) -> void:
	var h := GameConfig.FARM_BED_HEIGHT
	var half := BED_DEPTH * 0.5
	kit.box(Vector3(x1 - x0 - 0.12, h - 0.05, BED_DEPTH - 0.12), SOIL, Vector3((x0 + x1) * 0.5, (h - 0.05) * 0.5, z))
	for side in [-1.0, 1.0]:
		kit.box(Vector3(x1 - x0, h, 0.06), WOOD, Vector3((x0 + x1) * 0.5, h * 0.5, z + side * (half - 0.03)))
		kit.box(Vector3(0.06, h, BED_DEPTH - 0.12), WOOD, Vector3((x0 + x1) * 0.5 + side * ((x1 - x0) * 0.5 - 0.03), h * 0.5, z))
		for end in [x0 + 0.04, x1 - 0.04]:
			kit.box(Vector3(0.09, h + 0.06, 0.09), WOOD_DARK, Vector3(end, (h + 0.06) * 0.5, z + side * (half - 0.04)))
	# A plank line along each long side, so they look like boards.
	for side in [-1.0, 1.0]:
		kit.box(Vector3(x1 - x0, 0.015, 0.065), WOOD_DARK, Vector3((x0 + x1) * 0.5, h * 0.5, z + side * (half - 0.03)))


## Stand-in crops from simple shapes (the browser version has no model packs).
static func _plain_crops(parent: Node3D, id: String, spots: Array) -> void:
	var kit := MeshKit.new()
	if id.contains("Watermelon_Crop"):
		kit.ball(0.17, Color(0.2, 0.45, 0.18), Vector3(0, 0.12, 0), 0.75)
		for i in 3:
			kit.box(Vector3(0.36, 0.2, 0.025), Color(0.12, 0.3, 0.12), Vector3(0, 0.12, -0.1 + i * 0.1))
	elif id.contains("Pumpkin_Crop"):
		kit.ball(0.2, Color(0.95, 0.5, 0.12), Vector3(0, 0.14, 0), 0.7)
		kit.cylinder(0.025, 0.03, 0.08, Color(0.35, 0.3, 0.12), Vector3(0, 0.31, 0))
	elif id.contains("Tomato"):
		kit.cylinder(0.12, 0.2, 0.8, Color(0.25, 0.5, 0.2), Vector3(0, 0.4, 0))
		for i in 4:
			kit.ball(0.05, Color(0.88, 0.15, 0.1), Vector3(cos(i * 1.7) * 0.15, 0.3 + i * 0.12, sin(i * 1.7) * 0.15))
	else:
		kit.ball(0.32, Color(0.3, 0.55, 0.22), Vector3(0, 0.12, 0), 0.45)
		kit.ball(0.22, Color(0.36, 0.62, 0.26), Vector3(0.2, 0.15, 0.1), 0.45)
	var view := kit.finish()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = view.mesh
	many.instance_count = spots.size()
	for i in spots.size():
		many.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(i) * 2.1), spots[i]))
	view.free()
	var drawn := MultiMeshInstance3D.new()
	drawn.name = "Plain_" + id.get_file()
	drawn.multimesh = many
	drawn.material_override = MeshKit.material()
	parent.add_child(drawn)


## A scarecrow: a pole and arms, a checked shirt, a sack head and a straw hat.
static func _scarecrow(parent: Node3D, spot: Vector3, variant: int) -> void:
	var kit := MeshKit.new()
	var shirt: Color = [Color(0.75, 0.2, 0.18), Color(0.25, 0.4, 0.7), Color(0.85, 0.65, 0.2)][variant % 3]
	kit.box(Vector3(0.07, 1.9, 0.07), STAKE, Vector3(0, 0.95, 0))
	kit.box(Vector3(1.3, 0.06, 0.06), STAKE, Vector3(0, 1.45, 0))
	kit.box(Vector3(0.5, 0.6, 0.25), shirt, Vector3(0, 1.3, 0))
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.42, 0.14, 0.16), shirt, Vector3(side * 0.42, 1.45, 0))
		kit.box(Vector3(0.08, 0.16, 0.08), Color(0.9, 0.78, 0.4), Vector3(side * 0.66, 1.42, 0))   # straw hands
	kit.box(Vector3(0.38, 0.35, 0.22), Color(0.4, 0.3, 0.6), Vector3(0, 0.88, 0))   # trousers
	kit.ball(0.17, Color(0.85, 0.72, 0.5), Vector3(0, 1.78, 0))                       # sack head
	kit.cylinder(0.33, 0.33, 0.03, Color(0.9, 0.8, 0.45), Vector3(0, 1.9, 0))       # hat brim
	kit.cylinder(0.13, 0.16, 0.18, Color(0.9, 0.8, 0.45), Vector3(0, 1.99, 0))      # hat top
	var view := kit.finish("Scarecrow")
	view.position = spot
	view.rotation.y = 0.3 * variant
	parent.add_child(view)


## A green wheelbarrow with a wheel at the front and two handles.
static func _wheelbarrow(parent: Node3D, spot: Vector3, facing: float) -> void:
	var kit := MeshKit.new()
	var green := Color(0.2, 0.5, 0.3)
	kit.box(Vector3(0.6, 0.06, 0.8), green, Vector3(0, 0.45, 0))
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.05, 0.28, 0.8), green, Vector3(side * 0.3, 0.6, 0))
		kit.box(Vector3(0.04, 0.04, 1.3), WOOD_DARK, Vector3(side * 0.22, 0.42, 0.35))          # handles
		kit.box(Vector3(0.04, 0.4, 0.04), PIPE, Vector3(side * 0.22, 0.2, 0.3))                 # legs
	kit.box(Vector3(0.6, 0.28, 0.05), green, Vector3(0, 0.6, -0.38))
	kit.box(Vector3(0.6, 0.28, 0.05), green, Vector3(0, 0.6, 0.38))
	kit.cylinder(0.2, 0.2, 0.08, PIPE, Vector3(0, 0.2, -0.55), Basis(Vector3.BACK, PI * 0.5), 10)   # wheel
	kit.ball(0.22, SOIL, Vector3(0, 0.62, 0), 0.4)                                            # a load of soil
	var view := kit.finish("Wheelbarrow")
	view.position = spot
	view.rotation_degrees.y = facing
	parent.add_child(view)


## A metal watering can with a long spout.
static func _watering_can(parent: Node3D, spot: Vector3, facing: float) -> void:
	var view := watering_can_mesh()
	view.position = spot
	view.rotation_degrees.y = facing
	parent.add_child(view)


static func watering_can_mesh() -> MeshInstance3D:
	var kit := MeshKit.new()
	var metal := Color(0.4, 0.62, 0.55)
	kit.cylinder(0.13, 0.14, 0.3, metal, Vector3(0, 0.15, 0), Basis(), 10)
	kit.cylinder(0.02, 0.03, 0.4, metal, Vector3(0, 0.25, -0.25), Basis(Vector3.RIGHT, -0.9))
	kit.cylinder(0.05, 0.03, 0.05, metal, Vector3(0, 0.38, -0.42), Basis(Vector3.RIGHT, -0.9))
	kit.box(Vector3(0.03, 0.03, 0.28), metal.darkened(0.2), Vector3(0, 0.36, 0.02))
	return kit.finish("WateringCan")
