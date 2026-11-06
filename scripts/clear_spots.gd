class_name ClearSpots
extends RefCounted
## Looks pass Session 58: is a spot on the map free for a lamp, bin, sign or table?
## Checks the map data (data/wahat_al_shams.gd): roads, homes and their doorsteps, shops,
## big buildings, car parks, building sites, pools, domes, palms, parked cars, bollards,
## the sunken square and the spine's planters and red tracks. Also remembers what has been
## put down already (add()), so two things don't land on the same spot.

var _map: Dictionary
var _taken: Array = []  # [Vector2, radius]
var _boxes: Array[Rect2] = []
var _points: Array = []  # [Vector2, radius]


func _init(map: Dictionary) -> void:
	_map = map
	var villa_size: Vector3 = map.get("VILLA_SIZE", Vector3(9, 8, 8))
	var house := maxf(villa_size.x, villa_size.z) * 0.5 + 0.6
	for villa: Dictionary in map.get("VILLAS", []):
		var p: Vector3 = villa["position"]
		var size: Vector3 = villa.get("size", villa_size)
		var half := maxf(size.x, size.z) * 0.5 + 0.6 if villa.has("size") else house
		_boxes.append(Rect2(p.x - half, p.z - half, half * 2, half * 2))
		if villa.has("approach"):
			var a: Vector3 = villa["approach"]
			_points.append([Vector2(a.x, a.z), 2.2])
	for shop: Dictionary in map.get("RESTAURANTS", []) + map.get("SHOPS", []):
		var p: Vector3 = shop["position"]
		var size: Vector3 = shop.get("size", map.get("RESTAURANT_SIZE", Vector3(18, 8, 16)))
		var turned := absf(sin(deg_to_rad(shop.get("facing", 0.0)))) > 0.5
		var half := Vector2(size.z, size.x) * 0.5 if turned else Vector2(size.x, size.z) * 0.5
		half += Vector2(0.8, 0.8)
		_boxes.append(Rect2(p.x - half.x, p.z - half.y, half.x * 2, half.y * 2))
		# The doorway in front stays clear.
		var front := Vector3(sin(deg_to_rad(shop.get("facing", 0.0))), 0, cos(deg_to_rad(shop.get("facing", 0.0))))
		var door := p + front * ((size.x if turned else size.z) * 0.5 + 2.5)
		_points.append([Vector2(door.x, door.z), 2.6])
	# Session 78: the two shops have a shaded arcade (about 3 m deep) along their front.
	# Keep tables, lamps and planters out of it.
	for shop: Dictionary in map.get("SHOPS", []):
		var p: Vector3 = shop["position"]
		var size: Vector3 = shop["size"]
		var turned := absf(sin(deg_to_rad(shop.get("facing", 0.0)))) > 0.5
		var front := Vector3(sin(deg_to_rad(shop.get("facing", 0.0))), 0, cos(deg_to_rad(shop.get("facing", 0.0))))
		var depth := (size.x if turned else size.z) * 0.5
		var width := (size.z if turned else size.x) * 0.5 + 1.0
		var middle := p + front * (depth + 2.0)  # the arcade's middle line
		var half := Vector2(2.5, width) if turned else Vector2(width, 2.5)
		_boxes.append(Rect2(middle.x - half.x, middle.z - half.y, half.x * 2, half.y * 2))
	for key in ["INSTITUTE", "GYM", "MOSQUE"]:
		if map.has(key):
			var p: Vector3 = map[key]["position"]
			var size: Vector3 = map[key]["size"]
			var turned := absf(sin(deg_to_rad(map[key].get("facing", 0.0)))) > 0.5
			var half := (Vector2(size.z, size.x) if turned else Vector2(size.x, size.z)) * 0.5 + Vector2(1.5, 1.5)
			_boxes.append(Rect2(p.x - half.x, p.z - half.y, half.x * 2, half.y * 2))
	for key in ["PARKING_AREAS", "BUILDING_SITES", "SAND_AREAS"]:
		for area in map.get(key, []):
			if area is Rect2:
				_boxes.append((area as Rect2).grow(0.5))
	for lot: Dictionary in map.get("PARKING_LOTS", []):  # Session 79: every car park, all of it
		_boxes.append((lot["area"] as Rect2).grow(0.5))
	for key in ["COMMUNITY_POOL", "LAP_POOL", "BASKETBALL_COURT", "PLAYGROUND", "BEEHIVES", "JUMPING_ARENA", "SCHOOL_PARKING"]:
		if map.has(key):
			_boxes.append((map[key] as Rect2).grow(1.0))
	for key in ["BUS_STATION"]:
		if map.has(key):
			_boxes.append((map[key]["area"] as Rect2).grow(0.5))
	if map.has("SCHOOL"):
		_boxes.append((map["SCHOOL"]["area"] as Rect2).grow(-0.5))
	if map.has("STABLES"):
		var block: Dictionary = map["STABLES"]["block"]
		var p: Vector3 = block["position"]
		var size: Vector3 = block["size"]
		_boxes.append(Rect2(p.x - size.x * 0.5 - 1, p.z - size.z * 0.5 - 1, size.x + 2, size.z + 2))
		_boxes.append((map["STABLES"]["paddock"] as Rect2).grow(1.0))
	if map.has("DONKEY_PEN"):
		_boxes.append((map["DONKEY_PEN"]["area"] as Rect2).grow(1.0))
	for bed in map.get("FARM_BEDS", []):
		_boxes.append((bed as Rect2).grow(0.8))
	for dome: Vector3 in map.get("SPINE_DOMES", []):
		_points.append([Vector2(dome.x, dome.z), map.get("DOME_RADIUS", 7.0) + 1.5])
	for palm: Vector3 in map.get("PALM_TREES", []):
		_points.append([Vector2(palm.x, palm.z), 1.6])
	for car: Dictionary in map.get("PARKED_CARS", []):
		var p: Vector3 = car["position"]
		_points.append([Vector2(p.x, p.z), 3.0])
	for bollard: Vector2 in map.get("BOLLARDS", []):
		_points.append([bollard, 0.8])
	for mini: Dictionary in map.get("MINI_PLAZAS", []):
		var tower: Vector3 = mini["tower"]
		var play: Vector3 = mini["playground"]
		_points.append([Vector2(tower.x, tower.z), 3.5])
		_points.append([Vector2(play.x, play.z), 5.0])
		for bench: Dictionary in mini["benches"]:
			var b: Vector3 = bench["position"]
			_points.append([Vector2(b.x, b.z), 1.8])
	if map.has("PLAZA"):
		_points.append([map["PLAZA"]["centre"], map["PLAZA"]["sunken_radius"] + 1.0])


## Remember something put down at `spot`, `radius` metres round.
func add(spot: Vector2, radius: float) -> void:
	_taken.append([spot, radius])


## True if nothing is within `radius` metres of `spot`. track_ok: the spine planter (the
## strip between the spine road and the red track) is allowed (for lamps along the spine).
func is_free(spot: Vector2, radius: float, track_ok := false) -> bool:
	for road: Dictionary in _map.get("ROADS", []):
		var half: float = road.get("width", _map.get("ROAD_WIDTH", 10.0)) * 0.5
		if road.get("name", "") == "Highway":
			half += 4.0
		var closest := Geometry2D.get_closest_point_to_segment(spot, road["from"], road["to"])
		if closest.distance_to(spot) < half + radius + 0.4:
			return false
	# Session 76: not on (or right beside) the curved corner of a junction.
	if RoadArea.current != null and RoadArea.current.fillet_at(spot, radius + 0.4) >= 0:
		return false
	for box: Rect2 in _boxes:
		if box.grow(radius).has_point(spot):
			return false
	for point: Array in _points + _taken:
		if (point[0] as Vector2).distance_to(spot) < point[1] + radius:
			return false
	if _map.has("SPINE_TRACKS"):
		var spec: Dictionary = _map["SPINE_TRACKS"]
		if spot.x > spec["from_x"] - 2.0 and spot.x < spec["to_x"] + 2.0:
			var road_half: float = spec["road_half"]
			var planter: float = spec["planter"]
			var track: float = spec["track"]
			var z := absf(spot.y)
			var in_planter := z > road_half + 0.4 + radius and z < road_half + planter - 0.3 - radius
			if z < road_half + planter + track + 0.6 + radius and not (track_ok and in_planter):
				return false
			for gap: Array in spec["path_gaps"]:
				if absf(spot.x - gap[0]) < gap[2] + 1.5 + radius:
					return false
	if _map.has("MAP_HALF"):
		var half: Vector2 = _map["MAP_HALF"]
		var edge := _map.get("RING_ROAD", {}).get("half", half) as Vector2
		if absf(spot.x) > edge.x - 6.0 or absf(spot.y) > edge.y - 6.0:
			return false  # leave the ring road's edge to its own lamps
	return true
