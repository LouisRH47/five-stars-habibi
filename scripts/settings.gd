class_name Settings
## Game settings: fullscreen (Session 15), the volume sliders (Session 16) and
## Graphics Low / Medium / High (Session 28).
## Kept in their own small file (user://settings.cfg), so "New game" doesn't reset them.
## The main menu and the pause menu both show these with scripts/settings_panel.gd.
## Sounds go through 3 audio buses (made here if missing): Music, Effects and Ambience,
## all feeding the Master bus.

const PATH := "user://settings.cfg"
## The volume sliders, in the order they show. Each is 0.0 (silent) to 1.0 (full).
const BUSES := ["Master", "Music", "Effects", "Ambience"]

## The Graphics setting names (Session 28). Settings.graphics is 0, 1 or 2.
const GRAPHICS_NAMES := ["Low", "Medium", "High"]

static var fullscreen := false
## 0 Low (browser default), 1 Medium (desktop default), 2 High. scripts/sun_cycle.gd does what each one means.
static var graphics := 0 if OS.has_feature("web") else 1
static var volumes := {"Master": 0.8, "Music": 0.6, "Effects": 0.8, "Ambience": 0.5}
## Session 66 (polish pass): accessibility settings, saved in the "access" section.
## Text size makes every screen bigger (the window's content scale). Session 71 shows them in Settings.
const TEXT_SCALES := [1.0, 1.15, 1.3]
static var text_size := 0            # 0 = 100%, 1 = 115%, 2 = 130%
static var colour_assist := false    # meter colours that work for colour-blind players (UiPalette.band_colour)
static var reduce_motion := false    # "Less motion": no shakes, quicker pops (UiJuice)
static var minimap_north_up := false # the mini-map keeps north up instead of turning with you
static var outlines := false         # dark outlines round things (Session 67, off by default)
static var _loaded := false


## Reads the settings file once and applies it. Safe to call many times.
static func load_once() -> void:
	if _loaded:
		return
	_loaded = true
	make_buses()
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		fullscreen = file.get_value("video", "fullscreen", false)
		graphics = clampi(file.get_value("video", "graphics", graphics), 0, GRAPHICS_NAMES.size() - 1)
		for bus in BUSES:
			volumes[bus] = clampf(file.get_value("audio", bus, volumes[bus]), 0.0, 1.0)
		text_size = clampi(int(file.get_value("access", "text_size", text_size)), 0, TEXT_SCALES.size() - 1)
		colour_assist = bool(file.get_value("access", "colour_assist", colour_assist))
		reduce_motion = bool(file.get_value("access", "reduce_motion", reduce_motion))
		minimap_north_up = bool(file.get_value("access", "minimap_north_up", minimap_north_up))
		outlines = bool(file.get_value("access", "outlines", outlines))
	else:
		# First start (Session 52): pick Low, Medium or High for this computer.
		graphics = detect_graphics()
	if OS.has_feature("web"):
		fullscreen = false
	apply()


## Saves the settings and applies them.
static func save() -> void:
	var file := ConfigFile.new()
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "graphics", graphics)
	for bus in BUSES:
		file.set_value("audio", bus, volumes[bus])
	file.set_value("access", "text_size", text_size)
	file.set_value("access", "colour_assist", colour_assist)
	file.set_value("access", "reduce_motion", reduce_motion)
	file.set_value("access", "minimap_north_up", minimap_north_up)
	file.set_value("access", "outlines", outlines)
	file.save(PATH)
	apply()


## Guesses the best Graphics setting for this computer (Session 52). Settings can change it.
## Browser and phones/tablets: Low. Apple M-series Macs and computers with their own
## graphics card: High. Everything else: Medium. The headless tests always get Medium.
static func detect_graphics() -> int:
	if OS.has_feature("web") or OS.has_feature("mobile"):
		return 0
	if DisplayServer.get_name() == "headless":
		return 1
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	var kind := RenderingServer.get_video_adapter_type()
	if kind == RenderingDevice.DEVICE_TYPE_CPU:
		return 0
	if kind == RenderingDevice.DEVICE_TYPE_DISCRETE_GPU or adapter.contains("apple m"):
		return 2
	return 1


## Smooths the jagged edges for the Graphics setting (Session 52): Low uses FXAA (cheap),
## Medium MSAA 4x, High MSAA 4x plus TAA. TAA only works on the desktop renderer.
static func apply_anti_aliasing(viewport: Viewport) -> void:
	if viewport == null:
		return
	var desktop := not OS.has_feature("web")
	viewport.msaa_3d = Viewport.MSAA_4X if graphics >= 1 else Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if graphics == 0 else Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = graphics == 2 and desktop


static func apply() -> void:
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volumes[bus], 0.0001)))
			AudioServer.set_bus_mute(index, volumes[bus] <= 0.001)
	# Tell the map that's running (if any) to switch its graphics extras straight away.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		apply_anti_aliasing(tree.root)
		tree.call_group("graphics", "apply_graphics")
	if DisplayServer.get_name() == "headless":
		return  # no window in the smoke test
	if tree != null:
		apply_text_size(tree.root)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## Text size (Session 66): 100%, 115% or 130% of the normal size, as the window's content scale.
## The game window is 1920x1080 "canvas_items", so this makes all text and screens bigger together.
static func text_scale() -> float:
	return TEXT_SCALES[clampi(text_size, 0, TEXT_SCALES.size() - 1)]


static func apply_text_size(window: Window) -> void:
	if window != null:
		window.content_scale_factor = text_scale()


## False in the headless smoke test: there are no speakers, and sounds still playing when
## the test quits make Godot print "leaked" warnings. Everything else about sound still runs.
static func can_play_audio() -> bool:
	return DisplayServer.get_name() != "headless"


## Adds the Music, Effects and Ambience buses (if they're not there yet).
static func make_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
