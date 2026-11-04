extends RefCounted
## Session 66 test helper: a stand-in polish part (like scripts/polish/look_extras.gd).
## tests/polish_groundwork_test.gd checks PolishHooks calls this once per world.

static func attach(world: Node) -> void:
	var marker := Node.new()
	marker.name = "PolishTestPart"
	world.add_child(marker)
	world.set_meta("polish_test_calls", int(world.get_meta("polish_test_calls", 0)) + 1)
