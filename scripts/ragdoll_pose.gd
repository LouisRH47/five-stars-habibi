class_name RagdollPose
extends SkeletonModifier3D
## Session 87: while the rider is a ragdoll, this moves each bone to follow its body part
## (scripts/ragdoll_bones.gd). It sits after the person's own pose (scripts/person_pose.gd),
## so it wins. influence (0 to 1, from SkeletonModifier3D) blends between the ragdoll
## (1) and the normal animated pose (0); getting up lowers it. Switched off (active =
## false) when not ragdolling, so it changes nothing then.

## The body parts, their bones, and where each bone sits on its body part.
var bodies: Array = []
var bones: Array = []
var rel: Array = []


func _process_modification_with_delta(_delta: float) -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var to_skeleton := skel.global_transform.affine_inverse()
	for i in bodies.size():
		var body: RigidBody3D = bodies[i]
		if not is_instance_valid(body):
			continue
		var at: Transform3D = body.get_global_transform_interpolated() * rel[i]
		skel.set_bone_global_pose(bones[i], to_skeleton * at)
