class_name GymMotion
extends Node
## Session 60: keeps the people in the gym working out. Runners jog on the treadmills,
## the cyclist pedals (feet go round the crank), the rower slides back and forth pulling
## the handle, and the lifter squats with the barbell. GymRoom fills in the lists.
## When the gym is far from the camera its people are paused (PlaceBuilder), and this
## stops too, so it costs nothing.

var runners: Array[Person] = []
var cyclists: Array[Person] = []
## Each rower: [person, seat mesh, handle mesh, front of the machine].
var rowers: Array = []
var lifter: Person
var lifter_base := Vector3.ZERO

var _time := 0.0
var _started := false


func _process(delta: float) -> void:
	if not _started:
		_started = true
		for runner in runners:
			runner.play("jog", 1.15)
	var awake := false
	for who in runners + cyclists:
		awake = awake or who.process_mode != Node.PROCESS_MODE_DISABLED
	if not awake and not runners.is_empty():
		return
	_time += delta
	for i in cyclists.size():
		_pedal(cyclists[i], _time * 5.5 + i)
	for rower in rowers:
		_row(rower, (1.0 - cos(_time * 2.4)) * 0.5)
	if lifter != null:
		var depth := (1.0 - cos(_time * 1.6)) * 0.5
		lifter.pose.reach = depth
		lifter.position.y = lifter_base.y - depth * GameConfig.PERSON_HEIGHT * 0.22


## Feet go round the crank, half a turn apart; hands stay on the handlebar.
func _pedal(who: Person, angle: float) -> void:
	var crank: Vector3 = who.get_meta("crank")
	var bar: Vector3 = who.get_meta("bar")
	for side in 2:
		var a := angle + side * PI
		var x := -0.12 if side == 0 else 0.12
		who.pose.feet[side] = crank + Vector3(x, sin(a) * 0.17, -cos(a) * 0.17)
		who.pose.hands[side] = bar + Vector3(x * 1.6, 0, 0)


## reach 0 = the catch (seat forward, knees up), 1 = the finish (legs straight, arms in).
## The numbers match PersonPose._row, so the feet stay on the footplate.
func _row(rower: Array, reach: float) -> void:
	var who: Person = rower[0]
	var seat: MeshInstance3D = rower[1]
	var handle: MeshInstance3D = rower[2]
	var leg := who.spot("LeftUpLeg").distance_to(who.spot("LeftLeg")) + who.spot("LeftLeg").distance_to(who.spot("LeftFoot"))
	var hips := who.spot("Hips")
	var seat_z := 0.62 + lerpf(leg * 0.62, leg * 0.97, reach)
	seat.position.z = seat_z
	who.position = Vector3(0, 0.3 - hips.y, seat_z)
	who.pose.reach = reach
	handle.position = Vector3(0, 0.3 + lerpf(0.15, 0.4, reach), seat_z + lerpf(-0.75, -0.2, reach))
