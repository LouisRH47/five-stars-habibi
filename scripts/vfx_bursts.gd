class_name VfxBursts
extends Node3D
## Session 68 (PRD "Polish pass", W5): little celebrations in the world, where it happened.
##   - a 5-star delivery: a burst of confetti in Snackaroo colours at the door
##   - a tip: a few coins hop out
##   - a level-up: a ring of light round your rider
## They keep playing while the Delivered card pauses the game, then remove themselves.
## world_extras.gd adds this.

## How many of each it has made (tests read them).
var made := {"confetti": 0, "coins": 0, "level_ring": 0}
## The last burst made (tests watch it finish).
var last_burst: Node3D
var _world: Node
var _level := 0


static func attach(world: Node) -> VfxBursts:
	var bursts := VfxBursts.new()
	bursts.name = "VfxBursts"
	bursts._world = world
	world.add_child(bursts)
	return bursts


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_level = GameState.level()
	GameState.order_delivered.connect(_on_delivered)
	GameState.stats_changed.connect(_on_stats_changed)


func _on_delivered(order: Order) -> void:
	var result: Dictionary = GameState.last_result
	var door := _door(order)
	if door == Vector3.INF:
		return
	if float(result.get("stars", 0.0)) >= 5.0:
		confetti(door + Vector3.UP * 1.2)
	if int(result.get("tip", 0)) > 0:
		coins(door + Vector3.UP * 0.6)


func _on_stats_changed() -> void:
	var now := GameState.level()
	if now > _level:
		var rider := _rider()
		if rider != null:
			level_ring(rider.global_position)
	_level = now


## 40 bits of paper in 4 colours, flying up and fluttering down.
func confetti(spot: Vector3) -> GPUParticles3D:
	var stuff := VfxKit.motion(Vector3.UP, 50.0, Vector2(3.5, 6.0), Vector3(0, -6.5, 0), Color.WHITE, Vector2(1.0, 0.8))
	stuff.damping_min = 2.0
	stuff.damping_max = 3.5
	stuff.angle_min = 0.0
	stuff.angle_max = 360.0
	stuff.angular_velocity_min = -400.0
	stuff.angular_velocity_max = 400.0
	var colours := Gradient.new()   # each bit picks one of the 4 colours
	colours.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colours.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	colours.colors = PackedColorArray([UiPalette.ORANGE, UiPalette.SUN, UiPalette.CYAN, UiPalette.SAND])
	var pick := GradientTexture1D.new()
	pick.gradient = colours
	stuff.color_initial_ramp = pick
	var paper := QuadMesh.new()
	paper.size = Vector2(0.12, 0.07)
	var look := StandardMaterial3D.new()
	look.vertex_color_use_as_albedo = true
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.material = look
	var p := VfxKit.emitter("Confetti", GameConfig.CONFETTI_COUNT, GameConfig.CONFETTI_TIME, paper, stuff, 10.0, 120.0)
	return _fire(p, spot, "confetti")


## A few gold coins hop up and fall.
func coins(spot: Vector3) -> GPUParticles3D:
	var stuff := VfxKit.motion(Vector3.UP, 30.0, Vector2(3.0, 4.2), Vector3(0, -12.0, 0), Color.WHITE)
	stuff.angle_min = 0.0
	stuff.angle_max = 360.0
	stuff.angular_velocity_min = 200.0
	stuff.angular_velocity_max = 500.0
	var coin := CylinderMesh.new()
	coin.top_radius = 0.09
	coin.bottom_radius = 0.09
	coin.height = 0.025
	coin.radial_segments = 10
	coin.rings = 1
	var gold := StandardMaterial3D.new()
	gold.albedo_color = UiPalette.SUN
	gold.metallic = 0.8
	gold.roughness = 0.3
	var upright := SurfaceTool.new()   # stood on its edge, so spinning round makes it flash
	upright.append_from(coin, 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	upright.set_material(gold)
	stuff.particle_flag_rotate_y = true
	var p := VfxKit.emitter("Coins", GameConfig.TIP_COINS, 0.9, upright.commit(), stuff, 6.0, 120.0)
	return _fire(p, spot, "coins")


## A ring of light that spreads out round the rider, with sparkles.
func level_ring(spot: Vector3) -> GPUParticles3D:
	var stuff := VfxKit.from_ring(VfxKit.motion(Vector3.UP, 5.0, Vector2(1.5, 2.5), Vector3(0, -0.5, 0),
			UiPalette.SUN.lightened(0.3), Vector2(1.0, 0.3)), 1.0, 0.95)
	stuff.radial_velocity_min = 1.5
	stuff.radial_velocity_max = 2.0
	var p := VfxKit.emitter("LevelRing", 36, 1.1, VfxKit.quad(VfxKit.SPARKLE, 0.22, false, true), stuff, 10.0, 120.0)
	var ring := MeshInstance3D.new()
	ring.name = "Glow"
	var square := PlaneMesh.new()
	square.size = Vector2.ONE * 2.5
	ring.mesh = square
	var look := ShaderMaterial.new()
	look.shader = preload("res://assets/shaders/marker_ring.gdshader")
	look.set_shader_parameter("colour", UiPalette.SUN)
	look.set_shader_parameter("strength", 1.0)
	ring.material_override = look
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0, 0.08, 0)
	_fire(p, spot, "level_ring")
	p.add_child(ring)
	ring.top_level = false
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(3.0, 1.0, 3.0), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(look, "shader_parameter/strength", 0.0, 1.0)
	return p


func _fire(p: GPUParticles3D, spot: Vector3, kind: String) -> GPUParticles3D:
	add_child(VfxKit.one_shot(p))
	p.global_position = spot
	made[kind] += 1
	last_burst = p
	return p


func _door(order: Order) -> Vector3:
	var places := _world.get_node_or_null("PlaceBuilder") if _world != null else null
	if places == null or order == null:
		return Vector3.INF
	if order.villa_number != 0 and places.has_method("villa_door"):
		return places.villa_door(order.villa_number)
	return Vector3.INF


func _rider() -> Node3D:
	if _world == null:
		return null
	for node in _world.get_children():
		if node is DeliveryManager and node.actor != null and is_instance_valid(node.actor):
			return node.actor
	return _world.get_node_or_null("Bike") as Node3D
