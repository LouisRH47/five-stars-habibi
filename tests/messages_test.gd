extends SceneTree
## Session 89: the phone's Messages and Jobs apps. Chats and the unread count, reading a
## chat, reply buttons, the 30-line cap, saving and loading (old saves too), regulars' and
## the boss's messages, the Jobs choices (never all off, and a kind that's off is offered
## less), and both app pages building with the right rows.
## Run: Godot --path . --headless -s tests/messages_test.gd
var failures: Array[String] = []
var checks := 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	state = root.get_node("GameState")
	state.save_path = "user://messages_test.json"
	state.new_game()
	_check_chats()
	_check_filters()
	_check_save()
	_check_feed()
	await _check_pages()
	await _check_orders()
	SaveGame.delete(state.save_path)
	SaveGame.delete("user://messages_old_save.json")
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " messages · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


func _check_chats() -> void:
	_expect(state.chats.is_empty() and state.unread_messages() == 0, "a new game has no messages")
	var heard := [0]
	state.messages_changed.connect(func(): heard[0] += 1)
	state.add_message("mariam", "Auntie Mariam", "Thank you dear!", "M", Color("#b9e4c9"))
	state.add_message("mariam", "Auntie Mariam", "Still cold!")
	state.post_news("Flea market tomorrow in the Plaza!")
	_expect(state.unread_messages() == 3, "three new lines make three unread", str(state.unread_messages()))
	_expect(heard[0] >= 3, "every new line sends messages_changed")
	_expect(state.chats[0]["id"] == GameConfig.CHAT_NEWS_ID and state.chats[1]["id"] == "mariam", "the newest chat is at the top")
	state.read_chat("mariam")
	_expect(state.unread_messages() == 1 and Messages.find(state.chats, "mariam")["unread"] == 0, "reading a chat clears its unread lines")
	state.set_replies("mariam", ["Anytime!"])
	state.send_reply("mariam", "Anytime!")
	var mariam: Dictionary = Messages.find(state.chats, "mariam")
	_expect(mariam["lines"].back() == {"from": "me", "text": "Anytime!"} and mariam["replies"].is_empty() and state.unread_messages() == 1,
			"a reply is your line, the buttons go and it isn't unread")
	for i in 40:
		state.add_message("spam", "Chatty", "Line %d" % i)
	var spam: Dictionary = Messages.find(state.chats, "spam")
	_expect(spam["lines"].size() == GameConfig.CHAT_MAX_LINES and spam["lines"].back()["text"] == "Line 39", "a chat keeps only its last 30 lines")
	state.read_chat("spam")


func _check_filters() -> void:
	_expect(state.order_filters.values().count(true) == 4, "every kind of order starts on")
	_expect(state.set_order_filter("normal", false) and state.set_order_filter("fragile", false) and state.set_order_filter("vip", false),
			"three kinds can be switched off")
	_expect(not state.set_order_filter("far", false) and state.wants_order_kind("far"), "the last kind on can't be switched off")
	_expect(not state.set_order_filter("pizza", false), "an unknown kind is refused")
	_expect(state.set_order_filter("normal", true) and state.set_order_filter("vip", true), "kinds switch back on")


func _check_save() -> void:
	state.save_game()
	var chats_before: Array = state.chats.duplicate(true)
	var filters_before: Dictionary = state.order_filters.duplicate()
	state.chats.clear()
	state.order_filters = {"normal": true, "fragile": true, "vip": true, "far": true}
	SaveGame.load_into(state, state.save_path)
	_expect(state.chats == chats_before, "saving and loading keeps every chat", str(state.chats.size()))
	_expect(state.order_filters == filters_before, "saving and loading keeps the Jobs choices", str(state.order_filters))
	var old := FileAccess.open("user://messages_old_save.json", FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 2, "money": 12, "hired": true}))
	old.close()
	_expect(SaveGame.load_into(state, "user://messages_old_save.json"), "an old save without chats loads")
	_expect(state.chats.is_empty() and state.order_filters.values().count(true) == 4 and state.money == 12,
			"an old save has no chats and every kind on")
	old = FileAccess.open("user://messages_old_save.json", FileAccess.WRITE)
	old.store_string(JSON.stringify({"chats": "junk", "order_filters": {"normal": false, "fragile": false, "vip": false, "far": false}}))
	old.close()
	SaveGame.load_into(state, "user://messages_old_save.json")
	_expect(state.chats.is_empty() and state.order_filters.values().has(true), "a broken save still loads with at least one kind on")
	state.new_game()


func _check_feed() -> void:
	state.hire("Lina", "Oman", 0)
	state.tutorial_done = true
	var boss: Dictionary = Messages.find(state.chats, GameConfig.CHAT_BOSS_ID)
	_expect(not boss.is_empty() and boss["name"] == "Snackaroo boss" and "Lina" in boss["lines"][0]["text"], "the boss welcomes you when you're hired", str(boss.get("name", "")))
	var order := Order.new()
	order.restaurant_id = "boba"
	order.restaurant_name = "Boba Oasis"
	order.villa_number = 207
	order.pay = 12
	order.regular = "Auntie Mariam"
	order.regular_id = "mariam"
	state.start_meters(60.0)
	var delivered: bool = state.offer_order(order) and state.accept_offer() and state.pick_up() and state.deliver()
	var mariam: Dictionary = Messages.find(state.chats, "mariam")
	_expect(delivered and not mariam.is_empty() and mariam["lines"].size() == 1 and mariam["unread"] == 1,
			"a regular thanks you in Messages after a delivery", str(mariam.get("lines", [])))
	_expect(mariam.get("face", "") == "M" and not mariam.get("replies", []).is_empty(), "the regular's chat has a picture and reply buttons")
	state.end_shift()
	boss = Messages.find(state.chats, GameConfig.CHAT_BOSS_ID)
	_expect(boss["lines"].size() == 2 and "1 delivery " in boss["lines"][1]["text"] and state.chats[0]["id"] == GameConfig.CHAT_BOSS_ID,
			"the boss sums up the shift", boss["lines"].back()["text"])


func _check_pages() -> void:
	var holder := VBoxContainer.new()
	holder.custom_minimum_size = Vector2(380, 700)
	root.add_child(holder)
	state.set_order_filter("far", false)
	var jobs_script: GDScript = load("res://scripts/phone_apps/jobs_app.gd")
	var messages_script: GDScript = load("res://scripts/phone_apps/messages_app.gd")
	_expect(jobs_script != null and jobs_script.can_instantiate() and messages_script != null and messages_script.can_instantiate(),
			"both app pages compile")
	if not jobs_script.can_instantiate() or not messages_script.can_instantiate():
		return
	var jobs: VBoxContainer = jobs_script.new()
	holder.add_child(jobs)
	await process_frame
	var rows := ["normal", "fragile", "vip", "far"].filter(func(k): return jobs.find_child("Row_" + k, true, false) != null)
	_expect(rows.size() == 4, "the Jobs app shows the four order kinds", str(rows))
	var far_switch: Button = jobs.find_child("Row_far", true, false).get_node("Switch")
	_expect(not far_switch.button_pressed and jobs.find_child("Row_normal", true, false).get_node("Switch").button_pressed, "the switches show the saved choices")
	far_switch.button_pressed = true
	_expect(state.wants_order_kind("far"), "tapping a switch turns that kind on")
	var goals: Control = jobs.find_child("GoalsCard", true, false)
	_expect(goals != null and goals.get_child(0).get_child_count() == state.shift_goals.size(), "the Jobs app lists today's shift goals", str(state.shift_goals))
	var now_text: String = (jobs.find_child("NowCard", true, false).get_child(0).get_child(0) as Label).text
	_expect(now_text == "No order right now.", "with no order the Now card says so", now_text)
	jobs.queue_free()
	var messages: VBoxContainer = messages_script.new()
	holder.add_child(messages)
	await process_frame
	var list: Control = messages.get_node("ChatList")
	_expect(list.visible and list.get_child_count() == state.chats.size(), "the Messages app lists every chat", str(list.get_child_count()))
	var mariam_row: Control = list.get_node("Chat_mariam")
	_expect(mariam_row.find_child("Unread", true, false) != null, "an unread chat has a red dot")
	(mariam_row as Button).pressed.emit()
	await process_frame
	var view: Control = messages.get_node("ChatView")
	_expect(view.visible and not list.visible and view.find_child("Bubbles", true, false).get_child_count() == 1, "tapping a chat opens it with its bubbles")
	_expect(Messages.find(state.chats, "mariam")["unread"] == 0, "opening a chat reads it")
	var reply: Button = view.find_child("Reply0", true, false)
	_expect(reply != null, "the chat shows its reply buttons")
	if reply != null:
		reply.pressed.emit()
		await process_frame
		await process_frame
		_expect(view.find_child("Bubbles", true, false).get_child_count() == 2 and view.find_child("Reply0", true, false) == null, "tapping a reply adds your bubble")
	(view.find_child("Back", true, false) as Button).pressed.emit()
	_expect(list.visible and not view.visible, "‹ Chats goes back to the list")
	messages.open("mariam")
	_expect(messages.go_back() and list.visible and not messages.go_back(), "Esc goes from a chat to the list, then lets the phone go home")
	holder.queue_free()
	await process_frame


func _check_orders() -> void:
	state.new_game()
	state.hired = true
	state.tutorial_done = true
	var world: Node3D = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 6:
		await physics_frame
	world.get_node("EventManager").enabled = false
	var delivery = world.get_node("DeliveryManager")  # untyped: its script needs the GameState autoload
	delivery.special_chance = 1.0
	delivery.regular_chance = 0.0
	var maker: OrderMaker = delivery.order_maker()
	var counts := func() -> Dictionary:
		var kinds := {"normal": 0, "fragile": 0, "vip": 0, "far": 0}
		for i in 200:
			kinds[maker.kind_of(delivery._wanted_order())] += 1
		return kinds
	var all_on: Dictionary = counts.call()
	state.set_order_filter("fragile", false)
	var no_fragile: Dictionary = counts.call()
	_expect(all_on["fragile"] >= 25 and no_fragile["fragile"] <= 3, "with Fragile off, fragile orders are rare", "%s -> %s" % [all_on, no_fragile])
	state.set_order_filter("fragile", true)
	delivery.special_chance = GameConfig.SPECIAL_ORDER_CHANCE
	delivery.regular_chance = GameConfig.REGULAR_ORDER_CHANCE
	var usual: Dictionary = counts.call()
	_expect(usual["far"] >= 30 and usual["far"] <= 110, "about a third of usual orders count as far", str(usual))
	state.set_order_filter("far", false)
	var no_far: Dictionary = counts.call()
	_expect(no_far["far"] * 3 < usual["far"], "with Far off, far orders are much rarer", str(no_far))
	world.queue_free()
	await process_frame
