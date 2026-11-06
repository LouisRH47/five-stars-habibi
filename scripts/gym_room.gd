class_name GymRoom
extends RefCounted
## Looks pass Session 56: the Wahat Gym as a real gym, with its rounded back; the front
## (local +Z) faces the spine and the lap pool is outside the left side (local -X), so both of
## those walls are glass. Session 90: 15% smaller (30.6 x 8 x 18.7 m, the data's size) so it
## clears the spine loop road; the things inside are placed for that size. A second door in
## the pool-side glass, and outside the restaurants' look: a colour band over the glass on
## both glass sides, a bilingual sign over each door, a canopy and two planters by each door.
##   Front:  4 treadmills facing the glass (left), 3 exercise bikes (right), the doors
##   Middle: reception with a smoothie cooler, a water fountain and a towel stand
##   Left:   2 rowing machines by the pool glass, yoga mats and kettlebells at the back
##   Right:  a mirror wall ("Train hard"), a dumbbell rack, a squat rack on a wood platform
## Rubber floor tiles, a lower ceiling (5 m) with light panels, gym music.
## People run, pedal, row, lift and stretch (scripts/gym_motion.gd).

const CREAM := Color(0.95, 0.92, 0.86)
const TEAL := Color(0.1, 0.5, 0.56)
const RUBBER := Color(0.16, 0.17, 0.18)
const RUBBER_B := Color(0.22, 0.23, 0.24)
const STEEL := Color(0.62, 0.64, 0.67)
const DARK := Color(0.1, 0.1, 0.11)
const WOOD := Color(0.62, 0.45, 0.28)
const PLATES := [Color(0.85, 0.15, 0.15), Color(0.15, 0.35, 0.8), Color(0.12, 0.12, 0.12)]
const MATS := [Color(0.55, 0.3, 0.7), Color(0.2, 0.65, 0.6), Color(0.95, 0.5, 0.25)]

const CEILING := 4.8
const DOOR_HALF := 1.3
## Where you stand to hand over the food (in front of reception).
const COUNTER_SPOT := Vector3(0, 0, 2.4)
const DESK_Z := 1.0


static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var tint: Color = place.get("colour", TEAL)
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", "gym")
	body.set_meta("interior_style", "gym")
	body.set_meta("room_rect", Rect2(-size.x * 0.5, -size.z * 0.5, size.x, size.z))
	body.set_meta("ceiling", CEILING)
	body.set_meta("counter_spot", COUNTER_SPOT)
	body.add_to_group("venue_room")
	var doors := VenueMotion.new()   # the sliding doors (scripts/venue_motion.gd)
	doors.name = "Motion"
	body.add_child(doors)
	var motion := GymMotion.new()
	motion.name = "GymMotion"
	body.add_child(motion)
	_shell(body, size, tint)
	_outside(body, place, size, tint)
	_reception(body, tint)
	var half := size.x * 0.5
	var front := size.z * 0.5
	for i in 4:
		_treadmill(body, Vector3(-half + 1.7 + i * 2.3, 0, front - 2.35), i, i < 3, motion)
	for i in 3:
		_exercise_bike(body, Vector3(6.0 + i * 2.2, 0, front - 2.15), i, i != 1, motion)
	# Session 90: the rowers sit behind the side door, so the way in from it stays clear.
	for i in 2:
		_rower(body, Vector3(-half + 2.1, 0, GameConfig.GYM_SIDE_DOOR_Z - 2.7 - i * 2.4), i, motion)
	_mirror_wall(body, size)
	_dumbbell_rack(body, Vector3(half - 0.7, 0, 3.4))
	_squat_rack(body, Vector3(half - 5.1, 0, -2.6), motion)
	_mats_and_kettlebells(body, motion)
	RoomProps.big_plant(body, Vector3(-half + 0.9, 0, front - 0.9))
	RoomProps.big_plant(body, Vector3(half - 0.9, 0, front - 0.9))
	RoomProps.bin(body, Vector3(-3.2, 0, 1.9))
	_lights(body)
	RestaurantRoom.sound(body, "room_gym.wav")
	Props.bake_kits(body)
	RestaurantRoom.draw_people_near(body)
	return body


## Glass front and pool side, cream walls, the rounded back, the roof, a 4.8 m ceiling
## and the rubber floor.
static func _shell(body: StaticBody3D, size: Vector3, tint: Color) -> void:
	var half := size.x * 0.5
	var front := size.z * 0.5
	var arc := -front + 4.0  # where the rounded back starts
	var straight := front - arc
	var mid := (front + arc) * 0.5
	VenueBuilder._rounded_back(body, size)
	VenueParts.block(body, Vector3(size.x + 0.2, 0.25, straight + 0.2), CREAM, Vector3(0, size.y + 0.12, mid))
	# The right wall (the mirror is on its inside). Session 90: the gym's colour band goes on
	# round its outside too, level with the band over the glass.
	VenueParts.block(body, Vector3(0.25, size.y, straight), CREAM, Vector3(half, size.y * 0.5, mid))
	var band := LowPoly.box(body, Vector3(0.06, size.y - CEILING, straight), tint, Vector3(half + 0.16, (size.y + CEILING) * 0.5, mid))
	band.name = "SideBand"
	# The pool side: glass up to the ceiling with the second door in it (Session 90), and a
	# band in the gym colour above, like the front.
	var door := GameConfig.GYM_SIDE_DOOR_Z
	VenueParts.glass_run(body, Vector3(-half, 0, arc), Vector3(-half, 0, door - DOOR_HALF), CEILING, 3.0)
	VenueParts.glass_run(body, Vector3(-half, 0, door + DOOR_HALF), Vector3(-half, 0, front), CEILING, 3.0)
	VenueParts.block(body, Vector3(0.25, size.y - CEILING, straight), tint, Vector3(-half, (size.y + CEILING) * 0.5, mid))
	_side_door(body, half, door)
	# The front: glass either side of the doors, a band in the gym colour above.
	for side in [-1.0, 1.0]:
		VenueParts.glass_run(body, Vector3(side * DOOR_HALF, 0, front), Vector3(side * half, 0, front), CEILING, 3.4)
	VenueParts.block(body, Vector3(size.x, size.y - CEILING, 0.25), tint, Vector3(0, (size.y + CEILING) * 0.5, front))
	RoomProps.pane(body, Vector3(DOOR_HALF * 2, CEILING - RestaurantRoom.GLASS_TOP, 0.06),
			Vector3(0, (CEILING + RestaurantRoom.GLASS_TOP) * 0.5, front))
	LowPoly.box(body, Vector3(DOOR_HALF * 2 + 0.2, 0.12, 0.16), DARK, Vector3(0, RestaurantRoom.GLASS_TOP, front + 0.01))
	RestaurantRoom.sliding_doors(body, front)
	# Ceiling (the straight part and the round part) and the rubber floor.
	LowPoly.box(body, Vector3(size.x - 0.3, 0.12, straight), Color(0.97, 0.97, 0.96), Vector3(0, CEILING + 0.06, mid))
	VenueParts.arc_cap(body, half - 0.15, arc, 3.9, CEILING, Color(0.97, 0.97, 0.96))
	var floor_view := LowPoly.box(body, Vector3(size.x - 0.3, 0.06, straight), Color.WHITE, Vector3(0, 0.03, mid))
	floor_view.name = "RubberFloor"
	floor_view.material_override = RoomProps.floor_material(RUBBER, RUBBER_B, "checker", 1.0, Vector2(size.x, straight))
	VenueParts.arc_cap(body, half - 0.15, arc, 3.9, 0.06, RUBBER)


static func _outside(body: StaticBody3D, place: Dictionary, size: Vector3, tint: Color) -> void:
	var front := size.z * 0.5
	var half := size.x * 0.5
	var y := (size.y + CEILING) * 0.5
	LowPoly.box(body, Vector3(minf(14, size.x - 4), 1.7, 0.12), tint.darkened(0.35), Vector3(0, y, front + 0.19))
	var sign := SignText.make_face(place.get("arabic", ""), place.get("name", "Wahat Gym"), 50, Color.WHITE)
	sign.name = "BilingualSign"
	sign.position = Vector3(0, y, front + 0.27)
	body.add_child(sign)
	# Session 90: the second door's sign on the pool side, over the door.
	var door := GameConfig.GYM_SIDE_DOOR_Z
	var side_board := LowPoly.box(body, Vector3(0.12, 1.4, 7.0), tint.darkened(0.35), Vector3(-half - 0.19, y, door))
	side_board.name = "SideSignBoard"
	var side_sign := SignText.make_face(place.get("arabic", ""), place.get("name", "Wahat Gym"), 40, Color.WHITE)
	side_sign.name = "SideSign"
	side_sign.position = Vector3(-half - 0.27, y, door)
	side_sign.rotation_degrees.y = -90.0  # faces the lap pool (-X)
	body.add_child(side_sign)
	# A canopy in the gym colour over each door, and a planter either side of it.
	var front_canopy := LowPoly.box(body, Vector3(DOOR_HALF * 2 + 1.6, 0.16, 1.5), tint, Vector3(0, RestaurantRoom.GLASS_TOP + 0.35, front + 0.8))
	front_canopy.name = "DoorCanopy"
	var side_canopy := LowPoly.box(body, Vector3(1.5, 0.16, DOOR_HALF * 2 + 1.6), tint, Vector3(-half - 0.8, RestaurantRoom.GLASS_TOP + 0.35, door))
	side_canopy.name = "SideDoorCanopy"
	var gap := GameConfig.GYM_DOOR_PLANTER
	for s in [-1.0, 1.0]:
		_door_planter(body, Vector3(s * gap, 0, front + 0.75), "DoorPlanter")
		_door_planter(body, Vector3(-half - 0.75, 0, door + s * gap), "SideDoorPlanter")


## Session 90: a stone planter with a little shrub, by a door (like the shops' planters). Solid.
static func _door_planter(body: StaticBody3D, at: Vector3, title: String) -> void:
	var holder := Node3D.new()
	holder.name = title
	holder.position = at
	body.add_child(holder, true)
	LowPoly.box(holder, Vector3(0.9, 0.6, 0.9), Color(0.84, 0.77, 0.64), Vector3(0, 0.3, 0))
	LowPoly.box(holder, Vector3(1.0, 0.08, 1.0), WallTrim.TRIM, Vector3(0, 0.64, 0))
	LowPoly.box(holder, Vector3(0.78, 0.03, 0.78), Color(0.36, 0.27, 0.19), Vector3(0, 0.69, 0))
	LowPoly.sphere(holder, 0.42, 0.9, Color(0.3, 0.55, 0.26), Vector3(0, 1.05, 0))
	LowPoly.sphere(holder, 0.3, 0.7, Color(0.36, 0.62, 0.3), Vector3(0.2, 1.0, 0.18))
	LowPoly.solid_box(body, Vector3(0.9, 0.7, 0.9), at + Vector3(0, 0.35, 0))


## Session 90: the second doorway, in the pool-side glass (local -X) at z `door`: a glass
## pane over it, a dark frame, and sliding doors that open as you walk up (their own
## VenueMotion, "SideDoorMotion", as the front doors use "Motion").
static func _side_door(body: StaticBody3D, half: float, door: float) -> void:
	RoomProps.pane(body, Vector3(0.06, CEILING - RestaurantRoom.GLASS_TOP, DOOR_HALF * 2),
			Vector3(-half, (CEILING + RestaurantRoom.GLASS_TOP) * 0.5, door))
	LowPoly.box(body, Vector3(0.16, 0.12, DOOR_HALF * 2 + 0.2), DARK, Vector3(-half - 0.01, RestaurantRoom.GLASS_TOP, door))
	var motion := VenueMotion.new()
	motion.name = "SideDoorMotion"
	body.add_child(motion)
	var doors := Node3D.new()
	doors.name = "SideDoor"
	doors.set_meta("static_batch_dynamic", true)
	doors.position = Vector3(-half - 0.12, 0, door)
	doors.rotation.y = -PI * 0.5  # its outside (+Z) faces the pool (-X); the panels slide along Z
	body.add_child(doors)
	var tall := RestaurantRoom.GLASS_TOP - 0.15
	for side in [-1.0, 1.0]:
		var panel := Node3D.new()
		panel.name = "DoorLeft" if side < 0 else "DoorRight"
		panel.position.x = side * DOOR_HALF * 0.5
		panel.set_meta("closed_x", panel.position.x)
		panel.set_meta("open_x", side * DOOR_HALF * 1.45)
		doors.add_child(panel)
		RoomProps.pane(panel, Vector3(DOOR_HALF, tall, 0.04), Vector3(0, tall * 0.5, 0))
		LowPoly.box(panel, Vector3(0.06, tall, 0.06), DARK, Vector3(side * DOOR_HALF * 0.5, tall * 0.5, 0))
		LowPoly.box(panel, Vector3(0.04, 0.5, 0.08), Color(0.8, 0.8, 0.82), Vector3(-side * DOOR_HALF * 0.4, 1.1, 0.03))
	motion.doors = doors


## Reception: a desk in the gym colour with the receptionist, a smoothie cooler, cups,
## a logo wall behind, a water fountain and a towel stand.
static func _reception(body: StaticBody3D, tint: Color) -> void:
	VenueParts.block(body, Vector3(5.0, 1.05, 0.8), tint, Vector3(0, 0.525, DESK_Z))
	LowPoly.box(body, Vector3(5.2, 0.06, 0.95), Color(0.93, 0.93, 0.92), Vector3(0, 1.08, DESK_Z + 0.05))
	LowPoly.box(body, Vector3(0.45, 0.3, 0.05), DARK, Vector3(-1.2, 1.3, DESK_Z - 0.1))
	for i in 4:  # smoothies waiting on the desk
		var cup := LowPoly.cylinder(body, 0.05, 0.04, 0.16, [Color(0.95, 0.4, 0.55), Color(0.55, 0.8, 0.3), Color(0.98, 0.7, 0.2), Color(0.5, 0.3, 0.6)][i],
				Vector3(0.6 + i * 0.2, 1.19, DESK_Z + 0.15))
		cup.name = "Smoothie%d" % i
	var staff := Person.new()
	staff.paint({"skin": PeopleLooks.SKINS[1], "shirt": tint.lightened(0.15), "pants": DARK})
	PeopleLooks.shoes(staff, Color.WHITE)
	staff.name = "CounterStaff"
	staff.position = Vector3(0, 0, DESK_Z - 0.85)
	staff.rotation.y = PI
	body.add_child(staff)
	var cooler := RoomProps.drinks_fridge(body, Vector3(3.6, 0, DESK_Z - 0.4), 0.0)
	cooler.name = "SmoothieCooler"
	var label := SignText.make_face("عصائر", "Smoothies", 30, Color(1, 0.9, 0.6))
	label.position = Vector3(3.6, 2.45, DESK_Z + 0.0)
	body.add_child(label)
	# The logo wall behind reception.
	VenueParts.block(body, Vector3(7.0, 3.4, 0.3), Color(0.12, 0.13, 0.15), Vector3(0, 1.7, DESK_Z - 2.2))
	var logo := SignText.make_face("نادي الواحة الرياضي", "WAHAT GYM", 64, tint.lightened(0.4))
	logo.position = Vector3(0, 2.3, DESK_Z - 2.04)
	body.add_child(logo)
	# Water fountain.
	var fountain := Node3D.new()
	fountain.name = "WaterFountain"
	fountain.position = Vector3(-4.6, 0, 1.0)
	body.add_child(fountain)
	LowPoly.box(fountain, Vector3(0.5, 0.95, 0.4), STEEL, Vector3(0, 0.475, 0))
	LowPoly.box(fountain, Vector3(0.44, 0.06, 0.34), Color(0.8, 0.82, 0.85), Vector3(0, 0.98, 0.02))
	LowPoly.cylinder(fountain, 0.02, 0.02, 0.1, DARK, Vector3(0, 1.04, -0.05))
	LowPoly.box(fountain, Vector3(0.5, 0.5, 0.06), Color(0.2, 0.55, 0.85), Vector3(0, 1.3, -0.17))
	LowPoly.solid_box(body, Vector3(0.5, 1.0, 0.4), fountain.position + Vector3(0, 0.5, 0))
	# Towel stand: a wooden shelf of rolled white and teal towels.
	var towels := Node3D.new()
	towels.name = "TowelStand"
	towels.position = Vector3(-6.2, 0, 1.0)
	body.add_child(towels)
	for x in [-0.45, 0.45]:
		LowPoly.box(towels, Vector3(0.06, 1.3, 0.4), WOOD, Vector3(x, 0.65, 0))
	for shelf in 3:
		LowPoly.box(towels, Vector3(0.96, 0.04, 0.4), WOOD, Vector3(0, 0.25 + shelf * 0.45, 0))
		for i in 4:
			var roll := LowPoly.cylinder(towels, 0.08, 0.08, 0.36, Color.WHITE if (i + shelf) % 2 == 0 else tint.lightened(0.3),
					Vector3(-0.3 + i * 0.2, 0.36 + shelf * 0.45, 0))
			roll.rotation.x = PI * 0.5
	LowPoly.solid_box(body, Vector3(1.0, 1.3, 0.4), towels.position + Vector3(0, 0.65, 0))


## A treadmill facing the glass (+Z), with someone running on it if `used`.
static func _treadmill(body: StaticBody3D, at: Vector3, i: int, used: bool, motion: GymMotion) -> void:
	var holder := Node3D.new()
	holder.name = "Treadmill%d" % i
	holder.position = at
	body.add_child(holder)
	LowPoly.box(holder, Vector3(0.85, 0.2, 2.0), Color(0.2, 0.21, 0.23), Vector3(0, 0.17, 0))
	LowPoly.box(holder, Vector3(0.62, 0.02, 1.8), DARK, Vector3(0, 0.28, -0.05))
	for side in [-1.0, 1.0]:
		var post := LowPoly.box(holder, Vector3(0.06, 1.25, 0.06), STEEL, Vector3(side * 0.39, 0.85, 0.8))
		post.rotation.x = -0.15
		LowPoly.box(holder, Vector3(0.05, 0.05, 0.6), STEEL, Vector3(side * 0.39, 1.25, 0.55))
	var console := LowPoly.box(holder, Vector3(0.8, 0.32, 0.1), Color(0.18, 0.19, 0.2), Vector3(0, 1.5, 0.95))
	console.rotation.x = 0.5
	var screen := LowPoly.box(holder, Vector3(0.42, 0.18, 0.02), Color(0.3, 0.8, 0.95), Vector3(0, 1.5, 0.89))
	screen.rotation.x = 0.5
	screen.material_override = VenueParts.glow(Color(0.3, 0.8, 0.95), 1.2)
	LowPoly.solid_box(body, Vector3(0.9, 1.6, 2.0), at + Vector3(0, 0.8, 0))
	if used:
		var runner := PlaceLooks.gym_goer(i)
		runner.name = "Runner%d" % i
		runner.position = at + Vector3(0, 0.29, -0.15)
		runner.rotation.y = PI  # faces the glass
		body.add_child(runner, true)
		runner.play("jog", 0.9 + i * 0.07)


## An exercise bike facing the glass, with someone pedalling if `used`.
static func _exercise_bike(body: StaticBody3D, at: Vector3, i: int, used: bool, motion: GymMotion) -> void:
	var holder := Node3D.new()
	holder.name = "ExerciseBike%d" % i
	holder.position = at
	body.add_child(holder)
	LowPoly.box(holder, Vector3(0.5, 0.07, 0.1), DARK, Vector3(0, 0.1, -0.5))
	LowPoly.box(holder, Vector3(0.5, 0.07, 0.1), DARK, Vector3(0, 0.1, 0.55))
	LowPoly.box(holder, Vector3(0.08, 0.08, 1.1), Color(0.85, 0.15, 0.15), Vector3(0, 0.16, 0.02))
	var post := LowPoly.box(holder, Vector3(0.08, 0.85, 0.08), Color(0.85, 0.15, 0.15), Vector3(0, 0.55, -0.2))
	post.rotation.x = 0.25
	LowPoly.box(holder, Vector3(0.26, 0.07, 0.32), DARK, Vector3(0, 0.98, -0.3))  # saddle
	var wheel := LowPoly.cylinder(holder, 0.26, 0.26, 0.07, STEEL, Vector3(0, 0.42, 0.42))
	wheel.rotation.z = PI * 0.5
	var bars := LowPoly.box(holder, Vector3(0.08, 0.9, 0.08), Color(0.85, 0.15, 0.15), Vector3(0, 0.75, 0.42))
	bars.rotation.x = -0.2
	LowPoly.box(holder, Vector3(0.52, 0.04, 0.05), DARK, Vector3(0, 1.22, 0.52))
	LowPoly.box(holder, Vector3(0.22, 0.14, 0.05), Color(0.3, 0.8, 0.95), Vector3(0, 1.3, 0.5))
	LowPoly.solid_box(body, Vector3(0.6, 1.3, 1.3), at + Vector3(0, 0.65, 0))
	if not used:
		return
	var rider := PlaceLooks.gym_goer(i + 4)
	rider.name = "Cyclist%d" % i
	rider.rotation.y = PI
	var hips := rider.spot("Hips")
	rider.position = at + Vector3(0, 1.05, -0.3) - rider.basis * hips
	body.add_child(rider, true)
	rider.play("pedal")
	var to_rider := rider.transform.affine_inverse()
	for side in 2:
		var x := -0.24 if side == 0 else 0.24
		rider.pose.hands[side] = to_rider * (at + Vector3(-x, 1.25, 0.5))
	rider.pose.lean = 18.0
	motion.pedallers.append([rider, to_rider * (at + Vector3(0, 0.42, 0.22))])


## A rowing machine along the pool glass; the rower faces the pool (-X).
static func _rower(body: StaticBody3D, at: Vector3, i: int, motion: GymMotion) -> void:
	var holder := Node3D.new()
	holder.name = "RowingMachine%d" % i
	holder.position = at
	holder.rotation_degrees.y = 90.0  # its front (-Z) points at the pool glass
	body.add_child(holder)
	LowPoly.box(holder, Vector3(0.14, 0.08, 2.5), STEEL, Vector3(0, 0.32, 0.25))
	for z in [-0.9, 1.4]:
		LowPoly.box(holder, Vector3(0.5, 0.3, 0.08), DARK, Vector3(0, 0.15, z))
	var fly := LowPoly.cylinder(holder, 0.3, 0.3, 0.16, Color(0.2, 0.2, 0.22), Vector3(0, 0.45, -1.05))
	fly.rotation.z = PI * 0.5
	for side in [-1.0, 1.0]:
		LowPoly.box(holder, Vector3(0.16, 0.22, 0.05), DARK, Vector3(side * 0.12, 0.3, -0.7))
	LowPoly.solid_box(body, Vector3(2.6, 0.9, 0.7), at + Vector3(-0.25, 0.45, 0))
	var rower := PlaceLooks.gym_goer(i + 7)
	rower.name = "Rower%d" % i
	rower.rotation.y = holder.rotation.y
	var hips := rower.spot("Hips")
	rower.position = holder.transform * Vector3(0, 0.5, 0.1) - rower.basis * hips
	body.add_child(rower, true)
	rower.play("pedal")
	var seat := LowPoly.box(rower, Vector3(0.3, 0.06, 0.34), DARK, hips + Vector3(0, -0.07, 0.02))
	seat.name = "Seat"
	var handle := LowPoly.box(body, Vector3(0.05, 0.04, 0.5), DARK, rower.position)
	handle.name = "RowHandle%d" % i
	handle.set_meta("static_batch_dynamic", true)
	motion.rowers.append([rower, rower.position, handle, hips.y])


## A big mirror on the right wall with "Train hard" above it.
static func _mirror_wall(body: StaticBody3D, size: Vector3) -> void:
	var x := size.x * 0.5 - 0.14
	var mirror := LowPoly.box(body, Vector3(0.03, 2.4, 12.0), Color.WHITE, Vector3(x, 1.45, 2.0))
	mirror.name = "MirrorWall"
	var silver := StandardMaterial3D.new()
	silver.albedo_color = Color(0.8, 0.85, 0.88)
	silver.metallic = 1.0
	silver.roughness = 0.05
	mirror.material_override = silver
	LowPoly.box(body, Vector3(0.05, 0.08, 12.2), DARK, Vector3(x, 2.68, 2.0))
	LowPoly.box(body, Vector3(0.05, 0.08, 12.2), DARK, Vector3(x, 0.22, 2.0))
	var words := SignText.make_face("تمرّن بقوة", "Train hard", 60, Color(0.1, 0.5, 0.56))
	words.name = "TrainHard"
	words.position = Vector3(x - 0.04, 3.55, 2.0)
	words.rotation_degrees.y = -90.0  # reads from inside the gym
	body.add_child(words)


## A two-shelf dumbbell rack against the mirror, light ones at one end, heavy at the other.
static func _dumbbell_rack(body: StaticBody3D, at: Vector3) -> void:
	var rack := Node3D.new()
	rack.name = "DumbbellRack"
	rack.position = at
	body.add_child(rack)
	for z in [-2.6, 0.0, 2.6]:
		LowPoly.box(rack, Vector3(0.7, 0.9, 0.08), DARK, Vector3(0, 0.45, z))
	for shelf in 2:
		var y := 0.38 + shelf * 0.42
		var shelf_box := LowPoly.box(rack, Vector3(0.6, 0.05, 5.2), DARK, Vector3(0, y, 0))
		shelf_box.rotation.z = 0.15
		for i in 8:
			var weight := 0.07 + i * 0.012
			var z := -2.3 + i * 0.66
			var bar := LowPoly.cylinder(rack, 0.02, 0.02, 0.36, STEEL, Vector3(0, y + 0.1, z))
			bar.rotation.z = PI * 0.5
			for end in [-0.15, 0.15]:
				var bell := LowPoly.cylinder(rack, weight, weight, 0.07, DARK if shelf == 0 else Color(0.25, 0.25, 0.27), Vector3(end, y + 0.1, z))
				bell.rotation.z = PI * 0.5
	LowPoly.solid_box(body, Vector3(0.8, 1.0, 5.4), at + Vector3(0, 0.5, 0))
	# A flat bench in front of the rack, and someone curling dumbbells.
	VenueParts.block(body, Vector3(0.4, 0.45, 1.3), DARK, at + Vector3(-2.2, 0.225, 0))
	var lifter := PlaceLooks.gym_goer(10)
	lifter.name = "DumbbellLifter"
	lifter.position = at + Vector3(-1.2, 0, -1.4)
	lifter.rotation_degrees.y = -90.0  # faces the mirror
	body.add_child(lifter, true)
	for hand in ["LeftHand", "RightHand"]:
		var grip := lifter.follow(hand)
		var bar := LowPoly.cylinder(grip, 0.02, 0.02, 0.3, STEEL, lifter.spot(hand))
		bar.rotation.z = PI * 0.5
		for end in [-0.12, 0.12]:
			var bell := LowPoly.cylinder(grip, 0.08, 0.08, 0.06, DARK, lifter.spot(hand) + Vector3(end, 0, 0))
			bell.rotation.z = PI * 0.5


## A squat rack with a loaded barbell, on a wooden platform. The lifter squats with it.
static func _squat_rack(body: StaticBody3D, at: Vector3, motion: GymMotion) -> void:
	var platform := LowPoly.box(body, Vector3(3.0, 0.06, 3.0), WOOD, at + Vector3(0, 0.09, 0))
	platform.name = "LiftingPlatform"
	var rack := Node3D.new()
	rack.name = "SquatRack"
	rack.position = at + Vector3(0, 0.12, 0)
	body.add_child(rack)
	for x in [-0.6, 0.6]:
		for z in [-0.8, 0.8]:
			LowPoly.box(rack, Vector3(0.08, 2.4, 0.08), DARK, Vector3(x, 1.2, z))
			LowPoly.solid_box(body, Vector3(0.12, 2.4, 0.12), rack.position + Vector3(x, 1.2, z))
		LowPoly.box(rack, Vector3(0.08, 0.08, 1.68), DARK, Vector3(x, 2.4, 0))
	for z in [-0.8, 0.8]:
		LowPoly.box(rack, Vector3(1.28, 0.08, 0.08), DARK, Vector3(0, 2.4, z))
	# Spare plates leaning on a stand.
	for i in 3:
		var plate := LowPoly.cylinder(rack, 0.2 + i * 0.03, 0.2 + i * 0.03, 0.05, PLATES[i], Vector3(1.1, 0.25 + i * 0.03, -0.6 + i * 0.12))
		plate.rotation.x = PI * 0.5
	var lifter := PlaceLooks.gym_goer(3)
	lifter.name = "Lifter"
	lifter.rotation_degrees.y = -90.0  # faces the mirror
	lifter.position = rack.position
	body.add_child(lifter, true)
	lifter.play("pedal")
	var bar_y := lifter.spot("Neck").y + 0.02
	for side in 2:
		lifter.pose.hands[side] = Vector3(-0.42 if side == 0 else 0.42, bar_y, 0.06)
	var bar := Node3D.new()
	bar.name = "Barbell"
	bar.set_meta("static_batch_dynamic", true)
	bar.position = rack.position + Vector3(0, bar_y, 0) + lifter.basis * Vector3(0, 0, 0.06)
	bar.rotation.y = lifter.rotation.y
	body.add_child(bar)
	var pole := LowPoly.cylinder(bar, 0.025, 0.025, 2.1, STEEL, Vector3.ZERO)
	pole.rotation.z = PI * 0.5
	for end in [-0.85, -0.78, 0.78, 0.85]:
		var disc := LowPoly.cylinder(bar, 0.24, 0.24, 0.06, PLATES[0 if absf(end) > 0.8 else 1], Vector3(end, 0, 0))
		disc.rotation.z = PI * 0.5
	motion.lifters.append([lifter, lifter.position, bar, bar.position])


## Three yoga mats at the back with someone stretching, and a row of kettlebells.
static func _mats_and_kettlebells(body: StaticBody3D, motion: GymMotion) -> void:
	for i in 3:
		var mat := LowPoly.box(body, Vector3(0.7, 0.012, 1.85), MATS[i], Vector3(-10.2 + i * 1.9, 0.067, -3.6))
		mat.name = "YogaMat%d" % i
	var stretcher := PlaceLooks.gym_goer(5)
	stretcher.name = "Stretcher"
	var hips := stretcher.spot("Hips")
	stretcher.position = Vector3(-8.3, 0.2, -3.1) - hips
	body.add_child(stretcher, true)
	stretcher.play("pedal")
	for side in 2:
		var x := -0.12 if side == 0 else 0.12
		stretcher.pose.feet[side] = Vector3(x, hips.y - 0.08, -0.8)
		stretcher.pose.hands[side] = Vector3(x * 1.3, hips.y + 0.1, -0.65)
	motion.stretchers.append(stretcher)
	for i in 6:
		var at := Vector3(-10.8 + i * 0.85, 0, -5.2)
		var size := 0.12 + (i % 3) * 0.03
		var bell := LowPoly.sphere(body, size, size * 1.8, [DARK, Color(0.85, 0.5, 0.1), Color(0.2, 0.5, 0.3)][i % 3], at + Vector3(0, 0.06 + size * 0.9, 0))
		bell.name = "Kettlebell%d" % i
		var grip := LowPoly.box(body, Vector3(size * 1.2, size * 0.9, 0.04), DARK, at + Vector3(0, 0.06 + size * 1.9, 0))
		grip.name = "KettlebellHandle%d" % i


static func _lights(body: StaticBody3D) -> void:
	for x in [-11.0, -5.5, 0.0, 5.5, 11.0]:  # Session 90: closer together in the smaller gym
		for z in [-3.0, 2.1, 6.6]:
			VenueParts.ceiling_light(body, Vector3(x, 0, z), Vector2(2.4, 0.6), CEILING)
	VenueParts.room_light(body, "InteriorLight", Vector3(0, CEILING - 0.7, 3.8), 1.6, 15.0, true, Color(1, 0.96, 0.9))
	VenueParts.room_light(body, "BackLight", Vector3(-7.6, CEILING - 0.7, -2.6), 1.1, 10.0)
	VenueParts.room_light(body, "WeightsLight", Vector3(8.5, CEILING - 0.7, -1.0), 1.1, 10.0)
