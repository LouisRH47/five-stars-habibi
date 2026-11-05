class_name InstituteRoom
extends RefCounted
## Looks pass Session 56: the C Institute lobby, two storeys tall (the whole 46 x 14 x 36 m
## building). The front (local +Z) faces the spine; the back faces the other way. Both
## long sides are glass from the floor to the roof, so you see right through.
##   Middle: a curved white reception desk with a big "C" logo wall behind (drop-off)
##   Left:   wide wooden stepped seats with cushions, people on laptops, facing the talk
##           screen on the left wall (it changes during the shift: scripts/talk_screen.gd)
##   Right:  a staircase up to the balcony walkway (glass railing) along the right and back
## A wood-slat ceiling, hanging plants, couches by the back glass, quiet chatter.

const WHITE := Color(0.97, 0.97, 0.96)
const CREAM := Color(0.94, 0.91, 0.85)
const WOOD := Color(0.72, 0.52, 0.32)
const WOOD_DARK := Color(0.4, 0.27, 0.16)
const TEAL := Color(0.1, 0.5, 0.56)
const STONE := Color(0.88, 0.86, 0.82)
const STONE_B := Color(0.82, 0.8, 0.76)
const STEEL := Color(0.7, 0.72, 0.74)
const LEAF := Color(0.24, 0.55, 0.28)
const CUSHIONS := [Color(0.95, 0.55, 0.25), Color(0.1, 0.5, 0.56), Color(0.85, 0.75, 0.3), Color(0.75, 0.35, 0.4)]

const FLOOR2 := 6.5          # the balcony floor
const CEILING := 13.4        # under the wood slats
const DOOR_HALF := 1.3
const DESK_CENTRE := Vector3(0, 0, 3.0)
const DESK_RADIUS := 2.4
## Where you stand to hand over the food (in front of the curved desk).
const COUNTER_SPOT := Vector3(0, 0, 6.9)


static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", "institute")
	body.set_meta("interior_style", "institute_lobby")
	body.set_meta("room_rect", Rect2(-size.x * 0.5, -size.z * 0.5, size.x, size.z))
	body.set_meta("ceiling", CEILING)
	body.set_meta("counter_spot", COUNTER_SPOT)
	body.add_to_group("venue_room")
	var doors := VenueMotion.new()
	doors.name = "Motion"
	body.add_child(doors)
	_shell(body, size)
	_outside(body, place, size)
	_reception(body)
	_stepped_seats(body, size)
	_balcony_and_stairs(body, size)
	_plants(body, size)
	_lounge(body, size)
	_lights(body)
	RestaurantRoom.sound(body, "room_institute.wav")
	Props.bake_kits(body)
	RestaurantRoom.draw_people_near(body)
	return body


## Glass front and back (both storeys), cream side walls, roof, wood-slat ceiling, stone floor.
static func _shell(body: StaticBody3D, size: Vector3) -> void:
	var half := size.x * 0.5
	var front := size.z * 0.5
	for side in [-1.0, 1.0]:
		VenueParts.block(body, Vector3(0.3, size.y, size.z), CREAM, Vector3(side * half, size.y * 0.5, 0))
	VenueParts.block(body, Vector3(size.x + 0.4, 0.3, size.z + 0.4), CREAM, Vector3(0, size.y + 0.15, 0))
	var low := FLOOR2 - 0.2
	for z in [front, -front]:
		if z > 0.0:
			for side in [-1.0, 1.0]:
				VenueParts.glass_run(body, Vector3(side * DOOR_HALF, 0, z), Vector3(side * half, 0, z), low, 3.8)
			RoomProps.pane(body, Vector3(DOOR_HALF * 2, low - RestaurantRoom.GLASS_TOP, 0.06),
					Vector3(0, (low + RestaurantRoom.GLASS_TOP) * 0.5, z))
			LowPoly.box(body, Vector3(DOOR_HALF * 2 + 0.2, 0.12, 0.16), VenueParts.POST, Vector3(0, RestaurantRoom.GLASS_TOP, z + 0.01))
		else:
			VenueParts.glass_run(body, Vector3(-half, 0, z), Vector3(half, 0, z), low, 3.8)
		# The band between the storeys, then the upper glass, then a band under the roof.
		LowPoly.box(body, Vector3(size.x, 0.4, 0.3), Color(0.2, 0.22, 0.24), Vector3(0, FLOOR2, z))
		VenueParts.glass_run(body, Vector3(-half, 0, z), Vector3(half, 0, z), CEILING - FLOOR2 - 0.2, 3.8, FLOOR2 + 0.2, false)
		LowPoly.box(body, Vector3(size.x, size.y - CEILING, 0.3), TEAL if z > 0.0 else CREAM, Vector3(0, (size.y + CEILING) * 0.5, z))
	RestaurantRoom.sliding_doors(body, front)
	# The wood-slat ceiling: dark backing with light slats every 0.6 m.
	LowPoly.box(body, Vector3(size.x - 0.4, 0.1, size.z - 0.4), WOOD_DARK, Vector3(0, CEILING + 0.2, 0))
	var slats := Node3D.new()
	slats.name = "WoodSlatCeiling"
	body.add_child(slats)
	var x := -half + 0.6
	while x < half - 0.4:
		LowPoly.box(slats, Vector3(0.16, 0.14, size.z - 0.6), WOOD, Vector3(x, CEILING + 0.07, 0))
		x += 0.6
	var floor_view := LowPoly.box(body, Vector3(size.x - 0.4, 0.06, size.z - 0.4), Color.WHITE, Vector3(0, 0.03, 0))
	floor_view.name = "StoneFloor"
	floor_view.material_override = RoomProps.floor_material(STONE, STONE_B, "checker", 1.2, Vector2(size.x, size.z))


static func _outside(body: StaticBody3D, place: Dictionary, size: Vector3) -> void:
	var front := size.z * 0.5
	var y := (size.y + CEILING) * 0.5
	var sign := SignText.make_face(place.get("arabic", "معهد سي"), place.get("name", "C Institute"), 52, Color.WHITE)
	sign.name = "BilingualSign"
	sign.position = Vector3(0, y, front + 0.17)
	body.add_child(sign)


## A curved white reception desk (the drop-off) with the receptionist, and a white wall
## behind with a big teal "C".
static func _reception(body: StaticBody3D) -> void:
	var desk := Node3D.new()
	desk.name = "CurvedDesk"
	body.add_child(desk)
	var parts := 9
	var spread := deg_to_rad(70.0)
	for i in parts:
		var a := lerpf(-spread, spread, (i + 0.5) / parts)
		var piece := 2.0 * spread / parts * DESK_RADIUS + 0.06
		var at := DESK_CENTRE + Vector3(sin(a), 0, cos(a)) * DESK_RADIUS
		var front := LowPoly.box(desk, Vector3(piece, 1.1, 0.45), WHITE, at + Vector3(0, 0.55, 0))
		front.rotation.y = a
		var top := LowPoly.box(desk, Vector3(piece, 0.05, 0.6), Color(0.85, 0.86, 0.87), at + Vector3(0, 1.125, -0.05))
		top.rotation.y = a
		var stripe := LowPoly.box(desk, Vector3(piece, 0.08, 0.02), TEAL, at + Vector3(0, 0.25, 0.235))
		stripe.rotation.y = a
		var solid := LowPoly.solid_box(body, Vector3(piece, 1.1, 0.45), at + Vector3(0, 0.55, 0))
		solid.rotation.y = a
	var staff := Person.new()
	staff.paint({"skin": PeopleLooks.SKINS[2], "shirt": TEAL.lightened(0.2), "pants": Color(0.2, 0.2, 0.24)})
	PeopleLooks.shoes(staff, Color(0.2, 0.15, 0.1))
	staff.name = "CounterStaff"
	staff.position = DESK_CENTRE + Vector3(0, 0, 0.9)
	staff.rotation.y = PI
	body.add_child(staff)
	LowPoly.box(body, Vector3(0.5, 0.32, 0.04), Color(0.15, 0.15, 0.17), DESK_CENTRE + Vector3(0.8, 1.32, 1.9))
	var welcome := SignText.make_face("الاستقبال", "Reception", 26, TEAL)
	welcome.position = DESK_CENTRE + Vector3(0, 0.7, DESK_RADIUS + 0.235)
	body.add_child(welcome)
	# The logo wall.
	var wall_at := DESK_CENTRE + Vector3(0, 0, -2.6)
	VenueParts.block(body, Vector3(9.0, 5.6, 0.4), WHITE, wall_at + Vector3(0, 2.8, 0))
	for facing in [0.0, 180.0]:
		var logo := Node3D.new()
		logo.name = "CLogo" if facing == 0.0 else "CLogoBack"
		logo.position = wall_at + Vector3(0, 0, 0.21 if facing == 0.0 else -0.21)
		logo.rotation_degrees.y = facing
		body.add_child(logo)
		var letter := SignText.make_label("C", 360, TEAL, Color(0, 0, 0, 0), 0)
		letter.position = Vector3(0, 3.3, 0)
		logo.add_child(letter)
		var name := SignText.make_face("معهد سي", "C Institute", 44, Color(0.2, 0.22, 0.25))
		name.position = Vector3(0, 1.0, 0)
		logo.add_child(name)


## Wide wooden steps facing the talk screen on the left wall, cushions, people on laptops.
static func _stepped_seats(body: StaticBody3D, size: Vector3) -> void:
	var wall := -size.x * 0.5 + 0.15
	var screen := Node3D.new()
	screen.name = "TalkScreenFrame"
	body.add_child(screen)
	LowPoly.box(screen, Vector3(0.15, 5.0, 11.4), Color(0.08, 0.08, 0.1), Vector3(wall + 0.1, 3.9, 0))
	var glass := LowPoly.box(screen, Vector3(0.04, 4.6, 11.0), Color(0.05, 0.12, 0.25), Vector3(wall + 0.2, 3.9, 0))
	glass.material_override = VenueParts.glow(Color(0.05, 0.14, 0.3), 1.0)
	var talk := TalkScreen.new()
	talk.name = "TalkScreen"
	talk.position = Vector3(wall + 0.24, 3.9, 0)
	talk.rotation_degrees.y = 90.0  # reads from inside (+X)
	body.add_child(talk)
	talk.setup()
	var sitters := 0
	for level in 4:
		var top := 0.45 * (level + 1)
		var x := wall + 6.0 + level * 1.6
		var step := VenueParts.block(body, Vector3(1.6, top, 15.0), WOOD if level % 2 == 0 else WOOD.darkened(0.08), Vector3(x, top * 0.5, 0))
		step.name = "SeatStep%d" % level
		for i in 6:
			var z := -6.3 + i * 2.5 + (level % 2) * 0.8
			if absf(z) > 7.0:
				continue
			LowPoly.box(body, Vector3(0.8, 0.1, 0.8), CUSHIONS[(i + level) % CUSHIONS.size()], Vector3(x - 0.2, top + 0.05, z))
			if (i + level) % 2 == 0 and sitters < 8:
				_laptop_person(body, Vector3(x - 0.2, top + 0.1, z), sitters)
				sitters += 1
	body.set_meta("laptop_people", sitters)


## Someone sitting on a step (facing the screen, -X) with a glowing laptop on their lap.
static func _laptop_person(body: StaticBody3D, seat: Vector3, i: int) -> void:
	var person := PeopleLooks.resident(i + 2, i % PeopleLooks.SKINS.size()) if i % 3 != 0 else PeopleLooks.teacher()
	person.name = "LaptopPerson%d" % i
	person.rotation_degrees.y = 90.0
	var hips := person.spot("Hips")
	person.position = seat + Vector3(0, 0.07, 0) - person.basis * hips
	body.add_child(person, true)
	person.play("sit")
	person.pose.floor_y = seat.y - 0.1  # Session 80: feet rest on this step, not inside it
	var lap := person.transform * Vector3(0, hips.y + 0.1, hips.z - 0.32)
	var base := LowPoly.box(body, Vector3(0.24, 0.02, 0.32), Color(0.75, 0.76, 0.78), lap)
	base.name = "Laptop%d" % i
	var lid := LowPoly.box(body, Vector3(0.22, 0.02, 0.3), Color(0.6, 0.8, 0.95), lap + Vector3(-0.14, 0.13, 0))
	lid.rotation.z = deg_to_rad(-70.0)
	lid.material_override = VenueParts.glow(Color(0.6, 0.8, 0.95), 0.8)


## The balcony walkway along the back and right walls with a glass railing, and a wooden
## staircase up to it along the right wall.
static func _balcony_and_stairs(body: StaticBody3D, size: Vector3) -> void:
	var half := size.x * 0.5
	var back := -size.z * 0.5
	var depth := 3.0
	var inner_z := back + depth + 0.15
	var inner_x := half - depth - 0.15
	var balcony := Node3D.new()
	balcony.name = "Balcony"
	body.add_child(balcony)
	LowPoly.box(balcony, Vector3(size.x - 0.3, 0.3, depth), WHITE, Vector3(0, FLOOR2 - 0.15, back + 0.15 + depth * 0.5))
	var side_from := inner_z
	var side_to := 12.0
	LowPoly.box(balcony, Vector3(depth, 0.3, side_to - side_from), WHITE, Vector3(half - 0.15 - depth * 0.5, FLOOR2 - 0.15, (side_from + side_to) * 0.5))
	# Wood on the walkway floor.
	LowPoly.box(balcony, Vector3(size.x - 0.4, 0.02, depth - 0.1), WOOD, Vector3(0, FLOOR2 + 0.01, back + 0.15 + depth * 0.5))
	LowPoly.box(balcony, Vector3(depth - 0.1, 0.02, side_to - side_from - 0.1), WOOD, Vector3(half - 0.15 - depth * 0.5, FLOOR2 + 0.01, (side_from + side_to) * 0.5))
	# Glass railing with a steel top rail (a gap at the top of the stairs).
	var rail := 1.1
	var runs := [[Vector3(-half + 0.2, 0, inner_z), Vector3(inner_x, 0, inner_z)],
			[Vector3(inner_x, 0, inner_z), Vector3(inner_x, 0, -5.0)],
			[Vector3(inner_x, 0, -1.6), Vector3(inner_x, 0, side_to)],
			[Vector3(inner_x, 0, side_to), Vector3(half - 0.2, 0, side_to)]]
	for run: Array in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		VenueParts.glass_run(body, a, b, rail, 2.0, FLOOR2, false)
		var along_x := absf(b.x - a.x) > absf(b.z - a.z)
		var length := a.distance_to(b)
		LowPoly.box(balcony, Vector3(length, 0.06, 0.08) if along_x else Vector3(0.08, 0.06, length), STEEL, (a + b) * 0.5 + Vector3(0, FLOOR2 + rail, 0))
	# Slim white columns under the walkway edge.
	for x in [-16.0, -6.0, 6.0]:
		LowPoly.cylinder(balcony, 0.16, 0.16, FLOOR2 - 0.3, WHITE, Vector3(x, (FLOOR2 - 0.3) * 0.5, inner_z - 0.2))
		LowPoly.solid_cylinder(body, 0.18, FLOOR2, Vector3(x, FLOOR2 * 0.5, inner_z - 0.2))
	# People on the balcony looking down.
	for i in 2:
		var person := PlaceLooks.teacher() if i == 0 else PeopleLooks.resident(4, 1)
		person.name = "BalconyPerson%d" % i
		person.position = Vector3(-8.0 + i * 14.0, FLOOR2 + 0.02, inner_z - 0.7)
		person.rotation.y = PI  # looking into the lobby (+Z)
		body.add_child(person, true)
	# The staircase: 26 wooden treads from the floor (z = 10) up to the walkway (z = -2).
	var stairs := Node3D.new()
	stairs.name = "Staircase"
	body.add_child(stairs)
	var sx := inner_x - 1.25
	var steps := 26
	var bottom := 10.0
	var top_z := -2.0
	var run_len := (bottom - top_z) / steps
	var rise := FLOOR2 / steps
	for i in steps:
		LowPoly.box(stairs, Vector3(2.3, 0.07, run_len + 0.04), WOOD, Vector3(sx, rise * (i + 1) - 0.035, bottom - run_len * (i + 0.5)))
	var slope := atan2(FLOOR2, bottom - top_z)
	var length := Vector2(bottom - top_z, FLOOR2).length()
	for side in [-1.2, 1.2]:
		var stringer := LowPoly.box(stairs, Vector3(0.08, 0.36, length), WHITE, Vector3(sx + side, FLOOR2 * 0.5 - 0.15, (bottom + top_z) * 0.5))
		stringer.rotation.x = slope
	var handrail := LowPoly.box(stairs, Vector3(0.06, 0.06, length), STEEL, Vector3(sx - 1.2, FLOOR2 * 0.5 + 0.95, (bottom + top_z) * 0.5))
	handrail.rotation.x = slope
	LowPoly.box(stairs, Vector3(2.5, 0.3, 3.4), WHITE, Vector3(sx, FLOOR2 - 0.15, top_z - 1.7))  # the landing
	LowPoly.solid_box(body, Vector3(2.5, 2.2, bottom - top_z), Vector3(sx, 1.1, (bottom + top_z) * 0.5))


## Plants hanging from the ceiling on long cords, and trailing plants on the balcony edge.
static func _plants(body: StaticBody3D, size: Vector3) -> void:
	var count := 0
	for x in [-12.0, -3.5, 5.0, 12.0]:
		for z in [-8.0, 2.0, 11.0]:
			var drop := 2.8 + float(int(absf(x + z)) % 3) * 0.6
			var holder := Node3D.new()
			holder.name = "HangingPlant%d" % count
			holder.position = Vector3(x, CEILING - drop, z)
			body.add_child(holder)
			LowPoly.cylinder(holder, 0.008, 0.008, drop, Color(0.2, 0.2, 0.2), Vector3(0, drop * 0.5, 0))
			LowPoly.cylinder(holder, 0.3, 0.2, 0.32, Color(0.95, 0.94, 0.9), Vector3.ZERO)
			for i in 6:
				var a := i * TAU / 6.0
				LowPoly.sphere(holder, 0.22, 0.6, LEAF.lightened(0.04 * i), Vector3(cos(a) * 0.28, -0.2 - (i % 3) * 0.15, sin(a) * 0.28))
			LowPoly.sphere(holder, 0.32, 0.35, LEAF, Vector3(0, 0.22, 0))
			count += 1
	var edge := -size.z * 0.5 + 3.15
	for i in 10:
		var x := -20.0 + i * 4.2
		LowPoly.box(body, Vector3(1.4, 0.3, 0.3), Color(0.95, 0.94, 0.9), Vector3(x, FLOOR2 + 0.15, edge - 0.35))
		var vine := LowPoly.box(body, Vector3(1.2, 1.2, 0.12), LEAF.darkened(0.1), Vector3(x, FLOOR2 - 0.6, edge + 0.08))
		vine.name = "TrailingPlant%d" % i
	body.set_meta("hanging_plants", count)


## Couches and low tables by the back glass, and big plants.
static func _lounge(body: StaticBody3D, size: Vector3) -> void:
	var back := -size.z * 0.5
	for x in [-6.0, 6.0]:
		Props.kit("furniture/couch", body, Vector3(x, 0.06, back + 5.0), 180.0, 1.0)
		Props.kit("furniture/table_low", body, Vector3(x, 0.06, back + 6.6), 0.0, 1.0)
		Props.kit("furniture/rug_oval_A", body, Vector3(x, 0.065, back + 6.0), 0.0, 1.2)
		LowPoly.solid_box(body, Vector3(2.2, 0.9, 1.0), Vector3(x, 0.45, back + 5.0))
	for x in [-20.0, 20.0]:
		RoomProps.big_plant(body, Vector3(x, 0, size.z * 0.5 - 1.2))
	RoomProps.big_plant(body, Vector3(-3.6, 0, 1.8))
	RoomProps.big_plant(body, Vector3(3.6, 0, 1.8))
	var reader := PeopleLooks.resident(3, 0)
	reader.name = "LoungeReader"
	reader.rotation.y = PI
	var hips := reader.spot("Hips")
	reader.position = Vector3(-6.0, 0.5, back + 5.1) - reader.basis * hips
	body.add_child(reader, true)
	reader.play("sit")


static func _lights(body: StaticBody3D) -> void:
	VenueParts.room_light(body, "InteriorLight", Vector3(0, 8.5, 7.0), 1.5, 22.0, true)
	VenueParts.room_light(body, "SeatsLight", Vector3(-13.0, 7.5, 0.0), 1.2, 16.0)
	VenueParts.room_light(body, "BalconyLight", Vector3(12.0, 9.0, -8.0), 1.0, 16.0)
