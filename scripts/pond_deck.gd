class_name PondDeck
extends RefCounted
## Session 91: a small wooden deck at the edge of a pond (the big pond by the C Institute).
## It starts on the grass and reaches out over the water on little posts, with two benches
## on it facing the water and a few flat stepping stones leading up to it from the spine
## road's crossing. The deck is solid with a gentle slope at the land end, so you can
## walk or ride onto it. The pond data says where it goes: "deck": {"centre", "size"}.

const PLANK := Color(0.62, 0.45, 0.28)
const PLANK_DARK := Color(0.5, 0.35, 0.21)
const POST := Color(0.36, 0.25, 0.15)
const STEP_STONE := Color(0.74, 0.71, 0.66)


## Builds the deck for `pond` under `holder`. Returns the deck (a StaticBody3D).
static func build(holder: Node3D, pond: Dictionary, seed: int) -> StaticBody3D:
	var spec: Dictionary = pond["deck"]
	var centre: Vector2 = spec["centre"]
	var size: Vector2 = spec["size"]
	var top: float = GameConfig.POND_DECK_TOP
	var body := StaticBody3D.new()
	body.name = "PondDeck_%d" % seed
	body.position = Vector3(centre.x, 0, centre.y)
	holder.add_child(body)
	# Which way the water is: the deck's far end points at the pond's middle.
	var to_water := (pond["centre"] as Vector2 - centre)
	var out := 1.0 if to_water.y > 0.0 else -1.0  # the deck runs along z
	# Planks across the deck, with small gaps, on two long beams.
	var planks := int(size.y / 0.3)
	for i in planks:
		var z := -size.y * 0.5 + (i + 0.5) * size.y / planks
		LowPoly.box(body, Vector3(size.x, 0.05, size.y / planks - 0.03), PLANK if i % 2 == 0 else PLANK_DARK,
				Vector3(0, top - 0.025, z))
	for x: float in [-size.x * 0.5 + 0.2, size.x * 0.5 - 0.2]:
		LowPoly.box(body, Vector3(0.14, 0.1, size.y), POST, Vector3(x, top - 0.1, 0))
		for z: float in [-size.y * 0.35, size.y * 0.35]:
			LowPoly.cylinder(body, 0.07, 0.07, top + 0.08, POST, Vector3(x, (top - 0.28) * 0.5, z))
	# A low wooden edge rail along the water end, so it looks finished.
	LowPoly.box(body, Vector3(size.x, 0.08, 0.1), POST, Vector3(0, top + 0.04, out * (size.y * 0.5 - 0.05)))
	# Solid: a gentle slope up from the grass at the land end, then flat.
	var shape := ConvexPolygonShape3D.new()
	var land := -out * size.y * 0.5
	var ramp := land + out * 0.6
	var far := out * size.y * 0.5
	var points := PackedVector3Array()
	for x: float in [-size.x * 0.5, size.x * 0.5]:
		points.append_array([Vector3(x, 0, land), Vector3(x, top, ramp), Vector3(x, top, far), Vector3(x, 0, far)])
	shape.points = points
	var solid := CollisionShape3D.new()
	solid.shape = shape
	body.add_child(solid)
	# Two benches on the deck, facing the water.
	for side: float in [-1.0, 1.0]:
		var bench := Props.bench(body, Vector3(side * (size.x * 0.25 - 0.05), top, out * 0.35), 0.0 if out > 0.0 else 180.0)
		bench.name = "DeckBench%d" % (0 if side < 0.0 else 1)
	# Flat stepping stones from the deck back towards the spine road.
	var stones := MeshKit.new()
	var z := land - out * 0.7
	for i in GameConfig.POND_DECK_STEPPING_STONES:
		stones.cylinder(0.32, 0.36, 0.04, STEP_STONE.darkened(0.04 * (i % 2)),
				Vector3(0.25 * sin(i * 1.7), 0.02, z), Basis(), 7)
		z -= out * 0.85
	var path := stones.finish("SteppingStones")
	body.add_child(path)
	body.set_meta("benches", 2)
	return body
