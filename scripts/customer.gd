extends Node3D
## A customer at their front door. They step out, wave, say one line in a speech bubble,
## then go back inside and disappear. The model is a simple low-poly person in one of a
## few outfits. CustomerSpawner makes one per delivery and calls setup().
## The customer isn't solid, so they never trap the bike. Front (where they walk) is +Z.

## Outfits: body colour, head cover colour (or none), and whether the robe goes to the feet.
const OUTFITS := [
	{"body": Color(0.97, 0.97, 0.95, 1), "head": Color(0.97, 0.97, 0.95, 1), "long": true},   # white kandura
	{"body": Color(0.1, 0.1, 0.12, 1), "head": Color(0.1, 0.1, 0.12, 1), "long": true},       # black abaya
	{"body": Color(0.2, 0.45, 0.75, 1), "head": null, "long": false},                         # t-shirt
	{"body": Color(0.85, 0.35, 0.3, 1), "head": null, "long": false},                         # red hoodie
	{"body": Color(0.35, 0.6, 0.4, 1), "head": Color(0.95, 0.9, 0.8, 1), "long": false},      # green top, cap
]
const SKINS := [Color(0.85, 0.66, 0.5, 1), Color(0.7, 0.5, 0.35, 1), Color(0.5, 0.35, 0.25, 1), Color(0.93, 0.78, 0.65, 1)]
const BUBBLE_HEIGHT := 2.7

## What they said (the smoke test checks it).
var line := ""
## True while the Delivered card is up: the customer stays at the door (Session 22).
var held := false

var _arm: Node3D
var _bubble: Node3D


## line_text: what they say. Their start spot is just inside the door; they walk out along +Z.
func setup(line_text: String) -> void:
	line = line_text
	var outfit: Dictionary = OUTFITS.pick_random()
	_build_model(outfit, SKINS.pick_random())
	_bubble = _make_bubble(line_text)
	_bubble.visible = false
	add_child(_bubble)
	# Keeps moving while the game is paused for the Delivered card.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_act.call_deferred()


## Step out, wave and talk; stay while the Delivered card is up; then go back inside.
func _act() -> void:
	var inside := position
	var out := position + transform.basis.z * GameConfig.CUSTOMER_STEP_OUT
	var walk := create_tween()
	walk.tween_property(self, "position", out, GameConfig.CUSTOMER_WALK_TIME)
	await walk.finished
	_bubble.visible = true
	var wave := create_tween()
	wave.tween_property(_arm, "rotation:x", deg_to_rad(-150.0), 0.25)  # wave hello
	for i in 3:
		wave.tween_property(_arm, "rotation:z", deg_to_rad(25.0), 0.2)
		wave.tween_property(_arm, "rotation:z", deg_to_rad(-25.0), 0.2)
	wave.tween_property(_arm, "rotation", Vector3.ZERO, 0.25)
	await wave.finished
	await get_tree().create_timer(maxf(GameConfig.CUSTOMER_TALK_TIME - 1.7, 0.0)).timeout
	while held:
		await get_tree().process_frame
	_bubble.visible = false
	var back := create_tween()
	back.tween_property(self, "rotation:y", rotation.y + PI, 0.3)  # turn round
	back.tween_property(self, "position", inside, GameConfig.CUSTOMER_WALK_TIME)
	back.tween_callback(queue_free)


func _build_model(outfit: Dictionary, skin: Color) -> void:
	var body: Color = outfit["body"]
	var legs := body if outfit["long"] else Color(0.25, 0.3, 0.45, 1)
	LowPoly.box(self, Vector3(0.36, 0.8, 0.24), legs, Vector3(0, 0.4, 0))       # legs / long robe
	LowPoly.box(self, Vector3(0.44, 0.65, 0.28), body, Vector3(0, 1.1, 0))      # body
	LowPoly.box(self, Vector3(0.1, 0.6, 0.12), body, Vector3(-0.28, 1.1, 0))    # left arm
	_arm = Node3D.new()  # the right arm swings from the shoulder
	_arm.position = Vector3(0.28, 1.4, 0)
	add_child(_arm)
	LowPoly.box(_arm, Vector3(0.1, 0.6, 0.12), body, Vector3(0, -0.3, 0))
	LowPoly.sphere(self, 0.17, 0.36, skin, Vector3(0, 1.62, 0))                  # head
	if outfit["head"] != null:
		LowPoly.sphere(self, 0.19, 0.3, outfit["head"], Vector3(0, 1.7, -0.02))  # head cover / cap
	LowPoly.box(self, Vector3(0.04, 0.04, 0.02), Color(0.1, 0.1, 0.1, 1), Vector3(-0.06, 1.65, 0.16))  # eyes
	LowPoly.box(self, Vector3(0.04, 0.04, 0.02), Color(0.1, 0.1, 0.1, 1), Vector3(0.06, 1.65, 0.16))


## A white rounded speech bubble that always faces the camera, with dark text on it.
static func _make_bubble(text: String) -> Node3D:
	var holder := Node3D.new()
	holder.position.y = BUBBLE_HEIGHT
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.005
	label.modulate = Color(0.08, 0.15, 0.18, 1)
	label.outline_modulate = Color(1, 1, 1, 1)
	label.outline_size = 40  # a thick white outline acts as the bubble
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 560.0
	label.render_priority = 2
	label.outline_render_priority = 1
	holder.add_child(label)
	return holder
