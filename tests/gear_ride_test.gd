extends SceneTree
## Compare the visible camera response to the same crest and bump before/after tyres.
var failed := false

func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, text: String) -> void:
	failed = failed or not ok
	print("PASS: " if ok else "FAIL: ", text)


func _run() -> void:
	var plain := await _sample(false)
	var comfy := await _sample(true)
	_expect(plain["rise"] > 0 and comfy["rise"] > 0, "both cameras follow a rising terrain surface")
	_expect(comfy["rise"] < plain["rise"], "comfy tyres soften the visible rise over an identical hill crest")
	_expect(comfy["jolt"] < plain["jolt"], "comfy tyres reduce the visible speed-bump jolt")
	print("TYRE_RESPONSE: ", JSON.stringify({"plain":plain,"comfy":comfy}))
	print("RESULT: ", "FAIL" if failed else "PASS", " gear ride")
	quit(1 if failed else 0)


func _sample(tyres: bool) -> Dictionary:
	var space := Node3D.new()
	root.add_child(space)
	var bike: Node3D = load("res://scenes/bike.tscn").instantiate()
	space.add_child(bike)
	bike.set_physics_process(false)
	bike.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	bike.configure_upgrades({"tyres":1} if tyres else {})
	var camera: Camera3D = load("res://scripts/follow_camera.gd").new()
	camera.target = bike
	space.add_child(camera)
	camera.set_process(false)
	await physics_frame
	var initial := camera.global_position.y
	bike.position.y = 1.2
	camera._process(0.1)
	var rise := camera.global_position.y - initial
	for frame in 120:
		camera._process(1.0 / 60)
	seed(741)
	camera._on_speed_bump(1.0)
	camera._process(1.0 / 60)
	var jolt := absf(camera.global_position.x)
	space.queue_free()
	await process_frame
	return {"rise":rise,"jolt":jolt}
