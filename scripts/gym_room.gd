class_name GymRoom
## Session 60: the Wahat Gym, a real gym instead of a restaurant room. 24 x 13 m, 6 m tall.
## In its own directions (+z is the street side, -z the pool side):
##   - the street side is rounded, with the door in the middle and reception just inside
##     (the drop-off: a curved white desk, the staff member and a smoothie cooler)
##   - the pool side is one big glass wall onto the lap pool
##   - cardio by the glass, facing out: 4 treadmills, 3 bikes and 2 rowers
##   - free weights away from the glass on black rubber tiles: a squat rack on a wooden
##     platform with a loaded barbell, a dumbbell rack, 2 benches and 6 kettlebells, and a
##     mirror wall with "Train hard · تمرّن بقوة" (mirrors face the weights, not the treadmills)
##   - stretching mats in a corner, a water fountain and a towel stand
##   - people running, cycling, rowing, squatting and stretching (scripts/gym_motion.gd)
## Real layouts put cardio by the windows and weights in their own zone, 1 to 2 m round
## every machine (PRD.md, "Layouts").

const CREAM := Color(0.95, 0.92, 0.85)
const WHITE := Color(0.97, 0.97, 0.96)
const TEAL := Color(0.16, 0.56, 0.61)
const FLOOR := Color(0.62, 0.64, 0.66)
const RUBBER := Color(0.12, 0.12, 0.13)
const DARK := Color(0.15, 0.16, 0.18)
const STEEL := Color(0.7, 0.72, 0.75)
const WOOD := Color(0.62, 0.45, 0.28)
const GLASS := Color(0.46, 0.7, 0.77)
const PLATE_COLOURS := [Color(0.8, 0.15, 0.15), Color(0.15, 0.3, 0.75), Color(0.95, 0.8, 0.15)]
const ARC_DEPTH := 4.0
const ARC_PIECES := 24


## Builds the gym. place: the VILLAS entry (with name and arabic). size: 24 x 6 x 13.
static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", "gym")
	body.set_meta("rounded_back", true)
	body.set_meta("real_gym", true)
	var motion := GymMotion.new()
	motion.name = "GymMotion"
	body.add_child(motion, true)
	_shell(body, place, size)
	var counter: Vector3 = place.get("counter", VenueBuilder.counter_local(size))
	_reception(body, counter)
	_cardio(body, size, motion)
	_weights(body, size, motion)
	_corner(body, size, motion)
	return body


## Floor, walls, the glass wall, the rounded street side with the door, roof, sign, lights.
static func _shell(body: StaticBody3D, place: Dictionary, size: Vector3) -> void:
	var half := size * 0.5
	var arc_z := half.z - ARC_DEPTH   # where the straight side walls end and the curve begins
	LowPoly.box(body, Vector3(size.x, 0.06, half.z + arc_z), FLOOR, Vector3(0, 0.03, (arc_z - half.z) * 0.5))
	_fan(body, half.x, arc_z, 0.06, FLOOR)   # the floor under the curve
	# The glass wall onto the pool: tall panes between white frames.
	var glass := _wall(body, Vector3(size.x, size.y, 0.12), Vector3(0, half.y, -half.z), 0.0, GLASS)
	glass.name = "PoolGlass"
	var clear := LowPoly.material(GLASS).duplicate() as StandardMaterial3D
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color.a = 0.22
	glass.material_override = clear
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 9:
		LowPoly.box(body, Vector3(0.12, size.y, 0.2), WHITE, Vector3(-half.x + i * size.x / 8.0, half.y, -half.z))
	for y in [0.15, 3.0, size.y - 0.1]:
		LowPoly.box(body, Vector3(size.x, 0.2 if y > 0.2 else 0.3, 0.2), WHITE, Vector3(0, y, -half.z))
	# Straight side walls, then the rounded street side with the doorway in the middle.
	for side in [-1.0, 1.0]:
		_wall(body, Vector3(0.25, size.y, arc_z + half.z), Vector3(side * half.x, half.y, (arc_z - half.z) * 0.5), 0.0, CREAM)
	for i in ARC_PIECES:
		var a := PI * i / ARC_PIECES
		var b := PI * (i + 1) / ARC_PIECES
		var p := Vector3(cos(a) * half.x, 0, arc_z + sin(a) * ARC_DEPTH)
		var q := Vector3(cos(b) * half.x, 0, arc_z + sin(b) * ARC_DEPTH)
		if absf((p.x + q.x) * 0.5) < 1.4:
			continue   # the doorway
		var turn := -atan2(q.z - p.z, q.x - p.x)
		_wall(body, Vector3(p.distance_to(q) + 0.1, size.y, 0.25), (p + q) * 0.5 + Vector3.UP * half.y, turn, CREAM)
		if i % 2 == 1 and absf((p.x + q.x) * 0.5) > 4.5:
			# Tall slim windows round the curve, so the street side isn't a blank wall.
			var along := (q - p).normalized()
			var out := Vector3(along.z, 0, -along.x)   # square to the wall...
			if out.dot((p + q) * 0.5 - Vector3(0, 0, arc_z)) < 0.0:
				out = -out                               # ...pointing outside
			out *= 0.14
			var pane := LowPoly.box(body, Vector3(p.distance_to(q) * 0.55, 3.2, 0.04), GLASS.darkened(0.35), (p + q) * 0.5 + out + Vector3.UP * 2.3)
			pane.rotation.y = turn
			pane.name = "StreetWindow"
	_doorway(body, half)
	# Roof: a flat slab over the straight part and a fan over the curve.
	LowPoly.box(body, Vector3(size.x + 0.3, 0.25, arc_z + half.z + 0.15), CREAM, Vector3(0, size.y + 0.12, (arc_z - half.z) * 0.5 - 0.07))
	_fan(body, half.x + 0.15, arc_z, size.y + 0.25, CREAM)
	LowPoly.box(body, Vector3(size.x + 0.4, 0.35, 0.3), TEAL, Vector3(0, size.y + 0.1, -half.z - 0.05))
	# The bilingual sign over the door, and a teal band round the top of the curve.
	var font := SignText.fit_size(place.get("arabic", ""), place.get("name", "Wahat Gym"), 64, 8.0)
	var sign := SignText.make_face(place.get("arabic", ""), place.get("name", "Wahat Gym"), font, Color.WHITE)
	sign.name = "BilingualSign"
	sign.position = Vector3(0, 4.6, half.z + 0.2)
	body.add_child(sign, true)
	LowPoly.box(body, Vector3(8.6, 1.5, 0.14), TEAL, Vector3(0, 4.6, half.z + 0.1))
	LowPoly.box(body, Vector3(4.6, 0.15, 1.1), TEAL, Vector3(0, 3.15, half.z + 0.5))   # entrance canopy (no posts: the road is right there)
	LowPoly.box(body, Vector3(size.x * 0.6, 0.3, 0.1), TEAL, Vector3(0, size.y - 0.4, half.z + 0.05))
	for x in [-0.25 * size.x, 0.25 * size.x]:
		var light := OmniLight3D.new()
		light.name = "GymLight"
		light.position = Vector3(x, size.y - 0.8, -0.5)
		light.light_color = Color(1.0, 0.95, 0.88)
		light.light_energy = 1.8
		light.omni_range = 13.0
		light.shadow_enabled = false
		body.add_child(light, true)
	for x in range(-9, 10, 3):   # long ceiling lamps
		LowPoly.box(body, Vector3(0.2, 0.06, 7.0), Color(1, 0.98, 0.9), Vector3(x, size.y - 0.15, -2.0))


## The doorway: frame posts and two glass doors slid open to the sides.
static func _doorway(body: StaticBody3D, half: Vector3) -> void:
	for x in [-1.55, 1.55]:
		LowPoly.box(body, Vector3(0.18, 2.8, 0.3), DARK, Vector3(x, 1.4, half.z - 0.05))
	LowPoly.box(body, Vector3(3.3, 0.25, 0.3), DARK, Vector3(0, 2.85, half.z - 0.05))
	LowPoly.box(body, Vector3(3.1, half.y * 2.0 - 2.95, 0.25), CREAM, Vector3(0, (half.y * 2.0 + 2.95) * 0.5, half.z - 0.05))
	for x in [-2.2, 2.2]:
		var door := LowPoly.box(body, Vector3(1.4, 2.6, 0.05), GLASS, Vector3(x, 1.3, half.z - 0.35))
		var clear := LowPoly.material(GLASS).duplicate() as StandardMaterial3D
		clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		clear.albedo_color.a = 0.35
		door.material_override = clear
	LowPoly.box(body, Vector3(2.4, 0.02, 1.4), DARK, Vector3(0, 0.07, half.z - 0.9))   # door mat


## Reception just inside the door: a curved white desk, the staff member behind it and the
## smoothie cooler (the drop-off). counter: where you stand.
static func _reception(body: StaticBody3D, counter: Vector3) -> void:
	var desk_z := counter.z - 1.2
	var radius := 2.0
	for i in 7:   # pieces round a circle, each turned along it, so they join into one curve
		var a := deg_to_rad(-45.0 + i * 15.0)
		var at := Vector3(sin(a) * radius, 0.55, desk_z - radius + cos(a) * radius)
		var piece := _wall(body, Vector3(0.58, 1.1, 0.45), at, a, WHITE)
		piece.name = "ReceptionDesk"
		var top := LowPoly.box(body, Vector3(0.62, 0.05, 0.6), WOOD, at + Vector3(0, 0.575, 0))
		top.rotation.y = a
	var staff := PeopleLooks.resident(4, 1)
	staff.name = "CounterStaff"
	staff.repaint({"shirt": TEAL, "pants": DARK})
	staff.position = Vector3(0, 0, desk_z - 1.0)
	staff.rotation.y = PI
	body.add_child(staff, true)
	# The smoothie cooler: a glass-front fridge of coloured bottles behind the desk.
	var cooler := Vector3(2.4, 0, desk_z - 1.6)
	var cooler_box := _wall(body, Vector3(0.8, 2.0, 0.7), cooler + Vector3(0, 1.0, 0), PI, WHITE)
	cooler_box.name = "SmoothieCooler"
	LowPoly.box(body, Vector3(0.66, 1.6, 0.04), Color(0.75, 0.9, 0.95), cooler + Vector3(0, 1.05, 0.36))
	for row in 3:
		for i in 4:
			LowPoly.cylinder(body, 0.05, 0.05, 0.22, [Color(0.95, 0.5, 0.6), Color(0.6, 0.85, 0.3), Color(1, 0.75, 0.2)][(row + i) % 3],
					cooler + Vector3(-0.22 + i * 0.15, 0.55 + row * 0.5, 0.25))
	var label := SignText.make_face("عصائر", "Smoothies", 28, Color.WHITE, TEAL, 3)
	label.position = cooler + Vector3(0, 2.15, 0.36)
	body.add_child(label, true)


## Treadmills, bikes and rowers in a row 1.5 m in from the glass, facing out at the pool.
static func _cardio(body: StaticBody3D, size: Vector3, motion: GymMotion) -> void:
	var front := -size.z * 0.5 + 1.5
	for i in 4:
		var runner := _treadmill(body, Vector3(-10.0 + i * 1.8, 0, front), i == 0 or i == 2)
		if runner != null:
			motion.runners.append(runner)
	for i in 3:
		var rider := _exercise_bike(body, Vector3(-2.2 + i * 1.5, 0, front), i == 1)
		if rider != null:
			motion.cyclists.append(rider)
	for i in 2:
		_rower(body, Vector3(3.0 + i * 1.5, 0, front), i == 0, motion)


static func _treadmill(body: StaticBody3D, front: Vector3, used: bool) -> Person:
	var middle := front + Vector3(0, 0, 1.0)
	var belt_deck := _wall(body, Vector3(0.85, 0.22, 2.0), middle + Vector3(0, 0.11, 0), 0.0, DARK)
	belt_deck.name = "Treadmill"
	LowPoly.box(body, Vector3(0.52, 0.02, 1.6), Color(0.05, 0.05, 0.05), middle + Vector3(0, 0.23, 0.05))
	for x in [-0.38, 0.38]:
		var post := LowPoly.box(body, Vector3(0.07, 1.25, 0.07), STEEL, front + Vector3(x, 0.8, 0.2))
		post.rotation.x = deg_to_rad(-12.0)
		LowPoly.box(body, Vector3(0.05, 0.05, 0.45), STEEL, front + Vector3(x, 1.05, 0.5))
	var console := LowPoly.box(body, Vector3(0.8, 0.32, 0.12), DARK, front + Vector3(0, 1.38, 0.08))
	console.rotation.x = deg_to_rad(25.0)
	LowPoly.box(body, Vector3(0.4, 0.2, 0.02), Color(0.3, 0.75, 0.9), front + Vector3(0, 1.4, 0.15))
	if not used:
		return null
	var runner := PeopleLooks.resident(2 + int(front.x) % 3, int(absf(front.x)) % 4)
	runner.name = "Runner"
	runner.repaint({"shirt": Color(0.95, 0.45, 0.2) if int(front.x) % 2 == 0 else Color(0.3, 0.3, 0.35), "pants": Color(0.12, 0.12, 0.15)})
	runner.position = middle + Vector3(0, 0.24, 0.0)
	body.add_child(runner, true)
	return runner


static func _exercise_bike(body: StaticBody3D, front: Vector3, used: bool) -> Person:
	var frame := front + Vector3(0, 0, 0.6)
	var bike_base := _wall(body, Vector3(0.5, 0.1, 1.1), frame + Vector3(0, 0.05, 0), 0.0, DARK)
	bike_base.name = "ExerciseBike"
	# The flywheel is a bit thicker (0.1) than the post (0.08) through it, so their sides don't flicker.
	var wheel := LowPoly.cylinder(body, 0.25, 0.25, 0.1, STEEL, front + Vector3(0, 0.35, 0.25))
	wheel.rotation.z = PI * 0.5
	var post := LowPoly.box(body, Vector3(0.08, 0.9, 0.08), DARK, front + Vector3(0, 0.6, 0.25))
	post.rotation.x = deg_to_rad(-15.0)
	LowPoly.box(body, Vector3(0.5, 0.05, 0.08), DARK, front + Vector3(0, 1.1, 0.12))   # handlebar
	LowPoly.box(body, Vector3(0.08, 0.8, 0.08), DARK, front + Vector3(0, 0.45, 0.9))    # seat post
	LowPoly.box(body, Vector3(0.24, 0.07, 0.3), Color(0.1, 0.1, 0.1), front + Vector3(0, 0.88, 0.9))
	if not used:
		return null
	var rider := PeopleLooks.resident(3, 2)
	rider.name = "Cyclist"
	rider.repaint({"shirt": Color(0.2, 0.6, 0.45), "pants": Color(0.12, 0.12, 0.15)})
	rider.position = front + Vector3(0, 0.93 - rider.spot("Hips").y, 0.95)
	rider.set_meta("crank", Vector3(0, 0.4, 0.45) - Vector3(0, 0.93 - rider.spot("Hips").y, 0.95))   # on the person
	rider.set_meta("bar", Vector3(0, 1.12, 0.12) - Vector3(0, 0.93 - rider.spot("Hips").y, 0.95))
	body.add_child(rider, true)
	rider.play("pedal")
	rider.pose.lean = 20.0
	return rider


static func _rower(body: StaticBody3D, front: Vector3, used: bool, motion: GymMotion) -> void:
	var flywheel := _wall(body, Vector3(0.5, 0.45, 0.5), front + Vector3(0, 0.3, 0.25), 0.0, DARK)
	flywheel.name = "Rower"   # flywheel box
	var wheel := LowPoly.cylinder(body, 0.22, 0.22, 0.52, Color(0.25, 0.25, 0.28), front + Vector3(0, 0.32, 0.25))
	wheel.rotation.z = PI * 0.5
	LowPoly.box(body, Vector3(0.14, 0.12, 2.0), STEEL, front + Vector3(0, 0.12, 1.4))     # the rail
	LowPoly.solid_box(body, Vector3(0.5, 0.4, 2.4), front + Vector3(0, 0.2, 1.2))
	LowPoly.box(body, Vector3(0.36, 0.05, 0.25), DARK, front + Vector3(0, 0.27, 0.6))      # footplate
	var moving := Node3D.new()
	moving.name = "RowerSeat"
	moving.set_meta("static_batch_dynamic", true)
	moving.position = front
	body.add_child(moving, true)
	var seat := LowPoly.box(moving, Vector3(0.3, 0.07, 0.32), Color(0.1, 0.1, 0.1), Vector3(0, 0.22, 1.1))
	var handle := LowPoly.box(moving, Vector3(0.5, 0.04, 0.04), DARK, Vector3(0, 0.5, 0.6))
	if not used:
		return
	var rower := PeopleLooks.resident(2, 3)
	rower.name = "RowerPerson"
	rower.repaint({"shirt": Color(0.9, 0.85, 0.3), "pants": Color(0.12, 0.12, 0.15)})
	moving.add_child(rower)
	rower.play("row")
	motion.rowers.append([rower, seat, handle, front])


## The free weights zone at the back on black rubber, away from the glass and the walkway.
static func _weights(body: StaticBody3D, size: Vector3, motion: GymMotion) -> void:
	var zone := Rect2(-size.x * 0.5 + 0.4, -1.9, 7.4, 4.6)
	LowPoly.box(body, Vector3(zone.size.x, 0.02, zone.size.y), RUBBER, Vector3(zone.get_center().x, 0.07, zone.get_center().y))
	for i in 7:   # tile lines
		LowPoly.box(body, Vector3(0.02, 0.005, zone.size.y), Color(0.2, 0.2, 0.21), Vector3(zone.position.x + i * 1.0 + 0.5, 0.082, zone.get_center().y))
	# Mirror wall on the side wall, facing the weights, with the motto above it.
	var mirror := LowPoly.box(body, Vector3(0.04, 2.0, 4.4), Color(0.85, 0.88, 0.9), Vector3(-size.x * 0.5 + 0.15, 1.4, 0.35))
	var shine := StandardMaterial3D.new()
	shine.albedo_color = Color(0.8, 0.85, 0.88)
	shine.metallic = 1.0
	shine.roughness = 0.04
	mirror.material_override = shine
	mirror.name = "MirrorWall"
	var motto := SignText.make_face("تمرّن بقوة", "Train hard", 44, Color.WHITE, DARK, 5)
	motto.name = "TrainHard"
	motto.position = Vector3(-size.x * 0.5 + 0.2, 2.95, 0.35)
	motto.rotation.y = PI * 0.5
	body.add_child(motto, true)
	# Squat rack on a wooden platform, facing the mirror, with a loaded barbell.
	var rack := Vector3(-8.0, 0, 0.6)
	LowPoly.box(body, Vector3(2.4, 0.05, 3.0), WOOD, rack + Vector3(0, 0.1, 0))
	for x in [-0.6, 0.6]:
		for z in [-0.7, 0.7]:
			LowPoly.box(body, Vector3(0.08, 2.3, 0.08), DARK, rack + Vector3(x, 1.15, z))
		LowPoly.box(body, Vector3(0.08, 0.08, 1.4), DARK, rack + Vector3(x, 2.3, 0))
	LowPoly.solid_box(body, Vector3(1.3, 2.3, 0.12), rack + Vector3(0, 1.15, 1.0))   # the uprights you can bump
	var lifter := PeopleLooks.resident(3, 0)
	lifter.name = "Lifter"
	lifter.repaint({"shirt": Color(0.2, 0.2, 0.22), "pants": Color(0.3, 0.35, 0.45)})
	lifter.position = rack + Vector3(0, 0.12, 0)
	lifter.rotation.y = PI * 0.5   # faces the mirror
	body.add_child(lifter, true)
	lifter.play("squat")
	var neck := lifter.follow("Neck")
	var bar_at := lifter.spot("Neck") + Vector3(0, -0.06, 0.1)
	var bar := LowPoly.cylinder(neck, 0.02, 0.02, 2.1, STEEL, bar_at)
	bar.rotation.z = PI * 0.5
	for side in [-1.0, 1.0]:
		for k in 2:
			var plate := LowPoly.cylinder(neck, 0.23 - k * 0.04, 0.23 - k * 0.04, 0.05, PLATE_COLOURS[k], bar_at + Vector3(side * (0.75 + k * 0.06), 0, 0))
			plate.rotation.z = PI * 0.5
	motion.lifter = lifter
	motion.lifter_base = lifter.position
	# Dumbbell rack along the back of the zone, two shelves of pairs.
	var dumbbells := Vector3(-8.3, 0, -1.4)
	var rack_shelf := _wall(body, Vector3(2.6, 0.08, 0.55), dumbbells + Vector3(0, 0.45, 0), 0.0, DARK)
	rack_shelf.name = "DumbbellRack"
	LowPoly.box(body, Vector3(2.6, 0.08, 0.55), DARK, dumbbells + Vector3(0, 0.8, 0))
	for x in [-1.25, 1.25]:
		LowPoly.box(body, Vector3(0.06, 0.85, 0.5), DARK, dumbbells + Vector3(x, 0.42, 0))
	for shelf in [0.53, 0.88]:
		for i in 6:
			var at := dumbbells + Vector3(-1.05 + i * 0.42, shelf, 0)
			LowPoly.box(body, Vector3(0.03, 0.03, 0.3), STEEL, at)
			for z in [-0.14, 0.14]:
				var weight := LowPoly.cylinder(body, 0.05 + i * 0.008, 0.05 + i * 0.008, 0.06, RUBBER, at + Vector3(0, 0.02, z))
				weight.rotation.x = PI * 0.5
	for i in 2:   # flat benches
		var bench := Vector3(-4.6, 0, -0.9 + i * 2.4)
		var pad := _wall(body, Vector3(0.32, 0.08, 1.2), bench + Vector3(0, 0.45, 0), 0.0, DARK)
		pad.name = "WeightBench"
		LowPoly.box(body, Vector3(0.08, 0.42, 0.08), STEEL, bench + Vector3(0, 0.21, -0.45))
		LowPoly.box(body, Vector3(0.08, 0.42, 0.08), STEEL, bench + Vector3(0, 0.21, 0.45))
	for i in 6:   # kettlebells in a row
		var bell := Vector3(-10.6 + i * 0.45, 0, 2.35)
		LowPoly.sphere(body, 0.11 + i * 0.01, 0.2 + i * 0.02, [DARK, Color(0.8, 0.2, 0.15), Color(0.2, 0.5, 0.8)][i % 3], bell + Vector3(0, 0.18, 0))
		LowPoly.box(body, Vector3(0.16, 0.04, 0.04), DARK, bell + Vector3(0, 0.33 + i * 0.015, 0))


## The other side: stretching mats in the corner by the glass, water fountain, towel stand, plants.
static func _corner(body: StaticBody3D, size: Vector3, motion: GymMotion) -> void:
	var mats := Vector3(size.x * 0.5 - 3.0, 0, -size.z * 0.5 + 2.6)
	for i in 3:
		LowPoly.box(body, Vector3(0.65, 0.02, 1.8), [Color(0.55, 0.3, 0.65), TEAL, Color(0.95, 0.55, 0.4)][i],
				mats + Vector3(-1.0 + i * 1.0, 0.075, 0))
	var stretcher := PeopleLooks.resident(1, 3)
	stretcher.name = "Stretcher"
	stretcher.repaint({"shirt": Color(0.95, 0.6, 0.7), "pants": Color(0.2, 0.2, 0.25)})
	stretcher.position = mats + Vector3(0, 0.12 - stretcher.spot("Hips").y + 0.06, 0.55)
	body.add_child(stretcher, true)
	stretcher.play("stretch")
	# Water fountain and a towel stand on the side wall.
	var wall_x := size.x * 0.5 - 0.35
	var fountain := _wall(body, Vector3(0.45, 1.0, 0.4), Vector3(wall_x, 0.5, 0.6), 0.0, STEEL)
	fountain.name = "WaterFountain"
	LowPoly.box(body, Vector3(0.4, 0.06, 0.35), Color(0.85, 0.87, 0.9), Vector3(wall_x - 0.02, 1.02, 0.6))
	var towels := _wall(body, Vector3(0.5, 1.2, 0.9), Vector3(wall_x - 0.05, 0.6, 2.0), 0.0, WOOD)
	towels.name = "TowelStand"
	for row in 3:
		for i in 3:
			LowPoly.box(body, Vector3(0.4, 0.12, 0.25), [WHITE, TEAL, WHITE][row], Vector3(wall_x - 0.1, 0.35 + row * 0.35, 1.75 + i * 0.27))
	# A row of teal lockers with a bench in front, near the door.
	for i in 8:
		var locker := Vector3(5.0 + i * 0.5, 0, 4.3)
		var box := _wall(body, Vector3(0.48, 1.9, 0.5), locker + Vector3(0, 0.95, 0), 0.0, TEAL if i % 2 == 0 else TEAL.darkened(0.12))
		box.name = "Locker"
		LowPoly.box(body, Vector3(0.04, 0.12, 0.02), STEEL, locker + Vector3(0.15, 1.1, -0.26))
	var bench := _wall(body, Vector3(3.6, 0.08, 0.4), Vector3(6.75, 0.45, 3.4), 0.0, WOOD)
	bench.name = "LockerBench"
	for x in [5.2, 8.3]:
		LowPoly.box(body, Vector3(0.08, 0.42, 0.35), STEEL, Vector3(x, 0.21, 3.4))
	# A teal stripe round the inside walls.
	for side in [-1.0, 1.0]:
		LowPoly.box(body, Vector3(0.04, 0.35, size.z - ARC_DEPTH), TEAL, Vector3(side * (size.x * 0.5 - 0.15), 3.6, -ARC_DEPTH * 0.5))
	for at in [Vector3(wall_x - 0.3, 0, -1.6), Vector3(-size.x * 0.5 + 0.8, 0, -size.z * 0.5 + 0.8)]:
		LowPoly.cylinder(body, 0.35, 0.25, 0.6, WOOD, at + Vector3.UP * 0.3)
		LowPoly.sphere(body, 0.5, 1.3, Color(0.28, 0.55, 0.26), at + Vector3.UP * 1.1)


## A box that's also solid (the bike and the walker bump into it). angle: turn about y.
static func _wall(body: StaticBody3D, size: Vector3, at: Vector3, angle: float, colour: Color) -> MeshInstance3D:
	var view := LowPoly.box(body, size, colour, at)
	view.rotation.y = angle
	var shape := LowPoly.solid_box(body, size, at)
	shape.rotation.y = angle
	return view


## A flat half-disc (the floor or roof over the rounded side). half_x: its radius along x.
static func _fan(body: StaticBody3D, half_x: float, arc_z: float, y: float, colour: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre := Vector3(0, y, arc_z)
	for i in ARC_PIECES:
		var a := PI * i / ARC_PIECES
		var b := PI * (i + 1) / ARC_PIECES
		for corner in [centre, Vector3(cos(a) * half_x, y, arc_z + sin(a) * ARC_DEPTH), Vector3(cos(b) * half_x, y, arc_z + sin(b) * ARC_DEPTH)]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corner)
	var view := MeshInstance3D.new()
	view.mesh = tool.commit()
	var both_sides := LowPoly.material(colour).duplicate() as StandardMaterial3D
	both_sides.cull_mode = BaseMaterial3D.CULL_DISABLED   # the roof is seen from inside too
	view.material_override = both_sides
	body.add_child(view, true)
