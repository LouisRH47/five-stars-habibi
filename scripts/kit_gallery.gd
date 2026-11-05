extends Node3D
## Session 53: a row of every model from each free kit (assets/kits/), so you can see
## what's there. Open scenes/kit_gallery.tscn and press F6. Fly round with the mouse
## wheel (zoom) and the arrow keys (move).

const SPACING := 3.0


func _ready() -> void:
	var row := 0
	for pack: String in Props.KIT_PACKS:
		var names := kit_names(pack)
		var title := SignText.make_label(pack.capitalize() + " (%d models)" % names.size(), 64, Color.WHITE, Color.BLACK, 8)
		title.position = Vector3(-4, 1, row * 6.0)
		add_child(title)
		for i in names.size():
			Props.kit(pack + "/" + names[i], self, Vector3(i * SPACING, 0, row * 6.0))
			var label := SignText.make_label(names[i], 18, Color.WHITE, Color.BLACK, 4)
			label.position = Vector3(i * SPACING, 2.6, row * 6.0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)
		row += 1
	# Plus the props built in code for the interiors (Session 54).
	var z := row * 6.0
	RoomProps.drinks_fridge(self, Vector3(0, 0, z))
	RoomProps.bin(self, Vector3(SPACING, 0, z))
	RoomProps.big_plant(self, Vector3(SPACING * 2, 0, z))
	RoomProps.pendant_lamp(self, Vector3(SPACING * 3, 0, z), Color(0.8, 0.2, 0.1), 3.0)


## The model names in one kit (works in the editor and in an exported game).
static func kit_names(pack: String) -> Array[String]:
	var names: Array[String] = []
	for file in DirAccess.get_files_at(Props.KIT_PACKS[pack]):
		var base := file.trim_suffix(".import")
		if base.ends_with(".gltf") and not base.get_basename() in names:
			names.append(base.get_basename())
	names.sort()
	return names


func _process(delta: float) -> void:
	var camera := $Camera3D as Camera3D
	var move := Vector3(Input.get_axis("ui_left", "ui_right"), 0, Input.get_axis("ui_up", "ui_down"))
	camera.position += move * delta * 12.0
