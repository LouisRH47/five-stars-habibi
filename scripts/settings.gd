class_name Settings
## Game settings: fullscreen (Session 15), the volume sliders (Session 16) and
## Graphics Low / Medium / High (Session 28) and Resolution (Session 67): window size on
## desktop and render scale (50, 75, 100%) everywhere.
## Kept in their own small file (user://settings.cfg), so "New game" doesn't reset them.
## The main menu and the pause menu both show these with scripts/settings_panel.gd.
## Sounds go through 3 audio buses (made here if missing): Music, Effects and Ambience,
## all feeding the Master bus.

const PATH := "user://settings.cfg"
## The volume sliders, in the order they show. Each is 0.0 (silent) to 1.0 (full).
const BUSES := ["Master", "Music", "Effects", "Ambience"]

## The Graphics setting names (Session 28). Settings.graphics is 0, 1 or 2.
const GRAPHICS_NAMES := ["Low", "Medium", "High"]

## Session 67: window sizes you can pick on desktop. 0 "Auto" leaves the window as it is.
const WINDOW_SIZES := [Vector2i.ZERO, Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
## Session 67: render scale choices in percent. Lower draws the 3D world at fewer pixels
## (faster, a bit softer); menus and text stay sharp.
const RENDER_SCALES := [50, 75, 100]

static var fullscreen := false
## Index into WINDOW_SIZES (Session 67).
static var window_size := 0
## 50, 75 or 100 (Session 67). The browser starts at 75, like before.
static var render_scale := 75 if OS.has_feature("web") else 100
## 0 Low (browser default), 1 Medium (desktop default), 2 High. scripts/sun_cycle.gd does what each one means.
static var graphics := 0 if OS.has_feature("web") else 1
static var volumes := {"Master": 0.8, "Music": 0.6, "Effects": 0.8, "Ambience": 0.5}
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
		window_size = clampi(file.get_value("video", "window_size", window_size), 0, WINDOW_SIZES.size() - 1)
		var scale: int = file.get_value("video", "render_scale", render_scale)
		render_scale = scale if RENDER_SCALES.has(scale) else render_scale
		for bus in BUSES:
			volumes[bus] = clampf(file.get_value("audio", bus, volumes[bus]), 0.0, 1.0)
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
	file.set_value("video", "window_size", window_size)
	file.set_value("video", "render_scale", render_scale)
	for bus in BUSES:
		file.set_value("audio", bus, volumes[bus])
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
		tree.root.scaling_3d_scale = render_scale / 100.0
		tree.call_group("graphics", "apply_graphics")
	if DisplayServer.get_name() == "headless":
		return  # no window in the smoke test
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	apply_window_size()


## True where you can pick a window size: desktop only (not the browser or phones).
static func can_pick_window_size() -> bool:
	return not OS.has_feature("web") and not OS.has_feature("mobile")


## Session 67: sets the window to the picked size (when not fullscreen) and centres it.
static func apply_window_size() -> void:
	if not can_pick_window_size() or fullscreen or window_size <= 0:
		return
	var wanted: Vector2i = WINDOW_SIZES[window_size]
	var screen := DisplayServer.window_get_current_screen()
	var room := DisplayServer.screen_get_usable_rect(screen)
	wanted = Vector2i(mini(wanted.x, room.size.x), mini(wanted.y, room.size.y))
	if DisplayServer.window_get_size() != wanted:
		DisplayServer.window_set_size(wanted)
		DisplayServer.window_set_position(room.position + (room.size - wanted) / 2)


## The names shown in the Window size list, e.g. "1600 x 900".
static func window_size_names() -> Array:
	var names: Array = []
	for size: Vector2i in WINDOW_SIZES:
		names.append("Auto" if size == Vector2i.ZERO else "%d x %d" % [size.x, size.y])
	return names


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
