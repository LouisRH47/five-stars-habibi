class_name BusStop
extends Node3D
## Session 64: the bus station platform island inside the bus loop (data: BUS_PLATFORM).
## Two detailed shelters face the bay lane: a roof on posts, a glass back panel with a
## route map, two benches, a bin and a small bilingual sign. 3 to 5 people wait in front.
## When a bus stops at the bay they walk to its door one after another and get on (they
## disappear into the bus); the bus waits until the last one is in. New people arrive over
## time (GameConfig BUS_STOP_*). Made by DistrictDetail.

const PAVERS := Color(0.84, 0.8, 0.72)
const KERB := Color(0.72, 0.7, 0.66)
const ROOF := Color(0.16, 0.56, 0.61)
const METAL := Color(0.62, 0.65, 0.68)
const WHITE := Color(0.97, 0.97, 0.94)
const MAP_LINES := [Color(0.85, 0.2, 0.2), Color(0.2, 0.55, 0.3), Color(0.95, 0.65, 0.1)]
const PLATFORM_TOP := 0.15  # higher than the road kerbs (0.13), so they never share a height

## How many shelters were built and how many people got on a bus so far (for the tests).
var shelters := 0
var boarded := 0
## The people standing at the stop: each {person, spot (index), state, target, delay}.
## state: "arriving" (walking to a spot), "waiting", "boarding" (walking to the door).
var waiting: Array = []

var _spec: Dictionary = {}
var _bay := Vector3.ZERO
var _spawn_left := 0.0
var _made := 0
var _check_left := 0.0
static var _glass: StandardMaterial3D = null


## Builds the platform and its shelters under parent. map: the data constants.
static func build(parent: Node3D, map: Dictionary) -> BusStop:
	var stop := BusStop.new()
	stop.name = "BusStop"
	stop._spec = map.get("BUS_PLATFORM", {})
	stop._bay = map.get("BUS_LOOP", {}).get("bay", Vector3.ZERO)
	parent.add_child(stop)
	if stop._spec.is_empty():
		return stop
	stop._platform()
	var station: Dictionary = map.get("BUS_STATION", {})
	var signs := [[station.get("arabic", "محطة حافلات الواحة"), station.get("name", "Wahat Bus Station")],
			["قريباً: السفر إلى مناطق أخرى", "Coming soon: travel to other districts"]]
	for i in stop._spec["shelters"].size():
		stop._shelter(stop._spec["shelters"][i], signs[i % signs.size()], i)
	for i in GameConfig.BUS_STOP_START_PEOPLE:
		stop._add_person(i, false)
	stop._spawn_left = GameConfig.BUS_STOP_SPAWN_EVERY
	return stop


## The raised paved island with a kerb round it (solid: it's a step up from the road).
func _platform() -> void:
	var area: Rect2 = _spec["area"]
	var body := StaticBody3D.new()
	body.name = "BusPlatform"
	body.position = Vector3(area.get_center().x, 0, area.get_center().y)
	add_child(body)
	var kit := MeshKit.new()
	kit.box(Vector3(area.size.x, PLATFORM_TOP, area.size.y), PAVERS, Vector3(0, PLATFORM_TOP * 0.5, 0))
	# The darker kerb stones along the edge and a yellow line where you wait for the bus.
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.3, 0.02, area.size.y), KERB, Vector3(side * (area.size.x * 0.5 - 0.15), PLATFORM_TOP + 0.01, 0))
		kit.box(Vector3(area.size.x - 0.6, 0.02, 0.3), KERB, Vector3(0, PLATFORM_TOP + 0.01, side * (area.size.y * 0.5 - 0.15)))
	kit.box(Vector3(0.12, 0.02, area.size.y - 2.0), Color(0.95, 0.8, 0.15), Vector3(-area.size.x * 0.5 + 0.55, PLATFORM_TOP + 0.012, 0))
	# Paving joints, so it reads as pavers from close up.
	for k in range(1, int(area.size.y / 2.0)):
		kit.box(Vector3(area.size.x - 0.8, 0.004, 0.04), PAVERS.darkened(0.12), Vector3(0, PLATFORM_TOP + 0.002, -area.size.y * 0.5 + k * 2.0))
	body.add_child(kit.finish("Pavers"))
	LowPoly.solid_box(body, Vector3(area.size.x, PLATFORM_TOP, area.size.y), Vector3(0, PLATFORM_TOP * 0.5, 0))


## One shelter. at: the middle of its floor; its front faces BUS_PLATFORM facing.
func _shelter(at: Vector3, words: Array, index: int) -> void:
	var body := StaticBody3D.new()
	body.name = "BusShelter_%d" % index
	body.position = at + Vector3.UP * PLATFORM_TOP
	body.rotation_degrees.y = _spec["facing"]
	add_child(body)
	var kit := MeshKit.new()
	var length := 9.0
	var height := 2.8
	# Posts: four along the back, two at the front corners, each with a foot plate.
	for x in [-4.3, -1.45, 1.45, 4.3]:
		kit.box(Vector3(0.12, height, 0.12), METAL, Vector3(x, height * 0.5, -1.15))
		LowPoly.solid_box(body, Vector3(0.14, height, 0.14), Vector3(x, height * 0.5, -1.15))
	for x in [-4.3, 4.3]:
		kit.box(Vector3(0.1, height + 0.12, 0.1), METAL, Vector3(x, (height + 0.12) * 0.5, 1.2))
		LowPoly.solid_box(body, Vector3(0.12, height, 0.12), Vector3(x, height * 0.5, 1.2))
	# The roof: tilted slightly back, with a white trim and a teal sign band at the front.
	kit.box(Vector3(length + 0.4, 0.12, 3.2), ROOF, Vector3(0, height + 0.1, 0.05), Basis(Vector3.RIGHT, -0.05))
	kit.box(Vector3(length + 0.5, 0.1, 0.1), WHITE, Vector3(0, height + 0.02, 1.62))
	kit.box(Vector3(length + 0.5, 0.1, 0.1), WHITE, Vector3(0, height + 0.18, -1.55))
	kit.box(Vector3(length - 1.0, 0.45, 0.08), ROOF.darkened(0.25), Vector3(0, height - 0.18, 1.62))
	# Side panel and back rails holding the glass.
	kit.box(Vector3(length - 0.2, 0.08, 0.08), METAL, Vector3(0, 0.25, -1.15))
	kit.box(Vector3(length - 0.2, 0.08, 0.08), METAL, Vector3(0, 2.4, -1.15))
	# The route map in the glass: a white board with three coloured lines and stops.
	var map_at := Vector3(2.9, 1.45, -1.08)
	kit.box(Vector3(1.6, 1.15, 0.05), WHITE, map_at)
	kit.box(Vector3(1.7, 1.25, 0.03), METAL, map_at + Vector3(0, 0, -0.02))
	for k in MAP_LINES.size():
		var y := 0.25 - k * 0.22
		kit.box(Vector3(1.25, 0.035, 0.02), MAP_LINES[k], map_at + Vector3(0, y, 0.035))
		for s in 5:
			kit.box(Vector3(0.07, 0.07, 0.02), WHITE.darkened(0.5), map_at + Vector3(-0.55 + s * 0.27, y, 0.045))
	kit.box(Vector3(0.12, 0.12, 0.02), Color(0.9, 0.1, 0.1), map_at + Vector3(-0.55, -0.42, 0.04))  # "you are here"
	# Two benches and a bin.
	for x in [-2.2, 0.6]:
		Props.bench(body, Vector3(x, 0, -0.5), 0.0)
	kit.cylinder(0.24, 0.21, 0.75, Color(0.2, 0.42, 0.3), Vector3(-4.0, 0.375, 0.6), Basis(), 10)
	kit.cylinder(0.26, 0.26, 0.05, METAL, Vector3(-4.0, 0.77, 0.6), Basis(), 10)
	LowPoly.solid_cylinder(body, 0.25, 0.8, Vector3(-4.0, 0.4, 0.6))
	var look := kit.finish("Shelter")
	body.add_child(look)
	var glass := MeshInstance3D.new()
	glass.name = "GlassBack"
	var pane := BoxMesh.new()
	pane.size = Vector3(length - 0.4, 2.1, 0.04)
	pane.material = glass_material()
	glass.mesh = pane
	glass.position = Vector3(0, 1.35, -1.15)
	body.add_child(glass)
	LowPoly.solid_box(body, Vector3(length - 0.4, 2.1, 0.08), Vector3(0, 1.35, -1.15))
	var map_title := SignText.make_face("خريطة الخطوط", "Route map", 20, Color(0.1, 0.15, 0.2))
	map_title.name = "RouteMap"
	map_title.position = map_at + Vector3(0, 0.44, 0.04)
	body.add_child(map_title)
	# The small sign on the front band of the roof.
	var size := SignText.fit_size(words[0], words[1], 34, length - 1.4)
	var face := SignText.make_face(words[0], words[1], size, Color.WHITE)
	face.name = "ShelterSign"
	face.position = Vector3(0, height - 0.18, 1.67)
	face.scale = Vector3.ONE * 0.55
	body.add_child(face)
	shelters += 1


static func glass_material() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = Color(0.62, 0.8, 0.88, 0.32)
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.roughness = 0.1
		_glass.metallic = 0.2
	return _glass


## Someone new at the stop. walk_in: they arrive from the pavement end of the island.
func _add_person(look: int, walk_in: bool) -> void:
	var spot := _free_spot()
	if spot < 0:
		return
	var person := PlaceLooks.commuter(_made + look)
	person.name = "WaitingCommuter_%d" % _made
	_made += 1
	var target: Vector3 = _spec["waiting"][spot] + Vector3.UP * PLATFORM_TOP
	person.position = (_spec["arrive"] + Vector3.UP * PLATFORM_TOP) if walk_in else target
	add_child(person)
	var entry := {"person": person, "spot": spot, "state": "arriving" if walk_in else "waiting",
			"target": target, "delay": 0.0}
	waiting.append(entry)
	if walk_in:
		person.play("walk")
	else:
		_stand(entry)


func _free_spot() -> int:
	var spots: Array = _spec.get("waiting", [])
	for i in spots.size():
		if not waiting.any(func(e): return e["spot"] == i):
			return i
	return -1


## Faces the bay lane (where the bus comes) and stands still.
func _stand(entry: Dictionary) -> void:
	var person: Person = entry["person"]
	person.rotation_degrees.y = _spec["facing"] + 180.0  # a Person faces -Z
	person.play("idle")


func _process(delta: float) -> void:
	tick(delta, _bus_at_bay())


## One step of the stop. bus: the bus standing at the bay right now (or null).
func tick(delta: float, bus: Node3D) -> void:
	if _spec.is_empty():
		return
	if bus != null:
		var order := 0
		for entry in waiting:
			if entry["state"] == "waiting":
				entry["state"] = "boarding"
				entry["target"] = _spec["door"] + Vector3.UP * PLATFORM_TOP
				entry["delay"] = order * GameConfig.BUS_STOP_BOARD_GAP
				order += 1
	var still_boarding := false
	for entry in waiting.duplicate():
		if entry["state"] == "waiting":
			continue
		if entry["delay"] > 0.0:
			entry["delay"] -= delta
			still_boarding = true
			continue
		var person: Person = entry["person"]
		var to: Vector3 = entry["target"] - person.position
		to.y = 0.0
		var step := GameConfig.BUS_STOP_WALK_SPEED * delta
		if to.length() > step:
			person.play("walk")
			person.position += to.normalized() * step
			person.rotation.y = atan2(-to.x, -to.z)
			still_boarding = still_boarding or entry["state"] == "boarding"
			continue
		person.position = entry["target"]
		if entry["state"] == "arriving":
			entry["state"] = "waiting"
			_stand(entry)
		else:  # in at the door: they've got on the bus
			waiting.erase(entry)
			person.queue_free()
			boarded += 1
	# Hold the bus at the bay until the last person is on.
	if bus != null and still_boarding and "_wait_left" in bus:
		bus.set("_wait_left", maxf(float(bus.get("_wait_left")), 0.5))
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = GameConfig.BUS_STOP_SPAWN_EVERY
		if waiting.size() < GameConfig.BUS_STOP_MAX_PEOPLE:
			_add_person(_made, true)
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.3
		_level_of_detail()


## A bus standing still at the bay, or null.
func _bus_at_bay() -> Node3D:
	if _bay == Vector3.ZERO:
		return null
	for vehicle in get_tree().get_nodes_in_group("traffic_vehicle"):
		if vehicle.get("kind") == "bus" and float(vehicle.get("_wait_left")) > 0.0 \
				and Vector2(vehicle.position.x - _bay.x, vehicle.position.z - _bay.z).length() < 1.5:
			return vehicle
	return null


## Near people are animated, further ones hold still, far ones are hidden (like PlaceCrowds).
func _level_of_detail() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
	for entry in waiting:
		var person: Person = entry["person"]
		PlaceCrowds.apply_detail(person, person.global_position.distance_to(camera.global_position), far)
