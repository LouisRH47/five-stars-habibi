extends StaticBody3D
## One parked car: a low-poly body, a cabin with dark windows, four dark wheels and
## lights front and back. It's solid (one box), so the bike bumps into it.
## The nose is the +Z side (like the front of a villa), so "facing" in the data list
## is the way the car points.
## DecorBuilder places one of these (scenes/parked_car.tscn) for every car in the
## data list and calls setup().

## Light car colours, picked by the car's number so neighbours differ.
const BODY_COLOURS := [
	Color(0.96, 0.96, 0.94, 1),  # white
	Color(0.78, 0.8, 0.82, 1),   # silver
	Color(0.85, 0.78, 0.62, 1),  # champagne
	Color(0.6, 0.75, 0.86, 1),   # light blue
	Color(0.88, 0.45, 0.38, 1),  # coral red
	Color(0.55, 0.7, 0.6, 1),    # sage green
]
const GLASS_COLOUR := Color(0.15, 0.22, 0.28, 1)
const WHEEL_COLOUR := Color(0.12, 0.12, 0.13, 1)
const HEADLIGHT_COLOUR := Color(1, 0.97, 0.8, 1)
const TAILLIGHT_COLOUR := Color(0.8, 0.1, 0.1, 1)

const WHEEL_RADIUS := 0.33
const WHEEL_WIDTH := 0.25
const BODY_HEIGHT := 0.65    # the lower part of the car
const CABIN_HEIGHT := 0.55   # the roof part with the windows


## Builds the car. size: width, height, length in metres (from the data list).
## colour_index: picks the body colour.
func setup(size: Vector3, colour_index: int) -> void:
	var body_colour: Color = BODY_COLOURS[colour_index % BODY_COLOURS.size()]
	var body_bottom := WHEEL_RADIUS * 0.6

	# One solid box for the whole car.
	LowPoly.solid_box(self, size, Vector3(0, size.y * 0.5, 0))

	# Body and cabin. The cabin sits a little towards the back, like a real car.
	var body := Vector3(size.x - 0.1, BODY_HEIGHT, size.z)
	LowPoly.box(self, body, body_colour, Vector3(0, body_bottom + BODY_HEIGHT * 0.5, 0))
	var cabin_y := body_bottom + BODY_HEIGHT + CABIN_HEIGHT * 0.5
	var cabin := Vector3(size.x - 0.35, CABIN_HEIGHT, size.z * 0.5)
	LowPoly.box(self, cabin, body_colour, Vector3(0, cabin_y, -size.z * 0.06))
	# Dark windows: a band just bigger than the cabin, but a bit lower than its roof.
	var glass := Vector3(cabin.x + 0.04, CABIN_HEIGHT * 0.6, cabin.z + 0.04)
	LowPoly.box(self, glass, GLASS_COLOUR, Vector3(0, cabin_y - 0.02, -size.z * 0.06))

	# Four wheels, lying on their side (turned a quarter around Z).
	var wheel_x := size.x * 0.5 - WHEEL_WIDTH * 0.5
	var wheel_z := size.z * 0.5 - 0.8
	for side: float in [-1.0, 1.0]:
		for end: float in [-1.0, 1.0]:
			var wheel := LowPoly.cylinder(self, WHEEL_RADIUS, WHEEL_RADIUS, WHEEL_WIDTH,
					WHEEL_COLOUR, Vector3(wheel_x * side, WHEEL_RADIUS, wheel_z * end))
			wheel.rotation.z = PI * 0.5

	# Lights: two at the front (+Z), two red ones at the back.
	var light_y := body_bottom + BODY_HEIGHT * 0.65
	var light := Vector3(0.35, 0.15, 0.06)
	for side: float in [-1.0, 1.0]:
		var light_x := (size.x * 0.5 - 0.35) * side
		LowPoly.box(self, light, HEADLIGHT_COLOUR, Vector3(light_x, light_y, size.z * 0.5 + 0.02))
		LowPoly.box(self, light, TAILLIGHT_COLOUR, Vector3(light_x, light_y, -size.z * 0.5 - 0.02))
