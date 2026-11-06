class_name Stroller
extends Node3D
## Session 92: a baby stroller with a child inside, pushed by a parent. The model is
## assets/models/stroller_<colour>.glb (made by tools/blender/make_stroller.py): a frame, a
## seat with a rounded hood, the child, and four wheels that turn as it rolls (roll()).
## push() puts it in front of a person and puts their hands on the handle (scripts/push_arms.gd),
## so it moves with them. The stroller faces -Z, its handle is at the back (+Z).

const COLOURS := ["navy", "berry", "grey"]

## The wheels (each turns round its own axle) and how far the stroller has rolled (metres).
var wheels: Array[Node3D] = []
var rolled := 0.0
## The middle of the handle bar, on the stroller.
var handle := Vector3(0, 1.0, 0.5)

static var _scenes := {}
static var _paint: StandardMaterial3D


## A stroller in colour number `colour` (0 navy, 1 berry, 2 grey).
static func make(colour: int) -> Stroller:
	var stroller := Stroller.new()
	stroller.name = "Stroller"
	var file: String = COLOURS[colour % COLOURS.size()]
	if not _scenes.has(file):
		_scenes[file] = load("res://assets/models/stroller_%s.glb" % file)
	var model := (_scenes[file] as PackedScene).instantiate() as Node3D
	model.name = "Model"
	stroller.add_child(model)
	for view: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		view.material_override = paint()
		if String(view.name).begins_with("Wheel"):
			stroller.wheels.append(view)
	var bar := model.find_child("Handle", true, false) as Node3D
	if bar != null:
		stroller.handle = bar.position
	return stroller


## The model's colours are painted on its corners (like the playground pieces).
static func paint() -> StandardMaterial3D:
	if _paint == null:
		_paint = StandardMaterial3D.new()
		_paint.vertex_color_use_as_albedo = true  # the colours are linear (as glTF stores them)
		_paint.roughness = 0.6
	return _paint


## Puts this stroller in front of `person` (both in `holder`) and their hands on the handle.
func push(person: Person, holder: Node3D) -> PushArms:
	position = Vector3(0, 0, -GameConfig.STROLLER_HANDLE_REACH - handle.z)
	holder.add_child(self)
	var arms := PushArms.new()
	arms.name = "PushArms"
	arms.person = person
	arms.pose = person.pose
	var grip := position + handle
	for side in [-1.0, 1.0]:
		arms.hands.append(grip + Vector3(side * GameConfig.STROLLER_HAND_GAP * 0.5, 0, 0))
	person.skeleton.add_child(arms)  # after PersonPose, so it goes on top of the walk
	person.set_meta("stroller", self)
	return arms


## Rolls `metres` forward: every wheel turns by the distance over its radius.
func roll(metres: float) -> void:
	rolled += metres
	for wheel in wheels:
		wheel.rotation.x = -rolled / maxf(wheel.position.y, 0.05)  # its axle is as high as its radius
