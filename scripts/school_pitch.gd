class_name SchoolPitch
extends Node3D
## Session 72: the school football pitch, in front of the school (between the gate and the
## building). Striped turf with full markings, two goals with nets, a 4-lane running track
## along the north side, and a fence of tall green posts with netting (a gap by the gate).
## Four floodlights light only the pitch (each one aims at its own quarter) and come on by
## themselves when it gets dark (GameConfig.FLOODLIGHT_ON_HOUR on the shift clock). In the
## day, pupils play a game of football. LandmarkBuilder makes it (replacing the old pitch).

const TURF := Color(0.36, 0.62, 0.3)
const TURF_LIGHT := Color(0.42, 0.69, 0.35)
const LINE := Color(0.97, 0.97, 0.95)
const POST := Color(0.2, 0.38, 0.32)
const MAST := Color(0.62, 0.64, 0.66)
const GOAL_WIDTH := 6.0
const GOAL_HEIGHT := 2.2
const GOAL_DEPTH := 1.8
const FENCE_HEIGHT := 6.5
const MAST_HEIGHT := 16.0

## Where everything is (world x, z). Set from the school area in build().
var fence := Rect2()
var track := Rect2()
var turf := Rect2()
var pitch := Rect2()        # inside the white lines
var gate_gap := Vector2()   # x from, x to: the opening in the north fence
var lights: Array[SpotLight3D] = []
var goals: Array[Node3D] = []
var pupils: Array[Person] = []
var ball: MeshInstance3D
var lights_on := false

var _lamp: StandardMaterial3D
var _ball_target := Vector3.ZERO
var _homes: Array[Vector3] = []
var _check_left := 0.0
var _near := false
var _playing := true


static func build(parent: Node3D, school: Dictionary) -> SchoolPitch:
	var area: Rect2 = school["area"]
	var pitch_node := SchoolPitch.new()
	pitch_node.name = "SchoolPitch"
	pitch_node.fence = Rect2(area.position.x + 23, area.position.y + 11, area.size.x - 31, 50)
	var f := pitch_node.fence
	pitch_node.track = Rect2(f.position.x + 6, f.position.y + 1.5, f.size.x - 12, 5)
	pitch_node.turf = Rect2(f.position.x + 2, f.position.y + 7.5, f.size.x - 4, f.size.y - 8.5)
	pitch_node.pitch = Rect2(f.position.x + 6, f.position.y + 10, f.size.x - 12, f.size.y - 13)
	var gate_x: float = school["gate_x"]
	pitch_node.gate_gap = Vector2(gate_x - 2.0, gate_x + 2.0)
	parent.add_child(pitch_node)
	pitch_node._build_ground()
	pitch_node._build_markings()
	for side in [-1.0, 1.0]:
		pitch_node._build_goal(side)
	pitch_node._build_fence()
	pitch_node._build_floodlights()
	pitch_node._build_pupils()
	pitch_node.update_lights(GameState.clock_hours())
	return pitch_node


## Floodlights on when it's dark (at or after FLOODLIGHT_ON_HOUR), pupils out in the day.
func update_lights(hour: float) -> void:
	var on := hour >= GameConfig.FLOODLIGHT_ON_HOUR
	_playing = hour < GameConfig.PITCH_PLAY_END_HOUR
	if on == lights_on and lights.size() > 0 and lights[0].visible == on:
		return
	lights_on = on
	for light in lights:
		light.visible = on
	_lamp.emission_enabled = on
	_lamp.albedo_color = Color(1.0, 0.98, 0.9) if on else Color(0.55, 0.57, 0.6)


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		update_lights(GameState.clock_hours())
		var camera := get_viewport().get_camera_3d()
		var middle := Vector3(pitch.get_center().x, 0, pitch.get_center().y)
		var gap := middle.distance_to(camera.global_position) if camera != null else 0.0
		var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)] + pitch.size.x * 0.5
		_near = _playing and gap < far
		ball.visible = _near
		for pupil in pupils:
			PlaceCrowds.apply_detail(pupil, gap - pitch.size.x * 0.4, far, _playing)
	if _near:
		play(delta)


## The game goes on: the ball rolls to where it was passed, the nearest two pupils chase it
## and everyone else keeps to their spot, shifting towards the ball.
func play(delta: float) -> void:
	var to_target := _ball_target - ball.position
	to_target.y = 0.0
	var step := GameConfig.PITCH_BALL_SPEED * delta
	if to_target.length() <= step:
		_ball_target = Vector3(randf_range(pitch.position.x + 4, pitch.end.x - 4), ball.position.y,
				randf_range(pitch.position.y + 3, pitch.end.y - 3))
	else:
		ball.position += to_target.normalized() * step
		ball.rotate(Vector3(to_target.z, 0, -to_target.x).normalized(), step / 0.12)
	var order := range(pupils.size())
	order.sort_custom(func(a, b): return _flat_gap(pupils[a]) < _flat_gap(pupils[b]))
	for rank in order.size():
		var i: int = order[rank]
		var holder := pupils[i].get_parent() as Node3D
		var want := ball.position if rank < 2 else _homes[i].lerp(ball.position, 0.3)
		want.y = 0.0
		var gap := want - holder.position
		gap.y = 0.0
		var run := GameConfig.PITCH_PUPIL_SPEED * delta
		if gap.length() > 0.8:
			holder.position += gap.normalized() * minf(run, gap.length())
			holder.rotation.y = lerp_angle(holder.rotation.y, atan2(-gap.x, -gap.z), minf(1.0, delta * 6.0))
			pupils[i].play("jog", GameConfig.PITCH_PUPIL_SPEED / GameConfig.PERSON_JOG_ANIM_MPS)
		else:
			pupils[i].play("idle")


func _flat_gap(pupil: Person) -> float:
	var at := (pupil.get_parent() as Node3D).position
	return Vector2(at.x - ball.position.x, at.z - ball.position.z).length()


func _build_ground() -> void:
	# Mowing stripes across the pitch, then the red running track with its lane lines.
	var stripes := 11
	var width := turf.size.x / stripes
	for i in stripes:
		LowPoly.box(self, Vector3(width, 0.04, turf.size.y), TURF if i % 2 == 0 else TURF_LIGHT,
				Vector3(turf.position.x + (i + 0.5) * width, 0.03, turf.get_center().y))
	SurfaceTextures.slab(self, "red_track", track.size, Vector3(track.get_center().x, 0.05, track.get_center().y))
	var kit := MeshKit.new()
	for lane in 5:
		kit.box(Vector3(track.size.x, 0.01, 0.06), LINE, Vector3(track.get_center().x, 0.056, track.position.y + 0.1 + lane * 1.2))
	for x in [track.position.x + 0.5, track.end.x - 0.5]:  # start and finish lines
		kit.box(Vector3(0.12, 0.01, track.size.y), LINE, Vector3(x, 0.057, track.get_center().y))
	add_child(kit.finish("TrackLines"))


func _build_markings() -> void:
	var kit := MeshKit.new()
	var y := 0.056
	var c := Vector3(pitch.get_center().x, y, pitch.get_center().y)
	var w := 0.12
	for z in [pitch.position.y, pitch.end.y]:  # touchlines
		kit.box(Vector3(pitch.size.x, 0.01, w), LINE, Vector3(c.x, y, z))
	for x in [pitch.position.x, pitch.end.x, c.x]:  # goal lines and the halfway line
		kit.box(Vector3(w, 0.01, pitch.size.y), LINE, Vector3(x, y, c.z))
	_ring(kit, c, 6.0, 28, 0.0, TAU)
	kit.cylinder(0.25, 0.25, 0.01, LINE, c)
	for side in [-1.0, 1.0]:
		var goal_x: float = c.x + side * pitch.size.x * 0.5
		for box_size: Vector2 in [Vector2(11.0, 24.0), Vector2(4.0, 11.0)]:  # penalty and goal areas
			var inner: float = goal_x - side * box_size.x
			kit.box(Vector3(w, 0.01, box_size.y), LINE, Vector3(inner, y, c.z))
			for z in [c.z - box_size.y * 0.5, c.z + box_size.y * 0.5]:
				kit.box(Vector3(box_size.x, 0.01, w), LINE, Vector3(goal_x - side * box_size.x * 0.5, y, z))
		kit.cylinder(0.2, 0.2, 0.01, LINE, Vector3(goal_x - side * 8.0, y, c.z))  # penalty spot
		# The arc outside the penalty area (the part of a 6 m circle round the spot).
		var spot := Vector3(goal_x - side * 8.0, y, c.z)
		var reach := acos(3.0 / 6.0)
		var facing := 0.0 if side < 0 else PI
		_ring(kit, spot, 6.0, 10, facing - reach, facing + reach)
		for z in [pitch.position.y, pitch.end.y]:  # corner arcs
			_ring(kit, Vector3(goal_x, y, z), 1.0, 12, 0.0, TAU, pitch)
	add_child(kit.finish("PitchLines"))


## A circle (or part of one: from `a` to `b` radians, 0 = +x) of short line pieces. Pieces
## outside `keep` (if given) are left out (for the corner arcs).
func _ring(kit: MeshKit, centre: Vector3, radius: float, pieces: int, a: float, b: float, keep := Rect2()) -> void:
	var step := (b - a) / pieces
	for i in pieces:
		var t := a + (i + 0.5) * step
		var at := centre + Vector3(cos(t), 0, sin(t)) * radius
		if keep.size != Vector2.ZERO and not keep.has_point(Vector2(at.x, at.z)):
			continue
		var length := radius * absf(step) * 1.08
		kit.box(Vector3(0.12, 0.01, length), LINE, at, Basis(Vector3.UP, -t))


## One goal on the goal line at x side (-1 west, +1 east): white posts, a frame going back,
## and a net (see-through netting texture).
func _build_goal(side: float) -> void:
	var goal := StaticBody3D.new()
	goal.name = "Goal_%s" % ("West" if side < 0 else "East")
	goal.position = Vector3(pitch.get_center().x + side * pitch.size.x * 0.5, 0, pitch.get_center().y)
	add_child(goal)
	goals.append(goal)
	var back := side * GOAL_DEPTH
	var kit := MeshKit.new()
	var half := GOAL_WIDTH * 0.5
	for z in [-half, half]:
		kit.cylinder(0.06, 0.06, GOAL_HEIGHT, LINE, Vector3(0, GOAL_HEIGHT * 0.5, z))
		kit.cylinder(0.04, 0.04, GOAL_HEIGHT * 0.75, LINE, Vector3(back, GOAL_HEIGHT * 0.375, z))
		var top := Vector3(0, GOAL_HEIGHT, z)
		var low := Vector3(back, GOAL_HEIGHT * 0.75, z)
		kit.cylinder(0.035, 0.035, top.distance_to(low), LINE, (top + low) * 0.5,
				Basis(Quaternion(Vector3.UP, (low - top).normalized())))
		kit.box(Vector3(GOAL_DEPTH, 0.05, 0.05), LINE, Vector3(back * 0.5, 0.03, z))
	kit.cylinder(0.06, 0.06, GOAL_WIDTH + 0.12, LINE, Vector3(0, GOAL_HEIGHT, 0), Basis(Vector3.RIGHT, PI * 0.5))
	kit.cylinder(0.04, 0.04, GOAL_WIDTH, LINE, Vector3(back, GOAL_HEIGHT * 0.75, 0), Basis(Vector3.RIGHT, PI * 0.5))
	goal.add_child(kit.finish("GoalFrame"))
	var net := _net_material(6.0)
	_panel(goal, net, Vector3(0.02, GOAL_HEIGHT * 0.75, GOAL_WIDTH), Vector3(back, GOAL_HEIGHT * 0.375, 0), 0.0)  # the back
	var slope := atan2(GOAL_HEIGHT * 0.25, GOAL_DEPTH)
	var roof := _panel(goal, net, Vector3(GOAL_DEPTH / cos(slope), 0.02, GOAL_WIDTH), Vector3(back * 0.5, GOAL_HEIGHT * 0.875, 0), 0.0)
	roof.rotation.z = slope * side
	for z in [-half, half]:  # the sides
		_panel(goal, net, Vector3(GOAL_DEPTH, GOAL_HEIGHT * 0.85, 0.02), Vector3(back * 0.5, GOAL_HEIGHT * 0.42, z), 0.0)
	for z in [-half, half]:  # you bump the posts, and the net at the back
		LowPoly.solid_box(goal, Vector3(0.2, GOAL_HEIGHT, 0.2), Vector3(0, GOAL_HEIGHT * 0.5, z))
	LowPoly.solid_box(goal, Vector3(0.2, GOAL_HEIGHT, GOAL_WIDTH), Vector3(back, GOAL_HEIGHT * 0.5, 0))


func _build_fence() -> void:
	var body := StaticBody3D.new()
	body.name = "PitchFence"
	add_child(body)
	var kit := MeshKit.new()
	var net := _net_material(2.0)
	var a := fence.position
	var b := Vector2(fence.end.x, fence.position.y)
	var c := fence.end
	var d := Vector2(fence.position.x, fence.end.y)
	for side: Array in [[a, Vector2(gate_gap.x, a.y)], [Vector2(gate_gap.y, a.y), b], [b, c], [c, d], [d, a]]:
		var from: Vector2 = side[0]
		var to: Vector2 = side[1]
		var length := from.distance_to(to)
		var middle := (from + to) * 0.5
		var along_x := absf(to.x - from.x) > absf(to.y - from.y)
		var posts := maxi(1, ceili(length / 5.0))
		for i in posts + 1:
			var at := from.lerp(to, float(i) / posts)
			kit.cylinder(0.08, 0.09, FENCE_HEIGHT, POST, Vector3(at.x, FENCE_HEIGHT * 0.5, at.y))
		var size := Vector3(length, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, length)
		kit.box(Vector3(maxf(size.x, 0.06), 0.06, maxf(size.z, 0.06)), POST, Vector3(middle.x, FENCE_HEIGHT, middle.y))
		kit.box(Vector3(maxf(size.x, 0.05), 0.45, maxf(size.z, 0.05)), POST, Vector3(middle.x, 0.225, middle.y))  # kick board
		_panel(body, net, Vector3(maxf(size.x, 0.02), FENCE_HEIGHT - 0.45, maxf(size.z, 0.02)),
				Vector3(middle.x, 0.45 + (FENCE_HEIGHT - 0.45) * 0.5, middle.y), 0.0)
		LowPoly.solid_box(body, Vector3(maxf(size.x, 0.3), FENCE_HEIGHT, maxf(size.z, 0.3)), Vector3(middle.x, FENCE_HEIGHT * 0.5, middle.y))
	body.add_child(kit.finish("FencePosts"))


## The four floodlights: one by each corner of the turf, each aimed at its own quarter of the
## pitch with a narrow beam, so the light stays on the pitch.
func _build_floodlights() -> void:
	_lamp = StandardMaterial3D.new()
	_lamp.emission = Color(1.0, 0.97, 0.85)
	_lamp.emission_energy_multiplier = 4.0
	var middle := pitch.get_center()
	for corner: Vector2 in [Vector2(turf.position.x - 1.0, turf.position.y + 0.5), Vector2(turf.end.x + 1.0, turf.position.y + 0.5),
			Vector2(turf.position.x - 1.0, turf.end.y + 0.5), Vector2(turf.end.x + 1.0, turf.end.y + 0.5)]:
		var mast := StaticBody3D.new()
		mast.name = "Floodlight"
		mast.position = Vector3(corner.x, 0, corner.y)
		add_child(mast)
		LowPoly.cylinder(mast, 0.14, 0.26, MAST_HEIGHT, MAST, Vector3(0, MAST_HEIGHT * 0.5, 0))
		LowPoly.solid_cylinder(mast, 0.3, MAST_HEIGHT, Vector3(0, MAST_HEIGHT * 0.5, 0))
		var quarter := Vector2(lerpf(corner.x, middle.x, 0.5), lerpf(corner.y, middle.y, 0.5))
		var aim := Vector3(quarter.x, 0, quarter.y)
		var head := Node3D.new()
		head.name = "Head"
		head.position = Vector3(0, MAST_HEIGHT, 0)
		mast.add_child(head)
		head.look_at_from_position(mast.global_position + head.position, aim, Vector3.UP)
		LowPoly.box(head, Vector3(2.4, 1.3, 0.3), MAST, Vector3(0, 0, 0.1))
		for x in [-0.8, 0.0, 0.8]:
			for y in [-0.3, 0.3]:
				var lamp := LowPoly.box(head, Vector3(0.6, 0.45, 0.06), Color.WHITE, Vector3(x, y, -0.07))
				lamp.material_override = _lamp
		var light := SpotLight3D.new()
		light.name = "Beam"
		light.light_color = Color(1.0, 0.97, 0.9)
		light.light_energy = GameConfig.FLOODLIGHT_ENERGY
		light.spot_range = GameConfig.FLOODLIGHT_RANGE
		light.spot_angle = GameConfig.FLOODLIGHT_ANGLE
		light.spot_attenuation = 0.6
		light.spot_angle_attenuation = 2.0
		light.shadow_enabled = false
		light.position = Vector3(0, 0, -0.3)
		head.add_child(light)
		lights.append(light)


## Pupils in their school uniforms playing football, and the ball.
func _build_pupils() -> void:
	ball = MeshInstance3D.new()
	ball.name = "Football"
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 8
	sphere.rings = 4
	ball.mesh = sphere
	ball.material_override = LowPoly.material(Color(0.97, 0.97, 0.97))
	ball.position = Vector3(pitch.get_center().x, 0.17, pitch.get_center().y)
	add_child(ball)
	_ball_target = ball.position
	for i in GameConfig.PITCH_PUPILS:
		var team := -1.0 if i % 2 == 0 else 1.0
		var row := i >> 1
		var home := Vector3(pitch.get_center().x + team * (6.0 + (row % 2) * 12.0),
				0.05, pitch.position.y + (row + 0.5) * pitch.size.y / (GameConfig.PITCH_PUPILS * 0.5))
		_homes.append(home)
		var holder := Node3D.new()
		holder.position = home
		add_child(holder)
		var pupil := PlaceLooks.pupil()
		pupil.set_meta("outfit", "uniform")
		holder.add_child(pupil)
		pupil.play("idle")
		pupils.append(pupil)


## A see-through net panel (a thin box with the netting texture).
func _panel(parent: Node3D, material: Material, size: Vector3, spot: Vector3, _turn: float) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	view.mesh = box
	view.material_override = material
	view.position = spot
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	return view


## Netting: the white diamond mesh texture (tools/blender/make_textures.py), repeated
## `per_metre` times a metre, see-through between the strings and drawn from both sides.
static func _net_material(per_metre: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/net.png")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * per_metre
	mat.roughness = 0.9
	return mat
