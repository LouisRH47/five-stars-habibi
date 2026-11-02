extends StaticBody3D
## The Palm Grove mosque: a white prayer hall with a teal dome on a drum, one tall
## minaret with a balcony ring and a small golden top, a big arched door, tall arched
## windows, a stone forecourt out to the street and a bilingual sign over the door.
## The front is the +Z side. DecorBuilder places scenes/mosque.tscn and calls setup().
## The hall and the minaret are solid; the forecourt is flat, you ride over it.

const WALL_COLOUR := Color(0.97, 0.95, 0.9, 1)      # white
const TRIM_COLOUR := Color(0.91, 0.86, 0.74, 1)     # cream
const DOME_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)  # the game's teal
const GOLD_COLOUR := Color(0.85, 0.68, 0.25, 1)
const DOOR_COLOUR := Color(0.36, 0.25, 0.16, 1)     # dark wood
const WINDOW_COLOUR := Color(0.11764706, 0.25, 0.3, 1)
const FORECOURT_COLOUR := Color(0.88, 0.84, 0.76, 1)
const SIGN_COLOUR := Color(0.06, 0.38, 0.52, 1)
const TEXT_COLOUR := Color(1, 1, 1, 1)

const DOME_RADIUS := 4.5
const DRUM_HEIGHT := 1.6
const MINARET_GAP := 2.5        # metres from the hall's side wall to the minaret's middle
const MINARET_RADIUS := 1.2     # solid part
const MINARET_HEIGHT := 16.0    # the main shaft
const BALCONY_RADIUS := 1.7
const DOOR_SIZE := Vector3(3.0, 3.5, 0.2)
const WINDOW_SIZE := Vector3(1.0, 2.4, 0.15)
const FORECOURT_SIZE := Vector2(14.0, 22.0)  # width, depth (out to Ghaf Street)
const SIGN_SIZE := Vector3(9.0, 1.2, 0.15)
const SIGN_FONT_SIZE := 80


## Builds the mosque. size: the prayer hall's width, height, depth.
func setup(english: String, arabic: String, size: Vector3) -> void:
	var front := size.z * 0.5
	LowPoly.solid_box(self, size, Vector3(0, size.y * 0.5, 0))
	LowPoly.box(self, size, WALL_COLOUR, Vector3(0, size.y * 0.5, 0))
	LowPoly.box(self, Vector3(size.x + 0.4, 0.5, size.z + 0.4), TRIM_COLOUR,
			Vector3(0, size.y + 0.25, 0))
	_build_dome(size)
	_build_minaret(size)
	_build_front(english, arabic, size, front)

	# The stone forecourt from the front wall out towards the street.
	LowPoly.box(self, Vector3(FORECOURT_SIZE.x, 0.03, FORECOURT_SIZE.y), FORECOURT_COLOUR,
			Vector3(0, 0.015, front + FORECOURT_SIZE.y * 0.5))


## The dome: a ball on a round drum. Its lower half hides inside the drum and the roof.
func _build_dome(size: Vector3) -> void:
	var roof := size.y + 0.5
	LowPoly.cylinder(self, DOME_RADIUS, DOME_RADIUS, DRUM_HEIGHT, TRIM_COLOUR,
			Vector3(0, roof + DRUM_HEIGHT * 0.5, 0))
	var dome_bottom := roof + DRUM_HEIGHT
	LowPoly.sphere(self, DOME_RADIUS, DOME_RADIUS * 2.0, DOME_COLOUR, Vector3(0, dome_bottom, 0))
	# A little golden crescent post on top.
	LowPoly.cylinder(self, 0.08, 0.08, 1.2, GOLD_COLOUR, Vector3(0, dome_bottom + DOME_RADIUS + 0.5, 0))
	LowPoly.sphere(self, 0.25, 0.5, GOLD_COLOUR, Vector3(0, dome_bottom + DOME_RADIUS + 1.2, 0))


## The minaret: a tall round tower by the east side of the hall, towards the back.
func _build_minaret(size: Vector3) -> void:
	var spot := Vector3(size.x * 0.5 + MINARET_GAP, 0, -size.z * 0.25)
	LowPoly.solid_cylinder(self, MINARET_RADIUS, MINARET_HEIGHT, spot + Vector3(0, MINARET_HEIGHT * 0.5, 0))
	LowPoly.cylinder(self, MINARET_RADIUS, MINARET_RADIUS, MINARET_HEIGHT, WALL_COLOUR,
			spot + Vector3(0, MINARET_HEIGHT * 0.5, 0))
	# The balcony ring where the call to prayer was made, then a thinner top part.
	LowPoly.cylinder(self, BALCONY_RADIUS, BALCONY_RADIUS, 0.4, TRIM_COLOUR,
			spot + Vector3(0, MINARET_HEIGHT - 3.0, 0))
	var upper := MINARET_RADIUS * 0.75
	LowPoly.cylinder(self, upper, upper, 3.0, WALL_COLOUR, spot + Vector3(0, MINARET_HEIGHT + 1.5, 0))
	LowPoly.cylinder(self, upper + 0.15, upper + 0.15, 0.3, TRIM_COLOUR,
			spot + Vector3(0, MINARET_HEIGHT + 3.15, 0))
	# A small teal cone and a golden tip on top.
	LowPoly.cylinder(self, 0.0, upper + 0.1, 2.2, DOME_COLOUR, spot + Vector3(0, MINARET_HEIGHT + 4.4, 0))
	LowPoly.sphere(self, 0.18, 0.36, GOLD_COLOUR, spot + Vector3(0, MINARET_HEIGHT + 5.6, 0))


## The front wall: an arched door, arched windows and the sign over the door.
func _build_front(english: String, arabic: String, size: Vector3, front: float) -> void:
	var z := front + DOOR_SIZE.z * 0.5
	LowPoly.box(self, DOOR_SIZE, DOOR_COLOUR, Vector3(0, DOOR_SIZE.y * 0.5, z))
	_add_arch_top(DOOR_SIZE, DOOR_COLOUR, Vector3(0, DOOR_SIZE.y, z))
	for x: float in [-6.0, -3.6, 3.6, 6.0]:
		var bottom := 1.2
		LowPoly.box(self, WINDOW_SIZE, WINDOW_COLOUR, Vector3(x, bottom + WINDOW_SIZE.y * 0.5, front + 0.075))
		_add_arch_top(WINDOW_SIZE, WINDOW_COLOUR, Vector3(x, bottom + WINDOW_SIZE.y, front + 0.075))

	# The sign board above the door: Arabic on top, English below.
	var board_y := size.y - SIGN_SIZE.y * 0.5 - 0.5
	LowPoly.box(self, SIGN_SIZE, SIGN_COLOUR, Vector3(0, board_y, front + SIGN_SIZE.z * 0.5))
	var font_size := SignText.fit_size(arabic, english, SIGN_FONT_SIZE, SIGN_SIZE.x - 0.6)
	var face := SignText.make_face(arabic, english, font_size, TEXT_COLOUR)
	face.name = "Sign"
	face.position = Vector3(0, board_y, front + SIGN_SIZE.z + 0.01)
	add_child(face)


## A half-round top on a door or window: a flat disc facing forwards (+Z).
## The lower half of the disc hides behind the door or window it sits on.
func _add_arch_top(opening: Vector3, colour: Color, spot: Vector3) -> void:
	var radius := opening.x * 0.5
	var arch := LowPoly.cylinder(self, radius, radius, opening.z, colour, spot)
	arch.rotation.x = PI * 0.5
