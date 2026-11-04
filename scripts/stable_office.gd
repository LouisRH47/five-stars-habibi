class_name StableOffice
## Session 61: the stable office, a little wooden room you can look into. Wood plank walls,
## a pitched roof, an open wooden door and windows. Inside: the groom at his desk, two saddles
## on stands, rosettes and horse photos on the wall, riding helmets on hooks and a hay bale.
## The side window looks onto a small paddock with a horse. The front (+z) faces the road;
## the drop-off is in front of the door, as before.

const PLANK := Color(0.66, 0.47, 0.3)
const PLANK_DARK := Color(0.5, 0.34, 0.2)
const ROOF := Color(0.42, 0.27, 0.16)
const FLOOR := Color(0.55, 0.42, 0.3)
const GREEN := Color(0.3, 0.45, 0.25)
const GLASS := Color(0.6, 0.8, 0.88)
const RAIL := Color(0.92, 0.92, 0.9)
const LEATHER := Color(0.42, 0.22, 0.1)
const HAY := Color(0.92, 0.8, 0.42)
const ROSETTES := [Color(0.15, 0.35, 0.85), Color(0.85, 0.15, 0.15), Color(0.95, 0.8, 0.2), Color(0.2, 0.65, 0.35)]
const DOOR_WIDTH := 1.1
const WALL := 0.15


## Builds the office (and its little paddock). place: the VILLAS entry (902).
static func build(parent: Node3D, place: Dictionary) -> StaticBody3D:
	var size: Vector3 = place["size"]
	var body := StaticBody3D.new()
	body.name = "StableOffice"
	body.position = place["position"]
	body.rotation_degrees.y = place["facing"]
	parent.add_child(body, true)
	body.set_meta("open_room", true)
	var half := size * 0.5
	var wall_h := size.y - 0.6
	LowPoly.box(body, Vector3(size.x, 0.08, size.z), FLOOR, Vector3(0, 0.04, 0))
	# Back wall, the left wall, the right wall with a window (onto the paddock), and the front
	# with the door on the left and a window on the right.
	_planks(body, Vector3(size.x, wall_h, WALL), Vector3(0, wall_h * 0.5, -half.z + WALL * 0.5))
	_planks(body, Vector3(WALL, wall_h, size.z), Vector3(-half.x + WALL * 0.5, wall_h * 0.5, 0))
	_wall_with_window(body, Vector3(WALL, wall_h, size.z), Vector3(half.x - WALL * 0.5, wall_h * 0.5, 0), true)
	var door_x := -half.x + 1.4
	var left := door_x - DOOR_WIDTH * 0.5 + half.x
	_planks(body, Vector3(left, wall_h, WALL), Vector3(-half.x + left * 0.5, wall_h * 0.5, half.z - WALL * 0.5))
	_planks(body, Vector3(DOOR_WIDTH, wall_h - 2.2, WALL), Vector3(door_x, 2.2 + (wall_h - 2.2) * 0.5, half.z - WALL * 0.5))
	var right := half.x - (door_x + DOOR_WIDTH * 0.5)
	_wall_with_window(body, Vector3(right, wall_h, WALL), Vector3(half.x - right * 0.5, wall_h * 0.5, half.z - WALL * 0.5), false)
	# The wooden door, standing open into the room.
	var hinge := Node3D.new()
	hinge.name = "WoodenDoor"
	hinge.position = Vector3(door_x - DOOR_WIDTH * 0.5, 0, half.z - WALL)
	hinge.rotation.y = deg_to_rad(-75.0)
	body.add_child(hinge, true)
	LowPoly.box(hinge, Vector3(DOOR_WIDTH - 0.05, 2.1, 0.06), PLANK_DARK, Vector3(DOOR_WIDTH * 0.5, 1.05, -0.03))
	LowPoly.sphere(hinge, 0.04, 0.08, Color(0.8, 0.7, 0.3), Vector3(DOOR_WIDTH - 0.15, 1.0, 0.02))
	# A pitched roof and the sign board over the door.
	for side in [-1.0, 1.0]:
		var roof := LowPoly.box(body, Vector3(size.x + 0.6, 0.15, half.z + 0.5), ROOF, Vector3(0, wall_h + 0.45, side * (half.z * 0.5 + 0.1)))
		roof.rotation.x = deg_to_rad(20.0 * side)   # slopes down to the front and the back
	for side in [-1.0, 1.0]:   # the gable ends, filling the triangle under the roof
		if GameConfig.INTERIOR_REVIEW_FIXES:
			# Review fix: the two stepped boards left triangles of sky between the side walls and
			# the roof (you saw them from inside). Now each gable is a real triangle with the
			# roof's 20 degree slope, a little bigger so its edges tuck under the roof.
			var gable := MeshInstance3D.new()
			gable.name = "Gable" + ("Left" if side < 0.0 else "Right")
			var prism := PrismMesh.new()
			var rise := tan(deg_to_rad(20.0))
			var base := (0.45 - 0.08 + (half.z * 0.5 + 0.1) * rise) / rise * 2.0 + 0.36
			prism.size = Vector3(base, base * 0.5 * rise, WALL)
			gable.mesh = prism
			gable.material_override = LowPoly.material(PLANK)
			gable.position = Vector3(side * (half.x - WALL * 0.5), wall_h + prism.size.y * 0.5, 0)
			gable.rotation.y = PI * 0.5
			body.add_child(gable, true)
			continue
		for k in 2:
			LowPoly.box(body, Vector3(WALL, 0.36, size.z * (0.6 - k * 0.32)), PLANK, Vector3(side * (half.x - WALL * 0.5), wall_h + 0.18 + k * 0.36, 0))
	var board := Vector3(size.x - 1.6, 0.6, 0.1)
	LowPoly.box(body, board, GREEN, Vector3(0.6, wall_h - 0.45, half.z + 0.06))
	var font := SignText.fit_size("مكتب الإسطبل", "Stable Office", 44, board.x - 0.3)
	var face := SignText.make_face("مكتب الإسطبل", "Stable Office", font, Color.WHITE)
	face.position = Vector3(0.6, wall_h - 0.45, half.z + 0.12)
	body.add_child(face, true)
	_inside(body, size, wall_h)
	var lamp := OmniLight3D.new()
	lamp.name = "OfficeLight"
	lamp.position = Vector3(0, wall_h - 0.4, 0)
	lamp.light_color = Color(1.0, 0.85, 0.65)
	lamp.light_energy = 1.2
	lamp.omni_range = 5.0
	body.add_child(lamp, true)
	_paddock(parent, place)
	return body


## Everything inside: desk and groom, saddles, rosettes, photos, helmets, the hay bale.
static func _inside(body: StaticBody3D, size: Vector3, wall_h: float) -> void:
	var half := size * 0.5
	var back := -half.z + WALL
	# The desk by the right wall, with the groom sitting at it, facing the door side.
	var desk := Vector3(half.x - 1.4, 0, -0.6)
	LowPoly.box(body, Vector3(1.4, 0.06, 0.75), PLANK_DARK, desk + Vector3(0, 0.76, 0))
	for x in [-0.62, 0.62]:
		LowPoly.box(body, Vector3(0.06, 0.74, 0.7), PLANK_DARK, desk + Vector3(x, 0.37, 0))
	LowPoly.box(body, Vector3(0.35, 0.03, 0.25), Color(0.95, 0.95, 0.9), desk + Vector3(-0.3, 0.8, 0.1))   # papers
	LowPoly.cylinder(body, 0.05, 0.05, 0.1, Color(0.9, 0.3, 0.2), desk + Vector3(0.4, 0.84, -0.1))       # a mug
	LowPoly.box(body, Vector3(0.5, 0.45, 0.5), LEATHER, desk + Vector3(0, 0.23, -0.85))                   # chair
	var groom := PeopleLooks.groom()
	groom.name = "OfficeGroom"
	groom.position = desk + Vector3(0, 0.52 - groom.spot("Hips").y, -0.8)
	body.add_child(groom, true)
	groom.play("sit")
	LowPoly.solid_box(body, Vector3(1.4, 0.8, 1.6), desk + Vector3(0, 0.4, -0.4))
	# Two saddles on wooden stands along the back wall.
	for i in 2:
		var stand := Vector3(-half.x + 1.2 + i * 1.3, 0, back + 0.5)
		LowPoly.box(body, Vector3(0.12, 0.9, 0.12), PLANK_DARK, stand + Vector3(0, 0.45, 0))
		LowPoly.box(body, Vector3(0.5, 0.06, 0.5), PLANK_DARK, stand + Vector3(0, 0.03, 0))
		LowPoly.box(body, Vector3(0.18, 0.12, 0.7), PLANK_DARK, stand + Vector3(0, 0.95, 0))
		var saddle := LowPoly.sphere(body, 0.3, 0.32, LEATHER, stand + Vector3(0, 1.08, 0))
		saddle.scale = Vector3(1.0, 1.0, 1.35)
		for side in [-1.0, 1.0]:   # the flaps and stirrups
			LowPoly.box(body, Vector3(0.03, 0.4, 0.35), LEATHER.darkened(0.2), stand + Vector3(side * 0.28, 0.85, 0))
			LowPoly.box(body, Vector3(0.1, 0.03, 0.08), Color(0.7, 0.72, 0.75), stand + Vector3(side * 0.3, 0.58, 0))
	LowPoly.solid_box(body, Vector3(2.6, 1.2, 0.8), Vector3(-half.x + 1.85, 0.6, back + 0.5))
	# Rosettes and framed horse photos on the back wall.
	for i in 4:
		var at := Vector3(-half.x + 0.8 + i * 0.55, 2.3, back + 0.02)
		var rosette := LowPoly.cylinder(body, 0.12, 0.12, 0.03, ROSETTES[i], at)
		rosette.rotation.x = PI * 0.5
		var middle := LowPoly.cylinder(body, 0.05, 0.05, 0.035, Color(0.95, 0.85, 0.3), at + Vector3(0, 0, 0.005))
		middle.rotation.x = PI * 0.5
		for side in [-1.0, 1.0]:
			var ribbon := LowPoly.box(body, Vector3(0.05, 0.22, 0.01), ROSETTES[i], at + Vector3(side * 0.04, -0.2, 0.0))
			ribbon.rotation.z = side * 0.2
	for i in 3:
		var photo := Vector3(-half.x + 3.4 + i * 0.85, 2.0 + (i % 2) * 0.35, back + 0.02)
		LowPoly.box(body, Vector3(0.6, 0.45, 0.03), PLANK_DARK, photo)
		LowPoly.box(body, Vector3(0.5, 0.35, 0.01), Color(0.85, 0.82, 0.7), photo + Vector3(0, 0, 0.02))
		LowPoly.box(body, Vector3(0.28, 0.14, 0.01), [Color(0.45, 0.28, 0.15), Color(0.2, 0.15, 0.12), Color(0.85, 0.82, 0.78)][i],
				photo + Vector3(0, -0.02, 0.026))   # a little horse shape
	# Riding helmets on hooks on the left wall.
	for i in 3:
		var hook := Vector3(-half.x + WALL + 0.04, 1.6, -1.6 + i * 0.6)
		LowPoly.box(body, Vector3(0.08, 0.03, 0.03), Color(0.7, 0.72, 0.75), hook)
		var helmet := LowPoly.sphere(body, 0.15, 0.2, [Color(0.1, 0.1, 0.12), Color(0.15, 0.2, 0.4), Color(0.3, 0.22, 0.15)][i], hook + Vector3(0.12, -0.12, 0))
		helmet.name = "RidingHelmet"
	# A hay bale in the corner by the door.
	LowPoly.box(body, Vector3(0.9, 0.45, 0.5), HAY, Vector3(-half.x + 0.75, 0.25, half.z - 1.1))
	for x in [-0.25, 0.25]:
		LowPoly.box(body, Vector3(0.03, 0.46, 0.52), Color(0.6, 0.45, 0.25), Vector3(-half.x + 0.75 + x, 0.25, half.z - 1.1))


## A wall with a window in its middle. side: true if the wall runs along z (a side wall).
static func _wall_with_window(body: StaticBody3D, size: Vector3, at: Vector3, side: bool) -> void:
	var long := size.z if side else size.x
	var window := minf(1.6, long - 0.8)
	var sill := 1.0
	var top := 2.2
	var edge := (long - window) * 0.5
	for k in [-1.0, 1.0]:
		var shift: float = (window * 0.5 + edge * 0.5) * k
		_planks(body, Vector3(size.x, size.y, edge) if side else Vector3(edge, size.y, size.z),
				at + (Vector3(0, 0, shift) if side else Vector3(shift, 0, 0)))
	var low := Vector3(size.x, sill, window) if side else Vector3(window, sill, size.z)
	_planks(body, low, Vector3(at.x, sill * 0.5, at.z))
	var high := size.y - top
	var over := Vector3(size.x, high, window) if side else Vector3(window, high, size.z)
	_planks(body, over, Vector3(at.x, top + high * 0.5, at.z))
	var pane := LowPoly.box(body, Vector3(0.02, top - sill, window) if side else Vector3(window, top - sill, 0.02), GLASS,
			Vector3(at.x, (sill + top) * 0.5, at.z))
	var clear := LowPoly.material(GLASS).duplicate() as StandardMaterial3D
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color.a = 0.25
	pane.material_override = clear
	pane.name = "OfficeWindow"
	LowPoly.solid_box(body, Vector3(size.x, top - sill, window) if side else Vector3(window, top - sill, size.z), Vector3(at.x, (sill + top) * 0.5, at.z))


## A solid wooden wall with plank lines.
static func _planks(body: StaticBody3D, size: Vector3, at: Vector3) -> void:
	LowPoly.box(body, size, PLANK, at)
	LowPoly.solid_box(body, size, at)
	var lines := int(size.y / 0.3)
	for i in range(1, lines):
		var y := at.y - size.y * 0.5 + i * size.y / lines
		LowPoly.box(body, Vector3(size.x + 0.01, 0.02, size.z + 0.01), PLANK_DARK, Vector3(at.x, y, at.z))


## The little paddock beside the office (outside its window) with a horse in it.
static func _paddock(parent: Node3D, place: Dictionary) -> void:
	var size: Vector3 = place["size"]
	var at: Vector3 = place["position"]
	var area := Rect2(at.x + size.x * 0.5 + 1.0, at.z - size.z * 0.5 - 1.0, 9.0, size.z + 0.5)
	var holder := Node3D.new()
	holder.name = "OfficePaddock"
	parent.add_child(holder, true)
	LowPoly.box(holder, Vector3(area.size.x, 0.02, area.size.y), Color(0.82, 0.7, 0.5), Vector3(area.get_center().x, 0.025, area.get_center().y))
	var a := area.position
	var b := Vector2(area.end.x, area.position.y)
	var c := area.end
	var d := Vector2(area.position.x, area.end.y)
	for side in [[a, b], [b, c], [c, d], [d, a]]:
		Props.fence(holder, side[0], side[1], 1.3, RAIL)
	Props.animal(holder, Vector3(area.get_center().x - 0.5, 0, area.get_center().y), -100.0, Color(0.45, 0.28, 0.15), true)
	LowPoly.box(holder, Vector3(1.2, 0.5, 0.5), Color(0.55, 0.55, 0.58), Vector3(area.end.x - 1.2, 0.25, area.position.y + 0.8))   # water trough
