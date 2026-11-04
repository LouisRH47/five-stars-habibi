class_name SlidingDoor
extends Node3D
## Session 57: a glass shop door with two panels that slide apart when you walk up (or
## ride up on the bike), and slide shut again when you leave. Only for looks: the doorway
## itself is always open, so nothing can get stuck. Numbers in game_config.gd (Session 57).

## How wide the doorway is; each panel is half of it.
var width := 2.4
## How tall the panels are.
var height := 2.5
## A closed door that never opens (the pharmacy is scenery only).
var locked := false
## 0 = shut, 1 = fully open.
var open_amount := 0.0

var _panels: Array[Node3D] = []
var _check_left := 0.0
var _wanted := 0.0


## Builds the two glass panels. glass: the see-through material, frame: the edge colour.
func build(glass: Material, frame: Color) -> void:
	for side in [-1.0, 1.0]:
		var panel := Node3D.new()
		panel.name = "Panel" + ("Left" if side < 0.0 else "Right")
		add_child(panel)
		var pane := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width * 0.5 - 0.04, height - 0.08, 0.04)
		pane.mesh = mesh
		pane.material_override = glass
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pane.position = Vector3(0, height * 0.5, 0)
		panel.add_child(pane)
		# A thin dark edge on the meeting side and a handle bar, so you can see it's a door.
		LowPoly.box(panel, Vector3(0.05, height, 0.06), frame, Vector3(-side * (width * 0.25 - 0.03), height * 0.5, 0))
		LowPoly.box(panel, Vector3(0.03, 0.9, 0.08), frame.lightened(0.5), Vector3(-side * (width * 0.25 - 0.15), 1.05, 0.04))
		panel.set_meta("side", side)
		_panels.append(panel)
	_place_panels()
	set_process(not locked)


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.15
		_wanted = 1.0 if _someone_near() else 0.0
	var before := open_amount
	open_amount = move_toward(open_amount, _wanted, delta * GameConfig.PLAZA_DOOR_SPEED)
	if open_amount != before:
		_place_panels()


func _someone_near() -> bool:
	var reach := GameConfig.PLAZA_DOOR_OPEN_DISTANCE
	var tree := get_tree()
	var bike := tree.get_first_node_in_group("bike") as Node3D
	if bike != null and bike.global_position.distance_squared_to(global_position) < reach * reach:
		return true
	var scene := tree.current_scene
	var walker := scene.get_node_or_null("Walker") as Node3D if scene != null else null
	return walker != null and walker.visible and walker.global_position.distance_squared_to(global_position) < reach * reach


func _place_panels() -> void:
	for panel in _panels:
		var side: float = panel.get_meta("side")
		# Shut: the panels meet in the middle. Open: each slides behind the glass beside it.
		panel.position = Vector3(side * width * 0.25 * (1.0 + 1.9 * open_amount), 0, 0)
