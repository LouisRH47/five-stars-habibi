class_name ChatFeed
## Fills the phone's Messages app from the game (Session 89). GameState calls these:
## a regular writes a thank-you after you deliver to them, your boss welcomes you when
## you're hired and writes a short note at the end of every shift. The lines are in
## data/chat_lines.gd. (DJ Salad comes in Sessions 95 and 96; Plaza news uses
## GameState.post_news().)


## After a delivery: a regular (Auntie Mariam, Mr Rashid, ...) writes you a thank-you.
static func after_delivery(state: Node, order: Order) -> void:
	if order == null or order.regular_id == "" or not ChatLines.REGULAR_THANKS.has(order.regular_id):
		return
	var stars := float(state.last_result.get("stars", 5.0))
	var pool: Array = ChatLines.REGULAR_THANKS[order.regular_id]["good" if stars >= 4.0 else "meh"]
	var face: Dictionary = ChatLines.REGULAR_FACES.get(order.regular_id, {})
	state.add_message(order.regular_id, order.regular, _fill(state, pool.pick_random()), face.get("face", ""), face.get("colour", Color()))
	state.set_replies(order.regular_id, ChatLines.REGULAR_REPLIES)


## When you're hired: your new boss says hello.
static func welcome(state: Node) -> void:
	_boss_says(state, ChatLines.BOSS_WELCOME)


## At the end of a shift: your boss sums it up (deliveries and stars).
static func after_shift(state: Node, summary: Dictionary) -> void:
	if not state.hired:
		return
	var count := int(summary.get("deliveries", 0))
	var stars := float(summary.get("stars", 0.0))
	var text := ""
	if count == 0:
		text = ChatLines.BOSS_SHIFT_NOTES["none"] % state.shift_number
	else:
		var key := "great" if stars >= 4.5 else ("good" if stars >= 3.5 else "low")
		var jobs := "1 delivery" if count == 1 else "%d deliveries" % count
		text = ChatLines.BOSS_SHIFT_NOTES[key] % [state.shift_number, jobs, stars]
	_boss_says(state, text)


static func _boss_says(state: Node, text: String) -> void:
	var company := Companies.current()
	var boss_name := "%s boss" % company.get("name", "Snackaroo")
	state.add_message(GameConfig.CHAT_BOSS_ID, boss_name, _fill(state, text), boss_name.left(1), company.get("colour", ChatLines.BOSS_FACE_COLOUR))


## Swaps {name} and {company} for your name and your company's name.
static func _fill(state: Node, text: String) -> String:
	var rider: String = state.rider_name if state.rider_name != "" else "habibi"
	return text.replace("{name}", rider).replace("{company}", Companies.current().get("name", "Snackaroo"))
