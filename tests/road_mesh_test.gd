extends SceneTree
## Session 61: the road surfaces, markings, kerbs and curved corners (no full game needed).
## Run: godot --path . --headless -s tests/road_mesh_test.gd

var _failures := 0
var _count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var map: Dictionary = (load("res://data/wahat_al_shams.gd") as Script).get_script_constant_map()
	var roads := RoadMesh.build(world, map)
	var stats: Dictionary = roads.stats
	print("ROADS: ", JSON.stringify(stats))
	_check("the short road pieces are joined into smooth chains", stats["chains"] < WahatAlShams.ROADS.size() / 2)
	var ring: Array = roads.chains.filter(func(c): return c["name"] == "Ring Road")
	_check("the ring road is one closed, rounded loop", ring.size() == 1 and ring[0]["closed"] and ring[0]["points"].size() > 20)
	var round: Array = roads.chains.filter(func(c): return c["name"] == "Institute Roundabout")
	_check("the roundabout is one closed curve", round.size() == 1 and round[0]["closed"])
	_check("every asphalt road gets a dashed yellow centre line", stats["dashes"] > 1000)
	_check("arrows on both sides of the roads", stats["arrows"] > 200)
	_check("curved corner pieces where roads meet", stats["fillets"] >= 60)
	_check("kerbs along the roads", stats["kerb_pieces"] > 3000)
	_check("no two road surfaces meet at the same height", stats["same_height_overlaps"] == 0)
	_check("road heights stay above the pavers", roads.chains.all(func(c): return not c["asphalt"] or c["top"] > RoadMesh.PAVING_TOP))
	_check("pavers stay below the asphalt", roads.chains.all(func(c): return c["asphalt"] or c["top"] < RoadMesh.UNDER_TOP))
	_check("roads are merged into a few meshes", stats["meshes"] > 0 and stats["meshes"] < 200)
	var lane: Array = roads.chains.filter(func(c): return c["name"] == "C1 Lane")
	_check("cluster lanes are asphalt", not lane.is_empty() and lane.all(func(c): return c["asphalt"]))
	# A car park access road leaves the ring road at every car park.
	_check("car park access roads", roads.chains.filter(func(c): return c["name"] == "Car Park Access").size() == WahatAlShams.PARKING_AREAS.size())
	world.free()
	print("ROAD RESULT: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _count])
	quit(0 if _failures == 0 else 1)


func _check(label: String, good: bool) -> void:
	_count += 1
	print("%s: %s" % ["PASS" if good else "FAIL", label])
	if not good:
		_failures += 1
