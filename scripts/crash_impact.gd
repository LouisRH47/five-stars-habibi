class_name CrashImpact
extends RefCounted
## One immutable description of an accident, captured before the bike stops.
## Both the authored fall and clinic quote use this record; bounce contacts never bill again.


static func capture(incoming_velocity: Vector3, normal: Vector3, obstacle: Object = null,
		obstacle_velocity := Vector3.ZERO, force_major := false) -> Dictionary:
	var relative := (incoming_velocity - obstacle_velocity) * Vector3(1, 0, 1)
	var kmh := relative.length() * 3.6
	var wall_normal := (normal * Vector3(1, 0, 1)).normalized()
	var head_on := absf(relative.normalized().dot(wall_normal)) if kmh > 0.001 else 0.0
	var normal_kmh := kmh * head_on
	var tangent_kmh := sqrt(maxf(kmh * kmh - normal_kmh * normal_kmh, 0.0))
	var category := category_for(obstacle)
	var hardness := hardness_for(obstacle, category)
	var score := (normal_kmh + tangent_kmh * GameConfig.CRASH_GLANCE_WEIGHT) * hardness
	var soft := category == "soft"
	var level := level_for(kmh, head_on, score, soft, force_major)
	var big := level == "big"
	# Session 87: a big crash is billed as severe (150 Dh hospital) or, very hard, critical.
	var severity := "minor"
	if big:
		severity = "critical" if score >= GameConfig.CRASH_CRITICAL_SCORE else "severe"
	var kind := "tip" if score < GameConfig.CRASH_TIP_SCORE or soft else ("skid" if head_on < GameConfig.CRASH_TUMBLE_HEAD_ON else "tumble")
	var bill := 0
	if level == "bump":
		bill = GameConfig.CRASH_BUMP_BILL
	elif level == "fall":
		bill = GameConfig.CRASH_FALL_BILL
	return {
		"what": label_for(obstacle), "kmh": kmh, "riding_kmh": incoming_velocity.length() * 3.6,
		"normal_kmh": normal_kmh, "head_on": head_on,
		"angle_degrees": rad_to_deg(acos(clampf(head_on, 0.0, 1.0))),
		"direction": relative.normalized(), "normal": wall_normal,
		"side": -1.0 if relative.cross(wall_normal).y < 0.0 else 1.0,
		"category": category, "hardness": hardness, "score": score,
		"severity": severity, "big": big, "fall": kind,
		"level": level, "bill": bill,
		"crash": level == "fall" or level == "big",  # you come off the bike
		"boosted": force_major,
	}


## Session 87: which of the three crash levels an impact is. "" is just a nudge (too slow, or
## only a scrape along the side). "bump": under CRASH_BUMP_KMH, or anything soft (a hedge, a
## bin, a cat): you stay on. "fall": up to CRASH_FALL_KMH: you fall off. "big": faster, into
## something hard: the clinic. The rocket boost makes any hit big (the old rule).
static func level_for(kmh: float, head_on: float, score: float, soft: bool, boosted := false) -> String:
	if boosted:
		return "big"
	# A scrape along a wall counts a fifth of its speed (the score), so it's rarely a bump.
	if score < GameConfig.CRASH_BUMP_MIN_KMH or head_on < GameConfig.CRASH_GLANCING_MIN:
		return ""
	if soft or score < GameConfig.CRASH_BUMP_KMH:
		return "bump"
	if score <= GameConfig.CRASH_FALL_KMH:
		return "fall"
	return "big"


static func severity_for(score: float) -> String:
	if score >= GameConfig.CRASH_CRITICAL_SCORE:
		return "critical"
	if score >= GameConfig.CRASH_SEVERE_SCORE:
		return "severe"
	if score >= GameConfig.CRASH_MAJOR_SCORE:
		return "moderate"
	return "minor"


## Empty input keeps direct legacy big_crash() calls at the prototype's severe quote.
static func quote(impact: Dictionary = {}) -> Dictionary:
	var severity: String = impact.get("severity", "severe")
	if not GameConfig.CRASH_BILL_BANDS.has(severity):
		severity = "severe"
	var made: Dictionary = GameConfig.CRASH_BILL_BANDS[severity].duplicate()
	made["severity"] = severity
	return made


static func category_for(obstacle: Object) -> String:
	var node := obstacle as Node
	while node != null:
		if node.has_meta("impact_category"):
			return str(node.get_meta("impact_category"))
		# Avoid a class dependency on Walker: it already reads GameState, which uses us.
		var source := node.get_script() as Script
		if node.is_in_group("critter") or (source != null and source.resource_path.ends_with("/walker.gd")):
			return "soft"
		var title := String(node.name).to_lower()
		if "car" in title or "bus" in title or "vehicle" in title:
			return "vehicle"
		if "palm" in title or "tree" in title or "fence" in title:
			return "wood"
		if "cone" in title or "bush" in title or "plant" in title:
			return "soft"
		node = node.get_parent()
	return "rigid"


static func hardness_for(obstacle: Object, category: String) -> float:
	var node := obstacle as Node
	while node != null:
		if node.has_meta("impact_hardness"):
			return clampf(float(node.get_meta("impact_hardness")), 0.1, 1.5)
		node = node.get_parent()
	return GameConfig.CRASH_MATERIAL_HARDNESS.get(category, 1.0)


static func label_for(obstacle: Object) -> String:
	var node := obstacle as Node
	while node != null:
		if node.has_meta("impact_name"):
			return str(node.get_meta("impact_name"))
		var title := String(node.name)
		if title.begins_with("ParkedCar"):
			return "a parked car"
		if title.begins_with("Villa") or title.begins_with("Housing"):
			return "a villa wall"
		if title.begins_with("Palm"):
			return "a palm tree"
		if title.begins_with("Restaurant"):
			return "a restaurant wall"
		if title == "RoadWorks":
			return "road works"
		if node.is_in_group("critter"):
			return "a cat" if title.begins_with("Cat") else "someone on the path"
		node = node.get_parent()
	return "a wall"
