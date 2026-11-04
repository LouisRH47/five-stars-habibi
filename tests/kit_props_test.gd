extends SceneTree
## Session 56: the free asset packs (assets/kits/) and scripts/kit_props.gd.
## Checks: every model in data/kit_catalogue.gd loads, comes out a sensible size in metres,
## and sits the right way (bottom on the floor, on the counter, top on the ceiling...);
## place_many makes one MultiMesh per part; the cache loads each file once; the animation
## library has its clips.
## Run: godot --path . --headless -s tests/kit_props_test.gd
## Add "-- --list" to print the size of EVERY model in assets/kits/ (to pick new ones).

const TOLERANCE := 0.35       # a model may be this much taller or shorter than "h"...
const SLACK := 0.03           # ...plus 3 cm, for tiny things
const SNAP_CM := 0.02         # bottoms must be within 2 cm of where they should sit
const UAL := "res://assets/kits/quaternius_ual/AnimationLibrary_Godot_Standard.gltf"

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if "--list" in OS.get_cmdline_user_args():
		_list_all()
		quit(0)
		return
	var world := Node3D.new()
	root.add_child(world)
	_check_catalogue(world)
	_check_snaps(world)
	_check_many(world)
	_check_cache()
	_check_animations()
	_check_licences()
	print("RESULT: %s" % ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)


## Every catalogue model loads, has a sensible height, and sits on the floor.
func _check_catalogue(world: Node3D) -> void:
	var bad := 0
	var x := 0.0
	for id: String in KitCatalogue.MODELS:
		var entry: Dictionary = KitCatalogue.MODELS[id]
		var prop := KitProps.place(world, id, Vector3(x, 0, 0), 30.0)
		x += 5.0
		if prop == null:
			_fail("%s doesn't load" % id)
			bad += 1
			continue
		var box := _world_box(prop)
		var want: float = entry["h"]
		var height := box.size.y
		if absf(height - want) > want * TOLERANCE + SLACK:
			_fail("%s is %.2f m tall, expected about %.2f m" % [id, height, want])
			bad += 1
		if not _sits_right(prop, box):
			bad += 1
	if bad == 0:
		_pass("%d catalogue models load, are a sensible size and sit right" % KitCatalogue.MODELS.size())


## The same model with each snap mode lands where it should.
func _check_snaps(world: Node3D) -> void:
	var id := "kaykit_restaurant/pot_A"
	var ok := true
	for snap: String in KitProps.SNAPS:
		var prop := KitProps.place(world, id, Vector3(0, 2.0, 50), 90.0, 1.0, snap)
		if not _sits_right(prop, _world_box(prop)):
			ok = false
	# "wall": the back touches the wall point, the front points along facing (+X at 90).
	var shelf := KitProps.place(world, "kaykit_furniture/shelf_B_large", Vector3(10, 1.5, 60), 90.0, 1.0, "wall")
	var box := _world_box(shelf)
	if absf(box.position.x - 10.0) > SNAP_CM:
		_fail("wall shelf back is at x %.3f, should touch the wall at 10" % box.position.x)
		ok = false
	if prop_missing_meta(shelf):
		ok = false
	if ok:
		_pass("floor, counter, wall, hang and origin snaps put the model in the right place")


func prop_missing_meta(prop: Node3D) -> bool:
	for key in ["kit_id", "kit_snap", "kit_snap_y"]:
		if not prop.has_meta(key):
			_fail("%s has no %s metadata" % [prop.name, key])
			return true
	if not prop.is_in_group(KitProps.GROUP):
		_fail("%s isn't in the kit_prop group" % prop.name)
		return true
	return false


## 50 chairs in one go: one MultiMesh per part, 50 copies each, standing on the floor.
func _check_many(world: Node3D) -> void:
	var id := "kaykit_restaurant/chair_A"
	var spots := []
	var facings := []
	for i in 50:
		spots.append(Vector3(i % 10 * 1.2, 0, 100 + i / 10 * 1.2))
		facings.append(i * 15.0)
	var group := KitProps.place_many(world, id, spots, facings)
	var parts := group.get_children()
	var model: Node = KitProps.scene(id).instantiate()
	var expected := KitProps._meshes(model).size()
	model.free()
	var lowest := INF
	for part: MultiMeshInstance3D in parts:
		if part.multimesh.instance_count != 50:
			_fail("place_many part %s has %d copies, not 50" % [part.name, part.multimesh.instance_count])
			return
		for i in 50:
			var aabb: AABB = part.multimesh.get_instance_transform(i) * part.multimesh.mesh.get_aabb()
			lowest = minf(lowest, aabb.position.y)
	if parts.size() != expected or parts.is_empty():
		_fail("place_many made %d MultiMeshes, expected %d" % [parts.size(), expected])
	elif absf(lowest) > SNAP_CM:
		_fail("place_many chairs' lowest point is %.3f, not on the floor" % lowest)
	else:
		_pass("place_many: 50 chairs drawn with %d MultiMesh(es), on the floor" % parts.size())


## Loading the same model twice gives the same cached file.
func _check_cache() -> void:
	var first := KitProps.scene("kenney_food/pizza")
	var second := KitProps.scene("kenney_food/pizza")
	if first == null or first != second:
		_fail("the model cache doesn't keep loaded models")
	elif KitProps.scene("kenney_food/no_such_thing") != null:
		_fail("a missing model should give null")
	else:
		_pass("loaded models are cached, missing ones give null")


## The animation library (Quaternius UAL 1, CC0) loads and has the clips we want later.
func _check_animations() -> void:
	var packed := load(UAL) as PackedScene
	if packed == null:
		_fail("animation library doesn't load")
		return
	var lib_root := packed.instantiate()
	var player := lib_root.find_children("*", "AnimationPlayer", true, false)
	var names: PackedStringArray = []
	if not player.is_empty():
		names = (player[0] as AnimationPlayer).get_animation_list()
	lib_root.free()
	var missing := []
	for want in ["Swim_Fwd", "Swim_Idle", "Sitting_Idle", "Jog_Fwd", "Walk", "Idle"]:  # Godot drops "_Loop" and loops them
		if not want in names:
			missing.append(want)
	if missing.is_empty():
		_pass("animation library has %d clips incl. swim, sit, jog" % names.size())
	else:
		_fail("animation library is missing %s" % [missing])


## Every pack folder has its licence file and is listed in sources.json.
func _check_licences() -> void:
	var text := FileAccess.get_file_as_string("res://assets/kits/sources.json")
	var sources = JSON.parse_string(text)
	if not sources is Array:
		_fail("assets/kits/sources.json is missing or not a list")
		return
	var listed := {}
	for item: Dictionary in sources:
		listed[item.get("folder", "")] = item
		if item.get("license", "") != "CC0-1.0":
			_fail("%s isn't marked CC0-1.0" % item.get("folder", "?"))
	var ok := true
	for pack: String in KitCatalogue.PACKS.keys() + ["quaternius_ual"]:
		if not listed.has(pack):
			_fail("%s isn't in sources.json" % pack)
			ok = false
		var files := DirAccess.get_files_at("res://assets/kits/" + pack)
		var has_licence := false
		for file in files:
			if file.to_lower().begins_with("licen"):
				has_licence = true
		if not has_licence:
			_fail("%s has no licence file" % pack)
			ok = false
	if ok:
		_pass("every pack has a licence file and a sources.json entry (all CC0)")


## Checks the prop's box sits where its snap says. Returns true if right.
func _sits_right(prop: Node3D, box: AABB) -> bool:
	var snap: String = prop.get_meta("kit_snap")
	var y: float = prop.get_meta("kit_snap_y")
	var id: String = prop.get_meta("kit_id")
	match snap:
		"hang":
			if absf(box.end.y - y) > SNAP_CM:
				_fail("%s (hang) top is at %.3f, should be %.3f" % [id, box.end.y, y])
				return false
		"origin":
			var model := prop.get_node("Model") as Node3D
			if absf(model.global_position.y - y) > SNAP_CM or box.position.y > y + SNAP_CM:
				_fail("%s (origin) doesn't reach the ground at %.3f (bottom %.3f)" % [id, y, box.position.y])
				return false
		_:
			if absf(box.position.y - y) > SNAP_CM:
				_fail("%s (%s) bottom is at %.3f, should be %.3f" % [id, snap, box.position.y, y])
				return false
	return true


## The box around every mesh of a placed prop, in world space.
func _world_box(prop: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for view: MeshInstance3D in KitProps._meshes(prop):
		var part: AABB = view.global_transform * view.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


## Prints every model in every pack with its size in metres (for picking models).
func _list_all() -> void:
	var world := Node3D.new()
	root.add_child(world)
	for pack: String in KitCatalogue.PACKS:
		for file in DirAccess.get_files_at("res://assets/kits/" + pack):
			if not (file.ends_with(".glb") or file.ends_with(".gltf")):
				continue
			var id := "%s/%s" % [pack, file.get_basename()]
			var size := KitProps.size_of(id)
			print("SIZE %-48s %5.2f x %5.2f x %5.2f m (w x h x d)" % [id, size.x, size.y, size.z])


func _pass(text: String) -> void:
	print("PASS: " + text)


func _fail(text: String) -> void:
	print("FAIL: " + text)
	_failed = true
