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
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = lean * float(TRUNK_PIECES - 1) + Vector3(0, height, 0)
	crown.rotation.y = float(variant) * 0.7
	add_child(crown)
	for i in FRONDS:
		var pivot := Node3D.new()
		# Each frond turns around the top of the trunk, then tips down.
		var droop := deg_to_rad(FROND_DROOP_DEG + float(i % 2) * 10.0)
		pivot.rotation = Vector3(droop, TAU * float(i) / FRONDS, 0.0)
		crown.add_child(pivot)
		var colour := FROND_COLOUR if i % 2 == 0 else FROND_DARK_COLOUR
		LowPoly.box(pivot, FROND_SIZE, colour, Vector3(0, 0, FROND_SIZE.z * 0.5))
	LowPoly.sphere(crown, 0.3, 0.4, FROND_DARK_COLOUR, Vector3.ZERO)

	# Three bunches of dates hanging under the crown.
	for i in 3:
		var turn := TAU * float(i) / 3.0
		LowPoly.sphere(crown, 0.18, 0.3, DATE_COLOUR,
				Vector3(cos(turn) * 0.32, -0.3, sin(turn) * 0.32))
