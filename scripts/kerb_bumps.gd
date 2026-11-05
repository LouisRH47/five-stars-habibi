class_name KerbBumps
extends Node3D
## Session 75: kerbs are low, so you can ride over them anywhere (no invisible walls). This
## watches the bike: when it crosses a kerb line it gets a small bump and loses a little
## speed (bike.hit_kerb()), never a crash. Kerbs have no collision at all; the lines are
## just remembered in a grid of 8 m squares, so checking is quick.
## RoadMesh and SpineTracks add their kerb lines with add_line().

const CELL := 8.0

## Every kerb line piece: [from, to] (flat x/z).
var lines: Array = []
## How many kerbs the bike has ridden over (the tests read this).
var crossings := 0

var _grid := {}
var _last := Vector2(INF, INF)
var _cooldown := 0.0


## Remembers a kerb line (a few points along it).
func add_line(points: Array) -> void:
	for k in points.size() - 1:
		var a: Vector2 = points[k]
		var b: Vector2 = points[k + 1]
		lines.append([a, b])
		var box := Rect2(a, Vector2.ZERO).expand(b)
		for x in range(floori(box.position.x / CELL), floori(box.end.x / CELL) + 1):
			for y in range(floori(box.position.y / CELL), floori(box.end.y / CELL) + 1):
				var key := Vector2i(x, y)
				if not _grid.has(key):
					_grid[key] = []
				_grid[key].append(lines.size() - 1)


## True if going from a to b crosses a kerb line.
func crosses(a: Vector2, b: Vector2) -> bool:
	var seen := {}
	for key: Vector2i in [_cell(a), _cell(b)]:
		for i: int in _grid.get(key, []):
			if seen.has(i):
				continue
			seen[i] = true
			if Geometry2D.segment_intersects_segment(a, b, lines[i][0], lines[i][1]) != null:
				return true
	return false


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var bike := get_tree().get_first_node_in_group("bike") as Node3D
	if bike == null:
		return
	var here := Vector2(bike.global_position.x, bike.global_position.z)
	# A jump (reset, clinic, teleport in a test) isn't riding over a kerb.
	if _last.x != INF and here.distance_to(_last) < 2.0 and _cooldown <= 0.0 and crosses(_last, here):
		crossings += 1
		_cooldown = GameConfig.KERB_BUMP_COOLDOWN
		if bike.has_method("hit_kerb"):
			bike.hit_kerb()
	_last = here


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))
