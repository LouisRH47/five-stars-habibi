extends Node3D
## Scenery and gentle riding terrain for the real-size district. Locations come from data.
@export var data: Script
var _map: Dictionary = {}
const WHITE := Color(0.97, 0.97, 0.94)
const SAND := Color(0.88, 0.78, 0.6)
const TEAL := Color(0.16, 0.56, 0.61)
const GLASS := Color(0.32, 0.53, 0.64)

func _ready() -> void:
	_map = data.get_script_constant_map()
	_checkpoints_and_station()
	_plaza_floors()
	_school_details()
	_institute_steps()
	for hill: Dictionary in _map.get("HILLS", []):
		_hill(hill)
	_planting()
	_pool(_map["LAP_POOL"], "LapPool", false)
	_pool(_map["COMMUNITY_POOL"], "CommunityPool", true)
	for area: Rect2 in _map.get("BUILDING_SITES", []).slice(1):
		if _map.has("PHASE3_SITE") and area == _map["PHASE3_SITE"]["area"]:
			continue  # Session 66: LandmarkBuilder dresses the phase 3 site like phase 2
		_site(area)
	_street_details()
	EndHouses.build(self, _map)  # Session 65: big end houses at the row ends
	MajlisGardens.build(self, _map)  # Session 66: the park between the car park and Cluster 1
	TerrainMaterials.dress_ground(get_parent().get_node("WahatBuilder"))
	TerrainMaterials.dress_ground(get_parent().get_node("SpineBuilder"))
	_finish_static_world.call_deferred()


func _finish_static_world() -> void:
	# AmbientMotion and deferred shop setup must bind their live nodes first.
	await get_tree().process_frame
	# Session 52: stop flicker where two boxes share a face, before they're merged.
	set_meta("zfight_fixed", ZFightFix.apply(get_parent()))
	var report := StaticBatch.bake(get_parent(), 48.0)
	set_meta("static_batch_report", report)
	print("STATIC_BATCH: ", JSON.stringify(report))


func _planting() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 35042
	var grass := QuadMesh.new()
	grass.size = Vector2(0.22, 0.45)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.27, 0.55, 0.18)
	green.cull_mode = BaseMaterial3D.CULL_DISABLED
	green.roughness = 1.0
	grass.material = green
	var spots: Array[Vector3] = []
	for i in 1800:
		var spot := Vector3(rng.randf_range(-140, 410), 0.2, rng.randf_range(-34, 34))
		if absf(spot.z) < 8.5 or spot.z > 22:  # Session 62: off the planters and red tracks
			continue
		var clear := true
		for dome: Vector3 in _map["SPINE_DOMES"]:
			if Vector2(spot.x - dome.x, spot.z - dome.z).length() < _map["DOME_RADIUS"] + 1:
				clear = false
		for area: Rect2 in _map["FARM_BEDS"] + [_map["COMMUNITY_POOL"], _map["LAP_POOL"], _map["BASKETBALL_COURT"], _map["PLAYGROUND"]]:
			if area.grow(1.5).has_point(Vector2(spot.x, spot.z)):
				clear = false
		if spot.x > 95 and spot.x < 135 and spot.z > 8:
			clear = false
		if not clear:
			continue
		for hill: Dictionary in _map["HILLS"]:
			var r := Vector2(spot.x - hill["position"].x, spot.z - hill["position"].z).length() / 10
			var flat: Vector2 = hill.get("clear", Vector2(3, 6))
			spot.y += hill["height"] * pow(maxf(0, 1-r*r), 2) * smoothstep(flat.x, flat.y, absf(spot.z))
		spots.append(spot)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = grass
	many.instance_count = spots.size()
	for i in spots.size():
		many.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), spots[i]))
	var view := MultiMeshInstance3D.new()
	view.name = "SpineGrassTufts"
	view.multimesh = many
	view.visibility_range_end = 100
	add_child(view)
	var flowers := MultiMesh.new()
	flowers.transform_format = MultiMesh.TRANSFORM_3D
	flowers.use_colors = true
	var bloom := SphereMesh.new()
	bloom.radius = 0.13
	bloom.height = 0.12
	bloom.radial_segments = 6
	bloom.rings = 3
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	bloom.material = material
	flowers.mesh = bloom
	flowers.instance_count = int(spots.size() / 6)
	for i in flowers.instance_count:
		flowers.set_instance_transform(i, Transform3D(Basis(), spots[i * 6] + Vector3.UP * 0.15))
		flowers.set_instance_color(i, [Color(1,0.8,0.2), Color(0.94,0.55,0.7), Color.WHITE][i%3])
	var blooms := MultiMeshInstance3D.new()
	blooms.name = "SpineFlowers"
	blooms.multimesh = flowers
	blooms.visibility_range_end = 90
	add_child(blooms)


func _checkpoints_and_station() -> void:
	for entry: Dictionary in _map["GATES"]:
		var checkpoint := Node3D.new()
		checkpoint.set_script(preload("res://scripts/checkpoint.gd"))
		checkpoint.name = str(entry["name"]).replace(" ", "")
		checkpoint.position = entry["position"]
		checkpoint.rotation_degrees.y = entry["facing"]
		add_child(checkpoint)
	# Session 64: the platform island inside the bus loop with two detailed shelters and
	# people who get on the bus (scripts/bus_stop.gd). It replaces the single shelter.
	BusStop.build(self, _map)
	_car_parks()


## Session 79: every car park (bay lines, arrows, solar roofs, the pay machines and the
## buggy park) comes from CarParkBuilder; its cars are DecorBuilder's ParkedCars.
## Session 64: the school car park gets the same asphalt pad as the other car parks.
func _car_parks() -> void:
	CarParkBuilder.build(self, _map)
	if not _map.has("SCHOOL_PARKING"):
		return
	var area: Rect2 = _map["SCHOOL_PARKING"]
	const PAD := 0.03  # like DecorBuilder's car park pads: just under the roads, the bay lines on top
	var pad := LowPoly.box(self, Vector3(area.size.x, PAD, area.size.y), Color(0.36, 0.37, 0.39, 1),
			Vector3(area.get_center().x, PAD * 0.5, area.get_center().y))
	pad.name = "SchoolCarParkPad"


func _plaza_floors() -> void:
	var blocks := Node3D.new()
	blocks.name = "PlazaUpperFloors"
	add_child(blocks)
	# Four shopfronts per pair of upper blocks. (Session 78: Dune Drip's block is gone; the
	# shop has its own stepped roof now, scripts/shop_exterior.gd.)
	for row in [-1.0, 1.0]:
		for col in [-1.0, 1.0]:
			var centre := Vector3(-200 + col * 32, 0, -145 + row * 50)
			_upper(blocks, centre, Vector3(60, 6, 16), -row)
	PlazaWalls.build(blocks, _map)  # Session 78: dress the blank walls facing the Plaza


func _upper(parent: Node3D, at: Vector3, size: Vector3, front: float) -> void:
	var body := StaticBody3D.new()
	body.position = at
	parent.add_child(body)
	_solid(body, size, SAND, Vector3(0, 8 + size.y * 0.5, 0))
	LowPoly.box(body, Vector3(size.x + 0.4, 0.3, size.z + 0.4), WHITE, Vector3(0, 14.1, 0))
	for level in [10.0, 12.5]:
		for x in range(2, int(size.x), 4):
			LowPoly.box(body, Vector3(2, 1.4, 0.1), GLASS, Vector3(x - size.x * 0.5, level, front * (size.z * 0.5 + 0.08)))
	LowPoly.box(body, Vector3(size.x, 0.3, 1.4), WHITE, Vector3(0, 10.9, front * (size.z * 0.5 + 0.3)))


func _school_details() -> void:
	var data_school: Dictionary = _map["SCHOOL"]
	var center: Vector3 = data_school["building"]["position"]
	var school := Node3D.new()
	school.name = "FairGradeCampus"
	add_child(school)
	# Rounded white balcony bands on the three-storey wings, with roof planting.
	for wing in [-1.0, 1.0]:
		for level in [4.4, 8.6, 12.8]:
			var at := center + Vector3(wing * 30, level, -25.8)
			LowPoly.box(school, Vector3(34, 0.32, 2.5), WHITE, at)
			for x in [-17.0, 17.0]:
				LowPoly.cylinder(school, 1.25, 1.25, 0.32, WHITE, at + Vector3(x, 0, 0))
	for x in range(-40, 45, 10):
		LowPoly.box(school, Vector3(2.4, 1, 2), Color(0.68, 0.7, 0.7), center + Vector3(x, 14.5, 8))
		LowPoly.box(school, Vector3(3.0, 0.5, 3), Color(0.28, 0.52, 0.25), center + Vector3(x, 14.3, -8))
	# Roof railings and a sports hall with the school's readable skyline sign.
	for z in [-24.5, 24.5]:
		LowPoly.box(school, Vector3(99, 0.12, 0.12), WHITE, center + Vector3(0, 15.1, z))
	var hall := StaticBody3D.new()
	hall.name = "SportsHall"
	hall.position = Vector3(-395, 0, 112)
	school.add_child(hall)
	_solid(hall, Vector3(45, 10, 25), SAND, Vector3(0, 5, 0))
	LowPoly.box(hall, Vector3(44, 1.6, 0.12), GLASS.darkened(0.4), Vector3(0, 7.2, -12.6))
	_sign(hall, data_school["arabic"], "FAIR GRADE INTERNATIONAL SCHOOL", Vector3(0, 9.2, -12.7), 180, 38)
	# Two shaded swimming pools and two playgrounds fit inside the perimeter.
	for x in [-349.0, -326.0]:
		_pool(Rect2(x, 98, 18, 11), "SchoolPool", false)
		# Session 67: the shade stands on posts with a proper roof (it used to float).
		_shade_roof(school, Vector3(x + 9, 3.8, 103.5), Vector2(19, 12), "SchoolPoolShade_%d" % int(-x))
	# Session 72: the tennis and basketball courts are gone; the football pitch
	# (scripts/school_pitch.gd, built by LandmarkBuilder) has the room now.
	PlaygroundKit.build(school, Vector3(-411, 0, 72), Vector2(12, 10))  # Session 71
	PlaygroundKit.build(school, Vector3(-321, 0, 121), Vector2(12, 10))
	for at: Vector3 in [Vector3(-411, 4.5, 72), Vector3(-321, 4.5, 121)]:
		_shade_roof(school, at, Vector2(14, 12), "PlaygroundShade_%d" % int(-at.x), Color(0.9, 0.75, 0.4))
	for x in range(-412, -316, 6):
		LowPoly.box(school, Vector3(5.8, 0.16, 7.0), GLASS.darkened(0.6), Vector3(x, 3.5, 188))
	for x in [-374.0, -357.0]:
		LowPoly.cylinder(school, 0.06, 0.07, 9, WHITE, Vector3(x, 4.5, 41))
		LowPoly.box(school, Vector3(0.06, 1.2, 2), TEAL, Vector3(x, 8.1, 42))


func _institute_steps() -> void:
	# Session 52: built in the institute's own directions, so the stepped seats sit in front
	# of its glass front (facing the spine) and the small car park is behind it.
	var institution: Dictionary = _map["INSTITUTE"]
	var size: Vector3 = institution["size"]
	var steps := Node3D.new()
	steps.name = "InstituteSeating"
	steps.position = institution["position"]
	steps.rotation.y = deg_to_rad(institution.get("facing", 0.0))
	add_child(steps)
	var front := size.z * 0.5
	# Seating leaves the central doorway and its level access clear.
	# Session 62: the seats step down away from the glass, so people sit facing outwards
	# (towards the spine), with their backs to the building.
	for side in [-1.0, 1.0]:
		for level in 4:
			LowPoly.box(steps, Vector3(16, 0.35 * (4 - level), 1.4), WHITE,
					Vector3(side * 11, 0.175 * (4 - level), front + 0.7 + level * 1.4))
		var visitor := PeopleLooks.teacher()
		visitor.name = "InstituteSitter"
		visitor.position = Vector3(side * 10, 1.05 - visitor.spot("Hips").y, front + 3.1)
		visitor.rotation.y = PI
		steps.add_child(visitor)
		visitor.play("sit")
		visitor.pose.floor_y = 0.7  # Session 80: feet rest on the step below, not inside it
	for x in [-10.0, 0.0, 10.0]:
		LowPoly.box(steps, Vector3(7, 0.03, 4), GLASS.darkened(0.5), Vector3(x, 0.04, -front - 6.0))
	# Session 80: a 5-a-side football pitch on the grass in front (scripts/institute_pitch.gd).
	if _map.has("INSTITUTE_PITCH"):
		InstitutePitch.build(self, _map["INSTITUTE_PITCH"])


func _hill(spec: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "RollingHill_%d_%d" % [spec["position"].x, spec["position"].z]
	body.position = spec["position"]
	add_child(body)
	var width := 21
	var heights := PackedFloat32Array()
	var clear: Vector2 = spec.get("clear", Vector2(3, 6))  # flat this close to the spine road
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in width:
		for x in width:
			var radius := Vector2(x - 10, z - 10).length() / 10.0
			var path_blend := smoothstep(clear.x, clear.y, absf(body.position.z + z - 10))
			heights.append(spec["height"] * pow(maxf(0, 1 - radius * radius), 2) * path_blend)
	for z in width - 1:
		for x in width - 1:
			for offset: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var point := Vector2i(x, z) + offset
				tool.add_vertex(Vector3(point.x - 10, heights[point.y * width + point.x], point.y - 10))
	tool.generate_normals()
	var view := MeshInstance3D.new()
	view.mesh = tool.commit()
	view.material_override = TerrainMaterials.make("grass")
	body.add_child(view)
	var shape := HeightMapShape3D.new()
	shape.map_width = width
	shape.map_depth = width
	shape.map_data = heights
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)


func _pool(area: Rect2, id: String, community: bool) -> void:
	var room := Node3D.new()
	room.name = id
	add_child(room)
	var c := Vector3(area.get_center().x, 0, area.get_center().y)
	# Session 81: a tiled deck, a stone edge, ladders, lane ropes and the water look
	# (scripts/pool_deck.gd). The community pool's deck fills its fence.
	var kind := "community" if community else ("lap" if id == "LapPool" else "school")
	var deck := area.grow(1.8 if kind == "lap" else 1.2)
	if community and _map.has("POOL_GATE"):
		deck = (_map["POOL_GATE"]["fence"] as Rect2).grow(-0.1)
	PoolDeck.build(room, area, kind, deck)
	# Session 81: the swimmers are made by PlaceCrowds (scripts/pool_swimmers.gd).
	if community:
		# Session 65: the gate and the pool sign face the red track (_pool_gate). Session 81:
		# the loungers, umbrellas, kids' area, shower and plants are in scripts/pool_deck.gd.
		_pool_gate(room)


## Session 65: a white pool fence with a gate on the south side and the bilingual pool sign
## standing outside the fence beside the gate (data: POOL_GATE).
func _pool_gate(room: Node3D) -> void:
	var spec: Dictionary = _map.get("POOL_GATE", {})
	if spec.is_empty():
		return
	var area: Rect2 = spec["fence"]
	var gx: float = spec["gate_x"]
	var half: float = spec["gate_width"] * 0.5
	var south := area.end.y
	var a := area.position
	var b := Vector2(area.end.x, area.position.y)
	for side in [[a, b], [b, area.end], [Vector2(area.position.x, south), a],
			[area.end, Vector2(gx + half, south)], [Vector2(gx - half, south), Vector2(area.position.x, south)]]:
		Props.fence(room, side[0], side[1], 1.2, WHITE)
	var gate := StaticBody3D.new()
	gate.name = "PoolGate"
	gate.position = Vector3(gx, 0, south)
	room.add_child(gate)
	for x in [-half, half]:
		LowPoly.box(gate, Vector3(0.16, 1.6, 0.16), TEAL, Vector3(x, 0.8, 0))
		LowPoly.solid_box(gate, Vector3(0.16, 1.6, 0.16), Vector3(x, 0.8, 0))
	LowPoly.box(gate, Vector3(spec["gate_width"] + 0.16, 0.1, 0.12), TEAL, Vector3(0, 1.62, 0))
	var leaf := Node3D.new()  # the gate itself, swung open inwards
	leaf.position = Vector3(-half, 0, 0)
	leaf.rotation_degrees.y = 100.0
	gate.add_child(leaf)
	for y in [0.25, 1.1]:
		LowPoly.box(leaf, Vector3(half * 2.0 - 0.2, 0.05, 0.05), WHITE, Vector3(half - 0.1, y, 0))
	for k in 7:
		LowPoly.box(leaf, Vector3(0.03, 0.9, 0.03), WHITE, Vector3(0.2 + k * 0.4, 0.68, 0))
	var sign := StaticBody3D.new()
	sign.name = "PoolSign"
	sign.position = spec["sign"]
	sign.rotation_degrees.y = spec["facing"]
	room.add_child(sign)
	LowPoly.box(sign, Vector3(1.9, 0.85, 0.08), TEAL, Vector3(0, 1.55, 0))
	for x in [-0.8, 0.8]:
		LowPoly.box(sign, Vector3(0.08, 1.2, 0.08), WHITE, Vector3(x, 0.6, -0.02))
		LowPoly.solid_box(sign, Vector3(0.1, 1.2, 0.1), Vector3(x, 0.6, -0.02))
	var faces := SignText.make_two_faces("المسبح المجتمعي", "Community Pool", SignText.fit_size("المسبح المجتمعي", "Community Pool", 40, 1.6), Color.WHITE, 0.08)
	faces.position.y = 1.55
	sign.add_child(faces)


func _site(area: Rect2) -> void:
	var holder := Node3D.new()
	holder.name = "ConstructionSite"
	add_child(holder)
	var c := Vector3(area.get_center().x, 0, area.get_center().y)
	LowPoly.box(holder, Vector3(area.size.x, 0.03, area.size.y), Color(0.8, 0.75, 0.66), c + Vector3.UP * 0.04)
	for pair in [[area.position, Vector2(area.end.x, area.position.y)], [Vector2(area.end.x, area.position.y), area.end], [area.end, Vector2(area.position.x, area.end.y)], [Vector2(area.position.x, area.end.y), area.position]]:
		Props.fence(holder, pair[0], pair[1], 2, TEAL)
	var crane := StaticBody3D.new()
	crane.name = "Crane"
	crane.position = c
	holder.add_child(crane)
	_solid(crane, Vector3(1.2, 20, 1.2), Color(0.96, 0.75, 0.1), Vector3(0, 10, 0))
	LowPoly.box(crane, Vector3(22, 0.6, 0.8), Color(0.96, 0.75, 0.1), Vector3(0, 20, 0))
	LowPoly.box(crane, Vector3(0.06, 10, 0.06), Color.DIM_GRAY, Vector3(-10, 15, 0))
	LowPoly.box(holder, Vector3(5, 2.6, 3.5), WHITE, c + Vector3(6, 1.3, 3))
	for i in 3:
		LowPoly.cylinder(holder, 0, 2, 1.6, SAND, c + Vector3(-6 + i * 5, 0.8, 5))
	for i in 2:
		var worker := PeopleLooks.resident(4, i)
		worker.position = c + Vector3(i * 3, 0, -3)
		holder.add_child(worker)
	_sign(holder, "قريباً", "Coming soon", c + Vector3(0, 2.6, -area.size.y * 0.5 - 0.1), 180, 52)


func _street_details() -> void:
	var props := Node3D.new()
	props.name = "StreetFurniture"
	add_child(props)
	for road: Dictionary in _map["ROADS"]:
		if road["name"] != "Ring Road":
			continue
		var a: Vector2 = road["from"]
		var b: Vector2 = road["to"]
		var direction := (b - a).normalized()
		var side := Vector2(-direction.y, direction.x)
		# Session 61: the old white dashes (they looked like tyre marks) are gone; RoadMesh paints the lines.
		for i in int(a.distance_to(b) / 45):
			var p := a + direction * (i * 45 + 15) + side * 7
			LowPoly.cylinder(props, 0.07, 0.13, 5.5, Color.DIM_GRAY, Vector3(p.x, 2.75, p.y))
			LowPoly.box(props, Vector3(1.3, 0.15, 0.4), WHITE, Vector3(p.x, 5.5, p.y))
	# Session 65: each cluster's three bins stand at the back, beside the back cross road.
	for entrance: Dictionary in _map.get("CLUSTER_ENTRANCES", []):
		var spot: Vector3 = entrance["bins"]
		var bins := StaticBody3D.new()
		bins.name = "ClusterBins_%s" % entrance["cluster"]
		bins.position = spot
		props.add_child(bins)
		for i in 3:
			LowPoly.box(bins, Vector3(0.65, 1.1, 0.65), [TEAL, Color.DARK_GREEN, Color(0.2, 0.35, 0.65)][i], Vector3(-1 + i, 0.55, 0))
		LowPoly.solid_box(bins, Vector3(2.8, 1.1, 0.7), Vector3(0, 0.55, 0))
	for area: Rect2 in _map["PARKING_AREAS"]:
		LowPoly.box(props, Vector3(0.5, 1.4, 0.4), TEAL, Vector3(area.position.x + 1, 0.7, area.position.y + 2))
		for i in 4:
			LowPoly.box(props, Vector3(0.08, 0.8, 1.4), Color.GRAY, Vector3(area.end.x - 1, 0.4, area.position.y + 3 + i))


## Session 67: a shade roof standing on posts. `top` is the middle of the roof slab,
## `size` its width (x) and depth (z). Posts at the corners and halfway along the long
## sides, a trim round the edge and a low raised middle, so it reads as a real roof.
func _shade_roof(parent: Node3D, top: Vector3, size: Vector2, id: String,
		tint := Color(0.83, 0.76, 0.6)) -> void:
	var shade := StaticBody3D.new()
	shade.name = id
	shade.position = Vector3(top.x, 0, top.z)
	parent.add_child(shade)
	var height := top.y
	var inset := Vector2(size.x * 0.5 - 0.3, size.y * 0.5 - 0.3)
	var spots: Array[Vector2] = []
	for sx in [-1.0, 0.0, 1.0]:
		for sz in [-1.0, 1.0]:
			if sx == 0.0 and size.x < 15.0:
				continue
			spots.append(Vector2(sx * inset.x, sz * inset.y))
	for spot in spots:
		var at := Vector3(spot.x, height * 0.5, spot.y)
		LowPoly.cylinder(shade, 0.11, 0.13, height, WHITE, at).name = "ShadePost"
		LowPoly.solid_cylinder(shade, 0.15, height, at)
		LowPoly.box(shade, Vector3(0.4, 0.12, 0.4), WHITE, Vector3(spot.x, 0.06, spot.y))  # foot plate
	LowPoly.box(shade, Vector3(size.x, 0.14, size.y), tint, Vector3(0, height, 0)).name = "ShadeRoof"
	for side in [-1.0, 1.0]:  # white trim round the edge
		LowPoly.box(shade, Vector3(size.x + 0.2, 0.3, 0.1), WHITE, Vector3(0, height - 0.03, side * (size.y * 0.5 + 0.05)))
		LowPoly.box(shade, Vector3(0.1, 0.3, size.y + 0.03), WHITE, Vector3(side * (size.x * 0.5 + 0.05), height - 0.03, 0))
		LowPoly.box(shade, Vector3(size.x - 0.6, 0.1, 0.16), WHITE.darkened(0.08), Vector3(0, height - 0.15, side * inset.y))  # beam
	LowPoly.box(shade, Vector3(size.x * 0.6, 0.22, size.y * 0.5), tint.darkened(0.06), Vector3(0, height + 0.17, 0))


func _solid(body: StaticBody3D, size: Vector3, tint: Color, at: Vector3) -> void:
	LowPoly.box(body, size, tint, at)
	LowPoly.solid_box(body, size, at)


func _sign(parent: Node3D, arabic: String, english: String, at: Vector3, facing: float, font_size: int) -> void:
	var sign := SignText.make_face(arabic, english, font_size, Color.WHITE, Color(0.1, 0.2, 0.2), 6)
	sign.position = at
	sign.rotation_degrees.y = facing
	parent.add_child(sign)
