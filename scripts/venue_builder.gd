class_name VenueBuilder
extends RefCounted
## Walk-in rooms. The counter target is a standing point on the customer's side,
## separate from both the parked-bike approach and the doorway.

const CREAM := Color(0.95, 0.9, 0.8)
const GLASS := Color(0.46, 0.7, 0.77)
const WOOD := Color(0.53, 0.33, 0.19)
const DARK := Color(0.08, 0.16, 0.18)

static func counter_local(size: Vector3) -> Vector3:
	return Vector3(0, 0, -size.z * 0.15 + 1.8)


## Sessions 60-61: where you stand at this place's desk. A place in the data can give its own
## "counter" spot (the gym and the C Institute have their reception by the door).
static func counter_of(place: Dictionary, size: Vector3) -> Vector3:
	var own := place.has("counter")
	if place.get("number", 0) == 903 and not GameConfig.INSTITUTE_LOBBY_ON:
		own = false   # the old lobby keeps its old counter
	if place.get("number", 0) == 904 and not GameConfig.GYM_ROOM_ON:
		own = false
	return place["counter"] if own else counter_local(size)


static func world_point(place: Dictionary, local: Vector3) -> Vector3:
	return place["position"] + local.rotated(Vector3.UP, deg_to_rad(place.get("facing", 0.0)))


static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	# Sessions 60-61: the real gym and the C Institute lobby are built by their own scripts.
	if place.get("venue_type", "") == "gym" and GameConfig.GYM_ROOM_ON:
		return GymRoom.build(place, size)
	if place.get("venue_type", "") == "institute" and GameConfig.INSTITUTE_LOBBY_ON:
		return InstituteLobby.build(place, size)
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", place.get("venue_type", "reception"))
	var tint: Color = place.get("colour", Color(0.16, 0.56, 0.61))
	var rounded: bool = place.get("venue_type", "") == "gym"
	# Solid shell with a four-metre doorway; no invisible box filling the room.
	var see_through: bool = place.get("venue_type", "") == "institute"
	if rounded:
		_rounded_back(body, size)
	elif see_through:
		# Session 52: the C Institute has big windows on the back too, so you see right through.
		for side in [-1.0, 1.0]:
			var wing := size.x * 0.5 - 2.0
			var back_window := _block(body, Vector3(wing, size.y, 0.25), GLASS,
				Vector3(side * (2.0 + wing * 0.5), size.y * 0.5, -size.z * 0.5))
			var clear := LowPoly.material(GLASS).duplicate() as StandardMaterial3D
			clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			clear.albedo_color.a = 0.24
			back_window.material_override = clear
			back_window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_block(body, Vector3(4, size.y, 0.25), CREAM, Vector3(0, size.y * 0.5, -size.z * 0.5))
	else:
		_block(body, Vector3(size.x, size.y, 0.25), CREAM, Vector3(0, size.y * 0.5, -size.z * 0.5))
	# Session 57: a Plaza shop (it has a "row") gets the new low shop front (ShopFront).
	var plaza_front: bool = GameConfig.PLAZA_LOOKS_PASS and place.has("row")
	for side in [-1.0, 1.0]:
		_block(body, Vector3(0.25, size.y, size.z - (4 if rounded else 0)), CREAM, Vector3(side * size.x * 0.5, size.y * 0.5, 2 if rounded else 0))
		if plaza_front:
			continue
		var wing := size.x * 0.5 - 2.0
		var window := _block(body, Vector3(wing, size.y, 0.25), GLASS,
			Vector3(side * (2.0 + wing * 0.5), size.y * 0.5, size.z * 0.5))
		var glass := LowPoly.material(GLASS).duplicate() as StandardMaterial3D
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.albedo_color.a = 0.24
		window.material_override = glass
		window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not plaza_front:
		_block(body, Vector3(4, size.y - 3.2, 0.25), tint, Vector3(0, 3.2 + (size.y - 3.2) * 0.5, size.z * 0.5))
	LowPoly.box(body, Vector3(size.x, 0.06, size.z), Color(0.83, 0.78, 0.68), Vector3(0, 0.03, 0))
	_block(body, Vector3(size.x + 0.2, 0.25, size.z + 0.2 - (4 if rounded else 0)), CREAM, Vector3(0, size.y + 0.12, 2 if rounded else 0))
	# The counter is behind its standing target. Clear central circulation stays open.
	var back := -size.z * 0.15
	_block(body, Vector3(minf(size.x * 0.55, 10), 1.05, 0.9), tint, Vector3(0, 0.525, back))
	LowPoly.box(body, Vector3(minf(size.x * 0.58, 10.4), 0.08, 1.1), WOOD, Vector3(0, 1.09, back))
	var staff := PeopleLooks.resident(2, 1)
	staff.name = "CounterStaff"
	staff.position = Vector3(0, 0, back - 1.2)
	staff.rotation.y = PI
	body.add_child(staff)
	if plaza_front:
		ShopFront.build(body, place, size)
	else:
		_old_front(body, place, size, tint)
	if not see_through:
		LowPoly.box(body, Vector3(5.4, 2.1, 0.12), DARK, Vector3(0, 3.0, -size.z * 0.5 + 0.1))
		var menu := SignText.make_face("القائمة", place.get("food", "Welcome").capitalize(), 70, Color.WHITE)
		menu.name = "MenuBoard"
		menu.position = Vector3(0, 2.8, -size.z * 0.5 + 0.2)
		body.add_child(menu)
	var light := OmniLight3D.new()
	light.name = "InteriorLight"
	light.position = Vector3(0, 4, 0)
	light.light_color = Color(1.0, 0.88, 0.7)
	light.light_energy = 2.0
	light.omni_range = maxf(15.0, size.z)
	light.shadow_enabled = false
	body.add_child(light)
	var reception: bool = place.get("venue_type", "") in ["institute", "gym"]
	for side in [-1.0, 1.0]:
		_table(body, Vector3(side * minf(size.x * 0.3, 6.0), 0, size.z * 0.2), tint, not reception)
		_planter(body, Vector3(side * (size.x * 0.5 - 0.8), 0, size.z * 0.5 - 1.0))
		if not reception and not plaza_front:   # Session 57: ShopFront puts its own tables and bench outside
			# Session 53: sit with your back to the shop, looking out at the Plaza (they faced the glass).
			Props.bench(body, Vector3(side * 5.0, 0, size.z * 0.5 + 2), 0)
	_decor(body, place.get("venue_type", ""), size, tint)
	return body


## The front before Session 57 (the C Institute and the gym still use it): a sign, a
## board and an awning across the top of a tall glass front.
static func _old_front(body: StaticBody3D, place: Dictionary, size: Vector3, tint: Color) -> void:
	var sign := SignText.make_face(place.get("arabic", ""), place.get("name", "Reception"), 46, Color.WHITE)
	sign.name = "BilingualSign"
	sign.position = Vector3(0, 4.5, size.z * 0.5 + 0.16)
	body.add_child(sign)
	var kind: String = place.get("venue_type", "")
	if kind in ["gelato", "boba", "tacos"]:
		var board := LowPoly.cylinder(body, 1.4, 1.4, 0.16, tint, Vector3(0, 4.5, size.z * 0.5 + 0.03))
		board.rotation.x = PI * 0.5
	else:
		LowPoly.box(body, Vector3(minf(size.x - 1, 14), 1.5, 0.16), tint.darkened(0.15), Vector3(0, 4.5, size.z * 0.5 + 0.03))
	var awning := LowPoly.box(body, Vector3(size.x + 0.5, 0.18, 2.2), tint, Vector3(0, 3.25, size.z * 0.5 + 0.8))
	awning.rotation.x = 0.12


static func _rounded_back(body: StaticBody3D, size: Vector3) -> void:
	body.set_meta("rounded_back", true)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(0, size.y + 0.25, -size.z * 0.5 + 4)
	for i in 24:
		var a := PI * i / 24
		var b := PI * (i + 1) / 24
		var p := Vector3(cos(a) * size.x * 0.5, 0, -sin(a) * 4) + Vector3(0, 0, center.z)
		var q := Vector3(cos(b) * size.x * 0.5, 0, -sin(b) * 4) + Vector3(0, 0, center.z)
		var panel := _block(body, Vector3(p.distance_to(q) + 0.1, size.y, 0.25), CREAM, (p + q) * 0.5 + Vector3.UP * size.y * 0.5)
		panel.rotation.y = -atan2(q.z - p.z, q.x - p.x)
		var collision := body.get_child(body.get_child_count() - 1) as CollisionShape3D
		collision.rotation.y = panel.rotation.y
		for corner in [center, q + Vector3.UP * center.y, p + Vector3.UP * center.y]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corner)
	var cap := MeshInstance3D.new()
	cap.mesh = tool.commit()
	cap.material_override = LowPoly.material(CREAM)
	body.add_child(cap)


static func _block(parent: StaticBody3D, size: Vector3, tint: Color, at: Vector3) -> MeshInstance3D:
	var view := LowPoly.box(parent, size, tint, at)
	LowPoly.solid_box(parent, size, at)
	return view


static func _table(parent: StaticBody3D, at: Vector3, tint: Color, occupied: bool) -> void:
	_block(parent, Vector3(1.6, 0.1, 1.2), WOOD, at + Vector3(0, 0.8, 0))
	LowPoly.cylinder(parent, 0.08, 0.12, 0.75, DARK, at + Vector3(0, 0.38, 0))
	for side in [-1.0, 1.0]:
		LowPoly.box(parent, Vector3(0.6, 0.08, 0.6), tint, at + Vector3(0, 0.43, side))
		LowPoly.box(parent, Vector3(0.6, 0.65, 0.08), tint, at + Vector3(0, 0.7, side * 1.25))
	if occupied:
		var customer := PeopleLooks.resident(3, 2)
		customer.name = "SeatedCustomer"
		customer.position = at + Vector3(0, -0.45, -1.0)
		customer.rotation.y = PI
		parent.add_child(customer)
		if customer.can_do("sit"):
			customer.play("sit")


static func _planter(parent: Node3D, at: Vector3) -> void:
	LowPoly.cylinder(parent, 0.4, 0.28, 0.6, WOOD, at + Vector3.UP * 0.3)
	LowPoly.sphere(parent, 0.55, 1.4, Color(0.28, 0.55, 0.26), at + Vector3.UP * 1.1)


static func _decor(body: StaticBody3D, kind: String, size: Vector3, tint: Color) -> void:
	var at := Vector3(-size.x * 0.3, 0, -size.z * 0.32)
	var holder := Node3D.new()
	holder.name = kind.capitalize().replace(" ", "") + "Decor"
	holder.position = at
	body.add_child(holder)
	var motion := VenueMotion.new()
	holder.add_child(motion)
	match kind:
		"pizza", "bakery":
			LowPoly.sphere(holder, 1.7, 2.7, Color(0.63, 0.29, 0.18), Vector3(0, 1.0, 0))
			LowPoly.box(holder, Vector3(1.5, 0.8, 0.15), DARK, Vector3(0, 0.9, 1.55))
			LowPoly.sphere(holder, 0.3, 0.6, Color(1, 0.52, 0.1), Vector3(0, 0.8, 1.65))
			if kind == "bakery":
				LowPoly.box(holder, Vector3(3, 1.4, 1.1), GLASS, Vector3(5, 0.7, 0))
				for i in 4:
					LowPoly.cylinder(holder, 0.24, 0.24, 0.24, Color(1, 0.76, 0.84), Vector3(4 + i * 0.65, 1.5, 0))
		"gelato":
			LowPoly.box(holder, Vector3(4, 1.0, 1.2), GLASS, Vector3(1, 0.5, 0))
			for i in 5:
				LowPoly.sphere(holder, 0.32, 0.35, [Color.PINK, Color(1, 0.96, 0.83), Color.SADDLE_BROWN, Color.PALE_GREEN, Color.ORANGE][i], Vector3(-0.5 + i * 0.72, 1.04, 0))
		"boba":
			for i in 6:
				LowPoly.cylinder(holder, 0.18, 0.18, 0.7, tint.lightened(i * 0.06), Vector3(i * 0.6, 1.5, 0))
				LowPoly.box(holder, Vector3(0.08, 0.1, 0.25), DARK, Vector3(i * 0.6, 1.5, 0.2))
		"shawarma":
			var spit := LowPoly.cylinder(holder, 0.4, 0.6, 1.6, Color(0.55, 0.29, 0.12), Vector3(0, 1.4, 0))
			spit.set_meta("static_batch_dynamic", true)
			motion.spit = spit
			LowPoly.cylinder(holder, 0.06, 0.06, 2.5, DARK, Vector3(0, 1.4, 0))
		"market":
			for i in 3:
				LowPoly.box(holder, Vector3(1.3, 2.8, 0.7), GLASS, Vector3(i * 1.5, 1.4, 0))
				for y in [0.6, 1.3, 2.0]:
					LowPoly.box(holder, Vector3(1.2, 0.08, 0.8), Color.WHITE, Vector3(i * 1.5, y, 0))
		"thai":
			for i in 3:
				LowPoly.sphere(holder, 0.45, 0.18, DARK, Vector3(i * 1.3, 1.1, 0))
				LowPoly.sphere(holder, 0.5, 0.9, Color(0.9, 0.2, 0.1), Vector3(i * 1.3, 3.3, 0))
		"sushi":
			LowPoly.box(holder, Vector3(4.8, 0.8, 1.1), WOOD, Vector3(1.5, 0.4, 0))
			LowPoly.box(holder, Vector3(4.8, 0.08, 0.7), DARK, Vector3(1.5, 0.85, 0))
			for i in 6:
				var plate := LowPoly.cylinder(holder, 0.18, 0.18, 0.07, Color.WHITE, Vector3(-0.5 + i * 0.75, 0.94, 0))
				plate.set_meta("static_batch_dynamic", true)
				motion.plates.append(plate)
		"tacos":
			for x in 6:
				for y in 3:
					LowPoly.box(holder, Vector3(0.6, 0.5, 0.05), [tint, Color.ORANGE, Color.TEAL][(x + y) % 3], Vector3(x * 0.63, 1.6 + y * 0.53, -0.6))
		"burger":
			LowPoly.box(holder, Vector3(3.5, 1, 1.2), DARK, Vector3(1, 0.5, 0))
			for i in 12:
				LowPoly.box(holder, Vector3(0.04, 0.04, 1.1), Color.GRAY, Vector3(-0.5 + i * 0.27, 1.03, 0))
			var neon := SignText.make_face("", "BURGEROLOGY", 40, Color(1, 0.4, 0.25))
			neon.position = Vector3(1, 2.7, -0.5)
			holder.add_child(neon)
		"gym":
			for i in 5:
				LowPoly.box(holder, Vector3(0.9, 0.15, 2), DARK, Vector3(i * 1.6, 0.15, 0))
				LowPoly.box(holder, Vector3(0.9, 1.2, 0.12), GLASS, Vector3(i * 1.6, 0.7, -1))
		"institute":
			for i in 3:
				_planter(holder, Vector3(i * 3.0, 0, 0))
