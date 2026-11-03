class_name PlaceBuilder
extends Node3D
## Builds the restaurants and villas from a data list when the game starts, and tells
## other scripts where each front door is. Which list is set in the scene (the "data"
## property): data/wahat_al_shams.gd for the real map, data/palm_grove.gd for the old map,
## data/test_area_places.gd for the test area. Palm Grove villas are scenes/villa.tscn;
## Wahat Al Shams homes come from the house kit (scripts/villa_builder.gd, Session 26).
## Shops are scenes/restaurant.tscn (with Arabic + English signs); each shop node is called
## Restaurant_<id>, e.g. Restaurant_pizza. Session 27: a shop with "style": "market" looks like
## the mini market, "stall" is the farm stall. A VILLAS entry with "kind": "spot" (the school
## booth, the stable office) is a drop-off spot only: no house is built for it. A place can
## have its own "size".

## The data list to build from. It must have RESTAURANTS, VILLAS,
## RESTAURANT_SIZE and VILLA_SIZE.
@export var data: Script

const VILLA_SCENE := preload("res://scenes/villa.tscn")
const RESTAURANT_SCENE := preload("res://scenes/restaurant.tscn")
const MARKET_SCENE := preload("res://scenes/supermarket.tscn")
const STALL_SCRIPT := preload("res://scripts/farm_stall.gd")


## The lists read from the data script. Other scripts (the DeliveryManager) use these.
var restaurants: Array = []
var villas: Array = []
var restaurant_size := Vector3.ONE
var villa_size := Vector3.ONE
## The regular customers (REGULARS in the data list), empty on maps without them.
var regulars: Array = []


func _enter_tree() -> void:
	# Read the data before any _ready runs, so other nodes can ask about doors right away.
	if data == null:
		push_error("PlaceBuilder has no data list set in the scene")
		return
	var lists := data.get_script_constant_map()
	restaurants = lists["RESTAURANTS"]
	villas = lists["VILLAS"]
	restaurant_size = lists["RESTAURANT_SIZE"]
	villa_size = lists["VILLA_SIZE"]
	regulars = lists.get("REGULARS", [])  # Session 32: only Wahat Al Shams has regulars


func _ready() -> void:
	for place in restaurants:
		var shop := _make_shop(place)
		shop.name = "Restaurant_" + place["id"]
		shop.position = place["position"]
		shop.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
		add_child(shop)
	var joined: Array = []
	for place in villas:
		if place.get("row_mode", false):
			joined.append(place)
	if not joined.is_empty():
		add_child(HousingRows.build(joined, villa_size))
	for place in villas:
		if place.get("row_mode", false):
			continue
		if place.get("interior", false):
			var room_data: Dictionary = place.duplicate()
			room_data["name"] = "C Institute" if place["number"] == 903 else "Wahat Gym"
			room_data["arabic"] = "معهد سي" if place["number"] == 903 else "نادي الواحة الرياضي"
			room_data["venue_type"] = "institute" if place["number"] == 903 else "gym"
			var room := VenueBuilder.build(room_data, villa_size_of(place))
			room.name = "Institute" if place["number"] == 903 else "Gym"
			room.position = place["position"]
			room.rotation_degrees.y = place["facing"]
			add_child(room)
			continue
		if is_spot(place):
			continue  # the school booth and the stable office are built by LandmarkBuilder
		if place.has("kind"):
			add_child(VillaBuilder.build(place, villa_size))  # Session 26: the house kit
			continue
		var villa = VILLA_SCENE.instantiate()
		villa.position = place["position"]
		villa.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
		villa.setup(place.get("house", place["number"]), villa_size)
		villa.name = "Villa%d" % place["number"]  # unique, even when two clusters both have a Villa 7
		add_child(villa)
	var lists := data.get_script_constant_map()
	for shop_data: Dictionary in lists.get("SHOPS", []):
		add_child(ShopInterior.build(shop_data))
	if lists.has("SHOPS"):
		_setup_shops.call_deferred()


func _setup_shops() -> void:
	var world := get_parent()
	var controller := ShopController.new()
	controller.name = "ShopController"
	controller.bike = world.get_node("Bike")
	controller.camera = world.get_node("FollowCamera")
	controller.walker = world.get_node_or_null("Walker")
	controller.configure(data.get_script_constant_map()["SHOPS"])
	world.add_child(controller)
	var counters := Node.new()
	counters.set_script(load("res://scripts/counter_panel.gd"))
	counters.name = "CounterPanel"
	world.add_child(counters)


## A restaurant, the mini market or the farm stall, depending on the shop's "style".
func _make_shop(place: Dictionary) -> Node3D:
	var size := restaurant_size_of(place)
	if place.get("interior", false):
		return VenueBuilder.build(place, size)
	var style: String = place.get("style", "")
	if style == "market":
		var market: Node3D = MARKET_SCENE.instantiate()
		market.setup(place["name"], place["arabic"], size)
		return market
	if style == "stall":
		var stall := StaticBody3D.new()
		stall.set_script(STALL_SCRIPT)
		stall.setup(place["name"], place["arabic"], place["colour"], size)
		return stall
	var restaurant: Node3D = RESTAURANT_SCENE.instantiate()
	restaurant.setup(place["name"], place["arabic"], place["colour"], size)
	return restaurant


## True for a drop-off spot that isn't a home (the school booth, the stable office).
static func is_spot(place: Dictionary) -> bool:
	return place.get("kind", "") == "spot"


## How big a shop is (its own "size", or the normal restaurant size).
func restaurant_size_of(place: Dictionary) -> Vector3:
	return place.get("size", restaurant_size)


## How big a home (or drop-off spot building) is.
func villa_size_of(place: Dictionary) -> Vector3:
	return place.get("size", villa_size)


## The spot on the ground in front of a restaurant's door.
func restaurant_door(id: String) -> Vector3:
	return restaurant_approach(id)


func restaurant_approach(id: String) -> Vector3:
	for place in restaurants:
		if place["id"] == id:
			return door_point(place["position"], place["facing"], restaurant_size_of(place))
	push_error("No restaurant with id " + id)
	return Vector3.ZERO


func restaurant_entrance(id: String) -> Vector3:
	for place in restaurants:
		if place["id"] == id:
			return VenueBuilder.world_point(place, Vector3(0, 0, restaurant_size_of(place).z * 0.5 + 0.7))
	return Vector3.ZERO


func restaurant_counter(id: String) -> Vector3:
	for place in restaurants:
		if place["id"] == id:
			if place.get("interior", false):
				return VenueBuilder.world_point(place, VenueBuilder.counter_local(restaurant_size_of(place)))
			return restaurant_approach(id)
	return Vector3.ZERO


## The spot on the ground in front of a villa's door.
func villa_door(number: int) -> Vector3:
	for place in villas:
		if place["number"] == number:
			if place.get("interior", false):
				return VenueBuilder.world_point(place, VenueBuilder.counter_local(villa_size_of(place)))
			return door_point(place["position"], place["facing"], villa_size_of(place))
	push_error("No villa number %d" % number)
	return Vector3.ZERO


func villa_approach(number: int) -> Vector3:
	for place in villas:
		if place["number"] == number:
			if place.has("approach"):
				return place["approach"]
			return door_point(place["position"], place["facing"], villa_size_of(place))
	return Vector3.ZERO


## Works out the door spot: DOOR_DISTANCE metres in front of the building's front wall.
static func door_point(spot: Vector3, facing_deg: float, size: Vector3) -> Vector3:
	var angle := deg_to_rad(facing_deg)
	var front := Vector3(sin(angle), 0.0, cos(angle))
	return spot + front * (size.z * 0.5 + GameConfig.DOOR_DISTANCE)
