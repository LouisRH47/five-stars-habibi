class_name HorseModels
## Session 70: the horses and donkeys made in Blender (tools/blender/make_horse.py and
## make_donkey.py export assets/models/horse_<coat>.glb and donkey_<coat>.glb).
## Each model faces -Z with its hooves on the ground. Its legs (Leg_FL, Leg_FR, Leg_HL,
## Leg_HR) pivot at the hips, so LifeLooks can swing them; "Tack" is the saddle and reins.

## Coat name -> the colour it's closest to (callers still pass a Color, like before).
const HORSE_COATS := {
	"bay": Color(0.45, 0.28, 0.15),
	"chestnut": Color(0.65, 0.38, 0.2),
	"grey": Color(0.85, 0.82, 0.78),
	"black": Color(0.2, 0.15, 0.12),
	"palomino": Color(0.85, 0.68, 0.42),
}
const DONKEY_COATS := {"grey": Color(0.55, 0.52, 0.5), "brown": Color(0.42, 0.33, 0.27)}
## The leg order LifeLooks expects: front left, front right, back left, back right.
const LEG_NAMES := ["Leg_FL", "Leg_FR", "Leg_HL", "Leg_HR"]

static var _scenes := {}


## The coat whose colour is nearest `colour`.
static func coat_for(colour: Color, coats: Dictionary = HORSE_COATS) -> String:
	var best := ""
	var best_gap := INF
	for coat: String in coats:
		var c: Color = coats[coat]
		var gap := Vector3(c.r - colour.r, c.g - colour.g, c.b - colour.b).length_squared()
		if gap < best_gap:
			best_gap = gap
			best = coat
	return best


## A horse facing -Z. tack: show the saddle and reins (for a rider). The legs are kept in
## the model's "legs" meta, like the old box horse.
static func horse(colour: Color, tack: bool) -> Node3D:
	var model := _make("horse_" + coat_for(colour))
	var saddle := model.get_node_or_null("Tack") as Node3D
	if saddle != null:
		saddle.visible = tack
	model.set_meta("coat", coat_for(colour))
	return model


## A donkey facing -Z (shorter than a horse, long ears, grey-brown).
static func donkey(colour: Color) -> Node3D:
	var model := _make("donkey_" + coat_for(colour, DONKEY_COATS))
	model.set_meta("coat", coat_for(colour, DONKEY_COATS))
	return model


## A horse (big = true) or a donkey standing still, just to look at (not solid). Replaces
## Props.animal: the same spot and facing (the head looks towards +Z at facing 0).
static func standing(parent: Node3D, spot: Vector3, facing: float, colour: Color, big: bool) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Horse" if big else "Donkey"
	holder.position = spot
	holder.rotation_degrees.y = facing
	parent.add_child(holder)
	var model := horse(colour, false) if big else donkey(colour)
	model.rotation.y = PI  # the models face -Z; the old ones faced +Z
	holder.add_child(model)
	holder.set_meta("legs", model.get_meta("legs"))
	holder.set_meta("animal", "horse" if big else "donkey")
	return holder


static func _make(file: String) -> Node3D:
	if not _scenes.has(file):
		_scenes[file] = load("res://assets/models/%s.glb" % file)
	var scene: PackedScene = _scenes[file]
	var model := scene.instantiate() as Node3D
	model.name = "Model"
	var legs: Array[Node3D] = []
	for leg_name: String in LEG_NAMES:
		var leg := model.find_child(leg_name, true, false) as Node3D
		if leg != null:
			legs.append(leg)
	model.set_meta("legs", legs)
	return model
