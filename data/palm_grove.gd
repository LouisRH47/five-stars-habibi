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


# --- Session 6: decoration and static obstacles ---
# scripts/decor_builder.gd builds everything below. Free land used: the band north of
# Ghaf Street (the park and the mosque), the corner east of the avenue by the gate (the
# supermarket and its car park), the avenue's sides and the roundabout island (palms) and
# the driveway strips between villas and their street (parked cars).
# Nothing here may stand in the bike's test lane up the avenue (x 0.5 to 3.5, z 90 to 145).

## The mosque, north of Ghaf Street on the avenue's line, its front facing south (0)
## towards Ghaf Street. size: the prayer hall's width, height, depth. The dome sits on top,
## the minaret stands at its east side and a stone forecourt runs to the street.
const MOSQUE := {
	"name": "Palm Grove Mosque",
	"arabic": "مسجد بستان النخيل",
	"position": Vector3(0, 0, -124),
	"facing": 0.0,
	"size": Vector3(18.0, 7.0, 14.0),
}

## The mini market east of the avenue near the gate. Its front faces west (-90), onto its
## car park, which opens onto the avenue by a short driveway south of the welcome sign.
const SUPERMARKET := {
	"name": "Al Sarab Mini Market",
	"arabic": "ميني ماركت السراب",
	"position": Vector3(42, 0, 132),
	"facing": -90.0,
	"size": Vector3(16.0, 5.0, 12.0),
}

## Flat asphalt for car parks and driveways (no collision, you ride over them).
## Rect2(x, z, width along x, depth along z): x/z is the north-west corner.
const PARKING_AREAS := [
	Rect2(15, 114, 19, 33),   # mini market car park (x 15 to 34, z 114 to 147)
	Rect2(4, 137, 11, 8),     # driveway from the avenue into the car park (south of the welcome sign)
	Rect2(16, -114, 10, 18),  # mosque car park (x 16 to 26, z -114 to -96)
]

## Every parked car is this big: width, height, length (the bumper-to-bumper length is z).
const PARKED_CAR_SIZE := Vector3(1.9, 1.5, 4.3)

## Parked cars. facing: which way the car's nose points (same angles as villas).
## bay: true draws white parking-bay lines around it (car parks only).
## Driveway cars stand parallel to their street in the strip between the road edge and the
## villa, at least 2 m away from the door spot so you can still reach the door.
const PARKED_CARS := [
	# Mini market car park: one row of 4 and one of 2, noses pointing east.
	{"position": Vector3(20.5, 0, 117), "facing": 90.0, "bay": true},
	{"position": Vector3(20.5, 0, 120), "facing": 90.0, "bay": true},
	{"position": Vector3(20.5, 0, 123), "facing": 90.0, "bay": true},
	{"position": Vector3(20.5, 0, 126), "facing": 90.0, "bay": true},
	{"position": Vector3(29.5, 0, 117), "facing": -90.0, "bay": true},
	{"position": Vector3(29.5, 0, 123), "facing": -90.0, "bay": true},
	# Mosque car park.
	{"position": Vector3(21, 0, -104), "facing": 90.0, "bay": true},
	{"position": Vector3(21, 0, -107), "facing": 90.0, "bay": true},
	{"position": Vector3(21, 0, -110), "facing": 90.0, "bay": true},
	# Villa driveways, beside villas 2, 6, 11, 15, 24, 21 and 34.
	{"position": Vector3(-53.5, 0, 96), "facing": 90.0, "bay": false},
	{"position": Vector3(44.5, 0, 96), "facing": -90.0, "bay": false},
	{"position": Vector3(-35.5, 0, 84), "facing": 90.0, "bay": false},
	{"position": Vector3(62.5, 0, 84), "facing": -90.0, "bay": false},
	{"position": Vector3(-53.5, 0, -6), "facing": -90.0, "bay": false},
	{"position": Vector3(62.5, 0, 6), "facing": 90.0, "bay": false},
	{"position": Vector3(44.5, 0, -84), "facing": 90.0, "bay": false},
]

## Every speed bump is this big: width (right across the road), height, depth (along the road).
const SPEED_BUMP_SIZE := Vector3(8.0, 0.12, 0.5)

## Speed bumps, each at least 12 m from any crossing or the roundabout and away from doors.
## facing: the way you ride over it. 0 = on a north-south road, 90 = on an east-west road.
## None on the avenue near the gate (z 85 to 150): the smoke test rides there.
## The smoke test rides over the FIRST bump in this list.
const SPEED_BUMPS := [
	{"position": Vector3(-49, 0, 0), "facing": 90.0},    # Oasis Street, west
	{"position": Vector3(49, 0, 0), "facing": 90.0},     # Oasis Street, east
	{"position": Vector3(-49, 0, 90), "facing": 90.0},   # Date Palm Street, west
	{"position": Vector3(49, 0, 90), "facing": 90.0},    # Date Palm Street, east
	{"position": Vector3(-49, 0, -90), "facing": 90.0},  # Ghaf Street, west
	{"position": Vector3(49, 0, -90), "facing": 90.0},   # Ghaf Street, east
	{"position": Vector3(-90, 0, -45), "facing": 0.0},   # West Lane
	{"position": Vector3(90, 0, 45), "facing": 0.0},     # East Lane
	{"position": Vector3(0, 0, 50), "facing": 0.0},      # Palm Grove Avenue, south of the roundabout
	{"position": Vector3(0, 0, -50), "facing": 0.0},     # Palm Grove Avenue, north of the roundabout
]

## Palm trees. y is the height of the ground they stand on (0.4 on the roundabout island).
const PALM_TREES := [
	# Palm Grove Avenue, both sides, between the roundabout and Date Palm Street.
	Vector3(-5.5, 0, 24), Vector3(5.5, 0, 24), Vector3(-5.5, 0, 36), Vector3(5.5, 0, 36),
	Vector3(-5.5, 0, 62), Vector3(5.5, 0, 62), Vector3(-5.5, 0, 74), Vector3(5.5, 0, 74),
	# The avenue between Date Palm Street and the gate (only where there's room).
	Vector3(-5.5, 0, 98), Vector3(5.5, 0, 98), Vector3(-5.5, 0, 106), Vector3(5.5, 0, 106),
	Vector3(5.5, 0, 113),
	# The avenue north of the roundabout.
	Vector3(-5.5, 0, -26), Vector3(5.5, 0, -26), Vector3(-5.5, 0, -38), Vector3(5.5, 0, -38),
	Vector3(-5.5, 0, -62), Vector3(5.5, 0, -62), Vector3(-5.5, 0, -74), Vector3(5.5, 0, -74),
	# The roundabout island.
	Vector3(0, 0.4, 0), Vector3(3.5, 0.4, 2.0), Vector3(-3.0, 0.4, -3.0),
	# Around the mosque.
	Vector3(-10, 0, -99), Vector3(10, 0, -99), Vector3(-13, 0, -118), Vector3(-13, 0, -130),
	# Around the mini market.
	Vector3(13, 0, 113), Vector3(52, 0, 127), Vector3(52, 0, 137),
	# In the park.
	Vector3(-100, 0, -105), Vector3(-70, 0, -105), Vector3(-128, 0, -128),
	Vector3(-42, 0, -128), Vector3(-100, 0, -140), Vector3(-70, 0, -140),
]

## The park north of Ghaf Street, west side. area: the grass, as Rect2(x, z, width, depth).
## A bilingual sign stands at the entrance, where the north-south path meets Ghaf Street.
const PARK := {
	"name": "Palm Grove Park",
	"arabic": "حديقة بستان النخيل",
	"area": Rect2(-140, -145, 110, 45),
	"sign": Vector3(-78, 0, -97.5),
	"sign_facing": 0.0,
	"fountain": Vector3(-85, 0, -122),
}
## Flat paving paths through the park, as Rect2(x, z, width, depth).
const PARK_PATHS := [
	Rect2(-138, -123.5, 106, 3),  # west to east through the fountain
	Rect2(-86.5, -143, 3, 49),    # from Ghaf Street north through the fountain
]
## Round shade trees in the park.
const PARK_TREES := [
	Vector3(-125, 0, -108), Vector3(-112, 0, -112), Vector3(-58, 0, -110), Vector3(-45, 0, -106),
	Vector3(-118, 0, -136), Vector3(-55, 0, -136), Vector3(-95, 0, -132), Vector3(-76, 0, -113),
]
## Benches beside the paths. facing: which way you look when you sit (towards the path).
const PARK_BENCHES := [
	{"position": Vector3(-105, 0, -119), "facing": 180.0},
	{"position": Vector3(-65, 0, -119), "facing": 180.0},
	{"position": Vector3(-105, 0, -125), "facing": 0.0},
	{"position": Vector3(-65, 0, -125), "facing": 0.0},
	{"position": Vector3(-82, 0, -108), "facing": -90.0},
	{"position": Vector3(-89, 0, -136), "facing": 90.0},
]
## Bench size: width, height, depth. The fountain basin's radius.
const BENCH_SIZE := Vector3(1.8, 0.9, 0.7)
const FOUNTAIN_RADIUS := 2.5


# --- Session 9: moving obstacles ---
# scripts/obstacle_builder.gd builds these. They're gentle: cats wander slowly in the gaps
# between villas, kids ride scooters up and down the edge of a street. Bumping into one
# knocks your food (damage meter). Kept clear of villas, parked cars and door spots.

## Cats. area: where the cat wanders, Rect2(x, z, width along x, depth along z).
## colour: the fur colour.
const CATS := [
	{"area": Rect2(-69, 94, 4, 10), "colour": Color(0.93, 0.55, 0.2, 1)},   # between villas 1 and 2
	{"area": Rect2(29, 94, 4, 10), "colour": Color(0.35, 0.35, 0.38, 1)},   # between villas 5 and 6
	{"area": Rect2(-69, 77, 4, 9), "colour": Color(0.95, 0.93, 0.88, 1)},   # between villas 9 and 10
	{"area": Rect2(47, 5, 4, 10), "colour": Color(0.15, 0.15, 0.17, 1)},    # between villas 20 and 21
	{"area": Rect2(-33, -84, 4, 10), "colour": Color(0.8, 0.62, 0.4, 1)},   # between villas 31 and 32
]

## Kids on scooters ride back and forth between two points near the edge of a street.
## shirt: the kid's shirt colour.
const SCOOTER_KIDS := [
	{"from": Vector3(-80, 0, 92.5), "to": Vector3(-14, 0, 92.5), "shirt": Color(0.2, 0.55, 0.9, 1)},  # Date Palm Street, west
	{"from": Vector3(14, 0, -87.5), "to": Vector3(80, 0, -87.5), "shirt": Color(0.9, 0.3, 0.5, 1)},   # Ghaf Street, east
	{"from": Vector3(92.5, 0, -78), "to": Vector3(92.5, 0, 78), "shirt": Color(0.3, 0.75, 0.35, 1)},  # East Lane
]
