extends CanvasLayer
## On-screen panel (bottom right): speed in km/h and the sprint stamina bar.

## The bike to read speed and stamina from.
@export var bike: Node

const BAR_NORMAL := Color("7FD3E0")
const BAR_TIRED := Color("F59A2E")

@onready var _speed: Label = $Panel/Margin/Rows/SpeedRow/Speed
@onready var _bar: ProgressBar = $Panel/Margin/Rows/Stamina
@onready var _fill: StyleBoxFlat = _bar.get_theme_stylebox("fill").duplicate()


func _ready() -> void:
	_bar.max_value = GameConfig.STAMINA_MAX
	_bar.add_theme_stylebox_override("fill", _fill)


func _process(_delta: float) -> void:
	if bike == null:
		return
	_speed.text = str(roundi(absf(bike.speed) * 3.6))
	_bar.max_value = bike.stamina_capacity()
	_bar.value = bike.stamina
	var colour := BAR_TIRED if bike.tired else BAR_NORMAL
	if _fill.bg_color != colour:
		_fill.bg_color = colour
