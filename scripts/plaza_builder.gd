extends Node3D
## Builds the Plaza (Session 27) from data/wahat_al_shams.gd: the round paving, and in the
## middle the sunken square: steps going down to a round floor with a fountain, benches and
## two shade sails. WahatBuilder leaves a square hole in the ground here; this fills it.
## The steps are only for looks: underneath them is one smooth, gentle slope (a "height map",
## a grid of heights) that the bike rolls down and back up without bumping.
## The shops round the Plaza come from PlaceBuilder, the palms from DecorBuilder.

## The map data to build from (set in the scene): data/wahat_al_shams.gd.
@export var data: Script

const PAVING := Color(0.86, 0.79, 0.66, 1)
const STEP_COLOURS := [Color(0.93, 0.88, 0.78, 1), Color(0.88, 0.82, 0.7, 1), Color(0.93, 0.88, 0.78, 1)]
const FLOOR := Color(0.8, 0.62, 0.48, 1)        # terracotta tiles
const FLOOR_RING := Color(0.16470589, 0.5568628, 0.6117647, 1)  # a teal tile ring
const FOUNTAIN_STONE := Color(0.96, 0.94, 0.88, 1)
const WATER := Color(0.35, 0.68, 0.9, 1)
const SAIL := Color(0.98, 0.96, 0.9, 1)
const POST := Color(0.85, 0.85, 0.85, 1)
const SEGMENTS := 48          # how round the rings are
const SAIL_HEIGHTS := [4.9, 4.0, 4.9]

var _plaza: Dictionary
var _centre := Vector3.ZERO


func _ready() -> void:
	if data == null:
		push_error("PlazaBuilder has no data list set in the scene")
		return
	var map := data.get_script_constant_map()
	_plaza = map["PLAZA"]
	_centre = Vector3(_plaza["centre"].x, 0, _plaza["centre"].y)
	var outer: float = _plaza["radius"]
	var top: float = _plaza["sunken_radius"]
	var bottom: float = _plaza["floor_radius"]
	var depth: float = _plaza["depth"]
	var steps: int = _plaza["steps"]
	# The paving from the edge of the Plaza to the top step.
	_ring(top, outer, 0.035, 0.035 + depth * 0.5 / steps, PAVING).name = "Plaza"
	# The steps, each a ring a bit lower than the last, then the round floor.
	var width := (top - bottom) / steps
	for k in steps:
		var step_top := -depth * (k + 0.5) / steps
		var drop := depth / steps if k < steps - 1 else depth * 0.5 / steps
		_ring(top - (k + 1) * width, top - k * width, step_top, drop, STEP_COLOURS[k % STEP_COLOURS.size()])
	LowPoly.cylinder(self, bottom, bottom, 0.1, FLOOR, _centre + Vector3(0, -depth - 0.05, 0))
	_ring(4.2, 5.0, -depth + 0.01, 0.0, FLOOR_RING)
	_build_slope(top, bottom, depth)
	_build_fountain(depth)
	for bench in map.get("PLAZA_BENCHES", []):
		Props.bench(self, bench["position"], bench["facing"])
	for posts in map.get("PLAZA_SAILS", []):
		_build_sail(posts)


## The invisible ground under the sunken square: flat at the top, a gentle slope over the
## steps, flat again on the floor. One height every metre, as a HeightMapShape3D.
func _build_slope(top: float, bottom: float, depth: float) -> void:
	var half := ceili(top)
	var size := half * 2 + 1
	var heights := PackedFloat32Array()
	heights.resize(size * size)
	for z in size:
		for x in size:
			var r := Vector2(x - half, z - half).length()
			heights[z * size + x] = -depth * clampf((top - r) / (top - bottom), 0.0, 1.0)
	var shape := HeightMapShape3D.new()
	shape.map_width = size
	shape.map_depth = size
	shape.map_data = heights
	var body := StaticBody3D.new()
	body.name = "SunkenSquareGround"
	body.position = _centre
	add_child(body)
	var holder := CollisionShape3D.new()
	holder.shape = shape
	body.add_child(holder)


## The fountain in the middle: a round stone basin of water with a column, a bowl on top
## and a jet of water. The basin is solid.
func _build_fountain(depth: float) -> void:
	var radius: float = _plaza["fountain_radius"]
	var body := StaticBody3D.new()
	body.name = "Fountain"
	body.position = _centre + Vector3(0, -depth, 0)
	add_child(body)
	LowPoly.cylinder(body, radius, radius + 0.15, 0.6, FOUNTAIN_STONE, Vector3(0, 0.3, 0))
	LowPoly.cylinder(body, radius - 0.25, radius - 0.25, 0.05, WATER, Vector3(0, 0.58, 0))
	LowPoly.cylinder(body, 0.35, 0.45, 1.6, FOUNTAIN_STONE, Vector3(0, 1.2, 0))
	LowPoly.cylinder(body, 1.2, 0.5, 0.35, FOUNTAIN_STONE, Vector3(0, 2.1, 0))
	LowPoly.cylinder(body, 1.0, 1.0, 0.05, WATER, Vector3(0, 2.26, 0))
	LowPoly.cylinder(body, 0.15, 0.2, 0.8, FOUNTAIN_STONE, Vector3(0, 2.6, 0))
	LowPoly.sphere(body, 0.25, 0.4, Color(0.85, 0.68, 0.25, 1), Vector3(0, 3.05, 0))
	var jet := LowPoly.cylinder(body, 0.05, 0.12, 0.9, WATER, Vector3(0, 3.6, 0))
	jet.transparency = 0.4
	LowPoly.solid_cylinder(body, radius + 0.1, 1.2, Vector3(0, 0.6, 0))


## A shade sail: three white posts and a cloth triangle stretched between their tops.
func _build_sail(posts: Array) -> void:
	var corners := PackedVector3Array()
	for i in posts.size():
		var spot: Vector3 = posts[i]
		var height: float = SAIL_HEIGHTS[i % SAIL_HEIGHTS.size()]
		var post := StaticBody3D.new()
		post.position = spot
		add_child(post)
		LowPoly.cylinder(post, 0.08, 0.12, height + 0.3, POST, Vector3(0, (height + 0.3) * 0.5, 0))
		LowPoly.solid_cylinder(post, 0.15, 2.0, Vector3(0, 1.0, 0))
		corners.append(spot + Vector3(0, height, 0))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_triangle(tool, corners[0], corners[1], corners[2], Vector3.UP)    # the top side
	_triangle(tool, corners[0], corners[1], corners[2], Vector3.DOWN)  # the side you see from below
	var sail := MeshInstance3D.new()
	sail.mesh = tool.commit()
	sail.material_override = LowPoly.material(SAIL)
	add_child(sail)


## A flat ring (like a washer) seen from above, from inner to outer radius, its top at "top",
## with a wall down the inside edge "drop" metres high (the front of a step).
func _ring(inner: float, outer: float, top: float, drop: float, colour: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in SEGMENTS:
		var a := TAU * i / SEGMENTS
		var b := TAU * (i + 1) / SEGMENTS
		var da := Vector3(cos(a), 0, sin(a))
		var db := Vector3(cos(b), 0, sin(b))
		var up := Vector3(0, top, 0)
		_quad(tool, da * inner + up, db * inner + up, db * outer + up, da * outer + up, Vector3.UP)
		if drop > 0.0:
			var low := Vector3(0, top - drop, 0)
			_quad(tool, da * inner + low, db * inner + low, db * inner + up, da * inner + up, -(da + db).normalized())
	var ring := MeshInstance3D.new()
	ring.mesh = tool.commit()
	ring.material_override = LowPoly.material(colour)
	ring.position = _centre
	add_child(ring)
	return ring


## Two triangles making a 4-cornered face that faces "normal". Godot draws a triangle's front
## when its corners go round clockwise, so the order is flipped when needed.
func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_triangle(tool, a, b, c, normal)
	_triangle(tool, a, c, d, normal)


func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var corners := [a, b, c] if (b - a).cross(c - a).dot(normal) < 0.0 else [a, c, b]
	tool.set_normal(normal)
	for corner: Vector3 in corners:
		tool.add_vertex(corner)
