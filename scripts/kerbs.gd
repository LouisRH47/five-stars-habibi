class_name Kerbs
extends RefCounted
## Session 62: kerbstones (a raised stone edge, 0.3 m wide and 0.15 m high).
## - Along both edges of the ring road, all the way round, with an opening wherever a lane,
##   path, car park aisle or horse crossing meets it (Session 53 left these for this session).
## - Round the car parks and their buggy lanes (the rectangles in CARPARK_KERBS).
## They're only for looks: no collision, so the bike rides over them like before.


## The ring road's kerb strips (Rect2 seen from above), with the openings cut out.
static func ring_segments(map: Dictionary) -> Array[Rect2]:
	var ring := _ring_bounds(map)
	if ring.size == Vector2.ZERO:
		return []
	var w: float = GameConfig.KERB_SIZE.x
	var inner := ring.grow(-float(map.get("ROAD_WIDTH", 10.0)) * 0.5)
	var outer := ring.grow(float(map.get("ROAD_WIDTH", 10.0)) * 0.5)
	var lines: Array[Rect2] = []
	# inner kerbs sit just inside the road edge, outer kerbs just outside it
	lines.append(Rect2(inner.position.x, inner.position.y, inner.size.x, w))           # inner north
	lines.append(Rect2(inner.position.x, inner.end.y - w, inner.size.x, w))            # inner south
	lines.append(Rect2(inner.position.x, inner.position.y + w, w, inner.size.y - 2 * w))   # inner west
	lines.append(Rect2(inner.end.x - w, inner.position.y + w, w, inner.size.y - 2 * w))    # inner east
	lines.append(Rect2(outer.position.x - w, outer.position.y - w, outer.size.x + 2 * w, w))  # outer north
	lines.append(Rect2(outer.position.x - w, outer.end.y, outer.size.x + 2 * w, w))          # outer south
	lines.append(Rect2(outer.position.x - w, outer.position.y, w, outer.size.y))            # outer west
	lines.append(Rect2(outer.end.x, outer.position.y, w, outer.size.y))                     # outer east
	var openings := _openings(map)
	var out: Array[Rect2] = []
	for line in lines:
		out.append_array(_cut(line, openings))
	return out


## Everything that needs a way across the kerb: lanes and paths meeting the ring road,
## the car park aisles and the horse crossings.
static func _openings(map: Dictionary) -> Array[Rect2]:
	var holes: Array[Rect2] = []
	for road: Dictionary in map["ROADS"]:
		if road["name"] != "Ring Road":
			holes.append(ClusterSigns.road_rect(road, map.get("ROAD_WIDTH", 6.0)))
	for park: Dictionary in map.get("CAR_PARKS", []):
		for aisle: Rect2 in park["aisles"]:
			holes.append(aisle.grow_individual(0, 1.0, 0, 1.0))
	for crossing: Dictionary in map.get("HORSE_CROSSINGS", []):
		var a: Vector3 = crossing["from"]
		var b: Vector3 = crossing["to"]
		holes.append(Rect2(Vector2(a.x, a.z), Vector2.ZERO).expand(Vector2(b.x, b.z)).grow(3.0))
	return holes


## A kerb line with every opening it crosses cut out. Openings that only run alongside it
## (like a cluster's cross lane just inside the kerb) don't cut it.
static func _cut(line: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var along_x := line.size.x >= line.size.y
	var gaps: Array[Vector2] = []
	for hole in holes:
		var cross := line.intersection(hole)
		if cross.size.x <= 0.05 or cross.size.y <= 0.05:
			continue
		# it must cross the whole kerb width, and be shorter than the kerb (not run along it)
		var across := cross.size.y if along_x else cross.size.x
		var thick := line.size.y if along_x else line.size.x
		var span := hole.size.x if along_x else hole.size.y
		var run := hole.size.y if along_x else hole.size.x
		if across < thick - 0.01 or span > run * 1.5 and span > 12.0:
			continue
		gaps.append(Vector2(cross.position.x, cross.end.x) if along_x else Vector2(cross.position.y, cross.end.y))
	gaps.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
	var start := line.position.x if along_x else line.position.y
	var finish := line.end.x if along_x else line.end.y
	var pieces: Array[Rect2] = []
	for gap in gaps:
		if gap.x > start + 0.05:
			pieces.append(_piece(line, along_x, start, gap.x))
		start = maxf(start, gap.y)
	if finish > start + 0.05:
		pieces.append(_piece(line, along_x, start, finish))
	return pieces


static func _piece(line: Rect2, along_x: bool, a: float, b: float) -> Rect2:
	if along_x:
		return Rect2(a, line.position.y, b - a, line.size.y)
	return Rect2(line.position.x, a, line.size.x, b - a)


static func _ring_bounds(map: Dictionary) -> Rect2:
	var bounds := Rect2()
	var first := true
	for road: Dictionary in map.get("ROADS", []):
		if road["name"] != "Ring Road":
			continue
		for point: Vector2 in [road["from"], road["to"]]:
			bounds = Rect2(point, Vector2.ZERO) if first else bounds.expand(point)
			first = false
	return bounds


## The kerbstones in the list (light grey stone), one plain box each. StaticBatch merges
## them into a few meshes later; separate boxes keep the real grass growing right up to them.
static func build(parent: Node3D, strips: Array, holder_name: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = holder_name
	parent.add_child(holder)
	var h: float = GameConfig.KERB_SIZE.y
	for strip: Rect2 in strips:
		var middle := strip.get_center()
		LowPoly.box(holder, Vector3(strip.size.x, h, strip.size.y), GameConfig.KERB_COLOUR, Vector3(middle.x, h * 0.5, middle.y))
	return holder
