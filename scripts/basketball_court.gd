class_name BasketballCourt
extends Node3D
## Session 80: the basketball court in the spine (BASKETBALL_COURT in the data), made to
## look finished: a blue court on a green surround with full white lines (sidelines,
## baselines, halfway line, centre circle, keys, free-throw circles and three-point arcs),
## a hoop at each end on a padded post with a white backboard, an orange rim and a net, a
## tall chain-link fence with a gate, and benches with a water cooler. In the day two
## players play one-on-one at the east hoop and one practises shots at the west hoop.
## SpineBuilder makes it.

const SURROUND := Color(0.22, 0.45, 0.33)
const COURT := Color(0.2, 0.42, 0.68)
const KEY := Color(0.82, 0.38, 0.24)
const LINE := Color(0.97, 0.97, 0.95)
const POST := Color(0.2, 0.22, 0.25)
const PAD := Color(0.16, 0.56, 0.61)
const RIM := Color(0.95, 0.42, 0.1)
const FENCE := Color(0.22, 0.36, 0.3)
const SHIRTS := [Color(0.9, 0.2, 0.2), Color(0.97, 0.97, 0.95), Color(0.98, 0.75, 0.2)]
const RIM_HEIGHT := 3.05
const RIM_RADIUS := 0.23
const RIM_IN := 1.35       # metres from the baseline to the middle of the rim
const SURROUND_TOP := 0.03
const COURT_TOP := 0.04
const KEY_TOP := 0.045
const LINE_TOP := 0.05

var area := Rect2()          # the court inside its lines
var hoops: Array[Vector3] = []  # the middle of each rim (west, east)
var players: Array[Person] = []
var balls: Array[MeshInstance3D] = []
var playing := true

# One game per ball: who has it, what the ball is doing, which hoop.
var _games: Array[Dictionary] = []
var _check_left := 0.0
var _near := false


static func build(parent: Node3D, court_area: Rect2) -> BasketballCourt:
	var court := BasketballCourt.new()
	court.name = "BasketballCourt"
	court.area = court_area
	parent.add_child(court)
	court._build_floor()
	court._build_lines()
	for side: float in [-1.0, 1.0]:
		court._build_hoop(side)
	court._build_fence()
	court._build_benches()
	court._build_players()
	court.update_play(GameState.clock_hours())
	return court


## Players play in the day (until GameConfig.COURT_PLAY_END_HOUR), then go home.
func update_play(hour: float) -> void:
	playing = hour < GameConfig.COURT_PLAY_END_HOUR


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.5
		update_play(GameState.clock_hours())
		var camera := get_viewport().get_camera_3d()
		var middle := Vector3(area.get_center().x, 0, area.get_center().y)
		var gap := middle.distance_to(camera.global_position) if camera != null else 0.0
		var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
		_near = playing and gap < far
		for ball in balls:
			ball.visible = _near
		for player in players:
			PlaceCrowds.apply_detail(player, gap, far, playing)
	if _near:
		play(delta)


## Each ball: the player who has it dribbles towards a spot, then shoots; the ball flies to
## the hoop, drops through the net, and the other player (or the same one, practising)
## runs to pick it up. A defender stays between the dribbler and the hoop.
func play(delta: float) -> void:
	for game in _games:
		var ball: MeshInstance3D = game["ball"]
		var hoop: Vector3 = hoops[game["hoop"]]
		var team: Array = game["players"]
		var holder: int = team[game["has"]]
		var at := _spot(holder)
		game["time"] += delta
		match game["phase"]:
			"dribble":
				_run_to(holder, game["target"], delta, hoop)
				var bounce := absf(sin(game["time"] * 7.0))
				var side := (players[holder].get_parent() as Node3D).basis.x * 0.35
				ball.position = at + side + Vector3(0, 0.12 + bounce * 0.75, 0)
				if team.size() > 1:  # the defender: between the dribbler and the hoop
					_run_to(team[1 - game["has"]], at.lerp(hoop, 0.3), delta, at)
				if game["time"] > GameConfig.COURT_SHOT_EVERY:
					game["phase"] = "shot"
					game["time"] = 0.0
					game["from"] = at + Vector3(0, 2.2, 0)
					for player: int in team:
						players[player].play("idle")
				elif _spot(holder).distance_to(game["target"]) < 0.7:
					game["target"] = _random_spot(game["hoop"])
			"shot":
				var t: float = game["time"] / GameConfig.COURT_SHOT_TIME
				var from: Vector3 = game["from"]
				ball.position = from.lerp(hoop + Vector3(0, 0.15, 0), t) + Vector3(0, sin(PI * t) * 1.6, 0)
				if t >= 1.0:
					game["phase"] = "drop"
					game["time"] = 0.0
			"drop":  # through the net and down to the ground under the hoop
				var t: float = minf(1.0, game["time"] / 0.6)
				ball.position = hoop.lerp(Vector3(hoop.x, COURT_TOP + 0.12, hoop.z), t * t)
				if t >= 1.0:
					game["phase"] = "fetch"
					game["has"] = (game["has"] + 1) % team.size()
			"fetch":
				var picker: int = team[game["has"]]
				_run_to(picker, ball.position, delta)
				if _spot(picker).distance_to(Vector3(ball.position.x, 0, ball.position.z)) < 0.8:
					game["phase"] = "dribble"
					game["time"] = 0.0
					game["target"] = _random_spot(game["hoop"])


func _spot(i: int) -> Vector3:
	var at := (players[i].get_parent() as Node3D).position
	return Vector3(at.x, 0, at.z)


func _run_to(i: int, want: Vector3, delta: float, face := Vector3.INF) -> void:
	var holder := players[i].get_parent() as Node3D
	var gap := Vector3(want.x - holder.position.x, 0, want.z - holder.position.z)
	var look := gap if face == Vector3.INF else Vector3(face.x - holder.position.x, 0, face.z - holder.position.z)
	if gap.length() > 0.5:
		holder.position += gap.normalized() * minf(GameConfig.COURT_RUN_SPEED * delta, gap.length())
		players[i].play("jog", GameConfig.COURT_RUN_SPEED / GameConfig.PERSON_JOG_ANIM_MPS)
	else:
		players[i].play("idle")
	if look.length() > 0.1:
		holder.rotation.y = lerp_angle(holder.rotation.y, atan2(-look.x, -look.z), minf(1.0, delta * 6.0))


## A spot on the court 3 to 6 m from hoop number `which` (0 west, 1 east), on the court.
func _random_spot(which: int) -> Vector3:
	var hoop := hoops[which]
	var inward := 1.0 if which == 0 else -1.0
	var a := randf_range(-1.2, 1.2)
	var r := randf_range(3.0, 6.0)
	var spot := hoop + Vector3(cos(a) * r * inward, 0, sin(a) * r)
	return Vector3(clampf(spot.x, area.position.x + 0.8, area.end.x - 0.8), 0, clampf(spot.z, area.position.y + 0.8, area.end.y - 0.8))


func _build_floor() -> void:
	var kit := MeshKit.new()
	var outer := area.grow(1.4)
	kit.box(Vector3(outer.size.x, 0.02, outer.size.y), SURROUND, Vector3(outer.get_center().x, SURROUND_TOP - 0.01, outer.get_center().y))
	kit.box(Vector3(area.size.x, 0.01, area.size.y), COURT, Vector3(area.get_center().x, COURT_TOP - 0.005, area.get_center().y))
	for side: float in [-1.0, 1.0]:  # the two keys (painted areas under the hoops)
		var x: float = area.get_center().x + side * (area.size.x * 0.5 - 2.5)
		kit.box(Vector3(5.0, 0.005, 4.0), KEY, Vector3(x, KEY_TOP - 0.0025, area.get_center().y))
	add_child(kit.finish("CourtFloor"))


func _build_lines() -> void:
	var kit := MeshKit.new()
	var w := 0.08
	var y := LINE_TOP - 0.0025
	var c := Vector3(area.get_center().x, y, area.get_center().y)
	for z: float in [area.position.y, area.end.y]:  # sidelines
		kit.box(Vector3(area.size.x + w, 0.005, w), LINE, Vector3(c.x, y, z))
	for x: float in [area.position.x, area.end.x, c.x]:  # baselines and the halfway line
		kit.box(Vector3(w, 0.005, area.size.y), LINE, Vector3(x, y, c.z))
	_ring(kit, c, 1.8, 24, 0.0, TAU)
	for side: float in [-1.0, 1.0]:
		var base: float = c.x + side * area.size.x * 0.5
		var inward := -side
		var key_end := base + inward * 5.0
		for z: float in [c.z - 2.0, c.z + 2.0]:  # the key's sides
			kit.box(Vector3(5.0, 0.005, w), LINE, Vector3(base + inward * 2.5, y, z))
		kit.box(Vector3(w, 0.005, 4.0), LINE, Vector3(key_end, y, c.z))  # free-throw line
		var facing := 0.0 if inward > 0 else PI
		_ring(kit, Vector3(key_end, y, c.z), 1.5, 12, facing - PI * 0.5, facing + PI * 0.5)  # free-throw circle
		# The three-point line: straight from the baseline near each sideline, then an arc
		# round the hoop.
		var hoop_x := base + inward * RIM_IN
		var radius := 5.6
		var corner_z := area.size.y * 0.5 - 0.6
		var reach := sqrt(radius * radius - corner_z * corner_z)
		for z: float in [c.z - corner_z, c.z + corner_z]:
			kit.box(Vector3(RIM_IN + reach, 0.005, w), LINE, Vector3(base + inward * (RIM_IN + reach) * 0.5, y, z))
		var spread := atan2(corner_z, reach)
		_ring(kit, Vector3(hoop_x, y, c.z), radius, 26, facing - spread, facing + spread)
	add_child(kit.finish("CourtLines"))


## A circle (or a part: from `a` to `b` radians, 0 = +x) made of short line pieces.
func _ring(kit: MeshKit, centre: Vector3, radius: float, pieces: int, a: float, b: float) -> void:
	var step := (b - a) / pieces
	for i in pieces:
		var t := a + (i + 0.5) * step
		var at := centre + Vector3(cos(t), 0, sin(t)) * radius
		kit.box(Vector3(0.08, 0.005, radius * absf(step) * 1.08), LINE, at, Basis(Vector3.UP, -t))


## A hoop at the west (-1) or east (+1) end: a padded post behind the baseline, an arm out
## to a white backboard with a red target square, an orange rim and a white net.
func _build_hoop(side: float) -> void:
	var base := area.get_center().x + side * area.size.x * 0.5
	var inward := -side
	var hoop := StaticBody3D.new()
	hoop.name = "Hoop_%s" % ("West" if side < 0 else "East")
	hoop.position = Vector3(base, 0, area.get_center().y)
	add_child(hoop)
	var rim := Vector3(inward * RIM_IN, RIM_HEIGHT, 0)
	hoops.append(hoop.position + rim)
	var post_x := -inward * 1.0
	var board_x := inward * (RIM_IN - RIM_RADIUS - 0.15)
	var kit := MeshKit.new()
	kit.box(Vector3(0.18, 3.6, 0.18), POST, Vector3(post_x, 1.8, 0))
	kit.box(Vector3(0.3, 1.8, 0.3), PAD, Vector3(post_x, 0.9, 0))  # the soft pad round the bottom
	kit.box(Vector3(0.5, 0.1, 0.5), POST, Vector3(post_x, 0.08, 0))  # the foot plate
	kit.box(Vector3(absf(board_x - post_x), 0.12, 0.12), POST, Vector3((board_x + post_x) * 0.5, 3.45, 0))
	kit.box(Vector3(absf(board_x - post_x) * 0.7, 0.08, 0.08), POST,
			Vector3((board_x + post_x) * 0.5, 3.0, 0) + Vector3(-inward * 0.15, 0, 0), Basis(Vector3.BACK, 0.5 * inward))
	kit.box(Vector3(0.06, 1.05, 1.8), LINE, Vector3(board_x, 3.4, 0))
	for z: float in [-0.3, 0.3]:  # the red target square on the board
		kit.box(Vector3(0.07, 0.45, 0.05), Color(0.85, 0.15, 0.15), Vector3(board_x + inward * 0.01, RIM_HEIGHT + 0.25, z))
	for y: float in [RIM_HEIGHT + 0.03, RIM_HEIGHT + 0.47]:
		kit.box(Vector3(0.07, 0.05, 0.6), Color(0.85, 0.15, 0.15), Vector3(board_x + inward * 0.01, y, 0))
	kit.box(Vector3(0.16, 0.05, 0.08), RIM, Vector3(board_x + inward * 0.08, RIM_HEIGHT, 0))
	var pieces := 14
	for i in pieces:  # the rim: a ring of short orange pieces
		var a := TAU * (i + 0.5) / pieces
		kit.cylinder(0.018, 0.018, RIM_RADIUS * TAU / pieces * 1.1, RIM, rim + Vector3(cos(a), 0, sin(a)) * RIM_RADIUS,
				Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, PI * 0.5), 5)
	hoop.add_child(kit.finish("HoopLook"))
	var net := MeshInstance3D.new()  # a cone of white netting hanging from the rim
	net.name = "Net"
	var cone := CylinderMesh.new()
	cone.top_radius = RIM_RADIUS
	cone.bottom_radius = RIM_RADIUS * 0.6
	cone.height = 0.42
	cone.radial_segments = 10
	cone.rings = 1
	cone.cap_top = false
	cone.cap_bottom = false
	net.mesh = cone
	net.material_override = SchoolPitch._net_material(8.0)
	net.position = rim - Vector3(0, 0.21, 0)
	net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hoop.add_child(net)
	LowPoly.solid_box(hoop, Vector3(0.3, 3.6, 0.3), Vector3(post_x, 1.8, 0))


## A tall chain-link fence round the surround, with a gate gap in the middle of the south side.
func _build_fence() -> void:
	var body := StaticBody3D.new()
	body.name = "CourtFence"
	add_child(body)
	var outer := area.grow(1.5)
	var gate := Vector2(area.get_center().x - 1.2, area.get_center().x + 1.2)
	var a := outer.position
	var b := Vector2(outer.end.x, outer.position.y)
	var c := outer.end
	var d := Vector2(outer.position.x, outer.end.y)
	var height := GameConfig.COURT_FENCE_HEIGHT
	var kit := MeshKit.new()
	var net := SchoolPitch._net_material(3.0)
	for side: Array in [[a, b], [b, c], [c, Vector2(gate.y, c.y)], [Vector2(gate.x, c.y), d], [d, a]]:
		var from: Vector2 = side[0]
		var to: Vector2 = side[1]
		var length := from.distance_to(to)
		var middle := (from + to) * 0.5
		var along_x := absf(to.x - from.x) > absf(to.y - from.y)
		var posts := maxi(1, ceili(length / 3.0))
		for i in posts + 1:
			var at := from.lerp(to, float(i) / posts)
			kit.cylinder(0.05, 0.05, height, FENCE, Vector3(at.x, height * 0.5, at.y), Basis(), 6)
		var size := Vector3(length if along_x else 0.05, 0.05, 0.05 if along_x else length)
		kit.box(size, FENCE, Vector3(middle.x, height, middle.y))
		kit.box(size, FENCE, Vector3(middle.x, 0.1, middle.y))
		var panel := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(size.x if along_x else 0.02, height - 0.1, 0.02 if along_x else size.z)
		panel.mesh = box
		panel.material_override = net
		panel.position = Vector3(middle.x, 0.05 + (height - 0.1) * 0.5, middle.y)
		panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(panel)
		LowPoly.solid_box(body, Vector3(maxf(size.x, 0.2), height, maxf(size.z, 0.2)), Vector3(middle.x, height * 0.5, middle.y))
	for x: float in [gate.x, gate.y]:  # thicker gate posts
		kit.cylinder(0.07, 0.07, height + 0.1, FENCE, Vector3(x, (height + 0.1) * 0.5, c.y), Basis(), 6)
	body.add_child(kit.finish("FencePosts"))


## Two benches inside the fence on the north side, with a water cooler and a bag between.
func _build_benches() -> void:
	var z := area.position.y - 0.9
	for dx: float in [-3.5, 3.5]:
		Props.bench(self, Vector3(area.get_center().x + dx, SURROUND_TOP, z), 0.0)
	var kit := MeshKit.new()
	var spot := Vector3(area.get_center().x, SURROUND_TOP, z)
	kit.cylinder(0.18, 0.18, 0.45, Color(0.9, 0.3, 0.2), spot + Vector3(0, 0.225, 0), Basis(), 10)
	kit.cylinder(0.2, 0.18, 0.08, LINE, spot + Vector3(0, 0.49, 0), Basis(), 10)
	kit.box(Vector3(0.55, 0.3, 0.3), Color(0.15, 0.2, 0.35), spot + Vector3(1.0, 0.15, 0.1))
	add_child(kit.finish("CourtBits"))


## Three players in vests and shorts, and two balls.
func _build_players() -> void:
	for i in GameConfig.COURT_PLAYERS:
		var holder := Node3D.new()
		add_child(holder)
		var player := PlaceLooks.jogger(i + 2)
		player.repaint({"shirt": SHIRTS[i % SHIRTS.size()]})
		holder.add_child(player)
		player.play("idle")
		players.append(player)
	var team_sets := [[0, 1], [2]] if players.size() >= 3 else [range(players.size())]
	for k in team_sets.size():
		var which := 1 - k  # the one-on-one at the east hoop, the practice at the west hoop
		var ball := MeshInstance3D.new()
		ball.name = "Basketball"
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		sphere.radial_segments = 8
		sphere.rings = 4
		ball.mesh = sphere
		ball.material_override = LowPoly.material(Color(0.9, 0.45, 0.15))
		add_child(ball)
		balls.append(ball)
		var team: Array = team_sets[k]
		for j in team.size():
			var start := _random_spot(which)
			(players[team[j]].get_parent() as Node3D).position = Vector3(start.x, COURT_TOP, start.z)
		_games.append({"ball": ball, "hoop": which, "players": team, "has": 0, "phase": "dribble",
				"time": randf() * 2.0, "target": _random_spot(which), "from": Vector3.ZERO})
