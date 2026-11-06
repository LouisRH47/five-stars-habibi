class_name PlaceBuilder
extends Node3D
## Builds the restaurants and villas from a data list when the game starts, and tells
## other scripts where each front door is. Which list is set in the scene (the "data"
## property): data/wahat_al_shams.gd for the real map, and
## data/test_area_places.gd for the test area. Test-area villas are scenes/villa.tscn;
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
const VENUE_ANIMATION_RESUME_M := 70.0
const VENUE_ANIMATION_PAUSE_M := 85.0
const VILLAS_PER_STEP := 6  # Session 86: homes built per loading-screen step


## The lists read from the data script. Other scripts (the DeliveryManager) use these.
var restaurants: Array = []
var villas: Array = []
var restaurant_size := Vector3.ONE
var villa_size := Vector3.ONE
## The regular customers (REGULARS in the data list), empty on maps without them.
var regulars: Array = []
var _venue_people: Array[Person] = []
var _venue_check_left := 0.25


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
	if WorldLoader.is_staged(self):
		return  # the loading screen runs build_steps() and finish_steps() (Session 86)
	WorldLoader.run_steps(build_steps())
	for step: Array in finish_steps():
		step[1].call_deferred()


## Session 86: the build as named steps (one per restaurant, venue and shop, the homes in
## small groups), so the loading screen can build a few per frame.
func build_steps() -> Array:
	if restaurants.is_empty() and villas.is_empty():
		_enter_tree()  # not in the game yet: read the lists now
	var steps: Array = []
	for place in restaurants:
		steps.append(["Opening %s..." % place["name"], _build_restaurant.bind(place)])
	var joined: Array = []
	for place in villas:
		if place.get("row_mode", false):
			joined.append(place)
	if not joined.is_empty():
		var rows := HousingRows.new()
		rows.name = "HousingRows"
		steps.append(["Building the town houses...", add_child.bind(rows)])
		var groups := HousingRows.row_groups(joined)
		for row: String in groups:
			steps.append(["Building the town houses...", rows.build_row.bind(row, groups[row], villa_size)])
	var group: Array = []
	for place in villas:
		if place.get("row_mode", false):
			continue
		if place.get("interior", false):
			if not group.is_empty():  # keep the homes in the same order as before
				steps.append(["Building the homes...", _build_villas.bind(group)])
				group = []
			var title := "the C Institute" if place["number"] == 903 else "the gym"
			steps.append(["Building %s..." % title, _build_venue.bind(place)])
			continue
		if is_spot(place):
			continue  # the school booth and the stable office are built by LandmarkBuilder
		group.append(place)
		if group.size() == VILLAS_PER_STEP:
			steps.append(["Building the homes...", _build_villas.bind(group)])
			group = []
	if not group.is_empty():
		steps.append(["Building the homes...", _build_villas.bind(group)])
	for shop_data: Dictionary in data.get_script_constant_map().get("SHOPS", []):
		steps.append(["Stocking the %s..." % shop_data.get("name", "shop"), func() -> void: add_child(ShopInterior.build(shop_data))])
	steps.append(["Unlocking the doors...", _find_venue_people])
	return steps


## Work that waits until the bike, the camera and the walker are in the game.
func finish_steps() -> Array:
	if data.get_script_constant_map().has("SHOPS"):
		return [["Hiring the shop staff...", _setup_shops]]
	return []


func _build_restaurant(place: Dictionary) -> void:
	var shop := _make_shop(place)
	shop.name = "Restaurant_" + place["id"]
	shop.position = place["position"]
	shop.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
	add_child(shop)


func _build_venue(place: Dictionary) -> void:
	var room_data: Dictionary = place.duplicate()
	room_data["name"] = "C Institute" if place["number"] == 903 else "Wahat Gym"
	room_data["arabic"] = "معهد سي" if place["number"] == 903 else "نادي الواحة الرياضي"
	room_data["venue_type"] = "institute" if place["number"] == 903 else "gym"
	var room := VenueBuilder.build(room_data, villa_size_of(place))
	room.name = "Institute" if place["number"] == 903 else "Gym"
	room.position = place["position"]
	room.rotation_degrees.y = place["facing"]
	add_child(room)


func _build_villas(group: Array) -> void:
	for place: Dictionary in group:
		if place.has("kind"):
			add_child(VillaBuilder.build(place, villa_size))  # Session 26: the house kit
			continue
		var villa = VILLA_SCENE.instantiate()
		villa.position = place["position"]
		villa.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
		villa.setup(place.get("house", place["number"]), villa_size)
		villa.name = "Villa%d" % place["number"]  # unique, even when two clusters both have a Villa 7
		add_child(villa)


func _find_venue_people() -> void:
	for venue in get_children():
		if venue.has_meta("walk_in"):
			for person in venue.get_children():
				if person is Person:
					_venue_people.append(person)
	set_process(not _venue_people.is_empty())


func _process(delta: float) -> void:
	_venue_check_left -= delta
	if _venue_check_left > 0.0:
		return
	_venue_check_left = 0.25
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	# Keep distant staff and diners visible in their last pose, and resume before they are close.
	for person in _venue_people:
		if not person.visible:
			continue  # the hidden queue people (venue_queue.gd turns them on when needed)
		var gap := camera.global_position.distance_squared_to(person.global_position)
		if person.process_mode == Node.PROCESS_MODE_DISABLED:
			if gap < VENUE_ANIMATION_RESUME_M * VENUE_ANIMATION_RESUME_M:
				person.process_mode = Node.PROCESS_MODE_INHERIT
		elif gap > VENUE_ANIMATION_PAUSE_M * VENUE_ANIMATION_PAUSE_M:
			person.process_mode = Node.PROCESS_MODE_DISABLED


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
	# Looks pass: the short queue at restaurant counters, and doors that slide open for you.
	var queue: Node = load("res://scripts/venue_queue.gd").new()
	queue.name = "VenueQueue"
	queue.places = self
	queue.walker = world.get_node_or_null("Walker")
	world.add_child(queue)
	if queue.walker != null:
		queue.walker.add_to_group("opens_doors")


## A restaurant, the mini market or the farm stall, depending on the shop's "style".
func _make_shop(place: Dictionary) -> Node3D:
	var size := restaurant_size_of(place)
	if place.get("interior", false) and RestaurantStyles.has_room(place.get("venue_type", "")):
		return RestaurantRoom.build(place, size)  # looks pass: the cosy restaurant room
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
		stall.goods = place.get("goods", "farm")  # Session 69: "honey" for the beekeeper
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
			if place.get("interior", false) and RestaurantStyles.has_room(place.get("venue_type", "")):
				return VenueBuilder.world_point(place, RestaurantRoom.counter_spot(place.get("venue_type", "")))
			if place.get("interior", false):
				return VenueBuilder.world_point(place, VenueBuilder.counter_local(restaurant_size_of(place)))
			return restaurant_approach(id)
	return Vector3.ZERO


## The spot on the ground in front of a villa's door.
func villa_door(number: int) -> Vector3:
	for place in villas:
		if place["number"] == number:
			if place.get("interior", false):
				var kind := "institute" if number == 903 else "gym"
				return VenueBuilder.world_point(place, VenueBuilder.reception_spot(kind, villa_size_of(place)))
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
