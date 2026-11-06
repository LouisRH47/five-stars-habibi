class_name MajlisGardens
extends Node3D
## Session 66: Majlis Gardens, the little park between the C1-west car park and Cluster 1
## (data: MAJLIS_GARDENS). A fountain on a round paved plaza, palms for shade, a shaded
## majlis (a sitting area with low sofas and a coffee table), benches, a community garden
## bed, low hedges and curving paver paths that join the cluster's lanes, the car park and
## the spine loop road. The people here (sitting, walking, gardening) come from PlaceCrowds.
## Session 90: the south path ends square on the spine loop road's edge, and a zebra crossing
## (ZEBRA_CROSSINGS, painted by RoadMesh) takes you over the road to the spine (no kerb at
## either end). Made by DistrictDetail.

const PAVERS := Color(0.86, 0.8, 0.69)
const PLAZA := Color(0.9, 0.85, 0.75)
const STONE := Color(0.93, 0.9, 0.83)
const WATER := Color(0.25, 0.6, 0.82)
const HEDGE := Color(0.24, 0.46, 0.2)
const WOOD := Color(0.55, 0.38, 0.22)
const SOIL := Color(0.35, 0.24, 0.15)
const LEAF := Color(0.3, 0.6, 0.25)
const CLOTH := Color(0.94, 0.9, 0.8)
const CUSHION := Color(0.62, 0.18, 0.2)
const PATH_TOP := 0.04    # paver paths (cluster paving is 0.022, the car park pad 0.03)
const PLAZA_TOP := 0.046  # the round plaza sits just over the paths that meet it
const PALM_SCENE := preload("res://scenes/palm_tree.tscn")

## What was built (for the tests).
var path_length := 0.0
var benches := 0
var palms := 0


static func build(parent: Node3D, map: Dictionary) -> MajlisGardens:
	var park := MajlisGardens.new()
	park.name = "MajlisGardens"
	parent.add_child(park)
	var spec: Dictionary = map.get("MAJLIS_GARDENS", {})
	if spec.is_empty():
		return park
	park._paths(spec)
	park._fountain(spec)
	park._hedges(spec)
	park._majlis(spec["majlis"])
	park._garden_bed(spec["bed"])
	for bench: Dictionary in spec["benches"]:
		Props.bench(park, bench["position"], bench["facing"])
		park.benches += 1
	for spot: Vector3 in spec["palms"]:
		var palm: Node3D = PALM_SCENE.instantiate()
		palm.name = "MajlisPalm_%d" % park.palms
		palm.position = spot
		palm.setup(park.palms + 3)
		park.add_child(palm)
		park.palms += 1
	park._sign(spec)
	return park


## The curving paver paths: one smooth strip mesh per path.
func _paths(spec: Dictionary) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = spec["path_width"] * 0.5
	for path: Array in spec["paths"]:
		for k in path.size() - 1:
			var a: Vector2 = path[k]
			var b: Vector2 = path[k + 1]
			path_length += a.distance_to(b)
		var sides: Array[Vector2] = []
		for k in path.size():
			var before: Vector2 = path[maxi(k - 1, 0)]
			var after: Vector2 = path[mini(k + 1, path.size() - 1)]
			var way := (after - before).normalized()
			sides.append(Vector2(-way.y, way.x) * half)
		for k in path.size() - 1:
			var p0: Vector2 = path[k]
			var p1: Vector2 = path[k + 1]
			var corners := [p0 - sides[k], p0 + sides[k], p1 + sides[k + 1], p1 - sides[k + 1]]
			for i in [0, 1, 2, 0, 2, 3]:
				var c: Vector2 = corners[i]
				tool.set_color(PAVERS)
				tool.set_normal(Vector3.UP)
				tool.add_vertex(Vector3(c.x, PATH_TOP, c.y))
	var view := MeshInstance3D.new()
	view.name = "MajlisPaths"
	view.mesh = tool.commit()
	view.material_override = _two_sided()  # seen from above whichever way a piece was wound
	add_child(view)


static var _path_material: StandardMaterial3D = null


func _two_sided() -> StandardMaterial3D:
	if _path_material == null:
		_path_material = StandardMaterial3D.new()
		_path_material.vertex_color_use_as_albedo = true
		_path_material.vertex_color_is_srgb = true
		_path_material.roughness = 0.95
		_path_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _path_material


## The fountain on its round paved plaza: a stone basin with water, a pedestal, a bowl
## and little jets. Solid, so you ride round it.
func _fountain(spec: Dictionary) -> void:
	var at: Vector3 = spec["fountain"]
	var body := StaticBody3D.new()
	body.name = "MajlisFountain"
	body.position = at
	add_child(body)
	var kit := MeshKit.new()
	var r: float = spec["plaza_radius"]
	kit.cylinder(r, r, 0.03, PLAZA, Vector3(0, PLAZA_TOP - 0.015, 0), Basis(), 28)
	kit.cylinder(r + 0.25, r + 0.25, 0.02, STONE.darkened(0.15), Vector3(0, PLAZA_TOP - 0.02, 0), Basis(), 28)
	kit.cylinder(2.8, 2.9, 0.55, STONE, Vector3(0, 0.275, 0), Basis(), 20)
	kit.cylinder(2.5, 2.5, 0.04, WATER, Vector3(0, 0.5, 0), Basis(), 20)
	kit.cylinder(0.35, 0.45, 1.3, STONE, Vector3(0, 0.95, 0), Basis(), 10)
	kit.cylinder(1.05, 0.5, 0.3, STONE, Vector3(0, 1.65, 0), Basis(), 14)
	kit.cylinder(0.9, 0.9, 0.04, WATER, Vector3(0, 1.79, 0), Basis(), 14)
	kit.cylinder(0.1, 0.18, 0.5, STONE, Vector3(0, 2.05, 0), Basis(), 8)
	kit.ball(0.16, STONE, Vector3(0, 2.38, 0))
	for k in 6:  # little jets falling from the bowl into the basin
		var a := TAU * k / 6.0
		kit.cylinder(0.04, 0.07, 1.25, WATER.lightened(0.45), Vector3(cos(a) * 1.15, 1.15, sin(a) * 1.15), Basis(), 6)
	body.add_child(kit.finish("Fountain"))
	LowPoly.solid_cylinder(body, 2.9, 0.8, Vector3(0, 0.4, 0))


## Low clipped hedges along both long sides, with gaps where the paths go through.
func _hedges(spec: Dictionary) -> void:
	var area: Rect2 = spec["area"]
	var gaps := {area.position.x: [], area.end.x: []}
	for path: Array in spec["paths"]:
		var end: Vector2 = path[-1]
		for x in gaps:
			if absf(end.x - x) < 5.0:  # this path leaves the park here: where does it cross?
				var cross: Vector2 = end
				for point: Vector2 in path:
					if absf(point.x - x) < absf(cross.x - x):
						cross = point
				gaps[x].append(cross.y)
	var body := StaticBody3D.new()
	body.name = "MajlisHedges"
	add_child(body)
	var kit := MeshKit.new()
	for x: float in gaps:
		var side := -0.5 if x == area.position.x else 0.5
		var z := area.position.y + 2.0
		while z < area.end.y - 1.0:
			var stop := area.end.y - 1.0
			for g: float in gaps[x]:
				if g > z:
					stop = minf(stop, g - 2.6)
			if stop - z > 0.5:
				var middle := Vector3(x - side, 0.4, (z + stop) * 0.5)
				kit.box(Vector3(0.8, 0.8, stop - z), HEDGE, middle)
				LowPoly.solid_box(body, Vector3(0.8, 0.8, stop - z), middle)
			z = stop + 5.2
	body.add_child(kit.finish("Hedges"))


## The majlis: a fabric shade on wooden posts over low sofas, cushions, a rug and a
## coffee table with a dallah (coffee pot) and little cups.
func _majlis(at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "MajlisShade"
	body.position = at
	add_child(body)
	var kit := MeshKit.new()
	var size := Vector2(6.0, 5.0)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var post := Vector3(x * (size.x * 0.5 - 0.15), 1.4, z * (size.y * 0.5 - 0.15))
			kit.box(Vector3(0.16, 2.8, 0.16), WOOD, post)
			LowPoly.solid_box(body, Vector3(0.18, 2.8, 0.18), post)
	for z in [-1.0, 1.0]:
		kit.box(Vector3(size.x, 0.14, 0.14), WOOD, Vector3(0, 2.85, z * (size.y * 0.5 - 0.15)))
	for x in [-1.0, 1.0]:
		kit.box(Vector3(0.14, 0.14, size.y), WOOD, Vector3(x * (size.x * 0.5 - 0.15), 2.85, 0))
	kit.box(Vector3(size.x + 0.4, 0.06, size.y + 0.4), CLOTH, Vector3(0, 3.0, 0))
	for x in [-1.0, 1.0]:  # scalloped cloth edges
		kit.box(Vector3(0.04, 0.35, size.y + 0.4), CLOTH.darkened(0.08), Vector3(x * (size.x * 0.5 + 0.2), 2.82, 0))
	kit.box(Vector3(3.6, 0.015, 2.6), Color(0.6, 0.2, 0.18), Vector3(0.3, 0.06, 0))  # the rug
	kit.box(Vector3(3.2, 0.016, 2.2), Color(0.85, 0.65, 0.3), Vector3(0.3, 0.065, 0))
	# Low sofas: one along the west side (facing east) and one along the north (facing south).
	kit.box(Vector3(0.8, 0.4, 4.0), CLOTH.darkened(0.1), Vector3(-2.3, 0.2, 0.1))
	kit.box(Vector3(0.25, 0.75, 4.0), CUSHION, Vector3(-2.6, 0.45, 0.1))
	kit.box(Vector3(4.0, 0.4, 0.8), CLOTH.darkened(0.1), Vector3(0.6, 0.2, -1.8))
	kit.box(Vector3(4.0, 0.75, 0.25), CUSHION, Vector3(0.6, 0.45, -2.1))
	for k in 3:
		kit.box(Vector3(0.45, 0.35, 0.18), [CUSHION.lightened(0.2), Color(0.2, 0.4, 0.5), Color(0.85, 0.7, 0.3)][k], Vector3(-2.35, 0.55, -1.1 + k * 1.2))
	LowPoly.solid_box(body, Vector3(0.9, 0.6, 4.0), Vector3(-2.35, 0.3, 0.1))
	LowPoly.solid_box(body, Vector3(4.0, 0.6, 0.9), Vector3(0.6, 0.3, -1.85))
	# The coffee table, a dallah and cups.
	kit.box(Vector3(1.2, 0.08, 0.8), WOOD.darkened(0.2), Vector3(0.2, 0.36, 0.1))
	for x in [-0.5, 0.5]:
		for z in [-0.3, 0.3]:
			kit.box(Vector3(0.06, 0.32, 0.06), WOOD.darkened(0.3), Vector3(0.2 + x, 0.16, 0.1 + z))
	var pot := Vector3(0.0, 0.4, 0.1)
	kit.cylinder(0.07, 0.11, 0.2, Color(0.85, 0.7, 0.3), pot + Vector3(0, 0.1, 0), Basis(), 10)
	kit.cylinder(0.0, 0.07, 0.12, Color(0.85, 0.7, 0.3), pot + Vector3(0, 0.26, 0), Basis(), 10)
	kit.box(Vector3(0.16, 0.03, 0.03), Color(0.85, 0.7, 0.3), pot + Vector3(0.13, 0.17, 0), Basis(Vector3.BACK, 0.6))
	for k in 3:
		kit.cylinder(0.03, 0.025, 0.05, Color.WHITE, Vector3(0.4 + k * 0.1, 0.43, 0.25), Basis(), 6)
	body.add_child(kit.finish("Majlis"))


## The community garden bed: a raised wooden bed with rows of vegetables and herbs, a
## watering can, a tap and a little bilingual sign.
func _garden_bed(area: Rect2) -> void:
	var body := StaticBody3D.new()
	body.name = "CommunityGardenBed"
	body.position = Vector3(area.get_center().x, 0, area.get_center().y)
	add_child(body)
	var kit := MeshKit.new()
	var half := area.size * 0.5
	for side in [-1.0, 1.0]:
		kit.box(Vector3(area.size.x, 0.45, 0.12), WOOD, Vector3(0, 0.225, side * (half.y - 0.06)))
		kit.box(Vector3(0.12, 0.45, area.size.y), WOOD, Vector3(side * (half.x - 0.06), 0.225, 0))
	kit.box(Vector3(area.size.x - 0.24, 0.36, area.size.y - 0.24), SOIL, Vector3(0, 0.18, 0))
	var colours := [LEAF, LEAF.darkened(0.15), Color(0.85, 0.2, 0.15), LEAF.lightened(0.15), Color(0.95, 0.75, 0.2)]
	for row in range(4):
		var x := -half.x + 1.3 + row * 2.1
		for k in range(int(area.size.y / 0.9) - 1):
			var z := -half.y + 0.9 + k * 0.9
			kit.ball(0.22 + 0.04 * (k % 2), LEAF.darkened(0.05 * (row % 2)), Vector3(x, 0.5, z), 0.8)
			if row == 1 and k % 2 == 0:  # tomatoes
				kit.ball(0.07, colours[2], Vector3(x + 0.12, 0.58, z + 0.1))
			if row == 3 and k % 3 == 0:  # marigolds
				kit.ball(0.08, colours[4], Vector3(x, 0.7, z))
	kit.cylinder(0.12, 0.14, 0.25, Color(0.2, 0.55, 0.35), Vector3(half.x + 0.5, 0.13, -half.y + 1.0), Basis(), 8)  # watering can
	kit.box(Vector3(0.22, 0.03, 0.03), Color(0.2, 0.55, 0.35), Vector3(half.x + 0.68, 0.24, -half.y + 1.0), Basis(Vector3.BACK, 0.7))
	kit.box(Vector3(0.08, 0.9, 0.08), Color(0.6, 0.62, 0.64), Vector3(half.x + 0.5, 0.45, -half.y + 2.2))  # the tap
	kit.box(Vector3(0.16, 0.05, 0.05), Color(0.6, 0.62, 0.64), Vector3(half.x + 0.56, 0.86, -half.y + 2.2))
	kit.box(Vector3(0.06, 1.0, 0.06), WOOD, Vector3(half.x + 0.5, 0.5, half.y - 1.0))
	kit.box(Vector3(0.06, 0.55, 1.3), Color(0.3, 0.45, 0.25), Vector3(half.x + 0.55, 1.2, half.y - 1.0))
	body.add_child(kit.finish("GardenBed"))
	LowPoly.solid_box(body, Vector3(area.size.x, 0.45, area.size.y), Vector3(0, 0.225, 0))
	var face := SignText.make_face("حديقة المجتمع", "Community garden", 22, Color.WHITE)
	face.name = "GardenSign"
	face.position = Vector3(half.x + 0.59, 1.2, half.y - 1.0)
	face.rotation.y = PI * 0.5
	body.add_child(face)


## The bilingual park sign at the south entrance, facing the spine loop road.
func _sign(spec: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "MajlisGardensSign"
	body.position = spec["sign"]
	body.rotation_degrees.y = spec["sign_facing"]
	add_child(body)
	var kit := MeshKit.new()
	kit.box(Vector3(2.6, 0.9, 0.5), STONE, Vector3(0, 0.45, 0))  # a low stone plinth sign
	kit.box(Vector3(2.4, 0.06, 0.06), Color(0.75, 0.6, 0.3), Vector3(0, 0.82, 0.26))
	body.add_child(kit.finish("Plinth"))
	LowPoly.solid_box(body, Vector3(2.6, 0.9, 0.5), Vector3(0, 0.45, 0))
	var size := SignText.fit_size(spec["arabic"], spec["name"], 40, 2.3)
	var faces := SignText.make_two_faces(spec["arabic"], spec["name"], size, Color(0.2, 0.3, 0.2), 0.5)
	faces.position.y = 0.45
	body.add_child(faces)

