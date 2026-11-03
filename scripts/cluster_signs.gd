class_name ClusterSigns
## The bilingual cluster signs (Session 26): "المجموعة ١ / Cluster 1" at the ends of each
## cluster's side lanes, where you ride in from the ring road or the spine. They stand just
## off the lane, on the outside of the cluster, and read from both sides.
## scripts/wahat_builder.gd calls build() with the map data (ROADS and CLUSTER_NAMES).

const BOARD := Vector3(2.4, 1.2, 0.12)
const BOARD_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)
const POST_COLOUR := Color(0.9, 0.9, 0.9, 1)
const BOARD_HEIGHT := 2.0   # metres from the ground to the middle of the board


## Adds a "ClusterSigns" node full of signs under parent.
static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ClusterSigns"
	parent.add_child(holder)
	var names: Dictionary = map["CLUSTER_NAMES"]
	# The side lanes of each cluster run north to south (same x at both ends).
	var lanes := {}
	for road in map["ROADS"]:
		var id := String(road["name"]).get_slice(" ", 0)
		if names.has(id) and is_equal_approx(road["from"].x, road["to"].x):
			lanes[id] = lanes.get(id, []) + [road]
	for id in lanes:
		var middle := 0.0
		for road in lanes[id]:
			middle += road["from"].x / lanes[id].size()
		for road in lanes[id]:
			for end in [[road["from"], road["to"]], [road["to"], road["from"]]]:
				_add_sign(holder, id, names[id], end[0], end[1], middle)
	return holder


## One sign near the lane end "end" (the lane runs on to "other").
static func _add_sign(holder: Node3D, id: String, arabic: String, end: Vector2, other: Vector2,
		cluster_x: float) -> void:
	var into := (other - end).normalized()
	var outside := signf(end.x - cluster_x)
	var spot := end + into * GameConfig.CLUSTER_SIGN_INSET + Vector2(outside * GameConfig.CLUSTER_SIGN_SIDE, 0)
	var board := StaticBody3D.new()
	board.name = "ClusterSign_%s_%d" % [id, holder.get_child_count()]
	board.position = Vector3(spot.x, 0, spot.y)
	board.rotation.y = atan2(-into.x, -into.y)  # the front faces riders coming in
	holder.add_child(board)
	LowPoly.box(board, BOARD, BOARD_COLOUR, Vector3(0, BOARD_HEIGHT, 0))
	for x in [-0.95, 0.95]:
		LowPoly.box(board, Vector3(0.12, BOARD_HEIGHT - 0.5, 0.12), POST_COLOUR, Vector3(x, (BOARD_HEIGHT - 0.5) * 0.5, 0))
		LowPoly.solid_box(board, Vector3(0.2, BOARD_HEIGHT + 0.6, 0.2), Vector3(x, (BOARD_HEIGHT + 0.6) * 0.5, 0))
	var english := "Cluster " + id.substr(1)
	var size := SignText.fit_size(arabic, english, 64, BOARD.x - 0.4)
	var faces := SignText.make_two_faces(arabic, english, size, Color.WHITE, BOARD.z)
	faces.position.y = BOARD_HEIGHT
	board.add_child(faces)
