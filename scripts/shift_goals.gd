class_name ShiftGoals
## The shift goals (Session 32, PRD "Shift goals"): at the start of each shift the phone shows
## 2 goals picked from the list below. Each one done pays GOAL_BONUS (15 Dh) at the end of the
## shift. GameState keeps which goals you have; this script only knows the list and checks
## how far you are, from the shift's deliveries (GameState.history) and its crash count.
## The goal numbers are in game_config.gd.

## Every goal: its id and what the phone says.
const ALL := {
	"deliveries": "Make %d deliveries" % GameConfig.GOAL_DELIVERIES,
	"streak": "%d five-star deliveries in a row" % GameConfig.GOAL_FIVE_STAR_STREAK,
	"no_crashes": "No crashes",
	"lunch": "A school lunch order" if GameConfig.GOAL_LUNCH_ORDERS == 1 else "%d school lunch orders" % GameConfig.GOAL_LUNCH_ORDERS,
	"fragile": "A fragile cake with 5 stars",
	"clusters": "Deliver to %d different clusters" % GameConfig.GOAL_CLUSTERS,
}


## The goals this map can do: no lunch goal without a school, no cluster goal without
## clusters, no cake goal without Sunrise Bakery.
static func allowed(places: PlaceBuilder) -> Array:
	var ids: Array = ALL.keys()
	if places == null:
		return ids
	if not places.villas.any(func(v): return v["number"] == GameConfig.SCHOOL_SPOT):
		ids.erase("lunch")
	var clusters := {}
	for villa in places.villas:
		if villa.get("cluster", "") != "":
			clusters[villa["cluster"]] = true
	if clusters.size() < GameConfig.GOAL_CLUSTERS:
		ids.erase("clusters")
	if not places.restaurants.any(func(r): return r["id"] == GameConfig.FRAGILE_SHOP):
		ids.erase("fragile")
	return ids


## How far along a goal is: x = done so far, y = needed. jobs: this shift's history entries.
static func progress(id: String, jobs: Array, crashes: int) -> Vector2i:
	var done := jobs.filter(func(j): return not j["cancelled"])
	match id:
		"deliveries":
			return Vector2i(mini(done.size(), GameConfig.GOAL_DELIVERIES), GameConfig.GOAL_DELIVERIES)
		"streak":
			var best := 0
			var run := 0
			for job in jobs:
				run = run + 1 if not job["cancelled"] and job["stars"] >= 5.0 else 0
				best = maxi(best, run)
			return Vector2i(mini(best, GameConfig.GOAL_FIVE_STAR_STREAK), GameConfig.GOAL_FIVE_STAR_STREAK)
		"no_crashes":
			var ok := crashes == 0 and done.size() >= GameConfig.GOAL_NO_CRASH_MIN_DELIVERIES
			return Vector2i(1 if ok else 0, 1)
		"lunch":
			var lunches := done.filter(func(j): return j.get("lunch", false)).size()
			return Vector2i(mini(lunches, GameConfig.GOAL_LUNCH_ORDERS), GameConfig.GOAL_LUNCH_ORDERS)
		"fragile":
			var cakes := done.filter(func(j): return j.get("special", "") == "fragile" and j["stars"] >= 5.0).size()
			return Vector2i(mini(cakes, 1), 1)
		"clusters":
			var seen := {}
			for job in done:
				if job.get("cluster", "") != "":
					seen[job["cluster"]] = true
			return Vector2i(mini(seen.size(), GameConfig.GOAL_CLUSTERS), GameConfig.GOAL_CLUSTERS)
	return Vector2i(0, 1)


static func is_done(id: String, jobs: Array, crashes: int) -> bool:
	var p := progress(id, jobs, crashes)
	return p.x >= p.y


## One line for the phone or the summary, e.g. "Make 8 deliveries  3/8".
static func line(id: String, jobs: Array, crashes: int) -> String:
	var p := progress(id, jobs, crashes)
	var text: String = ALL.get(id, id)
	if p.y > 1:
		text += "  %d/%d" % [p.x, p.y]
	return text
