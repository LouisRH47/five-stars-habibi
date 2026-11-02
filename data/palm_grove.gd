class_name PalmGrove
## Data only: the Palm Grove villa community (the Tier 1 map).
## scripts/map_builder.gd builds the ground, roads, roundabout and walls from this list,
## scripts/place_builder.gd builds the restaurants and villas, and
## scripts/sign_builder.gd builds the street-name signs and the welcome sign.
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

## Roads: a name in English and Arabic (for the street signs) and the two ends of its
## middle line. The x/y of each Vector2 here are the world x and z.
## scripts/sign_builder.gd puts a street-name sign near each end of every road.
const ROADS := [
	{"name": "Palm Grove Avenue", "arabic": "جادة بستان النخيل", "from": Vector2(0, 150), "to": Vector2(0, -90)},
	{"name": "Ghaf Street", "arabic": "شارع الغاف", "from": Vector2(-90, -90), "to": Vector2(90, -90)},
	{"name": "Oasis Street", "arabic": "شارع الواحة", "from": Vector2(-90, 0), "to": Vector2(90, 0)},
	{"name": "Date Palm Street", "arabic": "شارع نخلة التمر", "from": Vector2(-90, 90), "to": Vector2(90, 90)},
	{"name": "West Lane", "arabic": "السكة الغربية", "from": Vector2(-90, -90), "to": Vector2(-90, 90)},
	{"name": "East Lane", "arabic": "السكة الشرقية", "from": Vector2(90, -90), "to": Vector2(90, 90)},
]

## The big welcome sign just inside the gate, ahead on the right as you start.
## facing: which way the front of the sign points (0 = south, towards the gate).
const WELCOME_SIGN := {
	"name": "Welcome to Palm Grove",
	"arabic": "أهلاً بكم في بستان النخيل",
	"position": Vector3(9.5, 0, 129),
	"facing": 0.0,
}

## Every restaurant is the same size: width (along the road), height, depth.
const RESTAURANT_SIZE := Vector3(10.0, 5.0, 8.0)
const VILLA_SIZE := Vector3(12.0, 6.5, 12.0)

## The restaurant strip just inside the entrance, on the west side of Palm Grove Avenue,
## shop fronts facing the road. arabic: the Arabic name on the signs. colour: the brand colour.
const RESTAURANTS := [
	{"id": "pizza", "name": "Pizza", "arabic": "بيتزا", "food": "pizza",
			"colour": Color(0.8, 0.2, 0.15, 1), "position": Vector3(-10.5, 0, 137), "facing": 90.0},
	{"id": "gelato", "name": "Brain Freeze Gelato", "arabic": "برين فريز جيلاتو", "food": "ice cream",
			"colour": Color(0.86, 0.33, 0.56, 1), "position": Vector3(-10.5, 0, 127), "facing": 90.0},
	{"id": "boba", "name": "Boba Oasis", "arabic": "واحة البوبا", "food": "bubble tea",
			"colour": Color(0.47, 0.3, 0.66, 1), "position": Vector3(-10.5, 0, 117), "facing": 90.0},
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
