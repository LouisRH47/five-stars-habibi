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
	# Session 67: around the Plaza restaurants, flat tops only a few millimetres apart
	# (too far apart for ZFightFix, too close to stay steady far away) also count.
	# The area stops inside the ring road (its speed bump stripes are raised on purpose).
	var near := near_pairs(list, Rect2(-265, -198, 130, 112), 0.004, 0.015)
	var plaza := scene.find_child("Plaza", true, false) as MeshInstance3D
	if plaza != null:
		var top := (plaza.global_transform * plaza.get_aabb()).end.y
		if absf(top - 0.04) < 0.015 or absf(top) < 0.015:
			near.append("Plaza paving top %.3f is too close to the roads (0.04) or sand (0)" % top)
	print("Plaza near-flicker pairs: %d" % near.size())
	for line in near.slice(0, 20):
		print("  " + line)
	pairs.append_array(near)
	if pairs.is_empty() or report_only:
		print("RESULT: PASS" if pairs.is_empty() else "RESULT: REPORT")
		quit(0)
	else:
		print("RESULT: FAIL")
		quit(1)


## Pairs of flat box tops inside `area` (x, z) that overlap and sit between `low` and
## `high` metres apart, with different colours.
func near_pairs(list: Array, area: Rect2, low: float, high: float) -> Array:
	var found: Array = []
	var flat: Array = []
	for entry in list:
		var box: AABB = entry[1]
		if box.end.y < 0.5 and box.end.y > -0.6 and area.intersects(Rect2(box.position.x, box.position.z, box.size.x, box.size.z)):
			flat.append(entry)
	for i in flat.size():
		for j in range(i + 1, flat.size()):
			if flat[i][2] == flat[j][2]:
				continue
			var a: AABB = flat[i][1]
			var b: AABB = flat[j][1]
			var gap := absf(a.end.y - b.end.y)
			if gap < low or gap > high:
				continue
			var ox := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
			var oz := minf(a.end.z, b.end.z) - maxf(a.position.z, b.position.z)
			if ox > 0.1 and oz > 0.1:
				found.append("%s <-> %s tops %.3f / %.3f" % [_short(flat[i][0]), _short(flat[j][0]), a.end.y, b.end.y])
	return found


func _short(part: Node) -> String:
	return str(part.get_path()).replace("/root/WahatAlShams/", "")
