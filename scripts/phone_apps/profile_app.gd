extends VBoxContainer
## Session 89: the phone's Profile app. Your name, company, country and home, your stars,
## your Rider Level with the XP bar ("72 XP to level 7"), your career tier and what the
## next tier needs (PRD career ladder), lifetime numbers, and a button to the stamp card
## and neighbours page (scripts/profile_page.gd). It reads everything from GameState.


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	refresh()


func refresh() -> void:
	PhoneUI.clear(self)
	var state := get_tree().root.get_node("GameState")
	add_child(_who(state))
	add_child(_level_card(state))
	add_child(_career_card(state))
	add_child(_lifetime(state))
	var stamps := PhoneUI.button("Stamp card & neighbours  ›")
	stamps.name = "StampCard"
	stamps.pressed.connect(func():
		var shell := PhoneApp.of(self)
		if shell != null:
			shell.open_profile_page())
	add_child(stamps)


## Your picture (your first letter in your company's colour), name, details and stars.
func _who(state: Node) -> Control:
	var company := Companies.current()
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	var face := PanelContainer.new()
	face.custom_minimum_size = Vector2(72, 72)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.add_theme_stylebox_override("panel", PhoneUI.flat(company.get("colour", PhoneUI.ORANGE), 36))
	var rider: String = state.rider_name if state.rider_name != "" else "Rider"
	var letter := PhoneUI.label(rider.left(1).to_upper(), 36, Color.WHITE, "Heading")
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face.add_child(letter)
	line.add_child(face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 2)
	line.add_child(words)
	words.add_child(PhoneUI.label(rider, 30, PhoneUI.INK, "Heading"))
	var bits: Array[String] = [str(company.get("name", "Snackaroo"))]
	if state.rider_country != "":
		bits.append("from " + state.rider_country)
	bits.append("Home: Wahat Al Shams")
	words.add_child(PhoneUI.label("  ·  ".join(bits), 15, PhoneUI.SOFT))
	var stars_line := HBoxContainer.new()
	stars_line.add_theme_constant_override("separation", 8)
	var stars := StarRow.new()
	stars.star_size = 22
	stars.stars = roundf(state.rating() * 2.0) / 2.0
	stars_line.add_child(stars)
	var number := PhoneUI.label("New rider" if state.history.is_empty() else "%.2f" % state.rating(), 17, PhoneUI.INK, "BigNumber")
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	stars_line.add_child(number)
	words.add_child(stars_line)
	return line


func _level_card(state: Node) -> Control:
	var box := PhoneUI.card()
	var rows: VBoxContainer = box.get_child(0)
	var progress: Vector2i = state.level_progress()
	rows.add_child(PhoneUI.caps("Rider Level %d" % state.level()))
	rows.add_child(PhoneUI.bar(float(progress.x) / maxf(progress.y, 1)))
	rows.add_child(PhoneUI.label("%d XP to level %d" % [progress.y - progress.x, state.level() + 1], 16))
	return box


## Tier 1 now; what Tier 2 (Dune Express) needs: 4.0+ stars, 20 deliveries, the motorbike test.
func _career_card(state: Node) -> Control:
	var box := PhoneUI.card()
	var rows: VBoxContainer = box.get_child(0)
	rows.add_child(PhoneUI.caps("Career  ·  Tier 1  ·  Food rider"))
	rows.add_child(PhoneUI.label("Next: Tier 2  ·  Dune Express (motorbike)", 16, PhoneUI.TEAL, "BigNumber"))
	var rating: float = state.rating()
	var stars_ok: bool = not state.history.is_empty() and rating >= GameConfig.CAREER_TIER2_STARS
	rows.add_child(PhoneUI.row("%s  %.1f+ stars" % [_mark(stars_ok), GameConfig.CAREER_TIER2_STARS],
			"%.2f" % rating if not state.history.is_empty() else "-"))
	var count := mini(deliveries(state), GameConfig.CAREER_TIER2_DELIVERIES)
	rows.add_child(PhoneUI.row("%s  %d deliveries" % [_mark(count >= GameConfig.CAREER_TIER2_DELIVERIES), GameConfig.CAREER_TIER2_DELIVERIES],
			"%d/%d" % [count, GameConfig.CAREER_TIER2_DELIVERIES]))
	rows.add_child(PhoneUI.row("•  Motorbike test (%d Dh)" % GameConfig.MOTORBIKE_TEST_PRICE, "Soon", 16, PhoneUI.SOFT))
	return box


## Three tiles: deliveries, Dh earned and the best five-star streak.
func _lifetime(state: Node) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	var earned := 0
	for job: Dictionary in state.history:
		if not job.get("cancelled", false):
			earned += int(job.get("pay", 0)) + int(job.get("tip", 0))
	for pair in [[deliveries(state), "deliveries"], [earned, "Dh earned"], [int(state.personal_bests.get("streak", 0)), "best streak"]]:
		var tile := PhoneUI.card(PhoneUI.CARD, 14, 8)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rows: VBoxContainer = tile.get_child(0)
		rows.add_theme_constant_override("separation", 0)
		var number := PhoneUI.label(_thousands(pair[0]), 24, PhoneUI.INK, "BigNumber")
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.add_child(number)
		var words := PhoneUI.label(pair[1], 14, PhoneUI.SOFT)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.add_child(words)
		grid.add_child(tile)
	return grid


## Deliveries made (not cancelled) in your saved history.
static func deliveries(state: Node) -> int:
	var count := 0
	for job: Dictionary in state.history:
		if not job.get("cancelled", false):
			count += 1
	return count


func _mark(done: bool) -> String:
	return "✓" if done else "•"


## 2310 -> "2,310".
func _thousands(number: int) -> String:
	var text := str(absi(number))
	var out := ""
	while text.length() > 3:
		out = "," + text.right(3) + out
		text = text.left(text.length() - 3)
	return ("-" if number < 0 else "") + text + out
