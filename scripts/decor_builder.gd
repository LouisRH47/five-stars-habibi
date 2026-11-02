extends Node3D
## Builds the Session 6 decorations and static obstacles when the game starts, from the
## data list in data/palm_grove.gd: the mosque, the mini market, the park, palm trees,
## parked cars, car-park asphalt with bay lines, and speed bumps.
## Node names: Mosque, Supermarket, Park, Palm_<n>, ParkedCar_<n>, SpeedBump_<n>
## (n counts from 0 in list order). The smoke test checks they were all built.

## The map data to build from (set in the scene): data/palm_grove.gd.
@export var data: Script

const MOSQUE_SCENE := preload("res://scenes/mosque.tscn")
const SUPERMARKET_SCENE := preload("res://scenes/supermarket.tscn")
const PARK_SCENE := preload("res://scenes/park.tscn")
const PALM_SCENE := preload("res://scenes/palm_tree.tscn")
const CAR_SCENE := preload("res://scenes/parked_car.tscn")
const BUMP_SCENE := preload("res://scenes/speed_bump.tscn")

const ASPHALT_COLOUR := Color(0.36, 0.37, 0.39, 1)  # a little lighter than the roads
const LINE_COLOUR := Color(0.95, 0.95, 0.95, 1)
const PAD_THICKNESS := 0.03      # just under the roads (0.04), over the sand
const LINE_WIDTH := 0.12
const BAY_HALF_WIDTH := 1.5      # bay lines this far either side of a parked car's middle

## The lists read from the data (the smoke test checks every one was built).
var palms: Array = []
var parked_cars: Array = []
var speed_bumps: Array = []

# The constants from the data script, e.g. _map["PALM_TREES"].
var _map: Dictionary = {}


func _ready() -> void:
	if data == null:
		push_error("DecorBuilder has no data list set in the scene")
		return
	_map = data.get_script_constant_map()
	palms = _map["PALM_TREES"]
	parked_cars = _map["PARKED_CARS"]
	speed_bumps = _map["SPEED_BUMPS"]

	for area: Rect2 in _map["PARKING_AREAS"]:
		var middle := area.get_center()
		LowPoly.box(self, Vector3(area.size.x, PAD_THICKNESS, area.size.y), ASPHALT_COLOUR,
				Vector3(middle.x, PAD_THICKNESS * 0.5, middle.y))
	_build_mosque()
	_build_supermarket()
	var park: Node3D = PARK_SCENE.instantiate()
	park.name = "Park"
	add_child(park)
	park.setup(_map)
	_build_palms()
	_build_cars()
	_build_bumps()


func _build_mosque() -> void:
	var place: Dictionary = _map["MOSQUE"]
	var mosque: Node3D = MOSQUE_SCENE.instantiate()
	mosque.name = "Mosque"
	_place(mosque, place)
	var english: String = place["name"]
	var arabic: String = place["arabic"]
	var size: Vector3 = place["size"]
	mosque.setup(english, arabic, size)
	add_child(mosque)


func _build_supermarket() -> void:
	var place: Dictionary = _map["SUPERMARKET"]
	var shop: Node3D = SUPERMARKET_SCENE.instantiate()
	shop.name = "Supermarket"
	_place(shop, place)
	var english: String = place["name"]
	var arabic: String = place["arabic"]
	var size: Vector3 = place["size"]
	shop.setup(english, arabic, size)
	add_child(shop)


func _build_palms() -> void:
	for i in palms.size():
		var palm: Node3D = PALM_SCENE.instantiate()
		palm.name = "Palm_%d" % i
		var spot: Vector3 = palms[i]
		palm.position = spot
		palm.setup(i)
		add_child(palm)


func _build_cars() -> void:
	var size: Vector3 = _map["PARKED_CAR_SIZE"]
	for i in parked_cars.size():
		var place: Dictionary = parked_cars[i]
		var car: Node3D = CAR_SCENE.instantiate()
		car.name = "ParkedCar_%d" % i
		_place(car, place)
		car.setup(size, i)
		add_child(car)
		var bay: bool = place["bay"]
		if bay:
			_add_bay_lines(place, size)


## White lines either side of a parked car, as long as the car plus a bit.
func _add_bay_lines(place: Dictionary, car_size: Vector3) -> void:
	var lines := Node3D.new()
	_place(lines, place)
	add_child(lines)
	var line := Vector3(LINE_WIDTH, 0.01, car_size.z + 0.8)
	for side: float in [-1.0, 1.0]:
		LowPoly.box(lines, line, LINE_COLOUR, Vector3(BAY_HALF_WIDTH * side, PAD_THICKNESS + 0.005, 0))


func _build_bumps() -> void:
	var size: Vector3 = _map["SPEED_BUMP_SIZE"]
	for i in speed_bumps.size():
		var place: Dictionary = speed_bumps[i]
		var bump: Node3D = BUMP_SCENE.instantiate()
		bump.name = "SpeedBump_%d" % i
		_place(bump, place)
		bump.setup(size)
		add_child(bump)


## Puts a node at the place's position, turned to its facing (degrees).
func _place(node: Node3D, place: Dictionary) -> void:
	var spot: Vector3 = place["position"]
	var facing: float = place["facing"]
	node.position = spot
	node.rotation_degrees = Vector3(0.0, facing, 0.0)
