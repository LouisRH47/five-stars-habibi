class_name GymRoom
extends RefCounted
## Looks pass Session 56: the Wahat Gym as a real gym. The building keeps its size
## (36 x 8 x 22 m) and its rounded back; the front (local +Z) faces the spine and the
## lap pool is outside the left side (local -X), so both of those walls are glass.
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
	for i in 4:
		_treadmill(body, Vector3(-15.0 + i * 2.5, 0, 8.2), i, i < 3, motion)
	for i in 3:
		_exercise_bike(body, Vector3(7.0 + i * 2.4, 0, 8.4), i, i != 1, motion)
	for i in 2:
		_rower(body, Vector3(-15.6, 0, 3.6 - i * 2.6), i, motion)
	_mirror_wall(body, size)
	_dumbbell_rack(body, Vector3(16.9, 0, 4.0))
	_squat_rack(body, Vector3(12.0, 0, -2.6), motion)
	_mats_and_kettlebells(body, motion)
	RoomProps.big_plant(body, Vector3(-17.0, 0, 10.0))
	RoomProps.big_plant(body, Vector3(17.0, 0, 10.0))
	RoomProps.bin(body, Vector3(-2.2, 0, 3.2))
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
	# The right wall (the mirror is on its inside).
	VenueParts.block(body, Vector3(0.25, size.y, straight), CREAM, Vector3(half, size.y * 0.5, mid))
	# The pool side: glass up to the ceiling, a cream band above.
	VenueParts.glass_run(body, Vector3(-half, 0, arc), Vector3(-half, 0, front), CEILING, 3.0)
	VenueParts.block(body, Vector3(0.25, size.y - CEILING, straight), CREAM, Vector3(-half, (size.y + CEILING) * 0.5, mid))
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
	var y := (size.y + CEILING) * 0.5
	LowPoly.box(body, Vector3(14, 1.7, 0.12), tint.darkened(0.35), Vector3(0, y, front + 0.19))
	var sign := SignText.make_face(place.get("arabic", ""), place.get("name", "Wahat Gym"), 50, Color.WHITE)
	sign.name = "BilingualSign"
	sign.position = Vector3(0, y, front + 0.27)
	body.add_child(sign)


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
	var mirror := LowPoly.box(body, Vector3(0.03, 2.4, 14.0), Color.WHITE, Vector3(x, 1.45, 2.4))
	mirror.name = "MirrorWall"
	var silver := StandardMaterial3D.new()
	silver.albedo_color = Color(0.8, 0.85, 0.88)
	silver.metallic = 1.0
	silver.roughness = 0.05
	mirror.material_override = silver
	LowPoly.box(body, Vector3(0.05, 0.08, 14.2), DARK, Vector3(x, 2.68, 2.4))
	LowPoly.box(body, Vector3(0.05, 0.08, 14.2), DARK, Vector3(x, 0.22, 2.4))
	var words := SignText.make_face("تمرّن بقوة", "Train hard", 60, Color(0.1, 0.5, 0.56))
	words.name = "TrainHard"
	words.position = Vector3(x - 0.04, 3.55, 2.4)
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
		var mat := LowPoly.box(body, Vector3(0.7, 0.012, 1.85), MATS[i], Vector3(-12.0 + i * 2.2, 0.067, -3.4))
		mat.name = "YogaMat%d" % i
	var stretcher := PlaceLooks.gym_goer(5)
	stretcher.name = "Stretcher"
	var hips := stretcher.spot("Hips")
	stretcher.position = Vector3(-9.8, 0.2, -2.9) - hips
	body.add_child(stretcher, true)
	stretcher.play("pedal")
	for side in 2:
		var x := -0.12 if side == 0 else 0.12
		stretcher.pose.feet[side] = Vector3(x, hips.y - 0.08, -0.8)
		stretcher.pose.hands[side] = Vector3(x * 1.3, hips.y + 0.1, -0.65)
	motion.stretchers.append(stretcher)
	for i in 6:
		var at := Vector3(-12.6 + i * 1.0, 0, -5.6)
		var size := 0.12 + (i % 3) * 0.03
		var bell := LowPoly.sphere(body, size, size * 1.8, [DARK, Color(0.85, 0.5, 0.1), Color(0.2, 0.5, 0.3)][i % 3], at + Vector3(0, 0.06 + size * 0.9, 0))
		bell.name = "Kettlebell%d" % i
		var grip := LowPoly.box(body, Vector3(size * 1.2, size * 0.9, 0.04), DARK, at + Vector3(0, 0.06 + size * 1.9, 0))
		grip.name = "KettlebellHandle%d" % i


static func _lights(body: StaticBody3D) -> void:
	for x in [-13.0, -6.5, 0.0, 6.5, 13.0]:
		for z in [-3.5, 2.5, 7.8]:
			VenueParts.ceiling_light(body, Vector3(x, 0, z), Vector2(2.4, 0.6), CEILING)
	VenueParts.room_light(body, "InteriorLight", Vector3(0, CEILING - 0.7, 4.5), 1.6, 17.0, true, Color(1, 0.96, 0.9))
	VenueParts.room_light(body, "BackLight", Vector3(-9, CEILING - 0.7, -3.0), 1.1, 12.0)
	VenueParts.room_light(body, "WeightsLight", Vector3(10, CEILING - 0.7, -1.0), 1.1, 12.0)
