class_name DesertBackdrop
## The low-poly 3D desert behind the start screen and the loading screen (Session 86):
## a warm sky, a low sun light, a big pale sun ball, sand dunes and one palm.
## build() makes a full-screen picture of it. The screen that uses it gets the camera
## back, so it can drift slowly over the dunes.

const PALM_SCENE := preload("res://scenes/palm_tree.tscn")


## Makes the desert. Returns {"frame": the full-screen SubViewportContainer to add,
## "camera": the Camera3D looking at the dunes, "world": the Node3D everything is in}.
static func build() -> Dictionary:
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view := SubViewport.new()
	view.own_world_3d = true
	frame.add_child(view)
	var world := Node3D.new()
	view.add_child(world)
	world.add_child(_sky())
	var sun_light := DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-25, -150, 0)
	sun_light.light_color = Color(1, 0.9, 0.75)
	sun_light.shadow_enabled = true
	world.add_child(sun_light)
	_sun_ball(world)
	# Dunes: big squashed sand balls in a few warm shades.
	var shades := [Color(0.93, 0.8, 0.58), Color(0.89, 0.74, 0.5), Color(0.96, 0.85, 0.65)]
	var dunes := [[Vector3(-40, -10, -60), 36.0], [Vector3(30, -12, -80), 44.0], [Vector3(0, -14, -30), 30.0],
			[Vector3(-80, -16, -110), 50.0], [Vector3(70, -15, -40), 34.0], [Vector3(10, -40, -5), 44.0]]
	for i in dunes.size():
		var dune := LowPoly.sphere(world, dunes[i][1], dunes[i][1] * 0.6, shades[i % shades.size()], dunes[i][0])
		dune.scale = Vector3(1.6, 1.0, 1.0)
	var palm: Node3D = PALM_SCENE.instantiate()
	world.add_child(palm)
	palm.setup(2)
	palm.position = Vector3(9, 1.0, -22)
	palm.scale = Vector3.ONE * 1.4
	var camera := Camera3D.new()
	camera.fov = 55.0
	world.add_child(camera)
	camera.position = Vector3(0, 6, 12)
	camera.rotation_degrees = Vector3(-4, 0, 0)
	return {"frame": frame, "camera": camera, "world": world}


## The warm desert sky, with a little haze far away.
static func _sky() -> WorldEnvironment:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.31, 0.66, 0.84)
	sky_material.sky_horizon_color = Color(0.98, 0.86, 0.66)
	sky_material.ground_horizon_color = Color(0.98, 0.86, 0.66)
	sky_material.ground_bottom_color = Color(0.85, 0.7, 0.45)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.98, 0.86, 0.66)
	environment.fog_density = 0.004
	var lights := WorldEnvironment.new()
	lights.environment = environment
	return lights


## The big pale sun, low over the dunes.
static func _sun_ball(world: Node3D) -> void:
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1, 0.96, 0.82)
	var disc := SphereMesh.new()
	disc.radius = 14.0
	disc.height = 28.0
	disc.material = glow
	var sun_ball := MeshInstance3D.new()
	sun_ball.mesh = disc
	sun_ball.position = Vector3(-35, 16, -140)
	world.add_child(sun_ball)
