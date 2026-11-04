class_name KitProps
extends RefCounted
## Puts models from the free CC0 packs (assets/kits/, Session 56) into the world.
## Which packs there are, and the size that turns each one into metres: data/kit_catalogue.gd.
##
## KitProps.place(parent, "kaykit_restaurant/stove_multi", Vector3(2, 0, 5), 90.0)
##   pos     where it goes. pos.y is the floor (or the ceiling for "hang").
##   facing  degrees, like the data lists: 0 = the model's front looks along +Z.
##   scale   extra size on top of the pack's own size (1.0 = real size).
##   snap    how it sits (see SNAPS below).
## Every placed model is in the group "kit_prop" and has metadata kit_id, kit_snap and
## kit_snap_y (the height its bottom, top or origin should be at), so tests can check it.
## Loaded models are kept (cached), so placing 300 chairs loads the chair file once.

## How a model can sit:
##   "floor"   its bottom sits on pos.y, centred on pos
##   "counter" its bottom sits on a counter top: pos.y + GameConfig.KIT_COUNTER_HEIGHT
##   "wall"    bottom on pos.y, and its back touches pos (the wall face); the front points
##             along facing, out of the wall
##   "hang"    its top touches pos.y (a ceiling)
##   "origin"  the model's own origin goes on pos (crops and trees with roots under ground)
const SNAPS := ["floor", "counter", "wall", "hang", "origin"]
const GROUP := "kit_prop"

static var _scenes := {}   # id -> PackedScene (or null if the file is missing)
static var _bounds := {}   # id -> AABB of the model in its own space, before scaling


## Places one model and returns its holder node (or null if the model doesn't exist).
static func place(parent: Node, id: String, pos: Vector3, facing := 0.0, scale := 1.0,
		snap := "") -> Node3D:
	var packed := scene(id)
	if packed == null:
		push_warning("KitProps: no model called %s" % id)
		return null
	if snap == "":
		snap = default_snap(id)
	var holder := Node3D.new()
	holder.name = id.get_file()
	holder.position = pos
	holder.rotation.y = deg_to_rad(facing)
	var model := packed.instantiate() as Node3D
	model.name = "Model"
	_fit(model, id, scale, snap)
	holder.add_child(model)
	var snap_y := pos.y + (GameConfig.KIT_COUNTER_HEIGHT if snap == "counter" else 0.0)
	holder.position.y = snap_y
	holder.add_to_group(GROUP)
	holder.set_meta("kit_id", id)
	holder.set_meta("kit_snap", snap)
	holder.set_meta("kit_snap_y", snap_y)
	parent.add_child(holder)
	return holder


## Many copies of one model, drawn together: one MultiMesh per part of the model, so
## 300 chairs in a room cost a few draw calls instead of 300. Only for things that never
## move (no animation). spots: Vector3 positions; facings: degrees (same count, or empty).
static func place_many(parent: Node, id: String, spots: Array, facings: Array = [],
		scale := 1.0, snap := "") -> Node3D:
	var packed := scene(id)
	if packed == null or spots.is_empty():
		return null
	if snap == "":
		snap = default_snap(id)
	var model := packed.instantiate() as Node3D
	_fit(model, id, scale, snap)
	var group := Node3D.new()
	group.name = "%s_x%d" % [id.get_file(), spots.size()]
	group.add_to_group(GROUP + "_many")
	group.set_meta("kit_id", id)
	group.set_meta("kit_snap", snap)
	var lift := GameConfig.KIT_COUNTER_HEIGHT if snap == "counter" else 0.0
	for view: MeshInstance3D in _meshes(model):
		if view.skin != null:
			continue  # animated parts can't go in a MultiMesh
		var part := model.transform * _transform_to(view, model)
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = view.mesh
		multi.instance_count = spots.size()
		for i in spots.size():
			var turn := deg_to_rad(float(facings[i])) if i < facings.size() else 0.0
			var spot: Vector3 = spots[i] + Vector3(0, lift, 0)
			multi.set_instance_transform(i, Transform3D(Basis(Vector3.UP, turn), spot) * part)
		var drawn := MultiMeshInstance3D.new()
		drawn.name = view.name
		drawn.multimesh = multi
		if view.material_override != null:
			drawn.material_override = view.material_override
		group.add_child(drawn)
	model.free()
	parent.add_child(group)
	return group


## The loaded model file for an id like "kenney_food/pizza" (loaded once, then cached).
static func scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		var path := file_of(id)
		_scenes[id] = load(path) as PackedScene if path != "" else null
	return _scenes[id]


## The file for an id, or "" if there is none.
static func file_of(id: String) -> String:
	var pack := id.get_slice("/", 0)
	var info: Dictionary = KitCatalogue.PACKS.get(pack, {})
	for ext in [info.get("ext", ".glb"), ".glb", ".gltf"]:
		var path := "res://assets/kits/%s%s" % [id, ext]
		if ResourceLoader.exists(path):
			return path
	return ""


## How many metres one unit of this model is (pack size times the model's own fix).
static func unit_scale(id: String) -> float:
	var pack: Dictionary = KitCatalogue.PACKS.get(id.get_slice("/", 0), {})
	var entry: Dictionary = KitCatalogue.MODELS.get(id, {})
	return float(pack.get("scale", 1.0)) * float(entry.get("scale", 1.0))


## The snap a model uses when none is given: from the catalogue, else "floor".
static func default_snap(id: String) -> String:
	var entry: Dictionary = KitCatalogue.MODELS.get(id, {})
	var pack: Dictionary = KitCatalogue.PACKS.get(id.get_slice("/", 0), {})
	return entry.get("snap", pack.get("snap", "floor"))


## The model's box in metres at scale 1 (after the pack's turn), e.g. size.y is its height.
static func size_of(id: String) -> Vector3:
	return _turned_bounds(id).size * unit_scale(id)


## The box around every mesh of the model, in its own space before scaling (cached).
static func bounds(id: String) -> AABB:
	if not _bounds.has(id):
		var packed := scene(id)
		if packed == null:
			return AABB()
		var model := packed.instantiate() as Node3D
		_bounds[id] = _box(model, model)
		model.free()
	return _bounds[id]


## Scales the model to metres, turns it to face +Z and moves it so it sits the snap way.
static func _fit(model: Node3D, id: String, scale: float, snap: String) -> void:
	var size := unit_scale(id) * scale
	var turn := deg_to_rad(float(KitCatalogue.PACKS.get(id.get_slice("/", 0), {}).get("turn", 0.0)))
	var box := _turned_bounds(id)
	model.rotation.y = turn
	model.scale = Vector3.ONE * size
	var centre := box.get_center()
	match snap:
		"origin":
			model.position = Vector3.ZERO
		"hang":
			model.position = Vector3(-centre.x, -box.end.y, -centre.z) * size
		"wall":
			model.position = Vector3(-centre.x, -box.position.y, -box.position.z) * size
		_:
			model.position = Vector3(-centre.x, -box.position.y, -centre.z) * size


## The model's box after the pack's turn (still before scaling).
static func _turned_bounds(id: String) -> AABB:
	var turn := deg_to_rad(float(KitCatalogue.PACKS.get(id.get_slice("/", 0), {}).get("turn", 0.0)))
	return Transform3D(Basis(Vector3.UP, turn), Vector3.ZERO) * bounds(id)


## Every mesh under root, in root's own space (works before root is in the scene tree).
static func _box(root: Node3D, top: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for view: MeshInstance3D in _meshes(root):
		var part: AABB = _transform_to(view, top) * view.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


static func _meshes(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var view := node as MeshInstance3D
		if view.mesh != null:
			found.append(view)
	return found


## The transform from a node to one of its parents (top), without needing the scene tree.
static func _transform_to(node: Node3D, top: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != top:
		if current is Node3D:
			result = (current as Node3D).transform * result
		current = current.get_parent()
	return result
