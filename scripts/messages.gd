class_name Messages
## The phone's chats (Session 89), as plain data that GameState keeps in GameState.chats.
## Each chat is a Dictionary:
##   "id": "mariam", "name": "Auntie Mariam",
##   "face": "M" (the letter in the round picture), "colour": "#b9e4c9" (its colour),
##   "lines": [{"from": "them" or "me", "text": "..."}], oldest first,
##   "unread": how many of their lines you haven't read,
##   "replies": the reply buttons you can tap (you never type).
## The newest chat is first in the list. Only GameState should call these; it sends
## messages_changed and saves afterwards.

const DEFAULT_COLOUR := "#5c6b70"


## Where the chat with this id is in the list, or -1.
static func index_of(chats: Array, id: String) -> int:
	for i in chats.size():
		if chats[i].get("id", "") == id:
			return i
	return -1


## The chat with this id, or {}.
static func find(chats: Array, id: String) -> Dictionary:
	var i := index_of(chats, id)
	return chats[i] if i >= 0 else {}


## Adds one line to a chat (making the chat if it's new) and moves the chat to the top.
## from: "them" or "me". name / face / colour update the chat when they're given.
static func add_line(chats: Array, id: String, name: String, from: String, text: String, face := "", colour := Color()) -> Dictionary:
	var i := index_of(chats, id)
	var chat: Dictionary = chats[i] if i >= 0 else {"id": id, "name": name, "face": "", "colour": DEFAULT_COLOUR, "lines": [], "unread": 0, "replies": []}
	if i >= 0:
		chats.remove_at(i)
	if name != "":
		chat["name"] = name
	if face != "":
		chat["face"] = face
	elif chat["face"] == "":
		chat["face"] = chat["name"].left(1).to_upper()
	if colour != Color():
		chat["colour"] = "#" + colour.to_html(false)
	chat["lines"].append({"from": from, "text": text})
	while chat["lines"].size() > GameConfig.CHAT_MAX_LINES:
		chat["lines"].pop_front()
	if from == "them":
		chat["unread"] = int(chat["unread"]) + 1
	chats.push_front(chat)
	return chat


## All unread lines in all chats (the red badge on the Messages icon).
static func unread_total(chats: Array) -> int:
	var total := 0
	for chat in chats:
		total += int(chat.get("unread", 0))
	return total


## The round picture's colour of a chat.
static func colour_of(chat: Dictionary) -> Color:
	return Color.from_string(str(chat.get("colour", DEFAULT_COLOUR)), Color(DEFAULT_COLOUR))


## The chats from a save file, cleaned up (JSON turns whole numbers into decimals, and an
## old or broken save may have nothing or junk here: then there are just no chats).
static func from_save(saved) -> Array:
	var chats: Array = []
	if not saved is Array:
		return chats
	for chat in saved:
		if not chat is Dictionary or str(chat.get("id", "")) == "":
			continue
		var lines: Array = []
		for line in chat.get("lines", []):
			if line is Dictionary:
				lines.append({"from": "me" if line.get("from", "") == "me" else "them", "text": str(line.get("text", ""))})
		var replies: Array = []
		for reply in chat.get("replies", []):
			replies.append(str(reply))
		chats.append({"id": str(chat["id"]), "name": str(chat.get("name", chat["id"])), "face": str(chat.get("face", "")),
				"colour": str(chat.get("colour", DEFAULT_COLOUR)), "lines": lines.slice(-GameConfig.CHAT_MAX_LINES),
				"unread": maxi(0, int(chat.get("unread", 0))), "replies": replies})
	return chats


## The Jobs app's choices from a save file. Old saves (or junk) get everything on.
static func filters_from_save(saved) -> Dictionary:
	var filters := {"normal": true, "fragile": true, "vip": true, "far": true}
	if saved is Dictionary:
		for kind in filters:
			filters[kind] = bool(saved.get(kind, true))
	if not filters.values().has(true):
		filters["normal"] = true  # never all off
	return filters
