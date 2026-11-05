class_name RoadCorners
extends RefCounted
## Session 76: the curved inside corners where roads meet (a "fillet" is the curved bit of
## asphalt that rounds off a corner). RoadMesh finds the junctions; this works out each
## corner's curve:
## - a road ending on the side of another (a T): a curve on both sides of the road,
## - a road ending on the roundabout: a curve from its edge round onto the roundabout's ring,
## - two roads crossing (an X): a curve in each of the four corners.
## The radius is about 6 m where a lane (or the spine road) is involved and 10 m between
## bigger roads (ROAD_CORNERS in the data). Where there isn't room (another road or a corner
## is in the way, or the road bends), the curve is made smaller until it fits.
## Each corner: {corner, arc (Array of Vector2, from the road's edge round to the other
## road's edge), centre, poly (its outline), chain, host, radius}.

const MIN_RADIUS := 0.3
const SHRINK := 0.7
const ARC_STEP := 0.6   # metres between the points of a curve


## joins: [{chain, host, point, inward, round}], crosses: [{a, b, spot}].
static func make(chains: Array, joins: Array, crosses: Array, area: RoadArea, corners: Dictionary) -> Array:
	var out: Array = []
	for join: Dictionary in joins:
		var own: Dictionary = chains[join["chain"]]
		var host: Dictionary = chains[join["host"]]
		var radius := radius_for(own, host, corners)
		for side in [-1.0, 1.0]:
			var corner: Dictionary
			if join["round"]:
				corner = _round_corner(chains, join, side, radius, area)
			else:
				corner = _t_corner(chains, join, side, radius, area)
			if not corner.is_empty():
				area.add_fillet(corner["poly"], corner["chain"], corner["host"])
				out.append(corner)
	for cross: Dictionary in crosses:
		var a: Dictionary = chains[cross["a"]]
		var b: Dictionary = chains[cross["b"]]
		var radius := radius_for(a, b, corners)
		var da: Vector2 = cross["dir_a"]
		var db: Vector2 = cross["dir_b"]
		var na := Vector2(-da.y, da.x)
		var nb := Vector2(-db.y, db.x)
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var spot: Vector2 = cross["spot"]
				var hit = Geometry2D.line_intersects_line(spot + na * sa * a["width"] * 0.5, da, spot + nb * sb * b["width"] * 0.5, db)
				if hit == null:
					continue
				var c: Vector2 = hit
				var u := da * signf(da.dot(c - spot))
				var v := db * signf(db.dot(c - spot))
				var corner := _fit(c, u, v, radius, cross["a"], a["width"] * 0.5, cross["b"], b["width"] * 0.5, area)
				if not corner.is_empty():
					area.add_fillet(corner["poly"], corner["chain"], corner["host"])
					out.append(corner)
	return out


## 6 m if either road is a lane (or the spine road, a car park road...), else 10 m.
static func radius_for(own: Dictionary, host: Dictionary, corners: Dictionary) -> float:
	for word: String in corners.get("lane_roads", []):
		if word in String(own["name"]) or word in String(host["name"]):
			return corners.get("lane", 6.0)
	return corners.get("road", 10.0)


## A road (own) ending on the side of another (host): the corner on one side of it.
static func _t_corner(chains: Array, join: Dictionary, side: float, radius: float, area: RoadArea) -> Dictionary:
	var own: Dictionary = chains[join["chain"]]
	var host: Dictionary = chains[join["host"]]
	var p: Vector2 = join["point"]
	var g: Vector2 = -join["inward"]          # along the road, away from the junction
	var n := Vector2(-g.y, g.x)
	var th: Vector2 = join["host_dir"]        # along the other road
	var m := Vector2(-th.y, th.x)
	if m.dot(g) < 0.0:
		m = -m                                # the other road's edge on our side
	var own_half: float = own["width"] * 0.5
	var host_half: float = host["width"] * 0.5
	var hit = Geometry2D.line_intersects_line(p + n * side * own_half, g, join["host_point"] + m * host_half, th)
	if hit == null:
		return {}
	var v := th if th.dot(n * side) > 0.0 else -th
	return _fit(hit, g, v, radius, join["chain"], own_half, join["host"], host_half, area)


## The curve that fits in the corner at c between two straight edges: along u (the road's
## edge) and v (the other road's edge). Smaller and smaller until it fits.
static func _fit(c: Vector2, u: Vector2, v: Vector2, radius: float, own: int, own_half: float,
		host: int, host_half: float, area: RoadArea) -> Dictionary:
	var angle := u.angle_to(v)
	var half_angle := absf(angle) * 0.5
	if half_angle < 0.2 or half_angle > PI * 0.5 - 0.05:
		return {}  # the roads meet almost in line: no corner to round
	var r := radius
	while r >= MIN_RADIUS:
		var reach := r / tan(half_angle)
		var centre := c + (u + v).normalized() * (r / sin(half_angle))
		var t_own := c + u * reach
		var t_host := c + v * reach
		if _edge_ok(c, t_own, own, own_half, host, area) and _edge_ok(c, t_host, host, host_half, own, area):
			var arc := _arc(centre, t_own, t_host, r)
			if _arc_ok(arc, own, host, area):
				var poly := PackedVector2Array([c])
				poly.append_array(PackedVector2Array(arc))
				return {"corner": c, "arc": arc, "centre": centre, "poly": poly, "chain": own, "host": host, "radius": r}
		r *= SHRINK
	return {}


## A road ending on the roundabout: the curve from its edge round onto the ring's outside.
static func _round_corner(chains: Array, join: Dictionary, side: float, radius: float, area: RoadArea) -> Dictionary:
	var own: Dictionary = chains[join["chain"]]
	var ring: Dictionary = chains[join["host"]]
	var centre_o := Vector2.ZERO
	for q: Vector2 in ring["points"]:
		centre_o += q
	centre_o /= ring["points"].size()
	var outer: float = (ring["points"][0] as Vector2).distance_to(centre_o) + float(ring["width"]) * 0.5
	var p: Vector2 = join["point"]
	var g: Vector2 = -join["inward"]
	var n := Vector2(-g.y, g.x)
	var own_half: float = own["width"] * 0.5
	var edge := p + n * side * own_half
	var c := _line_circle(edge, g, centre_o, outer)
	if c.x == INF:
		return {}
	var r := radius
	while r >= MIN_RADIUS:
		var centre := _line_circle(p + n * side * (own_half + r), g, centre_o, outer + r)
		if centre.x != INF:
			var t_own := centre - n * side * r
			var t_ring := centre_o + (centre - centre_o).normalized() * outer
			if _edge_ok(c, t_own, join["chain"], own_half, join["host"], area):
				var arc := _arc(centre, t_own, t_ring, r)
				if _arc_ok(arc, join["chain"], join["host"], area):
					# The outline goes back to the corner along the ring's edge.
					var poly := PackedVector2Array([c])
					poly.append_array(PackedVector2Array(arc))
					var a0 := (t_ring - centre_o).angle()
					var a1 := (c - centre_o).angle()
					var turn := wrapf(a1 - a0, -PI, PI)
					var steps := maxi(2, ceili(absf(turn) * outer / ARC_STEP))
					for k in range(1, steps):
						var a := a0 + turn * k / steps
						poly.append(centre_o + Vector2(cos(a), sin(a)) * outer)
					return {"corner": c, "arc": arc, "centre": centre, "poly": poly,
							"chain": join["chain"], "host": join["host"], "radius": r}
		r *= SHRINK
	return {}


## Where the line from + t * dir (the larger t) meets the circle, or Vector2(INF, INF).
static func _line_circle(from: Vector2, dir: Vector2, centre: Vector2, radius: float) -> Vector2:
	var f := from - centre
	var b := f.dot(dir)
	var c := f.length_squared() - radius * radius
	var disc := b * b - c
	if disc < 0.0:
		return Vector2(INF, INF)
	return from + dir * (-b + sqrt(disc))


## Points round the curve from a to b (both radius r from centre), the short way.
static func _arc(centre: Vector2, a: Vector2, b: Vector2, r: float) -> Array:
	var a0 := (a - centre).angle()
	var turn := wrapf((b - centre).angle() - a0, -PI, PI)
	var steps := clampi(ceili(absf(turn) * r / ARC_STEP), 3, 24)
	var out: Array = [a]
	for k in range(1, steps):
		var angle := a0 + turn * k / steps
		out.append(centre + Vector2(cos(angle), sin(angle)) * r)
	out.append(b)
	return out


## The straight edge from the corner c to t runs along road `chain` (its middle line stays
## `half` away, so the road is straight and long enough) and nothing else is there.
static func _edge_ok(c: Vector2, t: Vector2, chain: int, half: float, other: int, area: RoadArea) -> bool:
	var steps := maxi(2, ceili(c.distance_to(t) / 0.5))
	for k in range(1, steps + 1):
		var q := c.lerp(t, float(k) / steps)
		if absf(area.distance_to_road(q, chain) - half) > 0.15:
			return false
		if area.fillet_at(q) >= 0:
			return false
	# Leave room for a corner at the far end too (a short road between two others gets a
	# curve at each end): no other asphalt for twice the distance.
	for k in range(1, steps * 2 + 1):
		if area.road_at(c.lerp(t, float(k) / steps), -0.01, chain, true, other) >= 0:
			return false
	return true


## The curve doesn't run over (or touch) another road or another corner.
static func _arc_ok(arc: Array, own: int, host: int, area: RoadArea) -> bool:
	for q: Vector2 in arc:
		if area.road_at(q, -0.01, own, true, host) >= 0 or area.fillet_at(q) >= 0:
			return false
	return true
