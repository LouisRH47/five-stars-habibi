class_name VfxAmbient
extends Node3D
## Session 68 (PRD "Polish pass", W4): little life in the air. Particle effects placed from the
## map data and the things already in the world:
##   - fine mist round the fountain (also on Graphics Low)
##   - a wisp of steam from the bag when you pick up hot food (also on Low)
##   - steam from the kitchen vents on the pizza and shawarma roofs
##   - leaves drifting down in the spine, the gardeners' sprinkler arcs, swimmers' splashes,
##     drops where the falaj (stream) starts
##   - thin sand wisps blowing across the ring road
## Everything fits in GameConfig.VFX_MAX_PARTICLES for the Graphics level (Low 150, Medium 600,
## High 1200): the most important ones get their particles first, and the ones further than
## VFX_RANGE metres from the camera stop (they cost nothing then). world_extras.gd adds this.

## Every emitter: {node, level (lowest Graphics level), rank (0 = most important)}.
var emitters: Array[Dictionary] = []
## Where the camera is, for tests (INF = use the real camera).
var test_eye := Vector3.INF
var _map: Dictionary = {}
var _world: Node
var _check_left := 0.0


static func attach(world: Node) -> VfxAmbient:
	var vfx := VfxAmbient.new()
	vfx.name = "VfxAmbient"
	vfx._world = world
	vfx._map = WaterLook._map(world)
	world.add_child(vfx)
	vfx.build()
	return vfx


func _ready() -> void:
	add_to_group("graphics")   # Settings.apply() calls apply_graphics() on this group
	var state := _state()
	if state != null:
		state.order_stage_changed.connect(_on_stage_changed)


func build() -> void:
	_fountain_mist()
	_kitchen_vents()
	_leaves()
	_sprinklers()
	_splashes()
	_stream_spring()
	_sand_wisps()
	apply_graphics()


func apply_graphics() -> void:
	_check_left = 0.0
	_share_budget()


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		_share_budget()


## Turns emitters on, most important and nearest first, until the budget is used up.
func _share_budget() -> void:
	var level := clampi(Settings.graphics, 0, 2)
	var budget: int = GameConfig.VFX_MAX_PARTICLES[level]
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var eye := camera.global_position if camera != null else Vector3.INF
	if test_eye != Vector3.INF:
		eye = test_eye
	emitters = emitters.filter(func(e: Dictionary) -> bool: return is_instance_valid(e["node"]))
	var wanted: Array[Dictionary] = []
	for e: Dictionary in emitters:
		var node: GPUParticles3D = e["node"]
		var far := 0.0 if eye == Vector3.INF else node.global_position.distance_to(eye)
		e["far"] = far
		if e["level"] <= level and (eye == Vector3.INF or far <= GameConfig.VFX_RANGE):
			wanted.append(e)
		else:
			_switch(e, false)
	wanted.sort_custom(func(a, b): return a["rank"] < b["rank"] or (a["rank"] == b["rank"] and a["far"] < b["far"]))
	var used := 0
	for e: Dictionary in wanted:
		var node: GPUParticles3D = e["node"]
		var fits := used + node.amount <= budget
		_switch(e, fits)
		if fits:
			used += node.amount


func _switch(e: Dictionary, on: bool) -> void:
	if not is_instance_valid(e["node"]):
		return
	var node: GPUParticles3D = e["node"]
	if e.get("timed", false):
		node.visible = on   # a puff that runs out by itself: only hide it
		return
	node.visible = on
	node.emitting = on


## Particles running now (switched on and shown). Tests read it.
func live_total() -> int:
	var total := 0
	for e: Dictionary in emitters:
		if not is_instance_valid(e["node"]):
			continue
		var node: GPUParticles3D = e["node"]
		if node.visible and (node.emitting or e.get("timed", false)):
			total += node.amount
	return total


func _register(node: GPUParticles3D, level: int, rank: int, parent: Node = self) -> GPUParticles3D:
	if node.get_parent() == null:
		parent.add_child(node)
	node.emitting = false
	emitters.append({"node": node, "level": level, "rank": rank})
	return node


# --- The effects -------------------------------------------------------------------------

func _fountain_mist() -> void:
	var plaza: Dictionary = _map.get("PLAZA", {})
	if plaza.is_empty():
		return
	var centre: Vector2 = plaza["centre"]
	var stuff := VfxKit.from_box(VfxKit.motion(Vector3.UP, 60.0, Vector2(0.1, 0.35), Vector3(0, -0.15, 0),
			Color(0.92, 0.97, 1.0, 0.35), Vector2(0.6, 1.6)), Vector3(1.1, 0.4, 1.1))
	var mist := VfxKit.emitter("FountainMist", 24, 2.2, VfxKit.quad(VfxKit.DOT, 0.5, true), stuff, 6.0)
	mist.position = Vector3(centre.x, -float(plaza.get("depth", 0.0)) + 1.1, centre.y)
	_register(mist, 0, 0)


func _kitchen_vents() -> void:
	var size: Vector3 = _map.get("RESTAURANT_SIZE", Vector3(12, 4.5, 10))
	for place: Dictionary in _map.get("RESTAURANTS", []):
		if not place["id"] in GameConfig.VFX_VENT_KITCHENS:
			continue
		var forward := Vector3(0, 0, 1).rotated(Vector3.UP, deg_to_rad(place["facing"]))
		var stuff := VfxKit.from_box(VfxKit.motion(Vector3(0.15, 1, 0), 12.0, Vector2(0.5, 0.9), Vector3(0.25, 0.05, 0),
				Color(0.95, 0.95, 0.95, 0.45), Vector2(0.7, 2.6)), Vector3(0.15, 0.05, 0.15))
		var vent := VfxKit.emitter("KitchenVent_%s" % place["id"], 14, 3.2, VfxKit.quad(VfxKit.DOT, 0.7, true), stuff, 8.0)
		vent.position = (place["position"] as Vector3) - forward * size.z * 0.3 + Vector3(size.x * 0.25, size.y + 0.6, 0)
		_register(vent, 1, 1)


func _leaves() -> void:
	var spine: Rect2 = _map.get("SPINE", Rect2())
	if spine.size == Vector2.ZERO:
		return
	var count := 6
	for i in count:
		var x := spine.position.x + spine.size.x * (i + 0.5) / count
		var stuff := VfxKit.from_box(VfxKit.motion(Vector3(1, -0.3, 0.3), 40.0, Vector2(0.2, 0.6), Vector3(0.15, -0.45, 0.05),
				Color(0.55, 0.62, 0.25, 1.0)), Vector3(7, 1.5, 7))
		stuff.angle_min = 0.0
		stuff.angle_max = 360.0
		stuff.angular_velocity_min = -90.0
		stuff.angular_velocity_max = 90.0
		stuff.hue_variation_min = -0.06
		stuff.hue_variation_max = 0.06
		var leaves := VfxKit.emitter("Leaves_%d" % i, 8, 8.0, VfxKit.quad(VfxKit.LEAF, 0.2, true), stuff, 16.0)
		leaves.position = Vector3(x, 6.0, spine.get_center().y + (i % 2 * 2 - 1) * 12.0)
		_register(leaves, 1, 2)


func _sprinklers() -> void:
	var list: Array = _map.get("GARDENERS", [])
	for i in list.size():
		var spot: Vector3 = list[i]["position"]
		var facing := deg_to_rad(float(list[i]["facing"]) + 180.0)
		var way := Vector3(0, 0, -1).rotated(Vector3.UP, facing)   # where the gardener faces
		var stuff := VfxKit.motion((way + Vector3.UP * 1.1).normalized(), 18.0, Vector2(3.0, 3.8), Vector3(0, -9.0, 0),
				Color(0.85, 0.94, 1.0, 0.75), Vector2(1.0, 0.6))
		var spray := VfxKit.emitter("Sprinkler_%d" % i, 30, 1.0, VfxKit.quad(VfxKit.DROPLET, 0.09, true), stuff, 8.0)
		spray.position = spot + way * 0.6 + Vector3(0, 0.9, 0)
		_register(spray, 1, 2)


func _splashes() -> void:
	var detail := _world.get_node_or_null("DistrictDetail") if _world != null else null
	if detail == null or not "pools" in detail:
		return
	for pool: Node in detail.pools:
		for swimmer in pool.get("swimmers"):
			if swimmer.kind != "lap":
				continue
			var stuff := VfxKit.from_ring(VfxKit.motion(Vector3.UP, 35.0, Vector2(0.6, 1.2), Vector3(0, -6.0, 0),
					Color(0.95, 0.98, 1.0, 0.85), Vector2(1.0, 0.5)), 0.35, 0.15)
			var splash := VfxKit.emitter("Splash", 10, 0.6, VfxKit.quad(VfxKit.DOT, 0.14, true), stuff, 3.0)
			splash.position = Vector3(0, 0.1, 0)
			swimmer.add_child(splash)
			_register(splash, 1, 3, swimmer)


func _stream_spring() -> void:
	var stream: Dictionary = _map.get("STREAM", {})
	if stream.is_empty():
		return
	var x: float = stream["from_x"] + 1.0
	var stuff := VfxKit.from_box(VfxKit.motion(Vector3.UP, 30.0, Vector2(0.8, 1.4), Vector3(0, -6.0, 0),
			Color(0.85, 0.95, 1.0, 0.8), Vector2(1.0, 0.5)), Vector3(0.6, 0.02, 0.6))
	var drops := VfxKit.emitter("StreamSpring", 16, 0.6, VfxKit.quad(VfxKit.DROPLET, 0.08, true), stuff, 3.0)
	drops.position = Vector3(x, 0.08, float(stream["z"]) + sin(x * 0.06) * 3.0)
	_register(drops, 1, 3)


func _sand_wisps() -> void:
	var road: Dictionary = {}
	for r: Dictionary in _map.get("ROADS", []):
		if r["name"] == "Ring Road":
			road = r
			break
	var half: Vector2 = _map.get("MAP_HALF", Vector2(470, 250))
	var ring := Vector2(half.x - 45.0, half.y - 45.0)
	var spots := [Vector2(-ring.x * 0.5, -ring.y - 0), Vector2(ring.x * 0.5, -ring.y), Vector2(-ring.x * 0.5, ring.y),
			Vector2(ring.x * 0.5, ring.y), Vector2(-ring.x, 0), Vector2(ring.x, 0)]
	if not road.is_empty():
		var a: Vector2 = road["from"]
		spots = [Vector2(a.x * 0.5, a.y), Vector2(-a.x * 0.5, a.y), Vector2(a.x * 0.5, -a.y), Vector2(-a.x * 0.5, -a.y),
				Vector2(a.x, 0), Vector2(-a.x, 0), Vector2(a.x, a.y * 0.5), Vector2(-a.x, -a.y * 0.5)]
	var wind: Vector3 = GameConfig.VFX_WIND
	for i in spots.size():
		var stuff := VfxKit.from_box(VfxKit.motion(wind.normalized(), 8.0, Vector2(2.5, 4.0), Vector3(0, 0.05, 0),
				Color(0.86, 0.76, 0.58, 0.32), Vector2(0.8, 1.4)), Vector3(9, 0.2, 9))
		var sand := VfxKit.emitter("SandWisp_%d" % i, 16, 3.0, VfxKit.quad(VfxKit.WISP, 1.4, true), stuff, 24.0)
		sand.position = Vector3(spots[i].x, 0.35, spots[i].y)
		_register(sand, 1, 4)


## A wisp of steam from the bag when you pick up hot food (it follows you for a few seconds).
func _on_stage_changed(stage: int) -> void:
	var state := _state()
	if stage != ArrivalMarker.TO_VILLA or state == null or state.current_order == null:
		return
	if not state.current_order.food in GameConfig.HOT_FOODS:
		return
	var rider := _rider()
	if rider == null:
		return
	var stuff := VfxKit.motion(Vector3.UP, 15.0, Vector2(0.3, 0.6), Vector3(0, 0.15, 0),
			Color(1, 1, 1, 0.5), Vector2(0.5, 2.0))
	var steam := VfxKit.emitter("PickupSteam", 18, 1.6, VfxKit.quad(VfxKit.DOT, 0.35, true), stuff, 4.0)
	steam.position = Vector3(0, 1.25, 0.35)
	steam.one_shot = false
	rider.add_child(steam)
	_register(steam, 0, 0, rider)
	steam.emitting = true
	emitters[-1]["timed"] = true
	_share_budget()
	get_tree().create_timer(GameConfig.VFX_STEAM_TIME).timeout.connect(func():
		if is_instance_valid(steam):
			steam.emitting = false
			get_tree().create_timer(steam.lifetime + 0.2).timeout.connect(func():
				if is_instance_valid(steam):
					steam.queue_free()))


func _rider() -> Node3D:
	if _world == null:
		return null
	for node in _world.get_children():
		if node.name == "DeliveryManager" and "actor" in node:
			var who: Node3D = node.actor
			if who != null and is_instance_valid(who):
				return who
	return _world.get_node_or_null("Bike") as Node3D


## The GameState autoload, looked up (not named: see ArrivalMarker).
func _state() -> Node:
	return get_node_or_null("/root/GameState")
