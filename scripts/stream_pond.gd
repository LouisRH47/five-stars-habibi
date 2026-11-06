class_name StreamPond
extends RefCounted
## Session 81: the small ponds at the ends of the stream (STREAM "ponds" in the data). The
## stream used to run under the gym; now it ends in a pond before the gym and starts again
## from a little spring pond after the gym's lap pool. Each pond is a slightly wobbly round
## pool of water (the same water look as the stream) on a muddy bank, with a ring of stones
## round the edge, a few reeds and lily pads. Flat and not solid: you can ride over it, like
## the stream. WahatBuilder makes them.
## Session 91: a pond can also have more "reeds" clumps, a wooden "deck" with two benches
## (scripts/pond_deck.gd; no stones or reeds where the deck is) and "ducks" paddling about
## (scripts/pond_ducks.gd). The big pond by the C Institute has all three.

const BANK := Color(0.42, 0.36, 0.25)
const STONES := [Color(0.62, 0.6, 0.57), Color(0.76, 0.69, 0.56), Color(0.5, 0.49, 0.47), Color(0.68, 0.66, 0.62)]
const REED := Color(0.35, 0.55, 0.22)
const REED_TOP := Color(0.45, 0.3, 0.16)
const LILY := Color(0.25, 0.55, 0.25)
const WATER_TOP := 0.05  # just above the stream's top (0.04), so they don't flicker
const BANK_TOP := 0.03


## Builds every pond in the stream data under `parent`. Returns the holder ("StreamPonds").
static func build(parent: Node3D, stream: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "StreamPonds"
	parent.add_child(holder)
	var ponds: Array = stream.get("ponds", [])
	for i in ponds.size():
		var pond: Dictionary = ponds[i]
		_pond(holder, pond, i, stream)
		if pond.has("deck"):
			PondDeck.build(holder, pond, i)
		if pond.get("ducks", 0) > 0:
			PondDucks.build(holder, pond, i)
	return holder


## How far the pond's edge is from its middle in direction `angle` (a little wobbly).
static func edge(radius: float, angle: float, seed: int) -> float:
	return radius * (1.0 + 0.1 * sin(angle * 3.0 + seed) + 0.05 * cos(angle * 5.0 + seed * 2.0))


## True if (x, z) is on the stream itself (where it runs into or out of a pond).
static func on_stream(stream: Dictionary, x: float, z: float) -> bool:
	for gap: Vector2 in stream.get("gaps", []):
		if x > gap.x and x < gap.y:
			return false
	var water_z: float = stream["z"] + sin(x * 0.06) * 3.0  # the same wiggle as WahatBuilder
	return absf(z - water_z) < stream["width"] * 0.5 + 0.3


## True if (x, z) is on (or right next to) the pond's wooden deck.
static func on_deck(pond: Dictionary, x: float, z: float) -> bool:
	if not pond.has("deck"):
		return false
	var deck: Dictionary = pond["deck"]
	var size: Vector2 = deck["size"]
	return Rect2(deck["centre"] - size * 0.5, size).grow(0.4).has_point(Vector2(x, z))


static func _pond(holder: Node3D, pond: Dictionary, seed: int, stream: Dictionary) -> void:
	var centre: Vector2 = pond["centre"]
	var radius: float = pond["radius"]
	var middle := Vector3(centre.x, 0, centre.y)
	var bank := _disc(radius + 0.7, BANK_TOP, seed)
	bank.material_override = LowPoly.material(BANK)
	bank.name = "PondBank_%d" % seed
	bank.position = middle
	holder.add_child(bank)
	var water := _disc(radius, WATER_TOP, seed)
	water.material_override = WaterLook.pond()
	water.name = "PondWater_%d" % seed
	water.position = middle
	holder.add_child(water)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8100 + seed
	var kit := MeshKit.new()
	# Stones all round the edge, half in the water, with a few bigger ones behind.
	var count := int(TAU * radius / GameConfig.POND_STONE_GAP)
	var stones := 0
	var reeds := 0
	for k in count:
		var a := TAU * k / count + rng.randf_range(-0.05, 0.05)
		var r := edge(radius, a, seed) + rng.randf_range(0.0, 0.2)
		var size := rng.randf_range(0.2, 0.34)
		if on_stream(stream, centre.x + cos(a) * r, centre.y + sin(a) * r):
			continue  # leave the way open where the stream flows in or out
		if on_deck(pond, centre.x + cos(a) * r, centre.y + sin(a) * r):
			continue  # Session 91: the deck sits here
		kit.ball(size, STONES[rng.randi() % STONES.size()], Vector3(cos(a) * r, size * 0.25, sin(a) * r), 0.55)
		stones += 1
		if k % 3 == 0:
			var big := rng.randf_range(0.3, 0.45)
			var out := r + size + big * 0.6
			kit.ball(big, STONES[rng.randi() % STONES.size()], Vector3(cos(a) * out, big * 0.3, sin(a) * out), 0.6)
	# Clumps of reeds at the edge, and lily pads floating on the water.
	var clumps: int = pond.get("reeds", 4)
	for k in clumps:
		var a := TAU * (k + 0.3) / clumps + seed
		var r := edge(radius, a, seed) - 0.3
		if on_deck(pond, centre.x + cos(a) * r, centre.y + sin(a) * r) or (pond.has("reeds") and on_stream(stream, centre.x + cos(a) * r, centre.y + sin(a) * r)):
			continue
		for j in 6:
			var spot := Vector3(cos(a) * r + rng.randf_range(-0.35, 0.35), 0, sin(a) * r + rng.randf_range(-0.35, 0.35))
			var tall := rng.randf_range(0.6, 1.1)
			kit.cylinder(0.008, 0.025, tall, REED, spot + Vector3(0, tall * 0.5, 0), Basis(), 4)
			reeds += 1
			if j % 2 == 0:
				kit.cylinder(0.03, 0.03, 0.14, REED_TOP, spot + Vector3(0, tall - 0.12, 0), Basis(), 4)
	for k in 5:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.3, 0.75) * radius
		var pad := rng.randf_range(0.18, 0.3)
		kit.cylinder(pad, pad, 0.01, LILY, Vector3(cos(a) * r, WATER_TOP + 0.008, sin(a) * r), Basis(), 7)
	var look := kit.finish("PondStones_%d" % seed)
	look.set_meta("stones", stones)  # Session 91: the tests count them
	look.set_meta("reeds", reeds)
	look.position = middle
	holder.add_child(look)


## A flat wobbly disc whose top is at `top` (a fan of triangles round the middle).
static func _disc(radius: float, top: float, seed: int) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	const SIDES := 28
	for k in SIDES:
		var a := TAU * k / SIDES
		var b := TAU * (k + 1) / SIDES
		tool.add_vertex(Vector3(0, top, 0))
		tool.add_vertex(Vector3(cos(a), 0, sin(a)) * edge(radius, a, seed) + Vector3(0, top, 0))
		tool.add_vertex(Vector3(cos(b), 0, sin(b)) * edge(radius, b, seed) + Vector3(0, top, 0))
	var view := MeshInstance3D.new()
	view.mesh = tool.commit()
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return view
