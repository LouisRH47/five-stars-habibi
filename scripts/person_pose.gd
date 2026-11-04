class_name PersonPose
extends SkeletonModifier3D
## Poses made in code for a Person (Session 29), on top of their animation:
##   "wave":  the right arm goes up and the hand waves from side to side
##   "pedal": sitting on the bike, leaning forward, hands on the handlebars and feet on
##            the pedals. The bike tells us where the pedals and grips are each frame.
##   "lie":   straight legs and arms by the sides (the clinic bed)
##   "sit":   thighs forward, feet down and hands on the lap (cafe/reception chairs)
##   "ragdoll": floppy, after a crash (Session 54). The bones follow a RagdollSim.
##   Sessions 60-61 (the gym, the pools and the C Institute):
##   "swim":    front crawl: the arms go round one after the other, the legs kick. The
##              swimmer's holder lays the person flat in the water (scripts/swimmer.gd).
##   "splash":  standing in the kids' pool, arms out, slapping the water
##   "row":     on a rowing machine; `reach` 0 = knees up, arms forward, 1 = legs straight, pulled in
##   "squat":   barbell on the shoulders; `reach` 0 = standing, 1 = deep squat
##   "stretch": sitting on a mat, legs straight, reaching for the toes
##   "laptop":  sitting, hands typing on a laptop on the lap, looking down
## It works by pointing bones at spots (like a puppet on strings). Spots are in metres on
## the person (facing -Z, +X is their right).

## Which pose: "", "wave", "pedal", "lie", "sit", "ragdoll" or one of the Session 60-61 poses.
var mode := ""
## For "row" and "squat": how far through the move (0 to 1). The gym sets it every frame.
var reach := 0.0
## For "swim": a different start for each swimmer, so they don't all stroke together.
var stroke_offset := 0.0
## The Person we belong to.
var person: Person
## For "pedal": where the left and right foot, and left and right hand should go.
var feet: Array[Vector3] = [Vector3(-0.1, 0.3, -0.1), Vector3(0.1, 0.3, -0.1)]
var hands: Array[Vector3] = [Vector3(-0.25, 1.05, -0.5), Vector3(0.25, 1.05, -0.5)]
## For "pedal": degrees the body leans forward.
var lean := 0.0
## For "ragdoll": the floppy body the bones follow.
var ragdoll: RagdollSim

var _time := 0.0
var _bones := {}


func _process_modification_with_delta(delta: float) -> void:
	_time += delta
	if mode == "wave":
		_wave()
	elif mode == "pedal":
		_pedal()
	elif mode == "lie":
		_lie()
	elif mode == "sit":
		_sit()
	elif mode == "ragdoll" and ragdoll != null:
		_ragdoll()
	elif mode == "swim":
		_swim()
	elif mode == "splash":
		_splash()
	elif mode == "row":
		_row()
	elif mode == "squat":
		_squat()
	elif mode == "stretch":
		_stretch()
	elif mode == "laptop":
		_laptop()


func _wave() -> void:
	_point("RightArm", "RightForeArm", Vector3(0.5, 0.85, 0.05))
	var swing := sin(_time * 9.0) * 0.5
	_point("RightForeArm", "RightHand", Vector3(0.1 + swing, 1.0, -0.1))
	_turn("Head", Vector3.RIGHT, deg_to_rad(10.0))  # chin up a little


func _pedal() -> void:
	_turn("Spine", Vector3.RIGHT, deg_to_rad(-lean))
	_reach("LeftUpLeg", "LeftLeg", "LeftFoot", feet[0], Vector3(-0.1, 0.2, -1.0))
	_reach("RightUpLeg", "RightLeg", "RightFoot", feet[1], Vector3(0.1, 0.2, -1.0))
	_reach("LeftArm", "LeftForeArm", "LeftHand", hands[0], Vector3(-0.5, -0.6, 0.6))
	_reach("RightArm", "RightForeArm", "RightHand", hands[1], Vector3(0.5, -0.6, 0.6))


func _lie() -> void:
	for side in ["Left", "Right"]:
		var x := -0.12 if side == "Left" else 0.12
		_point(side + "UpLeg", side + "Leg", Vector3.DOWN)
		_point(side + "Leg", side + "Foot", Vector3.DOWN)
		_point(side + "Arm", side + "ForeArm", Vector3(x, -1.0, 0.0))
		_point(side + "ForeArm", side + "Hand", Vector3(x * 0.5, -1.0, -0.1))


func _sit() -> void:
	var hip_height := person.spot("Hips").y
	for side in ["Left", "Right"]:
		var x := -0.2 if side == "Left" else 0.2
		_point(side + "UpLeg", side + "Leg", Vector3(0, -0.05, -1))
		_point(side + "Leg", side + "Foot", Vector3.DOWN)
		_reach(side + "Arm", side + "ForeArm", side + "Hand",
				Vector3(x, hip_height - 0.1, -0.35), Vector3(x * 3, -0.3, 0.1))


## Front crawl (Session 60). On the person, "up" (+Y) is where the head points, which the
## swimmer's holder turns to face along the lane, and the front (-Z) faces down into the water.
## So each arm goes round a circle: reach past the head (+Y), pull down under the body (-Z),
## push past the hip (-Y), then swing back over the water (+Z).
func _swim() -> void:
	var turn := (_time + stroke_offset) * TAU * GameConfig.SWIM_STROKES
	for side in ["Left", "Right"]:
		var x := -0.16 if side == "Left" else 0.16
		var a := turn + (0.0 if side == "Left" else PI)
		var arm := Vector3(x, cos(a), -sin(a))
		_point(side + "Arm", side + "ForeArm", arm)
		# The elbow bends a little as the arm comes back over the water.
		var bend := maxf(0.0, -sin(a)) * 0.6
		_point(side + "ForeArm", side + "Hand", (arm + Vector3(0, -bend, 0)).normalized())
		var kick := sin(_time * 9.0 + (0.0 if side == "Left" else PI))
		_point(side + "UpLeg", side + "Leg", Vector3(x * 0.4, -1.0, 0.12 * kick))
		_point(side + "Leg", side + "Foot", Vector3(x * 0.3, -1.0, 0.2 * kick + 0.05))
	_turn("Head", Vector3.UP, sin(turn) * 0.35)   # turns to the side to breathe


## Kids in the kids' pool: arms out to the sides, slapping the water up and down.
func _splash() -> void:
	for side in ["Left", "Right"]:
		var x := -1.0 if side == "Left" else 1.0
		var slap := sin(_time * 7.0 + (0.0 if side == "Left" else 1.7))
		_point(side + "Arm", side + "ForeArm", Vector3(x, -0.15 + 0.35 * slap, -0.5))
		_point(side + "ForeArm", side + "Hand", Vector3(x * 0.8, -0.3 + 0.5 * slap, -0.7))


## Rowing machine: sitting low, feet on the footplate in front. reach 0 = the catch (knees up,
## arms forward), 1 = the finish (legs straight, handle pulled to the chest).
func _row() -> void:
	var hips := person.spot("Hips")
	var leg := person.spot("LeftUpLeg").distance_to(person.spot("LeftLeg")) + person.spot("LeftLeg").distance_to(person.spot("LeftFoot"))
	var feet_ahead := lerpf(leg * 0.62, leg * 0.97, reach)
	_turn("Spine", Vector3.RIGHT, deg_to_rad(lerpf(-25.0, 15.0, reach)))   # lean forward, then back
	for side in ["Left", "Right"]:
		var x := -0.13 if side == "Left" else 0.13
		_reach(side + "UpLeg", side + "Leg", side + "Foot", Vector3(x, hips.y - 0.05, -feet_ahead), Vector3(0, 1, -0.3))
		var hand := Vector3(x * 0.8, hips.y + lerpf(0.15, 0.4, reach), lerpf(-0.75, -0.2, reach))
		_reach(side + "Arm", side + "ForeArm", side + "Hand", hand, Vector3(x * 4.0, -0.4, 0.6))


## Squat with a barbell on the shoulders. reach 0 = standing tall, 1 = deep squat. The gym
## lowers the whole person, so here the feet are pushed back up to the floor.
func _squat() -> void:
	var drop := reach * GameConfig.PERSON_HEIGHT * 0.22
	_turn("Spine", Vector3.RIGHT, deg_to_rad(-25.0 * reach))
	for side in ["Left", "Right"]:
		var x := -0.17 if side == "Left" else 0.17
		var ankle := person.spot(side + "Foot")
		_reach(side + "UpLeg", side + "Leg", side + "Foot", Vector3(x, ankle.y + drop, ankle.z), Vector3(x, 0.2, -1.0))
		var shoulder := person.spot(side + "Arm")
		_reach(side + "Arm", side + "ForeArm", side + "Hand", Vector3(x * 2.6, shoulder.y + 0.05, shoulder.z + 0.12),
				Vector3(x, -1.0, 0.4))


## Sitting on a mat with straight legs, reaching for the toes (slowly in and out).
func _stretch() -> void:
	var lean := 40.0 + 15.0 * sin(_time * 0.8)
	_turn("Spine", Vector3.RIGHT, deg_to_rad(-lean))
	for side in ["Left", "Right"]:
		var x := -0.1 if side == "Left" else 0.1
		_point(side + "UpLeg", side + "Leg", Vector3(x, 0.0, -1.0))
		_point(side + "Leg", side + "Foot", Vector3(x, 0.0, -1.0))
		_point(side + "Arm", side + "ForeArm", Vector3(x * 1.5, -0.55, -1.0))
		_point(side + "ForeArm", side + "Hand", Vector3(x, -0.5, -1.0))


## Sitting with a laptop on the lap, typing and looking down at it.
func _laptop() -> void:
	_sit()
	var hip_height := person.spot("Hips").y
	for side in ["Left", "Right"]:
		var x := -0.12 if side == "Left" else 0.12
		var tap := 0.012 * sin(_time * 14.0 + (0.0 if side == "Left" else 2.0))
		_reach(side + "Arm", side + "ForeArm", side + "Hand", Vector3(x, hip_height + 0.12 + tap, -0.42),
				Vector3(x * 4.0, -0.5, 0.3))
	_turn("Head", Vector3.RIGHT, deg_to_rad(-20.0))


## Points each bone at the next joint of the rag-doll (parents first, so children follow).
func _ragdoll() -> void:
	var to_skeleton := get_skeleton().global_transform.affine_inverse()
	for link in [["Spine", "Spine2", "chest"], ["Spine2", "Neck", "neck"], ["Neck", "HeadTop_End", "head"],
			["LeftArm", "LeftForeArm", "l_el"], ["LeftForeArm", "LeftHand", "l_ha"],
			["RightArm", "RightForeArm", "r_el"], ["RightForeArm", "RightHand", "r_ha"],
			["LeftUpLeg", "LeftLeg", "l_kn"], ["LeftLeg", "LeftFoot", "l_ft"],
			["RightUpLeg", "RightLeg", "r_kn"], ["RightLeg", "RightFoot", "r_ft"]]:
		var target: Vector3 = to_skeleton * (ragdoll.points[link[2]] as Vector3)
		_aim(link[0], link[1], target - _at(link[0]))


## Bends a limb (upper bone, lower bone, end bone) so its end reaches `target`.
## bend: which way the knee or elbow should point.
func _reach(upper: String, lower: String, end: String, target: Vector3, bend: Vector3) -> void:
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
func _point(bone: String, child: String, way: Vector3) -> void:
	_aim(bone, child, person.skeleton_to_me.affine_inverse().basis * way)


## Turns a bone by `angle` around an axis on the person.
func _turn(bone: String, axis: Vector3, angle: float) -> void:
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


func _bone(bone: String) -> int:
	if not _bones.has(bone):
		_bones[bone] = get_skeleton().find_bone(bone)
	return _bones[bone]
