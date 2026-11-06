class_name LoadingBike
extends SubViewportContainer
## The strip along the bottom of the loading screen (Session 86): a little road and the
## Snackaroo bike with its rider, seen from the side, riding left to right. The loading
## screen calls ride() every frame with how full the bar is; the bike's spot on the road
## follows it, and the wheels and pedals turn as it moves. Its own small 3D world, with a
## see-through background, so the desert shows above the road.

## How tall the strip is (screen pixels, on the 1920 x 1080 layout).
const STRIP_HEIGHT := 200.0
## How many metres of the world the strip shows from top to bottom.
const VIEW_METRES := 2.9
## Metres the road's top edge sits above the bottom of the strip.
const ROAD_UP := 0.62
## Degrees the camera looks down, so a bit of the road's top shows.
const LOOK_DOWN := 12.0
## Metres the camera stands back from the bike.
const CAMERA_BACK := 10.0
## Metres kept free at each end, so the whole bike stays on screen.
const END_GAP := 1.3
const ROAD := Color(0.32, 0.33, 0.36, 1)
const KERB := Color(0.8, 0.67, 0.47, 1)
const LINE := Color(0.96, 0.94, 0.88, 1)

var _view: SubViewport
var _camera: Camera3D
var _bike: Node3D
var _rider: Person
var _crank: Node3D
var _wheels: Array[Node3D] = []
var _crank_angle := 0.0
var _last_x := INF


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -STRIP_HEIGHT
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.msaa_3d = Viewport.MSAA_4X  # smooth edges on the thin bike tubes
	add_child(_view)
	_build_world()


## Puts the bike at `fraction` (0 = the left end, 1 = the right end) of the road, and
## turns its wheels and pedals by however far it moved since last time.
func ride(fraction: float) -> void:
	var half := VIEW_METRES * _aspect() * 0.5 - END_GAP
	var x := lerpf(-half, half, clampf(fraction, 0.0, 1.0))
	var moved := 0.0 if _last_x == INF else maxf(x - _last_x, 0.0)
	_last_x = x
	_bike.position.x = x
	var turn := moved / GameConfig.WHEEL_RADIUS
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.UP, -turn)
	_crank_angle += turn / GameConfig.PEDAL_GEAR
	_crank.rotation.x = -_crank_angle
	for pedal in _crank.get_children():
		if pedal.name.begins_with("Pedal"):
			(pedal as Node3D).rotation.x = _crank_angle
	_place_rider_limbs()


func _aspect() -> float:
	var pixels := Vector2(_view.size)
	return pixels.x / maxf(pixels.y, 1.0) if pixels.y > 0 else 1920.0 / STRIP_HEIGHT


func _build_world() -> void:
	var world := Node3D.new()
	_view.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color(1, 0.93, 0.8)
	sun.shadow_enabled = true
	world.add_child(sun)
	var lights := WorldEnvironment.new()
	lights.environment = Environment.new()
	lights.environment.background_mode = Environment.BG_CLEAR_COLOR
	lights.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lights.environment.ambient_light_color = Color(0.85, 0.8, 0.72)
	lights.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(lights)
	# The road: dark top, a pale kerb in front, and a dashed white line.
	LowPoly.box(world, Vector3(400, 0.2, 3.0), ROAD, Vector3(0, -0.1, -0.4))
	LowPoly.box(world, Vector3(400, 2.0, 0.4), KERB, Vector3(0, -0.95, 1.3))
	for i in 60:
		LowPoly.box(world, Vector3(1.4, 0.02, 0.12), LINE, Vector3(-90 + i * 3.0, 0.005, -1.4))
	_bike = Node3D.new()
	_bike.rotation.y = -PI * 0.5 - 0.2  # side on, front to the right, a little towards us
	world.add_child(_bike)
	BikeModel.build(_bike)
	_wheels = [_bike.get_node("Fork/FrontWheel") as Node3D, _bike.get_node("RearWheel") as Node3D]
	_crank = _bike.get_node("Crank")
	(_bike.get_node("Kickstand") as Node3D).rotation.x = deg_to_rad(-85.0)  # folded up
	_rider = _bike.get_node("Rider") as Person
	_rider.play("pedal")
	var state := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameState")  # not the GameState name: -s tests compile this before autoloads exist
	RiderLook.apply(_rider, state.rider_look if state != null else 0)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = VIEW_METRES
	world.add_child(_camera)
	# Height that puts the road's top edge ROAD_UP metres above the strip's bottom edge.
	var down := deg_to_rad(LOOK_DOWN)
	var height := (VIEW_METRES * 0.5 - ROAD_UP + CAMERA_BACK * sin(down)) / cos(down)
	_camera.position = Vector3(0, height, CAMERA_BACK)
	_camera.rotation.x = -down
	ride(0.0)


## Keeps the rider's feet on the pedals and hands on the grips (like scripts/bike.gd).
func _place_rider_limbs() -> void:
	var to_rider := _rider.transform.affine_inverse()
	var fork := _bike.get_node("Fork") as Node3D
	for i in 2:
		var pedal := _crank.get_node("PedalLeft" if i == 0 else "PedalRight") as Node3D
		_rider.pose.feet[i] = to_rider * (_crank.transform * pedal.position + Vector3(0, 0.07, 0.03))
		var grip := fork.transform * BikeModel.grip_spot(-1.0 if i == 0 else 1.0)
		_rider.pose.hands[i] = to_rider * (grip + Vector3(0, 0.03, 0.04))
	_rider.pose.lean = GameConfig.RIDER_LEAN_DEG
