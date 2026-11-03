extends StaticBody3D
## One date palm: a slightly leaning trunk made of stacked, narrowing pieces, a crown of
## drooping green fronds and a few bunches of dates. Only the bottom of the trunk is
## solid, so you bump into it but ride under the fronds.
## DecorBuilder places one of these (scenes/palm_tree.tscn) for every palm in the data
## list and calls setup().

const TRUNK_COLOUR := Color(0.55, 0.42, 0.28, 1)    # brown bark
const TRUNK_RING_COLOUR := Color(0.47, 0.35, 0.23, 1)
const FROND_COLOUR := Color(0.27, 0.55, 0.24, 1)    # palm green
const FROND_DARK_COLOUR := Color(0.2, 0.45, 0.2, 1)
const DATE_COLOUR := Color(0.75, 0.42, 0.12, 1)     # orange-brown dates

const TRUNK_PIECES := 4
const TRUNK_HEIGHT := 5.5        # metres, the shortest palm (others are a bit taller)
const TRUNK_BOTTOM_RADIUS := 0.28
const TRUNK_TOP_RADIUS := 0.16
const LEAN := 0.12               # metres each trunk piece shifts sideways
const FRONDS := 7
const FROND_SIZE := Vector3(0.55, 0.05, 2.8)  # width, thickness, length
const FROND_DROOP_DEG := 28.0    # how far the fronds hang down
const SOLID_RADIUS := 0.35       # the part you bump into (data checks use this too)
const SOLID_HEIGHT := 2.0

static var _shared_crown: ArrayMesh

## Builds the palm. variant: any whole number; it changes the height, lean and turn a
## little, so a row of palms doesn't look copy-pasted.
func setup(variant: int) -> void:
	var height := TRUNK_HEIGHT + float(variant % 3) * 0.6
	var lean_angle := float(variant) * 2.4  # radians, a different way for each palm
	var lean := Vector3(cos(lean_angle), 0.0, sin(lean_angle)) * LEAN
	var piece := height / TRUNK_PIECES

	# Solid bottom of the trunk.
	LowPoly.solid_cylinder(self, SOLID_RADIUS, SOLID_HEIGHT, Vector3(0, SOLID_HEIGHT * 0.5, 0))

	# The trunk: stacked pieces, each a bit thinner and shifted sideways (the lean).
	for i in TRUNK_PIECES:
		var bottom := lerpf(TRUNK_BOTTOM_RADIUS, TRUNK_TOP_RADIUS, float(i) / TRUNK_PIECES)
		var top := lerpf(TRUNK_BOTTOM_RADIUS, TRUNK_TOP_RADIUS, float(i + 1) / TRUNK_PIECES)
		var middle := lean * float(i) + Vector3(0, piece * (float(i) + 0.5), 0)
		LowPoly.cylinder(self, top, bottom, piece, TRUNK_COLOUR, middle)
		# A darker ring where two pieces meet, like the bark of a real palm.
		LowPoly.cylinder(self, top + 0.03, top + 0.03, 0.08, TRUNK_RING_COLOUR,
				middle + Vector3(0, piece * 0.5, 0))

	# The crown: fronds spread out in a circle and droop down.
	var crown := MeshInstance3D.new()
	crown.name = "Crown"
	crown.mesh = _crown_mesh()
	crown.position = lean * float(TRUNK_PIECES - 1) + Vector3(0, height, 0)
	crown.rotation.y = float(variant) * 0.7
	add_child(crown)


## Each crown sways as a unit. Share the original geometry in one mesh with three materials.
static func _crown_mesh() -> ArrayMesh:
	if _shared_crown != null:
		return _shared_crown
	_shared_crown = ArrayMesh.new()
	var frond := BoxMesh.new()
	frond.size = FROND_SIZE
	var bunch := SphereMesh.new()
	bunch.radial_segments = 12
	bunch.rings = 6
	bunch.radius = 0.3
	bunch.height = 0.4
	for shade in 2:
		var leaves := SurfaceTool.new()
		leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(shade, FRONDS, 2):
			var droop := deg_to_rad(FROND_DROOP_DEG + float(shade) * 10.0)
			var turn := Basis.from_euler(Vector3(droop, TAU * float(i) / FRONDS, 0.0))
			var middle := turn * Vector3(0, 0, FROND_SIZE.z * 0.5)
			leaves.append_from(frond, 0, Transform3D(turn, middle))
		if shade == 1:
			leaves.append_from(bunch, 0, Transform3D.IDENTITY)
		leaves.set_material(LowPoly.material(FROND_COLOUR if shade == 0 else FROND_DARK_COLOUR))
		leaves.commit(_shared_crown)
	bunch.radius = 0.18
	bunch.height = 0.3
	var dates := SurfaceTool.new()
	dates.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var turn := TAU * float(i) / 3.0
		var middle := Vector3(cos(turn) * 0.32, -0.3, sin(turn) * 0.32)
		dates.append_from(bunch, 0, Transform3D(Basis.IDENTITY, middle))
	dates.set_material(LowPoly.material(DATE_COLOUR))
	dates.commit(_shared_crown)
	return _shared_crown
