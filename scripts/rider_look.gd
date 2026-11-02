class_name RiderLook
## Dresses the rider on the bike in one of the 3 looks from the application
## (PRD "3 character presets"). All three ride the same; only the look changes.
##   0 Classic: cap, hoodie and a backpack
##   1 Sporty: helmet with stickers, sports top
##   2 Chill: bucket hat, sunglasses, shorts
## The bike (scripts/bike.gd) calls apply() when it starts, with GameState.rider_look.
## The rider faces -Z (the way the bike rides); the back is +Z.

const SKIN := Color(0.78, 0.58, 0.42, 1)
const HEAD_SPOT := Vector3(0, 1.78, -0.2)  # where the helmet sits on the bike model


## Changes the rider on `model` (the bike's Model node) to look number `look`.
static func apply(model: Node3D, look: int) -> void:
	var old := model.get_node_or_null("Look")
	if old != null:
		old.free()
	var parts := Node3D.new()
	parts.name = "Look"
	model.add_child(parts)
	var body := model.get_node("RiderBody") as MeshInstance3D
	var helmet := model.get_node("Helmet") as MeshInstance3D
	var legs: Array[MeshInstance3D] = [model.get_node("LegLeft"), model.get_node("LegRight")]
	helmet.visible = true
	_paint(body, null)
	_paint(helmet, null)
	for leg in legs:
		_paint(leg, null)
	match look:
		0:  # Classic
			_paint(body, Color(0.32, 0.38, 0.48, 1))  # grey-blue hoodie
			helmet.visible = false
			LowPoly.sphere(parts, 0.16, 0.32, SKIN, HEAD_SPOT)
			LowPoly.sphere(parts, 0.17, 0.2, Color(0.8, 0.15, 0.15, 1), HEAD_SPOT + Vector3(0, 0.08, 0))  # cap
			LowPoly.box(parts, Vector3(0.24, 0.03, 0.18), Color(0.8, 0.15, 0.15, 1), HEAD_SPOT + Vector3(0, 0.07, -0.2))  # peak
			LowPoly.box(parts, Vector3(0.34, 0.4, 0.16), Color(0.15, 0.17, 0.2, 1), Vector3(0, 1.38, 0.28))  # backpack
		1:  # Sporty
			_paint(body, Color(0.75, 0.9, 0.2, 1))  # bright sports top
			_paint(helmet, Color(0.95, 0.95, 0.97, 1))
			var stickers := [Color(0.95, 0.3, 0.3, 1), Color(0.2, 0.55, 0.95, 1), Color(0.98, 0.78, 0.1, 1)]
			var spots := [Vector3(-0.12, 0.06, -0.06), Vector3(0.11, 0.08, 0.02), Vector3(0.0, 0.14, 0.05)]
			for i in 3:
				LowPoly.box(parts, Vector3(0.06, 0.06, 0.06), stickers[i], HEAD_SPOT + spots[i])
		2:  # Chill
			_paint(body, Color(0.95, 0.6, 0.65, 1))  # pink holiday shirt
			helmet.visible = false
			LowPoly.sphere(parts, 0.16, 0.32, SKIN, HEAD_SPOT)
			LowPoly.cylinder(parts, 0.26, 0.26, 0.03, Color(0.9, 0.84, 0.65, 1), HEAD_SPOT + Vector3(0, 0.08, 0))  # hat brim
			LowPoly.cylinder(parts, 0.13, 0.16, 0.14, Color(0.9, 0.84, 0.65, 1), HEAD_SPOT + Vector3(0, 0.15, 0))  # hat top
			LowPoly.box(parts, Vector3(0.26, 0.06, 0.04), Color(0.05, 0.05, 0.05, 1), HEAD_SPOT + Vector3(0, 0.0, -0.16))  # sunglasses
			for leg in legs:
				_paint(leg, SKIN)  # bare legs...
				LowPoly.box(parts, Vector3(0.2, 0.22, 0.2), Color(0.2, 0.5, 0.55, 1), leg.position + Vector3(0, 0.22, 0))  # ...and shorts


## Gives one part its own colour (null = back to the colour from the bike scene).
static func _paint(part: MeshInstance3D, colour: Variant) -> void:
	part.material_override = null if colour == null else LowPoly.material(colour)
