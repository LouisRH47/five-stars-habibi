class_name BuggyRoads
extends RefCounted
## Session 64: the golf buggies' road map. Made from the ROADS list in the map data, so a new
## lane (like the spine buggy road or a car park buggy lane) is used as soon as it's in the
## data. What's left out:
##   - the black car roads (GameConfig.BLACK_ROADS: ring road, gate roads, highway, bus road),
##     plus a strip GameConfig.BUGGY_BLACK_ROAD_GAP wide beside them, so a buggy never drives
##     on them or along them. Lanes that run into a black road stop before it.
##   - paths whose name has a word from GameConfig.BUGGY_NO_GO_WORDS (the red walking track,
##     the bike and horse tracks, door paths) and very thin paths.
##   - any stretch with something solid on it (checked with physics by check_clear()).
## Every crossing and T-junction becomes a "node"; the stretches between them are "edges".
## Buggies drive on the right: driving_line() moves the route to the right of the middle.

## Where each node is (x, z).
var nodes: Array[Vector2] = []
## For each node, the nodes it joins to.
var links: Array = []
## Which road each edge belongs to, by edge key (see key()).
var road_of := {}
## How far right of the middle buggies keep on each edge (metres), by edge key.
var keep_of := {}
## The black roads, grown by the gap: no buggy route point may be inside these.
var no_go: Array[Rect2] = []
## Edges that check_clear() found blocked: {key: what was in the way}.
var blocked := {}
## Every buggy driving on this map (so they can keep out of each other's way).
var drivers: Array = []

var _astar := AStar2D.new()
var _bollards: Array[Vector2] = []


## Builds the road map from the map data (data/wahat_al_shams.gd's constants).
static func build(map: Dictionary) -> BuggyRoads:
	var roads := BuggyRoads.new()
	roads._build(map)
	return roads


## True if buggies may use this road (by its name and width).
static func allowed(road: Dictionary) -> bool:
	var name := String(road.get("name", ""))
	if name in GameConfig.BLACK_ROADS:
		return false
	var low := name.to_lower()
	var thinnest: float = GameConfig.BUGGY_LANE_MIN_WIDTH if low.contains("buggy") else GameConfig.BUGGY_MIN_ROAD_WIDTH
	if float(road.get("width", 6.0)) < thinnest:
		return false
	for word: String in GameConfig.BUGGY_NO_GO_WORDS:
		if low.contains(word):
			return false
	return true


## The black roads as rectangles, grown by `gap` metres all round.
static func black_rects(map: Dictionary, gap: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for road: Dictionary in map.get("ROADS", []):
		if String(road["name"]) in GameConfig.BLACK_ROADS:
			var a: Vector2 = road["from"]
			var b: Vector2 = road["to"]
			out.append(Rect2(a, Vector2.ZERO).expand(b).grow(float(road.get("width", 10.0)) * 0.5 + gap))
	return out


## The same key for an edge whichever way round it's given.
static func key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]


## The right-hand side of a heading (x east, z south): facing north, right is east.
static func right_of(way: Vector2) -> Vector2:
	return Vector2(-way.y, way.x)


## The node nearest to a spot.
func nearest_node(spot: Vector2) -> int:
	return _astar.get_closest_point(spot) if not nodes.is_empty() else -1


## The nodes along the shortest way from one node to another ([] if there's none).
## avoid: an edge [a, b] not to use (where something was in the way).
func path(from: int, to: int, avoid: Array = []) -> Array[int]:
	var out: Array[int] = []
	if from < 0 or to < 0:
		return out
	var cut := avoid.size() == 2 and _astar.are_points_connected(avoid[0], avoid[1])
	if cut:
		_astar.disconnect_points(avoid[0], avoid[1])
	for id in _astar.get_id_path(from, to):
		out.append(int(id))
	if cut:
		_astar.connect_points(avoid[0], avoid[1])
	return out


## Every node a buggy can get to (all of them: only the biggest joined-up part is kept).
func node_count() -> int:
	return nodes.size()


## The names of the roads buggies use.
func road_names() -> Array[String]:
	var out: Array[String] = []
	for name: String in road_of.values():
		if not name in out:
			out.append(name)
	return out


## Where to drive (keeping right) along a list of nodes. came: the way the buggy was going
## when it got to the first node (Vector2.ZERO if not known). Corners are cut a little so
## turns are smooth, and a turn back the way it came is a little U-turn.
## Returns {"points": Array[Vector3], "edges": [[from, to], ...] (the edge each point is on)}.
func driving_line(route: Array[int], came := Vector2.ZERO) -> Dictionary:
	var points: Array[Vector3] = []
	var edges: Array = []
	var round_off: float = GameConfig.BUGGY_CORNER_ROUND
	for k in route.size():
		var here := nodes[route[k]]
		var has_out := k < route.size() - 1
		var way_out := (nodes[route[k + 1]] - here).normalized() if has_out else Vector2.ZERO
		var way_in := came if k == 0 else (here - nodes[route[k - 1]]).normalized()
		var keep_in: float = keep_of.get(key(route[k - 1], route[k]), GameConfig.BUGGY_KEEP_RIGHT) if k > 0 else 0.0
		var keep_out: float = keep_of.get(key(route[k], route[k + 1]), GameConfig.BUGGY_KEEP_RIGHT) if has_out else 0.0
		if k == 0:
			keep_in = keep_out if has_out else GameConfig.BUGGY_KEEP_RIGHT
		if not has_out:
			keep_out = keep_in
		var edge_in := [route[k - 1], route[k]] if k > 0 else [route[k], route[k + 1] if has_out else route[k]]
		var edge_out := [route[k], route[k + 1]] if has_out else edge_in
		var len_in := here.distance_to(nodes[route[k - 1]]) if k > 0 else 4.0
		var len_out := here.distance_to(nodes[route[k + 1]]) if has_out else 4.0
		if way_in == Vector2.ZERO:   # the start, with no way in: just the right side
			_add(points, edges, here + right_of(way_out) * keep_out, edge_out)
			continue
		if not has_out:              # the end: stop on the right side
			_add(points, edges, here + right_of(way_in) * keep_in, edge_in)
			continue
		var turn := absf(way_in.angle_to(way_out))
		var side_in := here + right_of(way_in) * keep_in
		var side_out := here + right_of(way_out) * keep_out
		if turn > 2.6:               # back the way it came: a little U-turn
			_add(points, edges, side_in, edge_in)
			_add(points, edges, here + way_in * minf(1.2, keep_in), edge_in)
			_add(points, edges, side_out, edge_out)
		elif turn < 0.1:             # straight on (move over gently if the keep changes)
			if absf(keep_in - keep_out) > 0.05:
				var ease := minf(1.5, minf(len_in, len_out) * 0.4)
				_add(points, edges, side_in - way_in * ease, edge_in)
				_add(points, edges, side_out + way_out * ease, edge_out)
		else:                        # a corner: meet where the two right-side lines cross
			var corner: Variant = Geometry2D.line_intersects_line(side_in, way_in, side_out, way_out)
			var at: Vector2 = corner if corner != null else here
			var cut := minf(round_off, minf(len_in, len_out) * 0.4)
			_add(points, edges, at - way_in * cut, edge_in)
			_add(points, edges, at + way_out * cut, edge_out)
	return {"points": points, "edges": edges}


## True if a spot (x, z) is inside a black road or the strip beside it.
func in_no_go(spot: Vector2) -> bool:
	for area in no_go:
		if area.has_point(spot):
			return true
	return false


## Looks along every edge, on both sides, for anything solid at buggy height (walls, posts,
## playgrounds, a gardener who stands still...) and drops edges that are blocked, then keeps
## only the biggest joined-up part again. Call it when the world's bodies are in place.
## Returns how many edges were dropped.
func check_clear(world: World3D) -> int:
	var space := world.direct_space_state
	var box := BoxShape3D.new()
	var query := PhysicsShapeQueryParameters3D.new()
	query.collide_with_areas = false
	var dropped := 0
	for a in nodes.size():
		for b: int in links[a].duplicate():
			if b < a:
				continue
			var hit := _edge_hit(space, query, box, a, b)
			if hit == "":
				hit = _edge_hit(space, query, box, b, a)
			if hit != "":
				blocked[key(a, b)] = hit
				_unlink(a, b)
				dropped += 1
	if dropped > 0:
		_keep_biggest_part()
	return dropped


# ---------------------------------------------------------------------------------------

func _build(map: Dictionary) -> void:
	no_go = black_rects(map, GameConfig.BUGGY_BLACK_ROAD_GAP)
	for spot: Vector2 in map.get("BOLLARDS", []):
		_bollards.append(spot)
	# 1) The usable bits of every allowed road, cut short where they near a black road.
	var pieces: Array = []
	for road: Dictionary in map.get("ROADS", []) + map.get("BUGGY_LANES", []):
		if not allowed(road):
			continue
		for part: Array in _clip(road["from"], road["to"]):
			if (part[0] as Vector2).distance_to(part[1]) >= 2.0:
				pieces.append({"a": part[0], "b": part[1], "width": float(road.get("width", 6.0)), "name": road["name"]})
	# 2) Where pieces cross or one ends on another: cut both there.
	var cuts: Array = []
	for piece: Dictionary in pieces:
		cuts.append([0.0, 1.0])
	for i in pieces.size():
		for j in range(i + 1, pieces.size()):
			_join(pieces, cuts, i, j)
			_join(pieces, cuts, j, i)
			var cross: Variant = Geometry2D.segment_intersects_segment(pieces[i]["a"], pieces[i]["b"], pieces[j]["a"], pieces[j]["b"])
			if cross != null:
				cuts[i].append(_along(pieces[i], cross))
				cuts[j].append(_along(pieces[j], cross))
	# 3) Nodes at the cuts, edges between them.
	for i in pieces.size():
		var list: Array = cuts[i]
		list.sort()
		var last := -1
		for t: float in list:
			var spot: Vector2 = (pieces[i]["a"] as Vector2).lerp(pieces[i]["b"], clampf(t, 0.0, 1.0))
			var id := _node_at(spot)
			if last >= 0 and last != id:
				_link(last, id, pieces[i])
			last = id
	_keep_biggest_part()


## The parts of a line from a to b that stay out of every no-go rectangle.
func _clip(a: Vector2, b: Vector2) -> Array:
	var spans: Array = []
	for area in no_go:
		var t := _inside(a, b, area)
		if t.x < t.y:
			spans.append(t)
	spans.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	var out: Array = []
	var start := 0.0
	for span: Vector2 in spans:
		if span.x > start:
			out.append([a.lerp(b, start), a.lerp(b, span.x)])
		start = maxf(start, span.y)
	if start < 1.0:
		out.append([a.lerp(b, start), b])
	return out


## The part (from t.x to t.y, 0 to 1 along a to b) inside a rectangle; t.x >= t.y if none.
static func _inside(a: Vector2, b: Vector2, area: Rect2) -> Vector2:
	var t := Vector2(0.0, 1.0)
	var gap := b - a
	for axis in 2:
		var low: float = area.position[axis]
		var high: float = area.end[axis]
		if absf(gap[axis]) < 0.000001:
			if a[axis] < low or a[axis] > high:
				return Vector2(1.0, 0.0)
		else:
			var ta: float = (low - a[axis]) / gap[axis]
			var tb: float = (high - a[axis]) / gap[axis]
			t.x = maxf(t.x, minf(ta, tb))
			t.y = minf(t.y, maxf(ta, tb))
	return t


## If an end of piece i stops on piece j (a T-junction), cut j there and move i's end onto it.
func _join(pieces: Array, cuts: Array, i: int, j: int) -> void:
	for end in ["a", "b"]:
		var spot: Vector2 = pieces[i][end]
		var near := Geometry2D.get_closest_point_to_segment(spot, pieces[j]["a"], pieces[j]["b"])
		if spot.distance_to(near) <= pieces[j]["width"] * 0.5 + 0.6:
			cuts[j].append(_along(pieces[j], near))
			cuts[i].append(0.0 if end == "a" else 1.0)
			pieces[i][end] = near


static func _along(piece: Dictionary, spot: Vector2) -> float:
	var a: Vector2 = piece["a"]
	var b: Vector2 = piece["b"]
	return clampf((spot - a).dot(b - a) / maxf(a.distance_squared_to(b), 0.0001), 0.0, 1.0)


## The node at this spot (an existing one within 1 m, or a new one).
func _node_at(spot: Vector2) -> int:
	for i in nodes.size():
		if nodes[i].distance_to(spot) < 1.0:
			return i
	nodes.append(spot)
	links.append([])
	return nodes.size() - 1


func _link(a: int, b: int, piece: Dictionary) -> void:
	if b in links[a]:
		return
	links[a].append(b)
	links[b].append(a)
	road_of[key(a, b)] = piece["name"]
	keep_of[key(a, b)] = _keep_for(nodes[a], nodes[b], piece["width"])


func _unlink(a: int, b: int) -> void:
	links[a].erase(b)
	links[b].erase(a)
	road_of.erase(key(a, b))
	keep_of.erase(key(a, b))


## How far right of the middle to keep on this stretch: GameConfig.BUGGY_KEEP_RIGHT, less on
## a narrow path, and less where there are bollards at the lane entrance to squeeze past.
func _keep_for(a: Vector2, b: Vector2, width: float) -> float:
	var keep := minf(GameConfig.BUGGY_KEEP_RIGHT, width * 0.5 - GameConfig.BUGGY_HALF_WIDTH - 0.2)
	for post in _bollards:
		var near := Geometry2D.get_closest_point_to_segment(post, a, b)
		var beside := post.distance_to(near)
		if beside < width * 0.5 + 0.3:
			keep = minf(keep, beside - GameConfig.BUGGY_POST_CLEARANCE)
	return maxf(keep, 0.0)


## Throws away every node that isn't joined to the biggest group (little bits on their own).
func _keep_biggest_part() -> void:
	var group := PackedInt32Array()
	group.resize(nodes.size())
	group.fill(-1)
	var sizes: Array[int] = []
	for start in nodes.size():
		if group[start] >= 0:
			continue
		var id := sizes.size()
		var queue: Array[int] = [start]
		group[start] = id
		var count := 0
		while not queue.is_empty():
			var n: int = queue.pop_back()
			count += 1
			for m: int in links[n]:
				if group[m] < 0:
					group[m] = id
					queue.append(m)
		sizes.append(count)
	var best := sizes.find(sizes.max()) if not sizes.is_empty() else -1
	var old_nodes := nodes.duplicate()
	var old_links := links.duplicate(true)
	var old_road := road_of.duplicate()
	var old_keep := keep_of.duplicate()
	var new_id := {}
	nodes = []
	links = []
	road_of = {}
	keep_of = {}
	for i in old_nodes.size():
		if group[i] == best and (sizes[best] > 1):
			new_id[i] = nodes.size()
			nodes.append(old_nodes[i])
			links.append([])
	for i: int in new_id:
		for j: int in old_links[i]:
			if new_id.has(j) and not new_id[j] in links[new_id[i]]:
				links[new_id[i]].append(new_id[j])
				links[new_id[j]].append(new_id[i])
				road_of[key(new_id[i], new_id[j])] = old_road[key(i, j)]
				keep_of[key(new_id[i], new_id[j])] = old_keep[key(i, j)]
	_astar.clear()
	for i in nodes.size():
		_astar.add_point(i, nodes[i])
	for i in nodes.size():
		for j: int in links[i]:
			if j > i:
				_astar.connect_points(i, j)


## What's in the way driving from node a to node b on the right side ("" if nothing).
func _edge_hit(space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, box: BoxShape3D, a: int, b: int) -> String:
	var way := (nodes[b] - nodes[a]).normalized()
	var keep: float = keep_of[key(a, b)]
	var from := nodes[a] + right_of(way) * keep + way * 1.5
	var to := nodes[b] + right_of(way) * keep - way * 1.5
	var length := from.distance_to(to)
	if length < 0.5 or from.dot(way) > to.dot(way):
		return ""
	var steps := ceili(length / 2.0)
	box.size = Vector3((GameConfig.BUGGY_HALF_WIDTH + 0.15) * 2.0, 1.2, length / steps)
	query.shape = box
	var basis := Basis(Vector3.UP, atan2(way.x, way.y))
	for s in steps:
		var middle := from.lerp(to, (s + 0.5) / steps)
		query.transform = Transform3D(basis, Vector3(middle.x, 0.95, middle.y))
		for hit in space.intersect_shape(query, 8):
			var thing: Object = hit["collider"]
			if thing is Node and _ignore(thing as Node):
				continue
			return "%s at (%d, %d)" % [(thing as Node).name if thing is Node else "?", middle.x, middle.y]
	return ""


## Moving things and the player don't block a road for good (a gardener standing still does).
static func _ignore(thing: Node) -> bool:
	if thing.is_in_group("bike") or thing.name == "Walker" or thing.is_in_group("road_works"):
		return true
	if thing.is_in_group("critter"):
		return thing.get("kind") != "gardener"
	return false


static func _add(points: Array[Vector3], edges: Array, spot: Vector2, edge: Array) -> void:
	points.append(Vector3(spot.x, 0.0, spot.y))
	edges.append(edge)
