class_name SpotBuildings
extends RefCounted
## Looks pass Session 57: the two small drop-off buildings (VILLAS "kind": "spot"), built by
## LandmarkBuilder. The front is local +Z; the drop-off is in front of it, as before.
##   office()  the stable office: plank walls, an open wooden door, a big front window, the
##             groom at his desk, saddles on stands, rosettes and horse photos, riding
##             helmets on hooks, a hay bale and a back window onto the stable block
##   booth()   the school gate's glass security booth with the guard at his desk and a
##             red and white barrier (raised)

const WOOD := Color(0.55, 0.36, 0.2)
const PLANK := Color(0.66, 0.46, 0.28)
const DARK_WOOD := Color(0.36, 0.23, 0.13)
const STRAW := Color(0.9, 0.78, 0.45)
const LEATHER := Color(0.42, 0.24, 0.12)
const WHITE := Color(0.95, 0.95, 0.93)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const RED := Color(0.85, 0.15, 0.12)
const DRAW_PEOPLE := 80.0


static func office(place: Dictionary) -> StaticBody3D:
	var size: Vector3 = place["size"]
	var body := StaticBody3D.new()
	body.name = "StableOffice"
	body.position = place["position"]
	body.rotation_degrees.y = place["facing"]
	body.set_meta("interior_style", "stable_office")
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var t := 0.15
	# Plank walls: back, sides, and the front with a doorway and a big window.
	# The back wall, round a window onto the stable block and its horses.
	var win := Rect2(-0.1, 1.3, 2.6, 1.2)  # x from, y from, width, height
	VenueParts.block(body, Vector3(win.position.x + hx, size.y, t), PLANK, Vector3((-hx + win.position.x) * 0.5, size.y * 0.5, -hz))
	VenueParts.block(body, Vector3(hx - win.end.x, size.y, t), PLANK, Vector3((win.end.x + hx) * 0.5, size.y * 0.5, -hz))
	VenueParts.block(body, Vector3(win.size.x, win.position.y, t), PLANK, Vector3(win.get_center().x, win.position.y * 0.5, -hz))
	VenueParts.block(body, Vector3(win.size.x, size.y - win.end.y, t), PLANK, Vector3(win.get_center().x, (win.end.y + size.y) * 0.5, -hz))
	var back := RoomProps.pane(body, Vector3(win.size.x, win.size.y, 0.04), Vector3(win.get_center().x, win.get_center().y, -hz))
	back.name = "PaddockWindow"
	LowPoly.solid_box(body, Vector3(win.size.x, win.size.y, t), Vector3(win.get_center().x, win.get_center().y, -hz))
	for side in [-1.0, 1.0]:
		VenueParts.block(body, Vector3(t, size.y, size.z), PLANK, Vector3(side * hx, size.y * 0.5, 0))
	var door_from := -hx + 0.9
	var door_to := door_from + 1.2
	var window_from := -0.2
	var window_to := hx - 0.5
	VenueParts.block(body, Vector3(door_from + hx, size.y, t), PLANK, Vector3((-hx + door_from) * 0.5, size.y * 0.5, hz))
	VenueParts.block(body, Vector3(window_from - door_to, size.y, t), PLANK, Vector3((door_to + window_from) * 0.5, size.y * 0.5, hz))
	VenueParts.block(body, Vector3(hx - window_to, size.y, t), PLANK, Vector3((window_to + hx) * 0.5, size.y * 0.5, hz))
	VenueParts.block(body, Vector3(door_to - door_from, size.y - 2.3, t), PLANK, Vector3((door_from + door_to) * 0.5, 2.3 + (size.y - 2.3) * 0.5, hz))
	var wide := window_to - window_from
	VenueParts.block(body, Vector3(wide, 0.95, t), PLANK, Vector3((window_from + window_to) * 0.5, 0.475, hz))
	VenueParts.block(body, Vector3(wide, size.y - 2.5, t), PLANK, Vector3((window_from + window_to) * 0.5, 2.5 + (size.y - 2.5) * 0.5, hz))
	var window := RoomProps.pane(body, Vector3(wide, 1.55, 0.04), Vector3((window_from + window_to) * 0.5, 1.725, hz))
	window.name = "FrontWindow"
	LowPoly.solid_box(body, Vector3(wide, 1.55, 0.15), Vector3((window_from + window_to) * 0.5, 1.725, hz))
	LowPoly.box(body, Vector3(wide + 0.1, 0.08, 0.3), DARK_WOOD, Vector3((window_from + window_to) * 0.5, 0.96, hz + 0.05))
	# Darker plank lines on the outside walls.
	for y in range(1, int(size.y / 0.5)):
		LowPoly.box(body, Vector3(size.x + 0.04, 0.03, 0.03), DARK_WOOD, Vector3(0, y * 0.5, -hz - 0.08))
		for side in [-1.0, 1.0]:
			LowPoly.box(body, Vector3(0.03, 0.03, size.z + 0.04), DARK_WOOD, Vector3(side * (hx + 0.08), y * 0.5, 0))
	# A sloping roof with an overhang, and a little porch over the door.
	var roof := LowPoly.box(body, Vector3(size.x + 0.8, 0.18, size.z + 1.0), DARK_WOOD, Vector3(0, size.y + 0.2, 0.2))
	roof.rotation.x = deg_to_rad(-6.0)
	LowPoly.box(body, Vector3(size.x - 0.3, 0.1, size.z - 0.3), Color(0.92, 0.88, 0.8), Vector3(0, size.y - 0.05, 0))
	LowPoly.box(body, Vector3(2.0, 0.1, 1.4), DARK_WOOD, Vector3((door_from + door_to) * 0.5, 2.6, hz + 0.7))
	for x in [door_from - 0.3, door_to + 0.3]:
		LowPoly.box(body, Vector3(0.1, 2.6, 0.1), DARK_WOOD, Vector3(x, 1.3, hz + 1.3))
	# The wooden door, open outwards against the porch.
	var hinge := Node3D.new()
	hinge.name = "WoodenDoor"
	hinge.position = Vector3(door_from, 0, hz + 0.08)
	hinge.rotation_degrees.y = -100.0
	body.add_child(hinge)
	LowPoly.box(hinge, Vector3(1.15, 2.2, 0.06), WOOD, Vector3(0.58, 1.12, 0))
	for y in [0.5, 1.12, 1.75]:
		LowPoly.box(hinge, Vector3(1.05, 0.08, 0.08), DARK_WOOD, Vector3(0.58, y, 0.03))
	LowPoly.sphere(hinge, 0.04, 0.08, Color(0.85, 0.7, 0.3), Vector3(1.0, 1.05, 0.07))
	# Wooden plank floor.
	var floor_view := LowPoly.box(body, Vector3(size.x - 0.3, 0.05, size.z - 0.3), Color.WHITE, Vector3(0, 0.025, 0))
	floor_view.material_override = RoomProps.floor_material(Color(0.62, 0.44, 0.27), Color(0.52, 0.35, 0.2), "planks", 0.6, Vector2(size.x, size.z))
	_office_inside(body, size)
	var light := VenueParts.room_light(body, "OfficeLight", Vector3(0, size.y - 0.6, 0), 1.0, 7.0, false, Color(1, 0.85, 0.6))
	light.distance_fade_begin = 30.0
	RoomProps.pendant_lamp(body, Vector3(0.8, 0, -0.8), DARK_WOOD, size.y - 0.1)
	Props.bake_kits(body)
	_people_near(body)
	return body


static func _office_inside(body: StaticBody3D, size: Vector3) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	# The groom at his desk, facing the door.
	var desk_at := Vector3(1.6, 0, -1.4)
	VenueParts.block(body, Vector3(1.8, 0.78, 0.8), WOOD, desk_at + Vector3(0, 0.39, 0))
	LowPoly.box(body, Vector3(1.9, 0.05, 0.9), DARK_WOOD, desk_at + Vector3(0, 0.8, 0))
	LowPoly.box(body, Vector3(0.4, 0.03, 0.3), WHITE, desk_at + Vector3(-0.4, 0.84, 0.1))  # papers
	LowPoly.box(body, Vector3(0.3, 0.06, 0.22), Color(0.2, 0.35, 0.25), desk_at + Vector3(0.3, 0.86, 0.1))  # the ledger
	LowPoly.cylinder(body, 0.05, 0.04, 0.1, Color(0.95, 0.95, 0.9), desk_at + Vector3(0.65, 0.88, -0.1))  # a mug
	Props.kit("furniture/chair_A_wood", body, desk_at + Vector3(0, 0.05, -0.8), 0.0, 0.7)
	var groom := PlaceLooks.groom()
	groom.name = "OfficeGroom"
	groom.rotation.y = PI  # faces the door (+Z)
	var hips := groom.spot("Hips")
	groom.position = desk_at + Vector3(0, 0.5, -0.75) - groom.basis * hips
	body.add_child(groom)
	groom.play("sit")
	# Two saddles on wooden stands.
	for i in 2:
		var at := Vector3(-hx + 0.8, 0, -1.8 + i * 1.4)
		var stand := Node3D.new()
		stand.name = "SaddleStand%d" % i
		stand.position = at
		body.add_child(stand)
		for z in [-0.3, 0.3]:
			LowPoly.box(stand, Vector3(0.5, 0.85, 0.06), DARK_WOOD, Vector3(0, 0.43, z))
		LowPoly.box(stand, Vector3(0.12, 0.08, 0.7), DARK_WOOD, Vector3(0, 0.88, 0))
		var saddle := LowPoly.sphere(stand, 0.32, 0.25, LEATHER if i == 0 else Color(0.2, 0.12, 0.08), Vector3(0, 0.98, 0))
		saddle.scale = Vector3(1.0, 1.0, 1.4)
		LowPoly.box(stand, Vector3(0.08, 0.2, 0.3), LEATHER.lightened(0.15), Vector3(0, 1.08, -0.3))  # the pommel
		for side in [-1.0, 1.0]:
			LowPoly.box(stand, Vector3(0.02, 0.45, 0.05), Color(0.25, 0.15, 0.08), Vector3(side * 0.33, 0.73, 0))
			LowPoly.box(stand, Vector3(0.1, 0.03, 0.1), Color(0.75, 0.75, 0.78), Vector3(side * 0.33, 0.5, 0))  # stirrup
		LowPoly.solid_box(body, Vector3(0.7, 1.1, 0.8), at + Vector3(0, 0.55, 0))
	# Rosettes (prize ribbons) and horse photos on the back wall.
	var colours := [Color(0.15, 0.35, 0.8), RED, Color(0.95, 0.75, 0.15), Color(0.2, 0.6, 0.35)]
	for i in 4:
		var at := Vector3(-2.6 + i * 0.55, 2.7, -hz + 0.1)
		var rosette := LowPoly.cylinder(body, 0.13, 0.13, 0.03, colours[i], at)
		rosette.rotation.x = PI * 0.5
		rosette.name = "Rosette%d" % i
		var middle := LowPoly.cylinder(body, 0.06, 0.06, 0.035, Color(0.98, 0.95, 0.85), at + Vector3(0, 0, 0.01))
		middle.rotation.x = PI * 0.5
		for side in [-0.04, 0.04]:
			LowPoly.box(body, Vector3(0.05, 0.25, 0.01), colours[i], at + Vector3(side, -0.22, 0.01))
	for i in 3:
		var at := Vector3(-2.3 + i * 0.85, 1.75, -hz + 0.1)
		if i == 2:
			at = Vector3(hx - 0.1, 1.9, 1.2)
		var photo := Node3D.new()
		photo.name = "HorsePhoto%d" % i
		photo.position = at
		photo.rotation_degrees.y = -90.0 if i == 2 else 0.0
		body.add_child(photo)
		LowPoly.box(photo, Vector3(0.62, 0.48, 0.03), DARK_WOOD, Vector3.ZERO)
		LowPoly.box(photo, Vector3(0.52, 0.38, 0.02), Color(0.6, 0.78, 0.55), Vector3(0, 0, 0.01))
		var coat: Color = [Color(0.45, 0.28, 0.15), Color(0.85, 0.82, 0.78), Color(0.2, 0.15, 0.12)][i]
		LowPoly.box(photo, Vector3(0.24, 0.1, 0.01), coat, Vector3(0, -0.02, 0.025))  # body
		var neck := LowPoly.box(photo, Vector3(0.05, 0.14, 0.01), coat, Vector3(0.12, 0.07, 0.025))
		neck.rotation.z = -0.5
		LowPoly.box(photo, Vector3(0.09, 0.05, 0.01), coat, Vector3(0.17, 0.13, 0.025))  # head
		for x in [-0.09, -0.04, 0.05, 0.1]:
			LowPoly.box(photo, Vector3(0.02, 0.1, 0.01), coat, Vector3(x, -0.12, 0.025))  # legs
	# Riding helmets on hooks by the door.
	for i in 3:
		var at := Vector3(hx - 0.15, 1.7, 1.6 + i * 0.45 - 0.9)
		LowPoly.box(body, Vector3(0.1, 0.03, 0.03), Color(0.75, 0.75, 0.78), at + Vector3(-0.05, 0.12, 0))
		var helmet := LowPoly.sphere(body, 0.14, 0.17, [Color(0.1, 0.1, 0.12), Color(0.15, 0.2, 0.4), Color(0.3, 0.22, 0.15)][i], at + Vector3(-0.15, 0, 0))
		helmet.name = "RidingHelmet%d" % i
	# A hay bale by the door.
	var bale := VenueParts.block(body, Vector3(1.0, 0.5, 0.6), STRAW, Vector3(-hx + 0.8, 0.3, hz - 1.3))
	bale.name = "HayBale"
	for x in [-0.25, 0.25]:
		LowPoly.box(body, Vector3(0.03, 0.52, 0.62), Color(0.75, 0.3, 0.15), Vector3(-hx + 0.8 + x, 0.3, hz - 1.3))


static func booth(place: Dictionary) -> StaticBody3D:
	var size: Vector3 = place["size"]
	var body := StaticBody3D.new()
	body.name = "SchoolBooth"
	body.position = place["position"]
	body.rotation_degrees.y = place["facing"]
	body.set_meta("interior_style", "glass_booth")
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	LowPoly.solid_box(body, size, Vector3(0, size.y * 0.5, 0))
	LowPoly.box(body, Vector3(size.x + 0.3, 0.15, size.z + 0.3), Color(0.7, 0.7, 0.72), Vector3(0, 0.075, 0))
	# White panels at the bottom, glass all round above, white corner posts.
	for side in [-1.0, 1.0]:
		LowPoly.box(body, Vector3(size.x, 0.9, 0.1), WHITE, Vector3(0, 0.6, side * hz))
		LowPoly.box(body, Vector3(0.1, 0.9, size.z), WHITE, Vector3(side * hx, 0.6, 0))
		RoomProps.pane(body, Vector3(size.x - 0.2, size.y - 1.15, 0.05), Vector3(0, 1.05 + (size.y - 1.15) * 0.5, side * hz))
		RoomProps.pane(body, Vector3(0.05, size.y - 1.15, size.z - 0.2), Vector3(side * hx, 1.05 + (size.y - 1.15) * 0.5, 0))
		for other in [-1.0, 1.0]:
			LowPoly.box(body, Vector3(0.14, size.y, 0.14), WHITE, Vector3(side * hx, size.y * 0.5, other * hz))
	LowPoly.box(body, Vector3(size.x - 0.1, 0.05, size.z - 0.1), Color(0.55, 0.55, 0.58), Vector3(0, 0.175, 0))
	# The door outline on the side.
	LowPoly.box(body, Vector3(0.03, 2.1, 0.06), Color(0.3, 0.3, 0.32), Vector3(-hx - 0.03, 1.2, 0.5))
	LowPoly.box(body, Vector3(0.03, 2.1, 0.06), Color(0.3, 0.3, 0.32), Vector3(-hx - 0.03, 1.2, -0.5))
	# Inside: the desk with a screen, and the guard.
	LowPoly.box(body, Vector3(size.x - 0.5, 0.08, 0.7), Color(0.85, 0.85, 0.85), Vector3(0, 0.95, hz - 0.5))
	LowPoly.box(body, Vector3(size.x - 0.5, 0.75, 0.05), Color(0.6, 0.6, 0.62), Vector3(0, 0.55, hz - 0.2))
	var screen := LowPoly.box(body, Vector3(0.5, 0.32, 0.04), Color(0.3, 0.75, 0.9), Vector3(-0.6, 1.25, hz - 0.65))
	screen.material_override = VenueParts.glow(Color(0.3, 0.75, 0.9), 1.0)
	LowPoly.box(body, Vector3(0.06, 0.25, 0.06), Color(0.2, 0.2, 0.22), Vector3(-0.6, 1.05, hz - 0.68))
	LowPoly.box(body, Vector3(0.3, 0.04, 0.12), Color(0.2, 0.2, 0.22), Vector3(0.3, 1.0, hz - 0.45))  # a phone
	var guard := Person.new()
	guard.paint({"skin": PeopleLooks.SKINS[3], "shirt": Color(0.12, 0.17, 0.3), "pants": Color(0.12, 0.13, 0.18)})
	PeopleLooks.cap(guard, Color(0.12, 0.17, 0.3), guard)
	PeopleLooks.shoes(guard, Color(0.05, 0.05, 0.05))
	guard.name = "Guard"
	guard.position = Vector3(0.2, 0.2, -0.3)
	guard.rotation.y = PI  # looking out at the road (+Z)
	body.add_child(guard)
	# The roof with an overhang and the sign (LandmarkBuilder adds the sign).
	LowPoly.box(body, Vector3(size.x + 1.2, 0.25, size.z + 1.2), TEAL, Vector3(0, size.y + 0.12, 0.2))
	var light := VenueParts.room_light(body, "BoothLight", Vector3(0, size.y - 0.4, 0), 0.8, 5.0)
	light.distance_fade_begin = 30.0
	# The barrier beside the booth: a striped arm, raised so the gate stays open.
	var barrier := Node3D.new()
	barrier.name = "GateBarrier"
	barrier.position = Vector3(hx + 0.45, 0, hz - 0.3)
	body.add_child(barrier)
	LowPoly.box(barrier, Vector3(0.35, 1.0, 0.35), Color(0.95, 0.8, 0.15), Vector3(0, 0.5, 0))
	LowPoly.solid_box(body, Vector3(0.35, 1.0, 0.35), barrier.position + Vector3(0, 0.5, 0))
	var arm := Node3D.new()
	arm.name = "Arm"
	arm.position = Vector3(0, 0.95, 0)
	arm.rotation.z = deg_to_rad(80.0)  # raised
	barrier.add_child(arm)
	for i in 6:
		LowPoly.box(arm, Vector3(0.5, 0.1, 0.08), RED if i % 2 == 0 else WHITE, Vector3(0.25 + i * 0.5, 0, 0))
	_people_near(body)
	return body


## People in these small buildings are only drawn when you're fairly close.
static func _people_near(body: Node3D) -> void:
	for person in body.get_children():
		if person is Person:
			for part: MeshInstance3D in person.find_children("*", "MeshInstance3D", true, false):
				part.visibility_range_end = DRAW_PEOPLE
