class_name PoolPoses
## Session 81 (people): the poses for the pools, made in code like the other poses in
## scripts/person_pose.gd (bones pointed at spots, like a puppet on strings).
##   swim():    swimming laps, front crawl or breaststroke, head up out of the water.
##              The swimmer lies face down (scripts/pool_swimmers.gd tips the whole person
##              forward), so on the person "forward" (where the head goes) is +Y and
##              "up out of the water" is +Z.
##   rest():    standing in the water with both arms folded on the pool edge (pose.hands).
##   whistle(): the lifeguard: whistle to the mouth, the other arm pointing at the pool.


## How far through one stroke the swimmer is (0 to 1).
static func stroke_part(pose: PersonPose) -> float:
	return fposmod(pose.clock * GameConfig.SWIM_STROKE_RATE + pose.stroke_start, 1.0)


static func swim(pose: PersonPose) -> void:
	if pose.stroke == "breast":
		_breaststroke(pose, stroke_part(pose))
	else:
		_crawl(pose, stroke_part(pose))


## Front crawl: one arm pulls under the water while the other swings over the top, the body
## rolls a little from side to side and the legs kick fast (3 kicks per arm).
static func _crawl(pose: PersonPose, part: float) -> void:
	var t := part * TAU
	var roll := sin(t) * 0.35
	pose.turn("Spine1", Vector3.UP, roll)
	for side in [-1.0, 1.0]:
		var name := "Left" if side < 0.0 else "Right"
		var arm := fposmod(t + (0.0 if side < 0.0 else PI), TAU)
		var hand: Vector3
		var elbow: Vector3
		if arm < PI:  # the pull: from out in front, down under the body, back to the hip
			var u := arm / PI
			hand = Vector3(side * 0.2, lerpf(2.0, 0.95, smoothstep(0.0, 1.0, u)), -0.12 - sin(u * PI) * 0.3)
			elbow = Vector3(side, 0.2, 0.6)
		else:  # the swing over the top: out of the water at the hip, forward through the air
			var u := (arm - PI) / PI
			hand = Vector3(side * (0.28 + sin(u * PI) * 0.12), lerpf(1.0, 2.0, pow(u, 0.7)), 0.03 + sin(u * PI) * 0.22)
			elbow = Vector3(side * 0.5, -0.2, 1.0)  # elbow high, hand low over the water
		pose.reach(name + "Arm", name + "ForeArm", name + "Hand", hand, elbow)
		var kick := sin(t * 3.0 + (0.0 if side < 0.0 else PI))
		pose.point(name + "UpLeg", name + "Leg", Vector3(side * 0.06, -1.0, kick * 0.18))
		pose.point(name + "Leg", name + "Foot", Vector3(side * 0.04, -1.0, kick * 0.3 + 0.08))
		pose.point(name + "Foot", name + "ToeBase", Vector3(0, -1.0, 0.25))  # pointed toes
	# Head up and looking ahead (the swimmers keep their faces out of the water).
	pose.turn("Head", Vector3.UP, -roll * 0.8)
	pose.turn("Neck", Vector3.RIGHT, deg_to_rad(GameConfig.SWIM_CHIN_UP_DEG * 0.4))
	pose.turn("Head", Vector3.RIGHT, deg_to_rad(GameConfig.SWIM_CHIN_UP_DEG * 0.6))


## Breaststroke: the hands sweep out and round to the chin, shoot forward together, then a
## frog kick and a glide. The head comes up a bit more while the arms pull.
static func _breaststroke(pose: PersonPose, part: float) -> void:
	for side in [-1.0, 1.0]:
		var name := "Left" if side < 0.0 else "Right"
		# The hands: [part of the stroke, where the hand is].
		var hand := _keys(part, [
			[0.0, Vector3(side * 0.08, 2.05, -0.08)],   # out in front, together
			[0.25, Vector3(side * 0.5, 1.75, -0.15)],   # sweep out wide
			[0.42, Vector3(side * 0.12, 1.35, -0.2)],   # round in under the chin
			[0.62, Vector3(side * 0.08, 2.05, -0.08)],  # shoot forward
			[1.0, Vector3(side * 0.08, 2.05, -0.08)],   # glide
		])
		pose.reach(name + "Arm", name + "ForeArm", name + "Hand", hand, Vector3(side, -0.3, 0.4))
		# The feet: straight, then heels up to the bottom, then kick out round and together.
		var foot := _keys(part, [
			[0.0, Vector3(side * 0.09, 0.02, 0.0)],
			[0.4, Vector3(side * 0.09, 0.02, 0.0)],
			[0.58, Vector3(side * 0.22, 0.45, 0.32)],   # heels up
			[0.72, Vector3(side * 0.45, 0.1, 0.05)],    # kick out wide
			[0.85, Vector3(side * 0.09, 0.02, 0.0)],    # and together
			[1.0, Vector3(side * 0.09, 0.02, 0.0)],
		])
		pose.reach(name + "UpLeg", name + "Leg", name + "Foot", foot, Vector3(side, 0.0, -1.0))
	var breathe := sin(clampf(part / 0.5, 0.0, 1.0) * PI)  # head highest while the arms pull
	pose.turn("Neck", Vector3.RIGHT, deg_to_rad(GameConfig.SWIM_CHIN_UP_DEG * (0.3 + 0.2 * breathe)))
	pose.turn("Head", Vector3.RIGHT, deg_to_rad(GameConfig.SWIM_CHIN_UP_DEG * (0.5 + 0.2 * breathe)))


## How far the breaststroke swimmer surges forward right now (1 = average speed).
static func breaststroke_push(part: float) -> float:
	# Fastest just after the kick, slowest while the knees come up.
	return 0.55 + 0.9 * maxf(sin((part - 0.62) / 0.38 * PI), 0.0) if part > 0.62 else 0.55 + 0.35 * sin(part / 0.62 * PI)


## Standing in the water with both forearms on the edge (pose.hands), legs paddling slowly.
static func rest(pose: PersonPose) -> void:
	for side in [-1.0, 1.0]:
		var name := "Left" if side < 0.0 else "Right"
		var hand: Vector3 = pose.hands[0 if side < 0.0 else 1]
		pose.reach(name + "Arm", name + "ForeArm", name + "Hand", hand, Vector3(side, -0.6, 0.2))
		var paddle := sin(pose.clock * 1.4 + side) * 0.15
		pose.point(name + "UpLeg", name + "Leg", Vector3(side * 0.1, -1.0, paddle))


## The lifeguard: whistle to the mouth with the right hand, left arm pointing at the pool.
static func whistle(pose: PersonPose) -> void:
	var person := pose.person
	var mouth := person.head_spot() + Vector3(0, -0.07, -0.12)
	pose.reach("RightArm", "RightForeArm", "RightHand", mouth + Vector3(0.03, -0.05, -0.05), Vector3(1, -1, 0))
	pose.point("LeftArm", "LeftForeArm", Vector3(-0.35, 0.45, -1.0))
	pose.point("LeftForeArm", "LeftHand", Vector3(-0.3, 0.55, -1.0))
	pose.turn("Head", Vector3.RIGHT, deg_to_rad(8.0))  # chin up a little


## Where something is part-way through a list of [part, spot] keys (a smooth blend).
static func _keys(part: float, keys: Array) -> Vector3:
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if part <= b[0]:
			var u := smoothstep(0.0, 1.0, (part - a[0]) / maxf(b[0] - a[0], 0.0001))
			return (a[1] as Vector3).lerp(b[1], u)
	return keys[-1][1]
