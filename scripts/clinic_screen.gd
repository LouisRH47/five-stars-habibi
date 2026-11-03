extends CanvasLayer
## After a big crash: the screen fades to black, you wake up at the Al Sarab Clinic and the
## bills pop up (PRD "Crashes, bills and insurance"). Press E (or click OK) to carry on:
## the bike goes back to the start and the screen fades back in. The game is paused while
## this shows. GameState.big_crash() does the money; this only shows it.
## Session 13 ends the shift after a big crash.

## The bike: we listen for its big crashes and put it back at the start afterwards.
@export var bike: Node3D

const PANEL_COLOUR := Color(0.05882353, 0.1254902, 0.14901961, 0.95)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const SOFT := Color(0.79, 0.89, 0.92, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)

## Sent when you close the clinic screen (the ShiftManager then ends the shift).
signal closed

## True while the clinic screen is up.
var showing := false
## The last bills shown (for the smoke test).
var last_bills: Dictionary = {}

var _fade: ColorRect
var _panel: PanelContainer
var _lines: Label
var _total: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # works while the game is paused
	layer = 20
	_build()
	if bike != null:
		bike.crashed.connect(_on_crashed)


func _unhandled_input(event: InputEvent) -> void:
	if showing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close()


## Shows the clinic with these bills (fades out first, unless instantly is true).
func open(bills: Dictionary, instantly := false) -> void:
	last_bills = bills
	showing = true
	get_tree().paused = true
	_fill(bills)
	if instantly:
		_fade.color.a = 1.0
		_panel.visible = true
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, GameConfig.CRASH_FADE_TIME)
	tween.tween_callback(func(): _panel.visible = true)


## Back to riding: bike at the start, fade back in, game runs again.
func close() -> void:
	if not showing:
		return
	showing = false
	_panel.visible = false
	if bike != null:
		bike.reset_to_start()
	get_tree().paused = false
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, GameConfig.CRASH_FADE_TIME)
	closed.emit()


func _on_crashed(big: bool) -> void:
	if big and not showing:
		open(GameState.big_crash())


func _fill(bills: Dictionary) -> void:
	var text := "Hospital bill:  %d Dh\nBike repair:  %d Dh\n" % [bills["hospital"], bills["repair"]]
	if bills["lost_order"]:
		text += "\nYour order was cancelled (0 stars, no pay).\n"
	if bills["boss"]:
		text += "\nMessage from your boss:\n\"Don't worry, Snackaroo pays this one. Ride safe!\"\n"
	elif bills["insured"]:
		text += "\nYour insurance pays the rest.\n"
	else:
		text += "\nNo insurance, so you pay it all.\n"
	_lines.text = text
	_total.text = "You pay:  %d Dh" % bills["paid"]


func _build() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOUR
	style.border_color = TEAL
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(32)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	_panel.add_child(rows)
	var clinic_title := _label("Al Sarab Clinic", 36, ORANGE)
	clinic_title.theme_type_variation = &"Heading"
	rows.add_child(clinic_title)
	rows.add_child(_label("Ouch! You had a big crash. The nurses patched you up.", 18, SOFT))
	_lines = _label("", 20, TEXT)
	rows.add_child(_lines)
	_total = _label("", 28, TEXT)
	rows.add_child(_total)
	var ok := Button.new()
	ok.text = "OK, back to work  (E)"
	ok.add_theme_font_size_override("font_size", 20)
	ok.pressed.connect(close)
	rows.add_child(ok)


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label
