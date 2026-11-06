class_name RagdollBones
## Builds the floppy body of a ragdoll (Session 87) for a Person: one physics body (a
## RigidBody3D) per big body part, joined so knees and elbows only bend one way and the
## head doesn't spin round. scripts/rider_ragdoll.gd uses it when the rider falls off.
## Why not Godot's own PhysicalBone3D? The model's skeleton is tiny and scaled up ~23
## times, and the physics engine ignores that scale-up, so those bones came out tiny and
## spun wildly. These bodies live in the world at real size (metres) instead, and
## scripts/ragdoll_pose.gd moves the bones to follow them.

## Body parts: bone, the bone where the part ends, thickness (metres), weight (kg), joint.
## Smaller bones (shoulders, hands, feet, neck, fingers) just ride along on these.
## tip: a flat box from the part's end bone to this bone (the hand or the foot), tip_size
## wide and thick (metres).
## Joints: "cone" swings any way up to `swing` degrees and twists up to `twist`;
## "knee" and "elbow" are hinges that only bend one way (up to `bend` degrees).
const PARTS := [
	{"bone": "Hips", "radius": 0.12, "mass": 11.0},
	{"bone": "Spine", "end": "Neck", "radius": 0.13, "mass": 18.0, "joint": "cone", "swing": 30.0, "twist": 20.0},
	{"bone": "Head", "end": "HeadTop_End", "radius": 0.1, "mass": 5.5, "joint": "cone", "swing": 40.0, "twist": 45.0},
	{"bone": "LeftArm", "end": "LeftForeArm", "radius": 0.05, "mass": 2.5, "joint": "cone", "swing": 80.0, "twist": 45.0},
	{"bone": "RightArm", "end": "RightForeArm", "radius": 0.05, "mass": 2.5, "joint": "cone", "swing": 80.0, "twist": 45.0},
	{"bone": "LeftForeArm", "end": "LeftHand", "radius": 0.045, "mass": 2.0, "joint": "elbow", "bend": 140.0, "extra": 0.09, "tip": "LeftHandIndex3", "tip_size": Vector2(0.1, 0.05)},
	{"bone": "RightForeArm", "end": "RightHand", "radius": 0.045, "mass": 2.0, "joint": "elbow", "bend": 140.0, "extra": 0.09, "tip": "RightHandIndex3", "tip_size": Vector2(0.1, 0.05)},
	{"bone": "LeftUpLeg", "end": "LeftLeg", "radius": 0.075, "mass": 8.0, "joint": "cone", "swing": 75.0, "twist": 15.0},
	{"bone": "RightUpLeg", "end": "RightLeg", "radius": 0.075, "mass": 8.0, "joint": "cone", "swing": 75.0, "twist": 15.0},
	{"bone": "LeftLeg", "end": "LeftFoot", "radius": 0.055, "mass": 4.5, "joint": "knee", "bend": 150.0, "tip": "LeftToe_End", "tip_size": Vector2(0.09, 0.06)},
	{"bone": "RightLeg", "end": "RightFoot", "radius": 0.055, "mass": 4.5, "joint": "knee", "bend": 150.0, "tip": "RightToe_End", "tip_size": Vector2(0.09, 0.06)},
]
## Joints are centred on a relaxed pose, not the stiff T-pose of the model: thighs this
## many degrees forward (so legs swing well forward, like on the saddle, but not far
## back) and arms this many degrees down from sideways.
const THIGH_FORWARD := 40.0
const ARM_DOWN := 45.0
## Degrees a knee or elbow may bend the wrong way (a tiny bit, so it isn't rigid).
const STRAIGHT_SLACK := 5.0
const FRICTION := 0.8
const BOUNCE := 0.0
const LINEAR_DAMP := 0.1
const ANGULAR_DAMP := 1.5


## Makes the bodies (in `holder`) and joints, starting from the person's pose right now.
## Returns {"bodies": [RigidBody3D], "bones": [bone index], "rel": [body-to-bone
## Transform3D], "joints": [RID]}. Free the joints with PhysicsServer3D.free_rid().
static func make(person: Person, holder: Node3D, layer: int, mask: int) -> Dictionary:
	var skel := person.skeleton
	var sk := skel.global_transform
	var unit := sk.basis.get_scale().x  # metres in one skeleton unit (the model is tiny)
	var up := (person.skeleton_to_me.basis.inverse() * Vector3.UP).normalized()
	var right := _rest(skel, "RightUpLeg").origin - _rest(skel, "LeftUpLeg").origin
	right = (right - up * right.dot(up)).normalized()
	var forward := up.cross(right)
	var out := {"bodies": [], "bones": [], "rel": [], "joints": []}
	var made := {}     # bone name -> body
	var relaxed := {}  # bone name -> where the body is in the relaxed pose (world)
	for part: Dictionary in PARTS:
		var id: String = part["bone"]
		var bone := skel.find_bone(id)
		var frame := _frame(skel, part, right, unit)
		var length := frame.origin.length() * 2.0 * unit
		if not part.has("end"):
			length = _rest(skel, "LeftUpLeg").origin.distance_to(_rest(skel, "RightUpLeg").origin) * unit
		var now := sk * skel.get_bone_global_pose(bone)
		var body := _body(part, length)
		body.name = id
		body.collision_layer = layer
		body.collision_mask = mask
		holder.add_child(body)
		body.global_transform = _metric(now * frame)
		body.reset_physics_interpolation()
		if part.has("tip"):
			_add_tip(body, sk * skel.get_bone_global_pose(skel.find_bone(part["end"])).origin,
					sk * skel.get_bone_global_pose(skel.find_bone(part["tip"])).origin, part["tip_size"])
		for other: RigidBody3D in made.values():
			body.add_collision_exception_with(other)  # parts don't fight each other
		made[id] = body
		var pose := sk * _relax(skel, id, up, forward) * _rest(skel, id)
		relaxed[id] = _metric(pose * frame)
		out["bodies"].append(body)
		out["bones"].append(bone)
		out["rel"].append(body.global_transform.affine_inverse() * now)
		if part.has("joint"):
			var parent := _parent_part(skel, bone, made)
			var bend := sk.basis * (-forward if part["joint"] == "knee" else forward + up * 0.3)
			out["joints"].append(_joint(part, made[parent], body, relaxed[parent], relaxed[id],
					pose.origin, bend.normalized()))
	return out


## Where the body part sits, seen from its bone (in skeleton units): in the middle of the
## part, with its Y axis running along it (so a capsule needs no turning).
static func _frame(skel: Skeleton3D, part: Dictionary, right: Vector3, unit: float) -> Transform3D:
	var rest := _rest(skel, part["bone"])
	if not part.has("end"):  # the hips: a fat capsule from one hip to the other
		var hips := (_rest(skel, "LeftUpLeg").origin + _rest(skel, "RightUpLeg").origin) * 0.5
		var middle := rest.affine_inverse() * ((hips + rest.origin) * 0.5)
		return Transform3D(_along((rest.basis.inverse() * right).normalized()), middle)
	var end := rest.affine_inverse() * _rest(skel, part["end"]).origin
	end += end.normalized() * float(part.get("extra", 0.0)) / unit
	return Transform3D(_along(end.normalized()), end * 0.5)


## A body for one part: a capsule `length` metres long between its joints.
static func _body(part: Dictionary, length: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = part["mass"]
	body.linear_damp = LINEAR_DAMP
	body.angular_damp = ANGULAR_DAMP
	body.continuous_cd = true
	var material := PhysicsMaterial.new()
	material.friction = FRICTION
	material.bounce = BOUNCE
	body.physics_material_override = material
	var radius: float = part["radius"]
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = maxf(length + radius, radius * 2.0)
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	body.add_child(shape)
	return body


## A flat box for a hand or foot, from the wrist or ankle to the fingers or toes
## (world spots).
static func _add_tip(body: RigidBody3D, ankle: Vector3, toes: Vector3, size: Vector2) -> void:
	var a := body.global_transform.affine_inverse() * ankle
	var b := body.global_transform.affine_inverse() * toes
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, a.distance_to(b) + 0.05)
	var foot := CollisionShape3D.new()
	foot.shape = box
	var way := (b - a).normalized()
	foot.transform = Transform3D(Basis.looking_at(way, Vector3.UP if absf(way.y) < 0.9 else Vector3.BACK), (a + b) * 0.5)
	body.add_child(foot)


## Joins body b to body a at `at` (world), measured from the relaxed pose.
static func _joint(part: Dictionary, a: RigidBody3D, b: RigidBody3D, relaxed_a: Transform3D,
		relaxed_b: Transform3D, at: Vector3, bend: Vector3) -> RID:
	var along := relaxed_b.basis.y.normalized()
	var joint := PhysicsServer3D.joint_create()
	if part["joint"] == "cone":  # a cone joint swings around its X axis
		var side := along.cross(Vector3.UP if absf(along.y) < 0.9 else Vector3.RIGHT).normalized()
		var frame := Transform3D(Basis(along, side.cross(along), side), at)
		PhysicsServer3D.joint_make_cone_twist(joint, a.get_rid(), relaxed_a.affine_inverse() * frame,
				b.get_rid(), relaxed_b.affine_inverse() * frame)
		PhysicsServer3D.cone_twist_joint_set_param(joint, PhysicsServer3D.CONE_TWIST_JOINT_SWING_SPAN, deg_to_rad(part["swing"]))
		PhysicsServer3D.cone_twist_joint_set_param(joint, PhysicsServer3D.CONE_TWIST_JOINT_TWIST_SPAN, deg_to_rad(part["twist"]))
	else:  # a hinge turns around its Z axis; turning by - bends towards `bend`
		var axis := along.cross(bend - along * bend.dot(along)).normalized()
		var frame := Transform3D(Basis(along, axis.cross(along), axis), at)
		PhysicsServer3D.joint_make_hinge(joint, a.get_rid(), relaxed_a.affine_inverse() * frame,
				b.get_rid(), relaxed_b.affine_inverse() * frame)
		PhysicsServer3D.hinge_joint_set_flag(joint, PhysicsServer3D.HINGE_JOINT_FLAG_USE_LIMIT, true)
		PhysicsServer3D.hinge_joint_set_param(joint, PhysicsServer3D.HINGE_JOINT_LIMIT_LOWER, -deg_to_rad(part["bend"]))
		PhysicsServer3D.hinge_joint_set_param(joint, PhysicsServer3D.HINGE_JOINT_LIMIT_UPPER, deg_to_rad(STRAIGHT_SLACK))
	PhysicsServer3D.joint_disable_collisions_between_bodies(joint, true)
	return joint


## The relaxed pose for a bone (on the skeleton): legs swung forward, arms down.
static func _relax(skel: Skeleton3D, id: String, up: Vector3, forward: Vector3) -> Transform3D:
	var side := "Left" if id.begins_with("Left") else "Right"
	if id.ends_with("UpLeg") or id.ends_with("Leg"):
		return _swing(skel, side + "UpLeg", side + "Leg", forward, THIGH_FORWARD)
	if id.ends_with("Arm"):
		return _swing(skel, side + "Arm", side + "ForeArm", -up, ARM_DOWN)
	return Transform3D()


## Turns a limb about its top joint, `degrees` from where it points towards `toward`.
static func _swing(skel: Skeleton3D, top: String, next: String, toward: Vector3, degrees: float) -> Transform3D:
	var pivot := _rest(skel, top).origin
	var way := (_rest(skel, next).origin - pivot).normalized()
	var axis := way.cross(toward).normalized()
	return Transform3D(Basis(), pivot) * Transform3D(Basis(axis, deg_to_rad(degrees)), Vector3.ZERO) \
			* Transform3D(Basis(), -pivot)


## The nearest bone above `bone` that has a body.
static func _parent_part(skel: Skeleton3D, bone: int, made: Dictionary) -> String:
	var above := skel.get_bone_parent(bone)
	while above >= 0 and not made.has(skel.get_bone_name(above)):
		above = skel.get_bone_parent(above)
	return skel.get_bone_name(maxi(above, 0))


## A turn whose Y axis points along `way`.
static func _along(way: Vector3) -> Basis:
	var side := way.cross(Vector3.BACK if absf(way.z) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(side, way, side.cross(way).normalized())


## The same place and turn, without the skeleton's scale-up.
static func _metric(t: Transform3D) -> Transform3D:
	return Transform3D(t.basis.orthonormalized(), t.origin)


static func _rest(skel: Skeleton3D, bone: String) -> Transform3D:
	return skel.get_bone_global_rest(skel.find_bone(bone))
