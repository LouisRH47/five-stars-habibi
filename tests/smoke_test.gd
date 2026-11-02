extends SceneTree
## Smoke test: loads the main scene, pedals for a few seconds and checks the bike
## actually moves, sprints and stops. Run it with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s tests/smoke_test.gd
## It prints PASS or FAIL lines and exits with code 1 on any failure.

const STEPS := {
	"pedal": 180,      # 3 seconds at 60 physics frames per second
	"sprint": 180,
	"brake": 240,
}

var _bike: CharacterBody3D
var _frame := 0
var _phase := "pedal"
var _failed := false
var _top_speed := 0.0


func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_bike = main.get_node("Bike")
	Input.action_press("move_forward")


func _physics_process(_delta: float) -> bool:
	_frame += 1
	_top_speed = maxf(_top_speed, _bike.speed)
	match _phase:
		"pedal":
			if _frame >= STEPS.pedal:
				_check("bike moves when pedalling", _bike.speed > 3.0, "speed %.1f m/s" % _bike.speed)
				_check("bike stays on the ground", _bike.is_on_floor(), "")
				Input.action_press("sprint")
				_frame = 0
				_phase = "sprint"
		"sprint":
			if _frame >= STEPS.sprint:
				var sprint_kmh := _top_speed * 3.6
				_check("sprint goes faster than normal top speed", sprint_kmh > GameConfig.BIKE_MAX_SPEED_KMH + 2.0, "%.1f km/h" % sprint_kmh)
				_check("sprinting drains stamina", _bike.stamina < GameConfig.STAMINA_MAX, "stamina %.0f" % _bike.stamina)
				Input.action_release("sprint")
				Input.action_release("move_forward")
				Input.action_press("move_back")
				_frame = 0
				_phase = "brake"
		"brake":
			if _frame >= STEPS.brake:
				_check("brake stops the bike", _bike.speed <= 0.1, "speed %.1f m/s" % _bike.speed)
				_check("stamina refills", _bike.stamina > 30.0, "stamina %.0f" % _bike.stamina)
				Input.action_release("move_back")
				_finish()
	return false


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		print("PASS: ", label, "  ", detail)
	else:
		_failed = true
		print("FAIL: ", label, "  ", detail)


func _finish() -> void:
	print("RESULT: ", "FAIL" if _failed else "PASS")
	quit(1 if _failed else 0)
