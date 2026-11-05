class_name PlaceCrowds
extends Node3D
## Session 68: every place has its own kind of people (PRD table in BUILD_PLAN Session 68).
## Made by LifeBuilder. Standing or sitting people are placed here from the map data;
## people who walk a route are RouteMovers made through LifeBuilder (Plaza shoppers,
## pupils in the school yard). The pools' swimmers get swimwear and the building site
## workers hi-vis vests and hard hats (they're built by DistrictDetail and LandmarkBuilder).
## Only people near the camera are animated; further away they hold still, and past the
## life view distance they're hidden (cheap on Low graphics).

## Everyone placed here: [Person, level]. Level: lowest Graphics setting that shows them.
var people: Array = []

var _builder: Node3D
var _map: Dictionary
var _check_left := 0.5  # let everyone take their pose before the far ones hold still


func build(builder: Node3D, map: Dictionary) -> void:
	_builder = builder
	_map = map
	var world := builder.get_parent()
	_dress_existing(world)
	_pools()
	_gym()
	_school()
	_stables()
	_plaza()
	_bus_station()
	_beekeeper()
	_farm_beds()
	_clusters()
	_majlis_gardens()  # Session 66


## How many people of each outfit there are (swimmers and workers included).
func outfits() -> Dictionary:
	var count := {}
	var world := _builder.get_parent()
	for node in world.find_children("*", "Node3D", true, false):
		if node is Person and node.has_meta("outfit"):
			var kind: String = node.get_meta("outfit")
			count[kind] = count.get(kind, 0) + 1
	return count


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 0.25
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
	for entry in people:
		var person: Person = entry[0]
		var gap := person.global_position.distance_to(camera.global_position)
		apply_detail(person, gap, far, Settings.graphics >= entry[1])


## Near: shown and animated. Mid: shown, holding its pose. Far (or not on this Graphics level): hidden.
static func apply_detail(person: Node3D, gap: float, far: float, allowed := true) -> void:
	var shown := allowed and gap < far
	if person.visible != shown:
		person.visible = shown
	var animate := shown and gap < GameConfig.PEOPLE_ANIMATE_DISTANCE
	var mode := Node.PROCESS_MODE_INHERIT if animate else Node.PROCESS_MODE_DISABLED
	if person.process_mode != mode:
		person.process_mode = mode


## Stands someone at a spot (x, z), facing `facing` degrees (0 = towards +Z, like the data).
func place(person: Person, at: Vector3, facing: float, level := 0, action := "idle") -> Person:
	var holder := Node3D.new()
	holder.position = Vector3(at.x, at.y, at.z)
	holder.rotation_degrees.y = facing + 180.0  # a Person faces -Z
	add_child(holder)
	holder.add_child(person)
	person.play(action)
	people.append([person, level])
	return person


## Sits someone on a bench (Props.bench at `at`, facing `facing`).
func sit_on_bench(person: Person, at: Vector3, facing: float, level := 0) -> Person:
	place(person, at, facing, level, "sit")
	person.position = Vector3(0, 0.5 - person.spot("Hips").y + 0.05, 0.08)
	return person


func _dress_existing(world: Node) -> void:
	var sites: Array = _map.get("BUILDING_SITES", [])
	var swimmer := 0
	var worker := 0
	for root_name in ["DistrictDetail", "LandmarkBuilder"]:
		var root := world.get_node_or_null(root_name)
		if root == null:
			continue
		for node in root.find_children("*", "Node3D", true, false):
			if not node is Person or node.has_meta("outfit"):
				continue
			if node.get_parent() != null and str(node.get_parent().name).contains("Pool"):  # the swimmers
				PlaceLooks.dress_swimmer(node, swimmer)
				swimmer += 1
				continue
			var at := Vector2(node.global_position.x, node.global_position.z)
			for area: Rect2 in sites:
				if area.grow(2.0).has_point(at):
					PlaceLooks.dress_worker(node, worker)
					worker += 1
					break


## A lifeguard (red and yellow) beside each pool.
func _pools() -> void:
	if _map.has("COMMUNITY_POOL"):
		var pool: Rect2 = _map["COMMUNITY_POOL"]
		place(PlaceLooks.lifeguard(), Vector3(pool.end.x + 2.0, 0.08, pool.get_center().y), -90.0)
	if _map.has("LAP_POOL"):  # the gym's lap pool
		var lap: Rect2 = _map["LAP_POOL"]
		place(PlaceLooks.lifeguard(), Vector3(lap.end.x + 2.0, 0.08, lap.get_center().y), -90.0)
	if _map.has("SCHOOL"):  # between the two school pools (scripts/district_detail.gd)
		place(PlaceLooks.lifeguard(), Vector3(-328.5, 0.08, 111.5), 180.0, 1)


func _gym() -> void:
	if not _map.has("GYM"):
		return
	var gym: Vector3 = _map["GYM"]["position"]
	var front: float = gym.z - _map["GYM"]["size"].z * 0.5 - 2.5
	place(PlaceLooks.gym_goer(0), Vector3(gym.x - 6.0, 0, front), 90.0)
	place(PlaceLooks.gym_goer(1), Vector3(gym.x - 4.8, 0, front), -90.0, 1)


## Pupils in uniform running about the yard, and teachers with lanyards watching.
func _school() -> void:
	if not _map.has("SCHOOL"):
		return
	place(PlaceLooks.teacher(), Vector3(-350.0, 0, 58.0), -90.0)
	place(PlaceLooks.teacher(), Vector3(-380.0, 0, 66.0), 90.0, 1)
	for i in 4:
		var pupil := PlaceLooks.pupil()
		var z := 53.0 + i * 2.0
		var route := {"points": [Vector3(-368.0, 0, z), Vector3(-354.0, 0, z)], "level": i % 3, "extra": true}
		_builder._add("Pupil_%d" % i, "person", route, GameConfig.PLAY_KID_SPEED, Vector3(0.45, 1.3, 0.45),
				_builder._holder(pupil), pupil)


func _stables() -> void:
	if not _map.has("STABLES"):
		return
	place(PlaceLooks.groom(), Vector3(-262.0, 0, 186.0), 0.0)
	place(PlaceLooks.rider(), Vector3(-205.0, 0, 186.0), -90.0)
	place(PlaceLooks.groom(), Vector3(-203.8, 0, 186.0), 90.0, 1)


## Waiters outside the restaurants, shoppers with bags walking round, a family.
func _plaza() -> void:
	if not _map.has("PLAZA"):
		return
	var restaurants: Array = _map.get("RESTAURANTS", [])
	var waiter := 0
	for shop in restaurants:
		if not shop.get("interior", false) or waiter >= 4:
			continue
		var at: Vector3 = shop["position"]
		var facing: float = shop["facing"]
		var out := Vector3(sin(deg_to_rad(facing)), 0, cos(deg_to_rad(facing)))
		place(PlaceLooks.waiter(waiter), at + out * 11.5 + Vector3(3.0, 0.02, 0), facing, waiter % 2)
		waiter += 1
	var centre: Vector2 = _map["PLAZA"]["centre"]
	var ring: Array[Vector3] = []
	for k in 16:
		var a := TAU * k / 16.0
		ring.append(Vector3(centre.x + cos(a) * 32.0, 0.02, centre.y + sin(a) * 32.0))
	for i in 3:
		var shopper := PlaceLooks.shopper(i)
		var route := {"points": ring, "loop": true, "level": i, "extra": true}
		var mover: RouteMover = _builder._add("Shopper_%d" % i, "person", route, GameConfig.WALKER_SPEED,
				Vector3(0.5, 1.8, 0.5), _builder._holder(shopper), shopper)
		mover.start_at(i * 5, 0.3, i % 2 == 0)
	# A family: a parent and a child by the steps.
	place(PlaceLooks.shopper(3), Vector3(centre.x - 25.0, 0.02, centre.y + 2.0), 90.0)
	var child := LifeLooks.kid()
	child.set_meta("outfit", "family")
	place(child, Vector3(centre.x - 25.0, 0.02, centre.y + 3.0), 90.0)


func _bus_station() -> void:
	# Session 64: the people waiting for the bus (and getting on) are BusStop's. Here: one
	# traveller with a suitcase reading the route map in the first shelter, who stays.
	var platform: Dictionary = _map.get("BUS_PLATFORM", {})
	if platform.is_empty():
		return
	var shelter: Vector3 = platform["shelters"][0]
	place(PlaceLooks.commuter(1), shelter + Vector3(0.1, BusStop.PLATFORM_TOP, 2.9), 90.0)


func _beekeeper() -> void:
	if not _map.has("BEEHIVES"):
		return
	var hives: Rect2 = _map["BEEHIVES"]
	place(PlaceLooks.beekeeper(), Vector3(hives.get_center().x - 4.0, 0, hives.position.y - 1.5), 0.0)


## A gardener in a sun hat at each farm bed in the spine (watering it).
func _farm_beds() -> void:
	var beds: Array = _map.get("FARM_BEDS", [])
	for i in beds.size():
		var bed: Rect2 = beds[i]
		var look := LifeLooks.gardener(1.0)
		var spot := {"position": Vector3(bed.get_center().x, 0, bed.position.y - 1.5), "level": i % 2, "extra": true}
		var mover: RouteMover = _builder._add("FarmGardener_%d" % i, "gardener", spot, 0.0,
				Vector3(0.5, 1.8, 0.5), look[0], look[1])
		mover.rotation_degrees.y = 180.0  # facing the bed (+Z)


## Neighbours chatting on each cluster's little plaza, and a parent on the bench by the playground.
func _clusters() -> void:
	var plazas: Array = _map.get("MINI_PLAZAS", [])
	for i in plazas.size():
		var mini: Dictionary = plazas[i]
		var tower: Vector3 = mini["tower"]
		var chat := Vector3(tower.x + 32.0, 0, tower.z)
		place(PlaceLooks.neighbour(i * 2), chat, 90.0, 0)
		place(PlaceLooks.neighbour(i * 2 + 1), chat + Vector3(1.2, 0, 0), -90.0, 1)
		for bench in mini.get("benches", []):
			var parent := PlaceLooks.neighbour(i + 2)
			parent.set_meta("outfit", "parent on bench")
			sit_on_bench(parent, bench["position"], bench["facing"], i % 2)


## Session 66: Majlis Gardens: neighbours on the benches and in the majlis, two people out
## for a walk on the paths, a child by the fountain and a gardener at the garden bed.
func _majlis_gardens() -> void:
	var park: Dictionary = _map.get("MAJLIS_GARDENS", {})
	if park.is_empty():
		return
	var benches: Array = park["benches"]
	for i in [0, 1, 3]:
		var sitter := PlaceLooks.neighbour(i + 5)
		sitter.set_meta("outfit", "parent on bench" if i == 1 else "casual")
		sit_on_bench(sitter, benches[i]["position"], benches[i]["facing"], i % 2)
	var majlis: Vector3 = park["majlis"]
	for k in 2:  # sitting on the low sofas (seat 0.4 m), chatting over coffee
		var guest := sit_on_bench(PlaceLooks.neighbour(k + 8), majlis + Vector3(-2.2, 0, -0.6 + k * 1.4), 90.0, k)
		guest.position.y -= 0.1
	var fountain: Vector3 = park["fountain"]
	var child := LifeLooks.kid()
	child.set_meta("outfit", "family")
	place(child, fountain + Vector3(0, 0.05, 3.4), 180.0)
	place(PlaceLooks.neighbour(11), fountain + Vector3(1.2, 0.05, 4.2), 200.0, 1)
	var walk: Array = park["walk"]
	for i in 2:
		var walker := PlaceLooks.neighbour(12 + i)
		var route := {"points": walk, "loop": true, "level": i, "extra": true}
		var mover: RouteMover = _builder._add("MajlisWalker_%d" % i, "person", route, GameConfig.WALKER_SPEED,
				Vector3(0.5, 1.8, 0.5), _builder._holder(walker), walker)
		mover.start_at(i * 6, 0.2, i == 0)
	var bed: Rect2 = park["bed"]
	var look := LifeLooks.gardener(1.0)
	var spot := {"position": Vector3(bed.end.x + 1.0, 0, bed.get_center().y), "level": 0, "extra": true}
	var gardener: RouteMover = _builder._add("MajlisGardener", "gardener", spot, 0.0, Vector3(0.5, 1.8, 0.5), look[0], look[1])
	gardener.rotation_degrees.y = 90.0  # facing the bed (-X)
