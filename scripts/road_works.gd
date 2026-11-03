class_name RoadWorks
## Builds one set of road works (Session 33) from a line in ROAD_WORKS
## (data/wahat_al_shams.gd): a red and white barrier across the road at each end of the
## closed stretch, orange cones along both sides, a small yellow digger in the middle and a
## bilingual "Road works" sign on each barrier. The barriers and the digger are solid (the
## bike bumps into them), the cones are just to look at. scripts/event_manager.gd uses it.

const RED := Color(0.85, 0.15, 0.12, 1)
const WHITE := Color(0.97, 0.97, 0.95, 1)
const CONE := Color(0.98, 0.45, 0.08, 1)
const YELLOW := Color(0.96, 0.72, 0.1, 1)
const DARK := Color(0.16, 0.17, 0.19, 1)
const GLASS := Color(0.35, 0.55, 0.65, 1)
const POST := Color(0.3, 0.32, 0.35, 1)
const BARRIER_HEIGHT := 1.1
const SIGN_ARABIC := "أعمال طرق"
const SIGN_ENGLISH := "Road works"


## Builds the road works for this line of the data list and adds it to parent.
## Inside, the road runs along the holder's own Z and across its X.
static func build(parent: Node3D, works: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "RoadWorks"
	var centre: Vector2 = works["centre"]
	body.position = Vector3(centre.x, 0, centre.y)
	body.rotation.y = PI * 0.5 if works["along"] == "x" else 0.0
	parent.add_child(body)
	var width: float = works["width"]
	var length: float = works["length"]
	for end in [-1.0, 1.0]:
		_barrier(body, width + 1.6, end * length * 0.5, end)
	var side := width * 0.5 - 0.3
	var z := -length * 0.5 + 1.0
	while z <= length * 0.5 - 0.9:
		for x in [-side, side]:
			cone(body, Vector3(x, 0, z))
		z += 2.0
	_digger(body, Vector3(-width * 0.12, 0, 0), width >= 6.0)
	return body


## One traffic cone: orange with a white band. spot: where it stands.
static func cone(parent: Node3D, spot: Vector3) -> void:
	LowPoly.box(parent, Vector3(0.42, 0.05, 0.42), CONE, spot + Vector3(0, 0.025, 0))
	LowPoly.cylinder(parent, 0.03, 0.17, 0.62, CONE, spot + Vector3(0, 0.34, 0))
	LowPoly.cylinder(parent, 0.085, 0.11, 0.12, WHITE, spot + Vector3(0, 0.4, 0))


## A barrier across the road: two posts and a red and white striped board, with a sign
## facing out (end: -1 or 1, which end of the stretch it is on).
static func _barrier(body: Node3D, across: float, z: float, end: float) -> void:
	var stripes := 7
	for i in stripes:
		var x := -across * 0.5 + (i + 0.5) * across / stripes
		LowPoly.box(body, Vector3(across / stripes, 0.3, 0.12), RED if i % 2 == 0 else WHITE, Vector3(x, 0.85, z))
		LowPoly.box(body, Vector3(across / stripes, 0.2, 0.12), WHITE if i % 2 == 0 else RED, Vector3(x, 0.45, z))
	for x in [-across * 0.5 + 0.2, across * 0.5 - 0.2]:
		LowPoly.box(body, Vector3(0.1, BARRIER_HEIGHT, 0.1), POST, Vector3(x, BARRIER_HEIGHT * 0.5, z))
		LowPoly.box(body, Vector3(0.5, 0.06, 0.5), POST, Vector3(x, 0.03, z))
		LowPoly.sphere(body, 0.07, 0.14, CONE, Vector3(x, BARRIER_HEIGHT + 0.05, z))  # warning lamp
	LowPoly.solid_box(body, Vector3(across, BARRIER_HEIGHT, 0.3), Vector3(0, BARRIER_HEIGHT * 0.5, z))
	# The sign stands on top of the middle of the barrier and faces the way you come from.
	var board := Vector3(1.9, 0.75, 0.06)
	var sign_spot := Vector3(0, BARRIER_HEIGHT + 0.5, z + end * 0.08)
	LowPoly.box(body, board, YELLOW, sign_spot)
	LowPoly.box(body, Vector3(0.08, 0.5, 0.08), POST, Vector3(0, BARRIER_HEIGHT - 0.1, z))
	var size := SignText.fit_size(SIGN_ARABIC, SIGN_ENGLISH, 44, board.x - 0.2)
	var faces := SignText.make_two_faces(SIGN_ARABIC, SIGN_ENGLISH, size, DARK, board.z)
	faces.position = sign_spot
	faces.rotation.y = 0.0 if end > 0.0 else PI
	body.add_child(faces)


## A small yellow digger: tracks, a body with a cab, and an arm with a bucket. Bigger on
## the ring road. spot: its middle on the ground.
static func _digger(body: Node3D, spot: Vector3, big: bool) -> void:
	var holder := Node3D.new()
	holder.position = spot
	holder.scale = Vector3.ONE * (1.25 if big else 0.85)
	body.add_child(holder)
	for x in [-0.55, 0.55]:
		LowPoly.box(holder, Vector3(0.35, 0.45, 2.2), DARK, Vector3(x, 0.23, 0))   # tracks
	LowPoly.box(holder, Vector3(1.4, 0.55, 1.6), YELLOW, Vector3(0, 0.75, 0.15))  # body
	LowPoly.box(holder, Vector3(0.9, 0.9, 0.9), YELLOW, Vector3(0.2, 1.45, 0.45)) # cab
	LowPoly.box(holder, Vector3(0.8, 0.55, 0.92), GLASS, Vector3(0.2, 1.55, 0.45))
	LowPoly.box(holder, Vector3(1.0, 0.08, 1.0), DARK, Vector3(0.2, 1.93, 0.45))   # cab roof
	var boom := LowPoly.box(holder, Vector3(0.22, 0.22, 1.7), YELLOW, Vector3(-0.35, 1.45, -0.85))
	boom.rotation.x = deg_to_rad(-30.0)
	var stick := LowPoly.box(holder, Vector3(0.18, 1.1, 0.18), YELLOW, Vector3(-0.35, 1.25, -1.7))
	stick.rotation.x = deg_to_rad(15.0)
	LowPoly.box(holder, Vector3(0.6, 0.35, 0.4), DARK, Vector3(-0.35, 0.55, -1.85))  # bucket
	LowPoly.sphere(holder, 0.45, 0.4, Color(0.78, 0.66, 0.45, 1), Vector3(-0.35, 0.1, -2.5))  # dug-up sand
	var s: float = holder.scale.x
	LowPoly.solid_box(body, Vector3(1.5, 2.0, 3.6) * s, spot + Vector3(-0.1, 1.0, -0.5) * s)
