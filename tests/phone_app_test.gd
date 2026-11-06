extends SceneTree
## Session 89: checks the big phone (scripts/phone_app.gd) on the real Wahat Al Shams map.
## P opens it and pauses the game, every app opens and has something on it, ‹ goes back
## home, the Messages badge follows the unread count, the Company app switches company,
## Esc goes home then closes, and P closes and lets the game run again.
## Run: godot --headless --path . -s tests/phone_app_test.gd

const APPS := ["jobs", "profile", "collection", "messages", "company", "map", "settings"]

var _failed := false
var _world: Node
var _state: Node
var _phone: Node  # the PhoneApp (untyped: test scripts load before the autoloads)


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_path = "user://phone_app_test.json"
	_state.reset()
	_state.tutorial_done = true
	_world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 4:
		await process_frame
	for path in ["Bike", "Walker", "DeliveryManager", "ShiftManager"]:
		_world.get_node(path).set_physics_process(false)
	_phone = _world.get_node_or_null("Phone/PhoneApp")
	_expect(_phone != null, "the corner phone has a PhoneApp child")
	if _phone == null:
		await _finish()
		return
	paused = false
	_key(KEY_P)
	await process_frame
	_expect(_phone.showing and paused, "P opens the big phone and pauses the game")
	_expect(_phone.home.visible and _phone.current_app == "", "it opens on the home screen")
	_expect(_phone.home.icons.size() == 7, "the home screen has 7 app icons")
	_expect(_phone.home.icon("company").logo != null, "the Company icon shows the company logo")
	await _check_badge()
	_key(KEY_RIGHT)
	_expect(_phone.home.highlighted_app() == "jobs", "the first arrow key shows the ring on Jobs")
	_key(KEY_DOWN)
	_expect(_phone.home.highlighted_app() == "messages", "arrow keys move the ring (down from Jobs is Messages)")
	_key(KEY_E)
	await process_frame
	_expect(_phone.current_app == "messages", "E opens the ringed app")
	_key(KEY_ESCAPE)
	await process_frame
	_expect(_phone.showing and _phone.current_app == "", "Esc in an app goes back to the home screen")
	for id in APPS:
		_phone.open_app(id)
		await process_frame
		var page: Control = _phone.page(id)
		_expect(page != null and page.visible and page.get_child_count() > 0, "the %s app opens and has things on it" % id)
		_phone.back()
		await process_frame
		_expect(_phone.current_app == "" and _phone.home.visible, "back from %s goes home" % id)
	await _check_company()
	await _check_collection()
	_key(KEY_P)
	await process_frame
	_expect(not _phone.showing and not paused, "P closes the phone and the game runs again")
	_phone.open()
	_key(KEY_ESCAPE)
	await process_frame
	_expect(not _phone.showing and not paused, "Esc on the home screen closes the phone")
	paused = true
	_expect(not _phone.open(), "the phone doesn't open while something else has paused the game")
	paused = false
	await _check_map()
	await _check_stamp_card()
	await _finish()


## The Profile app's "Stamp card & neighbours" button: the phone closes, the old page opens.
func _check_stamp_card() -> void:
	_phone.open()
	_phone.open_app("profile")
	await process_frame
	_phone.page("profile").get_node("StampCard").pressed.emit()
	await process_frame
	var profile: Node = _world.get_node("Phone/ProfilePage")
	_expect(not _phone.showing and profile.showing and paused, "the Stamp card button closes the phone and opens the stamp card page")
	_key(KEY_P)
	await process_frame
	_expect(profile.showing and not _phone.showing, "P doesn't open the phone over the stamp card page")
	_key(KEY_ESCAPE)
	await process_frame
	_expect(not profile.showing and not paused, "Esc closes the stamp card page")


## The red badge on Messages: hidden at 0, the number when there are unread messages.
func _check_badge() -> void:
	var badge: Control = _phone.home.icon("messages")
	if not _state.has_method("unread_messages"):
		_expect(badge.badge == 0, "no Messages data yet: the badge stays hidden")
		return
	_expect(badge.badge == int(_state.unread_messages()), "the badge shows the unread count (%d)" % badge.badge)
	if int(_state.unread_messages()) > 0:
		print("INFO: there are unread messages at the start; the badge shows them")
	_expect((badge.badge > 0) == (int(_state.unread_messages()) > 0), "the badge hides at 0 and shows a number otherwise")
	if not _state.has_method("add_message") or not _state.has_method("read_chat"):
		return
	var before := int(_state.unread_messages())
	_state.add_message("phone_app_test", "Test friend", "Hello!")
	_state.add_message("phone_app_test", "Test friend", "Are you there?")
	await process_frame
	_expect(badge.badge == before + 2 and badge.badge == int(_state.unread_messages()), "two new messages: the badge shows %d" % badge.badge)
	for chat: Dictionary in _state.chats.duplicate():
		_state.read_chat(str(chat["id"]))
	await process_frame
	_expect(badge.badge == 0, "after reading every chat the badge hides")


func _check_company() -> void:
	_state.money = 100
	_phone.open_app("company")
	await process_frame
	var app: Control = _phone.page("company")
	var other := "zoomaroo" if _state.company != "zoomaroo" else "snackaroo"
	app.pick(other)
	await process_frame
	_expect(app.switch_to_picked() and _state.company == other and _state.money == 100 - GameConfig.COMPANY_SWITCH_PRICE,
			"the Company app switches to %s for %d Dh" % [other, GameConfig.COMPANY_SWITCH_PRICE])
	await process_frame
	_expect(app.has_node("Result"), "it says how the switch went")
	_state.money = 10
	app.pick("deliverooz")
	await process_frame
	_expect(not app.switch_to_picked() and _state.company == other, "without enough money it doesn't switch")
	await process_frame
	var result := app.get_node_or_null("Result") as Label
	_expect(result != null and result.text.contains("costs"), "it explains it costs %d Dh" % GameConfig.COMPANY_SWITCH_PRICE)
	_phone.back()
	await process_frame
	_expect(_phone.home.icon("company").logo == Companies.logo(Companies.find(other)), "the Company icon follows the new company")


func _check_collection() -> void:
	_phone.open_app("collection")
	await process_frame
	var app: Control = _phone.page("collection")
	for tab in ["bikes", "looks", "gear"]:
		app.show_tab(tab)
		await process_frame
		var grid := app.get_node_or_null("Items") as GridContainer
		_expect(grid != null and grid.get_child_count() > 0, "the Collection app's %s tab lists items" % tab)
	_phone.back()
	await process_frame


## The Map app closes the phone and opens the HUD's big map.
func _check_map() -> void:
	_phone.open()
	_phone.open_app("map")
	await process_frame
	var opened: bool = _phone.page("map").open_map()
	await process_frame
	var map: Node = _world.find_child("FullMap", true, false)
	_expect(opened and not _phone.showing and map.visible and paused, "the Map app closes the phone and opens the big map")
	map.close()
	await process_frame
	_expect(not paused, "closing the map lets the game run again")


func _finish() -> void:
	paused = false
	_world.queue_free()
	await process_frame
	SaveGame.delete(_state.save_path)
	await preload("res://tests/clean_exit.gd").run(self)
	print("RESULT: FAIL" if _failed else "RESULT: PASS")
	quit(1 if _failed else 0)
