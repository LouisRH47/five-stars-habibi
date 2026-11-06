class_name CrashToast
extends CanvasLayer
## Session 87: the short message under the clock when you hit something, with the real
## speed at impact and the bill: "Bump! 9 km/h · -10 Dh", "You fell off! 17 km/h · -30 Dh",
## "Big crash! 31 km/h". Made by the HUD; listens to the bike's knocked and crashed signals.

const TEAL := Color(0.05882353, 0.29803923, 0.36078432, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const RED := Color(0.8, 0.25, 0.2, 1)

## The text showing now ("" when hidden). The tests read it.
var text := ""
var _label: Label
var _box: PanelContainer
var _style: StyleBoxFlat
var _shown_ms := 0


static func make(bike: Node) -> CrashToast:
	var toast := CrashToast.new()
	toast.name = "CrashToast"
	toast.layer = 5
	if bike != null and bike.has_signal("knocked"):
		bike.knocked.connect(toast.show_impact)
		bike.crashed.connect(func(_big: bool): toast.show_impact(bike.last_crash))
	return toast


func _ready() -> void:
	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.offset_top = 200
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.bg_color = TEAL
	_style.set_corner_radius_all(18)
	_style.content_margin_left = 26
	_style.content_margin_right = 26
	_style.content_margin_top = 10
	_style.content_margin_bottom = 10
	_box.add_theme_stylebox_override("panel", _style)
	_label = Label.new()
	_label.theme_type_variation = "Heading"
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_box.add_child(_label)
	add_child(_box)
	_box.visible = false


## Shows the message for one impact (a dictionary from CrashImpact.capture()).
func show_impact(impact: Dictionary) -> void:
	var kmh := roundi(float(impact.get("kmh", 0.0)))
	match str(impact.get("level", "")):
		"bump":
			text = "Bump! %d km/h · -%d Dh" % [kmh, int(impact.get("bill", GameConfig.CRASH_BUMP_BILL))]
			_style.bg_color = TEAL
		"fall":
			text = "You fell off! %d km/h · -%d Dh" % [kmh, int(impact.get("bill", GameConfig.CRASH_FALL_BILL))]
			_style.bg_color = ORANGE
		"big":
			text = "Big crash! %d km/h" % kmh
			_style.bg_color = RED
		_:
			return
	_label.text = text
	_box.visible = true
	_box.modulate.a = 1.0
	_shown_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if not _box.visible:
		return
	var age := (Time.get_ticks_msec() - _shown_ms) / 1000.0
	_box.modulate.a = clampf((GameConfig.CRASH_TOAST_SECONDS - age) / 0.4, 0.0, 1.0)
	if age >= GameConfig.CRASH_TOAST_SECONDS:
		_box.visible = false
		text = ""
