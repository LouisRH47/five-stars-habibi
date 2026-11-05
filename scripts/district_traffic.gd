class_name DistrictTraffic
extends Node3D
## Sessions 37–38: fixed car/bus routes, solar bays and separated riding tracks.
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
var _ring_cache: Array[Vector3] = []
var _bus_entry := Vector3.ZERO
var _bus_bay := Vector3.ZERO
var _bus_loop: Array[Vector3] = []  # the loop through the bus station, entry to exit
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


## Session 61: the driving line round the ring road, following its rounded corners.
## It is the ring road's middle line moved 2.2 m inwards (drive on the right), except on
## the north side, where the lane stays in the middle to clear the restaurants' back walls.
## Clockwise from the middle of the north side.
func _ring_points() -> Array[Vector3]:
	if not _ring_cache.is_empty():
		return _ring_cache
	var centre: Array[Vector2] = []
	for road: Dictionary in _map.get("ROADS", []):
		if road.get("name", "") == "Ring Road":
			if centre.is_empty() or centre.back().distance_to(road["from"]) > 0.05:
				centre.append(road["from"])
			centre.append(road["to"])
	if centre.size() > 1 and centre[0].distance_to(centre.back()) < 0.05:
		centre.pop_back()
	var north := _ring.position.y
	var n := centre.size()
	for k in n:
		var d: Vector2 = (centre[(k + 1) % n] - centre[(k - 1 + n) % n]).normalized()
		var inward := Vector2(-d.y, d.x)  # the right-hand side of a clockwise loop
		var inset := 2.2 * clampf((centre[k].y - north) / 12.0, 0.0, 1.0)
		var p := centre[k] + inward * inset
		_ring_cache.append(Vector3(p.x, 0, p.y))
	return _ring_cache


## The ring's points driving clockwise after `from` up to and including the last point
## before `to` (all the way round if `to` is just behind `from`).
func _ring_between(from: Vector3, to: Vector3) -> Array[Vector3]:
	var ring := _ring_points()
	var n := ring.size()
	var a := _ring_spot(from)
	var b := _ring_spot(to)
	var count: int = posmod(int(b.x) - int(a.x), n)
	if count == 0 and b.y <= a.y:
		count = n
	var out: Array[Vector3] = []
	for k in count:
		out.append(ring[(int(a.x) + 1 + k) % n])
	return out


## [segment index, how far along it] of the ring point nearest to a spot.
func _ring_spot(spot: Vector3) -> Vector2:
	var ring := _ring_points()
	var best := Vector2.ZERO
	var best_d := INF
	for k in ring.size():
		var a := Vector2(ring[k].x, ring[k].z)
		var b := Vector2(ring[(k + 1) % ring.size()].x, ring[(k + 1) % ring.size()].z)
		var q := Geometry2D.get_closest_point_to_segment(Vector2(spot.x, spot.z), a, b)
		var d := q.distance_squared_to(Vector2(spot.x, spot.z))
		if d < best_d:
			best_d = d
			best = Vector2(k, a.distance_to(q))
	return best


func _build_cars() -> void:
	var ring := _ring_points()
	for i in range(4):
		var car := _make_car(ring, i)
		car.start_at(i * ring.size() / 4)
	for i in _map.get("PARKING_AREAS", []).size():
		var area: Rect2 = _map["PARKING_AREAS"][i]
		var north := area.get_center().y < 0.0
		var x := RoadMesh.parking_access_x(area)  # RoadMesh lays this access road
		var edge_z := _ring.position.y if north else _ring.end.y
		var entry := Vector3(x, 0, edge_z)
		var aisle := Vector3(x, 0, area.end.y - 9.0)
		var park := Vector3(area.position.x + 4.0, 0, aisle.z)
		var route: Array[Vector3] = [park, aisle, entry]
		route.append_array(_ring_between(entry, entry))
		route.append(entry)
		route.append(aisle)
		route.append(park)
		var car := _make_car(route, i + 4)
		car.stop_index = route.size() - 1
		car.dwell_time = GameConfig.TRAFFIC_PARK_WAIT
		car._wait_left = GameConfig.TRAFFIC_PARK_WAIT + i
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


func _build_solar_bays() -> void:
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
	# Session 60: the bus station is a loop off the north ring road. Buses turn in at the
	# entry, stop at the bay beside the platform, go round and turn back out at the exit.
	var loop: Dictionary = _map.get("BUS_LOOP", {})
	if loop.is_empty():
		return
	_bus_loop.clear()
	for point: Vector3 in loop["points"]:
		_bus_loop.append(Vector3(point.x, 0, point.z))
	var entry: Vector2 = loop["entry"]
	_bus_entry = Vector3(entry.x, 0, _ring.position.y)
	_bus_loop[0] = _bus_entry
	_bus_loop[_bus_loop.size() - 1] = Vector3(_bus_loop[-1].x, 0, _ring.position.y)
	_bus_bay = loop["bay"]
	_next_arrival = GameConfig.BUS_INTERVAL_GAME_MINUTES
	_spawn_bus(true)


func _spawn_bus(already_at_bay: bool) -> TrafficVehicle:
	var bus := TrafficVehicle.new()
	bus.name = "CommunityBus_%d" % bus_arrivals
	add_child(bus)
	# In at the entry, the bay (index 1), round the loop, out at the exit, then once round the ring.
	var route: Array[Vector3] = [_bus_entry, _bus_bay]
	route.append_array(_bus_loop.slice(2))
	route.append_array(_ring_between(route.back(), _bus_entry))
	route.append(_bus_entry)
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
	var radius: float = track.get("radius", 0.0)
	var gap: float = _map.get("GATE_HALF_WIDTH", 7.0)
	# Session 63: the rails follow the track's rounded corners. Cut the loop into short
	# pieces, leave out the ones at the gate roads, then join straight pieces back up.
	for offset: float in [-width * 0.5, width * 0.5]:
		var loop := EdgeBuilder.rounded_rect(half + Vector2.ONE * offset, radius + offset if radius > 0.0 else 0.0)
		var pieces: Array[Vector2] = []
		for k in loop.size():
			var a: Vector2 = loop[k]
			var b: Vector2 = loop[(k + 1) % loop.size()]
			var bits := maxi(1, ceili(a.distance_to(b) / 1.0))
			for s in bits:
				pieces.append(a.lerp(b, float(s) / bits))
		var runs: Array = []
		var run: Array[Vector3] = []
		var start := 0
		# Start just after a gate gap so no run wraps round the loop's first point.
		for k in pieces.size():
			if _in_gate_gap(pieces[k], gap) and not _in_gate_gap(pieces[(k + 1) % pieces.size()], gap):
				start = k + 1
				break
		for j in pieces.size() + 1:
			var p: Vector2 = pieces[(start + j) % pieces.size()]
			if _in_gate_gap(p, gap):
				if run.size() > 1:
					runs.append(run)
				run = []
			else:
				run.append(Vector3(p.x, 0, p.y))
		if run.size() > 1:
			runs.append(run)
		for line: Array[Vector3] in runs:
			var corners: Array[Vector3] = [line[0]]
			for k in range(1, line.size() - 1):
				var d1: Vector3 = (line[k] - corners.back()).normalized()
				var d2: Vector3 = (line[k + 1] - line[k]).normalized()
				if d1.dot(d2) < 0.99995:
					corners.append(line[k])
			corners.append(line.back())
			for k in corners.size() - 1:
				_rail_line(corners[k], corners[k + 1])


func _in_gate_gap(p: Vector2, gap: float) -> bool:
	if p.x > 0.0:
		return false
	for gate: Dictionary in _map.get("GATES", []):
		if absf(p.y - gate["position"].z) < gap:
			return true
	return false


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
