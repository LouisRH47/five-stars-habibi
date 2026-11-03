class_name PersonPose
extends SkeletonModifier3D
## Poses made in code for a Person (Session 29), on top of their animation:
##   "wave":  the right arm goes up and the hand waves from side to side
##   "pedal": sitting on the bike, leaning forward, hands on the handlebars and feet on
##            the pedals. The bike tells us where the pedals and grips are each frame.
##   "lie":   straight legs and arms by the sides (the clinic bed)
##   "sit":   thighs forward, feet down and hands on the lap (cafe/reception chairs)
## It works by pointing bones at spots (like a puppet on strings). Spots are in metres on
## the person (facing -Z, +X is their right).

## Which pose: "", "wave", "pedal", "lie" or "sit".
var mode := ""
## The Person we belong to.
var person: Person
## For "pedal": where the left and right foot, and left and right hand should go.
var feet: Array[Vector3] = [Vector3(-0.1, 0.3, -0.1), Vector3(0.1, 0.3, -0.1)]
var hands: Array[Vector3] = [Vector3(-0.25, 1.05, -0.5), Vector3(0.25, 1.05, -0.5)]
## For "pedal": degrees the body leans forward.
var lean := 0.0

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
