class_name GymMotion
extends Node
## Looks pass Session 56: the people working out in the Wahat Gym. Runners on the
## treadmills just play their running animation; this moves the rest:
##   pedallers  feet go round the exercise bike's pedals
##   rowers     slide back and forth on the rowing machine, pulling the handle
##   lifters    squat down and up with the barbell on their shoulders
##   stretchers lean forward and back on a yoga mat
## Only while the camera is close (cheaper). Numbers: GameConfig GYM_*.

const ACTIVE_DISTANCE := 45.0

## [person, crank centre (person space)]
var pedallers: Array = []
## [person, start position, handle node, hips height (person space)]
var rowers: Array = []
## [person, start position, barbell node, barbell start]
var lifters: Array = []
## [person]
var stretchers: Array = []
var _time := 0.0


func _process(delta: float) -> void:
	var room := get_parent() as Node3D
	if room == null or not room.is_inside_tree():
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_to(room.global_position) > ACTIVE_DISTANCE:
		return
	_time += delta
	for i in pedallers.size():
		var person := pedallers[i][0] as Person
		var crank: Vector3 = pedallers[i][1]
		var turn := _time * TAU * GameConfig.GYM_PEDAL_TURNS + i
		for side in 2:
			var a := turn + PI * side
			person.pose.feet[side] = crank + Vector3(-0.1 if side == 0 else 0.1, sin(a) * 0.15, cos(a) * 0.15)
	for i in rowers.size():
		var person := rowers[i][0] as Person
		var start: Vector3 = rowers[i][1]
		# 0 = reaching forward (legs bent), 1 = pulled back (legs straight).
		var stroke := 0.5 - 0.5 * cos(_time * TAU * GameConfig.GYM_ROW_STROKES + i * 1.3)
		var slide := stroke * GameConfig.GYM_ROW_SLIDE
		person.position = start + person.basis.z * slide
		var hips_y: float = rowers[i][3]
		var foot := Vector3(0, hips_y - 0.2, -0.75 - slide)
		person.pose.feet[0] = foot + Vector3(-0.12, 0, 0)
		person.pose.feet[1] = foot + Vector3(0.12, 0, 0)
		var hand := Vector3(0, hips_y + 0.3, lerpf(-0.75, -0.2, stroke) - slide * 0.2)
		person.pose.hands[0] = hand + Vector3(-0.2, 0, 0)
		person.pose.hands[1] = hand + Vector3(0.2, 0, 0)
		person.pose.lean = lerpf(25.0, -12.0, stroke)
		var handle := rowers[i][2] as Node3D
		if handle != null:
			handle.position = person.position + person.basis * hand
	for i in lifters.size():
		var person := lifters[i][0] as Person
		var start: Vector3 = lifters[i][1]
		var squat := maxf(0.0, sin(_time * TAU * GameConfig.GYM_SQUATS + i)) * GameConfig.GYM_SQUAT_DEPTH
		person.position = start + Vector3(0, -squat, 0)
		for side in 2:
			person.pose.feet[side] = Vector3(-0.17 if side == 0 else 0.17, 0.08 + squat, -0.05)
		person.pose.lean = squat * 40.0
		var bar := lifters[i][2] as Node3D
		bar.position = lifters[i][3] + Vector3(0, -squat, 0)
	for person: Person in stretchers:
		person.pose.lean = 25.0 + sin(_time * 0.8) * 15.0
