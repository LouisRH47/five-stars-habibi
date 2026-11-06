class_name ParkedCarBatch
extends Node3D
## Session 79: draws hundreds of parked cars cheaply. Every ParkedCar keeps its own solid box
## (so the bike still bumps into it), but its look is one copy in a MultiMesh (a list of
## places that draws the same model many times in one go): one MultiMesh per car model per
## square of the map, so far-away squares are skipped and 300 cars cost a few dozen draws.
## ParkedCar calls ParkedCarBatch.for_parent(...).add(...) when it's placed.

const NODE_NAME := "ParkedCarBatch"
const META := "parked_car_batch"

## How many cars this batch draws (the smoke test checks it).
var count := 0

# Each car model's parts merged into one mesh, kept so it's only done once per model.
static var _merged: Dictionary = {}
# "model path|cell x|cell z" -> {scene, transforms}
var _cars: Dictionary = {}


## The batch for the cars under `parent` (made the first time it's asked for).
static func for_parent(parent: Node3D) -> ParkedCarBatch:
	if parent.has_meta(META):
		return parent.get_meta(META)
	var batch := ParkedCarBatch.new()
	batch.name = NODE_NAME
	parent.set_meta(META, batch)
	parent.add_child.call_deferred(batch)  # the parent may still be building its children
	return batch


## One car: its model, where it stands (in the parent's space) and its size (the solid box).
func add(scene: PackedScene, spot: Transform3D, size: Vector3) -> void:
	var cell := GameConfig.PARKED_CAR_BATCH_CELL
	var key := "%s|%d|%d" % [scene.resource_path, floori(spot.origin.x / cell), floori(spot.origin.z / cell)]
	if not _cars.has(key):
		_cars[key] = {"scene": scene, "transforms": []}
	var look: Array = _merged_model(scene)
	var box: AABB = look[0].get_aabb()
	# Scale the model so it's as long as the solid box and stands on the ground (like before).
	var scale := size.z / box.size.z if box.size.z > 0.01 else 1.0
	var fit := Transform3D(Basis.from_scale(Vector3.ONE * scale), Vector3(0, -box.position.y * scale, 0))
	_cars[key]["transforms"].append(spot * fit)
	count += 1


func _ready() -> void:
	for key: String in _cars:
		var group: Dictionary = _cars[key]
		var transforms: Array = group["transforms"]
		var many := MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_3D
		many.mesh = _merged_model(group["scene"])[0]
		many.instance_count = transforms.size()
		for i in transforms.size():
			many.set_instance_transform(i, transforms[i])
		var view := MultiMeshInstance3D.new()
		view.name = "Cars_%d" % get_child_count()
		view.multimesh = many
		# Headless runs (the tests) can't read copies back from a MultiMesh, so keep the list.
		view.set_meta("instance_transforms", transforms.duplicate())
		view.visibility_range_end = GameConfig.PARKED_CAR_DRAW_DISTANCE
		view.visibility_range_end_margin = 10.0
		add_child(view)
	_cars.clear()


## The model's meshes (body and wheels) joined into one mesh, with the model's own material.
static func _merged_model(scene: PackedScene) -> Array:
	if _merged.has(scene.resource_path):
		return _merged[scene.resource_path]
	var model: Node3D = scene.instantiate()
	var tool := SurfaceTool.new()
	var material: Material = null
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var spot := Transform3D()
		var node: Node = part
		while node != model:
			spot = (node as Node3D).transform * spot
			node = node.get_parent()
		for surface in part.mesh.get_surface_count():
			if material == null:
				material = part.get_active_material(surface)
			if String(part.name).begins_with("wheel"):
				# A parked car's wheels never turn, so a simple 8-sided wheel looks the same
				# and has a fifth of the corners (the car parks hold about 300 cars).
				tool.append_from(_simple_wheel(part.mesh, surface), 0, spot)
			else:
				tool.append_from(part.mesh, surface, spot)
	var mesh := tool.commit()
	if material != null:
		mesh.surface_set_material(0, material)
	model.free()
	_merged[scene.resource_path] = [mesh]
	return _merged[scene.resource_path]


## An 8-sided wheel the size of the model's wheel, coloured from the tyre's spot in the
## model's colour texture (the Kenney cars use one small colour chart for every part).
static func _simple_wheel(source: Mesh, surface: int) -> ArrayMesh:
	var box := source.get_aabb()
	var arrays := source.surface_get_arrays(surface)
	var uv: Vector2 = (arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array)[0]
	var centre := box.get_center()
	# Wheels turn on their thinnest side (x for the road wheels, z for a spare on the back).
	var turn := Basis() if box.size.x <= box.size.z else Basis(Vector3.UP, PI * 0.5)
	var size := turn.inverse() * box.size
	var radius := maxf(absf(size.y), absf(size.z)) * 0.5
	var half := absf(size.x) * 0.5
	# The hub's colour: the corner of the model's wheel nearest the middle of its flat side.
	var hub_uv := uv
	var best := INF
	var points := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for k in points.size():
		var off := turn.inverse() * (points[k] - centre)
		var score := Vector2(off.y, off.z).length() - absf(off.x) * 2.0
		if score < best:
			best = score
			hub_uv = (arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array)[k]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 8
	for i in SIDES:
		var a := TAU * i / SIDES
		var b := TAU * (i + 1) / SIDES
		var pa := Vector3(0, cos(a), sin(a)) * radius
		var pb := Vector3(0, cos(b), sin(b)) * radius
		var out := turn * (pa + pb).normalized()
		var corners := [pa + Vector3(-half, 0, 0), pb + Vector3(-half, 0, 0), pb + Vector3(half, 0, 0), pa + Vector3(half, 0, 0)]
		for k in 4:
			corners[k] = centre + turn * corners[k]
		tool.set_uv(uv)
		_face(tool, corners[0], corners[1], corners[2], out)  # the tyre
		_face(tool, corners[0], corners[2], corners[3], out)
		for side in [-1.0, 1.0]:  # the two flat sides: the tyre, then the lighter hub on top
			var facing := turn * Vector3(side, 0, 0)
			var hub := Vector3(side * half, 0, 0)
			tool.set_uv(uv)
			_face(tool, centre + turn * hub, centre + turn * (pa + hub), centre + turn * (pb + hub), facing)
			var cap := Vector3(side * (half + 0.01), 0, 0)
			tool.set_uv(hub_uv)
			_face(tool, centre + turn * cap, centre + turn * (pa * 0.6 + cap), centre + turn * (pb * 0.6 + cap), facing)
	tool.index()  # the car body is indexed, so the wheel must be too or it won't be drawn
	return tool.commit()


## One triangle whose front faces `normal`. Godot shows a triangle's front when its corners go
## round clockwise, so the order is flipped when needed.
static func _face(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var corners := [a, b, c] if (b - a).cross(c - a).dot(normal) < 0.0 else [a, c, b]
	for corner: Vector3 in corners:
		tool.set_normal(normal)
		tool.add_vertex(corner)
