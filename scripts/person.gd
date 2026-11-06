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
## Session 92: "lounge" (lying back on a sun lounger, scripts/lounge_pose.gd).
const ACTIONS := ["idle", "walk", "jog", "wave", "pedal", "lie", "sit", "swim", "rest", "whistle", "lounge"]
## The actions that are poses made in code (scripts/person_pose.gd), on top of the idle clip.
const POSES := ["wave", "pedal", "lie", "sit", "swim", "rest", "whistle", "lounge"]
## The default colours. Anything not given to paint() comes from here.
## Session 92: "shoes" is the colour painted on the feet (the same as the skin if not given:
## bare feet), and "shins" below the knees (the same as the trousers if not given; skin
## for shorts). Painted on the body, they bend and move exactly with the legs.
const COLOURS := {
	"skin": Color(0.85, 0.66, 0.5),
	"eyes": Color(0.12, 0.1, 0.1),
	"hair": Color(0.18, 0.13, 0.1),
	"shirt": Color(0.95, 0.55, 0.16),
	"pants": Color(0.23, 0.3, 0.48),
}
# Which rows of the 32-row stripe picture belong to which colour (from the model's texture).
# Session 92: row 10 (unused by the model) is the feet, so shoes can be painted on.
# Rows 10 and 30 (unused by the model) are the feet and the shins.
const STRIPES := [["skin", 0, 6], ["eyes", 6, 10], ["shoes", 10, 11], ["hair", 11, 17], ["shirt", 17, 23],
		["pants", 23, 30], ["shins", 30, 32]]
const FEET_ROW := 10
const SHINS_ROW := 30

## What the person is doing now (one of ACTIONS).
var action := ""
var skeleton: Skeleton3D
var player: AnimationPlayer
var pose: PersonPose
## Turns a spot on the skeleton into a spot on the person (metres, facing -Z).
var skeleton_to_me := Transform3D()
## Session 83: the model's resting skeleton is turned about 43 degrees round. This turns
## it back, so spots (spot()) and the clothes that follow a bone (follow()) are on a
## person standing straight: left to right is +X and the front is -Z. Worked out once.
static var _straight := Basis()
static var _straight_known := false

var _mesh: MeshInstance3D
var _followers: Array = []  # the holders from follow()
static var _fitted: ArrayMesh  # Session 92: the body with the shirt's hem held on the hips
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
	_mesh.mesh = _fitted_body(_mesh)
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
	# Session 92: draw the body whenever a box round the whole person (in any pose) is on
	# screen. Godot's own box for a moving skinned body sometimes lagged behind, so some
	# workers' bodies vanished while their hats and vests stayed.
	var mesh_to_me := Transform3D()
	node = _mesh
	while node != self:
		mesh_to_me = (node as Node3D).transform * mesh_to_me
		node = node.get_parent()
	_mesh.custom_aabb = mesh_to_me.affine_inverse() * GameConfig.PERSON_DRAW_BOX
	if not _straight_known:
		_straight = _find_straight()
		_straight_known = true
	pose = PersonPose.new()
	pose.name = "Pose"
	pose.person = self
	skeleton.add_child(pose)
	skeleton.skeleton_updated.connect(_move_followers)
	paint({})
	Face.add(self)  # Session 83: eyes and a smile
	play("idle")


## Starts an action from ACTIONS. speed: how fast the animation runs (1 = normal).
func play(what: String, speed := 1.0) -> void:
	player.speed_scale = speed
	if what == action:
		return
	action = what
	pose.mode = what if what in POSES else ""
	# Session 92: running feet move too fast for the round shoe shells to keep up exactly
	# (they'd trail behind the foot), so then only the shoes painted on the feet show.
	for holder: Variant in _followers:
		if not is_instance_valid(holder):
			continue
		for part in ["Shoe", "ShoeToe"]:
			var shell := (holder as Node).get_node_or_null(part) as Node3D
			if shell != null:
				shell.visible = what != "jog"
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
	if not colours.has("shoes"):
		all["shoes"] = all["skin"]  # bare feet
	if not colours.has("shins"):
		all["shins"] = all["pants"]  # long trousers
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


## Session 92: the model's shirt hem is partly fixed to the thighs, so when the legs swing
## (running) the shirt stretched down over the leg. This copy of the body moves those
## shirt corners onto the hips instead. Made once and shared by everyone.
static func _fitted_body(view: MeshInstance3D) -> Mesh:
	if _fitted != null:
		return _fitted
	var arrays := view.mesh.surface_get_arrays(0)
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / maxi(uv.size(), 1)
	var hips := -1
	var legs: Array[int] = []
	for i in view.skin.get_bind_count():
		var bone := view.skin.get_bind_name(i)
		if bone == "Hips":
			hips = i
		elif bone in ["LeftUpLeg", "RightUpLeg"]:
			legs.append(i)
	var shirt: Array = STRIPES[4]
	var feet: Array[int] = []
	var shins: Array[int] = []
	for i in view.skin.get_bind_count():
		if view.skin.get_bind_name(i) in ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
			feet.append(i)
		elif view.skin.get_bind_name(i) in ["LeftLeg", "RightLeg"]:
			shins.append(i)
	for v in uv.size():
		var row := int(uv[v].y * 32.0)
		var bone := _main_bone(bones, weights, v, per)
		if row < 6 and bone in feet:
			uv[v] = Vector2(uv[v].x, (FEET_ROW + 0.5) / 32.0)  # the feet get their own stripe (shoes)
			continue
		if row >= 23 and (bone in shins or bone in feet):  # (the trouser cuffs are on the feet)
			uv[v] = Vector2(uv[v].x, (SHINS_ROW + 0.5) / 32.0)  # and so do the shins
			continue
		if row < shirt[1] or row >= shirt[2]:
			continue
		var moved := 0.0
		var on_hips := -1
		for k in per:
			var slot := v * per + k
			if bones[slot] in legs:
				moved += weights[slot]
				weights[slot] = 0.0
			elif bones[slot] == hips and on_hips < 0:
				on_hips = slot
		if moved <= 0.0:
			continue
		if on_hips < 0:  # use an empty slot for the hips
			for k in per:
				if weights[v * per + k] <= 0.0:
					on_hips = v * per + k
					bones[on_hips] = hips
					break
		weights[on_hips] += moved
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_TEX_UV] = uv
	_fitted = ArrayMesh.new()
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0
	_fitted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	_fitted.surface_set_material(0, view.mesh.surface_get_material(0))
	return _fitted


## The bone (its number in the skin) that moves corner `v` the most.
static func _main_bone(bones: PackedInt32Array, weights: PackedFloat32Array, v: int, per: int) -> int:
	var best := v * per
	for k in per:
		if weights[v * per + k] > weights[best]:
			best = v * per + k
	return bones[best]


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
	return _straight.inverse() * (skeleton_to_me * skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin)


## How much the resting skeleton is turned: from the hips and shoulders, which should
## run straight from left (-X) to right (+X).
func _find_straight() -> Basis:
	var across := Vector3.ZERO
	for pair in [["LeftUpLeg", "RightUpLeg"], ["LeftArm", "RightArm"], ["LeftFoot", "RightFoot"]]:
		var a := skeleton_to_me * skeleton.get_bone_global_rest(skeleton.find_bone(pair[0])).origin
		var b := skeleton_to_me * skeleton.get_bone_global_rest(skeleton.find_bone(pair[1])).origin
		across += Vector3(b.x - a.x, 0, b.z - a.z).normalized()
	return Basis(Vector3.UP, -atan2(across.z, across.x))


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
	holder.transform = skeleton_to_me * moved * skeleton_to_me.affine_inverse() * Transform3D(_straight)
