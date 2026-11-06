class_name WorkerArms
extends SkeletonModifier3D
## Session 92: a building site worker's arms (and tools), on top of their walk or idle.
## It runs after PersonPose, like WaiterArms. task (set by SiteCrew):
##   "carry":  holding a concrete block in front with both hands (walking)
##   "lift":   bending down to pick a block up from the pallet or put it down
##   "hammer": the left hand holds the timber, the right hand swings a hammer at it
##   "mix":    shovelling sand into the cement mixer (scoop low, lift, tip it in)
##   "":       nothing in the hands
## Spots are in metres on the person (facing -Z, +X is their right).

var person: Person
var pose: PersonPose
var task := ""
var hammer: Node3D
var shovel: Node3D
var block: Node3D
var _clock := randf() * 10.0


## Makes the hammer, the shovel and the block (hidden until a task needs them).
static func add_tools(arms: WorkerArms) -> void:
	var person := arms.person
	# The hammer: a wooden handle out of the fist (pointing forward on the resting arm) and a
	# steel head across its end.
	arms.hammer = person.follow("RightHand")
	arms.hammer.name = "Hammer"
	var grip := person.spot("RightHand") + Vector3(0.07, 0, 0)
	LowPoly.box(arms.hammer, Vector3(0.03, 0.03, 0.3), SiteCrew.WOOD, grip + Vector3(0, 0, -0.12))
	LowPoly.box(arms.hammer, Vector3(0.04, 0.13, 0.05), SiteCrew.STEEL, grip + Vector3(0, 0.02, -0.26))
	# The shovel and the block are on the person; _process_modification moves them with the hands.
	arms.shovel = Node3D.new()
	arms.shovel.name = "Shovel"
	person.add_child(arms.shovel)
	LowPoly.box(arms.shovel, Vector3(0.035, 0.035, 1.1), SiteCrew.WOOD, Vector3(0, 0, -0.35))
	LowPoly.box(arms.shovel, Vector3(0.24, 0.02, 0.28), SiteCrew.STEEL, Vector3(0, -0.03, -1.0))
	arms.block = LowPoly.box(person, Vector3(0.36, 0.2, 0.3), SiteCrew.BLOCK, Vector3(0, 0.9, -0.32))
	arms.block.name = "Block"
	for tool in [arms.hammer, arms.shovel, arms.block]:
		tool.visible = false


func _process_modification_with_delta(delta: float) -> void:
	if person == null or pose == null:
		return
	_clock += delta
	hammer.visible = task == "hammer"
	shovel.visible = task == "mix"
	block.visible = task == "carry"
	match task:
		"carry":
			_hold_block(GameConfig.WORKER_BLOCK_HEIGHT)
		"lift":
			var down := sin(_clock * PI / GameConfig.WORKER_PICK_SECONDS) ** 2  # down and back up
			pose.turn("Spine", Vector3.RIGHT, deg_to_rad(-55.0 * down))
			_reach_both(Vector3(0, lerpf(0.95, 0.55, down), lerpf(-0.32, -0.5, down)))
		"hammer":
			_hammer()
		"mix":
			_shovel()


## Both hands under a block in front of the tummy.
func _hold_block(height: float) -> void:
	_reach_both(Vector3(0, height, -0.32))
	block.position = Vector3(0, height + 0.08, -0.36)


func _reach_both(middle: Vector3) -> void:
	pose.reach("LeftArm", "LeftForeArm", "LeftHand", middle + Vector3(-0.17, 0, 0), Vector3(-0.8, -1.0, 0.3))
	pose.reach("RightArm", "RightForeArm", "RightHand", middle + Vector3(0.17, 0, 0), Vector3(0.8, -1.0, 0.3))


## The left hand holds the timber; the right hand comes up and strikes, twice a second.
func _hammer() -> void:
	var beat := fposmod(_clock * GameConfig.WORKER_HAMMER_RATE, 1.0)
	var up := smoothstep(0.0, 0.7, beat) if beat < 0.7 else 1.0 - smoothstep(0.7, 1.0, beat)
	var hit := Vector3(0.12, 1.05, -0.5)
	var raised := Vector3(0.28, 1.45, -0.3)
	pose.reach("RightArm", "RightForeArm", "RightHand", hit.lerp(raised, up), Vector3(1.0, -0.6, 0.4))
	pose.reach("LeftArm", "LeftForeArm", "LeftHand", Vector3(-0.08, 1.12, -0.52), Vector3(-1.0, -0.8, 0.2))


## Shovelling: scoop low in front, lift and turn to the right, tip it into the mixer.
func _shovel() -> void:
	var t := fposmod(_clock / GameConfig.WORKER_SHOVEL_SECONDS, 1.0)
	var lift := sin(t * PI)  # 0 down at the sand, 1 up at the mixer
	pose.turn("Spine", Vector3.RIGHT, deg_to_rad(-30.0 * (1.0 - lift)))
	pose.turn("Spine1", Vector3.UP, deg_to_rad(-35.0 * lift))  # turning to the mixer (on the right)
	var low := Vector3(0.12, lerpf(0.62, 1.05, lift), lerpf(-0.42, -0.35, lift))  # the lower (right) hand
	var high := Vector3(-0.08, lerpf(0.95, 1.25, lift), lerpf(-0.05, -0.02, lift))  # the top of the handle
	pose.reach("RightArm", "RightForeArm", "RightHand", low, Vector3(1.0, -1.0, 0.2))
	pose.reach("LeftArm", "LeftForeArm", "LeftHand", high, Vector3(-1.0, -1.0, 0.2))
	# The shovel runs from the top hand through the lower hand and on to the blade.
	var way := (low - high).normalized()
	shovel.transform = Transform3D(Basis.looking_at(way, Vector3.UP), high)
