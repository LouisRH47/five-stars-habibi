extends SceneTree
## Session 52: checks there's no flicker ("z-fighting") left in Wahat Al Shams.
## Two surfaces in exactly the same place, facing the same way, with different colours
## flicker when the camera moves. scripts/zfight_fix.gd fixes them while the map loads;
## this loads the map and checks that none are left (also among boxes merged into batches).
## Run: Godot --path . --headless -s tests/coplanar_test.gd   (prints RESULT: PASS)
## Add "-- report" to list them without failing.


func _init() -> void:
	await process_frame
	var report_only := OS.get_cmdline_user_args().has("report")
	var scene: Node = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(scene)
	for i in 30:
		await process_frame
	var list := ZFightFix.boxes(scene)
	var pairs := ZFightFix.find(list)
	print("Boxes checked: %d" % list.size())
	print("Flicker pairs found: %d" % pairs.size())
	for pair in pairs.slice(0, 60):
		var a: MeshInstance3D = list[pair[0]][0]
		var b: MeshInstance3D = list[pair[1]][0]
		print("  %s  <->  %s  (%s)" % [_short(a), _short(b), pair[3]])
	var detail: Node = scene.find_child("DistrictDetail", true, false)
	if detail != null and detail.has_meta("zfight_fixed"):
		print("Fixed while loading: %d" % detail.get_meta("zfight_fixed"))
	if pairs.is_empty() or report_only:
		print("RESULT: PASS" if pairs.is_empty() else "RESULT: REPORT")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


func _short(part: Node) -> String:
	return str(part.get_path()).replace("/root/WahatAlShams/", "")
