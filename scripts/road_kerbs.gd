class_name RoadKerbs
extends RefCounted
## Session 76: works out where the kerbs go, so they join up. Every road edge, every curved
## corner and the end of every dead-end road is a candidate kerb line. Each line is cut
## wherever it would lie on other asphalt (another road or a curved corner) or in a kerb
## gap (a paver path, a crossing, a car park or its entrance). What is left are the kerb
## "runs": continuous lines that end only where another kerb carries on or at a gap.
## RoadMesh draws the runs as raised kerbs; KerbBumps gives a small bump riding over them.

const SAMPLE := 0.75     # metres between the points the line is checked at
const MAX_PIECE := 12.0  # the longest straight kerb piece drawn
const EDGE_SLACK := 0.03 # a road edge lying along a curved corner's outline counts as covered

## Every kerb run: {points: Array of Vector2 (the road-side edge), out: Array of Vector2
## (the way away from the road at each point), closed: bool}.
var runs: Array = []

var _area: RoadArea


func _init(area: RoadArea) -> void:
	_area = area


## Adds one candidate kerb line. points: along the road's edge. out: away from the road at
## each point. owner_chain / owner_fillet: the road or corner the line belongs to (that one
## doesn't cut it).
func add_line(points: Array, out: Array, closed: bool, owner_chain := -1, owner_fillet := -1) -> void:
	if points.size() < 2:
		return
	var dense := _resample(points, out, closed)
	var pts: Array = dense[0]
	var dirs: Array = dense[1]
	var keep: Array = []
	for q: Vector2 in pts:
		keep.append(not _covered(q, owner_chain, owner_fillet))
	var n := pts.size()
	if closed and keep.all(func(k): return k):
		runs.append(_simplified(pts, dirs, true))
		return
	# Start from a cut point, so a closed loop's run isn't split where the list starts.
	var start := 0
	if closed:
		start = keep.find(false)
	var run_pts: Array = []
	var run_out: Array = []
	for step in n + (1 if closed else 0):
		var k := (start + step) % n
		var prev := (k - 1 + n) % n
		if keep[k]:
			if run_pts.is_empty() and (closed or k > 0) and not keep[prev]:
				# The run starts between a cut point and this one: find the exact spot.
				var edge := _boundary(pts[prev], pts[k], owner_chain, owner_fillet)
				run_pts.append(edge)
				run_out.append(dirs[k])
			run_pts.append(pts[k])
			run_out.append(dirs[k])
		elif not run_pts.is_empty():
			run_pts.append(_boundary(pts[k], pts[prev], owner_chain, owner_fillet))
			run_out.append(dirs[prev])
			_finish_run(run_pts, run_out)
			run_pts = []
			run_out = []
	if not run_pts.is_empty():
		_finish_run(run_pts, run_out)


## The kerb ends of every open run (for the "no kerb ends in mid-air" test).
func ends() -> Array:
	var out: Array = []
	for run: Dictionary in runs:
		if not run["closed"]:
			out.append([run["points"][0], run])
			out.append([run["points"].back(), run])
	return out


## Total metres of kerb.
func length() -> float:
	var total := 0.0
	for run: Dictionary in runs:
		var pts: Array = run["points"]
		for k in pts.size() - 1:
			total += (pts[k + 1] as Vector2).distance_to(pts[k])
	return total


# --- Inside workings ---------------------------------------------------------------------

## True if q is on other asphalt, on a corner piece or in a kerb gap (so no kerb there).
func _covered(q: Vector2, owner_chain: int, owner_fillet: int) -> bool:
	if owner_chain >= 0 and not _area.busy(q, owner_chain):
		return false  # nothing else anywhere near: quick answer
	if _area.road_at(q, 0.02, owner_chain) >= 0:
		return true
	if _area.fillet_at(q, EDGE_SLACK, owner_fillet) >= 0:
		return true
	return _area.in_gap(q)


## The spot between a (covered) and b (not covered) where the cover stops.
func _boundary(a: Vector2, b: Vector2, owner_chain: int, owner_fillet: int) -> Vector2:
	for i in 10:
		var mid := a.lerp(b, 0.5)
		if _covered(mid, owner_chain, owner_fillet):
			a = mid
		else:
			b = mid
	return b


func _finish_run(pts: Array, dirs: Array) -> void:
	# Drop runs too short to see (a sliver between two cuts).
	var total := 0.0
	for k in pts.size() - 1:
		total += (pts[k + 1] as Vector2).distance_to(pts[k])
	if total < 0.05:
		return
	runs.append(_simplified(pts, dirs, false))


## The run with the points along straight stretches dropped (fewer pieces to draw), keeping
## every bend and both ends.
func _simplified(pts: Array, dirs: Array, closed: bool) -> Dictionary:
	var keep_pts: Array = [pts[0]]
	var keep_dirs: Array = [dirs[0]]
	var n := pts.size()
	for k in range(1, n if closed else n - 1):
		var last: Vector2 = keep_pts.back()
		var here: Vector2 = pts[k]
		var next: Vector2 = pts[(k + 1) % n]
		var bend := absf((here - last).angle_to(next - here)) > 0.01
		var turned := (dirs[k] as Vector2).dot(keep_dirs.back()) < 0.9999
		if bend or turned or last.distance_to(next) > MAX_PIECE:
			keep_pts.append(here)
			keep_dirs.append(dirs[k])
	if not closed:
		keep_pts.append(pts.back())
		keep_dirs.append(dirs.back())
	return {"points": keep_pts, "out": keep_dirs, "closed": closed}


## Points no more than SAMPLE apart (with the "away" direction blended between them).
func _resample(points: Array, out: Array, closed: bool) -> Array:
	var pts: Array = []
	var dirs: Array = []
	var count := points.size() if closed else points.size() - 1
	for k in count:
		var a: Vector2 = points[k]
		var b: Vector2 = points[(k + 1) % points.size()]
		var da: Vector2 = out[k]
		var db: Vector2 = out[(k + 1) % points.size()]
		var bits := maxi(1, ceili(a.distance_to(b) / SAMPLE))
		for s in bits:
			var t := float(s) / bits
			pts.append(a.lerp(b, t))
			dirs.append(da.lerp(db, t).normalized())
	if not closed:
		pts.append(points.back())
		dirs.append((out.back() as Vector2).normalized())
	return [pts, dirs]
