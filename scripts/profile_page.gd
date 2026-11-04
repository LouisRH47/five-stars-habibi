class_name ProfilePage
extends CanvasLayer
## Lifetime progress has its own page and save fields, so rating history can stay small.
var showing := false
var _root: Control
var _panel: PanelContainer
var _content: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 24
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.06, 0.07, 0.88)
	_root.add_child(shade)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.anchor_left = 0.12
	_panel.anchor_right = 0.88
	_panel.anchor_top = 0.06
	_panel.anchor_bottom = 0.94
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.88)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	_panel.add_child(rows)
	var header := HBoxContainer.new()
	rows.add_child(header)
	var title := _label("Your rider profile", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "Back to riding  ·  P / Esc"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if showing and event.physical_keycode in [KEY_P, KEY_ESCAPE]:
		close()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_P and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	if showing or get_tree().paused:
		return
	_rebuild()
	showing = true
	_root.visible = true
	get_tree().paused = true


func close() -> void:
	if not showing:
		return
	showing = false
	_root.visible = false
	get_tree().paused = false


func _rebuild() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_content.add_child(_label("%s  ·  Level %d  ·  %d Dh" % [GameState.rider_name if GameState.rider_name != "" else "Snackaroo rider", GameState.level(), GameState.money], 22))
	_content.add_child(_label("Wahat Al Shams stamp card  ·  %d / %d homes  ·  %d / %d venues" % [GameState.visited_homes.size(), GameState.home_catalog.size(), GameState.visited_venues.size(), GameState.venue_catalog.size()], 22))
	_content.add_child(_label("Every 25 different homes in a cluster earns 20 Dh. Fill a cluster to unlock its gold delivery box colour. A + marks a visited home.", 16))
	var clusters: Array[String] = []
	for home in GameState.home_catalog.values():
		if not str(home["cluster"]) in clusters:
			clusters.append(str(home["cluster"]))
	clusters.sort()
	for cluster in clusters:
		var homes: Array = []
		for key in GameState.home_catalog:
			if GameState.home_catalog[key]["cluster"] == cluster:
				homes.append({"id": key, "house": GameState.home_catalog[key]["house"], "address": GameState.home_catalog[key]["address"]})
		homes.sort_custom(func(a, b): return a["house"] < b["house"])
		var count := GameState.cluster_stamps(cluster)
		var reward := "  ·  Gold box unlocked!" if GameState.owned_collection_rewards.has(cluster) else ""
		_content.add_child(_label("%s  ·  %d / %d stamps%s" % [cluster, count, homes.size(), reward], 20))
		var grid := GridContainer.new()
		grid.columns = 10
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 5)
		_content.add_child(grid)
		for home in homes:
			var stamped := GameState.visited_homes.has(home["id"])
			var stamp := _label("%s %02d" % ["+" if stamped else "-", home["house"]], 16)
			stamp.tooltip_text = home["address"]
			stamp.custom_minimum_size.x = 62
			stamp.add_theme_color_override("font_color", Color(0.15, 0.53, 0.31) if stamped else Color(0.4, 0.44, 0.44))
			grid.add_child(stamp)
	for key in GameState.venue_catalog:
		var status := "Visited" if GameState.visited_venues.has(key) else "Unvisited"
		_content.add_child(_label("%s  ·  %s" % [GameState.venue_catalog[key], status], 18))
	_content.add_child(_label("Neighbours who know you", 24))
	for id in ReplayCatalog.REGULAR_NAMES:
		var stage: String = {"first": "Getting acquainted", "friendly": "Friendly", "best_friends": "Best friends"}[GameState.regular_stage(id)]
		_content.add_child(_label("%s  ·  %d visits  ·  %s" % [ReplayCatalog.REGULAR_NAMES[id], GameState.regular_visits.get(id, 0), stage], 18))
	_content.add_child(_label("Cats and horses you've met  ·  %d" % GameState.animals_met.size(), 24))
	_content.add_child(_label(", ".join(GameState.animals_met.values()) if not GameState.animals_met.is_empty() else "Ride up close and say hello to meet an animal.", 18))
	_content.add_child(_label("Personal bests", 24))
	for row in [["Best shift earnings", "%d Dh" % GameState.personal_bests.get("earnings", 0)], ["Longest five-star streak", str(GameState.personal_bests.get("streak", 0))], ["Most deliveries in a shift", str(GameState.personal_bests.get("deliveries", 0))], ["Fastest routes recorded", str(GameState.personal_bests.get("routes", {}).size())]]:
		_content.add_child(_label("%s  ·  %s" % row, 18))
	var routes: Dictionary = GameState.personal_bests.get("routes", {})
	if not routes.is_empty():
		var reveal := Button.new()
		reveal.text = "View fastest rides"
		_content.add_child(reveal)
		get_tree().root.get_node("TouchControls").fit_touch_widget(reveal)
		var records := VBoxContainer.new()
		records.visible = false
		_content.add_child(records)
		reveal.pressed.connect(func():
			records.visible = not records.visible
			reveal.text = "Hide fastest rides" if records.visible else "View fastest rides"
			if records.get_child_count() == 0:
				for key in routes:
					var route_name: String = GameState.personal_bests.get("route_labels", {}).get(key, "A saved route")
					var seconds := int(routes[key])
					records.add_child(_label("%s  ·  %d:%02d" % [route_name, seconds / 60, seconds % 60], 16)))
	_content.add_child(_label("Customer lines heard  ·  %d" % GameState.lines_heard.size(), 24))
	if GameState.lines_heard.is_empty():
		_content.add_child(_label("Your neighbours' stories will appear here after a delivery.", 18))
	for line in GameState.lines_heard:
		_content.add_child(_label("“%s”" % line, 16))


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.08, 0.25, 0.29))
	return label
