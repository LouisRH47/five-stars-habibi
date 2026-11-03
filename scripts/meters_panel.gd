extends CanvasLayer
## The meters panel (top left): time, freshness and damage bars while you carry food.
## Each bar is green, orange or red (PRD bands). It only shows things: the values live
## in GameState and scripts/meters.gd changes them.

const GREEN := Color(0.36, 0.8, 0.45, 1)
const ORANGE := Color(0.95, 0.6, 0.18, 1)
const RED := Color(0.9, 0.25, 0.22, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const SOFT := Color(0.79, 0.89, 0.92, 1)

var _bars: Dictionary = {}    # "time" -> ProgressBar
var _fills: Dictionary = {}   # "time" -> StyleBoxFlat (its colour changes)
var _values: Dictionary = {}  # "time" -> Label

@onready var _panel: Control = $Panel
@onready var _rows: VBoxContainer = $Panel/Margin/Rows
@onready var _title: Label = $Panel/Margin/Rows/Title


func _ready() -> void:
	for key in ["time", "freshness", "damage"]:
		_add_row(key)
	GameState.meters_changed.connect(_refresh)
	GameState.order_stage_changed.connect(func(_stage): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	if _panel.visible:
		var left := maxf(GameState.target_time - GameState.ride_time, 0.0)
		_values["time"].text = "%d:%02d" % [int(left) / 60, int(left) % 60]


func _refresh() -> void:
	_panel.visible = GameState.stage == GameState.Stage.TO_VILLA and GameState.current_order != null
	if not _panel.visible:
		return
	_title.text = GameState.current_order.food.capitalize()
	_show("time", GameState.meter_time)
	_show("freshness", GameState.meter_freshness)
	_show("damage", GameState.meter_damage)


func _show(key: String, value: float) -> void:
	_bars[key].value = value
	match Meters.band(value):
		Meters.Band.GREEN:
			_fills[key].bg_color = GREEN
		Meters.Band.ORANGE:
			_fills[key].bg_color = ORANGE
		_:
			_fills[key].bg_color = RED
	if key != "time":
		_values[key].text = "%d%%" % roundi(value)


func _add_row(key: String) -> void:
	var head := HBoxContainer.new()
	var name_label := _label(key.to_upper(), 13, SOFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := _label("", 15, TEXT)
	value.theme_type_variation = &"BigNumber"
	head.add_child(name_label)
	head.add_child(value)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.18, 0.29, 0.32, 1)
	back.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GREEN
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	_rows.add_child(head)
	_rows.add_child(bar)
	_bars[key] = bar
	_fills[key] = fill
	_values[key] = value


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
