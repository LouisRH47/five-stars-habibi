class_name LowPoly
## Little helpers for building low-poly decorations out of basic shapes in code:
## boxes, cylinders, spheres, and the invisible solid shapes the bike bumps into.
## Used by the Session 6 decorations (palms, cars, mosque, mini market, park).
## Each function adds the new part to "parent" and returns it.

## How shiny the parts are: 1 = completely matt.
const ROUGHNESS := 0.85

# One material per colour, shared by every part with that colour (faster to draw).
static var _materials: Dictionary = {}


## A plain matt material in this colour. Made once per colour, then shared.
static func material(colour: Color) -> StandardMaterial3D:
	if not _materials.has(colour):
		var made := StandardMaterial3D.new()
		made.albedo_color = colour
		made.roughness = ROUGHNESS
		_materials[colour] = made
	var shared: StandardMaterial3D = _materials[colour]
	return shared


## A coloured box. spot: its middle, relative to the parent.
static func box(parent: Node3D, size: Vector3, colour: Color, spot: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(colour)
	return _add_mesh(parent, mesh, spot)


## A coloured cylinder standing upright. top = 0 makes a cone. spot: its middle.
static func cylinder(parent: Node3D, top: float, bottom: float, height: float,
		colour: Color, spot: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12  # low-poly look, and cheap to draw
	mesh.rings = 1
	mesh.material = material(colour)
	return _add_mesh(parent, mesh, spot)


## A coloured ball. height smaller than 2 x radius squashes it. spot: its middle.
static func sphere(parent: Node3D, radius: float, height: float, colour: Color,
		spot: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = material(colour)
	return _add_mesh(parent, mesh, spot)


## An invisible solid box (the bike bumps into it). spot: its middle.
static func solid_box(parent: Node3D, size: Vector3, spot: Vector3) -> CollisionShape3D:
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	return _add_shape(parent, box_shape, spot)


## An invisible solid upright cylinder (the bike bumps into it). spot: its middle.
static func solid_cylinder(parent: Node3D, radius: float, height: float,
		spot: Vector3) -> CollisionShape3D:
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = radius
	cylinder_shape.height = height
	return _add_shape(parent, cylinder_shape, spot)


static func _add_mesh(parent: Node3D, mesh: Mesh, spot: Vector3) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = spot
	parent.add_child(part)
	return part


static func _add_shape(parent: Node3D, shape: Shape3D, spot: Vector3) -> CollisionShape3D:
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.position = spot
	parent.add_child(holder)
	return holder
