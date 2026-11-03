extends Critter
## A kid on a kick scooter riding back and forth along the edge of a street, waiting a
## moment at each end before turning round. Bump into them and they stop and wobble for a
## moment, then carry on. ObstacleBuilder makes one per line in SCOOTER_KIDS
## (data/palm_grove.gd) and calls setup(). Speeds are in game_config.gd.

const BODY_SIZE := Vector3(0.5, 1.3, 1.0)

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _going_to_end := true
var _pause_left := 0.0
var _wobble := 0.0
var _blocked := 0.0  # seconds someone has been in the way
var _model: Node3D


## from, to: the two ends of the ride. shirt: the shirt colour.
func setup(from: Vector3, to: Vector3, shirt: Color) -> void:
	_from = from
	_to = to
	position = from.lerp(to, randf())  # start somewhere along the way
	_going_to_end = randf() < 0.5
	_model = Node3D.new()
	add_child(_model)
	_build_model(shirt)
	make_body(BODY_SIZE)
	face(_heading())


func _physics_process(delta: float) -> void:
	if scared_left > 0.0:
		scared_left -= delta
		_wobble += delta * 18.0
		_model.rotation.z = sin(_wobble) * 0.15 * scared_left
		return
	_model.rotation.z = 0.0
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			face(_heading())
		return
	if bike_in_the_way():
		# Wait politely, but if you stay in the way (say the bike is parked), turn back.
		_blocked += delta
		if _blocked > GameConfig.SCOOTER_GIVE_WAY_TIME:
			_blocked = 0.0
			_going_to_end = not _going_to_end
			_pause_left = GameConfig.SCOOTER_TURN_PAUSE
		return
	_blocked = 0.0
	var goal := _to if _going_to_end else _from
	var gap := goal - position
	var step := GameConfig.SCOOTER_SPEED * delta
	if gap.length() <= step:
		position = goal
		_going_to_end = not _going_to_end
		_pause_left = GameConfig.SCOOTER_TURN_PAUSE
		return
	position += gap.normalized() * step


func _heading() -> Vector3:
	return (_to - _from) if _going_to_end else (_from - _to)


func _build_model(shirt: Color) -> void:
	var grey := Color(0.25, 0.27, 0.3, 1)
	var skin := Color(0.78, 0.58, 0.42, 1)
	# The scooter: deck, two small wheels, the steering post and handlebar at the front.
	LowPoly.box(_model, Vector3(0.16, 0.05, 0.8), grey, Vector3(0, 0.1, 0))
	for z in [-0.38, 0.38]:
		var wheel := LowPoly.cylinder(_model, 0.07, 0.07, 0.05, Color(0.1, 0.1, 0.1, 1), Vector3(0, 0.07, z))
		wheel.rotation.z = PI * 0.5
	LowPoly.cylinder(_model, 0.025, 0.025, 0.85, Color(0.85, 0.2, 0.2, 1), Vector3(0, 0.52, -0.4))
	LowPoly.box(_model, Vector3(0.45, 0.04, 0.04), grey, Vector3(0, 0.95, -0.4))
	# The kid: legs, shirt, arms to the handlebar, head and a helmet.
	LowPoly.box(_model, Vector3(0.1, 0.42, 0.1), Color(0.2, 0.25, 0.45, 1), Vector3(-0.06, 0.34, 0.05))
	LowPoly.box(_model, Vector3(0.1, 0.42, 0.1), Color(0.2, 0.25, 0.45, 1), Vector3(0.06, 0.34, 0.12))
	LowPoly.box(_model, Vector3(0.28, 0.36, 0.18), shirt, Vector3(0, 0.73, 0.05))
	var arm := LowPoly.box(_model, Vector3(0.36, 0.07, 0.07), skin, Vector3(0, 0.86, -0.2))
	arm.rotation.x = deg_to_rad(-20.0)
	LowPoly.sphere(_model, 0.12, 0.24, skin, Vector3(0, 1.04, 0.03))
	LowPoly.sphere(_model, 0.14, 0.18, shirt.lightened(0.3), Vector3(0, 1.12, 0.03))
