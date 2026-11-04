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
## Session 53: two signs per cluster, one at each entrance (the spine side, where the link
## path comes in, and the ring-road side, where the middle lane meets the ring road). Each
## stands beside its lane on the house side, clear of every road, facing riders coming in.
## The old version put signs at both ends of every lane, some right on a lane's middle line
## (in the road) and some with their posts inside each other's.
static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ClusterSigns"
	parent.add_child(holder)
	var names: Dictionary = map["CLUSTER_NAMES"]
	for cluster: Dictionary in map["CLUSTERS"]:
		var id: String = cluster["id"]
		if not names.has(id):
			continue
		var centre: Vector2 = cluster["centre"]
		var area: Rect2 = cluster["area"]
		var outward := -1.0 if centre.y < 0.0 else 1.0   # towards the ring road
		var inner_edge := area.position.y if outward > 0.0 else area.end.y
		var outer_edge := area.end.y if outward > 0.0 else area.position.y
		var side := centre.x + GameConfig.CLUSTER_SIGN_SIDE
		# The spine side: just outside the cluster, beside the link path, facing the spine.
		var spine_z := clear_spot(map, side, inner_edge - outward * GameConfig.CLUSTER_SIGN_INSET, -outward)
		_add_sign(holder, id, names[id], Vector2(side, spine_z), Vector2(0.0, outward))
		# The ring-road side: inside the cluster edge, beside the middle lane, facing the road.
		var ring_z := clear_spot(map, side, outer_edge - outward * GameConfig.CLUSTER_SIGN_INSET, -outward)
		_add_sign(holder, id, names[id], Vector2(side, ring_z), Vector2(0.0, -outward))
	return holder


## The nearest z (from "start", stepping half a metre in direction "step") where a sign at x
## doesn't touch any road or path from the map. Signs never stand in a road.
static func clear_spot(map: Dictionary, x: float, start: float, step: float) -> float:
	var z := start
	for i in 40:
		var footprint := Rect2(x - BOARD.x * 0.5 - 0.2, z - 0.3, BOARD.x + 0.4, 0.6)
		if not touches_road(map, footprint):
			return z
		z += step * 0.5
	return start


## True if the rectangle (seen from above) overlaps any road, lane or path in the map.
static func touches_road(map: Dictionary, area: Rect2) -> bool:
	for road: Dictionary in map["ROADS"]:
		if road_rect(road, map.get("ROAD_WIDTH", 6.0)).intersects(area):
			return true
	return false


## A road's area seen from above (roads run along x or z; a slanted one gets its bounding box).
static func road_rect(road: Dictionary, default_width := 6.0) -> Rect2:
	var width: float = road.get("width", default_width)
	var a: Vector2 = road["from"]
	var b: Vector2 = road["to"]
	var box := Rect2(a, Vector2.ZERO).expand(b)
	return box.grow(width * 0.5)


## One sign at "spot"; "into": the way riders are going when they read it.
static func _add_sign(holder: Node3D, id: String, arabic: String, spot: Vector2, into: Vector2) -> void:
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
