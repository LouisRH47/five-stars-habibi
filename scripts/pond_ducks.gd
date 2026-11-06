class_name PondDucks
extends Node3D
## Session 91: ducks paddling about on a pond (the big pond by the C Institute). Each duck
## swims slowly round its own wobbly loop on the water, bobbing and rocking a little, and
## turns to face the way it's going. They only move when the camera is near (cheap).
## The pond data says how many: "ducks": 4. The duck model is LifeLooks.duck().

## Every duck's loop: [duck, loop radius, how far round it starts (radians), speed sign].
var ducks: Array = []
var _time := 0.0


## Makes the ducks for `pond` under `holder`. Returns the PondDucks node.
static func build(holder: Node3D, pond: Dictionary, seed: int) -> PondDucks:
	var centre: Vector2 = pond["centre"]
	var radius: float = pond["radius"]
	var flock := PondDucks.new()
	flock.name = "PondDucks_%d" % seed
	flock.position = Vector3(centre.x, StreamPond.WATER_TOP, centre.y)
	holder.add_child(flock)
	for i in int(pond.get("ducks", 0)):
		var duck := LifeLooks.duck(i % 2 == 0)
		duck.name = "Duck%d" % i
		flock.add_child(duck)
		# Loops of different sizes, some going clockwise, some the other way.
		var loop := radius * lerpf(0.25, 0.6, float(i) / maxf(1.0, pond["ducks"] - 1.0))
		flock.ducks.append([duck, loop, TAU * i / 4.0 + 0.6, 1.0 if i % 2 == 0 else -1.0])
	flock._place(0.0)
	return flock


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_to(global_position) > GameConfig.POND_DUCKS_AWAKE_DISTANCE:
		return
	_time += delta
	_place(_time)


## Puts every duck where it should be `time` seconds into its paddle.
func _place(time: float) -> void:
	for i in ducks.size():
		var entry: Array = ducks[i]
		var duck := entry[0] as Node3D
		var loop: float = entry[1]
		var turn: float = entry[3]
		var a: float = entry[2] + turn * time * GameConfig.POND_DUCK_SPEED / loop
		# A slightly squashed, wobbly loop so they don't look like they're on a turntable.
		var spot := Vector3(cos(a) * loop, 0, sin(a) * loop * 0.75 + sin(a * 2.0 + i) * 0.4)
		var ahead := Vector3(cos(a + turn * 0.05) * loop, 0, sin(a + turn * 0.05) * loop * 0.75 + sin((a + turn * 0.05) * 2.0 + i) * 0.4)
		duck.position = spot + Vector3(0, sin(time * 2.2 + i) * 0.02, 0)
		var way := ahead - spot
		duck.rotation = Vector3(0, atan2(-way.x, -way.z), sin(time * 1.7 + i * 0.9) * 0.08)  # ducks face -Z
