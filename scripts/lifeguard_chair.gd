class_name LifeguardChair
extends Node3D
## Session 81 (people): a tall white lifeguard chair at the pool's edge with the lifeguard
## sitting on top. He turns his head and body to look round the pool; every so often he
## stands up on the footrest, blows his whistle (you hear it if you're close) and points
## at the water, then sits down again. Made by PlaceCrowds, which also stops him moving
## when you're far away. The chair faces -Z, like a person.

const WHITE := Color(0.96, 0.96, 0.94)
const RED := Color(0.88, 0.12, 0.12)

## The lifeguard on the chair.
var person: Person
## True while he's standing up blowing the whistle.
var standing := false
## How many times he has blown the whistle (the smoke test checks it).
var whistles := 0

var _wait := 0.0       # seconds until he stands up (sitting) or sits down (standing)
var _look_at := 0.0    # degrees he's turning to look at
var _look_wait := 0.0  # seconds until he looks somewhere else
var _sound: AudioStreamPlayer3D
static var _whistle_wav: AudioStreamWAV


func _init() -> void:
	add_child(_chair())
	person = PlaceLooks.lifeguard(false)
	person.name = "Lifeguard"
	add_child(person)
	_sit_down()
	_wait = randf_range(GameConfig.LIFEGUARD_STAND_EVERY.x * 0.3, GameConfig.LIFEGUARD_STAND_EVERY.y)
	_sound = AudioStreamPlayer3D.new()
	_sound.name = "Whistle"
	_sound.stream = whistle_sound()
	_sound.bus = "Effects" if AudioServer.get_bus_index("Effects") >= 0 else "Master"
	_sound.max_distance = GameConfig.LIFEGUARD_WHISTLE_HEARD
	_sound.position = Vector3(0, GameConfig.LIFEGUARD_SEAT_HEIGHT + 1.2, 0)
	add_child(_sound)


func _ready() -> void:
	_sit_down()  # again, now we know how high the ground under the chair is


func _process(delta: float) -> void:
	if person.process_mode == Node.PROCESS_MODE_DISABLED or not person.visible:
		return  # far away: he holds still
	_wait -= delta
	if _wait <= 0.0:
		if standing:
			_sit_down()
		else:
			stand_up()
	# Look round: the head turns and the whole body turns a little on the seat.
	_look_wait -= delta
	if _look_wait <= 0.0:
		_look_wait = randf_range(1.5, 4.0)
		_look_at = randf_range(-GameConfig.LIFEGUARD_LOOK_DEG, GameConfig.LIFEGUARD_LOOK_DEG)
	var look := 0.0 if standing else _look_at
	person.pose.look = move_toward(person.pose.look, look, 70.0 * delta)
	person.rotation.y = lerp_angle(person.rotation.y, deg_to_rad(look * 0.35), 2.0 * delta)


## Stands up on the footrest, blows the whistle and points at the pool.
func stand_up() -> void:
	standing = true
	whistles += 1
	_wait = GameConfig.LIFEGUARD_STAND_TIME
	person.position = Vector3(0, GameConfig.LIFEGUARD_FOOTREST_HEIGHT + 0.05, -0.32)
	person.play("whistle")
	if _sound.is_inside_tree():
		_sound.play()


func _sit_down() -> void:
	standing = false
	_wait = randf_range(GameConfig.LIFEGUARD_STAND_EVERY.x, GameConfig.LIFEGUARD_STAND_EVERY.y)
	person.position = Vector3(0, GameConfig.LIFEGUARD_SEAT_HEIGHT + 0.07 - person.spot("Hips").y, 0.02)
	person.play("sit")
	# His feet go on the footrest.
	var ground := global_position.y if is_inside_tree() else 0.0
	person.pose.floor_y = ground + GameConfig.LIFEGUARD_FOOTREST_HEIGHT


## The chair: four white legs leaning in, a seat with a back and arms, a footrest, ladder
## rungs at the back, a red sun shade on a pole and a red rescue float hung on the side.
func _chair() -> MeshInstance3D:
	var kit := MeshKit.new()
	var seat := GameConfig.LIFEGUARD_SEAT_HEIGHT
	var foot := GameConfig.LIFEGUARD_FOOTREST_HEIGHT
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:  # legs from wide at the bottom to the seat corners
			var bottom := Vector3(x * 0.55, 0.0, z * 0.6)
			var top := Vector3(x * 0.33, seat, z * 0.28)
			kit.box(Vector3(0.07, bottom.distance_to(top), 0.07), WHITE, (bottom + top) * 0.5,
					Basis(Quaternion(Vector3.UP, (top - bottom).normalized())))
	kit.box(Vector3(0.75, 0.07, 0.6), WHITE, Vector3(0, seat, 0))               # the seat
	kit.box(Vector3(0.75, 0.55, 0.06), WHITE, Vector3(0, seat + 0.3, 0.3))      # the back
	for x in [-0.38, 0.38]:
		kit.box(Vector3(0.05, 0.05, 0.55), WHITE, Vector3(x, seat + 0.25, 0.02))  # arm rests
		kit.box(Vector3(0.05, 0.25, 0.05), WHITE, Vector3(x, seat + 0.12, -0.24))
	kit.box(Vector3(0.8, 0.05, 0.3), WHITE, Vector3(0, foot, -0.45))           # the footrest
	for z in [-0.6, -0.3]:
		kit.box(Vector3(0.05, 0.05, 0.3), WHITE, Vector3(-0.38, foot - 0.02, z + 0.12))
		kit.box(Vector3(0.05, 0.05, 0.3), WHITE, Vector3(0.38, foot - 0.02, z + 0.12))
	for i in 4:  # ladder rungs up the back
		kit.box(Vector3(0.9, 0.04, 0.04), WHITE, Vector3(0, 0.35 + i * 0.32, 0.5 - i * 0.065))
	kit.cylinder(0.025, 0.025, 1.6, WHITE, Vector3(0.36, seat + 0.8, 0.3))       # the shade pole
	kit.cylinder(0.02, 0.85, 0.35, RED, Vector3(0.36, seat + 1.7, 0.3))         # the shade
	kit.box(Vector3(0.6, 0.18, 0.12), RED, Vector3(0, seat + 0.42, 0.35))        # "LIFEGUARD" band
	kit.box(Vector3(0.12, 0.7, 0.08), RED, Vector3(-0.55, 0.9, 0.0), Basis(Vector3.FORWARD, 0.2))  # rescue float
	var view := kit.finish("LifeguardChair")
	return view


## A short two-tone whistle trill, made in code (no sound file needed), made once.
static func whistle_sound() -> AudioStreamWAV:
	if _whistle_wav != null:
		return _whistle_wav
	var rate := 22050
	var seconds := 0.55
	var data := PackedByteArray()
	data.resize(int(rate * seconds) * 2)
	var phase := 0.0
	for i in int(rate * seconds):
		var t := float(i) / rate
		var trill := 2900.0 + 250.0 * sin(TAU * 28.0 * t)  # the pea in the whistle rattling
		phase += TAU * trill / rate
		var fade := minf(t / 0.03, 1.0) * minf((seconds - t) / 0.08, 1.0)
		var wave := sin(phase) * 0.35 * fade
		data.encode_s16(i * 2, int(wave * 32767.0))
	_whistle_wav = AudioStreamWAV.new()
	_whistle_wav.format = AudioStreamWAV.FORMAT_16_BITS
	_whistle_wav.mix_rate = rate
	_whistle_wav.data = data
	return _whistle_wav
