extends SceneTree
## World polish pass Sessions 64 to 66 (signs wave), focused: loads Wahat Al Shams and runs
## the same checks as the smoke test (tests/smoke_signs.gd): bus stop, car parks, cluster
## entrance signs, end houses, bins, pool gate, Majlis Gardens and the phase 3 site.
## Run: Godot --path . --headless -s tests/signs_wave_test.gd   (prints RESULT: PASS)

var _main: Node
var _failed := false


func _init() -> void:
	await process_frame
	_main = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(_main)
	for i in 30:
		await process_frame
	load("res://tests/smoke_signs.gd").new().run(self)
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)


func _check(label: String, ok: bool, detail: String) -> void:
	if not ok:
		_failed = true
	print("PASS: " if ok else "FAIL: ", label, "  ", detail)
