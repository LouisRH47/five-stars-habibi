class_name PersonPose
extends SkeletonModifier3D
## Poses made in code for a Person (Session 29), on top of their animation:
##   "wave":  the right arm goes up and the hand waves from side to side
##   "pedal": sitting on the bike, leaning forward, hands on the handlebars and feet on
##            the pedals. The bike tells us where the pedals and grips are each frame.
##   "lie":   straight legs and arms by the sides (the clinic bed)
##   "swim", "rest", "whistle": Session 81, see scripts/pool_poses.gd
##   "sit":   thighs forward, feet down and hands on the lap (cafe/reception chairs).
##            Session 80: the feet never go below the floor (floor_y). On a low seat the
##            knees come up and the feet rest on the floor in front, like a real person.
## It works by pointing bones at spots (like a puppet on strings). Spots are in metres on
## the person (facing -Z, +X is their right).

## Which pose: "", "wave", "pedal", "lie", "sit", "swim", "rest" or "whistle".
var mode := ""
## The Person we belong to.
var person: Person
## For "pedal": where the left and right foot, and left and right hand should go.
var feet: Array[Vector3] = [Vector3(-0.1, 0.3, -0.1), Vector3(0.1, 0.3, -0.1)]
var hands: Array[Vector3] = [Vector3(-0.25, 1.05, -0.5), Vector3(0.25, 1.05, -0.5)]
## For "pedal": degrees the body leans forward.
var lean := 0.0
## Session 75 (the jump on foot), on top of standing, walking or jogging:
## squat: metres the hips drop while the feet stay where they are (landing).
## tuck: metres the feet lift up towards the body (in the air).
var squat := 0.0
var tuck := 0.0
## Session 80, for "sit": how high the floor under the feet is (world height in metres).
## 0 is the ground; people sitting on steps get the height of the step their feet are on.
var floor_y := 0.0
## Session 81, for "swim": "crawl" or "breast" (breaststroke), and where in the stroke
## this swimmer starts (0 to 1), so swimmers don't all move in step.
var stroke := "crawl"
var stroke_start := 0.0
## Degrees the head turns to look around (+ is to the left). Not for swimmers.
var look := 0.0
## Seconds this pose has been running (the swim strokes and waving use it).
var clock := 0.0
## Session 83 (scripts/alive_pose.gd): standing and sitting people breathe, look round
## and shift their weight when the rider is near. talking: in a pair, talking with the
## hands in turns (talk_turn 0 or 1 says who starts). auto_look: false when something else
## turns the head (the lifeguard).
var alive := true
var talking := false
var talk_turn := 0.0
var auto_look := true
## Each person's own timing, so a crowd doesn't move in step.
var own_time := randf() * 100.0
## Where the head is turning to, and how long until it looks somewhere new.
var look_to := 0.0
var look_wait := 0.0
var _near := false
var _near_wait := randf() * 0.5

var _bones := {}
var _lengths := {}


func _process_modification_with_delta(delta: float) -> void:
	clock += delta
	if mode == "wave":
		_wave()
	elif mode == "pedal":
		_pedal()
	elif mode == "lie":
		_lie()
	elif mode == "sit":
		_sit()
	elif mode == "swim":
		PoolPoses.swim(self)
	elif mode == "rest":
		PoolPoses.rest(self)
	elif mode == "whistle":
		PoolPoses.whistle(self)
	if alive and (mode == "sit" or (mode == "" and person.action == "idle")) and _close(delta):
		AlivePose.apply(self, delta)
	if absf(look) > 0.5 and mode != "swim":
		turn("Neck", Vector3.UP, deg_to_rad(look * 0.35))
		turn("Head", Vector3.UP, deg_to_rad(look * 0.65))
	if (squat > 0.001 or tuck > 0.001) and mode in ["", "wave"]:
		_bend_legs()


func _wave() -> void:
	point("RightArm", "RightForeArm", Vector3(0.5, 0.85, 0.05))
	var swing := sin(clock * 9.0) * 0.5
	point("RightForeArm", "RightHand", Vector3(0.1 + swing, 1.0, -0.1))
	turn("Head", Vector3.RIGHT, deg_to_rad(10.0))  # chin up a little


func _pedal() -> void:
	turn("Spine", Vector3.RIGHT, deg_to_rad(-lean))
	reach("LeftUpLeg", "LeftLeg", "LeftFoot", feet[0], Vector3(-0.1, 0.2, -1.0))
	reach("RightUpLeg", "RightLeg", "RightFoot", feet[1], Vector3(0.1, 0.2, -1.0))
	reach("LeftArm", "LeftForeArm", "LeftHand", hands[0], Vector3(-0.5, -0.6, 0.6))
	reach("RightArm", "RightForeArm", "RightHand", hands[1], Vector3(0.5, -0.6, 0.6))


func _lie() -> void:
	for side in ["Left", "Right"]:
		var x := -0.12 if side == "Left" else 0.12
		point(side + "UpLeg", side + "Leg", Vector3.DOWN)
		point(side + "Leg", side + "Foot", Vector3.DOWN)
		point(side + "Arm", side + "ForeArm", Vector3(x, -1.0, 0.0))
		point(side + "ForeArm", side + "Hand", Vector3(x * 0.5, -1.0, -0.1))


func _sit() -> void:
	var hips := person.spot("Hips")
	# The floor on the person (their own metres, standing on y = 0).
	var floor := floor_y - person.global_position.y + GameConfig.SIT_FEET_CLEARANCE
	for side in ["Left", "Right"]:
		var x := -0.2 if side == "Left" else 0.2
		point(side + "UpLeg", side + "Leg", Vector3(0, -0.05, -1))
		point(side + "Leg", side + "Foot", Vector3.DOWN)
		# Would the foot go into the floor (a low seat or a step)? Then put the foot down
		# on the floor a little in front and let the knee come up, like a real person
		# on a low seat or a big step.
		var ankle := person.skeleton_to_me * _at(side + "Foot")
		var ankle_floor := floor + GameConfig.SIT_ANKLE_HEIGHT
		if ankle.y < ankle_floor:
			var hip := person.skeleton_to_me * _at(side + "UpLeg")
			var thigh := length(side + "UpLeg", side + "Leg")
			var shin := length(side + "Leg", side + "Foot")
			var drop := maxf(hip.y - ankle_floor, 0.0)
			var forward := thigh + sqrt(maxf(shin * shin - drop * drop, 0.0)) * 0.5  # knees up a little
			reach(side + "UpLeg", side + "Leg", side + "Foot", Vector3(hip.x, ankle_floor, hip.z - forward),
					Vector3(0, 1, -0.3))
		reach(side + "Arm", side + "ForeArm", side + "Hand",
				Vector3(x, hips.y - 0.1, -0.35), Vector3(x * 3, -0.3, 0.1))


## True if the camera (so the rider) is near enough to bother looking alive. Checked
## twice a second, not every frame.
func _close(delta: float) -> bool:
	_near_wait -= delta
	if _near_wait <= 0.0:
		_near_wait = 0.5
		var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
		_near = camera != null and person.global_position.distance_squared_to(camera.global_position) \
				< GameConfig.ALIVE_DISTANCE * GameConfig.ALIVE_DISTANCE
	return _near


## Bends the knees: the hips go down by `squat` and the feet up by `tuck`.
func _bend_legs() -> void:
	var to_me := person.skeleton_to_me
	var feet := [to_me * _at("LeftFoot"), to_me * _at("RightFoot")]
	if squat > 0.001:
		var skel := get_skeleton()
		var hips := _bone("Hips")  # the root bone, so its position is in skeleton space
		var down := to_me.affine_inverse().basis * Vector3(0, -squat, 0)
		skel.set_bone_pose_position(hips, skel.get_bone_pose_position(hips) + down)
	var lift := Vector3(0, tuck, -tuck * 0.3)
	reach("LeftUpLeg", "LeftLeg", "LeftFoot", feet[0] + lift, Vector3(0, 0.3, -1))
	reach("RightUpLeg", "RightLeg", "RightFoot", feet[1] + lift, Vector3(0, 0.3, -1))


## Where a bone is right now, in metres on the person.
func now(bone: String) -> Vector3:
	return person.skeleton_to_me * _at(bone)


## Bends a limb (upper bone, lower bone, end bone) so its end reaches `target`.
## bend: which way the knee or elbow should point.
func reach(upper: String, lower: String, end: String, target: Vector3, bend: Vector3) -> void:
	var to_skeleton: Transform3D = person.skeleton_to_me.affine_inverse()
	var aim :=to_skeleton * target
	var pole := (to_skeleton.basis * bend).normalized()
	var top := _at(upper)
	var a := top.distance_to(_at(lower))
	var b := _at(lower).distance_to(_at(end))
	var gap := aim - top
	var d := clampf(gap.length(), 0.001, (a + b) * 0.999)
	var way := gap.normalized()
	var cos_top := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var side := (pole - way * pole.dot(way)).normalized()
	var joint := top + way * (a * cos_top) + side * (a * sqrt(1.0 - cos_top * cos_top))
	_aim(upper, lower, joint - top)
	_aim(lower, end, aim - _at(lower))


## Points a bone (from it to its child bone) along a direction on the person.
func point(bone: String, child: String, way: Vector3) -> void:
	_aim(bone, child, person.skeleton_to_me.affine_inverse().basis * way)


## Turns a bone by `angle` around an axis on the person.
func turn(bone: String, axis: Vector3, angle: float) -> void:
	var skel := get_skeleton()
	var i := _bone(bone)
	var skel_axis: Vector3 = (person.skeleton_to_me.affine_inverse().basis * axis).normalized()
	var now := skel.get_bone_global_pose(i).basis.get_rotation_quaternion()
	_set_global_rotation(i, Quaternion(skel_axis, angle) * now)


## Points a bone along a direction in skeleton space.
func _aim(bone: String, child: String, way: Vector3) -> void:
	if way.length() < 0.00001:
		return
	var skel := get_skeleton()
	var i := _bone(bone)
	var now := (_at(child) - _at(bone)).normalized()
	var spin := Quaternion(now, way.normalized())
	_set_global_rotation(i, spin * skel.get_bone_global_pose(i).basis.get_rotation_quaternion())


func _set_global_rotation(i: int, rot: Quaternion) -> void:
	var skel := get_skeleton()
	var parent := skel.get_bone_parent(i)
	var above := Quaternion.IDENTITY
	if parent >= 0:
		above = skel.get_bone_global_pose(parent).basis.get_rotation_quaternion()
	skel.set_bone_pose_rotation(i, (above.inverse() * rot).normalized())


## Where a bone is right now, in skeleton space.
func _at(bone: String) -> Vector3:
	return get_skeleton().get_bone_global_pose(_bone(bone)).origin


## How long a bone is on the person standing straight (metres), worked out once.
func length(bone: String, child: String) -> float:
	if not _lengths.has(bone):
		_lengths[bone] = person.spot(bone).distance_to(person.spot(child))
	return _lengths[bone]


func _bone(bone: String) -> int:
	if not _bones.has(bone):
		_bones[bone] = get_skeleton().find_bone(bone)
	return _bones[bone]
