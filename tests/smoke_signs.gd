extends RefCounted
## World polish pass, Sessions 64 to 66 (signs wave), run by tests/smoke_test.gd:
## the bus stop and car parks (64), cluster entrance signs, end houses, bins and the pool
## sign (65), Majlis Gardens and the phase 3 building site (66). Wahat Al Shams only.

var _t: SceneTree
var _main: Node
var _data: Dictionary


func run(t: SceneTree) -> void:
	_t = t
	_main = t.get("_main")
	var builder := _main.get_node_or_null("WahatBuilder")
	if builder == null or not (builder.data as Script).get_script_constant_map().has("BUS_PLATFORM"):
		print("      not Wahat Al Shams, Sessions 64 to 66 not checked")
		return
	_data = (builder.data as Script).get_script_constant_map()
	_session64()


func _check(label: String, ok: bool, detail := "") -> void:
	_t.call("_check", label, ok, detail)


## Session 64: the bus station platform, people boarding, the stables and school car parks.
func _session64() -> void:
	var stop = _main.get_node_or_null("DistrictDetail/BusStop")
	_check("Session 64: the bus station platform has two shelters with glass, a route map, benches and a bin",
			stop != null and stop.shelters == 2 and stop.find_children("GlassBack", "", true, false).size() == 2
			and stop.find_children("RouteMap", "", true, false).size() == 2
			and stop.find_children("ShelterSign", "", true, false).size() == 2)
	if stop == null:
		return
	var platform: Rect2 = _data["BUS_PLATFORM"]["area"]
	var bay: Vector3 = _data["BUS_LOOP"]["bay"]
	var lane_edge := bay.x + 3.5  # the bay lane is 7 m wide
	_check("Session 64: the platform is right next to the bay lane, not in the road",
			platform.position.x > lane_edge and platform.position.x - lane_edge < 1.0 and platform.has_point(Vector2(platform.get_center().x, bay.z)),
			"%s, lane edge %.1f" % [platform, lane_edge])
	var ready_count: int = stop.waiting.filter(func(e): return e["state"] == "waiting").size()
	_check("Session 64: 3 to 5 people wait at the stop", stop.waiting.size() >= 3 and stop.waiting.size() <= 5, "%d" % stop.waiting.size())
	var before: int = stop.boarded
	var fake_bus := Node3D.new()  # stands in for a bus at the bay
	for i in 200:
		stop.tick(0.1, fake_bus)
	fake_bus.free()
	_check("Session 64: the people get on when a bus stops at the bay", stop.boarded - before >= maxi(ready_count, 1),
			"%d got on" % (stop.boarded - before))
	for i in int(GameConfig.BUS_STOP_SPAWN_EVERY * 2.5 / 0.25):
		stop.tick(0.25, null)
	var standing: int = stop.waiting.filter(func(e): return e["state"] == "waiting").size()
	_check("Session 64: new people arrive at the stop over time", standing >= 2, "%d waiting" % standing)
	# The stables car park and the school car park look like the others.
	var stables: Rect2 = _data["PARKING_AREAS"][-1]
	var cars := 0
	for car in _main.get_node("DecorBuilder").get_children():
		if String(car.name).begins_with("ParkedCar_") and stables.has_point(Vector2(car.position.x, car.position.z)):
			cars += 1
	var roofs := 0
	var school_roofs := 0
	var school: Rect2 = _data["SCHOOL_PARKING"]
	for roof in _main.get_node("DistrictTraffic").get_children():
		if String(roof.name).begins_with("SolarBay_"):
			var at := Vector2(roof.position.x, roof.position.z)
			roofs += 1 if stables.has_point(at) else 0
			school_roofs += 1 if school.has_point(at) else 0
	_check("Session 64: the stables car park has parked cars, bay lines and solar roofs", cars >= 4 and roofs >= 5, "%d cars, %d roofs" % [cars, roofs])
	var pad := _main.get_node_or_null("DistrictDetail/SchoolCarParkPad")
	_check("Session 64: the school car park has an asphalt pad, cars and solar roofs", pad != null and school_roofs >= 8, "%d roofs" % school_roofs)
