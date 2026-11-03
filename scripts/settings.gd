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
## 0 Low, 1 Medium (the default), 2 High. scripts/sun_cycle.gd does what each one means.
static var graphics := 1
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
		for bus in BUSES:
			volumes[bus] = clampf(file.get_value("audio", bus, volumes[bus]), 0.0, 1.0)
	apply()


## Saves the settings and applies them.
static func save() -> void:
	var file := ConfigFile.new()
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "graphics", graphics)
	for bus in BUSES:
		file.set_value("audio", bus, volumes[bus])
	file.save(PATH)
	apply()


static func apply() -> void:
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volumes[bus], 0.0001)))
			AudioServer.set_bus_mute(index, volumes[bus] <= 0.001)
	# Tell the map that's running (if any) to switch its graphics extras straight away.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.call_group("graphics", "apply_graphics")
	if DisplayServer.get_name() == "headless":
		return  # no window in the smoke test
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


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
