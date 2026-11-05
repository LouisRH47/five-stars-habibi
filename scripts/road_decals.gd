class_name RoadDecals
extends Node3D
## Session 68 (PRD "Polish pass", W3): roads that look used. Flat pictures (Decals) laid on the
## roads and car parks from the map data (read only, the map isn't changed):
##   - pale sand blown onto the road edges (every 12 to 20 m on the car roads, less elsewhere)
##   - dark tyre marks where roads meet
##   - manhole covers and drain grates along the ring road, a few cracks and patches
##   - oil spots in some empty car park bays
##   - faded "SLOW / ببطء" paint and a zebra crossing at the school gate
## The pictures are made by tools/make_decals.py. Each decal is a thin box (0.3 m) that only
## paints flat ground facing up, fades out with distance, and keeps away from speed bumps,
## road works, gates, horse crossings and cars. Graphics Low: about half of them, fading out
## sooner, so the browser never has more than 64 in view. world_extras.gd adds this.

const PICTURES := {
	"tyre_arc": preload("res://assets/textures/decals/tyre_arc.png"),
	"oil_spot": preload("res://assets/textures/decals/oil_spot.png"),
	"manhole": preload("res://assets/textures/decals/manhole.png"),
	"drain": preload("res://assets/textures/decals/drain.png"),
	"crack": preload("res://assets/textures/decals/crack.png"),
	"patch": preload("res://assets/textures/decals/patch.png"),
	"sand_drift": preload("res://assets/textures/decals/sand_drift.png"),
	"slow_ar_en": preload("res://assets/textures/decals/slow_ar_en.png"),
	"zebra": preload("res://assets/textures/decals/zebra.png"),
}
const ROAD_TOP := 0.04      # the roads' top (WahatBuilder); lanes are 0.045
const CAR_PARK_TOP := 0.03  # the car parks' asphalt (CarParkBuilder.PAD_TOP)
const CELL := 48.0          # the same chunks StaticBatch merges the ground into

## Every decal, with what it is and whether Graphics Low keeps it. Tests read these.
var decals: Array[Decal] = []
var kinds: Array[String] = []
var on_low: Array[bool] = []

var _map: Dictionary = {}
var _roads: Array = []
var _junctions: Array = []   # [{spot: Vector2, sides: [Vector2 directions away from it]}]
var _rng := RandomNumberGenerator.new()


static func attach(world: Node) -> RoadDecals:
	var map := WaterLook._map(world)
	if map.is_empty() or not map.has("ROADS"):
		return null
	var wear := RoadDecals.new()
	wear.name = "RoadDecals"
	world.add_child(wear)
	wear.build(map)
	return wear


func _ready() -> void:
	add_to_group("graphics")   # Settings.apply() calls apply_graphics() on this group


func build(map: Dictionary) -> void:
	_map = map
	_rng.seed = GameConfig.DECAL_SEED
	for road: Dictionary in map["ROADS"]:
		if float(road.get("width", 10.0)) >= 6.0 and road.get("kind", "") != "walk_track":
			_roads.append(road)
	_find_junctions()
	for road: Dictionary in _roads:
		_sand(road)
		_cracks(road)
		if road["name"] == "Ring Road":
			_ring_road_metal(road)
	_junction_marks()
	_car_parks()
	_school()
	_pick_low()
	apply_graphics()


## Graphics Low / Medium / High: how many show and how far away they fade.
func apply_graphics() -> void:
	var level := clampi(Settings.graphics, 0, 2)
	for i in decals.size():
		var decal := decals[i]
		decal.visible = level > 0 or on_low[i]
		decal.distance_fade_begin = GameConfig.DECAL_FADE_BEGIN[level]
		decal.distance_fade_length = GameConfig.DECAL_FADE_LENGTH


## How many decals could be in view at once (within the fade distance) from `spot`.
func count_near(spot: Vector2, level: int) -> int:
	var reach: float = GameConfig.DECAL_FADE_BEGIN[level] + GameConfig.DECAL_FADE_LENGTH
	var count := 0
	for i in decals.size():
		if level == 0 and not on_low[i]:
			continue
		var p := decals[i].position
		if Vector2(p.x, p.z).distance_to(spot) <= reach:
			count += 1
	return count


## True if this spot (x, z) is on one of the roads the decals go on, or in a car park.
func on_road_or_car_park(spot: Vector2) -> bool:
	for road: Dictionary in _roads:
		if _across(road, spot) >= 0.0:
			return true
	for park: Dictionary in _map.get("CAR_PARKS", []):
		if (park["area"] as Rect2).has_point(spot):
			return true
	return false


# --- What goes where ---------------------------------------------------------------------

## Sand along both edges, the top of the picture against the kerb.
func _sand(road: Dictionary) -> void:
	var black := String(road["name"]) in GameConfig.BLACK_ROADS
	var from: Vector2 = road["from"]
	var to: Vector2 = road["to"]
	var dir := (to - from).normalized()
	var length := from.distance_to(to)
	var half := float(road["width"]) * 0.5
	var spacing: Vector2 = GameConfig.DECAL_SAND_SPACING if black else GameConfig.DECAL_SAND_SPACING * 2.0
	for side: float in [-1.0, 1.0]:
		var normal := Vector2(-dir.y, dir.x) * side   # pointing out to this edge
		var s := _rng.randf_range(4.0, spacing.y)
		while s < length - 4.0:
			var long := _rng.randf_range(5.0, 9.0)
			var deep := _rng.randf_range(1.5, 2.2)
			var spot := from + dir * s + normal * (half - deep * 0.5 - 0.05)
			var kerb := from + dir * s + normal * (half + 0.8)
			var ends_ok := _is_clear(spot + dir * long * 0.5, 2.0) and _is_clear(spot - dir * long * 0.5, 2.0)
			if not _on_any_road(kerb) and ends_ok and _away_from_junctions(spot, 7.0):
				_add("sand_drift", spot, -normal, Vector2(long, deep))
			s += _rng.randf_range(spacing.x, spacing.y)


## A crack or a patch every 50 to 80 m, somewhere across the road.
func _cracks(road: Dictionary) -> void:
	var from: Vector2 = road["from"]
	var to: Vector2 = road["to"]
	var dir := (to - from).normalized()
	var half := float(road["width"]) * 0.5
	var s := _rng.randf_range(15.0, 50.0)
	while s < from.distance_to(to) - 10.0:
		var size := _rng.randf_range(1.8, 2.8)
		var spot := from + dir * s + Vector2(-dir.y, dir.x) * _rng.randf_range(-(half - 1.6), half - 1.6)
		if _is_clear(spot, 3.0) and _away_from_junctions(spot, 6.0):
			var turn := Vector2.from_angle(_rng.randf() * TAU)
			_add("crack" if _rng.randf() < 0.55 else "patch", spot, turn, Vector2(size, size))
		s += _rng.randf_range(50.0, 80.0)


## Manhole covers every 40 m (one lane, then the other) and a drain by the kerb in between.
func _ring_road_metal(road: Dictionary) -> void:
	var from: Vector2 = road["from"]
	var to: Vector2 = road["to"]
	var dir := (to - from).normalized()
	var across := Vector2(-dir.y, dir.x)
	var half := float(road["width"]) * 0.5
	var step: float = GameConfig.DECAL_MANHOLE_SPACING
	var i := 0
	var s := step * 0.5
	while s < from.distance_to(to) - 8.0:
		var lane := 2.5 if i % 2 == 0 else -2.5
		var hole := from + dir * s + across * lane
		if _is_clear(hole, 3.0) and _away_from_junctions(hole, 8.0):
			_add("manhole", hole, dir, Vector2(0.9, 0.9))
		var drain := from + dir * (s + step * 0.5) + across * (half - 0.45) * (1.0 if i % 2 == 0 else -1.0)
		if s + step * 0.5 < from.distance_to(to) - 8.0 and _is_clear(drain, 3.0) and _away_from_junctions(drain, 8.0) \
				and not _on_any_road(drain + across.normalized() * signf(lane) * 1.2):
			_add("drain", drain, across * signf(lane), Vector2(1.0, 0.5))
		s += step
		i += 1


## Dark tyre marks curving into each side road where roads meet.
func _junction_marks() -> void:
	for junction: Dictionary in _junctions:
		var spot: Vector2 = junction["spot"]
		for way: Vector2 in junction["sides"]:
			for turn: float in [-1.0, 1.0]:
				if _rng.randf() > 0.7:
					continue
				var corner := spot + way * _rng.randf_range(2.0, 3.5) + way.orthogonal() * turn * _rng.randf_range(1.5, 2.5)
				if _is_clear(corner, 3.0) and _on_any_road(corner):
					var size := _rng.randf_range(3.5, 5.0)
					_add("tyre_arc", corner, way.rotated(turn * PI * 0.25), Vector2(size, size))


## Oil spots in about 1 in 4 empty bays (never under a parked car or by a charger).
func _car_parks() -> void:
	var cars: Array = []
	for car: Dictionary in _map.get("PARKED_CARS", []):
		var p: Vector3 = car["position"]
		cars.append(Vector2(p.x, p.z))
	for park: Dictionary in _map.get("CAR_PARKS", []):
		for row: Dictionary in park["rows"]:
			var area: Rect2 = row["area"]
			var bays := int(row["bays"])
			var along_x := area.size.x > area.size.y
			for b in bays:
				var t := (b + 0.5) / bays
				var spot := Vector2(area.position.x + area.size.x * t, area.get_center().y) if along_x \
						else Vector2(area.get_center().x, area.position.y + area.size.y * t)
				if _rng.randf() > GameConfig.DECAL_OIL_BAY_CHANCE:
					continue
				if cars.any(func(c: Vector2) -> bool: return c.distance_to(spot) < GameConfig.DECAL_CAR_GAP + 2.2):
					continue
				if not _is_clear(spot, 1.0) or _in_garden(spot):
					continue
				var size := _rng.randf_range(0.9, 1.4)
				_add("oil_spot", spot, Vector2.from_angle(_rng.randf() * TAU), Vector2(size, size), CAR_PARK_TOP)


## The school gate: a faded zebra across School Road and "SLOW / ببطء" in each lane before it.
func _school() -> void:
	var school: Dictionary = _map.get("SCHOOL", {})
	var road := _road_named("School Road")
	if school.is_empty() or road.is_empty():
		return
	var gate_x: float = school["gate_x"]
	var z: float = (road["from"] as Vector2).y
	var width: float = road["width"]
	_add("zebra", Vector2(gate_x, z), Vector2(1, 0), Vector2(width - 0.6, 3.0))
	# Traffic keeps right: going east (+x) uses the +z lane. The writing's top points the way
	# you're going, so you read it as you ride up to it.
	_add("slow_ar_en", Vector2(gate_x - 16.0, z + width * 0.25), Vector2(-1, 0), Vector2(2.8, 4.5))
	_add("slow_ar_en", Vector2(gate_x + 16.0, z - width * 0.25), Vector2(1, 0), Vector2(2.8, 4.5))


# --- Helpers -----------------------------------------------------------------------------

## Adds one decal. `down` is the way the picture's bottom edge faces (its top faces -down).
func _add(kind: String, spot: Vector2, down: Vector2, size: Vector2, top := ROAD_TOP) -> Decal:
	var decal := Decal.new()
	decal.name = "%s_%d" % [kind, decals.size()]
	decal.texture_albedo = PICTURES[kind]
	decal.size = Vector3(size.x, GameConfig.DECAL_THICKNESS, size.y)
	decal.upper_fade = 0.3
	decal.lower_fade = 0.3
	decal.normal_fade = 0.5   # only flat ground facing up, never the side of a kerb or a car
	decal.distance_fade_enabled = true
	var z := Vector3(down.x, 0, down.y).normalized()
	decal.transform = Transform3D(Basis(Vector3.UP.cross(z), Vector3.UP, z), Vector3(spot.x, top, spot.y))
	add_child(decal)
	decals.append(decal)
	kinds.append(kind)
	on_low.append(true)
	return decal


## Graphics Low keeps every other sand drift, crack and oil spot, and never more than 8 in one
## 48 m chunk of ground (the browser draws at most 8 decals on one piece of ground).
func _pick_low() -> void:
	var per_cell := {}
	for i in decals.size():
		var keep := kinds[i] in ["manhole", "slow_ar_en", "zebra", "tyre_arc"] or i % 2 == 0
		var p := decals[i].position
		var cell := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
		if keep and int(per_cell.get(cell, 0)) >= GameConfig.DECAL_LOW_PER_CELL:
			keep = false
		if keep:
			per_cell[cell] = int(per_cell.get(cell, 0)) + 1
		on_low[i] = keep


## Where roads meet: crossings and T-junctions of the roads' middle lines.
func _find_junctions() -> void:
	for i in _roads.size():
		for j in range(i + 1, _roads.size()):
			var a: Dictionary = _roads[i]
			var b: Dictionary = _roads[j]
			var spot: Variant = Geometry2D.segment_intersects_segment(a["from"], a["to"], b["from"], b["to"])
			if spot == null:
				spot = _t_junction(a, b)
			if spot == null:
				spot = _t_junction(b, a)
			if spot == null:
				continue
			var sides: Array = []
			for road: Dictionary in [a, b]:
				for end: Vector2 in [road["from"], road["to"]]:
					if end.distance_to(spot) > float(road["width"]) * 0.5 + 1.5:
						sides.append((end - spot).normalized())
			_merge_junction(spot, sides)


## If one end of `side` stops at `main`, the spot on main's middle line where it meets.
func _t_junction(main: Dictionary, side: Dictionary) -> Variant:
	for end: Vector2 in [side["from"], side["to"]]:
		var on: Vector2 = Geometry2D.get_closest_point_to_segment(end, main["from"], main["to"])
		if on.distance_to(end) <= float(main["width"]) * 0.5 + 1.0:
			return on
	return null


func _merge_junction(spot: Vector2, sides: Array) -> void:
	for junction: Dictionary in _junctions:
		if (junction["spot"] as Vector2).distance_to(spot) < 5.0:
			for way: Vector2 in sides:
				if not junction["sides"].any(func(w: Vector2) -> bool: return w.dot(way) > 0.95):
					junction["sides"].append(way)
			return
	_junctions.append({"spot": spot, "sides": sides})


func _away_from_junctions(spot: Vector2, gap: float) -> bool:
	for junction: Dictionary in _junctions:
		if (junction["spot"] as Vector2).distance_to(spot) < gap + 4.0:
			return false
	return true


## How far inside the road `spot` is from its nearest edge (negative = not on it). The road's
## ends stick out half a width (corners), like WahatBuilder draws them.
func _across(road: Dictionary, spot: Vector2) -> float:
	var from: Vector2 = road["from"]
	var to: Vector2 = road["to"]
	var length := from.distance_to(to)
	if length < 0.01:
		return -1.0
	var dir := (to - from) / length
	var rel := spot - from
	var half := float(road.get("width", 10.0)) * 0.5
	var along := rel.dot(dir)
	if along < -half or along > length + half:
		return -1.0
	return half - absf(rel.dot(Vector2(-dir.y, dir.x)))


## On any path or road in the data (lanes and tracks too), for "is there a side road here?".
func _on_any_road(spot: Vector2) -> bool:
	for road: Dictionary in _map["ROADS"]:
		if _across(road, spot) >= 0.0:
			return true
	return false


## Away from things a flat picture shouldn't touch: speed bumps, road works, the gates, the
## horse crossings, the bus station and any car that isn't in a bay.
func _is_clear(spot: Vector2, gap: float) -> bool:
	for bump: Dictionary in _map.get("SPEED_BUMPS", []):
		var p: Vector3 = bump["position"]
		if Vector2(p.x, p.z).distance_to(spot) < 5.5 + gap:
			return false
	for works: Dictionary in _map.get("ROAD_WORKS", []):
		var c: Vector2 = works["centre"]
		var size := Vector2(works["width"], works["length"]) if works["along"] == "z" else Vector2(works["length"], works["width"])
		if Rect2(c - size * 0.5, size).grow(gap + 2.0).has_point(spot):
			return false
	for gate: Dictionary in _map.get("GATES", []):
		var p: Vector3 = gate["position"]
		if Vector2(p.x, p.z).distance_to(spot) < 12.0 + gap:
			return false
	for crossing: Dictionary in _map.get("HORSE_CROSSINGS", []):
		var a: Vector3 = crossing["from"]
		var b: Vector3 = crossing["to"]
		var on: Vector2 = Geometry2D.get_closest_point_to_segment(spot, Vector2(a.x, a.z), Vector2(b.x, b.z))
		if on.distance_to(spot) < 3.0 + gap:
			return false
	var bus: Dictionary = _map.get("BUS_STATION", {})
	if bus.has("area") and (bus["area"] as Rect2).grow(gap).has_point(spot):
		return false
	for car: Dictionary in _map.get("PARKED_CARS", []):
		if car.get("bay", false):
			continue
		var p: Vector3 = car["position"]
		if Vector2(p.x, p.z).distance_to(spot) < GameConfig.DECAL_CAR_GAP + 2.5:
			return false
	return true


func _in_garden(spot: Vector2) -> bool:
	for area: Rect2 in _map.get("CARPARK_GARDENS", []):
		if area.grow(0.6).has_point(spot):
			return true
	return false


func _road_named(id: String) -> Dictionary:
	for road: Dictionary in _map["ROADS"]:
		if road["name"] == id:
			return road
	return {}
