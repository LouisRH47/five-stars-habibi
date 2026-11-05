class_name Person
extends Node3D
## One animated person (Session 29): the rider, customers, teachers, kids, grooms...
## The body is the free "Animated Human" by Quaternius (CC0, assets/characters/, see
## CREDITS.md). It comes with idle, walk and run (we call it jog) animations. Waving and
## pedalling are made here in code by bending the bones (scripts/person_pose.gd).
## Clothes are painted: the model's texture is 5 coloured stripes (skin, eyes, hair,
## shirt, trousers), so paint() makes a new stripe picture in any colours.
## Hats, helmets, bags and so on are small shapes that follow one bone (follow()).
## The person faces -Z (like the bike) and stands on y = 0.

const MODEL := preload("res://assets/characters/quaternius_human/human.fbx")
const MODEL_HEIGHT := 5.2  # how tall the model is before we scale it
## Our names for the model's animations.
const CLIPS := {
	"idle": "Human Armature|Idle",
	"walk": "Human Armature|Walk",
	"jog": "Human Armature|Run",
}
## Everything a person can do: the clips above, plus poses made in code.
## Session 81: "swim" (swimming laps), "rest" (in the water, arms on the pool edge) and
## "whistle" (the lifeguard blowing his whistle), see scripts/pool_poses.gd.
const ACTIONS := ["idle", "walk", "jog", "wave", "pedal", "lie", "sit", "swim", "rest", "whistle"]
## The actions that are poses made in code (scripts/person_pose.gd), on top of the idle clip.
const POSES := ["wave", "pedal", "lie", "sit", "swim", "rest", "whistle"]
## The default colours. Anything not given to paint() comes from here.
const COLOURS := {
	"skin": Color(0.85, 0.66, 0.5),
	"eyes": Color(0.12, 0.1, 0.1),
	"hair": Color(0.18, 0.13, 0.1),
	"shirt": Color(0.95, 0.55, 0.16),
	"pants": Color(0.23, 0.3, 0.48),
}
# Which rows of the 32-row stripe picture belong to which colour (from the model's texture).
const STRIPES := [["skin", 0, 6], ["eyes", 6, 11], ["hair", 11, 17], ["shirt", 17, 23], ["pants", 23, 32]]

## What the person is doing now (one of ACTIONS).
var action := ""
var skeleton: Skeleton3D
var player: AnimationPlayer
var pose: PersonPose
## Turns a spot on the skeleton into a spot on the person (metres, facing -Z).
var skeleton_to_me := Transform3D()

var _mesh: MeshInstance3D
var _followers: Array = []  # the holders from follow()
static var _materials := {}  # one material per set of colours, shared
var _colours: Dictionary = COLOURS.duplicate()


func _init(height := GameConfig.PERSON_HEIGHT) -> void:
	var body: Node3D = MODEL.instantiate()
	body.name = "Body"
	body.rotation.y = PI  # the model faces +Z; our people face -Z
	body.scale = Vector3.ONE * height / MODEL_HEIGHT
	add_child(body)
	skeleton = body.find_children("*", "Skeleton3D", true, false)[0]
	player = body.find_children("*", "AnimationPlayer", true, false)[0]
	_mesh = body.find_children("*", "MeshInstance3D", true, false)[0]
	# Skinned poses can move the skull/hands beyond the imported rest-pose bounds.
	# Keep a modest local margin so turning/waving people do not disappear at an edge.
	for part: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		part.extra_cull_margin = part.mesh.get_aabb().size.y * 0.25
	for clip in CLIPS.values():
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var node: Node = skeleton
	while node != self:
		skeleton_to_me = (node as Node3D).transform * skeleton_to_me
		node = node.get_parent()
	pose = PersonPose.new()
	pose.name = "Pose"
	pose.person = self
	skeleton.add_child(pose)
	skeleton.skeleton_updated.connect(_move_followers)
	paint({})
	play("idle")


## Starts an action from ACTIONS. speed: how fast the animation runs (1 = normal).
func play(what: String, speed := 1.0) -> void:
	player.speed_scale = speed
	if what == action:
		return
	action = what
	pose.mode = what if what in POSES else ""
	player.play(CLIPS.get(what, CLIPS["idle"]), GameConfig.PERSON_BLEND_TIME)


## True if this person can do `what` (the smoke test checks every action).
func can_do(what: String) -> bool:
	if what in CLIPS:
		return player.has_animation(CLIPS[what])
	return what in ACTIONS


## Validate the actual skinned skull, not just a hat or an empty attachment node.
func has_head_geometry() -> bool:
	var head := skeleton.find_bone("Head")
	if head < 0 or skeleton.find_bone("HeadTop_End") < 0:
		return false
	for part: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface in part.mesh.get_surface_count():
			var arrays := part.mesh.surface_get_arrays(surface)
			var bones = arrays[Mesh.ARRAY_BONES]
			var weights = arrays[Mesh.ARRAY_WEIGHTS]
			if bones == null or weights == null:
				continue
			for i in bones.size():
				if bones[i] == head and weights[i] > 0.1:
					return true
	return false


## Paints the clothes. colours: any of skin, eyes, hair, shirt, pants.
func paint(colours: Dictionary) -> void:
	var all := COLOURS.merged(colours, true)
	_colours = all
	var key := str(all)
	if not _materials.has(key):
		var picture := Image.create(1, 32, false, Image.FORMAT_RGBA8)
		for stripe in STRIPES:
			for y in range(stripe[1], stripe[2]):
				picture.set_pixel(0, y, all[stripe[0]])
		var made := StandardMaterial3D.new()
		made.albedo_texture = ImageTexture.create_from_image(picture)
		made.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		made.roughness = 0.85
		_materials[key] = made
	_mesh.material_override = _materials[key]


## Change one garment while retaining the rest of the rider's preset palette.
func repaint(colours: Dictionary) -> void:
	paint(_colours.merged(colours, true))


## A holder that moves with one bone (e.g. "Head", "Spine2", "LeftHand", "LeftFoot").
## Put shapes in it at spots on the person standing straight (see spot()), and they
## follow that bone when it moves. parent: where the holder goes (this person if null).
func follow(bone: String, parent: Node3D = null) -> Node3D:
	var holder := Node3D.new()
	holder.name = bone
	holder.set_meta("bone", skeleton.find_bone(bone))
	(parent if parent != null else self).add_child(holder)
	_followers.append(holder)
	# Try-on screens pause animation. A new hat still needs the current bone pose
	# immediately, rather than waiting for the next skeleton_updated signal.
	_move_follower(holder)
	return holder


## Where a bone is (in metres on the person) when they stand straight, arms out.
func spot(bone: String) -> Vector3:
	return skeleton_to_me * skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin


## The middle of the head, standing straight.
func head_spot() -> Vector3:
	return (spot("Head") + spot("HeadTop_End")) * 0.5


## After the bones move each frame: move every holder with its bone.
func _move_followers() -> void:
	_followers = _followers.filter(func(holder: Variant) -> bool: return is_instance_valid(holder))
	for holder: Node3D in _followers:
		_move_follower(holder)


func _move_follower(holder: Node3D) -> void:
	var bone: int = holder.get_meta("bone")
	var moved := skeleton.get_bone_global_pose(bone) * skeleton.get_bone_global_rest(bone).affine_inverse()
	holder.transform = skeleton_to_me * moved * skeleton_to_me.affine_inverse()
