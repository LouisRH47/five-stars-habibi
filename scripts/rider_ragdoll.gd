class_name RiderRagdoll
extends Node
## Session 87: the rider goes floppy and tumbles for real when they fall off the bike
## (a "ragdoll"). The body parts (scripts/ragdoll_bones.gd) are only made when the fall
## starts and are removed after getting up, so until then the person looks and moves
## exactly as before. scripts/ragdoll_pose.gd makes the bones follow the parts.
## How to use it:
##   var ragdoll := RiderRagdoll.attach(person)   # once
##   ragdoll.exclude(bike)                         # don't bump into the bike itself
##   ragdoll.start(velocity)                       # fall!
##   ... wait until ragdoll.resting() ...          # follow ragdoll.body_position()
##   (put the person back on the bike), then: await ragdoll.get_up()

const LAYER := 1 << 7          # the ragdoll's own physics layer (128)
const MASK := 1                # it only bumps into the world (layer 1)
const REST_SPEED := 0.25       # m/s: slower than this counts as lying still
const REST_TIME := 0.4         # seconds every part must be still to count as resting
const REST_TIMEOUT := 4.0      # seconds: after this it counts as resting anyway
const MAX_SPEED := 14.0        # m/s: no body part ever moves faster (no explosions)
const MAX_SPIN := 20.0         # radians per second, the same for spinning
const TUMBLE := 1.2            # m/s of random wobble added to each part at the start
const GROUND_SLACK := 0.05     # metres a part may sink into the ground before we lift it
const CULL_ROOM := 6.0         # metres of extra room so the flung body never vanishes

var person: Person
## The bone mover. Its influence goes 1 -> 0 while getting up.
var pose: RagdollPose
## The body parts while falling (empty otherwise).
var bodies: Array[RigidBody3D] = []
var _joints: Array[RID] = []
var _holder: Node3D
var _still := 0.0
var _clock := 0.0
var _falling := false
var _ignored: Array[PhysicsBody3D] = []
var _cull := {}  # the meshes' own cull room, put back after a fall


## Adds a ragdoll to `person` (a Person, e.g. from RiderLook.make_rider()).
static func attach(person: Person) -> RiderRagdoll:
	var ragdoll := RiderRagdoll.new()
	ragdoll.name = "RiderRagdoll"
	ragdoll.person = person
	ragdoll.pose = RagdollPose.new()
	ragdoll.pose.name = "RagdollPose"
	ragdoll.pose.active = false
	person.skeleton.add_child(ragdoll.pose)
	person.add_child(ragdoll)
	return ragdoll


## Never bump into `body` (e.g. the bike's own collision shape).
func exclude(body: PhysicsBody3D) -> void:
	_ignored.append(body)
	for part in bodies:
		part.add_collision_exception_with(body)


## Falls off: every part starts moving at `velocity` (m/s), turning with `spin`
## (radians per second around each axis), plus a little random tumble.
func start(velocity: Vector3, spin := Vector3.ZERO) -> void:
	_remove_parts()
	person.player.pause()
	_holder = Node3D.new()
	_holder.name = "RagdollParts"
	_holder.top_level = true
	_top_node().add_child(_holder)  # not under the person, so moving the bike can't drag it
	var made := RagdollBones.make(person, _holder, LAYER, MASK)
	bodies.assign(made["bodies"])
	_joints.assign(made["joints"])
	for body in _ignored:
		for part in bodies:
			if is_instance_valid(body):
				part.add_collision_exception_with(body)
	var middle := body_position()
	for part in bodies:
		var wobble := Vector3(randf_range(-1, 1), randf_range(0, 1), randf_range(-1, 1)) * TUMBLE
		part.linear_velocity = (velocity + spin.cross(part.global_position - middle) + wobble).limit_length(MAX_SPEED)
		part.angular_velocity = (spin + wobble).limit_length(MAX_SPIN)
	pose.bodies = made["bodies"]
	pose.bones = made["bones"]
	pose.rel = made["rel"]
	pose.influence = 1.0
	pose.active = true
	_still = 0.0
	_clock = 0.0
	_falling = true
	for mesh: MeshInstance3D in person.skeleton.get_parent().find_children("*", "MeshInstance3D", true, false):
		if not _cull.has(mesh):
			_cull[mesh] = mesh.extra_cull_margin
		mesh.extra_cull_margin = CULL_ROOM / maxf(mesh.global_basis.get_scale().x, 0.0001)


## True once the body has stopped moving (or after REST_TIMEOUT seconds).
func resting() -> bool:
	return not _falling or _clock >= REST_TIMEOUT or _still >= REST_TIME


## True while the body is floppy (from start() until get_up() has finished).
func active() -> bool:
	return _falling


## Where the body is (the hips). The camera follows this while you are down.
func body_position() -> Vector3:
	if bodies.is_empty():
		return person.skeleton.global_transform * person.skeleton.get_bone_global_pose(0).origin
	return bodies[0].global_position


## Where the body lies: a spot on the ground under the hips, facing from the hips
## towards the head (so someone standing up there faces where their head was).
func settle_point() -> Transform3D:
	var hips := body_position()
	var head := person.skeleton.global_transform * person.skeleton.get_bone_global_pose(
			person.skeleton.find_bone("Head")).origin
	var way := Vector3(head.x - hips.x, 0, head.z - hips.z)
	if way.length() < 0.05:
		way = -person.global_basis.z
		way.y = 0.0
	var spot := Vector3(hips.x, _ground_y(hips), hips.z)
	return Transform3D(Basis.looking_at(way.normalized(), Vector3.UP), spot)


## Gets up: blends from the lying body back to the normal (animated) pose over
## `duration` seconds, then removes the body parts. Put the person where they should
## end up (e.g. back on the bike) before calling this. Use with await.
func get_up(duration := 0.5) -> void:
	person.player.play()
	var left := maxf(duration, 0.0)
	while left > 0.0 and is_inside_tree() and _falling:
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
		pose.influence = clampf(left / maxf(duration, 0.001), 0.0, 1.0)
	pose.influence = 0.0
	_remove_parts()


func _physics_process(delta: float) -> void:
	if not _falling:
		return
	_clock += delta
	var fastest := 0.0
	for part in bodies:
		part.linear_velocity = part.linear_velocity.limit_length(MAX_SPEED)
		part.angular_velocity = part.angular_velocity.limit_length(MAX_SPIN)
		fastest = maxf(fastest, part.linear_velocity.length())
	_still = _still + delta if fastest < REST_SPEED else 0.0
	if resting():
		_keep_above_ground()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:  # the person is removed mid-fall: tidy up
		for joint in _joints:
			PhysicsServer3D.free_rid(joint)
		_joints.clear()
		if is_instance_valid(_holder):
			_holder.queue_free()


## Takes the body parts away and hands the bones back to the animation.
func _remove_parts() -> void:
	pose.active = false
	pose.bodies = []
	for joint in _joints:
		PhysicsServer3D.free_rid(joint)
	_joints.clear()
	if is_instance_valid(_holder):
		_holder.queue_free()
	_holder = null
	bodies.clear()
	_falling = false
	for mesh: MeshInstance3D in _cull:
		if is_instance_valid(mesh):
			mesh.extra_cull_margin = _cull[mesh]
	_cull.clear()


## If any part has sunk into the ground, lift it back on top (it shouldn't happen).
func _keep_above_ground() -> void:
	for part in bodies:
		var at := part.global_position
		var floor_y := _ground_y(at)
		if at.y < floor_y - GROUND_SLACK:
			part.global_position = Vector3(at.x, floor_y, at.z)


## How high the ground is under `at` (world height in metres); `at.y - 2` if none found.
func _ground_y(at: Vector3) -> float:
	var space := person.get_world_3d().direct_space_state
	var skip: Array[RID] = []
	for body in _ignored:
		if is_instance_valid(body):
			skip.append(body.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.5, at + Vector3.DOWN * 3.0, MASK, skip)
	var hit := space.intersect_ray(ray)
	return hit["position"].y if not hit.is_empty() else at.y - 2.0


## The highest 3D node above the person (the map), where the body parts go.
func _top_node() -> Node:
	var node: Node = person
	while node.get_parent() is Node3D:
		node = node.get_parent()
	return node.get_parent() if node == person else node
