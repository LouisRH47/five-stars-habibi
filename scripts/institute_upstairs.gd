class_name InstituteUpstairs
extends RefCounted
## Session 91: the C Institute's second floor (6.5 m up), built inside the lobby:
##   a deep balcony floor along the back (offices and the meeting room sit on it, see
##   scripts/institute_offices.gd), a landing and a narrower balcony down the right side,
##   glass railings with a steel top rail round every open edge, slim white columns under
##   the edge, and the wooden staircase you can really walk up (an invisible slope under
##   the steps; no step is too high for you on foot). The lift is scripts/institute_lift.gd.
## Room metres: x across the building (-23 to 23), z from the back (-18) to the front (18).

const WHITE := Color(0.97, 0.97, 0.96)
const WOOD := Color(0.72, 0.52, 0.32)
const OAK := Color(0.93, 0.78, 0.56)  # the light oak floor upstairs
const STEEL := Color(0.7, 0.72, 0.74)
const FRAME := Color(0.93, 0.93, 0.92)

const FLOOR2 := 6.5          # the upstairs floor (same as InstituteRoom.FLOOR2)
const SLAB := 0.3            # how thick the floor is
const EDGE_Z := -7.0         # the front edge of the back balcony
const INNER := 22.85         # the inside face of the side walls (x)
const BACK := -17.85         # the inside of the back glass (z)
const STAIR_X := 18.5        # the middle of the staircase
const STAIR_HALF := 1.1      # half its width
const STAIR_BOTTOM := 10.0   # where the first step is (z)
const STAIR_TOP := -2.0      # where the last step meets the landing (z)
const STEPS := 26
const SIDE_X := 19.6         # the inner edge of the right-hand balcony
const SIDE_END := 12.0       # where the right-hand balcony stops (z)
const RAIL := 1.05           # railing height


## Builds the floors, railings, columns and stairs into the institute `body`.
static func build(body: StaticBody3D) -> void:
	var balcony := Node3D.new()
	balcony.name = "Balcony"
	body.add_child(balcony)
	# The floors: [x from, x to, z from, z to].
	var floors := [[-INNER, INNER, BACK, EDGE_Z],  # along the back (the offices)
			[STAIR_X - STAIR_HALF - 0.05, INNER, EDGE_Z, STAIR_TOP],  # the landing at the top of the stairs
			[SIDE_X, INNER, STAIR_TOP, SIDE_END]]  # down the right side
	for f: Array in floors:
		var size := Vector3(f[1] - f[0], SLAB, f[3] - f[2])
		var middle := Vector3((f[0] + f[1]) * 0.5, FLOOR2 - SLAB * 0.5, (f[2] + f[3]) * 0.5)
		LowPoly.box(balcony, size, WHITE, middle)
		LowPoly.solid_box(body, size, middle)
		LowPoly.box(balcony, Vector3(size.x - 0.02, 0.02, size.z - 0.02), OAK, Vector3(middle.x, FLOOR2 + 0.01, middle.z))
	# Glass railings with a steel top rail round the open edges (a gap for the lift door and
	# the top of the stairs).
	var lift_from := InstituteLift.CENTRE.x - InstituteLift.HALF
	var lift_to := InstituteLift.CENTRE.x + InstituteLift.HALF
	var landing_x := STAIR_X - STAIR_HALF - 0.05
	var runs := [[Vector3(-INNER, 0, EDGE_Z), Vector3(lift_from, 0, EDGE_Z)],
			[Vector3(lift_to, 0, EDGE_Z), Vector3(landing_x, 0, EDGE_Z)],
			[Vector3(landing_x, 0, EDGE_Z), Vector3(landing_x, 0, STAIR_TOP)],
			[Vector3(SIDE_X, 0, STAIR_TOP), Vector3(SIDE_X, 0, SIDE_END)],
			[Vector3(SIDE_X, 0, SIDE_END), Vector3(INNER, 0, SIDE_END)]]
	for run: Array in runs:
		railing(body, balcony, run[0], run[1], FLOOR2)
	# Slim white columns under the back balcony's edge (clear of the stepped seats and lift).
	for x: float in [-20.0, -9.0, 2.0, 9.0]:
		LowPoly.cylinder(balcony, 0.16, 0.16, FLOOR2 - SLAB, WHITE, Vector3(x, (FLOOR2 - SLAB) * 0.5, EDGE_Z - 0.3))
		LowPoly.solid_cylinder(body, 0.18, FLOOR2 - SLAB, Vector3(x, (FLOOR2 - SLAB) * 0.5, EDGE_Z - 0.3))
	# Flat lights under the balcony, for the lounge below.
	for x: float in [-14.0, -2.0, 8.0]:
		VenueParts.ceiling_light(balcony, Vector3(x, 0, -12.0), Vector2(2.4, 0.6), FLOOR2 - SLAB)
	_staircase(body)


## A glass railing from `a` to `b` (x and z; along X or along Z) on a floor at height `y`,
## with slim white posts, a steel top rail, and solid so you can't walk through it.
static func railing(body: StaticBody3D, holder: Node3D, a: Vector3, b: Vector3, y: float) -> void:
	VenueParts.glass_run(body, a, b, RAIL, 1.6, y, true, FRAME)
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var length := a.distance_to(b)
	LowPoly.box(holder, Vector3(length + 0.06, 0.05, 0.07) if along_x else Vector3(0.07, 0.05, length + 0.06), STEEL,
			(a + b) * 0.5 + Vector3(0, y + RAIL + 0.025, 0))


## How high the walking slope is at `z` on the stairs: it runs along the front edges of
## the steps, from the floor just in front of the first step up to the landing.
static func stair_height(z: float) -> float:
	var run := (STAIR_BOTTOM - STAIR_TOP) / STEPS
	var rise := FLOOR2 / STEPS
	return clampf((STAIR_BOTTOM + run - z) / run * rise, 0.0, FLOOR2)


## The wooden steps on a white stair block, glass sides with steel handrails, and the
## invisible slope you walk up.
static func _staircase(body: StaticBody3D) -> void:
	var stairs := Node3D.new()
	stairs.name = "Staircase"
	body.add_child(stairs)
	var run := (STAIR_BOTTOM - STAIR_TOP) / STEPS
	var rise := FLOOR2 / STEPS
	var width := STAIR_HALF * 2.0
	for i in STEPS:
		var tread := LowPoly.box(stairs, Vector3(width, 0.06, run + 0.02), WOOD, Vector3(STAIR_X, rise * (i + 1) - 0.03, STAIR_BOTTOM - run * (i + 0.5)))
		tread.name = "Step%d" % i
		LowPoly.box(stairs, Vector3(width - 0.02, rise - 0.06, 0.04), WHITE, Vector3(STAIR_X, rise * (i + 0.5) - 0.03, STAIR_BOTTOM - run * i - 0.02))
	stairs.add_child(_stair_block(width - 0.04))
	# The slope you walk on (and the space under the stairs, so you can't walk under them).
	var foot := STAIR_BOTTOM + run  # the slope starts on the floor in front of the first step
	var top_at := STAIR_TOP + run   # ...and reaches the landing's height here
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for x: float in [STAIR_X - STAIR_HALF, STAIR_X + STAIR_HALF]:
		points.append_array([Vector3(x, 0, foot), Vector3(x, FLOOR2, top_at), Vector3(x, FLOOR2, STAIR_TOP), Vector3(x, 0, STAIR_TOP)])
	shape.points = points
	var slope := CollisionShape3D.new()
	slope.name = "StairSlope"
	slope.shape = shape
	body.add_child(slope)
	# Glass sides with a steel handrail, following the slope (solid, so you can't fall off).
	var tilt := atan2(FLOOR2, foot - top_at)
	var length := Vector2(foot - top_at, FLOOR2).length()
	var middle_z := (foot + top_at) * 0.5
	for side: float in [-1.0, 1.0]:
		var x := STAIR_X + side * (STAIR_HALF + 0.03)
		var glass := RoomProps.pane(stairs, Vector3(0.04, 0.9, length - 1.0), Vector3(x, FLOOR2 * 0.5 + 0.5, middle_z))
		glass.rotation.x = tilt
		var hand := LowPoly.box(stairs, Vector3(0.06, 0.05, length - 0.8), STEEL, Vector3(x, FLOOR2 * 0.5 + 0.98, middle_z))
		hand.rotation.x = tilt
		var wall := LowPoly.solid_box(body, Vector3(0.1, 1.1, length), Vector3(x, FLOOR2 * 0.5 + 0.55, middle_z))
		wall.rotation.x = tilt


## The white block under the steps: each step is solid white underneath, like a modern
## staircase (no gaps you could see through).
static func _stair_block(width: float) -> MeshInstance3D:
	var run := (STAIR_BOTTOM - STAIR_TOP) / STEPS
	var rise := FLOOR2 / STEPS
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var x := STAIR_X + side * width * 0.5
		tool.set_normal(Vector3(side, 0, 0))
		for i in STEPS:
			var near := STAIR_BOTTOM - run * i
			var far := near - run
			var top := rise * (i + 1) - 0.06
			_quad(tool, Vector3(x, 0.01, near), Vector3(x, 0.01, far), Vector3(x, top, far), Vector3(x, top, near), side < 0.0)
	# The back of the block, under the landing (it faces the back of the building).
	var a := Vector3(STAIR_X - width * 0.5, 0.01, STAIR_TOP)
	var b := Vector3(STAIR_X + width * 0.5, 0.01, STAIR_TOP)
	tool.set_normal(Vector3(0, 0, -1))
	_quad(tool, a, b, b + Vector3(0, FLOOR2 - 0.31, 0), a + Vector3(0, FLOOR2 - 0.31, 0), false)
	var view := MeshInstance3D.new()
	view.name = "StairBlock"
	view.mesh = tool.commit()
	var look := LowPoly.material(WHITE).duplicate() as StandardMaterial3D
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	view.material_override = look
	return view


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool) -> void:
	var corners := [a, b, c, a, c, d]
	if flip:
		corners.reverse()
	for p: Vector3 in corners:
		tool.add_vertex(p)
