extends SceneTree
## Takes screenshots of named spots in Wahat Al Shams, in a real window (not headless), so
## you see exactly what the game draws on this Mac with Forward+.
##   Godot --path . -s tests/screenshot_spots.gd -- out=/tmp/shots graphics=1 only=plaza,gym
## out: folder for the PNGs (default: user://screenshots). graphics: 0 Low, 1 Medium, 2 High.
## only: comma list of spot names (default: all). hour: time of day (default 11.0).
## ui=1 keeps the HUD and phone on screen. size=1280x800 sets the window size in pixels (the
## Steam Deck screen, Session 85). Your real save is never touched.

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
	# lane R2
	"r2_plaza_corner": [Vector3(-282, 2.4, -104), Vector3(-245, 1.0, -150)],
	"r2_buggy_park": [Vector3(-88, 3.5, -118), Vector3(-108, 0.5, -146)],
	"r2_buggy_park_top": [Vector3(-104, 45, -112), Vector3(-112, 0, -146)],
	"r2_mosque_park": [Vector3(-318, 3.0, -108), Vector3(-345, 0.5, -138)],
	"r2_car_park_c1c2_top": [Vector3(125, 70, -110), Vector3(125, 0, -160)],
	"r2_car_park_c2c3_top": [Vector3(276, 70, -110), Vector3(276, 0, -160)],
	"r2_car_park_c4w_top": [Vector3(-11, 70, 105), Vector3(-11, 0, 150)],
	"r2_car_park_c4c5_top": [Vector3(195, 70, 105), Vector3(195, 0, 150)],
	"r2_car_park_c5_top": [Vector3(398, 70, 110), Vector3(398, 0, 155)],
	"r2_stables_park_top": [Vector3(-155, 50, 135), Vector3(-155, 0, 172)],
	"r2_school_park_top": [Vector3(-365, 60, -5), Vector3(-365, 0, 32)],
	"r2_car_park_ground": [Vector3(195, 2.4, 196), Vector3(190, 0.5, 150)],
	"r2_parked_cars_close": [Vector3(193, 1.7, 176), Vector3(187.8, 0.5, 168)],
	# lane B (Session 78): every side of both shops, the arcade and the Plaza walls
	"pedal_point_front": [Vector3(-250, 3.0, -145), Vector3(-275, 4.0, -145)],
	"pedal_point_north": [Vector3(-275, 3.0, -175), Vector3(-275, 3.5, -145)],
	"pedal_point_south": [Vector3(-262, 3.0, -118), Vector3(-278, 3.5, -145)],
	"pedal_point_arcade": [Vector3(-264.6, 1.7, -153), Vector3(-264.6, 1.9, -138)],
	"dune_drip_front": [Vector3(-150, 3.0, -145), Vector3(-125, 4.0, -145)],
	"dune_drip_north": [Vector3(-138, 3.0, -172), Vector3(-123, 3.5, -145)],
	"dune_drip_south": [Vector3(-125, 3.0, -115), Vector3(-125, 3.5, -145)],
	"shops_top": [Vector3(-200, 45, -100), Vector3(-200, 0, -145)],
	"pedal_point_roof": [Vector3(-250, 22, -120), Vector3(-275, 6, -145)],
	"plaza_row_ends": [Vector3(-275, 2.4, -165), Vector3(-258, 5.0, -192)],
	"plaza_row_gap": [Vector3(-236, 2.0, -176), Vector3(-243, 3.0, -195)],
	# lane W
	"institute_pitch": [Vector3(-150, 6.0, -12), Vector3(-167, 0.5, -33)],
	"institute_pitch_top": [Vector3(-150, 35, -10), Vector3(-170, 0, -36)],
	"basketball_close": [Vector3(-125, 3.0, -16), Vector3(-137, 1.0, -28)],
	"pool_deck": [Vector3(193, 2.2, -14), Vector3(212, 0.3, -30)],
	"community_pool_top": [Vector3(215, 30, 5), Vector3(215, 0, -22)],
	"pond_west": [Vector3(70, 3.0, 32), Vector3(83, 0, 21)],
	"pond_east": [Vector3(200, 3.0, 33), Vector3(189, 0, 22)],
	# lane P (people close-ups: seats, swimmers, the lifeguard, faces and outfits)
	"p_institute_step_sitter": [Vector3(-190.0, 1.6, -20.0), Vector3(-193.9, 0.8, -23.0)],
	"p_cafe_sitter": [Vector3(-204.6, 1.3, -104.4), Vector3(-206.8, 0.5, -106.4)],
	"p_restaurant_diners": [Vector3(-149.0, 1.5, -100.5), Vector3(-151.2, 0.4, -101.7)],
	"p_majlis_sofa": [Vector3(-40.6, 1.3, -89.6), Vector3(-43.3, 0.4, -91.9)],
	"p_cluster_bench": [Vector3(-27.6, 1.2, -121.4), Vector3(-29.8, 0.5, -123.5)],
	"p_institute_laptops": [Vector3(-211.5, 2.4, -14.5), Vector3(-216.3, 1.0, -17.6)],
	"p_pool_wide": [Vector3(214.0, 3.0, -10.8), Vector3(214.0, 0.0, -24.0)],
	"p_pool_resting": [Vector3(215.0, 1.3, -10.9), Vector3(212.0, 0.3, -13.5)],
	"p_lifeguard": [Vector3(236.5, 2.4, -18.0), Vector3(240.9, 1.9, -22.0)],
	"p_lap_pool_lifeguard": [Vector3(178.0, 2.6, 21.5), Vector3(182.9, 1.6, 17.5)],
	"p_school_pools": [Vector3(-328.5, 5.0, 117.0), Vector3(-328.5, 0.0, 103.0)],
	# lane T
	"t_cluster_sign_close": [Vector3(53, 2.2, -48.5), Vector3(53, 2.15, -52.6)],
	"t_cluster_sign_far": [Vector3(50, 1.8, -32), Vector3(53, 2.15, -52.6)],
	"t_police_sign_close": [Vector3(42.4, 2.0, -51.5), Vector3(42.4, 2.0, -54.4)],
	"t_shop_sign": [Vector3(-174, 2.4, -178), Vector3(-174, 4.6, -195)],
	"t_shop_sign_far": [Vector3(-180, 2.0, -150), Vector3(-174, 4.6, -195)],
	"t_playground_close_top": [Vector3(93, 16, -46), Vector3(93, 0, -56)],
	"t_playground_down": [Vector3(93, 30, -49), Vector3(93, 0, -50)],
	"t_stables_sand": [Vector3(-196, 2.4, 98), Vector3(-226, 0.0, 118)],
	"t_red_track": [Vector3(-30, 1.8, -6.3), Vector3(10, 0.0, -6.3)],
	"t_footpath_pavers": [Vector3(44, 1.8, -75), Vector3(60, 0.0, -95)],
	"t_bin": [Vector3(55, 1.6, -42), Vector3(59, 0.5, -48)],
	"t_lawn_top": [Vector3(20, 30, 0), Vector3(40, 0, 20)],
	"p_chat_pair": [Vector3(32.6, 1.6, -58.6), Vector3(32.6, 1.3, -56.0)],
	"p_chat_pair_side": [Vector3(30.2, 1.7, -57.8), Vector3(32.6, 1.2, -56.0)],
	"p_stables_pair": [Vector3(-204.4, 1.6, 183.6), Vector3(-204.4, 1.3, 186.0)],
	# Session 90 (restaurants): the homes above the shops, benches, the pizza oven, waiters
	"s90_restaurant_row": [Vector3(-212, 3.0, -160), Vector3(-212, 7.5, -190)],
	"s90_row_join": [Vector3(-236, 6.0, -177), Vector3(-232, 8.2, -187)],
	"s90_row_north": [Vector3(-188, 3.0, -128), Vector3(-188, 7.5, -100)],
	"s90_benches": [Vector3(-246, 1.8, -178.5), Vector3(-252, 0.5, -185)],
	"s90_pizza_oven": [Vector3(-251.0, 1.8, -189.5), Vector3(-255.7, 2.6, -196.3)],
	"s90_waiter_pizza": [Vector3(-244, 2.0, -176), Vector3(-252, 0.9, -184)],
	"s90_waiter_sushi": [Vector3(-193, 2.0, -113), Vector3(-200, 0.9, -106)],
	"s90_homes_back": [Vector3(-215, 3.0, -222), Vector3(-205, 9.0, -203)],
	"s90_homes_roof": [Vector3(-222, 28, -168), Vector3(-208, 13, -195)],
	# Session 90 (layout): the paving to the roundabout, the buggy park, the gym, Majlis path
	"s90_paving_roundabout": [Vector3(-126, 2.2, -74), Vector3(-121, 0.8, -110)],
	"s90_paving_top": [Vector3(-108, 80, -72), Vector3(-118, 0, -114)],
	"s90_paving_corner_top": [Vector3(-126, 28, -64), Vector3(-136, 0, -86)],
	"s90_paving_walk_up": [Vector3(-137, 1.7, -72), Vector3(-134, 1.0, -100)],
	"s90_buggy_park": [Vector3(-90, 5.0, -112), Vector3(-108, 0.5, -146)],
	"s90_buggy_park_top": [Vector3(-98, 55, -118), Vector3(-108, 0, -150)],
	"s90_gym_road": [Vector3(115, 2.5, 50), Vector3(115, 2.5, 22)],
	"s90_gym_spine": [Vector3(115, 2.5, -4), Vector3(115, 2.5, 22)],
	"s90_gym_west": [Vector3(78, 3.0, 26), Vector3(115, 2.0, 22)],
	"s90_gym_top": [Vector3(115, 60, 62), Vector3(115, 0, 22)],
	"s90_gym_side_door": [Vector3(139, 2.2, 9), Vector3(129, 2.0, 18)],
	"s90_gym_inside": [Vector3(127.5, 1.9, 19.5), Vector3(112, 1.2, 20)],
	"s90_majlis_end": [Vector3(-31, 2.0, -53), Vector3(-31, 0, -40)],
	"s90_majlis_end_top": [Vector3(-31, 20, -58), Vector3(-31, 0, -42)],
	# Session 91: the C Institute inside and out, and its pond
	"s91_area_top": [Vector3(-170, 90, 30), Vector3(-170, 0, -5)],
	"s91_pond_top": [Vector3(-150, 45, 30), Vector3(-150, 0, 14)],
	"s91_institute_road": [Vector3(-163, 2.0, 3.0), Vector3(-212, 6.0, -30)],
	"s91_institute_front": [Vector3(-178, 2.2, -14), Vector3(-212, 6.0, -36)],
	"s91_institute_south": [Vector3(-222, 2.0, 1.5), Vector3(-218, 6.0, -12)],
	"s91_lobby_balcony": [Vector3(-200, 1.7, -38), Vector3(-225, 6.0, -33)],
	"s91_stairs": [Vector3(-203, 2.0, -45), Vector3(-215, 3.0, -51.5)],
	"s91_upstairs_offices": [Vector3(-223.4, 8.3, -34), Vector3(-230.5, 7.1, -24)],
	"s91_meeting_room": [Vector3(-227, 8.4, -19.8), Vector3(-230, 7.0, -14)],
	"s91_lift": [Vector3(-212, 1.8, -46.25), Vector3(-220.15, 3.0, -46.25)],
	"s91_lift_top": [Vector3(-224.5, 8.2, -41), Vector3(-221, 7.5, -46.25)],
	"s91_pond_road": [Vector3(-152, 2.2, 3.5), Vector3(-143, 0.3, 17)],
	"s91_pond_steps": [Vector3(-195.5, 2.6, -24), Vector3(-143, 0.3, 18)],
	"s91_pond_close": [Vector3(-136, 2.0, 10), Vector3(-144, 0.2, 18)],
	# Session 92 (people): the talking pair, the sunbeds, the workers, the courts
	"s92_chat_pair": [Vector3(34.6, 1.7, -58.6), Vector3(32.6, 1.1, -56.0)],
	"s92_sunbeds": [Vector3(208, 2.4, -38.5), Vector3(212, 0.4, -34.6)],
	"s92_sunbeds_close": [Vector3(208.4, 1.45, -31.4), Vector3(209.4, 0.7, -33.8)],
	"s92_sunbeds_side": [Vector3(213.0, 1.2, -32.4), Vector3(209.0, 0.6, -33.8)],
	"s92_workers": [Vector3(-366, 3.0, -76), Vector3(-372, 0.8, -55)],
	"s92_workers_phase2": [Vector3(-80, 3.0, 102), Vector3(-80, 0.8, 120)],
	"s92_workers_close": [Vector3(-366.5, 1.9, -69.5), Vector3(-371, 0.9, -61.5)],
	"s92_basketball": [Vector3(-133, 3.5, -15), Vector3(-133, 0.6, -27)],
	"s92_football": [Vector3(-156, 4.0, -20), Vector3(-167, 0.5, -33)],
}

## Session 92: spots that follow something that moves, or show the rider close up.
## name: [what, camera offset (metres, on the thing: +X its right, -Z its front), look height].
##   "mover:<outfit>": the first moving person on a route with that outfit (e.g. "buggy")
##   "look:<n>": the rider on the bike wearing look n (0 Classic, 1 Sporty, 2 Chill)
##   "stage:<who>:<action>": one person (see _stage_person) doing an action on the grass
const FOLLOW := {
	"s92_stage_jogger": ["stage:jogger:jog", Vector3(1.3, 1.0, -0.6), 0.85],
	"s92_stage_jogger_back": ["stage:jogger:jog", Vector3(-0.9, 1.0, 1.2), 0.85],
	"s92_stage_rider_jog": ["stage:rider0:jog", Vector3(1.3, 1.0, -0.6), 0.85],
	"s92_stage_rider_jog_back": ["stage:rider0:jog", Vector3(-0.9, 1.0, 1.2), 0.85],
	"s92_stage_kid_jog": ["stage:kid:jog", Vector3(1.0, 0.8, -0.6), 0.6],
	"s92_stage_worker": ["stage:worker:jog", Vector3(1.3, 1.0, -0.6), 0.85],
	"s92_stage_look0": ["stage:rider0:idle", Vector3(0.6, 1.5, -1.5), 1.1],
	"s92_stage_look1": ["stage:rider1:idle", Vector3(0.6, 1.5, -1.5), 1.1],
	"s92_stage_look2": ["stage:rider2:idle", Vector3(0.6, 1.5, -1.5), 1.1],
	"s92_stage_look0_back": ["stage:rider0:idle", Vector3(-0.5, 1.5, 1.5), 1.1],
	"s92_stage_look1_back": ["stage:rider1:idle", Vector3(-0.5, 1.5, 1.5), 1.1],
	"s92_stage_look2_back": ["stage:rider2:idle", Vector3(-0.5, 1.5, 1.5), 1.1],
	"s92_stage_shoes": ["stage:rider0:walk", Vector3(0.7, 0.45, -0.7), 0.1],
	"s92_stage_jogger_shoes": ["stage:jogger:jog", Vector3(0.8, 0.5, -0.6), 0.2],
	"s92_stage_crew": ["crew", Vector3(2.0, 3.5, 9.0), 0.8],
	"s92_stage_stroller": ["stroller", Vector3(1.4, 0.7, 0.3), 0.4],
	"s92_stage_shoes_frozen": ["stage:rider0:walk:freeze", Vector3(0.7, 0.45, -0.7), 0.1],
	"s92_stage_jogger_slow": ["stage:jogger:jog:slow", Vector3(1.3, 1.0, -0.6), 0.85],
	"s92_stroller": ["mover:buggy", Vector3(1.6, 1.5, -2.4), 0.8],
	"s92_stroller_side": ["mover:buggy", Vector3(2.4, 1.2, -0.4), 0.8],
	"s92_jogger": ["mover:sports", Vector3(1.6, 1.3, -1.4), 0.9],
	"s92_jogger_side": ["mover:sports", Vector3(2.2, 1.0, 0.0), 0.9],
	"s92_look0": ["look:0", Vector3(1.0, 1.7, -1.6), 1.3],
	"s92_look1": ["look:1", Vector3(1.0, 1.7, -1.6), 1.3],
	"s92_look2": ["look:2", Vector3(1.0, 1.7, -1.6), 1.3],
	"s92_look0_back": ["look:0", Vector3(-0.8, 1.8, 1.8), 1.3],
	"s92_look1_back": ["look:1", Vector3(-0.8, 1.8, 1.8), 1.3],
	"s92_look2_back": ["look:2", Vector3(-0.8, 1.8, 1.8), 1.3],
}

var _main: Node
var _out := "user://screenshots"
var _graphics := 1
var _size := Vector2i.ZERO
var _hour := 11.0
var _ui := false
var _names: Array = []
var _index := -1
var _wait := 0
var _camera: Camera3D
var _last_hash := 0
var _retries := 0
var _follow: Node3D  # Session 92: the thing the camera follows (FOLLOW spots)
var _follow_spot: Array = []
var _staged: Node3D  # Session 92: the person put on the grass for a "stage:" spot


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
			"size":
				var wh := parts[1].split("x")
				_size = Vector2i(int(wh[0]), int(wh[1]))
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
		if _size != Vector2i.ZERO:
			Settings.window_size = 0  # don't let the saved window size override it
		Settings.apply()
		if _size != Vector2i.ZERO:
			DisplayServer.window_set_size(_size)
		_set_hour(_hour)
	if not _ui:
		for child in _main.get_children():
			if child is CanvasLayer:
				child.visible = false
		for layer in _main.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
	_wait -= 1
	if _follow != null and is_instance_valid(_follow):
		_aim_follow()
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
	_follow = null
	if FOLLOW.has(_names[_index]):
		_start_follow(FOLLOW[_names[_index]])
		return false
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


## Session 92: finds what a FOLLOW spot looks at and keeps the camera on it.
func _start_follow(spot: Array) -> void:
	_follow_spot = spot
	var what: String = spot[0]
	var bike := _main.get_node("Bike") as Node3D
	if _staged != null:
		_staged.queue_free()
		_staged = null
	if what == "stroller":  # a stroller on its own, close up
		_staged = load("res://scripts/stroller.gd").make(0)
		_main.add_child(_staged)
		_staged.global_position = Vector3(100, 0.0, 5.9)  # on the red track
		bike.global_position = Vector3(20, 0.1, -40)
		_follow = _staged
	elif what == "crew":  # a building site crew on the grass
		_staged = Node3D.new()
		_main.add_child(_staged)
		_staged.global_position = Vector3(20, 0.0, -15)
		load("res://scripts/site_crew.gd").make(_staged, Vector3.ZERO, Vector3.RIGHT, 0)
		bike.global_position = Vector3(20, 0.1, -40)
		_follow = _staged
	elif what.begins_with("stage:"):
		var parts := what.split(":")
		_staged = _stage_person(parts[1])
		_main.add_child(_staged)
		_staged.global_position = Vector3(20, 0.0, -15)
		_staged.play(parts[2])
		if parts.size() > 3 and parts[3] == "slow":  # very slow (to compare with normal speed)
			_staged.play(parts[2], 0.05)
		elif parts.size() > 3:  # hold still part way through (to compare with playing)
			_staged.set_meta("freeze", true)
		bike.global_position = Vector3(20, 0.1, -40)
		_follow = _staged
	elif what.begins_with("look:"):
		var look := int(what.trim_prefix("look:"))
		var state := root.get_node("GameState")
		state.rider_look = look
		bike.global_position = Vector3(-30, 0.1, -6.3)
		bike.global_rotation = Vector3(0, PI * 0.5, 0)
		if bike is RigidBody3D:
			(bike as RigidBody3D).linear_velocity = Vector3.ZERO
		var rider := bike.find_child("Rider", true, false)
		if rider != null:
			load("res://scripts/rider_look.gd").apply(rider, look)
		_follow = bike.find_child("Model", true, false) as Node3D
	else:
		var outfit := what.trim_prefix("mover:")
		for mover: Node3D in _main.get_node("LifeBuilder").movers:
			if mover.person != null and str(mover.person.get_meta("outfit", "")) == outfit:
				_follow = mover
				break
		# The bike waits far off, so it is never in their way.
		bike.global_position = _follow.global_position + Vector3(0, 0.1, 30) if _follow != null else bike.global_position
	if _follow == null:
		print("nothing to follow for ", what)
		_wait = 1
		return
	_camera.make_current()
	_wait = 90
	_aim_follow()


func _aim_follow() -> void:
	if _staged != null and _staged.has_method("roll"):
		_staged.roll(0.02)
	if _staged != null and _staged.has_meta("freeze") and _wait == 30:
		_staged.player.pause()
	var offset: Vector3 = _follow_spot[1]
	var target := _follow.global_position + Vector3(0, float(_follow_spot[2]), 0)
	var eye := _follow.global_transform * offset
	eye.y = _follow.global_position.y + offset.y
	_camera.global_position = eye
	_camera.look_at(target)


## Session 92: makes the person for a "stage:" spot.
func _stage_person(who: String) -> Node3D:
	match who:
		"jogger": return load("res://scripts/place_looks.gd").jogger(0)
		"kid": return load("res://scripts/life_looks.gd").kid()
		"worker": return load("res://scripts/place_looks.gd").worker(0)
	var looks: Script = load("res://scripts/rider_look.gd")
	var rider: Node3D = looks.make_rider()
	looks.apply(rider, int(who.trim_prefix("rider")))
	return rider
