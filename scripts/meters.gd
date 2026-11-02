class_name Meters
extends Node
## Runs the three meters (PRD "The three meters") while you carry food to the villa.
## Time: full at pickup, empty at the target time. Freshness: drains every second, faster
## for ice cream. Damage: drops on speed bumps, hard braking and crashes into things,
## and bubble tea spills the most. The values live in GameState; numbers in game_config.gd.
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


func _physics_process(delta: float) -> void:
	if not _carrying():
		return
	GameState.ride_time += delta
	var time := 100.0 * (1.0 - GameState.ride_time / maxf(GameState.target_time, 1.0))
	var fresh := GameState.meter_freshness - _per_food(GameConfig.FRESHNESS_DRAIN) * delta
	GameState.set_meters(time, fresh, GameState.meter_damage)


## Green above 60, orange 30 to 60, red under 30.
static func band(value: float) -> Band:
	if value > GameConfig.METER_GREEN_ABOVE:
		return Band.GREEN
	if value >= GameConfig.METER_RED_BELOW:
		return Band.ORANGE
	return Band.RED


## Seconds to ride from a restaurant door to a villa door: straight-line distance at
## 20 km/h, times 1.5 for corners, plus 20 seconds (PRD).
static func target_time_for(from: Vector3, to: Vector3) -> float:
	var metres := Vector2(from.x - to.x, from.z - to.z).length()
	return metres / (GameConfig.TIME_TARGET_SPEED_KMH / 3.6) * GameConfig.TIME_TARGET_CORNERS \
			+ GameConfig.TIME_TARGET_EXTRA


## Knocks the food: takes `amount` off the damage meter (only while carrying food).
func hurt_food(amount: float) -> void:
	if _carrying():
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
	GameState.start_meters(target_time_for(places.restaurant_door(order.restaurant_id),
			places.villa_door(order.villa_number)))


func _on_bumped(strength: float) -> void:
	hurt_food(_per_food(GameConfig.DAMAGE_COLLISION) * strength)


func _on_speed_bump(strength: float) -> void:
	hurt_food(_per_food(GameConfig.DAMAGE_SPEED_BUMP) * lerpf(GameConfig.DAMAGE_SPEED_BUMP_SLOW_SHARE, 1.0, strength))


func _on_crashed(big: bool) -> void:
	if not big:
		hurt_food(GameConfig.CRASH_SMALL_DAMAGE)  # you fell off: the food took a big knock


func _on_hard_brake() -> void:
	hurt_food(_per_food(GameConfig.DAMAGE_HARD_BRAKE))
