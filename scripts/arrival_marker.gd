class_name ArrivalMarker
extends MeshInstance3D
## Session 68 (PRD "Polish pass", W1): the new delivery beam over the next stop.
##   - a soft light column that fades out at the top (assets/shaders/beam.gdshader)
##   - small sparkles rising inside it
##   - a glowing ring on the ground that pulses slowly and gets smaller when you're close
## Orange on the way to the restaurant, teal on the way to the customer (like the phone).
## When you finish a stop the ring bursts outward and the beam fades (burst()).
## DeliveryManager._make_marker() makes it when GameConfig.MARKER_V2 is on; it moves and
## shows it exactly like the old cylinder. No collision: you ride right into it.

const BEAM_SHADER := preload("res://assets/shaders/beam.gdshader")
const RING_SHADER := preload("res://assets/shaders/marker_ring.gdshader")
const RING_SPOT := 0.8   # where the ring is drawn on its square (marker_ring.gdshader "ring")
## GameState.Stage numbers. Copied, not read from GameState: a script with a class_name must
## not name an autoload (test scripts compile it before the autoloads exist).
const TO_RESTAURANT := 2
const TO_VILLA := 3

## The stage it's showing (GameState.Stage). Tests read it.
var step := -1
## How many times it has burst (tests read it).
var bursts := 0
var colour := Color.WHITE
var ring_view: MeshInstance3D
var sparkles: GPUParticles3D
var _beam_look: ShaderMaterial
var _ring_look: ShaderMaterial
var _clock := 0.0


func _init() -> void:
	name = "ArrivalMarker"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The beam jumps from door to door, so don't smooth (slide) it between physics steps.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visible = false
	_beam_look = ShaderMaterial.new()
	_beam_look.shader = BEAM_SHADER
	_beam_look.set_shader_parameter("height", GameConfig.MARKER_HEIGHT)
	_beam_look.set_shader_parameter("strength", 1.0)
	var column := CylinderMesh.new()
	column.top_radius = GameConfig.BEAM_RADIUS
	column.bottom_radius = GameConfig.BEAM_RADIUS
	column.height = GameConfig.MARKER_HEIGHT
	column.radial_segments = 24
	column.rings = 1
	column.cap_top = false
	column.cap_bottom = false
	column.material = _beam_look
	mesh = column
	ring_view = make_ring()
	_ring_look = ring_view.material_override
	add_child(ring_view)
	sparkles = _make_sparkles()
	add_child(sparkles)
	set_step(TO_RESTAURANT)


## Orange for the pick-up, teal for the drop-off. Moving on from a stop makes it burst there.
func set_step(stage: int) -> void:
	var was_target := step == TO_RESTAURANT or step == TO_VILLA
	if was_target and stage != step and visible and is_inside_tree():
		burst()
	step = stage
	colour = colour_for(stage)
	for look in [_beam_look, _ring_look]:
		look.set_shader_parameter("colour", colour)
	(sparkles.process_material as ParticleProcessMaterial).color = colour.lightened(0.45)


static func colour_for(stage: int) -> Color:
	if stage == TO_VILLA:
		var teal := UiPalette.TEAL   # the phone's teal, made bright enough to glow
		return Color.from_hsv(teal.h, GameConfig.BEAM_DROP_SATURATION, GameConfig.BEAM_DROP_VALUE)
	return UiPalette.ORANGE


## The ring's size now (metres): smaller when the rider is close, with a slow pulse.
func ring_radius(distance: float, time: float) -> float:
	var near := clampf((distance - GameConfig.BEAM_RING_NEAR_DISTANCE) / 4.0, 0.0, 1.0)
	var size := lerpf(GameConfig.BEAM_RING_NEAR_RADIUS, GameConfig.BEAM_RING_RADIUS, near)
	return size * (1.0 + GameConfig.BEAM_RING_PULSE * sin(time * TAU * GameConfig.BEAM_RING_PULSE_HZ))


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	var distance := 99.0
	var manager := get_parent()
	var rider: Node3D = manager.get("actor") if manager != null and "actor" in manager else null
	if rider != null and is_instance_valid(rider) and rider.is_inside_tree():
		var gap := rider.global_position - global_position
		distance = Vector2(gap.x, gap.z).length()
	var r := ring_radius(distance, _clock)
	ring_view.scale = Vector3(r, 1.0, r)


## The ring flies outward and fades, a ring of sparkles bursts and the beam fades away, all at
## the spot where the marker is now. It's a separate node, so the marker can already move on.
func burst() -> void:
	bursts += 1
	var holder := get_parent()
	if holder == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	fx.name = "MarkerBurst"
	fx.process_mode = Node.PROCESS_MODE_ALWAYS   # the Delivered card pauses the game
	fx.top_level = true
	holder.add_child(fx)
	fx.global_position = global_position
	var ring := make_ring()
	var ring_look: ShaderMaterial = ring.material_override
	ring_look.set_shader_parameter("colour", colour)
	ring.scale = ring_view.scale
	fx.add_child(ring)
	var column := MeshInstance3D.new()
	column.mesh = mesh.duplicate()
	var beam_look: ShaderMaterial = _beam_look.duplicate()
	column.material_override = beam_look
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(column)
	var pop := _make_sparkles(true)
	(pop.process_material as ParticleProcessMaterial).color = colour.lightened(0.5)
	pop.position = Vector3(0, -GameConfig.MARKER_HEIGHT * 0.5 + 0.2, 0)
	fx.add_child(VfxKit.one_shot(pop))
	var time := GameConfig.BEAM_BURST_TIME
	var big := GameConfig.BEAM_BURST_RADIUS
	var tween := fx.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(big, 1, big), time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_look, "shader_parameter/strength", 0.0, time)
	tween.tween_property(beam_look, "shader_parameter/strength", 0.0, time * 0.8)
	tween.tween_property(column, "scale", Vector3(1.6, 1.0, 1.6), time)
	tween.chain().tween_callback(fx.queue_free).set_delay(0.6)


## The ground ring: a flat square just above the ground, 1 m "radius" before scaling.
func make_ring() -> MeshInstance3D:
	var look := ShaderMaterial.new()
	look.shader = RING_SHADER
	look.set_shader_parameter("colour", colour)
	look.set_shader_parameter("ring", RING_SPOT)
	look.set_shader_parameter("strength", 1.0)
	var square := PlaneMesh.new()
	square.size = Vector2.ONE * (2.0 / RING_SPOT)   # the ring itself sits at 1 m
	var view := MeshInstance3D.new()
	view.name = "Ring"
	view.mesh = square
	view.material_override = look
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.position = Vector3(0, -GameConfig.MARKER_HEIGHT * 0.5 + GameConfig.BEAM_RING_LIFT, 0)
	return view


## Little sparkles rising up the beam (burst = a ring of them flying out once).
func _make_sparkles(burst_out := false) -> GPUParticles3D:
	var stuff: ParticleProcessMaterial
	if burst_out:
		stuff = VfxKit.from_ring(VfxKit.motion(Vector3(0, 0.6, 0), 80.0, Vector2(2.0, 3.5),
				Vector3(0, -2.0, 0), Color.WHITE, Vector2(1.0, 0.3)), 1.2, 0.9)
		stuff.radial_velocity_min = 2.0
		stuff.radial_velocity_max = 3.0
	else:
		stuff = VfxKit.from_ring(VfxKit.motion(Vector3.UP, 8.0, Vector2(0.5, 1.1), Vector3.ZERO,
				Color.WHITE, Vector2(1.0, 0.4)), GameConfig.BEAM_RADIUS * 0.8, 0.2)
	var count := GameConfig.BEAM_BURST_SPARKLES if burst_out else GameConfig.BEAM_SPARKLES
	var p := VfxKit.emitter("Sparkles", count, 0.8 if burst_out else 2.6,
			VfxKit.quad(VfxKit.SPARKLE, 0.16 if burst_out else 0.13), stuff, 8.0, 120.0)
	if not burst_out:
		p.position = Vector3(0, -GameConfig.MARKER_HEIGHT * 0.5 + 0.1, 0)
		p.emitting = true
	return p
