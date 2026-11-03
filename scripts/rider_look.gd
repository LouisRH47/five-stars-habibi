class_name RiderLook
## Dresses the rider in one of the 3 looks from the application
## (PRD "3 character presets"). All three ride the same; only the look changes.
##   0 Classic: cap, hoodie and a backpack
##   1 Sporty: helmet with stickers, sports top
##   2 Chill: bucket hat, sunglasses, shorts
## The rider is an animated Person (Session 29) with a "Helmet" that follows the head.
## make_rider() builds one; apply() dresses it. Used on the bike (Model/Rider), the
## walker, the start screen look cards and the clinic bed. The extra hats and bags of a
## look go in a "Look" node, so changing look removes the old ones.

const SKIN := Color(0.78, 0.58, 0.42, 1)
const HELMET_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)


## A new rider (a Person named "Model") wearing the Snackaroo helmet.
static func make_rider() -> Person:
	var rider := Person.new()
	rider.name = "Model"
	var helmet := rider.follow("Head")
	helmet.name = "Helmet"
	var r := PeopleLooks.head_size(rider) * 0.66
	LowPoly.sphere(helmet, r, r * 1.35, HELMET_COLOUR, rider.head_spot() + Vector3(0, r * 0.2, 0.01))
	PeopleLooks.shoes(rider, Color(0.95, 0.95, 0.95))  # white trainers
	return rider


## Changes `model` (a rider from make_rider()) to look number `look`.
static func apply(model: Node3D, look: int) -> void:
	var rider := model as Person
	var old := rider.get_node_or_null("Look")
	if old != null:
		old.free()
	var parts := Node3D.new()
	parts.name = "Look"
	rider.add_child(parts)
	var helmet := rider.get_node("Helmet") as Node3D
	var shell := helmet.get_child(0) as MeshInstance3D
	helmet.visible = true
	shell.material_override = null
	var head := rider.head_spot()
	var r := PeopleLooks.head_size(rider) * 0.66
	match look:
		0:  # Classic
			rider.paint({"skin": SKIN, "shirt": Color(0.32, 0.38, 0.48), "pants": Color(0.2, 0.25, 0.38)})
			helmet.visible = false
			PeopleLooks.cap(rider, Color(0.8, 0.15, 0.15), parts)
			PeopleLooks.backpack(rider, Color(0.15, 0.17, 0.2), parts)
		1:  # Sporty
			rider.paint({"skin": SKIN, "shirt": Color(0.75, 0.9, 0.2), "pants": Color(0.12, 0.12, 0.14)})
			shell.material_override = LowPoly.material(Color(0.95, 0.95, 0.97))
			var stickers := rider.follow("Head", parts)
			var colours := [Color(0.95, 0.3, 0.3), Color(0.2, 0.55, 0.95), Color(0.98, 0.78, 0.1)]
			var spots := [Vector3(-0.95, 0.35, 0.1), Vector3(0.9, 0.4, 0.25), Vector3(0.0, 0.85, 0.25)]
			for i in 3:
				LowPoly.box(stickers, Vector3.ONE * r * 0.35, colours[i], head + spots[i] * r)
		2:  # Chill
			rider.paint({"skin": SKIN, "shirt": Color(0.95, 0.6, 0.65), "pants": Color(0.2, 0.5, 0.55)})
			helmet.visible = false
			var hat := rider.follow("Head", parts)
			var sand := Color(0.9, 0.84, 0.65)
			LowPoly.cylinder(hat, r * 1.5, r * 1.5, 0.02, sand, head + Vector3(0, r * 0.55, 0))      # brim
			LowPoly.cylinder(hat, r * 0.8, r * 0.95, r * 0.6, sand, head + Vector3(0, r * 0.85, 0))   # top
			LowPoly.box(hat, Vector3(r * 1.6, r * 0.28, 0.03), Color(0.05, 0.05, 0.05), head + Vector3(0, r * 0.05, -r * 0.95))  # sunglasses
			for side in ["Left", "Right"]:  # bare legs under the shorts
				var shin := rider.follow(side + "Leg", parts)
				var knee := rider.spot(side + "Leg")
				var ankle := rider.spot(side + "Foot")
				var leg := LowPoly.cylinder(shin, 0.075, 0.06, knee.distance_to(ankle), SKIN, (knee + ankle) * 0.5)
				leg.basis = Basis(Quaternion(Vector3.UP, (knee - ankle).normalized()))
