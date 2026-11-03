class_name Sounds
extends Node
## The game's sound effects and background ambience (Session 16). It listens to what
## happens and plays the right sound:
##   new order: phone ping        pick up: bike bell     delivered: cash register
##   crash: crash                 speed bump: thump      riding: tyre noise (louder when faster)
##   B: the bike bell rings (Session 29)
##   all the time: birds and distant traffic (ambience)
## The sounds are made by tools/make_sounds.py. Effects play on the Effects bus, the
## ambience on the Ambience bus, so the sliders in Settings control them.

## The bike: for crashes, speed bumps and the tyre noise.
@export var bike: Node3D

const FILES := {
	"ping": "res://assets/audio/ping.wav",
	"bell": "res://assets/audio/bell.wav",
	"cash": "res://assets/audio/cash.wav",
	"crash": "res://assets/audio/crash.wav",
	"bump": "res://assets/audio/bump.wav",
	"ring": "res://assets/audio/ring.wav",  # the bike bell (B, Session 29)
}
const ROLL := "res://assets/audio/roll_loop.wav"
const AMBIENCE := "res://assets/audio/ambience_loop.wav"
const ROLL_LOUDEST_DB := -6.0   # tyre noise at top speed
const ROLL_QUIETEST_DB := -40.0 # tyre noise when crawling

## The name of the last sound played (the smoke test checks it).
var last_played := ""

var _players: Dictionary = {}
var _roll: AudioStreamPlayer
var _ambience: AudioStreamPlayer


## A sound file set to loop forever (for the music, tyres and ambience).
static func looping(path: String) -> AudioStream:
	var stream := load(path) as AudioStreamWAV
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	return stream


func _ready() -> void:
	Settings.load_once()
	for key in FILES:
		var player := AudioStreamPlayer.new()
		player.stream = load(FILES[key])
		player.bus = "Effects"
		add_child(player)
		_players[key] = player
	_roll = _loop_player(ROLL, "Effects")
	_roll.volume_db = ROLL_QUIETEST_DB
	_ambience = _loop_player(AMBIENCE, "Ambience")
	GameState.order_offered.connect(func(_order): play("ping"))
	GameState.order_delivered.connect(func(_order): play("cash"))
	GameState.order_stage_changed.connect(_on_stage_changed)
	if bike != null:
		bike.crashed.connect(func(_big): play("crash"))
		bike.went_over_bump.connect(func(_strength): play("bump"))
		bike.bell_rung.connect(func(): play("ring"))


func _process(_delta: float) -> void:
	if bike == null:
		return
	var fast := clampf(absf(bike.speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
	_roll.volume_db = lerpf(ROLL_QUIETEST_DB, ROLL_LOUDEST_DB, fast) if fast > 0.02 else -80.0
	_roll.pitch_scale = lerpf(0.8, 1.25, fast)


## Plays one of the sounds in FILES by name.
func play(key: String) -> void:
	if _players.has(key):
		if Settings.can_play_audio():
			_players[key].play()
		last_played = key


func _on_stage_changed(stage: int) -> void:
	if stage == GameState.Stage.TO_VILLA:
		play("bell")  # ding ding: you've got the food


func _loop_player(path: String, bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = looping(path)
	player.bus = bus
	add_child(player)
	if Settings.can_play_audio():
		player.play()
	return player


func _exit_tree() -> void:
	# Stop cleanly when leaving the map or closing the game.
	for player in get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
