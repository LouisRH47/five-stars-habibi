class_name EndHouses
extends Node3D
## Session 65: big end houses. Where a row of homes stops about 10 m short of the next
## road, a larger home from the same house kit (VillaBuilder) fills the gap at the row's
## end (data: END_HOUSES, worked out by tools/build_wahat_data.py). They're scenery: no
## address, no door number, and all 500 homes keep their numbers. Each cluster's end houses
## are joined into one near mesh and one far mesh (like HousingRows), so they're cheap.

const TALLER := 1.12  # the end houses are a bit taller than the others too

var count := 0


static func build(parent: Node3D, map: Dictionary) -> EndHouses:
	var holder := EndHouses.new()
	holder.name = "EndHouses"
	parent.add_child(holder)
	var groups := {}
	for place: Dictionary in map.get("END_HOUSES", []):
		var id: String = place["cluster"]
		groups[id] = groups.get(id, []) + [place]
	for id: String in groups:
		holder._cluster(id, groups[id])
	return holder


func _cluster(id: String, places: Array) -> void:
	var near := SurfaceTool.new()
	near.begin(Mesh.PRIMITIVE_TRIANGLES)
	var far := SurfaceTool.new()
	far.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stretch := Transform3D(Basis.from_scale(Vector3(1, TALLER, 1)), Vector3.ZERO)
	for place: Dictionary in places:
		var size: Vector3 = place["size"]
		var body := VillaBuilder.build(place, size)
		body.name = "EndHouse_%s_%d" % [id, count]
		var view: MeshInstance3D = body.get_node("House")
		near.append_from(view.mesh, 0, body.transform * stretch * view.transform)
		body.remove_child(view)
		view.free()
		var number := body.get_node_or_null("Number")
		if number != null:  # no address: the plate over the door stays blank
			body.remove_child(number)
			number.free()
		var outline := VillaBuilder.build_far(place, size)
		far.append_from(outline.mesh, 0, body.transform * stretch)
		outline.free()
		body.set_meta("end_house", true)
		add_child(body)
		count += 1
	near.index()
	far.index()
	var near_view := MeshInstance3D.new()
	near_view.name = "EndHouses_%s" % id
	near_view.mesh = near.commit()
	near_view.material_override = MeshKit.material()
	near_view.visibility_range_end = GameConfig.HOUSING_DETAIL_DISTANCE
	add_child(near_view)
	var far_view := MeshInstance3D.new()
	far_view.name = "FarEndHouses_%s" % id
	far_view.mesh = far.commit()
	far_view.material_override = MeshKit.material()
	far_view.visibility_range_begin = GameConfig.HOUSING_DETAIL_DISTANCE
	add_child(far_view)
