class_name AlivePose
## Session 83: small movements on top of standing and sitting, so nobody looks frozen:
##   breathing:     the chest rises and falls
##   looking round: every few seconds the head turns to look somewhere else
##   weight shift:  standing people sway their hips slowly from one foot to the other
##   talking:       people in a pair (pose.talking) take turns: one talks with hand
##                  gestures while the other listens and nods
## Session 92: stand() is a relaxed standing pose (people chatting use it, pose.relaxed):
## straight legs with the feet under the hips and the arms hanging down. The talker uses
## one hand at a time, low and open (it looked like a fight before), and their turns
## come from a clock the pair share (pose.talk_seed), so they never talk at once.
## Only people near the rider do this (PersonPose checks the distance now and then), so
## hundreds of people stay cheap. Every person has their own timing (pose.own_time).


static func apply(pose: PersonPose, delta: float) -> void:
	var t := pose.clock + pose.own_time
	var standing := pose.mode == ""
	if standing:
		_shift_weight(pose, t)
	# Breathing: a slow rise and fall of the chest.
	var breath := sin(t * TAU / GameConfig.ALIVE_BREATH_SECONDS)
	pose.turn("Spine2", Vector3.RIGHT, deg_to_rad(GameConfig.ALIVE_BREATH_DEG) * breath)
	if pose.talking:
		if is_speaking(pose):
			_gesture(pose, t, standing)
		else:  # listening: a small nod now and then
			pose.turn("Head", Vector3.RIGHT, deg_to_rad(GameConfig.TALK_NOD_DEG) * maxf(sin(t * 2.2), 0.0) ** 3)
	if pose.auto_look:
		_look_round(pose, delta)


## Every few seconds pick somewhere new to look, and turn the head there smoothly.
## People in a pair mostly look at each other (straight ahead).
static func _look_round(pose: PersonPose, delta: float) -> void:
	pose.look_wait -= delta
	if pose.look_wait <= 0.0:
		pose.look_wait = randf_range(GameConfig.ALIVE_LOOK_EVERY.x, GameConfig.ALIVE_LOOK_EVERY.y)
		var wide := GameConfig.ALIVE_LOOK_DEG * (0.3 if pose.talking else 1.0)
		pose.look_to = randf_range(-wide, wide)
	pose.look = move_toward(pose.look, pose.look_to, GameConfig.ALIVE_LOOK_SPEED * delta)


## The hips sway a few centimetres sideways; the feet stay where they are.
static func _shift_weight(pose: PersonPose, t: float) -> void:
	var person := pose.person
	var feet := [pose.now("LeftFoot"), pose.now("RightFoot")]
	var sway := sin(t * TAU / GameConfig.ALIVE_SWAY_SECONDS) * GameConfig.ALIVE_SWAY
	var skeleton := pose.get_skeleton()
	var hips := skeleton.find_bone("Hips")
	var move := person.skeleton_to_me.affine_inverse().basis * Vector3(sway, -absf(sway) * 0.3, 0)
	skeleton.set_bone_pose_position(hips, skeleton.get_bone_pose_position(hips) + move)
	pose.turn("Hips", Vector3.BACK, -sway * 1.5)  # the hips tilt a little towards the standing leg
	pose.turn("Spine1", Vector3.BACK, sway * 1.5)  # and the body leans back to stay upright
	pose.reach("LeftUpLeg", "LeftLeg", "LeftFoot", feet[0], Vector3(0, 0.3, -1))
	pose.reach("RightUpLeg", "RightLeg", "RightFoot", feet[1], Vector3(0, 0.3, -1))


## True while this person (in a talking pair) has their turn to speak. Both people in the
## pair use the same clock (the game's clock plus their shared talk_seed), half a turn apart.
static func is_speaking(pose: PersonPose) -> bool:
	var now := Time.get_ticks_msec() * 0.001 + pose.talk_seed
	return pose.talking and fposmod(now / GameConfig.ALIVE_TALK_TURN_SECONDS + pose.talk_turn, 2.0) < 1.0


## Talking with the hands: one hand at a time comes up, open, at waist height and moves
## a little as they speak; the head nods and tilts with the words.
static func _gesture(pose: PersonPose, t: float, standing: bool) -> void:
	var person := pose.person
	var hips := person.spot("Hips").y
	var side := 1.0 if fposmod(t / 5.0, 1.0) < 0.6 else -1.0  # mostly the right hand
	var name := "Left" if side < 0.0 else "Right"
	var lift := sin(t * 2.4) * 0.5 + 0.5
	var hand := Vector3(side * (0.2 + 0.05 * sin(t * 3.1)), hips + 0.08 + lift * 0.12, -0.26 - lift * 0.06)
	if not standing:
		hand.y = hips + 0.12 + lift * 0.1
	pose.reach(name + "Arm", name + "ForeArm", name + "Hand", hand, Vector3(side, -1.0, 0.4))
	pose.turn("Head", Vector3.RIGHT, deg_to_rad(4.0) * sin(t * 3.3))
	pose.turn("Head", Vector3.BACK, deg_to_rad(5.0) * sin(t * 0.9))


## Session 92: standing at ease. The hips go back to their resting height and stay level,
## the legs straight with the feet under the hips (a little apart), the back straight and
## the arms hanging down by the sides, the elbows a little bent.
static func stand(pose: PersonPose) -> void:
	var skeleton := pose.get_skeleton()
	var ground := minf(pose.now("LeftFoot").y, pose.now("RightFoot").y)  # where the clip has the ankles
	for bone in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "LeftShoulder", "RightShoulder"]:
		var i := skeleton.find_bone(bone)
		skeleton.set_bone_pose_rotation(i, skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
	# Hips up until the legs are nearly straight down to the ankles.
	var hips := skeleton.find_bone("Hips")
	skeleton.set_bone_pose_position(hips, skeleton.get_bone_rest(hips).origin)
	var gap := GameConfig.TALK_FEET_APART * 0.5
	var top := pose.now("LeftUpLeg")
	var leg := (pose.length("LeftUpLeg", "LeftLeg") + pose.length("LeftLeg", "LeftFoot")) * 0.985
	var across := absf(top.x) - gap
	var lift := ground + sqrt(maxf(leg * leg - across * across, 0.0)) - top.y
	var up := pose.person.skeleton_to_me.affine_inverse().basis * Vector3(0, lift, 0)
	skeleton.set_bone_pose_position(hips, skeleton.get_bone_rest(hips).origin + up)
	for side in [-1.0, 1.0]:
		var name := "Left" if side < 0.0 else "Right"
		var ankle := Vector3(side * gap, ground, pose.now(name + "UpLeg").z + 0.02)
		pose.reach(name + "UpLeg", name + "Leg", name + "Foot", ankle, Vector3(0, 0.1, -1))
		pose.point(name + "Foot", name + "ToeBase", Vector3(side * 0.15, -0.35, -1))
		pose.point(name + "ToeBase", name + "Toe_End", Vector3(side * 0.15, 0, -1))
		pose.point(name + "Arm", name + "ForeArm", Vector3(side * 0.18, -1, 0.05))
		pose.point(name + "ForeArm", name + "Hand", Vector3(side * 0.1, -1, -0.2))
