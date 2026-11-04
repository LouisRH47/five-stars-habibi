extends Node3D
## Session 56 preview: every model in data/kit_catalogue.gd at real size, one row per pack.
## Open scenes/kit_preview.tscn and press F6. Move with WASD or the arrow keys, Q and E go
## down and up, hold Shift to go faster, and the mouse wheel zooms.
## Counter things stand on a grey counter (GameConfig.KIT_COUNTER_HEIGHT), ceiling things hang
## from a beam, wall things have a wall behind them. The animals play their idle animation.
## This scene is only for looking: the game never opens it.

const GAP := 0.8          # metres between models in a row
const ROW_GAP := 3.0      # metres between pack rows
const BEAM_HEIGHT := 3.0  # where "hang" models hang from
const CAMERA_SPEED := 8.0 # metres a second (x4 with Shift)

var _camera: Camera3D


func _ready() -> void:
	_sky_and_sun()
	var z := 0.0
	var widest := 0.0
	for pack: String in KitCatalogue.PACKS:
		var ids := []
		for id: String in KitCatalogue.MODELS:
			if id.begins_with(pack + "/"):
				ids.append(id)
		if ids.is_empty():
			continue
		var depth := 0.6
		for id: String in ids:
			depth = maxf(depth, KitProps.size_of(id).z)
		var row_end := _row(pack, ids, z + depth * 0.5)
		widest = maxf(widest, row_end)
		z += depth + ROW_GAP
	_floor(widest, z)
	_camera = Camera3D.new()
	_camera.far = 800.0
	add_child(_camera)
	_camera.position = Vector3(widest * 0.5, 38.0, z + 18.0)
	_camera.look_at(Vector3(widest * 0.5, 0, z * 0.45))
	_camera.current = true


## Lays out one pack's models from x = 0 along a row at depth z. Returns where the row ends.
func _row(pack: String, ids: Array, z: float) -> float:
	var title := Label3D.new()
	title.text = "%s  (%s)" % [KitCatalogue.PACKS[pack]["name"], KitCatalogue.PACKS[pack]["maker"]]
	title.font_size = 64
	title.pixel_size = 0.01
	title.modulate = Color(0.05, 0.05, 0.08)
	title.outline_size = 0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.rotation_degrees.x = -90.0
	title.position = Vector3(-1.0, 0.02, z)
	add_child(title)
	var x := 0.0
	for id: String in ids:
		var size := KitProps.size_of(id)
		var width := maxf(size.x, 0.6)
		var spot := Vector3(x + width * 0.5, 0, z)
		var snap := KitProps.default_snap(id)
		match snap:
			"counter":
				_box(Vector3(width + 0.2, GameConfig.KIT_COUNTER_HEIGHT, maxf(size.z, 0.5) + 0.2),
						Vector3(spot.x, GameConfig.KIT_COUNTER_HEIGHT * 0.5, z), Color(0.55, 0.55, 0.58))
			"hang":
				spot.y = BEAM_HEIGHT
				_box(Vector3(width + 0.2, 0.15, 0.3), Vector3(spot.x, BEAM_HEIGHT + 0.075, z), Color(0.35, 0.3, 0.28))
			"wall":
				spot.z = z - 0.4
				spot.y = 0.0 if size.y >= 1.5 else 1.0
				_box(Vector3(width + 0.2, 2.2, 0.1), Vector3(spot.x, 1.1, spot.z - 0.05), Color(0.85, 0.8, 0.7))
		var prop := KitProps.place(self, id, spot, 0.0, 1.0, snap)
		if prop != null:
			_play_idle(prop)
		_name_tag(id.get_file(), Vector3(spot.x, 0.02, z + maxf(size.z * 0.5, 0.3) + 0.25))
		x += width + GAP
	return x


## A small name on the floor in front of each model.
func _name_tag(text: String, pos: Vector3) -> void:
	var tag := Label3D.new()
	tag.text = text
	tag.font_size = 48
	tag.pixel_size = 0.005
	tag.modulate = Color(0.05, 0.05, 0.08)
	tag.outline_size = 0
	tag.rotation_degrees.x = -90.0
	tag.position = pos
	add_child(tag)


## Animated models (the animals) play an idle clip so they don't stand in a T-pose.
func _play_idle(prop: Node) -> void:
	for player: AnimationPlayer in prop.find_children("*", "AnimationPlayer", true, false):
		for clip in player.get_animation_list():
			if clip.ends_with("Idle"):
				player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				player.play(clip)
				return


func _box(size: Vector3, pos: Vector3, colour: Color) -> void:
	LowPoly.box(self, size, colour, pos)


func _floor(width: float, depth: float) -> void:
	_box(Vector3(width + 30.0, 0.1, depth + 30.0), Vector3(width * 0.5 - 6.0, -0.05, depth * 0.5 - 6.0),
			Color(0.58, 0.55, 0.5))


func _sky_and_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.6, 0.9)
	sky_material.sky_horizon_color = Color(0.8, 0.85, 0.9)
	sky_material.ground_horizon_color = Color(0.8, 0.85, 0.9)
	sky_material.ground_bottom_color = Color(0.55, 0.6, 0.65)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)


## Simple fly camera for looking around.
func _process(delta: float) -> void:
	if _camera == null:
		return
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	if Input.is_key_pressed(KEY_E):
		move.y += 1
	if Input.is_key_pressed(KEY_Q):
		move.y -= 1
	var speed := CAMERA_SPEED * (4.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	_camera.position += move * speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _camera != null:
		var forward := -_camera.global_transform.basis.z
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.position += forward * 2.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position -= forward * 2.0
