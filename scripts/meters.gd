class_name Meters
extends Node
## Runs the three meters (PRD "The three meters") while you carry food to the villa.
## Time: full at pickup, empty at the target time. Freshness: drains every second, faster
## for ice cream. Damage: drops on speed bumps, hard braking and crashes into things,
## and bubble tea spills the most. Session 32: rush orders get less time, fragile cakes
## take double damage. The values live in GameState; numbers in game_config.gd.
## A meter at 0 never cancels the order: you can always deliver, just for fewer stars.

## The bike, to hear about bumps, crashes and hard braking.
@export var bike: Node3D
## Knows where the restaurant and villa doors are (for the target time).
@export var delivery_manager: DeliveryManager

enum Band { GREEN, ORANGE, RED }


func _ready() -> void:
	add_to_group("meters")  # cats and kids (scripts/critter.gd) call hurt_food_critter()
	GameState.order_stage_changed.connect(_on_stage_changed)
	if bike != null:
		bike.bumped.connect(_on_bumped)
		bike.went_over_bump.connect(_on_speed_bump)
		bike.hard_braked.connect(_on_hard_brake)
		bike.crashed.connect(_on_crashed)
		if bike.has_signal("knocked"):  # Session 87: a bump knocks the food a little
			bike.knocked.connect(func(_impact: Dictionary): hurt_food(GameConfig.CRASH_BUMP_DAMAGE))


func _physics_process(delta: float) -> void:
	if not _carrying():
		return
	GameState.ride_time += delta
	var time := time_meter_for(GameState.ride_time, GameState.target_time)
	var drain := _per_food(GameConfig.FRESHNESS_DRAIN) * GameState.freshness_multiplier()
	if GameState.upgrade_level("insulated_bag") > 0:
		drain *= GameConfig.INSULATED_BAG_FRESHNESS_SHARE
	var fresh := GameState.meter_freshness - drain * delta
	GameState.set_meters(time, fresh, GameState.meter_damage)


## Green above 60, orange 30 to 60, red under 30.
static func band(value: float) -> Band:
	if value > GameConfig.METER_GREEN_ABOVE:
		return Band.GREEN
	if value >= GameConfig.METER_RED_BELOW:
		return Band.ORANGE
	return Band.RED


## The time bar after riding `ride` seconds with a target of `target` seconds: 100 at
## pickup, TIME_METER_AT_TARGET at the target time, 0 at TIME_EMPTY_AT x the target.
static func time_meter_for(ride: float, target: float) -> float:
	var done := ride / maxf(target, 1.0)
	var at_target := GameConfig.TIME_METER_AT_TARGET
	if done <= 1.0:
		return lerpf(100.0, at_target, done)
	return maxf(at_target * (1.0 - (done - 1.0) / maxf(GameConfig.TIME_EMPTY_AT - 1.0, 0.01)), 0.0)


## Seconds to ride from a restaurant door to a villa door: straight-line distance at
## 20 km/h, times 1.5 for corners, plus 20 seconds (PRD).
static func target_time_for(from: Vector3, to: Vector3) -> float:
	var metres := Vector2(from.x - to.x, from.z - to.z).length()
	return metres / (GameConfig.TIME_TARGET_SPEED_KMH / 3.6) * GameConfig.TIME_TARGET_CORNERS \
			+ GameConfig.TIME_TARGET_EXTRA


## Knocks the food: takes `amount` off the damage meter (only while carrying food).
func hurt_food(amount: float) -> void:
	if _carrying():
		if GameState.upgrade_level("anti_spill") > 0:
			amount *= GameConfig.ANTI_SPILL_DAMAGE_SHARE
		if bike != null and "boost_active" in bike and bike.boost_active:
			amount *= GameConfig.BOOST_FOOD_DAMAGE_TIMES
		if GameState.current_order.special == "fragile":
			amount *= GameConfig.FRAGILE_DAMAGE_TIMES  # a fragile cake: every knock counts double
		amount *= Companies.damage_share(GameState.company)  # Session 88: Deliverooz's bigger box
		GameState.set_meters(GameState.meter_time, GameState.meter_freshness, GameState.meter_damage - amount)


## A cat or a kid on a scooter got bumped (Session 9).
func hurt_food_critter() -> void:
	hurt_food(_per_food(GameConfig.DAMAGE_CRITTER))


func _carrying() -> bool:
	return GameState.stage == GameState.Stage.TO_VILLA and GameState.current_order != null


## The number for the food you're carrying, from a per-food list in game_config.gd.
func _per_food(table: Dictionary) -> float:
	if GameState.current_order == null:
		return 0.0
	return table.get(GameState.current_order.food, table["pizza"])


func _on_stage_changed(stage: int) -> void:
	if stage != GameState.Stage.TO_VILLA or delivery_manager == null:
		return
	var order := GameState.current_order
	var places := delivery_manager.place_builder
	var target := target_time_for(places.restaurant_door(order.restaurant_id), places.villa_door(order.villa_number))
	if order.special == "rush":
		target *= GameConfig.RUSH_TIME_SHARE  # rush order: less time (Session 32)
	target *= Companies.wait_share(GameState.company)  # Session 88: Zoomaroo customers wait longer
	GameState.start_meters(target)


func _on_bumped(strength: float) -> void:
	hurt_food(_per_food(GameConfig.DAMAGE_COLLISION) * strength)


func _on_speed_bump(strength: float) -> void:
	# Slow over a bump (at or under the safe speed): only a little damage. Fast: the full knock.
	var kmh := strength * GameConfig.BIKE_MAX_SPEED_KMH
	var too_fast := clampf((kmh - GameConfig.SPEED_BUMP_SAFE_KMH)
			/ (GameConfig.BIKE_MAX_SPEED_KMH - GameConfig.SPEED_BUMP_SAFE_KMH), 0.0, 1.0)
	var gear := GameConfig.COMFY_TYRES_DAMAGE_SHARE if GameState.upgrade_level("tyres") > 0 else 1.0
	hurt_food(_per_food(GameConfig.DAMAGE_SPEED_BUMP) * lerpf(GameConfig.DAMAGE_SPEED_BUMP_SLOW_SHARE, 1.0, too_fast) * gear)


func _on_crashed(big: bool) -> void:
	if not big:
		hurt_food(GameConfig.CRASH_SMALL_DAMAGE)  # you fell off: the food took a big knock


func _on_hard_brake() -> void:
	var gear := GameConfig.BETTER_BRAKES_DAMAGE_SHARE if GameState.upgrade_level("brakes") > 0 else 1.0
	hurt_food(_per_food(GameConfig.DAMAGE_HARD_BRAKE) * gear)
