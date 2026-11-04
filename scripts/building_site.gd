class_name BuildingSite
extends Node3D
## Session 64: a building site that looks real. Inside each "coming soon" area: a half-built
## concrete building (2 or 3 floors of columns and slabs, the ground floor walled in, the
## next floor half done, steel bars sticking up on top), scaffolding round two sides (poles,
## boards and green safety net), the old crane, a site cabin and a toilet, piles of blocks,
## pipes and sand, a cement mixer, a "Phase 2 coming soon" hoarding and workers in hi-vis
## (one walking, one on the scaffolding, one at the mixer). Not enterable: the building and
## scaffolding are solid and the site has a fence.
## Everything is built from simple shapes (no CC0 pack has scaffolding or cranes). Plain
## boxes are merged later by StaticBatch; the many scaffold poles are one MultiMesh.
## The site is laid out along its long side: in this node's own space x runs along the long
## side (length) and z across it (depth), with (0, 0, 0) in the middle of the area.
## DistrictDetail._site() makes one per BUILDING_SITES area.

const CONCRETE := Color(0.7, 0.69, 0.66)
const SLAB_EDGE := Color(0.6, 0.59, 0.57)
const BLOCKS := Color(0.83, 0.79, 0.7)
const REBAR := Color(0.35, 0.25, 0.2)
const STEEL := Color(0.62, 0.64, 0.66)
const BOARD := Color(0.72, 0.56, 0.33)
const NET := Color(0.2, 0.55, 0.35, 0.45)
const CRANE := Color(0.96, 0.75, 0.1)
const CABIN := Color(0.95, 0.95, 0.93)
const CABIN_BAND := Color(0.2, 0.42, 0.7)
const HI_VIS := [Color(1.0, 0.5, 0.08), Color(0.85, 0.95, 0.2), Color(1.0, 0.5, 0.08)]
const TEAL := Color(0.16, 0.56, 0.61)

## How many floors the half-built frame has.
var floors := 2
## How many scaffold poles there are (the test checks there are some).
var pole_count := 0
## The workers, and the one who walks up and down.
var workers: Array[Person] = []
var _walker: Person
var _walk_from := Vector3.ZERO
var _walk_to := Vector3.ZERO
var _walk_way := 1.0
var _check_left := 0.0
var _near := true


## Makes the site in `area` (x, z on the map) and adds it to parent.
## main: the big site (LandmarkBuilder already made its fence, crane, containers and sign,
## so only the building, scaffolding, materials and workers are added here).
static func build(parent: Node3D, area: Rect2, main: bool, seed_number: int) -> BuildingSite:
	var site := BuildingSite.new()
	site.name = "BuildingSite_%d" % seed_number
	var along_x := area.size.x >= area.size.y
	site.position = Vector3(area.get_center().x, 0, area.get_center().y)
	site.rotation.y = 0.0 if along_x else PI * 0.5
	parent.add_child(site)
	site._lay_out(area.size.x if along_x else area.size.y, area.size.y if along_x else area.size.x, main, seed_number)
	return site


func _lay_out(length: float, depth: float, main: bool, seed_number: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6400 + seed_number
	var margin := 2.0
	var wide := clampf(length * 0.45, 10.0, 26.0)
	var deep := clampf(depth - 7.0, 6.0, 14.0)
	floors = 3 if deep >= 10.0 else 2
	var floor_height: float = GameConfig.SITE_FLOOR_HEIGHT
	var middle := Vector3(-length * 0.5 + margin + 9.0 + wide * 0.5, 0, depth * 0.5 - margin - deep * 0.5)
	set_meta("main", main)
	set_meta("floors", floors)
	_frame(middle, wide, deep, floor_height, rng)
	var front := middle.z - deep * 0.5   # the building's front wall (towards -z)
	var end := middle.x + wide * 0.5     # its far end wall (towards +x)
	_scaffolding(middle, wide, deep, floor_height)
	# The crane stands past the far end, its jib along the site, over the building.
	var crane_x := end + 1.6 + 6.0
	if not main:
		_crane(Vector3(crane_x, 0, 0))
		_cabin(Vector3(-length * 0.5 + margin + 3.0, 0, -depth * 0.5 + margin + 1.9))
		_toilet(Vector3(-length * 0.5 + margin + 7.0, 0, -depth * 0.5 + margin + 1.0))
	# Materials beyond the crane: pallets of blocks, pipes, steel bars, sand and the mixer.
	var stock_x := (crane_x + 3.0) if not main else (end + 4.0)
	var front_z := -depth * 0.5 + margin + 1.0
	var back_z := depth * 0.5 - margin - 1.0
	for i in 3:
		_pallet(Vector3(stock_x + 1.0 + i * 1.6, 0, front_z + 0.2))
	_pipes(Vector3(stock_x + 7.5, 0, front_z + 0.6))
	_rebar(Vector3(stock_x + 4.0, 0, back_z - 0.3))
	for i in 3:   # the sand piles the old sites had
		LowPoly.cylinder(self, 0.0, 1.6, 1.3, Color(0.88, 0.78, 0.6), Vector3(stock_x + 11.5 + i * 3.4, 0.65, back_z - 0.8))
	var mixer_at := Vector3(stock_x + 12.0, 0, front_z + 0.6)
	_mixer(mixer_at)
	if not main:
		_hoarding(Vector3(clampf(length * 0.25, -length * 0.5 + 8.0, length * 0.5 - 8.0), 0, -depth * 0.5 + 0.25),
				minf(12.0, length * 0.3))
	# Workers: one walks along the front, one is up on the scaffolding, one at the mixer.
	var walk_z := front - 1.6 - 1.0
	_walk_from = Vector3(middle.x - wide * 0.5, 0, walk_z)
	_walk_to = Vector3(stock_x, 0, walk_z)
	_walker = _worker(0, _walk_from, PI * 0.5)
	_worker(1, Vector3(middle.x - wide * 0.25, GameConfig.SITE_SCAFFOLD_LIFT + 0.05, front - 0.95), PI)
	if GameConfig.SITE_WORKERS > 2:
		_worker(2, mixer_at + Vector3(-1.5, 0, 0.3), -PI * 0.5)


## The half-built concrete frame: columns, floor slabs, walls on the lower floors, steel
## bars on top. Solid all over (you can't go in).
func _frame(middle: Vector3, wide: float, deep: float, floor_height: float, rng: RandomNumberGenerator) -> void:
	var body := StaticBody3D.new()
	body.name = "HalfBuiltFrame"
	body.position = middle
	add_child(body)
	var columns_x := maxi(2, ceili(wide / 5.0) + 1)
	var columns_z := maxi(2, ceili(deep / 5.0) + 1)
	var top := floors * floor_height
	LowPoly.box(body, Vector3(wide + 0.6, 0.3, deep + 0.6), SLAB_EDGE, Vector3(0, 0.15, 0))  # ground slab
	for level in floors:
		var y := level * floor_height
		var last := level == floors - 1
		for i in columns_x:
			for k in columns_z:
				var spot := Vector3(-wide * 0.5 + wide * i / (columns_x - 1), 0, -deep * 0.5 + deep * k / (columns_z - 1))
				if last and (i + k) % 3 == 1:
					continue   # the top floor isn't finished: some columns still to come
				LowPoly.box(body, Vector3(0.4, floor_height, 0.4), CONCRETE, spot + Vector3(0, y + floor_height * 0.5, 0))
				if last:
					for bar in [Vector2(-0.12, -0.12), Vector2(0.12, 0.12), Vector2(-0.12, 0.12), Vector2(0.12, -0.12)]:
						LowPoly.box(body, Vector3(0.03, 0.9, 0.03), REBAR, spot + Vector3(bar.x, top + 0.45, bar.y))
		if level > 0:   # the floor slab of this level (the top one only half poured)
			var slab := Vector3(wide + 0.4, 0.25, deep + 0.4)
			LowPoly.box(body, slab, CONCRETE, Vector3(0, y, 0))
			LowPoly.box(body, Vector3(slab.x + 0.04, 0.12, slab.z + 0.04), SLAB_EDGE, Vector3(0, y - 0.08, 0))
		# Walls: all round on the ground floor, the back and one end on the next floor.
		if level == 0:
			_walls(body, wide, deep, y, floor_height, columns_x, [true, true, true, true])
		elif level == 1 and floors > 2:
			_walls(body, wide, deep, y, floor_height, columns_x, [false, true, true, false])
	if floors > 1:   # half a top slab: shuttering boards where the rest will go
		LowPoly.box(body, Vector3(wide * 0.5 + 0.2, 0.25, deep + 0.4), CONCRETE, Vector3(-wide * 0.25, top, 0))
		LowPoly.box(body, Vector3(wide * 0.5, 0.05, deep), BOARD.darkened(0.15), Vector3(wide * 0.25, top - 0.1, 0))
	LowPoly.solid_box(body, Vector3(wide + 0.6, top + 1.0, deep + 0.6), Vector3(0, (top + 1.0) * 0.5, 0))
	body.set_meta("columns", columns_x * columns_z)
	var bar_seed := rng.randi()  # (kept so each site differs if more random parts are added)
	body.set_meta("seed", bar_seed)


## Block walls between the columns of one floor. sides: [front, back, far end, near end].
## Front and back get window gaps.
func _walls(body: Node3D, wide: float, deep: float, y: float, floor_height: float, columns_x: int, sides: Array) -> void:
	var tall := floor_height - 0.25
	var bay := wide / (columns_x - 1)
	for side in 2:
		if not sides[side]:
			continue
		var z := (-deep * 0.5 if side == 0 else deep * 0.5)
		for i in columns_x - 1:
			var x := -wide * 0.5 + bay * (i + 0.5)
			var gap := bay - 0.4
			LowPoly.box(body, Vector3(gap, 1.0, 0.2), BLOCKS, Vector3(x, y + 0.5, z))          # under the window
			LowPoly.box(body, Vector3(gap, tall - 2.4, 0.2), BLOCKS, Vector3(x, y + 2.4 + (tall - 2.4) * 0.5, z))  # over it
			LowPoly.box(body, Vector3(0.3, 1.4, 0.2), BLOCKS, Vector3(x - gap * 0.5 + 0.15, y + 1.7, z))
			LowPoly.box(body, Vector3(0.3, 1.4, 0.2), BLOCKS, Vector3(x + gap * 0.5 - 0.15, y + 1.7, z))
	for side in 2:
		if not sides[side + 2]:
			continue
		var x := (wide * 0.5 if side == 0 else -wide * 0.5)
		LowPoly.box(body, Vector3(0.2, tall, deep - 0.4), BLOCKS, Vector3(x, y + tall * 0.5, 0))


## Scaffolding along the front wall and the far end: two rows of upright poles 2 m apart,
## rails every 2 m up, boards to stand on, cross braces, and green safety net outside.
func _scaffolding(middle: Vector3, wide: float, deep: float, floor_height: float) -> void:
	var holder := StaticBody3D.new()
	holder.name = "Scaffolding"
	add_child(holder)
	var tall := floors * floor_height + 1.0
	var lift: float = GameConfig.SITE_SCAFFOLD_LIFT
	var poles: Array[Transform3D] = []
	# Each run: start, end (along the wall, x z), and which way is "out" from the wall.
	var front := middle.z - deep * 0.5
	var end := middle.x + wide * 0.5
	var runs := [
		[Vector2(middle.x - wide * 0.5 - 0.6, front), Vector2(end + 1.6, front), Vector2(0, -1)],
		[Vector2(end, front - 1.6), Vector2(end, middle.z + deep * 0.5 + 0.6), Vector2(1, 0)],
	]
	for run: Array in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var out: Vector2 = run[2]
		var length := a.distance_to(b)
		var way := (b - a).normalized()
		var bays := maxi(1, ceili(length / GameConfig.SITE_SCAFFOLD_BAY))
		for row: float in [0.3, 1.3]:
			var shift: Vector2 = out * row
			for i in bays + 1:
				var p: Vector2 = a + way * length * i / bays + shift
				poles.append(_pole(Vector3(p.x, 0, p.y), Vector3(p.x, tall, p.y)))
			var h := lift
			while h <= tall:   # the long rails
				poles.append(_pole(Vector3(a.x + shift.x, h, a.y + shift.y), Vector3(b.x + shift.x, h, b.y + shift.y)))
				h += lift
		var h := lift
		while h <= tall:
			for i in bays + 1:   # the short rails across, from the wall row to the outer row
				var p := a + way * length * i / bays
				poles.append(_pole(Vector3(p.x + out.x * 0.3, h, p.y + out.y * 0.3), Vector3(p.x + out.x * 1.3, h, p.y + out.y * 1.3)))
			# Boards to stand on, and a toe board on the outside.
			var mid := (a + b) * 0.5 + out * 0.8
			var board := LowPoly.box(holder, Vector3(length, 0.05, 0.95), BOARD, Vector3(mid.x, h + 0.03, mid.y))
			board.rotation.y = atan2(-way.y, way.x)
			var toe := LowPoly.box(holder, Vector3(length, 0.15, 0.03), BOARD.darkened(0.2), Vector3(mid.x + out.x * 0.48, h + 0.12, mid.y + out.y * 0.48))
			toe.rotation.y = board.rotation.y
			h += lift
		for i in range(0, bays, 3):   # cross braces on the outside
			var p := a + way * length * i / bays + out * 1.35
			var q := a + way * length * mini(i + 2, bays) / bays + out * 1.35
			poles.append(_pole(Vector3(p.x, 0.1, p.y), Vector3(q.x, minf(tall, lift * 2.0), q.y)))
		# Green safety net on the outside: all the way up the short end, only round the top
		# boards along the front (so you can still see the building).
		var net_bottom := lift if run == runs[1] else maxf(lift, tall - lift)
		var net := MeshInstance3D.new()
		net.name = "SafetyNet"
		var plane := BoxMesh.new()
		plane.size = Vector3(length, tall - net_bottom, 0.02)
		var material := StandardMaterial3D.new()
		material.albedo_color = NET
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 1.0
		plane.material = material
		net.mesh = plane
		var centre := (a + b) * 0.5 + out * 1.4
		net.position = Vector3(centre.x, net_bottom + (tall - net_bottom) * 0.5, centre.y)
		net.rotation.y = atan2(-way.y, way.x)
		holder.add_child(net)
		var solid_mid := (a + b) * 0.5 + out * 0.8
		var solid := LowPoly.solid_box(holder, Vector3(length, tall, 1.2), Vector3(solid_mid.x, tall * 0.5, solid_mid.y))
		solid.rotation.y = atan2(-way.y, way.x)
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.03
	pole_mesh.bottom_radius = 0.03
	pole_mesh.height = 1.0
	pole_mesh.radial_segments = 6
	pole_mesh.rings = 1
	pole_mesh.material = LowPoly.material(STEEL)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = pole_mesh
	many.instance_count = poles.size()
	for i in poles.size():
		many.set_instance_transform(i, poles[i])
	var view := MultiMeshInstance3D.new()
	view.name = "ScaffoldPoles"
	view.multimesh = many
	view.visibility_range_end = 260.0
	holder.add_child(view)
	pole_count = poles.size()


## One pole from a to b (a unit cylinder stretched and turned).
static func _pole(a: Vector3, b: Vector3) -> Transform3D:
	var way := (b - a).normalized()
	var turn := Basis(Quaternion(Vector3.UP, way)) if way.dot(Vector3.UP) > -0.999 else Basis(Vector3.RIGHT, PI)
	return Transform3D(turn * Basis.from_scale(Vector3(1.0, a.distance_to(b), 1.0)), (a + b) * 0.5)


## The crane from the old building sites, unchanged (a tall yellow mast and a long jib).
func _crane(at: Vector3) -> void:
	var crane := StaticBody3D.new()
	crane.name = "Crane"
	crane.position = at
	add_child(crane)
	LowPoly.box(crane, Vector3(1.2, 20, 1.2), CRANE, Vector3(0, 10, 0))
	LowPoly.solid_box(crane, Vector3(1.2, 20, 1.2), Vector3(0, 10, 0))
	LowPoly.box(crane, Vector3(22, 0.6, 0.8), CRANE, Vector3(0, 20, 0))
	LowPoly.box(crane, Vector3(0.06, 10, 0.06), Color.DIM_GRAY, Vector3(-10, 15, 0))
	LowPoly.box(crane, Vector3(2.4, 0.6, 2.4), Color(0.55, 0.55, 0.55), Vector3(0, 0.3, 0))   # Session 64: a base block


## The site cabin: the old white box, now with a blue band, a door and windows.
func _cabin(at: Vector3) -> void:
	var cabin := StaticBody3D.new()
	cabin.name = "SiteCabin"
	cabin.position = at
	add_child(cabin)
	LowPoly.box(cabin, Vector3(5, 2.6, 3.5), CABIN, Vector3(0, 1.3, 0))
	LowPoly.solid_box(cabin, Vector3(5, 2.6, 3.5), Vector3(0, 1.3, 0))
	LowPoly.box(cabin, Vector3(5.04, 0.3, 3.54), CABIN_BAND, Vector3(0, 2.35, 0))
	LowPoly.box(cabin, Vector3(0.9, 2.0, 0.05), CABIN_BAND.darkened(0.3), Vector3(-1.5, 1.0, -1.76))   # door
	for x in [0.2, 1.6]:
		LowPoly.box(cabin, Vector3(1.0, 0.8, 0.05), Color(0.32, 0.53, 0.64), Vector3(x, 1.5, -1.76))
	LowPoly.box(cabin, Vector3(1.2, 0.2, 0.8), Color(0.5, 0.5, 0.5), Vector3(-1.5, 0.1, -2.15))   # the step


## A portable toilet (blue box with a white roof).
func _toilet(at: Vector3) -> void:
	var box := StaticBody3D.new()
	box.name = "SiteToilet"
	box.position = at
	add_child(box)
	LowPoly.box(box, Vector3(1.2, 2.2, 1.2), CABIN_BAND, Vector3(0, 1.1, 0))
	LowPoly.box(box, Vector3(1.3, 0.12, 1.3), CABIN, Vector3(0, 2.26, 0))
	LowPoly.solid_box(box, Vector3(1.2, 2.3, 1.2), Vector3(0, 1.15, 0))


## A wooden pallet with a stack of grey concrete blocks.
func _pallet(at: Vector3) -> void:
	LowPoly.box(self, Vector3(1.2, 0.15, 1.0), BOARD.darkened(0.25), at + Vector3(0, 0.075, 0))
	LowPoly.box(self, Vector3(1.1, 0.8, 0.9), Color(0.62, 0.62, 0.6), at + Vector3(0, 0.55, 0))
	LowPoly.box(self, Vector3(1.12, 0.03, 0.92), Color(0.5, 0.5, 0.48), at + Vector3(0, 0.55, 0))   # a joint line


## A pile of orange plastic pipes lying down.
func _pipes(at: Vector3) -> void:
	for i in 6:
		var row := 0 if i < 3 else 1
		var pipe := LowPoly.cylinder(self, 0.16, 0.16, 4.0, Color(0.92, 0.5, 0.15),
				at + Vector3(0, 0.16 + row * 0.28, (i % 3) * 0.34 + row * 0.17 - 0.34))
		pipe.rotation.z = PI * 0.5


## A bundle of steel bars on two wooden blocks.
func _rebar(at: Vector3) -> void:
	for x in [-1.5, 1.5]:
		LowPoly.box(self, Vector3(0.2, 0.15, 0.8), BOARD.darkened(0.25), at + Vector3(x, 0.075, 0))
	LowPoly.box(self, Vector3(6.0, 0.18, 0.5), REBAR, at + Vector3(0, 0.24, 0))


## A cement mixer: a tilted orange drum on a stand with two wheels.
func _mixer(at: Vector3) -> void:
	var mixer := StaticBody3D.new()
	mixer.name = "CementMixer"
	mixer.position = at
	add_child(mixer)
	LowPoly.box(mixer, Vector3(0.9, 0.5, 0.6), Color(0.3, 0.32, 0.35), Vector3(0, 0.55, 0))
	var drum := LowPoly.cylinder(mixer, 0.3, 0.45, 0.9, Color(0.95, 0.45, 0.1), Vector3(0.2, 1.15, 0))
	drum.rotation.z = -0.6
	for z in [-0.35, 0.35]:
		var wheel := LowPoly.cylinder(mixer, 0.22, 0.22, 0.1, Color(0.15, 0.15, 0.16), Vector3(-0.3, 0.22, z))
		wheel.rotation.x = PI * 0.5
	LowPoly.solid_box(mixer, Vector3(1.2, 1.5, 0.9), Vector3(0, 0.75, 0))


## The "Phase 2 coming soon" hoarding on the fence (bilingual).
func _hoarding(at: Vector3, length: float) -> void:
	var board := StaticBody3D.new()
	board.name = "Hoarding"
	board.position = at
	add_child(board)
	LowPoly.box(board, Vector3(length, 2.4, 0.08), Color(0.97, 0.97, 0.95), Vector3(0, 1.2, 0))
	LowPoly.box(board, Vector3(length, 0.35, 0.09), TEAL, Vector3(0, 0.2, 0))
	LowPoly.box(board, Vector3(length, 0.15, 0.09), TEAL, Vector3(0, 2.35, 0))
	LowPoly.solid_box(board, Vector3(length, 2.4, 0.2), Vector3(0, 1.2, 0))
	var arabic := "المرحلة الثانية قريباً"
	var english := "Phase 2 coming soon"
	var font := SignText.fit_size(arabic, english, 56, length - 1.0)
	var face := SignText.make_face(arabic, english, font, Color(0.1, 0.3, 0.33))
	face.position = Vector3(0, 1.3, -0.06)
	face.rotation.y = PI   # reads from outside the site (-z)
	board.add_child(face)


## A worker in a hi-vis shirt and a white hard hat. facing: radians (0 = facing -z).
func _worker(number: int, at: Vector3, facing: float) -> Person:
	var person := Person.new()
	person.name = "SiteWorker%d" % number
	person.paint({"skin": PeopleLooks.SKINS[(number + get_index()) % PeopleLooks.SKINS.size()],
			"shirt": HI_VIS[number % HI_VIS.size()], "pants": Color(0.2, 0.25, 0.4)})
	PeopleLooks.boots(person, Color(0.35, 0.25, 0.15))
	var head := person.follow("Head")
	LowPoly.sphere(head, 0.15, 0.17, Color(0.97, 0.97, 0.95), person.head_spot() + Vector3(0, 0.07, 0))
	LowPoly.cylinder(head, 0.17, 0.17, 0.02, Color(0.97, 0.97, 0.95), person.head_spot() + Vector3(0, 0.02, 0))
	person.position = at
	person.rotation.y = facing
	add_child(person)
	person.play("idle")
	workers.append(person)
	return person


func _process(delta: float) -> void:
	# A few times a second: workers far from the camera stop animating (saves time).
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		var camera := get_viewport().get_camera_3d()
		var near := camera == null or camera.global_position.distance_to(global_position) < 120.0
		if near != _near:
			_near = near
			for person in workers:
				person.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
	if not _near or _walker == null:
		return
	# The walking worker goes up and down the front of the building.
	var target := _walk_to if _walk_way > 0.0 else _walk_from
	var gap := target - _walker.position
	if gap.length() < 0.1:
		_walk_way = -_walk_way
		return
	var step := gap.normalized() * minf(gap.length(), GameConfig.WALKER_SPEED * 0.8 * delta)
	_walker.position += step
	_walker.rotation.y = atan2(-step.x, -step.z)
	_walker.play("walk", GameConfig.WALKER_SPEED * 0.8 / GameConfig.PERSON_WALK_ANIM_MPS)
