extends SceneTree
## Looks pass Session 53: the free CC0 kits in assets/kits/ and the prop library
## (Props.kit, Props.bake_kits, RoomProps), plus the kit gallery scene.
## Run: Godot --path . --headless -s tests/kit_props_test.gd
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	_check_kits()
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " kit props · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


## Session 53: each kit has its CC0 licence, is credited, and every model in it loads.
func _check_kits() -> void:
	var credits := FileAccess.get_file_as_string("res://CREDITS.md")
	for pack: String in Props.KIT_PACKS:
		var folder: String = Props.KIT_PACKS[pack]
		var licence := FileAccess.get_file_as_string(folder + "License.txt")
		_expect(licence.contains("CC0") or licence.contains("Creative Commons Zero"), pack + " kit has its CC0 licence file")
		_expect(credits.contains(folder.trim_prefix("res://")), pack + " kit is credited in CREDITS.md")
		var bad: Array = []
		var names := preload("res://scripts/kit_gallery.gd").kit_names(pack)
		for name in names:
			if Props.kit_parts(pack + "/" + name).is_empty():
				bad.append(name)
		_expect(names.size() >= 15 and bad.is_empty(), pack + " kit: every model loads", "%d models %s" % [names.size(), bad])
	var holder := Node3D.new()
	var chair := Props.kit("restaurant/chair_A", holder, Vector3(1, 0, 2), 90.0, 0.7)
	Props.kit("furniture/cactus_small_A", holder, Vector3(0, 0, 0))
	_expect(chair.position == Vector3(1, 0, 2) and is_equal_approx(chair.scale.x, 0.7) and is_equal_approx(chair.rotation_degrees.y, 90.0),
			"Props.kit places a model by name with a position, rotation and scale")
	_expect(Props.bake_kits(holder) == 2 and holder.get_node_or_null("KitBatch_restaurant") != null
			and holder.get_node_or_null("KitBatch_furniture") != null and holder.find_children("Kit_*", "", true, false).is_empty(),
			"kit models in a room are joined into one mesh per kit")
	holder.free()
	var gallery: Node3D = load("res://scenes/kit_gallery.tscn").instantiate()
	root.add_child(gallery)
	_expect(gallery.find_children("Kit_*", "Node3D", true, false).size() >= 30, "the kit gallery scene shows a row of props from each kit")
	gallery.free()


