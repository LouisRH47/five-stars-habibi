extends Node3D
## Builds the Palm Grove map when the game starts: sandy ground, roads, the roundabout,
## the community wall and the entrance gate. Everything comes from the data list in
## data/palm_grove.gd. Buildings (villas, restaurants) are made by PlaceBuilder.
## Roads are flat and have no collision: the bike rides on the ground underneath.

const GROUND_COLOUR := Color(0.9098039, 0.827451, 0.6509804, 1)  # sand
const ROAD_COLOUR := Color(0.32, 0.33, 0.35, 1)                 # asphalt grey
const ISLAND_COLOUR := Color(0.45, 0.65, 0.35, 1)               # grass
const WALL_COLOUR := Color(0.95, 0.88, 0.74, 1)                 # light sandstone
const GATE_COLOUR := Color(0.85, 0.2, 0.2, 1)                   # red barrier
const GROUND_MARGIN := 20.0     # extra sand outside the walls, metres
const ROAD_THICKNESS := 0.04    # roads sit this far above the ground
const ISLAND_HEIGHT := 0.4
const WALL_THICKNESS := 0.6
const GATE_BAR_HEIGHT := 1.2


func _ready() -> void:
	_build_ground()
	for road in PalmGrove.ROADS:
		_build_road(road["from"], road["to"])
	_build_roundabout()
	_build_walls()


func _build_ground() -> void:
	var side := PalmGrove.HALF_SIZE * 2.0 + GROUND_MARGIN * 2.0
	_add_block(Vector3(side, 1.0, side), GROUND_COLOUR, Vector3(0, -0.5, 0), true)


## A road is a long flat strip from one end of its middle line to the other.
## It is made one road-width longer so corners and crossings are filled in.
func _build_road(from: Vector2, to: Vector2) -> void:
	var length := from.distance_to(to) + PalmGrove.ROAD_WIDTH
	var middle := (from + to) * 0.5
	var strip := _add_block(Vector3(PalmGrove.ROAD_WIDTH, ROAD_THICKNESS, length), ROAD_COLOUR,
			Vector3(middle.x, ROAD_THICKNESS * 0.5, middle.y), false)
	var direction := to - from
	strip.rotation.y = atan2(direction.x, direction.y)


func _build_roundabout() -> void:
	var centre := PalmGrove.ROUNDABOUT_CENTRE
	# The road ring, a tiny bit higher than the roads so the two don't flicker.
	var ring := CylinderMesh.new()
	ring.top_radius = PalmGrove.ROUNDABOUT_RADIUS
	ring.bottom_radius = PalmGrove.ROUNDABOUT_RADIUS
	ring.height = ROAD_THICKNESS * 1.5
	ring.material = _material(ROAD_COLOUR)
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.mesh = ring
	ring_mesh.position = Vector3(centre.x, ring.height * 0.5, centre.y)
	add_child(ring_mesh)

	# The grass island in the middle is solid: you ride around it.
	var island := StaticBody3D.new()
	island.position = Vector3(centre.x, ISLAND_HEIGHT * 0.5, centre.y)
	add_child(island)
	var cylinder := CylinderShape3D.new()
	cylinder.radius = PalmGrove.ROUNDABOUT_ISLAND_RADIUS
	cylinder.height = ISLAND_HEIGHT
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	island.add_child(shape)
	var grass := CylinderMesh.new()
	grass.top_radius = PalmGrove.ROUNDABOUT_ISLAND_RADIUS
	grass.bottom_radius = PalmGrove.ROUNDABOUT_ISLAND_RADIUS
	grass.height = ISLAND_HEIGHT
	grass.material = _material(ISLAND_COLOUR)
	var grass_mesh := MeshInstance3D.new()
	grass_mesh.mesh = grass
	island.add_child(grass_mesh)


## Four walls around the community, with a gap in the south wall closed by a red gate bar.
func _build_walls() -> void:
	var h := PalmGrove.HALF_SIZE
	var gap := PalmGrove.GATE_HALF_WIDTH
	var y := PalmGrove.WALL_HEIGHT * 0.5
	var full := h * 2.0 + WALL_THICKNESS
	_add_block(Vector3(full, PalmGrove.WALL_HEIGHT, WALL_THICKNESS), WALL_COLOUR, Vector3(0, y, -h), true)
	_add_block(Vector3(WALL_THICKNESS, PalmGrove.WALL_HEIGHT, full), WALL_COLOUR, Vector3(-h, y, 0), true)
	_add_block(Vector3(WALL_THICKNESS, PalmGrove.WALL_HEIGHT, full), WALL_COLOUR, Vector3(h, y, 0), true)
	# South wall: two pieces, one each side of the gate.
	var piece := h - gap
	var piece_x := gap + piece * 0.5
	_add_block(Vector3(piece, PalmGrove.WALL_HEIGHT, WALL_THICKNESS), WALL_COLOUR, Vector3(-piece_x, y, h), true)
	_add_block(Vector3(piece, PalmGrove.WALL_HEIGHT, WALL_THICKNESS), WALL_COLOUR, Vector3(piece_x, y, h), true)
	# The gate is closed for now: Palm Grove is your whole world in Tier 1.
	_add_block(Vector3(gap * 2.0, GATE_BAR_HEIGHT, WALL_THICKNESS), GATE_COLOUR,
			Vector3(0, GATE_BAR_HEIGHT * 0.5, h), true)


## A coloured box at a spot. With solid = true the bike bumps into it.
func _add_block(size: Vector3, colour: Color, spot: Vector3, solid: bool) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(colour)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	if not solid:
		view.position = spot
		add_child(view)
		return view
	var body := StaticBody3D.new()
	body.position = spot
	add_child(body)
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)
	body.add_child(view)
	return body


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material
