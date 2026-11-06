class_name AmbientMotion
extends Node3D
## The small moving things that make Wahat Al Shams feel alive (Session 30), none of them
## solid: birds circling overhead (BIRD_FLOCKS in the data), palm tops swaying in the breeze,
## ripples moving on the stream and the fountain (assets/shaders/water.gdshader), the
## fountain's jet bubbling with a spray of drops, and the donkeys strolling round their pen
## (DONKEY_PEN). LifeBuilder makes this and calls build().

const BIRD := Color(0.25, 0.25, 0.28)
const DONKEY := Color(0.55, 0.52, 0.5)

var _flocks: Array = []     # [{node, radius, birds: [Node3D]}]
var _crowns: Array = []     # [palm crown, its resting rotation]
var _jet: Node3D
var _donkeys: Array = []    # [{node, target, pause}]
var _pen := Rect2()
var _clock := 0.0


## Finds the palms, water and fountain the other builders made, and adds birds and donkeys.
func build(life: Node3D, map: Dictionary) -> void:
	var main := life.get_parent()
	for palm in main.get_node("DecorBuilder").get_children():
		var crown := palm.get_node_or_null("Crown") as Node3D
		if crown != null:
			_crowns.append([crown, crown.rotation])
	var water := WaterLook.stream()  # Session 81: the same water look everywhere (scripts/water_look.gd)
	var stream := main.get_node_or_null("WahatBuilder/Stream")
	if stream != null:
		for piece: MeshInstance3D in stream.get_children():
			piece.material_override = water
	var fountain := main.get_node_or_null("PlazaBuilder/Fountain")
	if fountain != null:
		for part in ["Water", "BowlWater"]:
			(fountain.get_node(part) as MeshInstance3D).material_override = water
		_jet = fountain.get_node("Jet")
		var spray := _fountain_spray()
		spray.position = _jet.position + Vector3(0, 0.4, 0)
		fountain.add_child(spray)
		life.register(spray, 1)
	for flock: Dictionary in map.get("BIRD_FLOCKS", []):
		_add_flock(flock, life)
	if map.has("DONKEY_PEN"):
		_pen = (map["DONKEY_PEN"]["area"] as Rect2).grow(-1.3)
		for i in map["DONKEY_PEN"]["donkeys"]:
			var spot := Vector3(_pen.get_center().x - 3.0 + i * 6.0, 0, _pen.get_center().y)
			# Session 70: the Blender donkey, grey and brown in turn (scripts/horse_models.gd).
			var donkey := HorseModels.standing(self, spot, 90.0, HorseModels.DONKEY_COATS.values()[i % 2], false)
			donkey.name = "Donkey_%d" % i
			_donkeys.append({"node": donkey, "target": spot, "pause": randf_range(0.5, 3.0)})


func _process(delta: float) -> void:
	_clock += delta
	var sway := deg_to_rad(GameConfig.PALM_SWAY_DEG)
	for i in _crowns.size():
		var crown: Node3D = _crowns[i][0]
		var rest: Vector3 = _crowns[i][1]
		var t := _clock * GameConfig.PALM_SWAY_SPEED + i * 1.3
		crown.rotation = rest + Vector3(sin(t) * sway, 0.0, sin(t * 0.7 + 1.0) * sway * 0.7)
	if _jet != null:
		_jet.scale.y = 1.0 + sin(_clock * 6.0) * 0.12 + sin(_clock * 13.0) * 0.05
	for flock: Dictionary in _flocks:
		if flock["node"].visible:
			_fly(flock, delta)
	for donkey: Dictionary in _donkeys:
		_stroll(donkey, delta)


## Birds go round and round a big circle, flapping, each a little behind the one before.
func _fly(flock: Dictionary, _delta: float) -> void:
	var angle: float = _clock * GameConfig.BIRD_SPEED / flock["radius"]
	var birds: Array = flock["birds"]
	for i in birds.size():
		var bird: Node3D = birds[i]
		var a := angle - i * 0.06
		var r: float = flock["radius"] + (i % 2) * 3.0
		bird.position = Vector3(cos(a) * r, sin(_clock * 0.8 + i) * 1.5 + i * 0.7, sin(a) * r)
		bird.rotation.y = -a  # facing along the circle
		var flap := sin(_clock * 11.0 + i * 1.7) * 0.6
		bird.get_child(1).rotation.z = flap
		bird.get_child(2).rotation.z = -flap


## A donkey walks slowly to a spot in the pen, stands for a while, then picks another.
func _stroll(donkey: Dictionary, delta: float) -> void:
	var node: Node3D = donkey["node"]
	if donkey["pause"] > 0.0:
		donkey["pause"] -= delta
		node.position.y = 0.0
		_swing_legs(node, 0.0)
		return
	var gap: Vector3 = donkey["target"] - node.position
	gap.y = 0.0
	var step := GameConfig.DONKEY_SPEED * delta
	if gap.length() <= step:
		donkey["pause"] = randf_range(2.0, 6.0)
		donkey["target"] = Vector3(randf_range(_pen.position.x, _pen.end.x), 0, randf_range(_pen.position.y, _pen.end.y))
		return
	node.position += gap.normalized() * step
	node.rotation.y = lerp_angle(node.rotation.y, atan2(gap.x, gap.z), minf(1.0, delta * 3.0))  # its head is +Z
	node.position.y = absf(sin(_clock * 6.0)) * 0.02
	_swing_legs(node, sin(_clock * 6.0) * 0.3)


## Session 70: a walking donkey swings its legs in diagonal pairs (0 = standing).
func _swing_legs(node: Node3D, swing: float) -> void:
	var legs: Array = node.get_meta("legs", [])
	for i in legs.size():
		(legs[i] as Node3D).rotation.x = swing * (1.0 if i == 0 or i == 3 else -1.0)


func _add_flock(flock: Dictionary, life: Node3D) -> void:
	var holder := Node3D.new()
	holder.position = flock["centre"]
	add_child(holder)
	var birds: Array[Node3D] = []
	for i in flock["birds"]:
		var bird := Node3D.new()
		holder.add_child(bird)
		LowPoly.box(bird, Vector3(0.12, 0.1, 0.45), BIRD, Vector3.ZERO)  # body (child 0)
		for side in [-1.0, 1.0]:  # wings (children 1 and 2), hinged at the body
			var hinge := Node3D.new()
			bird.add_child(hinge)
			LowPoly.box(hinge, Vector3(0.5, 0.03, 0.2), BIRD, Vector3(side * 0.27, 0, 0))
		birds.append(bird)
	_flocks.append({"node": holder, "radius": flock["radius"], "birds": birds})
	life.register(holder, flock.get("level", 0))


## Little drops of water falling from the top of the fountain into the bowl.
func _fountain_spray() -> CPUParticles3D:
	var drops := CPUParticles3D.new()
	drops.name = "Spray"
	drops.amount = 40
	drops.lifetime = 0.9
	drops.direction = Vector3.UP
	drops.spread = 25.0
	drops.initial_velocity_min = 1.5
	drops.initial_velocity_max = 2.2
	var drop := SphereMesh.new()
	drop.radius = 0.04
	drop.height = 0.08
	drop.radial_segments = 4
	drop.rings = 2
	drop.material = LowPoly.material(Color(0.75, 0.9, 1.0))
	drops.mesh = drop
	return drops
