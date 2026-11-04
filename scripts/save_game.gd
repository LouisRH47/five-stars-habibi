class_name SaveGame
## Saves and loads your progress (Session 15) to one small file, as JSON text:
## money, delivery history (your rating comes from it), XP, your name, country and look,
## the insurance setting, how often you've delivered to each regular, and whether you're hired / did the tutorial / the boss paid a
## crash. GameState calls these; it saves by itself whenever something changes.
## On a Mac the file is in ~/Library/Application Support/Godot/app_userdata/Five Stars Habibi/.

## Bump this if the save format changes, so old saves can be read differently.
const VERSION := 2
## Only the newest deliveries are kept in the save (the rating only needs the last 50).
const HISTORY_KEPT := 200
## History numbers that must come back as whole numbers (JSON turns them into decimals).
const WHOLE_NUMBERS := ["villa", "pay", "tip", "xp", "insurance"]


## Writes the game to `path`. Returns true if it worked.
static func save(state: Node, path: String) -> bool:
	var data := {
		"version": VERSION,
		"money": state.money,
		"xp": state.xp,
		"history": state.history.slice(-HISTORY_KEPT),
		"rider_name": state.rider_name,
		"rider_country": state.rider_country,
		"rider_look": state.rider_look,
		"hired": state.hired,
		"tutorial_done": state.tutorial_done,
		"insurance_on": state.insurance_on,
		"boss_paid_crash": state.boss_paid_crash,
		"shift_number": state.shift_number,
		"shift_finished": state.shift_finished,
		"choices": state._choices,
		"crash_shifts": state.crash_shifts,
		"regular_visits": state.regular_visits,
	}
	for field in ["streak", "day_kind", "tomorrow_kind", "personal_bests", "visited_homes", "visited_venues",
			"animals_met", "lines_heard", "collection_claims", "owned_collection_rewards", "upgrade_levels", "owned_items", "equipped_cosmetics"]:
		data[field] = state.get(field)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the game to " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


## Reads the game from `path` into `state`. Returns false if there's no save (or it's broken).
static func load_into(state: Node, path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_warning("The save file is broken, starting fresh: " + path)
		return false
	state.money = int(data.get("money", 0))
	state.xp = int(data.get("xp", 0))
	state.history.clear()
	for job in data.get("history", []):
		if job is Dictionary:
			for key in WHOLE_NUMBERS:
				if job.has(key):
					job[key] = int(job[key])
			if job.has("food"):
				job["food"] = renamed_food(str(job["food"]))
			state.history.append(job)
	state.rider_name = str(data.get("rider_name", ""))
	state.rider_country = str(data.get("rider_country", ""))
	state.rider_look = int(data.get("rider_look", 0))
	state.hired = bool(data.get("hired", false))
	state.tutorial_done = bool(data.get("tutorial_done", false))
	state.insurance_on = bool(data.get("insurance_on", true))
	state.boss_paid_crash = bool(data.get("boss_paid_crash", false))
	state.shift_number = int(data.get("shift_number", 0))
	# Older saves don't say; count the next launch as a new shift, as before.
	state.shift_finished = bool(data.get("shift_finished", true))
	# Your last accept / skip choices, so the acceptance rate survives a restart (PRD).
	state._choices.clear()
	for choice in data.get("choices", []):
		state._choices.append(bool(choice))
	state.crash_shifts.clear()
	for number in data.get("crash_shifts", []):
		state.crash_shifts.append(int(number))
	# How many times you've delivered to each regular customer (Session 32).
	state.regular_visits.clear()
	var visits = data.get("regular_visits", {})
	if visits is Dictionary:
		for id in visits:
			state.regular_visits[str(id)] = int(visits[id])
	# Version 1 remains readable. New progress is independent of the 200-job rating archive.
	state.streak = maxi(0, int(data.get("streak", 0)))
	state.day_kind = data.get("day_kind", "normal") if data.get("day_kind", "normal") in ReplayCatalog.DAYS else "normal"
	state.tomorrow_kind = data.get("tomorrow_kind", "hot_noon") if data.get("tomorrow_kind", "hot_noon") in ReplayCatalog.DAYS else "hot_noon"
	for field in ["visited_homes", "visited_venues", "animals_met", "lines_heard", "collection_claims", "owned_collection_rewards",
			"upgrade_levels", "owned_items", "equipped_cosmetics"]:
		var saved = data.get(field, {})
		state.set(field, saved.duplicate(true) if saved is Dictionary else {})
	var records = data.get("personal_bests", {})
	state.personal_bests = records.duplicate(true) if records is Dictionary else {}
	for field in ["earnings", "streak", "deliveries"]:
		state.personal_bests[field] = maxi(0, int(state.personal_bests.get(field, 0)))
	if not state.personal_bests.has("routes") or not state.personal_bests["routes"] is Dictionary:
		state.personal_bests["routes"] = {}
	# Migrate only the historical stamps that actually exist in an older save.
	if int(data.get("version", 1)) < 2:
		for job in state.history:
			if job.get("cancelled", false):
				continue
			var cluster: String = job.get("cluster", "")
			if cluster != "":
				state.visited_homes[str(job["villa"])] = {"cluster": cluster, "address": job.get("address", "")}
			elif int(job.get("villa", 0)) in [901, 902, 903, 904]:
				state.visited_venues[str(job["villa"])] = job.get("address", "Reception")
		for cluster in ["C1", "C2", "C3", "C4", "C5"]:
			state.collection_claims[cluster] = state.cluster_stamps(cluster) / GameConfig.COLLECTION_STAMP_INTERVAL
	return true


## Session 58: foods that changed name (bubble tea is an iced latte now) read as the new name.
static func renamed_food(food: String) -> String:
	if GameConfig.FOOD_CHANGES_ON and GameConfig.FOOD_RENAMES.has(food):
		return GameConfig.FOOD_RENAMES[food]
	return food


## Deletes the save (New game).
static func delete(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
