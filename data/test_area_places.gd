class_name TestAreaPlaces
## Data only: where the restaurants and villas stand on the flat test area.
## scripts/place_builder.gd reads this list and builds the buildings.
## To move a building, change its line here. Nothing else needs to change.
##
## position: the middle of the building, on the ground (y = 0). 1 unit = 1 metre.
## facing: which way the front door points, in degrees.
##   0 = towards +Z (the way the camera looks back at the start),
##   180 = towards -Z (the way the bike faces at the start), 90 = +X, -90 = -X.
## The 8 coloured boxes near the start (x -18..18, z -35..13) are left alone as
## obstacles, so every building here keeps well clear of them.

## Building sizes: width (across the front), height, depth (front to back).
const RESTAURANT_SIZE := Vector3(8.0, 4.5, 6.0)
const VILLA_SIZE := Vector3(8.0, 5.5, 8.0)

## Restaurants. Names are English only for now: bilingual signs come in Session 5.
const RESTAURANTS := [
	{"id": "pizza", "name": "Pizza", "food": "pizza", "position": Vector3(-35, 0, 5), "facing": 90.0},
	{"id": "gelato", "name": "Brain Freeze Gelato", "food": "ice cream", "position": Vector3(0, 0, 30), "facing": 180.0},
	{"id": "boba", "name": "Boba Oasis", "food": "bubble tea", "position": Vector3(35, 0, 5), "facing": -90.0},
]

## Villas: a row of five far ahead of the start and a row of five behind it,
## all with their doors facing the open middle of the test area.
const VILLAS := [
	{"number": 1, "position": Vector3(-40, 0, -55), "facing": 0.0},
	{"number": 2, "position": Vector3(-20, 0, -55), "facing": 0.0},
	{"number": 3, "position": Vector3(0, 0, -55), "facing": 0.0},
	{"number": 4, "position": Vector3(20, 0, -55), "facing": 0.0},
	{"number": 5, "position": Vector3(40, 0, -55), "facing": 0.0},
	{"number": 6, "position": Vector3(-40, 0, 60), "facing": 180.0},
	{"number": 7, "position": Vector3(-20, 0, 60), "facing": 180.0},
	{"number": 8, "position": Vector3(0, 0, 60), "facing": 180.0},
	{"number": 9, "position": Vector3(20, 0, 60), "facing": 180.0},
	{"number": 10, "position": Vector3(40, 0, 60), "facing": 180.0},
]
