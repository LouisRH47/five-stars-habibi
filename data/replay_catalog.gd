class_name ReplayCatalog
## Names and descriptions for the saved, in-game shift rotation. No real-world dates.

const DAYS := ["normal", "hot_noon", "rush_hour", "shop_special"]
const DAY_NAMES := {
	"normal": "A sunny day",
	"hot_noon": "Hot Noon",
	"rush_hour": "Rush Hour",
	"shop_special": "Brain Freeze special",
}
const DAY_DETAILS := {
	"normal": "Take your time and learn the neighbourhood.",
	"hot_noon": "Food loses freshness 25% faster. Choose your jobs carefully.",
	"rush_hour": "Orders arrive sooner and delivery pay is 10% higher.",
	"shop_special": "Double tip chance on Brain Freeze orders.",
}
const REGULAR_NAMES := {"mariam": "Auntie Mariam", "rashid": "Mr Rashid", "dana": "Ms Dana", "hamdan": "Hamdan"}


static func next_day(current: String) -> String:
	var choices: Array = DAYS.filter(func(kind): return kind != current)
	return choices.pick_random()


static func day_name(kind: String) -> String:
	return DAY_NAMES.get(kind, DAY_NAMES["normal"])


static func day_detail(kind: String) -> String:
	return DAY_DETAILS.get(kind, DAY_DETAILS["normal"])
