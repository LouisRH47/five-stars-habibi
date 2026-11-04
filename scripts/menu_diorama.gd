extends SubViewportContainer
## Session 71 (polish pass, GameConfig.START_DIORAMA): the small 3D scene behind the start
## screen's title. A villa corner at golden hour, palms, your Snackaroo bike parked on its
## stand with the orange box, and your rider (in the look you picked) standing by it. The
## camera swings slowly a few degrees each way. On the Mac the far houses are softly out of
## focus; in the browser the scene renders at 75% size with no blur, so it stays cheap.
## About 30 meshes, in its own little world (it doesn't load the big map).

const PALM_SCENE := preload("res://scenes/palm_tree.tscn")
const VILLA_SIZE := Vector3(9, 8.5, 8)

const SAND := Color(0.93, 0.8, 0.6)
const ROAD := Color(0.24, 0.25, 0.27)
const PAVING := Color(0.86, 0.78, 0.66)
const KERB := Color(0.95, 0.93, 0.88)

## What the camera looks at (the bike and rider), and where it sits before the swing.
const TARGET := Vector3(1.1, 1.05, -4.6)
const CAMERA_FROM := Vector3(5.6, 1.75, 3.2)

var view: SubViewport
var camera: Camera3D
var rider: Person
var bike: Node3D
var _time := 0.0


func _ready() -> void:
	stretch = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	view = SubViewport.new()
	view.own_world_3d = true
	if OS.has_feature("web") or Settings.graphics == 0:
		view.scaling_3d_scale = GameConfig.DIORAMA_WEB_SCALE
	Settings.apply_anti_aliasing(view)
	add_child(view)
	var world := Node3D.new()
	world.name = "Diorama"
	view.add_child(world)
	_light(world)
	_ground(world)
	_houses(world)
	_palms(world)
	_bike_and_rider(world)
	camera = Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	_place_camera(0.0)
	_depth_of_field()


func _process(delta: float) -> void:
	_time += delta
	if not Settings.reduce_motion:
		_place_camera(sin(_time * TAU / GameConfig.DIORAMA_ORBIT_TIME))


## Puts your rider in the look you picked (the form's look cards call this).
func set_look(look: int) -> void:
	if rider != null:
		RiderLook.apply(rider, look)


## swing: -1 to 1, how far round the camera has gone.
func _place_camera(swing: float) -> void:
	var angle := deg_to_rad(GameConfig.DIORAMA_ORBIT_DEG) * swing
	var from := TARGET + (CAMERA_FROM - TARGET).rotated(Vector3.UP, angle)
	camera.look_at_from_position(from, TARGET + Vector3(-1.4, 0.55, 0), Vector3.UP)


func _light(world: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.3, 0.55, 0.8)
	sky_material.sky_horizon_color = Color(1.0, 0.8, 0.58)
	sky_material.ground_horizon_color = Color(1.0, 0.8, 0.58)
	sky_material.ground_bottom_color = Color(0.75, 0.6, 0.42)
	sky_material.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.fog_enabled = true
	environment.fog_light_color = Color(1.0, 0.84, 0.64)
	environment.fog_density = 0.006
	environment.glow_enabled = Settings.graphics >= 1
	environment.glow_intensity = 0.5
	environment.glow_hdr_threshold = 1.1
	var lights := WorldEnvironment.new()
	lights.environment = environment
	world.add_child(lights)
	# A low golden sun from the front left, so the rider's face catches the light.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-16, -62, 0)
	sun.light_color = Color(1.0, 0.8, 0.56)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	world.add_child(sun)


func _ground(world: Node3D) -> void:
	LowPoly.box(world, Vector3(260, 0.2, 260), SAND, Vector3(0, -0.1, -40))
	LowPoly.box(world, Vector3(90, 0.04, 7.0), ROAD, Vector3(0, 0.02, 0))          # the road
	for x in range(-40, 44, 6):  # dashed middle line
		LowPoly.box(world, Vector3(2.4, 0.01, 0.14), Color(0.97, 0.95, 0.9), Vector3(x, 0.045, 0))
	LowPoly.box(world, Vector3(90, 0.16, 0.3), KERB, Vector3(0, 0.08, -3.65))      # kerb
	LowPoly.box(world, Vector3(90, 0.12, 3.0), PAVING, Vector3(0, 0.06, -5.3))     # pavement
	LowPoly.box(world, Vector3(90, 0.16, 0.3), KERB, Vector3(0, 0.08, 3.65))
	LowPoly.box(world, Vector3(90, 0.12, 3.0), PAVING, Vector3(0, 0.06, 5.3))


## A villa right behind the bike and two more down the street.
func _houses(world: Node3D) -> void:
	var spots := [[14, Vector3(-4.0, 0.0, -12.2), 0.0, "courtyard"], [27, Vector3(-17.0, 0.0, -12.6), 0.0, "garden"],
			[31, Vector3(10.5, 0.0, -12.4), 0.0, "signature"]]
	for spot in spots:
		var house := VillaBuilder.build({"number": spot[0], "house": spot[0], "position": spot[1],
				"facing": spot[2], "kind": spot[3]}, VILLA_SIZE)
		world.add_child(house)


func _palms(world: Node3D) -> void:
	var spots := [[Vector3(-6.5, 0.12, -5.6), 1], [Vector3(6.2, 0.12, -5.8), 2], [Vector3(-12.5, 0.12, -5.4), 4]]
	for spot in spots:
		var palm: Node3D = PALM_SCENE.instantiate()
		world.add_child(palm)
		palm.setup(spot[1])
		palm.position = spot[0]


## The parked bike on its stand, and you standing next to it.
func _bike_and_rider(world: Node3D) -> void:
	bike = Node3D.new()
	bike.name = "Bike"
	world.add_child(bike)
	BikeModel.build(bike)
	var sitting := bike.get_node_or_null("Rider")
	if sitting != null:
		sitting.free()  # you're standing beside it, not riding
	var stand := bike.get_node_or_null("Kickstand") as Node3D
	if stand != null:
		stand.rotation = Vector3(deg_to_rad(15.0), 0, deg_to_rad(-20.0))
	bike.position = TARGET * Vector3(1, 0, 1) + Vector3(0, 0.12, 0)
	bike.rotation = Vector3(0, deg_to_rad(68.0), deg_to_rad(GameConfig.PARKED_LEAN_DEG))
	rider = Walker.build_model() as Person
	world.add_child(rider)
	RiderLook.apply(rider, GameState.rider_look)
	set_meta("look", GameState.rider_look)
	rider.position = TARGET * Vector3(1, 0, 1) + Vector3(1.05, 0.12, 0.55)
	rider.rotation.y = deg_to_rad(205.0)


## On the Mac (Forward+, Medium or High): things far behind the bike go a little soft.
func _depth_of_field() -> void:
	if OS.has_feature("web") or Settings.graphics < 1:
		return
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return
	var blur := CameraAttributesPractical.new()
	blur.dof_blur_far_enabled = true
	blur.dof_blur_far_distance = CAMERA_FROM.distance_to(TARGET) + 3.0
	blur.dof_blur_far_transition = 9.0
	blur.dof_blur_amount = 0.05
	camera.attributes = blur
