class_name DistrictTraffic
extends Node3D
## Sessions 37–38: fixed car/bus routes, solar bays and separated riding tracks.
## Session 62: the car parks (CarParkBuilder) and their visiting cars.
## All layout comes from the map data. No vehicle can select an unlisted road.

@export var data: Script

const CAR_MODEL := preload("res://scripts/parked_car.gd")
const WHITE := Color(0.96, 0.96, 0.91)
const SOLAR := Color(0.13, 0.22, 0.34)
const METAL := Color(0.48, 0.51, 0.53)
const ASPHALT := Color(0.33, 0.34, 0.36)
const BUS_SIZE := Vector3(2.5, 3.0, 8.2)

var cars: Array[TrafficVehicle] = []
var buses: Array[TrafficVehicle] = []
var arena_horse: ArenaHorse
var solar_bays := 0
var rail_segments := 0
var bus_arrivals := 0
var _map := {}
var _ring := Rect2()
var _bus_entry := Vector3.ZERO
var _bus_bay := Vector3.ZERO
var _next_arrival := 0.0
var _last_elapsed := 0.0


func _ready() -> void:
	if data == null:
		return
	_map = data.get_script_constant_map()
	_ring = _ring_bounds()
	if _ring.size == Vector2.ZERO:
		return
	_build_solar_bays()
	_build_cars()
	_build_horse_rails()
	_build_arena()
	_setup_bus()


func _physics_process(_delta: float) -> void:
	if _bus_entry == _bus_bay or GameState.tutorial_running or GameState.shift_clock_out:
		return
	# One real second is one game minute. Reading the shift clock preserves every pause.
	var elapsed := GameConfig.SHIFT_LENGTH - GameState.shift_time_left
	if elapsed < _last_elapsed:
		_next_arrival = GameConfig.BUS_INTERVAL_GAME_MINUTES
	_last_elapsed = elapsed
	var approach := _bus_entry.distance_to(_bus_bay) / GameConfig.TRAFFIC_BUS_SPEED
	# The bay and its short access road are one shared spur. Keep a delayed
	# arrival pending until the departing bus has cleared it, rather than sending
	# two buses head-on or repeatedly spawning them at the same entry point.
	if elapsed >= _next_arrival - approach and _bus_access_clear():
		_spawn_bus(false)
		_next_arrival += GameConfig.BUS_INTERVAL_GAME_MINUTES


func _ring_bounds() -> Rect2:
	var bounds := Rect2()
	var first := true
	for road: Dictionary in _map.get("ROADS", []):
		if road.get("name", "") != "Ring Road":
			continue
		for point: Vector2 in [road["from"], road["to"]]:
			if first:
				bounds = Rect2(point, Vector2.ZERO)
				first = false
			else:
				bounds = bounds.expand(point)
	if first:
		return bounds
	var inset := bounds.grow(-2.2)
	# Keep the north lane centred so buses clear the storefronts' rear walls.
	return inset.expand(Vector2(inset.position.x, bounds.position.y))


func _watch(vehicle: Node3D) -> void:
	for title in ["Bike", "Walker"]:
		var actor := get_parent().get_node_or_null(title) as Node3D
		if actor != null:
			vehicle.watch.append(actor)


func _ring_points() -> Array[Vector3]:
	return [Vector3(_ring.position.x, 0, _ring.position.y), Vector3(_ring.end.x, 0, _ring.position.y),
			Vector3(_ring.end.x, 0, _ring.end.y), Vector3(_ring.position.x, 0, _ring.end.y)]


func _build_cars() -> void:
	var ring := _ring_points()
	for i in range(4):
		var car := _make_car(ring, i)
		car.start_at(i)
	if GameConfig.CARPARK_ROWS and _map.has("CAR_PARKS"):
		_build_visitors(ring)
		return
	for i in _map.get("PARKING_AREAS", []).size():
		var area: Rect2 = _map["PARKING_AREAS"][i]
		var north := area.get_center().y < 0.0
		var x := area.end.x - 3.5
		var edge_z := _ring.position.y if north else _ring.end.y
		var entry := Vector3(x, 0, edge_z)
		var aisle := Vector3(x, 0, area.end.y - 9.0)
		var park := Vector3(area.position.x + 4.0, 0, aisle.z)
		var route: Array[Vector3] = [park, aisle, entry]
		var start := 1 if north else 3
		for offset in range(4):
			route.append(ring[(start + offset) % 4])
		route.append(entry)
		route.append(aisle)
		route.append(park)
		var car := _make_car(route, i + 4)
		car.stop_index = route.size() - 1
		car.dwell_time = GameConfig.TRAFFIC_PARK_WAIT
		car._wait_left = GameConfig.TRAFFIC_PARK_WAIT + i
		_build_access(entry, aisle)
		_solar_canopy(park, 90.0, Vector3(3.2, 0.16, 5.8))


func _make_car(route: Array, number: int) -> TrafficVehicle:
	var vehicle := TrafficVehicle.new()
	vehicle.name = "MovingCar_%d" % number
	add_child(vehicle)
	var look: Node3D = CAR_MODEL.MODELS[number % CAR_MODEL.MODELS.size()].instantiate()
	var bounds := CAR_MODEL._bounds(look)
	look.rotation.y = PI # Kenney faces +Z; traffic faces -Z.
	look.scale = Vector3.ONE * 4.2 / bounds.size.z
	look.position.y = -bounds.position.y * look.scale.y
	vehicle.setup(route, "car", look, Vector3(1.9, 1.7, 4.2), GameConfig.TRAFFIC_CAR_SPEED)
	_watch(vehicle)
	cars.append(vehicle)
	return vehicle


## Session 62: one visiting car per car park. It waits in its free bay beside the first aisle,
## drives out through the aisle onto the ring road, goes once round and parks again.
## Cars never use the buggy lanes: only the ring road, the aisle and the bay.
func _build_visitors(ring: Array[Vector3]) -> void:
	var parks: Array = _map["CAR_PARKS"]
	for i in parks.size():
		var park: Dictionary = parks[i]
		var visit: Dictionary = park["visitor"]
		var north: bool = park["north"]
		var turned: bool = park.get("turned", false)   # rows east-west, on the east ring road
		var bay: Vector3 = visit["bay"]
		var entry: Vector3
		var aisle: Vector3
		if turned:
			entry = Vector3(_ring.end.x, 0, visit["aisle_z"])
			aisle = Vector3(bay.x, 0, visit["aisle_z"])
		else:
			var x: float = visit["aisle_x"]
			entry = Vector3(x, 0, _ring.position.y if north else _ring.end.y)
			aisle = Vector3(x, 0, bay.z)
		var route: Array[Vector3] = [bay, aisle, entry]
		var start := 2 if turned else (1 if north else 3)
		for offset in range(4):
			route.append(ring[(start + offset) % 4])
		route.append(entry)
		route.append(aisle)
		route.append(bay)
		var car := _make_car(route, i + 4)
		car.stop_index = route.size() - 1
		car.dwell_time = GameConfig.TRAFFIC_PARK_WAIT
		car._wait_left = GameConfig.TRAFFIC_PARK_WAIT + i
		for opening: Rect2 in park["aisles"]:
			if turned:
				var across := opening.get_center().y
				_build_access(Vector3(park["ring_x"], 0, across), Vector3(park["first_bay_x"], 0, across), opening.size.y, true)
				continue
			var middle := opening.get_center().x
			_build_access(Vector3(middle, 0, park["ring_z"]), Vector3(middle, 0, park["first_bay_z"]), opening.size.x, true)


## The short asphalt road from the ring road into a car park. Session 62 (textured = true):
## the aisle's opening through the verge, level with the car park's asphalt.
func _build_access(entry: Vector3, inside: Vector3, width := 6.0, textured := false) -> void:
	var centre := (entry + inside) * 0.5
	if textured:
		var size := Vector3(width, CarParkBuilder.PAD_TOP, entry.distance_to(inside))
		if absf(entry.x - inside.x) > absf(entry.z - inside.z):   # a turned car park's aisle runs along x
			size = Vector3(size.z, size.y, size.x)
		var mouth := LowPoly.box(self, size, ASPHALT,
				centre + Vector3.UP * CarParkBuilder.PAD_TOP * 0.5)
		mouth.name = "ParkingAccess"
		mouth.material_override = TerrainMaterials.make("road")
		return
	var road := LowPoly.box(self, Vector3(width, 0.025, entry.distance_to(inside) + 4.0), ASPHALT, centre + Vector3.UP * 0.06)
	road.name = "ParkingAccess"


func _build_solar_bays() -> void:
	if GameConfig.CARPARK_ROWS and _map.has("CAR_PARKS"):
		# Session 62: Louis's rows (1, 2 back to back, 1), a solar roof over every row.
		solar_bays += CarParkBuilder.build(self, _map)
		if GameConfig.CARPARK_CAR_BATCH:
			var looks := CarParkCars.new()
			looks.name = "ParkedCarLooks"
			add_child(looks)
			looks.build(_map.get("PARKED_CARS", []), _map["PARKED_CAR_SIZE"])
		return
	for place: Dictionary in _map.get("PARKED_CARS", []):
		if place.get("bay", false):
			_solar_canopy(place["position"], place["facing"], Vector3(8.5, 0.16, 6.2))


func _solar_canopy(spot: Vector3, facing: float, roof_size: Vector3) -> void:
	var shelter := StaticBody3D.new()
	shelter.name = "SolarBay_%d" % solar_bays
	shelter.position = spot
	shelter.rotation_degrees.y = facing
	add_child(shelter)
	var kit := MeshKit.new()
	kit.box(roof_size, SOLAR, Vector3(0, 3.2, 0), Basis(Vector3.RIGHT, -0.08))
	for x in [-roof_size.x * 0.45, roof_size.x * 0.45]:
		kit.box(Vector3(0.14, 3.2, 0.14), METAL, Vector3(x, 1.6, -2.8))
		LowPoly.solid_box(shelter, Vector3(0.14, 3.2, 0.14), Vector3(x, 1.6, -2.8))
	for column in range(1, 6):
		kit.box(Vector3(0.025, 0.025, roof_size.z), METAL, Vector3(-roof_size.x * 0.5 + roof_size.x * column / 6.0, 3.3, 0))
	for row in [-1.5, 0.0, 1.5]:
		kit.box(Vector3(roof_size.x, 0.025, 0.025), METAL, Vector3(0, 3.3, row))
	shelter.add_child(kit.finish())
	solar_bays += 1


func _setup_bus() -> void:
	for road: Dictionary in _map.get("ROADS", []):
		if road.get("name", "") == "Bus Access":
			var from: Vector2 = road["from"]
			var to: Vector2 = road["to"]
			_bus_entry = Vector3(_ring.position.x, 0, from.y)
			_bus_bay = Vector3(to.x, 0, to.y - 2.5)
	if _bus_entry == _bus_bay:
		return
	_next_arrival = GameConfig.BUS_INTERVAL_GAME_MINUTES
	_spawn_bus(true)


func _spawn_bus(already_at_bay: bool) -> TrafficVehicle:
	var bus := TrafficVehicle.new()
	bus.name = "CommunityBus_%d" % bus_arrivals
	add_child(bus)
	var ring := _ring_points()
	var route: Array[Vector3] = [_bus_entry, _bus_bay, _bus_entry, ring[0], ring[1], ring[2], ring[3], _bus_entry]
	bus.setup(route, "bus", _bus_look(), BUS_SIZE, GameConfig.TRAFFIC_BUS_SPEED)
	bus.stop_index = 1
	bus.dwell_time = GameConfig.BUS_DWELL_TIME
	bus.despawn_at_end = true
	_watch(bus)
	if already_at_bay:
		bus.start_at(1)
		bus._wait_left = GameConfig.BUS_DWELL_TIME
	bus_arrivals += 1
	buses.append(bus)
	return bus


func _bus_access_clear() -> bool:
	buses = buses.filter(func(bus): return is_instance_valid(bus) and not bus.is_queued_for_deletion())
	for bus in buses:
		if bus._next <= bus.stop_index + 1:
			return false # Inbound, dwelling at the bay, or leaving the spur.
	# Also let a ring-road vehicle finish passing before adding a bus at the
	# junction. Include both bodies and the normal following gap, so a new bus
	# cannot appear inside a car or obstruct a bus that has only just turned out.
	for vehicle: TrafficVehicle in cars + buses:
		if not is_instance_valid(vehicle) or vehicle.is_queued_for_deletion():
			continue
		var clearance := (vehicle.size.z + BUS_SIZE.z) * 0.5 + GameConfig.TRAFFIC_STOP_DISTANCE
		if vehicle.position.distance_to(_bus_entry) < clearance:
			return false
	return true


func _bus_look() -> Node3D:
	var model := Node3D.new()
	var kit := MeshKit.new()
	kit.box(Vector3(2.4, 2.35, 8.0), WHITE, Vector3(0, 1.65, 0))
	kit.box(Vector3(2.44, 0.55, 8.05), Color(0.08, 0.42, 0.48), Vector3(0, 0.95, 0))
	kit.box(Vector3(2.1, 1.1, 0.05), SOLAR, Vector3(0, 2.1, -4.03))
	for side in [-1.0, 1.0]:
		for z in [-2.8, -1.3, 0.2, 1.7, 3.2]:
			kit.box(Vector3(0.04, 0.95, 1.2), SOLAR, Vector3(side * 1.22, 2.15, z))
		for z in [-2.6, 2.6]:
			kit.cylinder(0.45, 0.45, 0.2, Color(0.13, 0.14, 0.15), Vector3(side * 1.18, 0.45, z), Basis(Vector3.BACK, PI * 0.5))
	for x in [-0.8, 0.8]:
		kit.box(Vector3(0.4, 0.2, 0.05), Color(1, 0.94, 0.64), Vector3(x, 0.95, -4.04))
	model.add_child(kit.finish())
	return model


func _build_horse_rails() -> void:
	var track: Dictionary = _map.get("HORSE_TRACK", {})
	if track.is_empty():
		return
	var half: Vector2 = track["half"]
	var width: float = track["width"]
	for offset: float in [-width * 0.5, width * 0.5]:
		var edge: Vector2 = half + Vector2.ONE * offset
		_rail_line(Vector3(-edge.x, 0, -edge.y), Vector3(edge.x, 0, -edge.y))
		_rail_line(Vector3(edge.x, 0, -edge.y), Vector3(edge.x, 0, edge.y))
		_rail_line(Vector3(edge.x, 0, edge.y), Vector3(-edge.x, 0, edge.y))
		var previous: float = -edge.y
		for gate: Dictionary in _map.get("GATES", []):
			var z: float = gate["position"].z
			var gap: float = _map.get("GATE_HALF_WIDTH", 7.0)
			_rail_line(Vector3(-edge.x, 0, previous), Vector3(-edge.x, 0, z - gap))
			previous = z + gap
		_rail_line(Vector3(-edge.x, 0, previous), Vector3(-edge.x, 0, edge.y))


func _rail_line(from: Vector3, to: Vector3) -> void:
	if from.distance_to(to) < 0.1:
		return
	var body := StaticBody3D.new()
	body.name = "HorseRail_%d" % rail_segments
	body.set_meta("impact_category", "wood")
	body.set_meta("impact_name", "a horse-track rail")
	add_child(body)
	var kit := MeshKit.new()
	var length := from.distance_to(to)
	var direction := (to - from).normalized()
	var turn := Basis.looking_at(direction)
	var centre := (from + to) * 0.5
	for fraction in [0.46, 0.86]:
		kit.box(Vector3(0.12, 0.15, length), WHITE, centre + Vector3.UP * GameConfig.HORSE_RAIL_HEIGHT * fraction, turn)
	var count := ceili(length / GameConfig.HORSE_RAIL_SPACING)
	for i in range(count + 1):
		kit.box(Vector3(0.16, GameConfig.HORSE_RAIL_HEIGHT, 0.16), WHITE,
				from.lerp(to, float(i) / count) + Vector3.UP * GameConfig.HORSE_RAIL_HEIGHT * 0.5)
	body.add_child(kit.finish())
	var collision := LowPoly.solid_box(body, Vector3(0.16, GameConfig.HORSE_RAIL_HEIGHT, length), centre + Vector3.UP * GameConfig.HORSE_RAIL_HEIGHT * 0.5)
	collision.basis = turn
	rail_segments += 1


func _build_arena() -> void:
	var area: Rect2 = _map.get("JUMPING_ARENA", Rect2())
	if area.size == Vector2.ZERO:
		return
	LowPoly.box(self, Vector3(area.size.x, 0.03, area.size.y), Color(0.83, 0.7, 0.49),
			Vector3(area.get_center().x, 0.04, area.get_center().y))
	var a := Vector3(area.position.x, 0, area.position.y)
	var b := Vector3(area.end.x, 0, area.position.y)
	var c := Vector3(area.end.x, 0, area.end.y)
	var d := Vector3(area.position.x, 0, area.end.y)
	_rail_line(a, b)
	_rail_line(b, c)
	_rail_line(d, a)
	var gate := Vector3(area.get_center().x, 0, area.end.y)
	_rail_line(c, gate + Vector3.RIGHT * 4.0)
	_rail_line(gate + Vector3.LEFT * 4.0, d)
	var course := area.grow(-12.0)
	var points: Array[Vector3] = [Vector3(course.position.x, 0, course.position.y), Vector3(course.end.x, 0, course.position.y),
			Vector3(course.end.x, 0, course.end.y), Vector3(course.position.x, 0, course.end.y)]
	var jumps: Array[Vector3] = []
	for z in [course.position.y, course.end.y]:
		var jump := Vector3(course.get_center().x, 0, z)
		_build_jump(jump)
		jumps.append(jump)
	var look := LifeLooks.horse(Color(0.56, 0.33, 0.19))
	arena_horse = ArenaHorse.new()
	arena_horse.name = "ArenaHorse"
	add_child(arena_horse)
	arena_horse.setup("horse", points, true, GameConfig.HORSE_TROT_SPEED, Vector3(0.9, 2.4, 3.0), look[0], look[1])
	arena_horse.jumps = jumps
	arena_horse.set_meta("gait_left", 999999.0) # This horse keeps trotting on its jumping course.
	_watch(arena_horse)


func _build_jump(spot: Vector3) -> void:
	var kit := MeshKit.new()
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.7, 1.5, 0.15), WHITE, spot + Vector3(0, 0.75, side * 2.3))
		kit.box(Vector3(1.3, 0.12, 0.7), WHITE, spot + Vector3(0, 0.06, side * 2.3))
	for height in [0.5, 0.95]:
		kit.box(Vector3(0.13, 0.13, 4.6), Color(0.76, 0.23, 0.22), spot + Vector3.UP * height)
	add_child(kit.finish("HorseJump"))
