class_name InstitutePitch
extends Node3D
## Session 80: the small 5-a-side football pitch on the grass in front of the C Institute
## (INSTITUTE_PITCH in the data; it replaced the pale blue patch that looked like a pool).
## Striped artificial turf with white lines, low white boards round it with two openings,
## a small goal with a net at each end and a tall ball-stop net behind each goal, and two
## benches. In the day, ten people play (two teams of five, the keepers stay in their
## goals), like the school pitch (scripts/school_pitch.gd). DistrictDetail makes it.

const TURF := Color(0.24, 0.58, 0.27)
const TURF_LIGHT := Color(0.3, 0.65, 0.31)
const LINE := Color(0.97, 0.97, 0.95)
const BOARD := Color(0.95, 0.95, 0.92)
const BOARD_TRIM := Color(0.16, 0.56, 0.61)
const POST := Color(0.2, 0.38, 0.32)
const TEAMS := [Color(0.95, 0.5, 0.15), Color(0.16, 0.56, 0.61)]
const KEEPER := Color(0.95, 0.85, 0.15)
const GOAL_WIDTH := 3.0
const GOAL_HEIGHT := 2.0
const GOAL_DEPTH := 1.0
const TURF_TOP := 0.035   # above the grass and the plot (0.01), below the roads (0.04)
const LINE_TOP := 0.042
const BOARD_HEIGHT := 0.6
const STOP_NET_HEIGHT := 4.0

var turf := Rect2()     # the whole green carpet
var lines := Rect2()    # inside the white lines
var goals: Array[Node3D] = []
var players: Array[Person] = []
var ball: MeshInstance3D
var playing := true

var _homes: Array[Vector3] = []
var _ball_target := Vector3.ZERO
var _check_left := 0.0
var _near := false


static func build(parent: Node3D, spec: Dictionary) -> InstitutePitch:
	var pitch := InstitutePitch.new()
	pitch.name = "InstitutePitch"
	pitch.turf = spec["area"]
	pitch.lines = spec["lines"]
	parent.add_child(pitch)
	pitch._build_turf()
	pitch._build_lines()
	for side: float in [-1.0, 1.0]:
		pitch._build_goal(side)
	pitch._build_boards()
	pitch._build_players()
	pitch.update_play(GameState.clock_hours())
	return pitch


## People play in the day (until GameConfig.INSTITUTE_PITCH_PLAY_END_HOUR), then go home.
func update_play(hour: float) -> void:
	playing = hour < GameConfig.INSTITUTE_PITCH_PLAY_END_HOUR


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		update_play(GameState.clock_hours())
		var camera := get_viewport().get_camera_3d()
		var middle := Vector3(lines.get_center().x, 0, lines.get_center().y)
		var gap := middle.distance_to(camera.global_position) if camera != null else 0.0
		var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)] + lines.size.y * 0.5
		_near = playing and gap < far
		ball.visible = _near
		for player in players:
			PlaceCrowds.apply_detail(player, gap - lines.size.y * 0.4, far, playing)
	if _near:
		play(delta)


## The game goes on: the ball rolls to where it was passed, the two nearest outfield players
## chase it, the others drift towards it from their spots, and the keepers follow it
## along their goal line.
func play(delta: float) -> void:
	var to_target := _ball_target - ball.position
	to_target.y = 0.0
	var step := GameConfig.INSTITUTE_PITCH_BALL_SPEED * delta
	if to_target.length() <= step:
		_ball_target = Vector3(randf_range(lines.position.x + 1.5, lines.end.x - 1.5), ball.position.y,
				randf_range(lines.position.y + 2.5, lines.end.y - 2.5))
	else:
		ball.position += to_target.normalized() * step
		ball.rotate(Vector3(to_target.z, 0, -to_target.x).normalized(), step / 0.11)
	var outfield: Array = range(2, players.size())
	outfield.sort_custom(func(a, b): return _gap_to_ball(a) < _gap_to_ball(b))
	for rank in outfield.size():
		var i: int = outfield[rank]
		var want := ball.position if rank < 2 else _homes[i].lerp(ball.position, 0.35)
		if rank == 1:  # Session 92: the second chaser closes in but stays a little way off
			want = ball.position + (_homes[i] - ball.position).normalized() * GameConfig.PITCH_SECOND_CHASER_GAP
		_run_to(i, want, delta)
	for i in 2:  # the keepers: on their line, level with the ball
		var want := _homes[i]
		want.x = clampf(ball.position.x, lines.get_center().x - GOAL_WIDTH * 0.4, lines.get_center().x + GOAL_WIDTH * 0.4)
		_run_to(i, want, delta, ball.position)
	CourtSpacing.spread(CourtSpacing.holders_of(players), GameConfig.COURT_PLAYER_GAP)  # Session 92: no two on one spot


func _run_to(i: int, want: Vector3, delta: float, face := Vector3.INF) -> void:
	var holder := players[i].get_parent() as Node3D
	want.y = holder.position.y
	var gap := want - holder.position
	var run := GameConfig.INSTITUTE_PITCH_RUN_SPEED * delta
	var look := gap if face == Vector3.INF else face - holder.position
	if gap.length() > 0.6:
		holder.position += gap.normalized() * minf(run, gap.length())
		players[i].play("jog", GameConfig.INSTITUTE_PITCH_RUN_SPEED / GameConfig.PERSON_JOG_ANIM_MPS)
	else:
		players[i].play("idle")
	if Vector2(look.x, look.z).length() > 0.1:
		holder.rotation.y = lerp_angle(holder.rotation.y, atan2(-look.x, -look.z), minf(1.0, delta * 6.0))


func _gap_to_ball(i: int) -> float:
	var at := (players[i].get_parent() as Node3D).position
	return Vector2(at.x - ball.position.x, at.z - ball.position.z).length()


func _build_turf() -> void:
	var kit := MeshKit.new()
	var stripes := 8  # mowing stripes across the pitch
	var depth := turf.size.y / stripes
	for i in stripes:
		kit.box(Vector3(turf.size.x, 0.025, depth), TURF if i % 2 == 0 else TURF_LIGHT,
				Vector3(turf.get_center().x, TURF_TOP - 0.0125, turf.position.y + (i + 0.5) * depth))
	add_child(kit.finish("Turf"))


func _build_lines() -> void:
	var kit := MeshKit.new()
	var w := 0.1
	var c := Vector3(lines.get_center().x, LINE_TOP - 0.003, lines.get_center().y)
	for x: float in [lines.position.x, lines.end.x]:  # touchlines (the long sides run along z)
		kit.box(Vector3(w, 0.006, lines.size.y), LINE, Vector3(x, c.y, c.z))
	for z: float in [lines.position.y, lines.end.y, c.z]:  # goal lines and the halfway line
		kit.box(Vector3(lines.size.x, 0.006, w), LINE, Vector3(c.x, c.y, z))
	_ring(kit, c, 3.0, 24, 0.0, TAU)
	kit.cylinder(0.15, 0.15, 0.006, LINE, c)
	for side: float in [-1.0, 1.0]:
		var goal_z: float = c.z + side * lines.size.y * 0.5
		# The D-shaped goal area: a 5 m half circle round the goal, and the penalty spot.
		var facing := -PI * 0.5 if side > 0 else PI * 0.5
		_ring(kit, Vector3(c.x, c.y, goal_z), 5.0, 18, facing - PI * 0.5, facing + PI * 0.5)
		kit.cylinder(0.12, 0.12, 0.006, LINE, Vector3(c.x, c.y, goal_z - side * 6.0))
	add_child(kit.finish("PitchLines"))


## A circle (or a part: from `a` to `b` radians, 0 = +x) made of short line pieces.
func _ring(kit: MeshKit, centre: Vector3, radius: float, pieces: int, a: float, b: float) -> void:
	var step := (b - a) / pieces
	for i in pieces:
		var t := a + (i + 0.5) * step
		var at := centre + Vector3(cos(t), 0, sin(t)) * radius
		kit.box(Vector3(0.1, 0.006, radius * absf(step) * 1.08), LINE, at, Basis(Vector3.UP, -t))


## A small goal on the goal line at the north (-1) or south (+1) end, opening onto the pitch,
## with a net (the school pitch's netting) and a tall ball-stop net behind it.
func _build_goal(side: float) -> void:
	var goal := StaticBody3D.new()
	goal.name = "Goal_%s" % ("North" if side < 0 else "South")
	goal.position = Vector3(lines.get_center().x, 0, lines.get_center().y + side * lines.size.y * 0.5)
	add_child(goal)
	goals.append(goal)
	var back := side * GOAL_DEPTH
	var half := GOAL_WIDTH * 0.5
	var kit := MeshKit.new()
	for x: float in [-half, half]:
		kit.cylinder(0.05, 0.05, GOAL_HEIGHT, LINE, Vector3(x, GOAL_HEIGHT * 0.5, 0))
		kit.cylinder(0.035, 0.035, GOAL_HEIGHT * 0.7, LINE, Vector3(x, GOAL_HEIGHT * 0.35, back))
		kit.box(Vector3(0.05, 0.05, GOAL_DEPTH), LINE, Vector3(x, 0.03, back * 0.5))
		kit.box(Vector3(0.05, 0.05, GOAL_DEPTH), LINE, Vector3(x, GOAL_HEIGHT * 0.7, back * 0.5))
	kit.cylinder(0.05, 0.05, GOAL_WIDTH + 0.1, LINE, Vector3(0, GOAL_HEIGHT, 0), Basis(Vector3.BACK, PI * 0.5))
	kit.cylinder(0.035, 0.035, GOAL_WIDTH, LINE, Vector3(0, GOAL_HEIGHT * 0.7, back), Basis(Vector3.BACK, PI * 0.5))
	goal.add_child(kit.finish("GoalFrame"))
	var net := SchoolPitch._net_material(6.0)
	_panel(goal, net, Vector3(GOAL_WIDTH, GOAL_HEIGHT * 0.7, 0.02), Vector3(0, GOAL_HEIGHT * 0.35, back))
	var roof := _panel(goal, net, Vector3(GOAL_WIDTH, 0.02, Vector2(GOAL_DEPTH, GOAL_HEIGHT * 0.3).length()),
			Vector3(0, GOAL_HEIGHT * 0.85, back * 0.5))
	roof.rotation.x = atan2(GOAL_HEIGHT * 0.3, GOAL_DEPTH) * side
	for x: float in [-half, half]:
		_panel(goal, net, Vector3(0.02, GOAL_HEIGHT * 0.85, GOAL_DEPTH), Vector3(x, GOAL_HEIGHT * 0.42, back * 0.5))
		LowPoly.solid_box(goal, Vector3(0.15, GOAL_HEIGHT, 0.15), Vector3(x, GOAL_HEIGHT * 0.5, 0))
	LowPoly.solid_box(goal, Vector3(GOAL_WIDTH, GOAL_HEIGHT, 0.15), Vector3(0, GOAL_HEIGHT * 0.5, back))
	# The ball-stop net behind the goal: green posts with netting between them.
	var stop_z := side * 1.98  # at the boards, 2 m behind the goal line
	var wide := lines.size.x + 1.0
	var posts := MeshKit.new()
	for x: float in [-wide * 0.5, -wide / 6.0, wide / 6.0, wide * 0.5]:
		posts.cylinder(0.06, 0.07, STOP_NET_HEIGHT, POST, Vector3(x, STOP_NET_HEIGHT * 0.5, stop_z))
	posts.box(Vector3(wide, 0.05, 0.05), POST, Vector3(0, STOP_NET_HEIGHT, stop_z))
	goal.add_child(posts.finish("StopNetPosts"))
	_panel(goal, SchoolPitch._net_material(2.0), Vector3(wide, STOP_NET_HEIGHT - BOARD_HEIGHT, 0.02),
			Vector3(0, BOARD_HEIGHT + (STOP_NET_HEIGHT - BOARD_HEIGHT) * 0.5, stop_z))


## Low white boards round the turf with a teal trim, open in the middle of each long side
## (where you walk on), and two benches beside the east opening.
func _build_boards() -> void:
	var body := StaticBody3D.new()
	body.name = "PitchBoards"
	add_child(body)
	var kit := MeshKit.new()
	var gap := 2.0
	var mid := turf.get_center().y
	var a := turf.position
	var b := turf.end
	var sides := [[Vector2(a.x, a.y), Vector2(b.x, a.y)], [Vector2(a.x, b.y), Vector2(b.x, b.y)],
			[Vector2(a.x, a.y), Vector2(a.x, mid - gap)], [Vector2(a.x, mid + gap), Vector2(a.x, b.y)],
			[Vector2(b.x, a.y), Vector2(b.x, mid - gap)], [Vector2(b.x, mid + gap), Vector2(b.x, b.y)]]
	for side: Array in sides:
		var from: Vector2 = side[0]
		var to: Vector2 = side[1]
		var middle := (from + to) * 0.5
		var size := Vector3(maxf(absf(to.x - from.x), 0.08), BOARD_HEIGHT, maxf(absf(to.y - from.y), 0.08))
		kit.box(size, BOARD, Vector3(middle.x, BOARD_HEIGHT * 0.5, middle.y))
		kit.box(size + Vector3(0.02, -BOARD_HEIGHT + 0.08, 0.02), BOARD_TRIM, Vector3(middle.x, BOARD_HEIGHT - 0.04, middle.y))
		LowPoly.solid_box(body, size, Vector3(middle.x, BOARD_HEIGHT * 0.5, middle.y))
	body.add_child(kit.finish("Boards"))
	for dz: float in [-4.5, 4.5]:
		Props.bench(self, Vector3(b.x + 1.6, 0, mid + dz), -90.0)


## Two teams in sports kit (one orange, one teal), a keeper in yellow in each goal, and the ball.
func _build_players() -> void:
	ball = MeshInstance3D.new()
	ball.name = "Football"
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	sphere.radial_segments = 8
	sphere.rings = 4
	ball.mesh = sphere
	ball.material_override = LowPoly.material(Color(0.97, 0.97, 0.97))
	ball.position = Vector3(lines.get_center().x, TURF_TOP + 0.11, lines.get_center().y)
	add_child(ball)
	_ball_target = ball.position
	var c := lines.get_center()
	for i in GameConfig.INSTITUTE_PITCH_PLAYERS:
		var team := i % 2  # 0 plays towards the south goal, 1 towards the north
		var home: Vector3
		if i < 2:  # the keepers, just in front of their goal line
			home = Vector3(c.x, TURF_TOP, lines.position.y + 0.8 if team == 0 else lines.end.y - 0.8)
		else:
			var row := (i - 2) >> 1
			var across: float = [-4.5, 4.5, -2.0, 2.0][row % 4]
			var along: float = [-9.0, -9.0, -3.5, -3.5][row % 4]
			home = Vector3(c.x + across, TURF_TOP, c.y + along * (1.0 if team == 0 else -1.0))
		_homes.append(home)
		var holder := Node3D.new()
		holder.position = home
		holder.rotation.y = PI if team == 0 else 0.0
		add_child(holder)
		var player := PlaceLooks.jogger(i)
		player.repaint({"shirt": KEEPER if i < 2 else TEAMS[team]})
		holder.add_child(player)
		player.play("idle")
		players.append(player)


func _panel(parent: Node3D, material: Material, size: Vector3, spot: Vector3) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	view.mesh = box
	view.material_override = material
	view.position = spot
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	return view
