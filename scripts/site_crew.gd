class_name SiteCrew
extends Node3D
## Session 92: the workers at a building site, each with a job loop. A foreman with a
## clipboard stands by the crane. The workers take turns at the jobs (JOBS): every
## GameConfig.WORKER_JOB_SECONDS each one walks to the next job:
##   "carry":  carries blocks from the pallet to the timber frame (and walks back for more)
##   "hammer": hammers nails into the timber frame
##   "mix":    shovels sand into the cement mixer (its drum turns)
##   "talk":   chats with the foreman by the crane (they take turns to talk)
## There's one more job than workers, so the jobs swap round. Their hands are posed by
## scripts/worker_arms.gd. They wear work clothes, a hi-vis vest and a hard hat.
## LandmarkBuilder and DistrictDetail make one at each site (make()). Far away the workers
## are hidden and stop animating (cheap), like PlaceCrowds does.
## Spots are on the crew: its X runs along the site, Z across it.

const JOBS := ["carry", "hammer", "mix", "talk"]
## Where each job is done: [spot, which way the worker faces there (a point to look at)].
const PALLET := Vector3(-4.2, 0, 0.6)
const FRAME := Vector3(0.4, 0, -2.6)
const MIXER := Vector3(4.0, 0, 0.4)
const FOREMAN := Vector3(0.6, 0, 3.2)
const WOOD := Color(0.72, 0.55, 0.35)
const BLOCK := Color(0.68, 0.68, 0.66)
const ORANGE := Color(0.95, 0.5, 0.12)
const STEEL := Color(0.45, 0.47, 0.5)

var workers: Array[Person] = []
var foreman: Person
## What each worker is doing now (one of JOBS), and how far through it they are.
var jobs: Array[String] = []
var arms: Array[WorkerArms] = []
var drum: Node3D
var _shift := 0           # how many times the jobs have swapped round
var _job_left := 0.0      # seconds until the next swap
var _walk: Array = []     # each worker: [from, to, seconds left walking, carrying?] or []
var _carry_left: Array[float] = []
var _check_left := 0.0
var _near := true


## A crew at `at` (on `parent`), its X turned to `along` (a direction on the ground).
## first: the first worker's number (so the sites don't all look the same).
static func make(parent: Node3D, at: Vector3, along: Vector3, first := 0) -> SiteCrew:
	var crew := SiteCrew.new()
	crew.name = "SiteCrew"
	crew.position = at
	crew.rotation.y = atan2(-along.z, along.x)  # its +X points along `along`
	parent.add_child(crew)
	crew._build_props()
	crew.foreman = crew._person(PlaceLooks.worker(first + 3), "SiteForeman", FOREMAN, FOREMAN + Vector3(0, 0, -1))
	crew.foreman.pose.relaxed = true
	crew.foreman.pose.talking = true
	PlaceLooks.held(crew.foreman, crew.foreman.follow("LeftHand"), "Left", Vector3(0.025, 0.3, 0.22), Color(0.55, 0.4, 0.25), 0.1)  # clipboard
	for i in GameConfig.SITE_WORKERS:
		var worker := crew._person(PlaceLooks.worker(first + i), "SiteWorker%d" % i, Vector3.ZERO, Vector3.FORWARD)
		var hands := WorkerArms.new()
		hands.name = "WorkerArms"
		hands.person = worker
		hands.pose = worker.pose
		worker.skeleton.add_child(hands)  # after PersonPose: on top of the walk or idle
		WorkerArms.add_tools(hands)
		crew.workers.append(worker)
		crew.arms.append(hands)
		crew.jobs.append("")
		crew._walk.append([])
		crew._carry_left.append(0.0)
	crew._job_left = GameConfig.WORKER_JOB_SECONDS * (0.5 + randf() * 0.5)
	crew._assign(true)
	return crew


## The job worker number `i` should be doing on swap number `shift`.
static func job_for(i: int, shift: int) -> String:
	return JOBS[(i + shift) % JOBS.size()]


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		var camera := get_viewport().get_camera_3d()
		var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
		var gap := global_position.distance_to(camera.global_position) if camera != null else 0.0
		_near = gap < far
		for person in workers + [foreman]:
			PlaceCrowds.apply_detail(person, gap, far)
	advance(delta)
	if _near and drum != null:
		var mixing: bool = jobs.has("mix") and (_walk[jobs.find("mix")] as Array).is_empty()
		drum.rotate_object_local(Vector3.UP, delta * (2.5 if mixing else 0.6))


## Moves time on by `delta` seconds: the jobs swap round now and then, and the workers walk
## to their jobs and do them. (The test calls this to skip ahead.)
func advance(delta: float) -> void:
	_job_left -= delta
	if _job_left <= 0.0:
		_job_left = GameConfig.WORKER_JOB_SECONDS
		_shift += 1
		_assign(false)
	for i in workers.size():
		_work(i, delta)


## Gives everyone their job for this swap. at_once: put them straight there (the start).
func _assign(at_once: bool) -> void:
	for i in workers.size():
		jobs[i] = job_for(i, _shift)
		var spot := _job_spot(jobs[i])
		if at_once:
			_holder(i).position = spot[0]
			_face(i, spot[1])
			_walk[i] = []
		else:
			_go(i, spot[0], false)
		arms[i].task = ""
	foreman.pose.talking = false


func _work(i: int, delta: float) -> void:
	var person := workers[i]
	var walk: Array = _walk[i]
	if not walk.is_empty():
		var holder := _holder(i)
		var to: Vector3 = walk[1]
		var gap := to - holder.position
		var step := GameConfig.WORKER_WALK_SPEED * delta
		person.play("walk", GameConfig.WORKER_WALK_SPEED / GameConfig.PERSON_WALK_ANIM_MPS)
		arms[i].task = "carry" if walk[2] else ""
		if gap.length() > step:
			holder.position += gap.normalized() * step
			holder.rotation.y = atan2(-gap.x, -gap.z)
			return
		holder.position = to
		_walk[i] = []
		_arrive(i)
		return
	person.play("idle")
	if jobs[i] == "carry":
		_carry_left[i] -= delta
		if _carry_left[i] <= 0.0:  # put the block down (or pick one up) and walk on
			var at_frame := _holder(i).position.distance_to(_drop_spot()) < 0.5
			_go(i, PALLET + Vector3(0, 0, 1.0) if at_frame else _drop_spot(), not at_frame)


## Starts walking to `to`. carrying: with a block in the hands.
func _go(i: int, to: Vector3, carrying: bool) -> void:
	_walk[i] = [_holder(i).position, to, carrying]
	workers[i].pose.talking = false
	workers[i].pose.relaxed = false


## Got there: face the work and start it.
func _arrive(i: int) -> void:
	var job := jobs[i]
	var spot := _job_spot(job)
	var person := workers[i]
	match job:
		"carry":
			var at_frame := _holder(i).position.distance_to(_drop_spot()) < 0.5
			_face(i, FRAME if at_frame else PALLET)
			arms[i].task = "lift"
			_carry_left[i] = GameConfig.WORKER_PICK_SECONDS
		"talk":  # face to face with the foreman
			_face(i, FOREMAN)
			var boss := foreman.get_parent() as Node3D
			var way := _holder(i).position - boss.position
			boss.rotation.y = atan2(-way.x, -way.z)
			foreman.pose.talking = true
			person.pose.relaxed = true
			person.pose.talking = true
			person.pose.talk_turn = 1.0
			person.pose.talk_seed = foreman.pose.talk_seed
			arms[i].task = ""
		_:
			_face(i, spot[1])
			arms[i].task = job


## [where to stand, what to look at] for a job.
func _job_spot(job: String) -> Array:
	match job:
		"carry":
			return [PALLET + Vector3(0, 0, 1.0), PALLET]
		"hammer":
			return [FRAME + Vector3(0.9, 0, 0.85), FRAME + Vector3(0.9, 0, 0)]
		"mix":
			return [MIXER + Vector3(-0.3, 0, 1.15), MIXER + Vector3(-0.6, 0, 0)]
	return [FOREMAN + Vector3(0, 0, -GameConfig.TALK_GAP), FOREMAN]


func _drop_spot() -> Vector3:
	return FRAME + Vector3(-1.3, 0, 0.9)


func _holder(i: int) -> Node3D:
	return workers[i].get_parent() as Node3D


func _face(i: int, target: Vector3) -> void:
	var holder := _holder(i)
	var way := target - holder.position
	if Vector2(way.x, way.z).length() > 0.05:
		holder.rotation.y = atan2(-way.x, -way.z)


## Puts a person in a holder at `spot` (on the crew), looking at `look`.
func _person(person: Person, node_name: String, spot: Vector3, look: Vector3) -> Person:
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = spot
	var way := look - spot
	holder.rotation.y = atan2(-way.x, -way.z)
	add_child(holder)
	person.name = node_name
	holder.add_child(person)
	person.play("idle")
	return person


## The pallet of blocks, the timber frame being built, the cement mixer and a sand pile.
func _build_props() -> void:
	var kit := MeshKit.new()
	# A pallet with blocks stacked on it.
	kit.box(Vector3(1.2, 0.14, 1.0), WOOD.darkened(0.2), PALLET + Vector3(0, 0.07, 0))
	for layer in 3:
		for x in 3:
			for z in 2:
				kit.box(Vector3(0.36, 0.2, 0.44), BLOCK, PALLET + Vector3(-0.38 + x * 0.38, 0.25 + layer * 0.21, -0.23 + z * 0.46))
	# The timber frame: posts, a bottom and a top beam, and a diagonal brace.
	for x in [-1.8, -0.6, 0.6, 1.8]:
		kit.box(Vector3(0.12, 2.4, 0.12), WOOD, FRAME + Vector3(x, 1.2, 0))
	kit.box(Vector3(3.8, 0.12, 0.14), WOOD, FRAME + Vector3(0, 0.06, 0))
	kit.box(Vector3(3.8, 0.12, 0.14), WOOD, FRAME + Vector3(0, 2.4, 0))
	kit.box(Vector3(0.1, 2.6, 0.1), WOOD.darkened(0.1), FRAME + Vector3(-1.2, 1.2, 0.02), Basis(Vector3.BACK, 0.46))
	# Blocks already put down by the frame.
	for k in 4:
		kit.box(Vector3(0.36, 0.2, 0.44), BLOCK, _drop_spot() + Vector3(-0.5 + (k % 2) * 0.4, 0.1 + (k >> 1) * 0.21, -0.75))
	# The cement mixer: a stand and two wheels (the drum turns, so it's a separate part).
	kit.box(Vector3(0.12, 0.7, 0.12), ORANGE, MIXER + Vector3(0, 0.35, 0))
	kit.box(Vector3(1.1, 0.08, 0.1), STEEL, MIXER + Vector3(0, 0.3, 0))
	for x in [-0.5, 0.5]:
		kit.cylinder(0.2, 0.2, 0.08, Color(0.1, 0.1, 0.1), MIXER + Vector3(x, 0.2, 0.25), Basis(Vector3.BACK, PI * 0.5))
	kit.cylinder(0.0, 1.4, 0.9, Color(0.86, 0.8, 0.62), MIXER + Vector3(-0.6, 0.45, -0.9), Basis(), 10)  # the sand pile
	add_child(kit.finish("SiteProps"))
	drum = Node3D.new()
	drum.name = "MixerDrum"
	drum.position = MIXER + Vector3(0, 0.95, 0)
	drum.rotation.z = deg_to_rad(-35.0)  # tipped towards the opening
	add_child(drum)
	var body := MeshKit.new()
	body.cylinder(0.32, 0.42, 0.55, ORANGE, Vector3.ZERO, Basis(), 10)
	body.cylinder(0.2, 0.32, 0.25, ORANGE.darkened(0.15), Vector3(0, 0.4, 0), Basis(), 10)
	body.box(Vector3(0.06, 0.5, 0.86), ORANGE.darkened(0.3), Vector3.ZERO)  # a band, so you see it turn
	drum.add_child(body.finish("Drum"))
