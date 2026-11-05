extends RefCounted
## Session 71 (polish pass): "every action gets an answer". Buttons grow 3% with a soft tick
## when the mouse is over them, and squash to 95% with a click when pressed. Panels pop in
## with a short "open" sound. The start screen calls wire_buttons() itself; in the game world
## attach() (called once by PolishHooks) wires every button that's there now or added later
## (pause menu, settings, Delivered card, clinic, shop rows...).
## Switch: GameConfig.SCREENS_V2.

const FEEL_META := "ui_feel"


static func attach(world: Node) -> void:
	if not GameConfig.SCREENS_V2:
		return
	var watcher := Watcher.new()
	watcher.name = "ScreenExtras"
	watcher.extras = load("res://scripts/polish/screen_extras.gd")
	world.add_child(watcher)


## Gives every button under `root` the hover and press feel.
static func wire_buttons(root: Node) -> void:
	if not GameConfig.SCREENS_V2:
		return
	for button in root.find_children("*", "BaseButton", true, false):
		wire(button)


static func wire(button: BaseButton) -> void:
	if button.has_meta(FEEL_META):
		return
	button.set_meta(FEEL_META, true)
	button.mouse_entered.connect(func(): _hover(button, true))
	button.mouse_exited.connect(func(): _hover(button, false))
	button.pressed.connect(func(): _press(button))


## Opens a panel: a pop (or a quick fade on touch screens, where the touch test measures
## the buttons straight away) and the "open" sound.
static func open_panel(panel: Control, sound_key := "ui_open") -> void:
	sound(sound_key)
	if not GameConfig.SCREENS_V2:
		return
	if _touch():
		panel.modulate.a = 0.0
		var fade := panel.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade.tween_property(panel, "modulate:a", 1.0, UiPalette.FAST)
		return
	# Wait one frame so the panel has its real size (the pop grows from its middle).
	var t := panel.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel.modulate.a = 0.0
	t.tween_interval(0.0)
	t.tween_callback(func():
		panel.modulate.a = 1.0
		UiJuice.pop_in(panel, UiPalette.PANEL_TIME * 0.8))


static func _hover(button: BaseButton, on: bool) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	if on and button.disabled:
		return
	if on:
		sound("ui_hover")
	if Settings.reduce_motion or _touch():
		return
	button.pivot_offset = button.size * 0.5
	var t := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(button, "scale", Vector2.ONE * (GameConfig.BUTTON_HOVER_SCALE if on else 1.0), UiPalette.FAST) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


static func _press(button: BaseButton) -> void:
	sound("ui_click")
	if not is_instance_valid(button) or not button.is_inside_tree() or Settings.reduce_motion or _touch():
		return
	UiJuice.press(button)


## Plays a UI sound through the UiSounds autoload (looked up by name, so scripts that are
## compiled before the autoloads exist, like class_name ones in tests, can still use it).
static func sound(key: String, pitch := 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var ui := tree.root.get_node_or_null("UiSounds") if tree != null else null
	if ui != null:
		ui.play(key, pitch)


static func _touch() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var touch := tree.root.get_node_or_null("TouchControls") if tree != null else null
	return touch != null and bool(touch.get("touch_enabled"))


## Lives in the game world: wires the buttons there now, and any button added later.
class Watcher extends Node:
	var extras: Script  # this file (an inner class can't call the outer static functions)

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var world := get_parent()
		for button in world.find_children("*", "BaseButton", true, false):
			extras.wire(button)
		get_tree().node_added.connect(_on_node_added)

	func _exit_tree() -> void:
		if get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.disconnect(_on_node_added)

	func _on_node_added(node: Node) -> void:
		if node is BaseButton and get_parent() != null and get_parent().is_ancestor_of(node):
			extras.wire(node)
