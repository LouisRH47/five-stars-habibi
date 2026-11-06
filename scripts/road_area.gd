class_name RoadArea
extends RefCounted
## Session 76: answers "where is the asphalt?" for the kerbs, the curved corners, the buggy
## test and anything placed beside a road. RoadMesh fills it in when it builds the roads:
## - every road's strip (its middle line and width; paver paths are kept separately),
## - every curved corner piece (a "fillet": the asphalt that rounds off a junction),
## - the kerb gaps: paver paths, crossings, car parks and car park entrances, the Plaza.
## Lookups use a grid of 8 m squares, so they stay quick.
## RoadArea.current is the one the last RoadMesh built (the game only builds one).

const CELL := 8.0

static var current: RoadArea

## {a, b, half, chain, asphalt, first, last} for every straight bit of every road.
var _bits: Array = []
## Grid square -> indices into _bits.
var _grid := {}
## {poly: PackedVector2Array, chain: int, host: int} for every curved corner piece.
var fillets: Array = []
var _fillet_grid := {}
## Kerb gaps: {kind: "circle", at, half} / {kind: "line", from, to, half} / {kind: "rect", rect}.
var gaps: Array = []
var _gap_grid := {}


## Adds a road's strip. points: its middle line (closed: a loop). asphalt: false for pavers.
func add_road(chain: int, points: Array, width: float, closed: bool, asphalt: bool) -> void:
	var count := points.size() if closed else points.size() - 1
	for k in count:
		var a: Vector2 = points[k]
		var b: Vector2 = points[(k + 1) % points.size()]
		if a.distance_to(b) < 0.001:
			continue
		var bit := {"a": a, "b": b, "half": width * 0.5, "chain": chain, "asphalt": asphalt,
				"first": not closed and k == 0, "last": not closed and k == count - 1}
		_bits.append(bit)
		_file(_grid, _bits.size() - 1, Rect2(a, Vector2.ZERO).expand(b).grow(width * 0.5 + 0.5))


## Adds a curved corner piece (a closed outline).
func add_fillet(poly: PackedVector2Array, chain: int, host: int) -> int:
	fillets.append({"poly": poly, "chain": chain, "host": host})
	var box := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		box = box.expand(p)
	_file(_fillet_grid, fillets.size() - 1, box.grow(0.2))
	return fillets.size() - 1


func add_gap_circle(at: Vector2, half: float) -> void:
	_add_gap({"kind": "circle", "at": at, "half": half}, Rect2(at, Vector2.ZERO).grow(half))


func add_gap_line(from: Vector2, to: Vector2, half: float) -> void:
	_add_gap({"kind": "line", "from": from, "to": to, "half": half}, Rect2(from, Vector2.ZERO).expand(to).grow(half))


func add_gap_rect(rect: Rect2) -> void:
	_add_gap({"kind": "rect", "rect": rect}, rect)


## True if p is on asphalt: inside a road strip by at least `margin` metres, or on a curved
## corner piece. skip_chain / skip_fillet leave one road or corner out (-1: none).
func on_asphalt(p: Vector2, margin := 0.0, skip_chain := -1, skip_fillet := -1) -> bool:
	return road_at(p, margin, skip_chain) >= 0 or fillet_at(p, 0.0, skip_fillet) >= 0


## The asphalt road whose strip p is inside (by `margin`), or -1. skip_chain and
## skip_other leave up to two roads out. asphalt false: look for paver paths instead.
func road_at(p: Vector2, margin := 0.0, skip_chain := -1, asphalt := true, skip_other := -1) -> int:
	for i: int in _grid.get(_cell(p), []):
		var bit: Dictionary = _bits[i]
		if bit["chain"] == skip_chain or bit["chain"] == skip_other or bit["asphalt"] != asphalt:
			continue
		if _in_bit(bit, p, margin):
			return bit["chain"]
	return -1


## The curved corner piece p is on (or within `slack` metres of its edge), or -1.
func fillet_at(p: Vector2, slack := 0.0, skip_fillet := -1) -> int:
	for i: int in _fillet_grid.get(_cell(p), []):
		if i == skip_fillet:
			continue
		var poly: PackedVector2Array = fillets[i]["poly"]
		if Geometry2D.is_point_in_polygon(p, poly):
			return i
		if slack > 0.0 and _near_outline(p, poly, slack):
			return i
	return -1


## True if p is in a kerb gap: on a paver path (or just beside one), a crossing, a car park
## or its entrance.
func in_gap(p: Vector2) -> bool:
	if road_at(p, -0.4, -1, false) >= 0:
		return true
	for i: int in _gap_grid.get(_cell(p), []):
		var gap: Dictionary = gaps[i]
		match gap["kind"]:
			"circle":
				if p.distance_to(gap["at"]) <= gap["half"]:
					return true
			"line":
				if Geometry2D.get_closest_point_to_segment(p, gap["from"], gap["to"]).distance_to(p) <= gap["half"]:
					return true
			"rect":
				if (gap["rect"] as Rect2).has_point(p):
					return true
	return false


## False if nothing but road `chain` is anywhere near p (no other road, corner or gap in its
## grid square), so the slower checks can be skipped.
func busy(p: Vector2, chain: int) -> bool:
	var key := _cell(p)
	if _fillet_grid.has(key) or _gap_grid.has(key):
		return true
	for i: int in _grid.get(key, []):
		if _bits[i]["chain"] != chain:
			return true
	return false


## How far p is from a road's middle line (INF if that road isn't near).
func distance_to_road(p: Vector2, chain: int) -> float:
	var best := INF
	for i: int in _grid.get(_cell(p), []):
		var bit: Dictionary = _bits[i]
		if bit["chain"] == chain:
			best = minf(best, Geometry2D.get_closest_point_to_segment(p, bit["a"], bit["b"]).distance_to(p))
	return best


# --- Inside workings ---------------------------------------------------------------------

func _in_bit(bit: Dictionary, p: Vector2, margin: float) -> bool:
	var a: Vector2 = bit["a"]
	var b: Vector2 = bit["b"]
	var ab := b - a
	var t := (p - a).dot(ab) / ab.length_squared()
	# A road's first and last bit stop square at its ends (no round cap).
	if (bit["first"] and t < 0.0) or (bit["last"] and t > 1.0):
		return false
	var q := a + ab * clampf(t, 0.0, 1.0)
	return q.distance_to(p) < float(bit["half"]) - margin


func _near_outline(p: Vector2, poly: PackedVector2Array, slack: float) -> bool:
	for k in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(p, poly[k], poly[(k + 1) % poly.size()])
		if q.distance_to(p) <= slack:
			return true
	return false


func _add_gap(gap: Dictionary, box: Rect2) -> void:
	gaps.append(gap)
	_file(_gap_grid, gaps.size() - 1, box.grow(0.1))


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func _file(grid: Dictionary, index: int, box: Rect2) -> void:
	for x in range(floori(box.position.x / CELL), floori(box.end.x / CELL) + 1):
		for y in range(floori(box.position.y / CELL), floori(box.end.y / CELL) + 1):
			var key := Vector2i(x, y)
			if not grid.has(key):
				grid[key] = []
			grid[key].append(index)
