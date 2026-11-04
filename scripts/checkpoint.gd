extends Node3D
## Scenery checkpoint: cars raise the boom, cyclists have a permanent side gap.
var _barrier: StaticBody3D
var _boom: Node3D
var _guard: Person
var _raised := false
var _wave_left := 0.0

func _ready() -> void:
	if GameConfig.GLASS_BOOTHS_ON:
		var made := glass_booth(self, Vector3(3, 3, 3), false)   # Session 61
		made.position = Vector3(-8, 0, 0)
	else:
		var booth := StaticBody3D.new()
		booth.position = Vector3(-8, 0, 0)
		add_child(booth)
		LowPoly.box(booth, Vector3(3, 3, 3), Color(0.95, 0.9, 0.8), Vector3(0, 1.5, 0))
		LowPoly.box(booth, Vector3(3.2, 0.2, 3.2), Color.TEAL, Vector3(0, 3.1, 0))
		LowPoly.solid_box(booth, Vector3(3, 3, 3), Vector3(0, 1.5, 0))
		LowPoly.box(booth, Vector3(2, 1.1, 0.1), Color(0.3, 0.55, 0.66), Vector3(0, 1.9, 1.55))
	_barrier = StaticBody3D.new()
	_barrier.name = "Barrier"
	add_child(_barrier)
	_boom = Node3D.new()
	_boom.position = Vector3(-3.5, 1.1, 0)
	_barrier.add_child(_boom)
	for i in 14:
		LowPoly.box(_boom, Vector3(0.5, 0.18, 0.2), Color.RED if i % 2 == 0 else Color.WHITE, Vector3(i * 0.5 + 0.25, 0, 0))
	LowPoly.solid_box(_barrier, Vector3(7, 1.2, 0.25), Vector3(0, 1.1, 0))
	_guard = PeopleLooks.resident(2, 2)
	_guard.position = Vector3(-5.4, 0, 1)
	_guard.rotation.y = PI
	add_child(_guard)
	set_meta("bike_gap", 1.5)


func _process(delta: float) -> void:
	var car_near := false
	for vehicle: Node3D in get_tree().get_nodes_in_group("traffic_vehicle"):
		if global_position.distance_to(vehicle.global_position) < 14:
			car_near = true
	if car_near != _raised:
		_raised = car_near
		for shape: CollisionShape3D in _barrier.find_children("*", "CollisionShape3D", true, false):
			shape.set_deferred("disabled", _raised)
	_boom.rotation.z = move_toward(_boom.rotation.z, -PI * 0.46 if _raised else 0.0, delta * 2.0)
	_wave_left -= delta
	for bike: Node3D in get_tree().get_nodes_in_group("bike"):
		if _wave_left <= 0 and global_position.distance_to(bike.global_position) < 20:
			_guard.play("wave")
			_wave_left = 6.0
	if _wave_left < 3 and _guard.action == "wave":
		_guard.play("idle")


## Session 61: a glass security booth (the school gate and the community checkpoints use it):
## a low stone base, glass all round in white frames, a flat teal roof with a light strip, a
## desk with a screen and a phone inside, and (if guard) the guard sitting at the desk.
## The front is +z. Returns the booth (solid, so the bike bumps into it).
static func glass_booth(parent: Node3D, size: Vector3, guard: bool) -> StaticBody3D:
	var booth := StaticBody3D.new()
	booth.name = "GlassBooth"
	parent.add_child(booth)
	var half := size * 0.5
	var base := 0.55
	var white := Color(0.97, 0.97, 0.96)
	var teal := Color(0.16, 0.56, 0.61)
	LowPoly.box(booth, Vector3(size.x, base, size.z), Color(0.85, 0.82, 0.76), Vector3(0, base * 0.5, 0))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.82, 0.9, 0.25)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	var pane_h := size.y - base - 0.3
	for side in 4:
		var along_x := side % 2 == 0
		var length := size.x if along_x else size.z
		var at := Vector3(0, base + pane_h * 0.5, half.z * (1.0 if side == 0 else -1.0)) if along_x \
				else Vector3(half.x * (1.0 if side == 1 else -1.0), base + pane_h * 0.5, 0)
		var pane := LowPoly.box(booth, Vector3(length - 0.1, pane_h, 0.04) if along_x else Vector3(0.04, pane_h, length - 0.1), Color.WHITE, at)
		pane.material_override = glass
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pane.name = "BoothGlass"
	for x in [-half.x, half.x]:
		for z in [-half.z, half.z]:
			LowPoly.box(booth, Vector3(0.1, size.y - 0.2, 0.1), white, Vector3(x, (size.y - 0.2) * 0.5, z))
	for z in [-half.z, half.z]:   # a white frame line round the middle of the glass
		LowPoly.box(booth, Vector3(size.x, 0.06, 0.08), white, Vector3(0, base + 0.9, z))
	LowPoly.box(booth, Vector3(size.x + 0.5, 0.25, size.z + 0.5), white, Vector3(0, size.y - 0.15, 0))
	LowPoly.box(booth, Vector3(size.x + 0.52, 0.1, size.z + 0.52), teal, Vector3(0, size.y - 0.3, 0))
	# The door on the left side: a darker frame in the glass.
	LowPoly.box(booth, Vector3(0.06, size.y - 0.4, 0.9), Color(0.25, 0.27, 0.3), Vector3(-half.x - 0.01, (size.y - 0.4) * 0.5, -half.z + 0.7))
	# Inside: a desk along the front with a screen and a phone, and a chair.
	LowPoly.box(booth, Vector3(size.x - 0.4, 0.06, 0.55), Color(0.55, 0.4, 0.28), Vector3(0, base + 0.35, half.z - 0.4))
	var screen := LowPoly.box(booth, Vector3(0.45, 0.3, 0.04), Color(0.1, 0.1, 0.12), Vector3(0.4, base + 0.6, half.z - 0.5))
	screen.rotation.y = PI
	LowPoly.box(booth, Vector3(0.4, 0.26, 0.01), Color(0.3, 0.6, 0.85), Vector3(0.4, base + 0.6, half.z - 0.475))
	LowPoly.box(booth, Vector3(0.18, 0.06, 0.12), Color(0.15, 0.15, 0.15), Vector3(-0.4, base + 0.41, half.z - 0.4))
	LowPoly.solid_box(booth, size, Vector3(0, half.y, 0))
	if guard:
		var who := Person.new()
		who.name = "BoothGuard"
		who.paint({"skin": PeopleLooks.SKINS[2], "shirt": Color(0.15, 0.2, 0.35), "pants": Color(0.12, 0.14, 0.2)})
		PeopleLooks.cap(who, Color(0.12, 0.15, 0.25), who)
		who.position = Vector3(-0.1, base + 0.45 - who.spot("Hips").y + 0.05, half.z - 1.05)
		who.rotation.y = PI   # looks out of the front glass
		booth.add_child(who)
		who.play("sit")
	return booth

