extends Node3D
## Session 61: the talk screen in the C Institute. It glows and shows the next slide every
## INSTITUTE_SCREEN_SECONDS: "Talk today · 4 PM", "Solar cities of tomorrow", "Welcome · أهلاً"
## (the list is GameConfig.INSTITUTE_SLIDES, English with Arabic above).

## Which slide is showing now (0, 1, 2...).
var slide := 0
var _left := 0.0
var _face: Node3D


func _ready() -> void:
	var panel := LowPoly.box(self, Vector3(7.8, 4.2, 0.02), Color.WHITE, Vector3(0, 0, 0.08))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.1, 0.3, 0.45)
	glow.emission_enabled = true
	glow.emission = Color(0.12, 0.38, 0.55)
	glow.emission_energy_multiplier = 0.8
	panel.material_override = glow
	panel.name = "ScreenGlow"
	show_slide(0)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		show_slide(slide + 1)


## Shows slide number `index` (it wraps round) and starts the timer again.
func show_slide(index: int) -> void:
	var slides: Array = GameConfig.INSTITUTE_SLIDES
	slide = index % slides.size()
	_left = GameConfig.INSTITUTE_SCREEN_SECONDS
	if _face != null:
		_face.queue_free()
	var english: String = slides[slide][0]
	var arabic: String = slides[slide][1]
	_face = SignText.make_face(arabic, english, SignText.fit_size(arabic, english, 80, 7.0), Color.WHITE)
	_face.name = "Slide"
	_face.position = Vector3(0, 0, 0.1)
	add_child(_face)


## The English line of the slide showing now (the tests read it).
func english_text() -> String:
	return GameConfig.INSTITUTE_SLIDES[slide][0]
