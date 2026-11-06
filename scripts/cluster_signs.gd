class_name ClusterSigns
## Session 65: the signs at each cluster's entrance (data: CLUSTER_ENTRANCES), like Louis's
## photo of the real "SIKKA E" sign: a dark green board on a pale blue metal frame with a
## pole. Ours says "Cluster 3" with the Arabic (المجموعة ٣) under it, the house ranges
## with arrows ("Villa 1–50 ←") and an EXIT line. It stands on the verge beside the middle
## lane, facing riders coming in. Beside it: the police sign (scripts/police_sign.gd) and a
## small bilingual STOP sign (قف / STOP) where the lane meets the road.
## scripts/wahat_builder.gd calls build() with the map data.

const BOARD := Vector3(1.7, 2.2, 0.05)
const BOARD_MIDDLE := 2.15             # metres from the ground to the middle of the board
const BOARD_COLOUR := Color(0.05, 0.3, 0.19)
const FRAME_COLOUR := Color(0.66, 0.8, 0.88)  # pale blue metal
const TEXT := Color(0.98, 0.98, 0.96)
const STOP_RED := Color(0.78, 0.08, 0.08)
const POLE_GREY := Color(0.6, 0.62, 0.64)


## Adds a "ClusterSigns" node with every entrance's signs under parent.
static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ClusterSigns"
	parent.add_child(holder)
	var names: Dictionary = map.get("CLUSTER_NAMES", {})
	for entrance: Dictionary in map.get("CLUSTER_ENTRANCES", []):
		var id: String = entrance["cluster"]
		var sign := cluster_sign(id, names.get(id, ""), entrance["left"], entrance["right"])
		sign.name = "ClusterSign_%s" % id
		sign.position = entrance["sign"]
		sign.rotation_degrees.y = entrance["sign_facing"]
		holder.add_child(sign)
		var police := PoliceSign.make()
		police.name = "PoliceSign_%s" % id
		police.position = entrance["police"]
		police.rotation_degrees.y = entrance["police_facing"]
		holder.add_child(police)
		var stop := stop_sign()
		stop.name = "StopSign_%s" % id
		stop.position = entrance["stop"]
		stop.rotation_degrees.y = entrance["stop_facing"]
		holder.add_child(stop)
	for i in map.get("POLICE_SIGNS", []).size():  # a few beside the spine's red tracks
		var spot: Dictionary = map["POLICE_SIGNS"][i]
		var police := PoliceSign.make()
		police.name = "PoliceSign_Track%d" % i
		police.position = spot["position"]
		police.rotation_degrees.y = spot["facing"]
		holder.add_child(police)
	return holder


## The green cluster sign. left / right: [English, Arabic] house ranges for each arrow.
static func cluster_sign(id: String, arabic: String, left: Array, right: Array) -> StaticBody3D:
	var body := StaticBody3D.new()
	var kit := MeshKit.new()
	var half := Vector2(BOARD.x, BOARD.y) * 0.5
	var y0 := BOARD_MIDDLE
	# The pole from the ground, and the pale blue frame round the board.
	kit.cylinder(0.06, 0.07, y0 + half.y + 0.1, FRAME_COLOUR, Vector3(0, (y0 + half.y + 0.1) * 0.5, -0.09), Basis(), 10)
	kit.box(Vector3(0.3, 0.06, 0.3), POLE_GREY, Vector3(0, 0.03, -0.09))
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.06, BOARD.y + 0.12, 0.08), FRAME_COLOUR, Vector3(side * (half.x + 0.03), y0, -0.02))
		kit.box(Vector3(BOARD.x + 0.12, 0.06, 0.08), FRAME_COLOUR, Vector3(0, y0 + side * (half.y + 0.03), -0.02))
	kit.box(Vector3(BOARD.x - 0.2, 0.05, 0.05), FRAME_COLOUR, Vector3(0, y0 - 0.4, -0.06))  # back brace
	kit.box(BOARD, BOARD_COLOUR, Vector3(0, y0, 0))
	# A thin white border line on the front, and the dividers between the parts.
	var front := BOARD.z * 0.5 + 0.004
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.025, BOARD.y - 0.12, 0.006), TEXT, Vector3(side * (half.x - 0.06), y0, front))
		kit.box(Vector3(BOARD.x - 0.12, 0.025, 0.006), TEXT, Vector3(0, y0 + side * (half.y - 0.06), front))
	for y in [0.37, -0.68]:
		kit.box(Vector3(BOARD.x - 0.3, 0.02, 0.006), TEXT, Vector3(0, y0 + y, front))
	# The three arrows: left, right and down (the way out).
	var arrow_x := half.x - 0.32
	_arrow(kit, Vector3(arrow_x, y0 + 0.08, front), PI)
	_arrow(kit, Vector3(arrow_x, y0 - 0.36, front), 0.0)
	_arrow(kit, Vector3(arrow_x, y0 - 0.86, front), -PI * 0.5)
	body.add_child(kit.finish("Sign"))
	LowPoly.solid_cylinder(body, 0.1, y0 + half.y, Vector3(0, (y0 + half.y) * 0.5, -0.09))
	# The words: Cluster N with the Arabic under it, the two ranges and EXIT.
	var z := front + 0.006
	var english := "Cluster " + id.substr(1)
	_text(body, english, _fit(english, 64, BOARD.x - 0.4), Vector3(0, y0 + 0.82, z))
	_text(body, arabic, _fit(arabic, 60, BOARD.x - 0.4), Vector3(0, y0 + 0.55, z))
	var left_x := -half.x + 0.16
	var range_width := BOARD.x - 0.75
	var size := mini(_fit(left[0], 34, range_width), _fit(right[0], 34, range_width))
	_text(body, left[0], size, Vector3(left_x, y0 + 0.16, z), true)
	_text(body, left[1], size - 4, Vector3(left_x, y0 - 0.02, z), true)
	_text(body, right[0], size, Vector3(left_x, y0 - 0.28, z), true)
	_text(body, right[1], size - 4, Vector3(left_x, y0 - 0.46, z), true)
	_text(body, "EXIT", size, Vector3(left_x, y0 - 0.86, z), true)
	_text(body, "خروج", size - 2, Vector3(left_x + 0.62, y0 - 0.86, z), true)
	# The back (seen by riders leaving): the cluster's name again, plain.
	var back := SignText.make_face(arabic, english, _fit(english, 48, BOARD.x - 0.5), TEXT)
	back.name = "Back"
	back.position = Vector3(0, y0 + 0.5, -BOARD.z * 0.5 - 0.01)
	back.rotation.y = PI
	body.add_child(back)
	body.set_meta("ranges", [left[0], right[0]])
	return body


## The small STOP sign on a grey pole: a red octagon with a white rim, قف above STOP.
static func stop_sign() -> StaticBody3D:
	var body := StaticBody3D.new()
	var kit := MeshKit.new()
	var y := 2.0
	var r := 0.36
	kit.cylinder(0.04, 0.045, y, POLE_GREY, Vector3(0, y * 0.5, -0.04), Basis(), 8)
	var flat := Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 8.0)  # facing +z, flat on top
	kit.cylinder(r + 0.03, r + 0.03, 0.02, TEXT, Vector3(0, y, 0), flat, 8)
	kit.cylinder(r, r, 0.02, STOP_RED, Vector3(0, y, 0.012), flat, 8)
	kit.cylinder(r + 0.03, r + 0.03, 0.02, POLE_GREY.darkened(0.2), Vector3(0, y, -0.02), flat, 8)
	body.add_child(kit.finish("Sign"))
	LowPoly.solid_cylinder(body, 0.08, y, Vector3(0, y * 0.5, -0.04))
	var face := SignText.make_face("قف", "STOP", 30, TEXT)
	face.name = "Face"
	face.position = Vector3(0, y - 0.02, 0.03)
	body.add_child(face)
	return body


## A flat white arrow on the board. turn: 0 points right, PI left, -PI/2 down.
static func _arrow(kit: MeshKit, at: Vector3, turn: float) -> void:
	var spin := Basis(Vector3.BACK, turn)
	var flat := Basis(Vector3.RIGHT, PI * 0.5)
	kit.box(Vector3(0.24, 0.05, 0.006), TEXT, at + spin * Vector3(-0.07, 0, 0), spin)
	kit.cylinder(0.1, 0.1, 0.006, TEXT, at + spin * Vector3(0.08, 0, 0), spin * flat, 3)


static func _text(body: Node3D, words: String, size: int, at: Vector3, from_left := false) -> Label3D:
	var label := SignText.make_label(words, size, TEXT, Color(0, 0, 0, 0), 0)
	if from_left:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.position = at
	body.add_child(label)
	return label


## The biggest font size (up to max_size) at which words fit in width metres.
static func _fit(words: String, max_size: int, width: float) -> int:
	var size := max_size
	while size > 10 and SignText.text_width(words, size) > width:
		size -= 2
	return size
