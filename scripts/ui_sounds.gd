extends Node
## Session 66: UI sounds for menus and the HUD (works on the start screen and while paused).
## Session 71 makes the files with tools/make_sounds.py. A missing file just stays quiet.

const KEYS := ["ui_hover", "ui_click", "ui_open", "ui_close", "tick", "meter_warn",
		"level_up", "stamp", "whoosh"]
var play_counts: Dictionary = {}
var _players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.load_once()
	for key in KEYS:
		var path := "res://assets/audio/%s.wav" % key
		if not ResourceLoader.exists(path):
			continue
		var p := AudioStreamPlayer.new()
		p.stream = load(path)
		p.bus = "Effects"
		add_child(p)
		_players[key] = p

func play(key: String, pitch := 1.0) -> void:
	play_counts[key] = play_counts.get(key, 0) + 1
	if _players.has(key) and Settings.can_play_audio():
		_players[key].pitch_scale = pitch
		_players[key].play()
