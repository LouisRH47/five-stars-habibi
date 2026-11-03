extends Node
## The background music (Session 16): a chill loop in maqam Hijaz, made for this game by
## tools/make_sounds.py (see CREDITS.md). This is an autoload called Music, so the music
## keeps playing when you go from the menu to the game. It plays on the Music bus, so the
## Music volume slider in Settings controls it.

const TRACK := "res://assets/audio/music_loop.wav"

var player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps playing while the game is paused
	Settings.load_once()
	player = AudioStreamPlayer.new()
	var stream := load(TRACK) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.bus = "Music"
	add_child(player)
	if Settings.can_play_audio():
		player.play()


func _exit_tree() -> void:
	# Stop cleanly when the game closes, so nothing is left playing.
	player.stop()
	player.stream = null
