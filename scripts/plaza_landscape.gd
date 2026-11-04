class_name PlazaLandscape
extends RefCounted
## Session 57: the green round the Plaza instead of a slab of concrete (PRD "Looks pass").
## From PLAZA_LANDSCAPE in data/wahat_al_shams.gd it builds: grass beds with a low stone
## kerb and shrubs and flowers round the edge (the grass blades come from GrassField, which
## finds every lawn by its grass material), benches looking at the beds, square planters
## by the shop terraces, round planters in the corners of the paved square, bins and bike
## racks. The walkways are PAVED_AREAS (WahatBuilder lays them) and the date palms are
## PALM_TREES (DecorBuilder plants them).

const KERB := Color(0.86, 0.84, 0.78)
const SHRUBS := [Color(0.22, 0.45, 0.2), Color(0.3, 0.53, 0.24), Color(0.25, 0.4, 0.22)]
const FLOWERS := [Color(0.95, 0.45, 0.6), Color(1, 0.8, 0.25), Color(0.98, 0.97, 0.95), Color(0.8, 0.38, 0.85)]
const PLANTER := Color(0.8, 0.74, 0.64)
const SOIL := Color(0.36, 0.26, 0.18)
const BIN := Color(0.2, 0.42, 0.35)
const RACK := Color(0.55, 0.57, 0.6)
const LAWN_TOP := 0.06        # the grass in a bed sits a little above the paving (0.03)
const KERB_TOP := 0.13
const KERB_WIDTH := 0.18
const SHRUB_SPACING := 3.2


static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var land: Dictionary = map.get("PLAZA_LANDSCAPE", {})
	var holder := Node3D.new()
	holder.name = "PlazaLandscape"
	parent.add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 57057
	var palms: Array = map.get("PALM_TREES", [])
	var beds: Array = land.get("beds", [])
	for i in beds.size():
		_bed(holder, beds[i], i, palms, rng)
	var count := 0
	for bench: Dictionary in land.get("benches", []):
		count += 1
		Props.bench(holder, bench["position"], bench["facing"]).name = "Bench_%d" % count
	for spot: Vector3 in land.get("planters", []):
		count += 1
		_planter(holder, spot, rng).name = "Planter_%d" % count
	for spot: Vector3 in land.get("core_planters", []):
		count += 1
		_round_planter(holder, spot, rng).name = "RoundPlanter_%d" % count
	for spot: Vector3 in land.get("bins", []):
		count += 1
		_bin(holder, spot).name = "Bin_%d" % count
	for rack: Dictionary in land.get("bike_racks", []):
		count += 1
		_rack(holder, rack).name = "BikeRack_%d" % count
	return holder


## One grass bed: the lawn, a stone kerb all round, shrubs and flowers inside the kerb.
static func _bed(holder: Node3D, area: Rect2, index: int, palms: Array, rng: RandomNumberGenerator) -> void:
	var inner := area.grow(-KERB_WIDTH)
	var middle := area.get_center()
	var lawn := LowPoly.box(holder, Vector3(inner.size.x, LAWN_TOP, inner.size.y), Color(0.47, 0.66, 0.34),
			Vector3(middle.x, LAWN_TOP * 0.5, middle.y))
	lawn.name = "PlazaBed_%d" % index
	lawn.material_override = TerrainMaterials.make("grass")
	lawn.add_to_group("plaza_bed")
	for side in [-1.0, 1.0]:
		LowPoly.box(holder, Vector3(area.size.x, KERB_TOP, KERB_WIDTH), KERB,
				Vector3(middle.x, KERB_TOP * 0.5, middle.y + side * (area.size.y - KERB_WIDTH) * 0.5))
		LowPoly.box(holder, Vector3(KERB_WIDTH, KERB_TOP, inner.size.y), KERB,
				Vector3(middle.x + side * (area.size.x - KERB_WIDTH) * 0.5, KERB_TOP * 0.5, middle.y))
	# Low shrubs and flowers just inside the kerb, keeping clear of the palm trunks.
	var edge := inner.grow(-0.55)
	var corners := [edge.position, Vector2(edge.end.x, edge.position.y), edge.end, Vector2(edge.position.x, edge.end.y)]
	var count := 0
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		var steps := maxi(1, int(a.distance_to(b) / SHRUB_SPACING))
		for i in steps:
			var spot := a.lerp(b, (i + 0.5) / steps)
			var clear := true
			for palm: Vector3 in palms:
				if Vector2(palm.x, palm.z).distance_to(spot) < 1.4:
					clear = false
			if not clear:
				continue
			count += 1
			var size := rng.randf_range(0.32, 0.5)
			LowPoly.sphere(holder, size, size * 1.5, SHRUBS[count % SHRUBS.size()], Vector3(spot.x, LAWN_TOP + size * 0.6, spot.y))
			if count % 2 == 0:
				var flower := spot.lerp(middle, 0.6 / maxf(spot.distance_to(middle), 0.6))
				for petal in 3:
					var near := flower + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))
					LowPoly.sphere(holder, 0.11, 0.12, FLOWERS[(count + petal) % FLOWERS.size()], Vector3(near.x, LAWN_TOP + 0.18, near.y))


## A 1.2 m square planter with a shrub and flowers, by a shop terrace.
static func _planter(holder: Node3D, spot: Vector3, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Planter"
	body.position = spot
	holder.add_child(body)
	LowPoly.box(body, Vector3(1.2, 0.6, 1.2), PLANTER, Vector3(0, 0.3, 0))
	LowPoly.box(body, Vector3(1.0, 0.04, 1.0), SOIL, Vector3(0, 0.6, 0))
	LowPoly.solid_box(body, Vector3(1.2, 0.6, 1.2), Vector3(0, 0.3, 0))
	LowPoly.sphere(body, 0.5, 0.85, SHRUBS[1], Vector3(0, 1.0, 0))
	for i in 4:
		var angle := TAU * i / 4.0 + rng.randf() * 0.5
		LowPoly.sphere(body, 0.11, 0.12, FLOWERS[i % FLOWERS.size()], Vector3(cos(angle) * 0.38, 0.7, sin(angle) * 0.38))
	return body


## A round raised planter (a palm grows out of it) in a corner of the paved square.
static func _round_planter(holder: Node3D, spot: Vector3, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "RoundPlanter"
	body.position = spot
	holder.add_child(body)
	LowPoly.cylinder(body, 1.6, 1.65, 0.5, PLANTER, Vector3(0, 0.25, 0))
	LowPoly.cylinder(body, 1.45, 1.45, 0.04, SOIL, Vector3(0, 0.5, 0))
	LowPoly.solid_cylinder(body, 1.65, 0.5, Vector3(0, 0.25, 0))
	for i in 6:
		var angle := TAU * i / 6.0 + rng.randf() * 0.3
		LowPoly.sphere(body, 0.3, 0.45, SHRUBS[i % SHRUBS.size()], Vector3(cos(angle) * 1.05, 0.7, sin(angle) * 1.05))
	return body


## A green litter bin with a lid.
static func _bin(holder: Node3D, spot: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Bin"
	body.position = spot
	holder.add_child(body)
	LowPoly.cylinder(body, 0.27, 0.24, 0.85, BIN, Vector3(0, 0.425, 0))
	LowPoly.cylinder(body, 0.3, 0.3, 0.06, BIN.darkened(0.3), Vector3(0, 0.88, 0))
	LowPoly.solid_cylinder(body, 0.3, 0.9, Vector3(0, 0.45, 0))
	return body


## A bike rack: a row of steel hoops on a rail (bikes park beside them).
static func _rack(holder: Node3D, rack: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "BikeRack"
	body.position = rack["position"]
	body.rotation_degrees.y = rack["facing"]
	holder.add_child(body)
	var length: float = rack.get("length", 3.0)
	LowPoly.box(body, Vector3(length, 0.05, 0.08), RACK, Vector3(0, 0.03, 0))
	var hoops := int(length / 0.75)
	for i in hoops:
		var x := -length * 0.5 + 0.375 + i * 0.75
		for z in [-0.28, 0.28]:
			LowPoly.box(body, Vector3(0.05, 0.75, 0.05), RACK, Vector3(x, 0.375, z))
		LowPoly.box(body, Vector3(0.05, 0.05, 0.61), RACK, Vector3(x, 0.77, 0))
	LowPoly.solid_box(body, Vector3(length, 0.8, 0.62), Vector3(0, 0.4, 0))
	return body
