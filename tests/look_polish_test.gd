extends SceneTree
## Session 67 (polish pass): sky, light and colour. Run:
## Godot --path . --headless -s tests/look_polish_test.gd
## Checks: texture filtering and debanding per Graphics setting, the cartoon sky (clouds per
## level, colours by the hour, the old sky back with the switch off), the colour grade LUTs
## (neutral changes nothing, golden is warm), the vignette under the HUD, SSIL only on High,
## the light shafts (at most 24, none on Low, every one inside its room), outlines off by
## default, no cloud shadows by default.

# Loaded when the test runs (not preloaded): these scripts use the GameState autoload.
var SunCycle: Script
var SkyLook: Script
var LightShafts: Script

var _failures := 0
var _count := 0


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://look_polish_test_save.json"
	_run.call_deferred()


func _run() -> void:
	SunCycle = load("res://scripts/sun_cycle.gd")
	SkyLook = load("res://scripts/sky_look.gd")
	LightShafts = load("res://scripts/light_shafts.gd")
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 6:
		await process_frame
	var hooks := root.get_node("PolishHooks")
	_check("the polish hooks ran look_extras.gd", "res://scripts/polish/look_extras.gd" in hooks.attached)
	var cycle: Node = world.get_node("SunCycle")
	var env: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var saved_level: int = Settings.graphics

	# L1 + L5: texture filtering, debanding and SSIL per Graphics setting.
	for level in 3:
		Settings.graphics = level
		cycle.apply_graphics()
		var view := cycle.get_viewport()
		_check("Graphics %d: texture filtering %d (want %d)" % [level, view.anisotropic_filtering_level, GameConfig.ANISO_LEVEL[level]],
				view.anisotropic_filtering_level == GameConfig.ANISO_LEVEL[level])
		_check("Graphics %d: debanding %s" % [level, view.use_debanding], view.use_debanding == (level >= 1))
		_check("Graphics %d: bounce light (SSIL) %s, only on High" % [level, env.ssil_enabled], env.ssil_enabled == (level == 2))
	_check("16x filtering on Medium and High, 4x on Low", GameConfig.ANISO_LEVEL[0] == Viewport.ANISOTROPY_4X
			and GameConfig.ANISO_LEVEL[1] == Viewport.ANISOTROPY_16X and GameConfig.ANISO_LEVEL[2] == Viewport.ANISOTROPY_16X)

	# L2: the cartoon sky.
	var sky_mat := env.sky.sky_material as ShaderMaterial
	_check("the sky is our cartoon sky shader", sky_mat != null and sky_mat.shader == SkyLook.SHADER)
	_check("the old sky is kept for the switch", env.sky.get_meta("old_sky", null) is ProceduralSkyMaterial)
	if sky_mat != null:
		for level in 3:
			Settings.graphics = level
			cycle.apply_graphics()
			var on: bool = sky_mat.get_shader_parameter("clouds_on")
			_check("Graphics %d: clouds %s (none on Low)" % [level, on], on == (level >= 1))
		cycle._sky_hour = -100.0
		cycle.apply_hour(8.0)
		var top: Color = sky_mat.get_shader_parameter("top_color")
		var morning: Color = sky_mat.get_shader_parameter("cloud_light")
		var shift8: Vector2 = sky_mat.get_shader_parameter("cloud_shift")
		_check("the sky colours come from LIGHT_KEYS at 08:00", top.is_equal_approx(GameConfig.LIGHT_KEYS[0]["top"]))
		cycle._sky_hour = -100.0
		cycle.apply_hour(12.5)
		var noon: Color = sky_mat.get_shader_parameter("cloud_light")
		var shift12: Vector2 = sky_mat.get_shader_parameter("cloud_shift")
		cycle._sky_hour = -100.0
		cycle.apply_hour(17.5)
		var evening: Color = sky_mat.get_shader_parameter("cloud_light")
		var evening_shade: Color = sky_mat.get_shader_parameter("cloud_shade")
		_check("clouds are peach in the morning (%s)" % morning, morning.r - morning.b > 0.12)
		_check("clouds are white at noon (%s)" % noon, noon.r - noon.b < 0.03 and noon.b > 0.95)
		_check("clouds are gold with pink bottoms at sunset (%s, %s)" % [evening, evening_shade],
				evening.r - evening.b > 0.15 and evening_shade.r > evening_shade.g + 0.15)
		_check("clouds drift with the clock", shift12.distance_to(shift8) > 0.2)
		# The switch off: the old sky comes back, and on again.
		cycle._use_sky_look(false)
		_check("SKY_STYLIZED off brings the old sky back", env.sky.sky_material is ProceduralSkyMaterial)
		cycle._use_sky_look(true)
		_check("and on again: the cartoon sky", env.sky.sky_material == sky_mat)

	# L3: the colour grade.
	var lut := env.adjustment_color_correction as Texture3D
	_check("the colour grade is on (%s)" % GameConfig.LOOK_LUT, (lut != null) == (GameConfig.LOOK_LUT != "neutral"))
	if lut != null:
		_check("the LUT is a 33 x 33 x 33 cube", lut.get_width() == 33 and lut.get_height() == 33 and lut.get_depth() == 33)
		_check("the LUT is the chosen one", lut.resource_path.contains(GameConfig.LOOK_LUT))
	_check("\"neutral\" means no grade", SunCycle.lut_for("neutral") == null and SunCycle.lut_for("golden") != null
			and SunCycle.lut_for("fresh") != null)
	var neutral := _lut_image("neutral")
	var worst := 0.0
	for v in [0.0, 8.5 / 33.0, 16.5 / 33.0, 24.5 / 33.0, 1.0]:
		var c := _lut_at(neutral, Color(v, 1.0 - v, v))
		worst = maxf(worst, maxf(absf(c.r - v), maxf(absf(c.g - (1.0 - v)), absf(c.b - v))))
	_check("the neutral LUT changes nothing (worst %.3f)" % worst, worst < 2.0 / 255.0)
	var golden := _lut_image("golden")
	var bright := _lut_at(golden, Color(0.85, 0.85, 0.85))
	var shade := _lut_at(golden, Color(0.15, 0.15, 0.15))
	_check("golden: sunny parts warmer (%s)" % bright, bright.r > bright.b + 0.04)
	_check("golden: shade a little teal (%s)" % shade, shade.b > shade.r + 0.01 and shade.g > shade.r)
	_check("golden: black stays black, white stays white", _lut_at(golden, Color.BLACK).v < 0.02
			and _lut_at(golden, Color.WHITE).v > 0.95)

	# L4: the vignette.
	var vignette := world.get_node_or_null("Vignette") as CanvasLayer
	_check("the vignette layer is there", vignette != null)
	if vignette != null:
		var lowest_other := 1000
		for layer in world.find_children("*", "CanvasLayer", true, false):
			if layer != vignette:
				lowest_other = mini(lowest_other, (layer as CanvasLayer).layer)
		_check("the vignette is under the HUD and menus (layer %d, lowest other %d)" % [vignette.layer, lowest_other],
				vignette.layer < lowest_other and vignette.layer < 0)
		var rect := vignette.get_child(0) as ColorRect
		_check("the vignette lets clicks through", rect.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		_check("its strength comes from GameConfig", is_equal_approx(float((rect.material as ShaderMaterial).get_shader_parameter("strength")), GameConfig.VIGNETTE_STRENGTH))

	# L6: the light shafts.
	var shafts := world.get_node_or_null("LightShafts")
	_check("the light shafts are there", shafts != null)
	if shafts != null:
		var list: Array = shafts.shafts
		var rooms := LightShafts.find_rooms(world)
		_check("shafts in the shop rooms (%d shafts, %d rooms)" % [list.size(), rooms.size()], list.size() > 0 and list.size() <= GameConfig.SHAFT_MAX)
		Settings.graphics = 0
		Settings.apply()
		_check("no shafts on Low", not shafts.visible)
		for hour in [9.0, 12.0, 17.0]:
			Settings.graphics = 1
			Settings.apply()
			shafts._update(hour)
			var outside := ""
			for shaft: Dictionary in list:
				var room: Node3D = shaft["room"]
				var view: MeshInstance3D = shaft["view"]
				var size: Vector3 = room.get_meta("room_size")
				var box := AABB(Vector3(-size.x * 0.5, 0.0, -size.z * 0.5), size)
				var local := room.global_transform.affine_inverse() * view.global_transform
				for corner: Vector3 in view.get_meta("corners", []):
					if not box.grow(0.01).has_point(local * corner) and outside == "":
						outside = "%s %s" % [room.name, local * corner]
				var aabb := local * view.mesh.get_aabb()
				if not box.grow(0.01).encloses(aabb) and outside == "":
					outside = "%s box %s" % [room.name, aabb]
			_check("%02d:00: every shaft is inside its room %s" % [int(hour), outside], outside == "")
		_check("shafts are drawn on Medium", shafts.visible)
		_check("shafts strongest early and late, faint at noon", LightShafts.strength_at(8.5) > 0.9
				and LightShafts.strength_at(17.0) > 0.9 and LightShafts.strength_at(12.5) < 0.5)

	# L8 + L7: outlines off by default, cloud shadows off by default.
	var outlines := world.get_node_or_null("Outlines") as MeshInstance3D
	var outlines_were: bool = Settings.outlines
	Settings.outlines = false
	Settings.apply()
	_check("outlines are off by default", outlines != null and not outlines.visible)
	Settings.outlines = true
	Settings.apply()
	_check("the outlines setting turns them on", outlines != null and outlines.visible)
	Settings.outlines = outlines_were
	_check("no cloud shadows unless switched on", (world.get_node_or_null("CloudShadows") != null) == GameConfig.CLOUD_SHADOWS)

	Settings.graphics = saved_level
	Settings.apply()
	_finish()


## The source picture of a LUT (1089 x 33: 33 squares, one per amount of blue).
func _lut_image(look_name: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path("res://assets/luts/%s.png" % look_name))


## What the LUT does to a colour (nearest square, the same way Godot reads it: square i is
## for colours around (i + 0.5) / 33, and the end squares for 0 and 1).
func _lut_at(image: Image, c: Color) -> Color:
	var n := 33
	var r := clampi(int(c.r * n), 0, n - 1)
	var g := clampi(int(c.g * n), 0, n - 1)
	var b := clampi(int(c.b * n), 0, n - 1)
	return image.get_pixel(b * n + r, g)


func _check(label: String, ok: bool) -> void:
	_count += 1
	if ok:
		print("PASS: ", label)
	else:
		_failures += 1
		print("FAIL: ", label)


func _finish() -> void:
	print("%d checks, %d failed" % [_count, _failures])
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL"))
	quit(0 if _failures == 0 else 1)
