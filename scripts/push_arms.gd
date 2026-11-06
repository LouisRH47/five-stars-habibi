class_name PushArms
extends SkeletonModifier3D
## Session 92: both hands hold a handle in front of the person (a stroller), on top of their
## walk or idle. It runs after PersonPose, like WaiterArms. The hands go to `hands` (metres
## on the person, facing -Z) with the elbows a little bent and out, and the body leans
## forward a little, like pushing.

var person: Person
var pose: PersonPose
## Where the left and the right hand hold on (metres on the person).
var hands: Array[Vector3] = []


func _process_modification_with_delta(_delta: float) -> void:
	if person == null or pose == null or hands.size() < 2:
		return
	pose.turn("Spine", Vector3.RIGHT, deg_to_rad(-GameConfig.STROLLER_LEAN_DEG))
	pose.reach("LeftArm", "LeftForeArm", "LeftHand", hands[0], Vector3(-0.6, -1.0, 0.3))
	pose.reach("RightArm", "RightForeArm", "RightHand", hands[1], Vector3(0.6, -1.0, 0.3))
