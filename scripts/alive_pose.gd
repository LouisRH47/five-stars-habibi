class_name AlivePose
## Session 83: small movements on top of standing and sitting, so nobody looks frozen:
##   breathing:     the chest rises and falls
##   looking round: every few seconds the head turns to look somewhere else
##   weight shift:  standing people sway their hips slowly from one foot to the other
##   talking:       people in a pair (pose.talking) take turns: one talks with hand
##                  gestures while the other listens and nods
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
	var talking_now := pose.talking and fposmod(t / GameConfig.ALIVE_TALK_TURN_SECONDS + pose.talk_turn, 2.0) < 1.0
	if pose.talking:
		if talking_now:
			_gesture(pose, t, standing)
		else:  # listening: a small nod now and then
			pose.turn("Head", Vector3.RIGHT, deg_to_rad(6.0) * maxf(sin(t * 2.2), 0.0))
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


## Talking with the hands: the forearms come up and the hands move as they speak.
static func _gesture(pose: PersonPose, t: float, standing: bool) -> void:
	var person := pose.person
	var chest := person.spot("Spine2").y
	for side in [-1.0, 1.0]:
		var name := "Left" if side < 0.0 else "Right"
		var lift := (sin(t * 2.6 + side) * 0.5 + 0.5) if side > 0.0 else (sin(t * 1.7) * 0.5 + 0.5) * 0.6
		var hand := Vector3(side * (0.18 + 0.07 * sin(t * 3.1 + side)), chest - 0.2 + lift * 0.25, -0.32 - lift * 0.1)
		if not standing:
			hand.y = chest - 0.15 + lift * 0.2
		pose.reach(name + "Arm", name + "ForeArm", name + "Hand", hand, Vector3(side, -1.0, 0.3))
	pose.turn("Head", Vector3.UP, sin(t * 1.3) * 0.12)
