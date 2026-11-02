class_name SignText
## Helpers for bilingual signs (Arabic on top, English below, like Dubai).
## One font does both languages: Noto Sans Arabic has Arabic and Latin letters.
## Godot joins the Arabic letters and runs them right-to-left by itself.
## Labels are flat (not turning to the camera) and one-sided, so text is never
## seen mirrored. A free-standing sign gets a second face on its back.

const FONT := preload("res://assets/fonts/NotoSansArabic.ttf")
## Label3D's own size of one font pixel, in metres (Godot's default).
const PIXEL_SIZE := 0.005
## The Arabic line is a little bigger than the English one.
const ARABIC_SCALE := 1.15
## How bold the letters are (400 = normal, 700 = bold).
const WEIGHT := 700

static var _bold: Font = null


## The sign font, made bold. Made once, then shared by every sign.
static func font() -> Font:
	if _bold == null:
		var bold := FontVariation.new()
		bold.base_font = FONT
		var wght: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		bold.variation_opentype = {wght: WEIGHT}
		_bold = bold
	return _bold


## One flat line of text. It reads from the front (its +Z side) only.
static func make_label(text: String, font_size: int, colour: Color,
		outline_colour: Color, outline_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = font()
	label.font_size = font_size
	label.pixel_size = PIXEL_SIZE
	label.modulate = colour
	label.outline_modulate = outline_colour
	label.outline_size = outline_size
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	return label


## How wide a line of text is, in metres.
static func text_width(text: String, font_size: int) -> float:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * PIXEL_SIZE


## The biggest font size (up to max_size) at which both lines fit in max_width metres.
static func fit_size(arabic: String, english: String, max_size: int, max_width: float) -> int:
	var size := max_size
	while size > 8:
		var wide := maxf(text_width(arabic, roundi(size * ARABIC_SCALE)), text_width(english, size))
		if wide <= max_width:
			break
		size -= 4
	return size


## A sign face: the Arabic line above the English line, centred on (0, 0).
## font_size is for the English line. It reads from the +Z side.
static func make_face(arabic: String, english: String, font_size: int, colour: Color,
		outline_colour := Color(0, 0, 0, 0), outline_size := 0) -> Node3D:
	var face := Node3D.new()
	face.name = "Face"
	var line := font_size * PIXEL_SIZE
	var top := make_label(arabic, roundi(font_size * ARABIC_SCALE), colour, outline_colour, outline_size)
	top.position.y = line * 0.75
	face.add_child(top)
	var bottom := make_label(english, font_size, colour, outline_colour, outline_size)
	bottom.position.y = -line * 0.65
	face.add_child(bottom)
	return face


## Two faces back to back, for a sign you can see from both sides.
## gap: the board's thickness, so each face sits just outside the board.
static func make_two_faces(arabic: String, english: String, font_size: int, colour: Color,
		gap: float) -> Node3D:
	var both := Node3D.new()
	both.name = "Faces"
	var front := make_face(arabic, english, font_size, colour)
	front.name = "Front"
	front.position.z = gap * 0.5 + 0.01
	both.add_child(front)
	var back := make_face(arabic, english, font_size, colour)
	back.name = "Back"
	back.position.z = -(gap * 0.5 + 0.01)
	back.rotation.y = PI
	both.add_child(back)
	return both
