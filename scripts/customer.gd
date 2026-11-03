extends Node3D
## A customer at their front door. They step out, wave, say one line in a speech bubble,
## then go back inside and disappear. The model is an animated Person (Session 29) in one
## of the 5 resident outfits (scripts/people_looks.gd: white kandura, black abaya,
## t-shirt, red hoodie, green top with a cap). They walk, wave and stand. Ring the bike
## bell (B) nearby and they wave again. CustomerSpawner makes one per delivery and calls setup().
## The customer isn't solid, so they never trap the bike. Front (where they walk) is +Z.

const BUBBLE_HEIGHT := 2.7

## What they said (the smoke test checks it).
var line := ""
## True while the Delivered card is up: the customer stays at the door (Session 22).
var held := false

## The animated person (the smoke test checks it walks and waves).
var person: Person
var _bubble: Node3D
var _walking := false


## line_text: what they say. Their start spot is just inside the door; they walk out along +Z.
func setup(line_text: String) -> void:
	line = line_text
	person = PeopleLooks.resident(randi() % PeopleLooks.RESIDENT_OUTFITS)
	person.rotation.y = PI  # people face -Z; customers walk out along +Z
	add_child(person)
	add_to_group("hears_bell")
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
	_walking = true
	person.play("walk")
	var walk := create_tween()
	walk.tween_property(self, "position", out, GameConfig.CUSTOMER_WALK_TIME)
	await walk.finished
	_walking = false
	_bubble.visible = true
	await _wave()  # wave hello
	await get_tree().create_timer(maxf(GameConfig.CUSTOMER_TALK_TIME - GameConfig.WAVE_TIME, 0.0)).timeout
	while held:
		await get_tree().process_frame
	_bubble.visible = false
	_walking = true
	person.play("walk")
	var back := create_tween()
	back.tween_property(self, "rotation:y", rotation.y + PI, 0.3)  # turn round
	back.tween_property(self, "position", inside, GameConfig.CUSTOMER_WALK_TIME)
	back.tween_callback(queue_free)


## Waves for a moment, then stands.
func _wave() -> void:
	person.play("wave")
	await get_tree().create_timer(GameConfig.WAVE_TIME).timeout
	if not _walking:
		person.play("idle")


## The bike rang its bell (Session 29): if it's close and we're standing, wave again.
func hear_bell(bike: Node3D) -> void:
	if _walking or person.action == "wave" or not is_inside_tree():
		return
	if global_position.distance_to(bike.global_position) <= GameConfig.BELL_HEAR_RANGE:
		_wave()


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
