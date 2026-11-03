class_name HorseCrossing
extends Node3D
## Horses crossing (Session 33): a groom leads 2 or 3 horses in a line across a road, from
## one spot to another (a line in HORSE_CROSSINGS, data/wahat_al_shams.gd). The groom and
## each horse is a Critter (scripts/critter.gd), so they're solid, riding into them is only
## ever a small crash, and the bell works on them. If the bike or the rider on foot is
## touching one of them, the whole line stops and waits (they never shove you); if you
## stay in the way too long, they give up and go back in. scripts/event_manager.gd makes
## one and calls step() every physics frame. Numbers: the Random events block of game_config.gd.

const HORSE_COLOURS := [Color(0.45, 0.28, 0.15, 1), Color(0.85, 0.82, 0.78, 1), Color(0.2, 0.15, 0.12, 1)]
const GROOM_SIZE := Vector3(0.6, 1.8, 0.6)
const HORSE_SIZE := Vector3(0.8, 2.0, 2.6)
const ROPE := Color(0.55, 0.4, 0.25, 1)

## The groom first, then the horses (each a Critter).
var members: Array[Critter] = []
## True once the whole line has gone (or given up).
var done := false
## Seconds the line has been walking or waiting.
var time_taken := 0.0

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _walked := 0.0   # metres the groom has walked from the start
var _waited := 0.0   # seconds someone has been in the way
var _groom: Person
var _layers: Array[int] = []


## from, to: where the line comes out and where it goes out of sight. horses: 2 or 3.
func setup(from: Vector3, to: Vector3, horses: int) -> void:
	_from = from
	_to = to
	for i in horses + 1:
		var member := Critter.new()
		member.name = "Groom" if i == 0 else "Horse_%d" % i
		add_child(member)
		if i == 0:
			_groom = PeopleLooks.groom()
			member.add_child(_groom)
			member.make_body(GROOM_SIZE)
			# The lead rope from the groom's hand back to the first horse's head.
			var rope := LowPoly.box(member, Vector3(0.03, 0.03, 1.56), ROPE, Vector3(0.12, 1.55, 0.55))
			rope.rotation.x = deg_to_rad(-45.0)
		else:
			var model := Node3D.new()
			model.name = "Model"
			member.add_child(model)
			Props.animal(model, Vector3(0, 0, 0.1), 180.0, HORSE_COLOURS[(i - 1) % HORSE_COLOURS.size()], true)
			member.make_body(HORSE_SIZE)
		member.face(_to - _from)
		_layers.append(member.collision_layer)
		members.append(member)
	_place_all()


## Moves the line on by one physics frame. Returns false once it's all over.
func step(delta: float) -> bool:
	if done:
		return false
	time_taken += delta
	for member in members:
		member.scared_left = maxf(member.scared_left - delta, 0.0)
	if _someone_in_the_way():
		_waited += delta
		_groom.play("idle")
		if _waited > GameConfig.HORSE_GIVE_UP_TIME:
			done = true  # you stayed in the way: they go back in
		return not done
	_waited = 0.0
	_walked += GameConfig.HORSE_WALK_SPEED * delta
	_groom.play("walk", GameConfig.HORSE_WALK_SPEED / GameConfig.PERSON_WALK_ANIM_MPS)
	_place_all()
	if _walked - (members.size() - 1) * GameConfig.HORSE_GAP > _from.distance_to(_to):
		done = true  # the last horse is out of sight
	return not done


## Puts each one on the line between from and to; ones not out yet (or already gone)
## are hidden and can't be hit.
func _place_all() -> void:
	var length := _from.distance_to(_to)
	for i in members.size():
		var member := members[i]
		var along := _walked - i * GameConfig.HORSE_GAP
		var out := along >= 0.0 and along <= length
		if member.visible != out:
			member.visible = out
			member.collision_layer = _layers[i] if out else 0
			member.get_node("Touch").set_deferred("monitoring", out)  # hidden ones can't be bumped
		member.position = _from.lerp(_to, clampf(along / length, 0.0, 1.0))
		var model := member.get_node_or_null("Model") as Node3D
		if model != null:  # horses nod along as they walk
			model.position.y = absf(sin(along * 2.2)) * 0.05


func _someone_in_the_way() -> bool:
	for member in members:
		if member.visible and member.bike_in_the_way():
			return true
	return false
