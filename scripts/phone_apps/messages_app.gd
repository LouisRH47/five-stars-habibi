extends VBoxContainer
## The phone's Messages app (Session 89): the list of chats (round picture, name, last line
## and a red dot with the unread count), and one chat opened inside the same page: their
## lines on the left in sand, yours on the right in teal, and reply buttons to tap at the
## bottom (you never type). "‹ Chats" goes back to the list. Opening a chat reads it.
## The chats live in GameState.chats (scripts/messages.gd). The phone shell puts this under
## its "‹ Messages" header and calls refresh() each time the app opens.

signal close_phone

const INK := Color("#1b1d22")
const SOFT := Color("#5c6b70")
const TEAL := Color("#0f4c5c")
const ORANGE := Color("#f28c28")
const RED := Color("#cc4033")
const SAND := Color("#efe6d4")
const LINE := Color("#efe6d4")
const BUBBLE_SHARE := 0.78  # a bubble is at most this share of the page's width
const PAGE_WIDTH := 344.0   # used for the bubbles until the page has its real width

var open_chat := ""  # the id of the chat that's open, "" = the list
var _list: VBoxContainer
var _view: VBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.name = "ChatList"
	_list.add_theme_constant_override("separation", 0)
	add_child(_list)
	_view = VBoxContainer.new()
	_view.name = "ChatView"
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_view)
	GameState.messages_changed.connect(_on_messages_changed)
	refresh()


## Opening the app always starts on the list of chats.
func refresh() -> void:
	open_chat = ""
	_show()


## Opens one chat inside the page and marks it read.
func open(chat_id: String) -> void:
	open_chat = chat_id
	GameState.read_chat(chat_id)
	_show()


## Back to the list of chats.
func back_to_list() -> void:
	open_chat = ""
	_show()


## Esc or the header's ‹ (the phone shell asks): in a chat, go back to the list and say
## true; on the list, say false so the shell goes back to the home screen.
func go_back() -> bool:
	if open_chat == "":
		return false
	back_to_list()
	return true


func _on_messages_changed() -> void:
	if is_inside_tree():
		if open_chat != "":
			GameState.read_chat(open_chat)  # a new line in the chat you're reading is read
		_show.call_deferred()


func _show() -> void:
	var chat := Messages.find(GameState.chats, open_chat)
	if chat.is_empty():
		open_chat = ""
	_list.visible = open_chat == ""
	_view.visible = open_chat != ""
	if open_chat == "":
		_fill_list()
	else:
		_fill_chat(chat)


func _fill_list() -> void:
	_clear(_list)
	if GameState.chats.is_empty():
		_list.add_child(_text("No messages yet. Your regulars and your boss will write to you here.", 14, SOFT))
	for chat: Dictionary in GameState.chats:
		_list.add_child(_chat_row(chat))


## One chat in the list: a flat button holding the picture, the name, the last line and the dot.
func _chat_row(chat: Dictionary) -> Button:
	var button := Button.new()
	button.name = "Chat_" + chat["id"]
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 60
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var under := StyleBoxFlat.new()
	under.bg_color = Color(0, 0, 0, 0)
	under.border_color = LINE
	under.border_width_bottom = 1
	for state in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = under.duplicate()
		if state != "normal":
			style.bg_color = Color("#fbf6ec")
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(open.bind(chat["id"]))
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	row.add_child(_face(chat, 40))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.add_child(_text(chat["name"], 15, INK, true, false))
	var last: Array = chat["lines"]
	var preview: String = ("You: " if last.back()["from"] == "me" else "") + last.back()["text"] if not last.is_empty() else ""
	var preview_label := _text(preview, 12, SOFT, false, false)
	preview_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	words.add_child(preview_label)
	row.add_child(words)
	if int(chat["unread"]) > 0:
		var dot := PanelContainer.new()
		dot.name = "Unread"
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", _round(RED, 10, 7, 1))
		var count := _text(str(chat["unread"]), 11, Color.WHITE, true, false)
		count.clip_text = false
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.custom_minimum_size.x = 22
		dot.add_child(count)
		row.add_child(dot)
	_ignore_mouse(row)
	button.add_child(row)
	return button


func _fill_chat(chat: Dictionary) -> void:
	_clear(_view)
	var top := HBoxContainer.new()
	top.name = "ChatTop"
	top.add_theme_constant_override("separation", 8)
	var back := Button.new()
	back.name = "Back"
	back.text = "‹ Chats"
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_color_override("font_color", TEAL)
	back.add_theme_color_override("font_hover_color", ORANGE)
	back.add_theme_font_override("font", _bold())
	back.add_theme_font_size_override("font_size", 15)
	back.pressed.connect(back_to_list)
	top.add_child(back)
	top.add_child(_face(chat, 30))
	var title := _text(chat["name"], 18, TEAL, false, false)
	title.theme_type_variation = &"Heading"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_view.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var bubbles := VBoxContainer.new()
	bubbles.name = "Bubbles"
	bubbles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubbles.add_theme_constant_override("separation", 6)
	for line: Dictionary in chat["lines"]:
		bubbles.add_child(_bubble(line["text"], line["from"] == "me"))
	scroll.add_child(bubbles)
	_view.add_child(scroll)
	_view.add_theme_constant_override("separation", 6)
	for i in chat["replies"].size():
		var reply := Button.new()
		reply.name = "Reply%d" % i
		reply.text = chat["replies"][i]
		reply.focus_mode = Control.FOCUS_NONE
		reply.add_theme_font_size_override("font_size", 14)
		reply.add_theme_font_override("font", _bold())
		reply.add_theme_stylebox_override("normal", _round(ORANGE, 14, 12, 7))
		reply.add_theme_stylebox_override("hover", _round(ORANGE.lightened(0.1), 14, 12, 7))
		reply.add_theme_stylebox_override("pressed", _round(TEAL, 14, 12, 7))
		reply.pressed.connect(GameState.send_reply.bind(chat["id"], chat["replies"][i]))
		_view.add_child(reply)
	# Start at the newest line, at the bottom.
	scroll.get_v_scroll_bar().changed.connect(func(): scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value), CONNECT_ONE_SHOT)


## One chat bubble: theirs on the left in sand, yours on the right in teal.
func _bubble(text: String, mine: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := _text(text, 14, Color.WHITE if mine else INK)
	var widest := (size.x if size.x > 100.0 else PAGE_WIDTH) * BUBBLE_SHARE - 24.0
	var font := label.get_theme_font("font")
	label.custom_minimum_size.x = minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 2.0, widest)
	var bubble := PanelContainer.new()
	var style := _round(TEAL if mine else SAND, 16, 12, 8)
	if mine:
		style.corner_radius_bottom_right = 4
	else:
		style.corner_radius_bottom_left = 4
	bubble.add_theme_stylebox_override("panel", style)
	bubble.add_child(label)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap if mine else bubble)
	row.add_child(bubble if mine else gap)
	return row


## The round picture: a letter on the chat's colour.
func _face(chat: Dictionary, diameter: int) -> PanelContainer:
	var colour := Messages.colour_of(chat)
	var face := PanelContainer.new()
	face.custom_minimum_size = Vector2(diameter, diameter)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.add_theme_stylebox_override("panel", _round(colour, diameter / 2, 0, 0))
	var letter := _text(chat["face"], int(diameter * 0.45), Color.WHITE if colour.get_luminance() < 0.5 or colour.s > 0.5 else TEAL, false, false)
	letter.theme_type_variation = &"Heading"
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face.add_child(letter)
	return face


# --- Small building blocks ---

func _text(text: String, size: int, colour: Color, bold := false, wrap := true) -> Label:
	var label := Label.new()
	label.text = text
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_constant_override("line_spacing", -4)
	else:
		label.clip_text = true
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if bold:
		label.add_theme_font_override("font", _bold())
	return label


static var _bold_font: FontVariation


## Nunito at its boldest.
static func _bold() -> FontVariation:
	if _bold_font == null:
		_bold_font = FontVariation.new()
		_bold_font.base_font = load("res://assets/fonts/Nunito.ttf")
		_bold_font.fallbacks = [load("res://assets/fonts/NotoSansArabic.ttf")]
		_bold_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
	return _bold_font


static func _round(colour: Color, radius: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	return style


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


static func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
