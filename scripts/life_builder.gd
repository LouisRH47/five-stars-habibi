extends Node3D
## Life on the map (Session 30). Builds everything that moves around Wahat Al Shams by
## itself, from the lists in data/wahat_al_shams.gd: golf buggies (BUGGIES), horses with
## riders (HORSE_RIDERS), joggers and walkers (PEOPLE_ROUTES), gardeners (GARDENERS), kids at
## the playgrounds (PLAY_KIDS) and ducks on the stream (DUCKS). Each one is a RouteMover
## (scripts/route_mover.gd) that follows its own route. Node names: Buggy_<n>, Horse_<n>,
## Person_<n>, Gardener_<n>, Kid_<n>, Duck_<n>.
## The birds, swaying palms, moving water and donkeys are in scripts/ambient_motion.gd.
## Graphics setting: every thing has a "level" in the data. Low shows only level 0, Medium
## levels 0 and 1, High everything. Far-away people are hidden and stop animating (faster).

## The map data to build from (set in the scene): data/wahat_al_shams.gd.
@export var data: Script

const MOVER := preload("res://scripts/route_mover.gd")

## Every RouteMover that was built from the data lists (shown or not).
var movers: Array[RouteMover] = []
## Session 68: RouteMovers made for PlaceCrowds (Plaza shoppers, pupils, farm gardeners).
var extra_movers: Array[RouteMover] = []
## The lowest Graphics level that shows each thing: {node: level}.
var levels := {}
var ambient: AmbientMotion
## Session 68: the people dressed for each place (scripts/place_crowds.gd).
var crowds: PlaceCrowds

var _map := {}
var _check_left := 0.0


func _ready() -> void:
	add_to_group("graphics")  # Settings.apply() calls apply_graphics() on this group
	if data == null:
		push_error("LifeBuilder has no data list set in the scene")
		return
	_map = data.get_script_constant_map()
	var list: Array = _map.get("BUGGIES", [])
	for i in list.size():
		var look := LifeLooks.buggy(list[i]["colour"])
		_add("Buggy_%d" % i, "buggy", list[i], GameConfig.BUGGY_SPEED, Vector3(1.3, 1.9, 2.4), look[0], look[1])
	list = _map.get("HORSE_RIDERS", [])
	for i in list.size():
		var look := LifeLooks.horse(list[i]["colour"])
		var horse := _add("Horse_%d" % i, "horse", list[i], GameConfig.HORSE_WALK_SPEED, Vector3(0.9, 2.4, 3.0), look[0], look[1])
		_set_animal_name(horse, list[i])
	list = _map.get("PEOPLE_ROUTES", [])
	for i in list.size():
		# Session 68: joggers in sports kit, then dog walkers and parents with buggies.
		var walker: Person
		var holder: Node3D
		var body := Vector3(0.5, 1.8, 0.5)
		if list[i]["jog"]:
			walker = PlaceLooks.jogger(i)
			holder = _holder(walker)
		elif i % 2 == 1:
			walker = PlaceLooks.neighbour(list[i]["look"])
			walker.set_meta("outfit", "dog walker")
			holder = LifeLooks.with_dog(walker)
		else:
			walker = PlaceLooks.neighbour(list[i]["look"] + 1)
			walker.set_meta("outfit", "buggy")
			holder = LifeLooks.with_buggy(walker)
			body = Vector3(0.7, 1.8, 1.6)
		var pace := GameConfig.JOGGER_SPEED if list[i]["jog"] else GameConfig.WALKER_SPEED
		_add("Person_%d" % i, "person", list[i], pace, body, holder, walker)
	_build_gardeners()
	_build_kids()
	_build_ducks()
	crowds = PlaceCrowds.new()
	crowds.name = "PlaceCrowds"
	add_child(crowds)
	crowds.build(self, _map)
	ambient = AmbientMotion.new()
	ambient.name = "AmbientMotion"
	add_child(ambient)
	ambient.build(self, _map)
	Settings.load_once()
	apply_graphics()


## Shows only the things for the current Graphics setting (0 Low, 1 Medium, 2 High).
## Hidden things also stop moving and are taken out of the physics world.
func apply_graphics() -> void:
	for node: Node3D in levels:
		var on: bool = Settings.graphics >= levels[node]
		node.visible = on
		node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	_check_left = 0.0


## How many things are shown right now (the smoke test compares Low and High).
func shown_count() -> int:
	return levels.keys().filter(func(node: Node3D) -> bool: return node.visible).size()


## Remembers which Graphics level shows `node` (AmbientMotion uses this too).
func register(node: Node3D, level: int) -> void:
	levels[node] = level


func _process(delta: float) -> void:
	# A few times a second: hide people far from the camera, show them again when near.
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = 0.25
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
	for mover in movers + extra_movers:
		if mover.process_mode != Node.PROCESS_MODE_DISABLED:
			var gap := mover.global_position.distance_to(camera.global_position)
			mover.set_near(gap < far)
			# Session 68: only people near the camera are fully animated; the rest keep
			# moving along their route but hold their pose (cheap).
			if mover.person != null and gap < far:
				var mode := Node.PROCESS_MODE_INHERIT if gap < GameConfig.PEOPLE_ANIMATE_DISTANCE else Node.PROCESS_MODE_DISABLED
				if mover.person.process_mode != mode:
					mover.person.process_mode = mode


## Makes one RouteMover from a line in the data. place: the line (points, loop, level).
func _add(node_name: String, kind: String, place: Dictionary, pace: float, body: Vector3,
		look: Node3D, rider: Person) -> RouteMover:
	var mover: RouteMover = MOVER.new()
	mover.name = node_name
	for watched in ["Bike", "Walker"]:
		var node := get_parent().get_node_or_null(watched) as Node3D
		if node != null:
			mover.watch.append(node)
	add_child(mover)
	var route: Array = place.get("points", [place.get("position", Vector3.ZERO)])
	mover.setup(kind, route, place.get("loop", false), pace, body, look, rider)
	if place.get("extra", false):
		extra_movers.append(mover)
	else:
		movers.append(mover)
	register(mover, place.get("level", 0))
	return mover


func _build_gardeners() -> void:
	var list: Array = _map.get("GARDENERS", [])
	for i in list.size():
		var look := LifeLooks.gardener(2.5)
		var mover := _add("Gardener_%d" % i, "gardener", list[i], 0.0, Vector3(0.5, 1.8, 0.5), look[0], look[1])
		mover.rotation_degrees.y = list[i]["facing"] + 180.0  # the person faces -Z, facing 0 = south


## Kids running back and forth by the playgrounds.
func _build_kids() -> void:
	var list: Array = _map.get("PLAY_KIDS", [])
	for i in list.size():
		var kid := LifeLooks.kid()
		_add("Kid_%d" % i, "person", list[i], GameConfig.PLAY_KID_SPEED, Vector3(0.45, 1.3, 0.45), _holder(kid), kid)


## Ducks paddling along a stretch of the stream (the stream's middle line wiggles, like
## WahatBuilder._build_stream draws it).
func _build_ducks() -> void:
	var stream: Dictionary = _map.get("STREAM", {})
	var list: Array = _map.get("DUCKS", [])
	for i in list.size():
		var route: Array[Vector3] = []
		var x: float = list[i]["from_x"]
		while x <= list[i]["to_x"]:
			route.append(Vector3(x, 0, stream["z"] + sin(x * 0.06) * 3.0 + list[i]["side"]))
			x += 2.5
		var line: Dictionary = list[i].duplicate()
		line["points"] = route
		var mover := _add("Duck_%d" % i, "duck", line, GameConfig.DUCK_SPEED, Vector3(0.3, 0.4, 0.45), LifeLooks.duck(i % 2 == 0), null)


## A plain holder for a person, so the mover can hide the holder.
func _holder(person: Person) -> Node3D:
	var holder := Node3D.new()
	holder.add_child(person)
	return holder


func _set_animal_name(animal: Node3D, place: Dictionary) -> void:
	if not place.has("collection_id"):
		return
	animal.set_meta("collection_id", place["collection_id"])
	animal.set_meta("collection_name", place.get("collection_name", place["collection_id"]))
	animal.set_meta("impact_name", "the horse %s" % place.get("collection_name", ""))
