class_name RideWind
extends Node
## Speed-shaped wind complements the tyre sound. It uses the Settings Effects bus.

var bike: Node3D
var intensity := 0.0
var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Silence the loop immediately when a menu pauses play.
	Settings.load_once()
	_player = AudioStreamPlayer.new()
	_player.name = "WindAudio"
	_player.stream = Sounds.looping("res://assets/audio/wind_loop.wav")
	_player.bus = "Effects"
	_player.volume_db = -80.0
	add_child(_player)


func _process(delta: float) -> void:
	var kmh := absf(float(bike.get("speed"))) * 3.6 if is_instance_valid(bike) else 0.0
	var allowed: bool = is_instance_valid(bike) and not get_tree().paused and bike.get("parked") != true \
			and bike.get("wrecked") != true and float(bike.get("fallen_left")) <= 0.0 and kmh > GameConfig.WIND_START_KMH
	if not allowed:
		intensity = 0.0
		_player.volume_db = -80.0
		_player.stop()
		return
	var wanted := clampf((kmh - GameConfig.WIND_START_KMH) / (GameConfig.BIKE_SPRINT_MAX_SPEED_KMH - GameConfig.WIND_START_KMH), 0.0, 1.0)
	intensity = lerpf(intensity, wanted, 1.0 - exp(-GameConfig.WIND_SMOOTHING * delta))
	var sprint: bool = bike.get("sprinting") == true or bike.get("boost_active") == true
	_player.volume_db = lerpf(GameConfig.WIND_VOLUME_DB.x, GameConfig.WIND_VOLUME_DB.y, intensity) + (GameConfig.WIND_SPRINT_GAIN_DB if sprint else 0.0)
	_player.pitch_scale = lerpf(GameConfig.WIND_PITCH.x, GameConfig.WIND_PITCH.y, intensity)
	if not _player.playing and Settings.can_play_audio():
		_player.play()


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
		_player.stream = null
