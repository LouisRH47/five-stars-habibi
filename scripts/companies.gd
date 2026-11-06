class_name Companies
## Session 88: the three made-up delivery companies (the list is data/companies.gd).
## Companies.find("zoomaroo") gives its name, Arabic name, colours, perk and logo paths.

const LIST := preload("res://data/companies.gd")


static func all() -> Array:
	return LIST.COMPANIES


## The company with this id, or {} if there isn't one.
static func find(id: String) -> Dictionary:
	for company: Dictionary in LIST.COMPANIES:
		if company["id"] == id:
			return company
	return {}


## The company you ride for now (Snackaroo if the save says something unknown).
static func current() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var state: Node = tree.root.get_node_or_null("GameState") if tree != null else null
	var found := find(str(state.company)) if state != null else {}
	return found if not found.is_empty() else find(LIST.DEFAULT)


## The company's logo picture (256 px), or null.
static func logo(company: Dictionary) -> Texture2D:
	return load(company.get("logo", "")) as Texture2D if company.has("logo") else null


## Session 92: the company's name and logo side by side (the wide picture, 256 px), or null.
static func mark(company: Dictionary) -> Texture2D:
	return load(company.get("mark", "")) as Texture2D if company.has("mark") else null


# --- The perks (numbers in game_config.gd) ---

## Snackaroo: tips 10% bigger, rounded up.
static func tip_with_perk(tip: int, company_id: String) -> int:
	return ceili(tip * (1.0 + GameConfig.COMPANY_SNACKAROO_TIP_BONUS)) if company_id == "snackaroo" and tip > 0 else tip


## Zoomaroo: customers wait 20% longer (the time target is that much longer).
static func wait_share(company_id: String) -> float:
	return 1.0 + GameConfig.COMPANY_ZOOMAROO_WAIT_BONUS if company_id == "zoomaroo" else 1.0


## Deliverooz: the bigger box takes 25% less food damage.
static func damage_share(company_id: String) -> float:
	return 1.0 - GameConfig.COMPANY_DELIVEROOZ_DAMAGE_CUT if company_id == "deliverooz" else 1.0
