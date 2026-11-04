class_name HousingRows
extends Node3D
## Session 36: one detailed mesh and one distant silhouette per joined double row.
## Individual homes retain their stable name, collision and readable door number.
## Their many visible parts are merged into row meshes instead of 500 draw submissions.

var home_count := 0
var row_count := 0
var near_meshes: Array[MeshInstance3D] = []
var far_meshes: Array[MeshInstance3D] = []


## Session 53: homes built ahead of time by the loading screen (scripts/loader.gd), one row
## per frame, so the game doesn't freeze. PlaceBuilder takes it if it matches its homes.
static var prebuilt: HousingRows = null

var _pending: Array = []        # [row id, homes] still to build
var _villa_size := Vector3.ONE


static func build(homes: Array, villa_size: Vector3) -> HousingRows:
	var result := begin(homes, villa_size)
	while not result.build_next():
		pass
	return result


## Groups the homes into rows without building anything yet. Call build_next() until it
## returns true.
static func begin(homes: Array, villa_size: Vector3) -> HousingRows:
	var result := HousingRows.new()
	result.name = "HousingRows"
	result._villa_size = villa_size
	var groups := {}
	for home: Dictionary in homes:
		if home.get("kind", "") == "spot":
			continue
		var row: String = str(home.get("row", "%s_Row" % home.get("cluster", "Homes")))
		if not groups.has(row):
			groups[row] = []
		groups[row].append(home)
	for row: String in groups:
		result._pending.append([row, groups[row]])
	result._finish_meta()
	return result


## Builds the next row. Returns true when every row is built.
func build_next() -> bool:
	if not _pending.is_empty():
		var next: Array = _pending.pop_front()
		_build_row(next[0], next[1], _villa_size)
		_finish_meta()
	return _pending.is_empty()


## How many rows are still waiting to be built.
func rows_left() -> int:
	return _pending.size()


## How many homes the finished build will have (counted before building).
static func homes_in(homes: Array) -> int:
	var count := 0
	for home: Dictionary in homes:
		if home.get("kind", "") != "spot":
			count += 1
	return count


func _finish_meta() -> void:
	set_meta("home_count", home_count)
	set_meta("row_count", row_count)


func _build_row(row_id: String, homes: Array, villa_size: Vector3) -> void:
	var row := Node3D.new()
	row.name = row_id
	var centre := Vector3.ZERO
	for home: Dictionary in homes:
		centre += home["position"]
	centre /= homes.size()
	row.position = centre
	add_child(row)
	var detailed := SurfaceTool.new()
	detailed.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distant := SurfaceTool.new()
	distant.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts := 0
	var kinds := {}
	for home: Dictionary in homes:
		var size: Vector3 = home.get("size", villa_size)
		var body := VillaBuilder.build(home, size)
		body.position -= centre
		row.add_child(body)
		var view: MeshInstance3D = body.get_node("House")
		detailed.append_from(view.mesh, 0, body.transform * view.transform)
		parts += int(body.get_meta("parts"))
		body.remove_child(view)
		view.free()
		var far := VillaBuilder.build_far(home, size)
		distant.append_from(far.mesh, 0, body.transform)
		far.free()
		body.set_meta("row", row_id)
		body.set_meta("batched", true)
		var kind: String = str(home.get("kind", "courtyard"))
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		home_count += 1
	detailed.index()
	distant.index()
	var near := MeshInstance3D.new()
	near.name = "JoinedHomes"
	near.mesh = detailed.commit()
	near.material_override = MeshKit.material()
	near.visibility_range_end = GameConfig.HOUSING_DETAIL_DISTANCE
	row.add_child(near)
	near_meshes.append(near)
	var far := MeshInstance3D.new()
	far.name = "DistantHomes"
	far.mesh = distant.commit()
	far.material_override = MeshKit.material()
	far.visibility_range_begin = GameConfig.HOUSING_DETAIL_DISTANCE
	row.add_child(far)
	far_meshes.append(far)
	row.set_meta("home_count", homes.size())
	row.set_meta("kind_counts", kinds)
	row.set_meta("detailed_parts", parts)
	row_count += 1
