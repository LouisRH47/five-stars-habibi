class_name PalmGrove
## Data only: the Palm Grove villa community (the Tier 1 map).
## scripts/map_builder.gd builds the ground, roads, roundabout and walls from this list,
## and scripts/place_builder.gd builds the restaurants and villas.
## To move a villa or a road, change its line here. Nothing else needs to change.
##
## Positions are in metres (1 Godot unit = 1 metre). x runs west (-) to east (+),
## z runs north (-) to south (+). The entrance gate is in the south wall.
## facing: which way the front door points, in degrees.
##   0 = south (+Z), 180 = north (-Z), 90 = east (+X), -90 = west (-X).
## Sizes: width (across the front), height, depth (front to back).

## Half the width of the whole community: the walls stand at -150 and +150.
const HALF_SIZE := 150.0
const ROAD_WIDTH := 8.0
const WALL_HEIGHT := 2.5
## The gap in the south wall where the entrance gate is (x from -GATE_HALF_WIDTH to +GATE_HALF_WIDTH).
const GATE_HALF_WIDTH := 6.0

## The roundabout in the middle, where Palm Grove Avenue crosses Oasis Street.
const ROUNDABOUT_CENTRE := Vector2(0, 0)
const ROUNDABOUT_RADIUS := 16.0       # outer edge of the road ring
const ROUNDABOUT_ISLAND_RADIUS := 8.0 # the raised grass island you ride around

## Roads: a name (for street signs in Session 5) and the two ends of its middle line.
## The x/y of each Vector2 here are the world x and z.
const ROADS := [
	{"name": "Palm Grove Avenue", "from": Vector2(0, 150), "to": Vector2(0, -90)},
	{"name": "Ghaf Street", "from": Vector2(-90, -90), "to": Vector2(90, -90)},
	{"name": "Oasis Street", "from": Vector2(-90, 0), "to": Vector2(90, 0)},
	{"name": "Date Palm Street", "from": Vector2(-90, 90), "to": Vector2(90, 90)},
	{"name": "West Lane", "from": Vector2(-90, -90), "to": Vector2(-90, 90)},
	{"name": "East Lane", "from": Vector2(90, -90), "to": Vector2(90, 90)},
]

const RESTAURANT_SIZE := Vector3(8.0, 4.5, 6.0)
const VILLA_SIZE := Vector3(12.0, 6.5, 12.0)

## The restaurant strip just inside the entrance, on the west side of Palm Grove Avenue.
## Names are English only for now: bilingual signs come in Session 5.
const RESTAURANTS := [
	{"id": "pizza", "name": "Pizza", "food": "pizza", "position": Vector3(-8, 0, 136), "facing": 90.0},
	{"id": "gelato", "name": "Brain Freeze Gelato", "food": "ice cream", "position": Vector3(-8, 0, 124), "facing": 90.0},
	{"id": "boba", "name": "Boba Oasis", "food": "bubble tea", "position": Vector3(-8, 0, 112), "facing": 90.0},
]

## Villas, numbered street by street, starting nearest the entrance.
const VILLAS := [
	{"number": 1, "position": Vector3(-76, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 2, "position": Vector3(-58, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 3, "position": Vector3(-40, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 4, "position": Vector3(-22, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 5, "position": Vector3(22, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 6, "position": Vector3(40, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 7, "position": Vector3(58, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 8, "position": Vector3(76, 0, 104), "facing": 180.0, "street": "Date Palm Street"},
	{"number": 9, "position": Vector3(-76, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 10, "position": Vector3(-58, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 11, "position": Vector3(-40, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 12, "position": Vector3(-22, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 13, "position": Vector3(22, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 14, "position": Vector3(40, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 15, "position": Vector3(58, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 16, "position": Vector3(76, 0, 76), "facing": 0.0, "street": "Date Palm Street"},
	{"number": 17, "position": Vector3(-76, 0, 14), "facing": 180.0, "street": "Oasis Street"},
	{"number": 18, "position": Vector3(-58, 0, 14), "facing": 180.0, "street": "Oasis Street"},
	{"number": 19, "position": Vector3(-40, 0, 14), "facing": 180.0, "street": "Oasis Street"},
	{"number": 20, "position": Vector3(40, 0, 14), "facing": 180.0, "street": "Oasis Street"},
	{"number": 21, "position": Vector3(58, 0, 14), "facing": 180.0, "street": "Oasis Street"},
	{"number": 22, "position": Vector3(76, 0, 14), "facing": 180.0, "street": "Oasis Street"},
	{"number": 23, "position": Vector3(-76, 0, -14), "facing": 0.0, "street": "Oasis Street"},
	{"number": 24, "position": Vector3(-58, 0, -14), "facing": 0.0, "street": "Oasis Street"},
	{"number": 25, "position": Vector3(-40, 0, -14), "facing": 0.0, "street": "Oasis Street"},
	{"number": 26, "position": Vector3(40, 0, -14), "facing": 0.0, "street": "Oasis Street"},
	{"number": 27, "position": Vector3(58, 0, -14), "facing": 0.0, "street": "Oasis Street"},
	{"number": 28, "position": Vector3(76, 0, -14), "facing": 0.0, "street": "Oasis Street"},
	{"number": 29, "position": Vector3(-76, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 30, "position": Vector3(-58, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 31, "position": Vector3(-40, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 32, "position": Vector3(-22, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 33, "position": Vector3(22, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 34, "position": Vector3(40, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 35, "position": Vector3(58, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
	{"number": 36, "position": Vector3(76, 0, -76), "facing": 180.0, "street": "Ghaf Street"},
]
