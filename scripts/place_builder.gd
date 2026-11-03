class_name PlaceBuilder
extends Node3D
## Builds the restaurants and villas from a data list when the game starts, and tells
## other scripts where each front door is. Which list is set in the scene (the "data"
## property): data/palm_grove.gd for the real map, data/test_area_places.gd for the test area.
## Palm Grove villas are scenes/villa.tscn, Wahat Al Shams homes come from the house kit
## (scripts/villa_builder.gd, Session 26), and restaurants are scenes/restaurant.tscn (with
## Arabic + English signs). Each restaurant node is called Restaurant_<id>, e.g. Restaurant_pizza.

## The data list to build from. It must have RESTAURANTS, VILLAS,
## RESTAURANT_SIZE and VILLA_SIZE.
@export var data: Script

const VILLA_SCENE := preload("res://scenes/villa.tscn")
const RESTAURANT_SCENE := preload("res://scenes/restaurant.tscn")


## The lists read from the data script. Other scripts (the DeliveryManager) use these.
var restaurants: Array = []
var villas: Array = []
var restaurant_size := Vector3.ONE
var villa_size := Vector3.ONE


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


func _ready() -> void:
	for place in restaurants:
		var restaurant = RESTAURANT_SCENE.instantiate()
		restaurant.name = "Restaurant_" + place["id"]
		restaurant.position = place["position"]
		restaurant.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
		restaurant.setup(place["name"], place["arabic"], place["colour"], restaurant_size)
		add_child(restaurant)
	for place in villas:
		# Session 26: Wahat Al Shams homes have a "kind" and are built by the house kit.
		# "spot" entries are drop-off spots (like the school gate), not homes: no house.
		if place.has("kind"):
			if place["kind"] != "spot":
				add_child(VillaBuilder.build(place, villa_size))
			continue
		var villa = VILLA_SCENE.instantiate()
		villa.position = place["position"]
		villa.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
		villa.setup(place.get("house", place["number"]), villa_size)
		villa.name = "Villa%d" % place["number"]  # unique, even when two clusters both have a Villa 7
		add_child(villa)


## The spot on the ground in front of a restaurant's door.
func restaurant_door(id: String) -> Vector3:
	for place in restaurants:
		if place["id"] == id:
			return door_point(place["position"], place["facing"], restaurant_size)
	push_error("No restaurant with id " + id)
	return Vector3.ZERO


## The spot on the ground in front of a villa's door.
func villa_door(number: int) -> Vector3:
	for place in villas:
		if place["number"] == number:
			return door_point(place["position"], place["facing"], villa_size)
	push_error("No villa number %d" % number)
	return Vector3.ZERO


## Works out the door spot: DOOR_DISTANCE metres in front of the building's front wall.
static func door_point(spot: Vector3, facing_deg: float, size: Vector3) -> Vector3:
	var angle := deg_to_rad(facing_deg)
	var front := Vector3(sin(angle), 0.0, cos(angle))
	return spot + front * (size.z * 0.5 + GameConfig.DOOR_DISTANCE)

