class_name Wardrobe
extends RefCounted
## The same saved appearance is applied to bike, walker, delivery/clinic and shop previews.


static func apply(person: Person, equipped: Dictionary) -> void:
	var clothes := Node3D.new()
	clothes.name = "Wardrobe"
	var old := person.get_node_or_null("Wardrobe")
	if old != null:
		old.free()
	person.add_child(clothes)
	if equipped.has("head"):
		var helmet := person.get_node_or_null("Helmet") as Node3D
		if helmet != null:
			helmet.visible = false
		var look := person.get_node_or_null("Look")
		if look != null:
			for part in look.get_children():
				if part.get_meta("bone", -1) == person.skeleton.find_bone("Head"):
					part.free()
	if equipped.has("bags"):
		var look := person.get_node_or_null("Look")
		if look != null:
			for part in look.get_children():
				if part.get_meta("bone", -1) == person.skeleton.find_bone("Spine2"):
					part.free()
	for slot: String in equipped:
		var item := GearCatalog.find(str(equipped[slot]))
		if item.is_empty():
			continue
		var colour: Color = item["colour"]
		match slot:
			"head":
				if item["category"] == "caps":
					PeopleLooks.cap(person, colour, clothes)
				else:
					var head := person.follow("Head", clothes)
					var r := PeopleLooks.head_size(person) * 0.66
					LowPoly.sphere(head, r, r, colour, person.head_spot() + Vector3(0, r * 0.45, 0))
					for x in [-0.6, 0.0, 0.6]:
						LowPoly.box(head, Vector3(r * 0.12, r * 0.12, r * 0.9), Color(0.1, 0.12, 0.13),
								person.head_spot() + Vector3(r * x, r * 0.93, 0))
			"glasses":
				var head := person.follow("Head", clothes)
				var r := PeopleLooks.head_size(person) * 0.6
				LowPoly.box(head, Vector3(r * 1.7, r * 0.28, 0.04), colour.darkened(0.7),
						person.head_spot() + Vector3(0, 0, -r * 0.92))
			"tops":
				person.repaint({"shirt": colour})
			"shoes":
				for side in ["LeftFoot", "RightFoot"]:
					var foot := person.get_node_or_null(side)
					if foot != null:
						for mesh: MeshInstance3D in foot.find_children("*", "MeshInstance3D", true, false):
							mesh.material_override = LowPoly.material(colour)
			"bags":
				PeopleLooks.backpack(person, colour, clothes)


static func apply_bike(model: Node3D, equipped: Dictionary) -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var slot := "paint" if mesh.get_meta("bike_paint", false) else ("box" if mesh.name == "DeliveryBox" else "")
		if slot == "":
			continue
		var item := GearCatalog.find(str(equipped.get(slot, "")))
		var colour: Color = item.get("colour", BikeModel.FRAME if slot == "paint" else Companies.current().get("colour", BikeModel.BOX))
		mesh.material_override = LowPoly.material(colour)
