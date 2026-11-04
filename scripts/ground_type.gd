class_name GroundType
## Is this spot bare sand? (Session 31, for the tyre dust.) It looks at the map's data list
## (data/wahat_al_shams.gd): roads, lanes, paving, grass, plots and
## car parks are not sand. Everywhere else on the map is. A map without a data list (the
## old test area) has no sand.


## map: the data list's constants (Script.get_script_constant_map()). spot: x and z.
static func is_sand(map: Dictionary, spot: Vector2) -> bool:
	if map.is_empty():
		return false
	var width: float = map.get("ROAD_WIDTH", 8.0)
	for road in map.get("ROADS", []):
		var road_width: float = road.get("width", width)
		# Roads are one width longer than their middle line, so corners are filled in.
		var along: Vector2 = (road["to"] - road["from"]).normalized() * road_width * 0.5
		var nearest := Geometry2D.get_closest_point_to_segment(spot, road["from"] - along, road["to"] + along)
		if spot.distance_to(nearest) <= road_width * 0.5:
			return false
	for key in ["PAVED_AREAS", "PARKING_AREAS", "PARK_PATHS"]:
		for area: Rect2 in map.get(key, []):
			if area.has_point(spot):
				return false
	for plot in map.get("PLOTS", []):
		if (plot["area"] as Rect2).has_point(spot):
			return false
	if map.has("SPINE") and (map["SPINE"] as Rect2).has_point(spot):
		return false
	if map.has("PLAZA") and spot.distance_to(map["PLAZA"]["centre"]) <= map["PLAZA"]["radius"]:
		return false
	return not _on_track(map.get("BIKE_TRACK", {}), spot)  # the red paved bike track


## Is the spot on a ring-shaped track (half: middle line's half size, width: metres)?
static func _on_track(track: Dictionary, spot: Vector2) -> bool:
	if track.is_empty():
		return false
	var half: Vector2 = track["half"]
	var w: float = track["width"] * 0.5
	var outer := Rect2(-half - Vector2.ONE * w, (half + Vector2.ONE * w) * 2.0)
	var inner := Rect2(-half + Vector2.ONE * w, (half - Vector2.ONE * w) * 2.0)
	return outer.has_point(spot) and not inner.has_point(spot)
