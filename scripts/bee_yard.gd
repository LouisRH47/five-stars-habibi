class_name BeeYard
extends RefCounted
## Session 63: the beehives (BEEHIVES in the data), the way Louis asked: 8 hives on stands in
## two rows, a low wooden fence round them with a closed gate, flower beds round the fence, a
## bilingual "Bees at work · نحل يعمل" sign and a few bees buzzing about. Every hive's lid is
## its own node (group "hive_lid") so the beekeeper (scripts/beekeeper.gd) can lift it.
## The fence is solid (you can't ride in among the bees); the flower beds are flat.

const HIVE := Color(0.98, 0.86, 0.42, 1)
const HIVE_LOW := Color(0.95, 0.78, 0.3, 1)
const LID := Color(0.95, 0.95, 0.92, 1)
const FENCE := Color(0.6, 0.44, 0.28, 1)
const BED := Color(0.32, 0.22, 0.15, 1)
const FLOWERS := ["quaternius_nature/Flowers", "quaternius_crops/Flower_4", "quaternius_crops/Flower_3",
		"quaternius_crops/Flower_2"]
const BED_WIDTH := 1.0
const GATE := 1.4


## Where the hives stand (2 rows of 4) inside the area.
static func hive_spots(area: Rect2) -> Array:
	var out: Array = []
	for row in 2:
		for i in 4:
			out.append(Vector3(area.position.x + 2.5 + i * (area.size.x - 5.0) / 3.0, 0,
					area.position.y + 2.0 + row * (area.size.y - 4.0)))
	return out


## The aisle between the two rows, where the beekeeper walks (z).
static func aisle(area: Rect2) -> float:
	return area.get_center().y


static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var area: Rect2 = map["BEEHIVES"]
	var holder := Node3D.new()
	holder.name = "BeeYard"
	parent.add_child(holder)
	var kit := MeshKit.new()
	for spot: Vector3 in hive_spots(area):
		var i := holder.get_child_count()
		# The stand, two boxes (a brood box and a honey box) and a white lid (its own node).
		for x in [-0.25, 0.25]:
			for z in [-0.2, 0.2]:
				kit.box(Vector3(0.07, 0.4, 0.07), FENCE.darkened(0.2), spot + Vector3(x, 0.2, z))
		kit.box(Vector3(0.7, 0.06, 0.6), FENCE.darkened(0.2), spot + Vector3(0, 0.43, 0))
		kit.box(Vector3(0.62, 0.42, 0.52), HIVE_LOW, spot + Vector3(0, 0.67, 0))
		kit.box(Vector3(0.62, 0.3, 0.52), HIVE, spot + Vector3(0, 1.03, 0))
		kit.box(Vector3(0.22, 0.03, 0.05), Color(0.2, 0.15, 0.1), spot + Vector3(0, 0.5, 0.27 if spot.z < area.get_center().y else -0.27))  # the entrance
		var lid := Node3D.new()
		lid.name = "HiveLid_%d" % i
		lid.position = spot + Vector3(0, 1.18, 0)
		lid.add_to_group("hive_lid")
		lid.set_meta("static_batch_dynamic", true)
		holder.add_child(lid)
		LowPoly.box(lid, Vector3(0.72, 0.1, 0.62), LID, Vector3.ZERO)
		LowPoly.box(lid, Vector3(0.6, 0.04, 0.5), LID.darkened(0.08), Vector3(0, 0.07, 0))
	holder.add_child(kit.finish("Hives"))
	_fence(holder, area)
	_flower_beds(holder, area)
	_sign(holder, area)
	holder.add_child(_bees(area))
	return holder


## A low wooden fence round the hives, with a closed gate in the middle of the north side.
static func _fence(parent: Node3D, area: Rect2) -> void:
	var a := area.position
	var b := Vector2(area.end.x, area.position.y)
	var c := area.end
	var d := Vector2(area.position.x, area.end.y)
	var gate_a := Vector2(area.get_center().x - GATE * 0.5, a.y)
	var gate_b := Vector2(area.get_center().x + GATE * 0.5, a.y)
	for side in [[a, gate_a], [gate_b, b], [b, c], [c, d], [d, a]]:
		Props.fence(parent, side[0], side[1], 1.0, FENCE)
	var gate := Props.fence(parent, gate_a, gate_b, 1.0, FENCE.lightened(0.25))
	gate.name = "BeeGate"


## Flower beds all round the outside of the fence (bees need flowers).
static func _flower_beds(parent: Node3D, area: Rect2) -> void:
	var outer := area.grow(BED_WIDTH + 0.2)
	var kit := MeshKit.new()
	var spots: Array = []
	for side in 4:
		var strip: Rect2
		match side:
			0: strip = Rect2(outer.position.x, outer.position.y, outer.size.x, BED_WIDTH)
			1: strip = Rect2(outer.position.x, outer.end.y - BED_WIDTH, outer.size.x, BED_WIDTH)
			2: strip = Rect2(outer.position.x, outer.position.y + BED_WIDTH, BED_WIDTH, outer.size.y - BED_WIDTH * 2.0)
			_: strip = Rect2(outer.end.x - BED_WIDTH, outer.position.y + BED_WIDTH, BED_WIDTH, outer.size.y - BED_WIDTH * 2.0)
		kit.box(Vector3(strip.size.x, 0.05, strip.size.y), BED, Vector3(strip.get_center().x, 0.025, strip.get_center().y))
		var step := 0.55
		var along := strip.size.x > strip.size.y
		var length := strip.size.x if along else strip.size.y
		var t := 0.3
		while t < length - 0.2:
			for lane in [-0.22, 0.22]:
				var p := strip.position + (Vector2(t, BED_WIDTH * 0.5 + lane) if along else Vector2(BED_WIDTH * 0.5 + lane, t))
				var at_gate: bool = side == 0 and absf(p.x - area.get_center().x) < GATE * 0.5 + 0.3
				if not at_gate:
					spots.append(Vector3(p.x, 0.05, p.y))
			t += step
	# A gap in the north bed in front of the gate, paved.
	# (1 cm higher than the bed and starting 1 cm in from its edge, so no faces line up and flicker.)
	kit.box(Vector3(GATE + 0.6, 0.05, BED_WIDTH + 0.19), Color(0.8, 0.76, 0.68), Vector3(area.get_center().x, 0.035, outer.position.y + BED_WIDTH * 0.5 + 0.105))
	parent.add_child(kit.finish("FlowerBeds"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 363
	var plants := Node3D.new()
	plants.name = "BeeFlowers"
	parent.add_child(plants)
	SpinePlanting._scatter(plants, spots, FLOWERS, {"quaternius_nature/Flowers": 1.3, "quaternius_crops/Flower_4": 1.2, "quaternius_crops/Flower_3": 1.2, "quaternius_crops/Flower_2": 1.3}, rng)


## The bilingual sign by the gate, facing the buggy road (north).
static func _sign(parent: Node3D, area: Rect2) -> void:
	var board := StaticBody3D.new()
	board.name = "BeeSign"
	board.position = Vector3(area.get_center().x + GATE * 0.5 + 1.6, 0, area.position.y - BED_WIDTH - 0.75)
	board.rotation.y = PI   # reads from the north
	parent.add_child(board)
	for x in [-1.0, 1.0]:   # two posts at the ends, behind the board, so they don't cover the words
		LowPoly.box(board, Vector3(0.09, 1.85, 0.09), FENCE.darkened(0.2), Vector3(x, 0.925, -0.08))
		LowPoly.solid_box(board, Vector3(0.18, 1.85, 0.18), Vector3(x, 0.925, -0.08))
	LowPoly.box(board, Vector3(1.9, 0.75, 0.06), Color(0.98, 0.84, 0.3), Vector3(0, 1.5, 0))
	var size := SignText.fit_size("نحل يعمل", "Bees at work", 40, 1.7)
	var faces := SignText.make_two_faces("نحل يعمل", "Bees at work", size, Color(0.2, 0.14, 0.05), 0.06)
	faces.position.y = 1.5
	board.add_child(faces)


## A few bees flying round the hives (little yellow and black dots).
static func _bees(area: Rect2) -> CPUParticles3D:
	var bees := CPUParticles3D.new()
	bees.name = "Bees"
	bees.position = Vector3(area.get_center().x, 1.2, area.get_center().y)
	bees.amount = 36
	bees.lifetime = 4.0
	bees.preprocess = 4.0
	bees.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bees.emission_box_extents = Vector3(area.size.x * 0.5 + 1.0, 0.6, area.size.y * 0.5 + 1.0)
	bees.direction = Vector3(1, 0.2, 0)
	bees.spread = 180.0
	bees.gravity = Vector3.ZERO
	bees.initial_velocity_min = 0.3
	bees.initial_velocity_max = 1.0
	bees.angular_velocity_min = -200.0
	bees.angular_velocity_max = 200.0
	var dot := SphereMesh.new()
	dot.radius = 0.03
	dot.height = 0.045
	dot.radial_segments = 6
	dot.rings = 3
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.95, 0.75, 0.1)
	dot.material = paint
	bees.mesh = dot
	bees.visibility_range_end = 60.0
	return bees
