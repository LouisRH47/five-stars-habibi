class_name TalkScreen
extends Node3D
## Looks pass Session 56: the big talk screen in the C Institute lobby. It changes during
## the shift with the game clock (GameState.clock_hours()):
##   until 12:00   "Welcome · أهلاً"
##   until 16:00   "Talk today · 4 PM"
##   from 16:00    "Solar cities of tomorrow" (the talk is on)
## The change times are GameConfig.TALK_SCREEN_TIMES.

var title: Label3D
var arabic: Label3D
var small: Label3D
## Which of the three slides is showing (0, 1, 2), -1 before the first update.
var slide := -1
var _check_left := 0.0


## Builds the labels. Reads from its +Z side.
func setup() -> void:
	arabic = SignText.make_label("", 120, Color(1, 0.86, 0.5), Color(0, 0, 0, 0), 0)
	arabic.position = Vector3(0, 1.0, 0)
	add_child(arabic)
	title = SignText.make_label("", 110, Color.WHITE, Color(0, 0, 0, 0), 0)
	title.position = Vector3(0, -0.15, 0)
	add_child(title)
	small = SignText.make_label("", 50, Color(0.6, 0.85, 0.95), Color(0, 0, 0, 0), 0)
	small.position = Vector3(0, -1.2, 0)
	add_child(small)
	show_hour(GameConfig.SHIFT_START_HOUR)


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 1.0
	var state := get_node_or_null("/root/GameState")
	if state != null:
		show_hour(state.clock_hours())


## Shows the right slide for this time of day.
func show_hour(hour: float) -> void:
	var which := slide_for(hour)
	if which == slide:
		return
	slide = which
	var lines: Array = SLIDES[which]
	title.text = lines[0]
	arabic.text = lines[1]
	small.text = lines[2]


const SLIDES := [
	["Welcome", "أهلاً", "C Institute · Lobby"],
	["Talk today · 4 PM", "محاضرة اليوم · ٤ مساءً", "Solar cities of tomorrow"],
	["Solar cities of tomorrow", "مدن الطاقة الشمسية في المستقبل", "Talk on now · Lecture hall"],
]


static func slide_for(hour: float) -> int:
	var times: Array = GameConfig.TALK_SCREEN_TIMES
	if hour < times[0]:
		return 0
	return 1 if hour < times[1] else 2
