class_name MeshKit
extends RefCounted
## Builds ONE mesh out of many coloured boxes, cylinders and balls (Session 26).
## Each part's colour is stored on its corners ("vertex colours"), so the whole house is
## drawn in one go with one shared material. That keeps 60 detailed homes fast.
## Use: var kit := MeshKit.new(); kit.box(...); kit.cylinder(...); var view := kit.finish()

## How shiny the parts are: 1 = completely matt (same as LowPoly).
const ROUGHNESS := 0.85

# The one material every MeshKit mesh shares: it uses the corner colours.
static var _shared: StandardMaterial3D = null

var _tool := SurfaceTool.new()
var _parts := 0


func _init() -> void:
	_tool.begin(Mesh.PRIMITIVE_TRIANGLES)


## A box. size: width, height, depth. spot: its middle. turn: an optional rotation.
func box(size: Vector3, colour: Color, spot: Vector3, turn := Basis()) -> void:
	var h := size * 0.5
	# Each side: which way it points, and two directions along it.
	var sides := [[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.BACK],
			[Vector3.UP, Vector3.RIGHT, Vector3.BACK], [Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
			[Vector3.BACK, Vector3.RIGHT, Vector3.UP], [Vector3.FORWARD, Vector3.RIGHT, Vector3.UP]]
	for side in sides:
		var n: Vector3 = side[0]
		var u: Vector3 = side[1] * absf((side[1] as Vector3).dot(h))
		var v: Vector3 = side[2] * absf((side[2] as Vector3).dot(h))
		var middle: Vector3 = n * absf(n.dot(h))
		_quad([middle - u - v, middle + u - v, middle + u + v, middle - u + v], n, colour, spot, turn)
	_parts += 1


## An upright cylinder (top = 0 makes a cone). spot: its middle. turn: optional rotation.
func cylinder(top: float, bottom: float, height: float, colour: Color, spot: Vector3,
		turn := Basis(), segments := 8) -> void:
	var y := height * 0.5
	for i in segments:
		var a := TAU * i / segments
		var b := TAU * (i + 1) / segments
		var da := Vector3(cos(a), 0, sin(a))
		var db := Vector3(cos(b), 0, sin(b))
		var out := (da + db).normalized()
		_quad([da * bottom + Vector3.DOWN * y, db * bottom + Vector3.DOWN * y,
				db * top + Vector3.UP * y, da * top + Vector3.UP * y], out, colour, spot, turn)
		_tri([Vector3.UP * y, da * top + Vector3.UP * y, db * top + Vector3.UP * y], Vector3.UP, colour, spot, turn)
		_tri([Vector3.DOWN * y, da * bottom + Vector3.DOWN * y, db * bottom + Vector3.DOWN * y], Vector3.DOWN, colour, spot, turn)
	_parts += 1


## A low-poly ball. squash < 1 makes it flatter. spot: its middle.
func ball(radius: float, colour: Color, spot: Vector3, squash := 1.0) -> void:
	var rings := 4
	var around := 8
	for r in rings:
		var t0 := PI * r / rings
		var t1 := PI * (r + 1) / rings
		for i in around:
			var a := TAU * i / around
			var b := TAU * (i + 1) / around
			var corners: Array[Vector3] = [_on_ball(t0, a), _on_ball(t0, b), _on_ball(t1, b), _on_ball(t1, a)]
			var out := (corners[0] + corners[1] + corners[2] + corners[3]).normalized()
			for k in 4:
				corners[k] = Vector3(corners[k].x, corners[k].y * squash, corners[k].z) * radius
			_quad(corners, out, colour, spot, Basis())
	_parts += 1


## How many parts went in (for the smoke test).
func part_count() -> int:
	return _parts


## Turns everything into one MeshInstance3D (not yet added to the scene).
func finish(view_name := "Look") -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.name = view_name
	view.mesh = _tool.commit()
	view.material_override = material()
	return view


## The shared material: matt, coloured by the corner colours.
static func material() -> StandardMaterial3D:
	if _shared == null:
		_shared = StandardMaterial3D.new()
		_shared.vertex_color_use_as_albedo = true
		_shared.vertex_color_is_srgb = true
		_shared.roughness = ROUGHNESS
	return _shared


func _on_ball(t: float, a: float) -> Vector3:
	return Vector3(sin(t) * cos(a), cos(t), sin(t) * sin(a))


## A four-cornered face, as two triangles.
func _quad(c: Array, n: Vector3, colour: Color, spot: Vector3, turn: Basis) -> void:
	_tri([c[0], c[1], c[2]], n, colour, spot, turn)
	_tri([c[0], c[2], c[3]], n, colour, spot, turn)


## One triangle facing direction n. The corners are put in the order Godot wants for a
## face you can see from the outside.
func _tri(c: Array, n: Vector3, colour: Color, spot: Vector3, turn: Basis) -> void:
	var a: Vector3 = turn * c[0] + spot
	var b: Vector3 = turn * c[1] + spot
	var d: Vector3 = turn * c[2] + spot
	var normal := (turn * n).normalized()
	if (b - a).cross(d - a).dot(normal) > 0.0:
		var swap := b
		b = d
		d = swap
	_tool.set_color(colour)
	_tool.set_normal(normal)
	for corner in [a, b, d]:
		_tool.add_vertex(corner)
