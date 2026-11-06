extends VBoxContainer
## Session 89: the phone's Map app. Its button closes the phone and opens the big map
## (the same one as M: scripts/full_map.gd, made by the HUD).

signal close_phone

var _missing: Label


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var picture := PanelContainer.new()
	picture.custom_minimum_size.y = 300
	picture.add_theme_stylebox_override("panel", PhoneUI.flat(PhoneUI.SAND, 18, 20))
	picture.add_child(PhoneGlyph.make("map", Color("4f9fd6"), 220, PhoneUI.RED))
	add_child(picture)
	add_child(PhoneUI.label("The whole of Wahat Al Shams: the roads, the parks, the Plaza and every cluster, with your pick-up and drop-off.", 16))
	var open_button := PhoneUI.button("Open the big map  ·  M", PhoneUI.ORANGE)
	open_button.name = "OpenMap"
	open_button.pressed.connect(open_map)
	add_child(open_button)
	_missing = PhoneUI.label("There's no map on this screen.", 15, PhoneUI.RED)
	_missing.visible = false
	add_child(_missing)
	add_child(PhoneUI.label("M or Esc closes the map again.", 15, PhoneUI.SOFT))


func refresh() -> void:
	_missing.visible = full_map() == null


## The HUD's big map in this world, or null.
func full_map() -> Node:
	var world := get_tree().current_scene
	return world.find_child("FullMap", true, false) if world != null else null


## Closes the phone (the game runs again for a moment), then opens the big map, which
## pauses the game itself. True if the map opened.
func open_map() -> bool:
	var map := full_map()
	if map == null:
		_missing.visible = true
		return false
	close_phone.emit()
	return map.open()
