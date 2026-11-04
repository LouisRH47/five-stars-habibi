class_name SpinePlanting
extends RefCounted
## Session 63: lots of palms and plants round the domes, like the real spine (Louis's list):
## round every dome a ring of 3 date palms, 2 fruit trees (pomegranate and fig) and 8 to 12
## shrubs and flower clumps; low plants and flowers along the raised strip between the red
## track and the buggy road. The models are the free CC0 packs (Quaternius, Kenney: see
## CREDITS.md). Repeated plants are drawn together (KitProps.place_many = MultiMesh) and
## small ones aren't drawn far away. Nothing is planted on a path, pool, court or gate.
## The browser version leaves the model packs out (to stay small): then plain shapes made
## here, and the palms from scenes/palm_tree.tscn, are used instead.

const PALMS := ["quaternius_crops/PalmTree_4", "quaternius_nature/PalmTree_3", "quaternius_nature/PalmTree_1"]
const FRUIT_TREES := ["quaternius_crops/Apple_4", "quaternius_crops/Orange_4"]   # pomegranate, fig
const SHRUBS := ["quaternius_nature/Bush_1", "quaternius_nature/Bush_2", "quaternius_nature/Plant_3",
		"quaternius_nature/Plant_1", "quaternius_nature/Flowers", "quaternius_crops/Flower_4",
		"quaternius_crops/BushBerries_4"]
const SHRUB_SCALE := {"quaternius_nature/Bush_1": 0.95, "quaternius_nature/Bush_2": 0.95,
		"quaternius_nature/Plant_3": 0.9, "quaternius_nature/Plant_1": 0.9, "quaternius_nature/Flowers": 1.6,
		"quaternius_crops/Flower_4": 1.6}
const STRIP_PLANTS := ["quaternius_nature/Flowers", "quaternius_crops/Flower_4", "quaternius_nature/Grass_Short",
		"quaternius_crops/Flower_3", "quaternius_nature/Plant_1"]
const STRIP_SCALE := {"quaternius_nature/Flowers": 1.3, "quaternius_crops/Flower_4": 1.2, "quaternius_crops/Flower_3": 1.2,
		"quaternius_nature/Plant_1": 0.45, "quaternius_nature/Grass_Short": 1.4}
const PALM_SCENE := preload("res://scenes/palm_tree.tscn")
const LEAF := [Color(0.24, 0.5, 0.2), Color(0.33, 0.58, 0.24), Color(0.2, 0.42, 0.22)]
const BLOOM := [Color(0.92, 0.3, 0.45), Color(0.98, 0.8, 0.25), Color(0.65, 0.4, 0.85), Color(1, 1, 1)]


## True if the model file is here (it isn't in the browser version).
static func has_kit(id: String) -> bool:
	return KitProps.file_of(id) != ""


## Plants round every dome and along the strip pieces. Returns the dome spots used (tests).
static func build(parent: Node3D, map: Dictionary, strips: Array) -> Dictionary:
	var holder := Node3D.new()
	holder.name = "SpinePlanting"
	parent.add_child(holder)
	var blocked := keep_out(map)
	var report := {"palms": [], "trees": [], "shrubs": []}
	var rng := RandomNumberGenerator.new()
	rng.seed = 6363
	var radius: float = map["DOME_RADIUS"]
	for d in map["SPINE_DOMES"].size():
		var dome: Vector3 = map["SPINE_DOMES"][d]
		var ring := Node3D.new()
		ring.name = "DomePlanting_%d" % d
		holder.add_child(ring)
		var near := GameConfig.SPINE_DOME_RING
		# Palms behind the dome, fruit trees at its sides, shrubs all round (not at the door).
		var palms := _ring(dome, [180.0, 125.0, 235.0, 150.0, 210.0, 100.0, 260.0], near.y - 1.0, 1.5, blocked, GameConfig.SPINE_DOME_PALMS)
		var trees := _ring(dome, [75.0, 285.0, 95.0, 265.0, 60.0, 300.0, 45.0, 315.0, 115.0, 245.0], near.y - 0.8, 1.4, blocked + _circles(palms, 2.5), GameConfig.SPINE_DOME_FRUIT_TREES)
		var angles: Array = []
		for i in 48:   # two times round, so a dome next to a pool still gets its shrubs
			angles.append(35.0 + (i % 24) * 12.0 + (6.0 if i >= 24 else 0.0) + rng.randf_range(-3.0, 3.0))
		var shrubs: Array = []
		var taken: Array = blocked + _circles(palms + trees, 1.6)
		for a: float in angles:
			if shrubs.size() >= GameConfig.SPINE_DOME_SHRUBS:
				break
			var r := rng.randf_range(near.x, near.y) + (1.5 if angles.find(a) >= 24 else 0.0)
			var spot := Vector3(dome.x + sin(deg_to_rad(a)) * r, 0, dome.z + cos(deg_to_rad(a)) * r)
			if _free(spot, 0.7, taken):
				shrubs.append(spot)
				taken = taken + _circles([spot], 1.3)
		_bed_ring(ring, map, dome, rng)
		_trees(ring, palms, PALMS, d, true)
		_trees(ring, trees, FRUIT_TREES, d, false)
		_scatter(ring, shrubs, SHRUBS, SHRUB_SCALE, rng)
		report["palms"].append_array(palms)
		report["trees"].append_array(trees)
		report["shrubs"].append_array(shrubs)
	# The planted strip: a low plant or flower clump every 1.1 m or so.
	var on_strip: Array = []
	for strip: Rect2 in strips:
		var x := strip.position.x + 0.6
		while x < strip.end.x - 0.4:
			on_strip.append(Vector3(x, GameConfig.SPINE_STRIP_TOP, strip.get_center().y + rng.randf_range(-0.3, 0.3)))
			x += rng.randf_range(0.55, 0.95)
	var chunk_size := 60.0
	var chunks := {}
	for spot: Vector3 in on_strip:
		var key := floori(spot.x / chunk_size)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(spot)
	for key: int in chunks:
		var part := Node3D.new()
		part.name = "StripPlants_%d" % key
		holder.add_child(part)
		_scatter(part, chunks[key], STRIP_PLANTS, STRIP_SCALE, rng)
	report["strip"] = on_strip
	holder.set_meta("report", report)
	return report


## Everything plants keep clear of: [Rect2...] and [[centre Vector2, radius]...].
static func keep_out(map: Dictionary, with_domes := true) -> Array:
	var out: Array = []
	var gap := GameConfig.SPINE_PLANT_CLEARANCE
	for road: Dictionary in map["ROADS"]:
		out.append(ClusterSigns.road_rect(road, map["ROAD_WIDTH"]).grow(gap))
	for key in ["LAP_POOL", "COMMUNITY_POOL", "BASKETBALL_COURT", "PLAYGROUND", "BEEHIVES"]:
		if map.has(key):
			out.append((map[key] as Rect2).grow(gap))
	out.append((map["DONKEY_PEN"]["area"] as Rect2).grow(gap))
	for bed: Rect2 in map["FARM_BEDS"]:
		out.append(bed.grow(gap))
	var gym: Dictionary = map["GYM"]
	var size: Vector3 = gym["size"]
	var turned := absf(sin(deg_to_rad(gym["facing"]))) > 0.5
	var half := Vector2(size.z, size.x) * 0.5 if turned else Vector2(size.x, size.z) * 0.5
	out.append(Rect2(Vector2(gym["position"].x, gym["position"].z) - half, half * 2.0).grow(gap))
	for key in ["LAP_POOL_DETAIL", "COMMUNITY_POOL_DETAIL"]:
		var pool: Dictionary = map.get(key, {})
		if pool.has("gate"):
			out.append([pool["gate"], 2.5])
	for dome: Vector3 in map["SPINE_DOMES"]:
		if with_domes:
			out.append([Vector2(dome.x, dome.z), float(map["DOME_RADIUS"]) + 0.9])
		# the door apron, from the door down to the track
		out.append(Rect2(dome.x - 1.8, dome.z + float(map["DOME_RADIUS"]), 3.6, 9.0))
	out.append(GameConfig.SPINE_FREE_CORNER)   # kept free for a car park (the lead, Session 62)
	return out


## A ring-shaped flower bed hugging the dome (dark soil, flowers and low plants), with a gap
## at the door.
static func _bed_ring(parent: Node3D, map: Dictionary, dome: Vector3, rng: RandomNumberGenerator) -> void:
	var inner: float = float(map["DOME_RADIUS"]) + 0.1
	var outer := inner + GameConfig.SPINE_DOME_BED
	var blocked := keep_out(map, false)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spots: Array = []
	const PIECES := 48
	for i in PIECES:
		var a0 := TAU * i / PIECES
		var a1 := TAU * (i + 1) / PIECES
		var middle := Vector3(dome.x + sin((a0 + a1) * 0.5) * (inner + outer) * 0.5, 0, dome.z + cos((a0 + a1) * 0.5) * (inner + outer) * 0.5)
		if not _free(middle, 0.2, blocked):
			continue   # the door and anything else in the way
		var corners: Array[Vector3] = []
		for c in [[a0, inner], [a1, inner], [a1, outer], [a0, outer]]:
			corners.append(Vector3(sin(c[0]) * c[1], 0.022, cos(c[0]) * c[1]))
		for k in [0, 1, 2, 0, 2, 3]:   # the order Godot draws from above
			tool.set_normal(Vector3.UP)
			tool.set_color(Color(0.33, 0.24, 0.17))
			tool.add_vertex(corners[k])
		for n in 3:
			var a := lerpf(a0, a1, rng.randf())
			var r := rng.randf_range(inner + 0.25, outer - 0.25)
			spots.append(Vector3(dome.x + sin(a) * r, 0.022, dome.z + cos(a) * r))
	var bed := MeshInstance3D.new()
	bed.name = "DomeBed"
	bed.mesh = tool.commit()
	bed.material_override = MeshKit.material()
	bed.position = Vector3(dome.x, 0, dome.z)
	parent.add_child(bed)
	_scatter(parent, spots, STRIP_PLANTS + ["quaternius_crops/Flower_2", "quaternius_nature/Plant_3"],
			STRIP_SCALE.merged({"quaternius_nature/Plant_3": 0.45}), rng)


## Up to `count` spots on a ring round the dome at the given angles (0 = the door side).
static func _ring(dome: Vector3, angles: Array, r: float, size: float, blocked: Array, count: int) -> Array:
	var spots: Array = []
	for a: float in angles:
		if spots.size() >= count:
			break
		for push in [0.0, 1.2, -1.0]:
			var spot := Vector3(dome.x + sin(deg_to_rad(a)) * (r + push), 0, dome.z + cos(deg_to_rad(a)) * (r + push))
			if _free(spot, size, blocked + _circles(spots, 3.0)):
				spots.append(spot)
				break
	return spots


static func _circles(spots: Array, r: float) -> Array:
	var out: Array = []
	for spot: Vector3 in spots:
		out.append([Vector2(spot.x, spot.z), r])
	return out


## True if a plant `size` metres round at `spot` touches nothing in `blocked`.
static func _free(spot: Vector3, size: float, blocked: Array) -> bool:
	var at := Vector2(spot.x, spot.z)
	for item in blocked:
		if item is Rect2:
			if (item as Rect2).grow(size).has_point(at):
				return false
		elif at.distance_to(item[0]) < float(item[1]) + size:
			return false
	return true


## Palms or fruit trees: the kit model plus a solid trunk, or a code-built palm.
static func _trees(parent: Node3D, spots: Array, ids: Array, variant: int, palms: bool) -> void:
	for i in spots.size():
		var id: String = ids[(i + variant) % ids.size()]
		var spot: Vector3 = spots[i]
		if has_kit(id):
			var tree := KitProps.place(parent, id, spot, float((variant * 97 + i * 53) % 360),
					1.0 if palms else 1.4)
			tree.name = ("Palm_%d" if palms else "FruitTree_%d") % i
			var trunk := StaticBody3D.new()
			trunk.position = spot
			parent.add_child(trunk)
			LowPoly.solid_cylinder(trunk, 0.3, 2.0, Vector3(0, 1.0, 0))
		elif palms:
			var palm: Node3D = PALM_SCENE.instantiate()
			palm.name = "Palm_%d" % i
			palm.position = spot
			parent.add_child(palm)
			palm.setup(variant * 3 + i)
		else:
			var tree := StaticBody3D.new()
			tree.name = "FruitTree_%d" % i
			tree.position = spot
			parent.add_child(tree)
			LowPoly.cylinder(tree, 0.12, 0.18, 1.6, Color(0.45, 0.33, 0.22), Vector3(0, 0.8, 0))
			LowPoly.sphere(tree, 1.3, 2.0, LEAF[i % LEAF.size()], Vector3(0, 2.3, 0))
			LowPoly.solid_cylinder(tree, 0.25, 2.0, Vector3(0, 1.0, 0))


## Small plants: each model's copies drawn together. Without the kit: plain shapes.
static func _scatter(parent: Node3D, spots: Array, ids: Array, scales: Dictionary, rng: RandomNumberGenerator) -> void:
	var groups := {}
	for spot: Vector3 in spots:
		var id: String = ids[rng.randi() % ids.size()]
		if not groups.has(id):
			groups[id] = [[], []]
		groups[id][0].append(spot)
		groups[id][1].append(rng.randf() * 360.0)
	for id: String in groups:
		var group: Node3D = null
		if has_kit(id):
			group = KitProps.place_many(parent, id, groups[id][0], groups[id][1], float(scales.get(id, 1.0)))
		else:
			group = _plain_many(parent, id, groups[id][0])
		if group != null:
			var views: Array = group.find_children("*", "GeometryInstance3D", true, false)
			if group is GeometryInstance3D:
				views.append(group)
			for view in views:
				(view as GeometryInstance3D).visibility_range_end = GameConfig.SPINE_PLANT_VIEW
				(view as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A stand-in plant from simple shapes (the browser version): a bush or a flower clump.
static func _plain_many(parent: Node3D, id: String, spots: Array) -> Node3D:
	var flower := id.contains("flower") or id.contains("Flowers")
	var kit := MeshKit.new()
	if flower:
		kit.ball(0.18, LEAF[1], Vector3(0, 0.12, 0), 0.7)
		var colour: Color = BLOOM[id.length() % BLOOM.size()]
		for i in 5:
			var a := TAU * i / 5.0
			kit.ball(0.06, colour, Vector3(cos(a) * 0.12, 0.25, sin(a) * 0.12))
	else:
		kit.ball(0.45, LEAF[id.length() % LEAF.size()], Vector3(0, 0.35, 0), 0.8)
		kit.ball(0.3, LEAF[(id.length() + 1) % LEAF.size()], Vector3(0.25, 0.55, 0.1), 0.8)
	var view := kit.finish()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = view.mesh
	many.instance_count = spots.size()
	for i in spots.size():
		many.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(i) * 1.3), spots[i]))
	view.free()
	var drawn := MultiMeshInstance3D.new()
	drawn.name = "Plain_" + id.get_file()
	drawn.multimesh = many
	drawn.material_override = MeshKit.material()
	parent.add_child(drawn)
	return drawn
