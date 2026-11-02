class_name Settings
## Game settings (Session 15): fullscreen for now; Session 16 adds the volume sliders.
## Kept in their own small file (user://settings.cfg), so "New game" doesn't reset them.
## The main menu and the pause menu both show these with scripts/settings_panel.gd.

const PATH := "user://settings.cfg"

static var fullscreen := false
static var _loaded := false


## Reads the settings file once and applies it. Safe to call many times.
static func load_once() -> void:
	if _loaded:
		return
	_loaded = true
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		fullscreen = file.get_value("video", "fullscreen", false)
	apply()


## Saves the settings and applies them.
static func save() -> void:
	var file := ConfigFile.new()
	file.set_value("video", "fullscreen", fullscreen)
	file.save(PATH)
	apply()


static func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return  # nothing to show in the smoke test
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
