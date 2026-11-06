extends SceneTree
## Session 87: the rider's ragdoll (scripts/rider_ragdoll.gd) and the tumbling bike
## (scripts/bike_tumble.gd) on flat ground. Run headless:
## Godot --path . --headless --fixed-fps 60 -s tests/ragdoll_test.gd

const LOOKS := ["Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot", "Hips"]

var _failures := 0
var _count := 0
## Every bone's final pose (after the ragdoll moved it), on the skeleton. The skeleton
## only shows the moved pose while it updates, so we copy it then.
var _poses: Array[Transform3D] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	var ground := StaticBody3D.new()  # layer 1, like the map
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	world.add_child(ground)
	await _rider_falls(world)
	await _bike_tumbles(world)
	print("RESULT: %s (%d checks, %d failed)" % ["PASS" if _failures == 0 else "FAIL", _count, _failures])
	quit(0 if _failures == 0 else 1)


func _rider_falls(world: Node3D) -> void:
	var person := RiderLook.make_rider()
	world.add_child(person)
	person.position.y = 1.0  # about where the rider sits on the saddle
	var ragdoll := RiderRagdoll.attach(person)
	person.skeleton.skeleton_updated.connect(_copy_poses.bind(person.skeleton))
	for i in 3:
		await physics_frame
	person.player.pause()
	var clip_time := person.player.current_animation_position
	await process_frame
	await process_frame
	var before := _looks(person)
	_check("attaching changes nothing until the fall", not ragdoll.pose.active and ragdoll.bodies.is_empty())
	var start := ragdoll.body_position()
	ragdoll.start(Vector3(0, 0, -6))
	_check("about 70 kg in 8 to 11 body parts", ragdoll.bodies.size() >= 8 and ragdoll.bodies.size() <= 11
			and absf(_mass(ragdoll) - 70.0) < 8.0)
	_check("the parts are on their own layer and only bump into the world",
			ragdoll.bodies.all(func(b: RigidBody3D) -> bool: return b.collision_layer == 128 and b.collision_mask == 1))
	var knees_ok := true
	var fastest := 0.0
	var frames := 0
	while not ragdoll.resting() and frames < 300:
		await physics_frame
		frames += 1
		knees_ok = knees_ok and _knees_bend_back(person)
		for part in ragdoll.bodies:
			fastest = maxf(fastest, part.linear_velocity.length())
	var hips := ragdoll.body_position()
	_check("the body comes to rest within 5 seconds (%d frames)" % frames, frames < 300)
	_check("the hips end up on the ground (y %.2f)" % hips.y, hips.y > 0.0 and hips.y < 0.6)
	_check("the body slid forward (%.1f m)" % (start.z - hips.z), start.z - hips.z > 1.0)
	_check("no part flew off faster than the cap (%.1f m/s)" % fastest, fastest <= RiderRagdoll.MAX_SPEED + 0.5)
	_check("knees only bent the right way", knees_ok)
	_check("no bone is under the ground (lowest %.2f m)" % _lowest(person), _lowest(person) > -0.05)
	var spot := ragdoll.settle_point()
	_check("settle_point is on the ground under the body", absf(spot.origin.y) < 0.05
			and Vector2(spot.origin.x - hips.x, spot.origin.z - hips.z).length() < 0.01)
	await ragdoll.get_up(0.3)
	_check("getting up hands the bones back to the animation", ragdoll.pose.influence == 0.0
			and not ragdoll.pose.active and ragdoll.bodies.is_empty() and not ragdoll.active())
	_check("the animation plays again", person.player.is_playing())
	person.player.pause()
	person.player.seek(clip_time, true)
	await process_frame
	await process_frame
	var after := _looks(person)
	var worst := 0.0
	for bone: String in before:
		worst = maxf(worst, before[bone].distance_to(after[bone]))
	_check("the person looks the same as before afterwards (%.3f m)" % worst, worst < 0.02)
	person.play("idle")
	person.player.play()
	await process_frame
	_check("play(\"idle\") still works", person.action == "idle" and person.player.is_playing())
	await physics_frame
	_check("the body parts are removed", world.find_children("RagdollParts", "", true, false).is_empty())
	person.queue_free()


func _bike_tumbles(world: Node3D) -> void:
	var bike := CharacterBody3D.new()  # like the real bike: layer 1, the look inside
	var capsule := CollisionShape3D.new()
	capsule.shape = CapsuleShape3D.new()
	capsule.position.y = 0.8
	bike.add_child(capsule)
	world.add_child(bike)
	bike.position = Vector3(5, 0, 0)
	var model := Node3D.new()
	model.name = "Model"
	bike.add_child(model)
	BikeModel.build(model)
	var home := model.transform
	await physics_frame
	var tumble := BikeTumble.start(model, Vector3(0, 0, -6), 1.0)
	_check("the bike's look moves into the tumbling body", model.get_parent() == tumble and tumble.get_parent() == world)
	var frames := 0
	while not tumble.resting() and frames < 300:
		await physics_frame
		frames += 1
	var up := tumble.global_basis.y.normalized()
	_check("the bike comes to rest within 5 seconds (%d frames)" % frames, frames < 300)
	_check("the bike lies on its side (up %.2f, %.2f, %.2f)" % [up.x, up.y, up.z], absf(up.y) < 0.5)
	_check("it fell to the right", up.dot(Vector3.RIGHT) > 0.5)
	_check("it slid forward (%.1f m)" % -tumble.global_position.z, tumble.global_position.z < -0.5)
	_check("it is not under the ground or floating", tumble.global_position.y > -0.05 and tumble.global_position.y < 0.6)
	tumble.put_back(bike, home)
	await physics_frame
	_check("put_back returns the bike's look", model.get_parent() == bike and model.transform.is_equal_approx(home)
			and not is_instance_valid(tumble))


func _copy_poses(skel: Skeleton3D) -> void:
	_poses.resize(skel.get_bone_count())
	for i in skel.get_bone_count():
		_poses[i] = skel.get_bone_global_pose(i)


## Where some bones are, on the person (metres).
func _looks(person: Person) -> Dictionary:
	var out := {}
	for bone in LOOKS:
		out[bone] = person.skeleton_to_me * _poses[person.skeleton.find_bone(bone)].origin
	return out


func _mass(ragdoll: RiderRagdoll) -> float:
	var total := 0.0
	for part in ragdoll.bodies:
		total += part.mass
	return total


## The lowest bone (world height), leaving out the tips of fingers and toes.
func _lowest(person: Person) -> float:
	var low := INF
	var skel := person.skeleton
	for i in skel.get_bone_count():
		if not skel.get_bone_name(i).ends_with("_end"):
			low = minf(low, (skel.global_transform * _poses[i].origin).y)
	return low


## True if the feet are not bent forward past the line of the thighs (knees don't bend
## backwards). "Forward" is the person's front, carried along with each thigh.
func _knees_bend_back(person: Person) -> bool:
	var skel := person.skeleton
	var front := (person.skeleton_to_me.basis.inverse() * Vector3.FORWARD).normalized()
	for side in ["Left", "Right"]:
		var thigh := skel.find_bone(side + "UpLeg")
		var knee := _poses[skel.find_bone(side + "Leg")].origin
		var ankle := _poses[skel.find_bone(side + "Foot")].origin
		var rest_front := skel.get_bone_global_rest(thigh).basis.inverse() * front
		var thigh_front := (_poses[thigh].basis * rest_front).normalized()
		if (ankle - knee).normalized().dot(thigh_front) > 0.3:
			return false
	return true


func _check(label: String, good: bool) -> void:
	_count += 1
	print("%s: %s" % ["PASS" if good else "FAIL", label])
	if not good:
		_failures += 1
