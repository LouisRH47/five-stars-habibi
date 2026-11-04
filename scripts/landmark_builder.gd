extends Node3D
## Builds the landmarks of Wahat Al Shams (Session 27) from data/wahat_al_shams.gd:
## Al Shams School (a low building in a fenced yard, a sign over the gate, the security
## booth), the stables (stable block, paddock with horses, stable office) and the building
## site (fence, crane, "Phase 2 coming soon" sign). The booth and the office are the two
## drop-off spots in the VILLAS list ("kind": "spot"). The mosque is built by DecorBuilder.
## Node names: School, SchoolBooth, Stables, StableOffice, BuildingSite, Crane.

## The map data to build from (set in the scene): data/wahat_al_shams.gd.
@export var data: Script

const CREAM := Color(0.95, 0.9, 0.8, 1)
const SAND := Color(0.88, 0.78, 0.6, 1)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const GLASS := Color(0.45, 0.65, 0.78, 1)
const DARK := Color(0.25, 0.25, 0.27, 1)
const WOOD := Color(0.55, 0.36, 0.2, 1)
const RAIL := Color(0.92, 0.92, 0.9, 1)
const PITCH := Color(0.42, 0.66, 0.34, 1)
const CRANE := Color(0.96, 0.75, 0.1, 1)
const HOARDING := Color(0.82, 0.86, 0.88, 1)
const HORSES := [Color(0.45, 0.28, 0.15, 1), Color(0.85, 0.82, 0.78, 1), Color(0.2, 0.15, 0.12, 1),
		Color(0.65, 0.42, 0.22, 1)]
const TEXT := Color(1, 1, 1, 1)

var _map: Dictionary = {}


func _ready() -> void:
	if data == null:
		push_error("LandmarkBuilder has no data list set in the scene")
		return
	_map = data.get_script_constant_map()
	if _map.has("SCHOOL"):
		_build_school(_map["SCHOOL"])
	if _map.has("STABLES"):
		_build_stables(_map["STABLES"])
	if _map.has("BUILDING_SITE"):
		_build_site(_map["BUILDING_SITE"])
	for place in _map["VILLAS"]:
		if place.get("kind", "") == "spot" and not place.get("interior", false):
			_build_spot(place)


## The school: a fence round the plot with a gate in the north side, a sign arch over the
## gate, a long low building with windows and solar panels, a football pitch and a flag.
func _build_school(school: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "School"
	add_child(holder)
	var area: Rect2 = school["area"]
	var gate_x: float = school["gate_x"]
	var gap: float = school["gate_width"] * 0.5
	var top := area.position.y
	_fence_box(holder, area, RAIL, 1.6, Vector2(gate_x - gap, gate_x + gap), true)
	var building: Dictionary = school["building"]
	var size: Vector3 = building["size"]
	var body := Node3D.new()
	body.name = "SchoolWings"
	body.position = building["position"]
	holder.add_child(body)
	# Five joined sections make the wings bow around the entrance courtyard.
	for section in 5:
		var bow: float = [3.0, 0.0, -2.0, 0.0, 3.0][section]
		var wing := _solid_block(body, Vector3(-40 + section * 20, 0, bow), Vector3(20.2, size.y, size.z - 4), CREAM)
		for floor_y in [2.0, 6.3, 10.6]:
			LowPoly.box(wing, Vector3(18.5, 1.9, 0.12), GLASS, Vector3(0, floor_y, -(size.z - 4) * 0.5 - 0.08))
			LowPoly.box(wing, Vector3(20.6, 0.28, 2.0), RAIL, Vector3(0, floor_y + 1.3, -(size.z - 4) * 0.5 - 0.4))
	var front := -size.z * 0.5  # the front faces north, to the gate
	LowPoly.box(body, Vector3(size.x + 0.3, 0.4, size.z + 0.3), TEAL, Vector3(0, size.y + 0.2, 0))
	LowPoly.box(body, Vector3(3.0, 2.6, 0.15), DARK, Vector3(0, 1.3, front - 0.08))
	LowPoly.box(body, Vector3(6.0, 0.2, 3.0), TEAL, Vector3(0, 3.0, front - 1.5))
	for i in 5:  # solar panels on the roof
		var panel := LowPoly.box(body, Vector3(4.0, 0.08, 2.2), Color(0.12, 0.2, 0.35, 1),
				Vector3(-11.0 + i * 5.5, size.y + 0.9, 0))
		panel.rotation.x = deg_to_rad(-15.0)
	var pitch := Rect2(area.position.x + 5, top + 8, area.size.x - 10, 24)
	LowPoly.box(holder, Vector3(pitch.size.x, 0.03, pitch.size.y), PITCH, Vector3(pitch.get_center().x, 0.03, pitch.get_center().y))
	_fence_box(holder, pitch.grow(0.5), RAIL, 1.3, Vector2(gate_x - 2, gate_x + 2))
	for x in [pitch.position.x + 0.8, pitch.end.x - 0.8]:
		for z in [pitch.get_center().y - 3.5, pitch.get_center().y + 3.5]:
			LowPoly.box(holder, Vector3(0.12, 2.4, 0.12), RAIL, Vector3(x, 1.2, z))
		LowPoly.box(holder, Vector3(0.12, 0.12, 7.1), RAIL, Vector3(x, 2.4, pitch.get_center().y))
	var flag := StaticBody3D.new()
	flag.position = Vector3(gate_x + 6.0, 0, top + 4.0)
	holder.add_child(flag)
	LowPoly.cylinder(flag, 0.05, 0.08, 7.0, RAIL, Vector3(0, 3.5, 0))
	LowPoly.box(flag, Vector3(0.05, 1.0, 1.6), TEAL, Vector3(0, 6.4, 0.8))
	LowPoly.solid_cylinder(flag, 0.15, 2.0, Vector3(0, 1.0, 0))
	# The sign arch over the gate.
	for x in [gate_x - gap - 0.4, gate_x + gap + 0.4]:
		var pillar := _solid_block(holder, Vector3(x, 0, top), Vector3(0.6, 4.2, 0.6), SAND)
		pillar.name = "GatePillar"
	LowPoly.box(holder, Vector3(gap * 2.0 + 1.4, 1.2, 0.2), TEAL, Vector3(gate_x, 3.6, top))
	_faces(holder, school["arabic"], school["name"], Vector3(gate_x, 3.6, top), 180.0, gap * 2.0, 0.2)


## The stables: a long stable block with stall doors and horses looking out, a big sign,
## and a white-fenced paddock with horses standing in it (just to look at).
func _build_stables(stables: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Stables"
	add_child(holder)
	var block: Dictionary = stables["block"]
	var size: Vector3 = block["size"]
	var body := _solid_block(holder, block["position"], size, CREAM)
	var front := size.z * 0.5  # the front faces south, to the paddock
	for side in [-1.0, 1.0]:  # a pitched roof
		var roof := LowPoly.box(body, Vector3(size.x + 0.6, 0.2, size.z * 0.6), WOOD,
				Vector3(0, size.y + 0.9, side * size.z * 0.25))
		roof.rotation.x = deg_to_rad(22.0 * -side)
	var doors := 6
	for i in doors:
		var x := -size.x * 0.5 + (i + 0.5) * size.x / doors
		LowPoly.box(body, Vector3(2.0, 2.6, 0.1), WOOD, Vector3(x, 1.3, front + 0.05))
		LowPoly.box(body, Vector3(1.6, 1.0, 0.12), DARK, Vector3(x, 2.1, front + 0.06))
		if i % 2 == 1:
			Props.animal(body, Vector3(x, -0.4, front - 1.0), 0.0, HORSES[i % HORSES.size()], true)
	LowPoly.box(body, Vector3(9.0, 1.4, 0.15), TEAL, Vector3(0, size.y + 0.9, front + 0.6))
	_faces(body, stables["arabic"], stables["name"], Vector3(0, size.y + 0.9, front + 0.6), 0.0, 8.4, 0.15)
	var paddock: Rect2 = stables["paddock"]
	LowPoly.box(holder, Vector3(paddock.size.x, 0.02, paddock.size.y), Color(0.82, 0.7, 0.5, 1),
			Vector3(paddock.get_center().x, 0.02, paddock.get_center().y))
	_fence_box(holder, paddock, RAIL, 1.3)
	for i in stables["horses"]:
		var spot := Vector3(paddock.position.x + (i + 0.5) * paddock.size.x / stables["horses"], 0, paddock.get_center().y)
		Props.animal(holder, spot, i * 75.0 + 20.0, HORSES[i % HORSES.size()], true)


## The building site: a tall fence all round (you can't get in), a crane, containers, sand
## piles and the bilingual "Phase 2 coming soon" sign.
func _build_site(site: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "BuildingSite"
	add_child(holder)
	var area: Rect2 = site["area"]
	_fence_box(holder, area, HOARDING, 2.2, Vector2.ZERO, true)
	var crane := StaticBody3D.new()
	crane.name = "Crane"
	crane.position = site["crane"]
	holder.add_child(crane)
	var tall := 24.0
	LowPoly.box(crane, Vector3(3.0, 1.0, 3.0), Color(0.6, 0.6, 0.6, 1), Vector3(0, 0.5, 0))
	LowPoly.box(crane, Vector3(1.0, tall, 1.0), CRANE, Vector3(0, tall * 0.5, 0))
	for i in 12:  # cross bars, so it looks like a lattice
		var bar := LowPoly.box(crane, Vector3(1.05, 0.08, 1.4), DARK, Vector3(0, 1.5 + i * 2.0, 0))
		bar.rotation.x = deg_to_rad(40.0)
	LowPoly.box(crane, Vector3(24.0, 0.8, 0.8), CRANE, Vector3(-7.0, tall + 0.4, 0))   # the jib
	LowPoly.box(crane, Vector3(2.5, 1.6, 1.4), Color(0.4, 0.4, 0.42, 1), Vector3(6.0, tall - 0.4, 0))  # counterweight
	LowPoly.box(crane, Vector3(1.6, 1.4, 1.4), RAIL, Vector3(0, tall - 0.6, 1.1))       # the cab
	LowPoly.cylinder(crane, 0.0, 0.5, 3.0, CRANE, Vector3(0, tall + 2.3, 0))
	LowPoly.box(crane, Vector3(0.04, 9.0, 0.04), DARK, Vector3(-15.0, tall - 4.5, 0))   # the hook's cable
	LowPoly.box(crane, Vector3(0.5, 0.5, 0.5), Color(0.9, 0.3, 0.1, 1), Vector3(-15.0, tall - 9.0, 0))
	LowPoly.solid_box(crane, Vector3(3.0, tall, 3.0), Vector3(0, tall * 0.5, 0))
	var middle := area.get_center()
	for i in 3:
		LowPoly.box(holder, Vector3(2.4, 2.5, 6.0), [TEAL, Color(0.75, 0.3, 0.2, 1), Color(0.3, 0.45, 0.6, 1)][i],
				Vector3(middle.x + 10.0, 1.25 + (2.5 if i == 2 else 0.0), middle.y - 8.0 + (i % 2) * 2.5))
	for i in 2:
		LowPoly.cylinder(holder, 0.0, 3.0, 2.0, SAND, Vector3(middle.x - 8.0 + i * 5.0, 1.0, middle.y + 10.0))
	for i in 2:
		var worker := PeopleLooks.resident(4, i)
		worker.name = "SiteWorker%d" % i
		worker.position = Vector3(middle.x - 4 + i * 3, 0, middle.y - 4)
		holder.add_child(worker)
	var sign_data: Dictionary = site["sign"]
	_free_sign(holder, sign_data["arabic"], sign_data["name"], sign_data["position"], sign_data["facing"],
			Vector2(6.0, 2.0), Color(0.9, 0.45, 0.1, 1))


## A drop-off spot's little building: the school security booth or the stable office.
func _build_spot(place: Dictionary) -> void:
	var size: Vector3 = place["size"]
	var booth: bool = place.get("look", "") == "booth"
	var body := _solid_block(self, place["position"], size, RAIL if booth else WOOD.lightened(0.3))
	body.name = "SchoolBooth" if booth else "StableOffice"
	body.rotation_degrees.y = place["facing"]
	var front := size.z * 0.5
	LowPoly.box(body, Vector3(size.x + 0.6, 0.2, size.z + 0.6), TEAL if booth else WOOD, Vector3(0, size.y + 0.1, 0.2))
	LowPoly.box(body, Vector3(0.9, 2.1, 0.1), DARK, Vector3(-size.x * 0.25, 1.05, front + 0.05))
	LowPoly.box(body, Vector3(size.x * 0.35, 0.9, 0.1), GLASS, Vector3(size.x * 0.22, 1.5, front + 0.05))
	var english := "Security" if booth else "Stable Office"
	var arabic := "الأمن" if booth else "مكتب الإسطبل"
	var board := Vector3(size.x - 0.2, 0.7, 0.12)
	LowPoly.box(body, board, TEAL if booth else Color(0.3, 0.45, 0.25, 1), Vector3(0, size.y - 0.65, front + 0.12))
	var font := SignText.fit_size(arabic, english, 48, board.x - 0.3)
	var face := SignText.make_face(arabic, english, font, TEXT)
	face.position = Vector3(0, size.y - 0.65, front + 0.19)
	body.add_child(face)


## A fence all round an area. gate: a gap in the north side, from x to y (Vector2.ZERO = no gap).
## panels = true: tall solid boards (a building-site hoarding) instead of posts and rails.
func _fence_box(parent: Node3D, area: Rect2, colour: Color, height: float, gate := Vector2.ZERO,
		panels := false) -> void:
	var a := area.position
	var b := Vector2(area.end.x, area.position.y)
	var c := area.end
	var d := Vector2(area.position.x, area.end.y)
	var sides := [[b, c], [c, d], [d, a]]
	if gate == Vector2.ZERO:
		sides.append([a, b])
	else:
		sides.append([a, Vector2(gate.x, a.y)])
		sides.append([Vector2(gate.y, a.y), b])
	for side in sides:
		var fence := Props.fence(parent, side[0], side[1], height, colour)
		if panels:
			LowPoly.box(fence, Vector3(0.1, height - 0.2, side[0].distance_to(side[1])), colour, Vector3(0, height * 0.5, 0))


## A box-shaped building that the bike bumps into. spot: the middle of its floor.
func _solid_block(parent: Node3D, spot: Vector3, size: Vector3, colour: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = spot
	parent.add_child(body)
	LowPoly.box(body, size, colour, Vector3(0, size.y * 0.5, 0))
	LowPoly.solid_box(body, size, Vector3(0, size.y * 0.5, 0))
	return body


## A free-standing sign on two posts, readable from both sides.
func _free_sign(parent: Node3D, arabic: String, english: String, spot: Vector3, facing: float,
		board: Vector2, colour: Color) -> void:
	var holder := StaticBody3D.new()
	holder.position = spot
	holder.rotation_degrees.y = facing
	parent.add_child(holder)
	var y := 1.4 + board.y * 0.5
	LowPoly.box(holder, Vector3(board.x, board.y, 0.2), colour, Vector3(0, y, 0))
	for x in [-board.x * 0.4, board.x * 0.4]:
		LowPoly.box(holder, Vector3(0.18, y, 0.18), RAIL, Vector3(x, y * 0.5, 0))
		LowPoly.solid_box(holder, Vector3(0.25, y + 1.0, 0.25), Vector3(x, (y + 1.0) * 0.5, 0))
	_faces(holder, arabic, english, Vector3(0, y, 0), 0.0, board.x - 0.4, 0.2)


## Sign text on both sides of a board. facing: which way the board's front points.
func _faces(parent: Node3D, arabic: String, english: String, spot: Vector3, facing: float,
		width: float, thickness: float) -> void:
	var font := SignText.fit_size(arabic, english, 72, width)
	var faces := SignText.make_two_faces(arabic, english, font, TEXT, thickness)
	faces.position = spot
	faces.rotation_degrees.y = facing
	parent.add_child(faces)
