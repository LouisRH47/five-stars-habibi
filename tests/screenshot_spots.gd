extends SceneTree
## Takes screenshots of named spots in Wahat Al Shams, in a real window (not headless), so
## you see exactly what the game draws on this Mac with Forward+.
##   Godot --path . -s tests/screenshot_spots.gd -- out=/tmp/shots graphics=1 only=plaza,gym
## out: folder for the PNGs (default: user://screenshots). graphics: 0 Low, 1 Medium, 2 High.
## only: comma list of spot names (default: all). hour: time of day (default 11.0).
## ui=1 keeps the HUD and phone on screen. Your real save is never touched.

## name: [eye, look-at point]. Heights are metres above the ground.
const SPOTS := {
	# Louis's fix-pass screenshots (docs/fix_pass_screens)
	"01_institute_front": [Vector3(-176, 2.4, -30), Vector3(-200, 0.5, -33)],
	"02_spine_kerb": [Vector3(-120, 2.4, -42), Vector3(-80, 0.3, -42)],
	"03_car_park_c1": [Vector3(-71, 2.6, -55), Vector3(-71, 0.5, -120)],
	"04_spine_junction": [Vector3(-132, 2.4, -82), Vector3(-132, 0.3, -50)],
	"05_cluster_entrance": [Vector3(48, 2.4, -36), Vector3(48, 0.3, -60)],
	"06_community_pool": [Vector3(215, 3.0, 0), Vector3(215, 0.0, -22)],
	"07_cluster1_entrance": [Vector3(10, 2.4, -36), Vector3(-5, 0.3, -60)],
	"08_institute_road": [Vector3(-160, 2.4, -42), Vector3(-200, 0.5, -34)],
	"09_pedal_point": [Vector3(-245, 2.4, -122), Vector3(-275, 2.0, -145)],
	# Other spots the fix pass changes
	"plaza_top": [Vector3(-200, 70, -100), Vector3(-200, 0, -145)],
	"plaza_ground": [Vector3(-200, 2.0, -110), Vector3(-200, 1.0, -150)],
	"dune_drip": [Vector3(-152, 2.4, -122), Vector3(-125, 2.0, -145)],
	"dune_drip_back": [Vector3(-95, 3.0, -160), Vector3(-125, 2.0, -145)],
	"pedal_point_back": [Vector3(-305, 3.0, -160), Vector3(-275, 2.0, -145)],
	"roundabout_top": [Vector3(-132, 35, -40), Vector3(-132, 0, -62)],
	"roundabout_ground": [Vector3(-110, 2.4, -62), Vector3(-132, 0.3, -62)],
	"car_park_c1_top": [Vector3(-71, 70, -90), Vector3(-71, 0, -131)],
	"mosque_top": [Vector3(-330, 70, -110), Vector3(-370, 0, -150)],
	"lap_pool": [Vector3(161, 3.0, 2), Vector3(161, 0.0, 17)],
	"gym_stream": [Vector3(80, 4.0, 45), Vector3(115, 1.0, 22)],
	"basketball": [Vector3(-133, 4.0, -12), Vector3(-133, 0.5, -27)],
	"blue_track": [Vector3(-438, 2.0, 0), Vector3(-438, 0.3, -40)],
	"spine_grass": [Vector3(0, 2.0, -20), Vector3(40, 0.3, -5)],
	"cluster_playground_top": [Vector3(48, 40, -100), Vector3(48, 0, -126)],
	# lane R1
	"r1_roundabout_above": [Vector3(-118, 26, -40), Vector3(-132, 0, -62)],
	"r1_c1_entrance_top": [Vector3(48, 30, -22), Vector3(48, 0, -45)],
	"r1_c4_entrance_top": [Vector3(73, 30, 18), Vector3(73, 0, 40)],
	"r1_lane_corner_top": [Vector3(96, 22, -36), Vector3(106, 0, -50)],
	"r1_spine_west_junction": [Vector3(-272, 10, 10), Vector3(-290, 0, -6)],
	"r1_spine_east_end": [Vector3(378, 12, 12), Vector3(396, 0, 0)],
	"r1_institute_access_top": [Vector3(-168, 30, -6), Vector3(-190, 0, -20)],
	"r1_gate_north": [Vector3(-450, 30, -160), Vector3(-430, 0, -190)],
	"r1_kerb_close": [Vector3(58, 1.2, -1.2), Vector3(70, 0.0, -3.4)],
	"r1_c1_entrance_ground": [Vector3(40, 1.8, -34), Vector3(48, 0.2, -47)],
	"r1_institute_back_road": [Vector3(-150, 2.4, -61), Vector3(-185, 0.3, -64)],
	"r1_institute_access_ground": [Vector3(-183, 2.2, 1), Vector3(-190, 0.5, -28)],
}

var _main: Node
var _out := "user://screenshots"
var _graphics := 1
var _hour := 11.0
var _ui := false
var _names: Array = []
var _index := -1
var _wait := 0
var _camera: Camera3D
var _last_hash := 0
var _retries := 0


func _initialize() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		if parts.size() < 2:
			continue
		match parts[0]:
			"out": _out = parts[1]
			"graphics": _graphics = int(parts[1])
			"hour": _hour = float(parts[1])
			"only": only = parts[1]
			"ui": _ui = parts[1] == "1"
	_names = SPOTS.keys() if only == "" else Array(only.split(","))
	DirAccess.make_dir_recursive_absolute(_out)
	var state := root.get_node("GameState")
	state.save_path = OS.get_cache_dir().path_join("habibi_screenshot_save.json")
	state.new_game()
	Settings.graphics = _graphics
	_main = (load("res://scenes/wahat_al_shams.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	var events := _main.get_node_or_null("EventManager")
	if events != null:
		events.enabled = false
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.far = 1500.0
	root.add_child(_camera)
	_wait = 120  # let the world build and the shaders compile
	# macOS stops drawing a window that's hidden behind others, which froze the pictures.
	# Keep the game window on top and in front while it takes them.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()
	OS.low_processor_usage_mode = false


func _process(_delta: float) -> bool:
	if _main == null:
		return true
	if _index == -1:
		Settings.graphics = _graphics
		Settings.fullscreen = false
		Settings.apply()
		_set_hour(_hour)
	if not _ui:
		for child in _main.get_children():
			if child is CanvasLayer:
				child.visible = false
		for layer in _main.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
	_wait -= 1
	if _wait > 0:
		return false
	if _index >= 0:
		var image := root.get_viewport().get_texture().get_image()
		# The same picture as last time means the window didn't draw: wait and try again.
		var picture_hash := hash(image.get_data())
		if picture_hash == _last_hash and _retries < 5:
			_retries += 1
			DisplayServer.window_move_to_foreground()
			_wait = 30
			return false
		if picture_hash == _last_hash:
			print("WARNING: the picture didn't change (is the window hidden?)")
		_last_hash = picture_hash
		_retries = 0
		var name: String = _names[_index]
		var path := _out.path_join("%s_g%d.png" % [name, _graphics])
		image.save_png(path)
		print("saved ", ProjectSettings.globalize_path(path))
	_index += 1
	if _index >= _names.size():
		print("RESULT: DONE")
		return true
	var spot: Array = SPOTS.get(_names[_index], [])
	if spot.is_empty():
		print("unknown spot ", _names[_index])
		_wait = 1
		return false
	var eye: Vector3 = spot[0]
	var target: Vector3 = spot[1]
	# The rider stands a little behind the camera, so things that only move near the rider
	# (people, animals) are awake, but the rider is out of the picture.
	var bike := _main.get_node("Bike") as Node3D
	var back := (eye - target)
	back.y = 0.0
	bike.global_position = Vector3(eye.x, 0.1, eye.z) + back.normalized() * 4.0
	if bike is RigidBody3D:
		(bike as RigidBody3D).linear_velocity = Vector3.ZERO
	_camera.global_position = eye
	_camera.look_at(target)
	_camera.make_current()
	_wait = 45
	return false


func _set_hour(hour: float) -> void:
	var state := root.get_node("GameState")
	var share := (hour - GameConfig.SHIFT_START_HOUR) / (GameConfig.SHIFT_END_HOUR - GameConfig.SHIFT_START_HOUR)
	state.shift_time_left = GameConfig.SHIFT_LENGTH * (1.0 - share)
