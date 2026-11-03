class_name WahatAlShams
## Data only: Wahat Al Shams ("Sun Oasis"), the Tier 1 community (Session 25).
## A made-up car-free eco community. Sketch: docs/wahat_al_shams_map.svg.
## scripts/wahat_builder.gd builds the ground, roads, tracks, trees, Plaza, spine, car parks,
## bollards, plots, walls, gate and signs from this list; scripts/place_builder.gd builds the
## shops and the 60 homes; scripts/decor_builder.gd the palms, parked cars and speed bumps;
## scripts/obstacle_builder.gd the cats and kids. To move something, change its line here.
## This file was first written by a small script, but it's a normal data list: edit it by hand.
##
## Positions are in metres. x runs west (-) to east (+), z runs north (-) to south (+).
## The main gate is in the middle of the west side. facing: which way a front door points,
## in degrees: 0 = south (+Z), 180 = north (-Z), 90 = east (+X), -90 = west (-X).

## Half the size of the whole community: 400 m west to east, 300 m north to south.
const MAP_HALF := Vector2(200, 150)
## The default road width (each road below can have its own "width").
const ROAD_WIDTH := 8.0
const WALL_HEIGHT := 2.5
## The gap in the west wall where the main gate is (z from -GATE_HALF_WIDTH to +GATE_HALF_WIDTH).
const GATE_HALF_WIDTH := 6.0

## Where you start: just inside the gate, facing east into the Plaza.
const START := {"position": Vector3(-188, 0, 2), "facing": -90.0}

## Tree belt round the edge, then the horse track and the bike track, then the ring road.
const TREE_BELT := {"inner": Vector2(193, 143), "spacing": 7.0}
const HORSE_TRACK := {"half": Vector2(188, 138), "width": 4.0}
const BIKE_TRACK := {"half": Vector2(183, 133), "width": 2.0}

## The Plaza: a round paved square just inside the gate (shops round it, Session 27 adds the
## sunken square, fountain and shade sails).
const PLAZA := {"centre": Vector2(-140, 0), "radius": 26.0}

## The green spine through the middle: grass, the spine path (above, in ROADS) and a stream.
const SPINE := Rect2(-116, -22, 240, 44)
const STREAM := {"z": 12.0, "from_x": -110.0, "to_x": 118.0, "width": 2.0}

## Roads, lanes and paths you can ride on. width: metres (lanes are 4 m, the ring road 8 m).
## Cluster lanes: two across each cluster, and one at each side from the ring road to the spine.
const ROADS := [
	{"name": "Ring Road", "from": Vector2(-176, -126), "to": Vector2(176, -126), "width": 8.0},
	{"name": "Ring Road", "from": Vector2(176, -126), "to": Vector2(176, 126), "width": 8.0},
	{"name": "Ring Road", "from": Vector2(176, 126), "to": Vector2(-176, 126), "width": 8.0},
	{"name": "Ring Road", "from": Vector2(-176, 126), "to": Vector2(-176, -126), "width": 8.0},
	{"name": "Gate Road", "from": Vector2(-200, 0), "to": Vector2(-164, 0), "width": 8.0},
	{"name": "Spine Path", "from": Vector2(-116, 0), "to": Vector2(130, 0), "width": 4.0},
	{"name": "C1 Lane", "from": Vector2(-111, -90), "to": Vector2(-45, -90), "width": 4.0},
	{"name": "C1 Lane", "from": Vector2(-111, -54), "to": Vector2(-45, -54), "width": 4.0},
	{"name": "C1 Lane", "from": Vector2(-111, -122), "to": Vector2(-111, -22), "width": 4.0},
	{"name": "C1 Lane", "from": Vector2(-45, -122), "to": Vector2(-45, -22), "width": 4.0},
	{"name": "C2 Lane", "from": Vector2(-31, -90), "to": Vector2(35, -90), "width": 4.0},
	{"name": "C2 Lane", "from": Vector2(-31, -54), "to": Vector2(35, -54), "width": 4.0},
	{"name": "C2 Lane", "from": Vector2(-31, -122), "to": Vector2(-31, -22), "width": 4.0},
	{"name": "C2 Lane", "from": Vector2(35, -122), "to": Vector2(35, -22), "width": 4.0},
	{"name": "C3 Lane", "from": Vector2(49, -90), "to": Vector2(115, -90), "width": 4.0},
	{"name": "C3 Lane", "from": Vector2(49, -54), "to": Vector2(115, -54), "width": 4.0},
	{"name": "C3 Lane", "from": Vector2(49, -122), "to": Vector2(49, -22), "width": 4.0},
	{"name": "C3 Lane", "from": Vector2(115, -122), "to": Vector2(115, -22), "width": 4.0},
	{"name": "C4 Lane", "from": Vector2(-111, 54), "to": Vector2(-45, 54), "width": 4.0},
	{"name": "C4 Lane", "from": Vector2(-111, 90), "to": Vector2(-45, 90), "width": 4.0},
	{"name": "C4 Lane", "from": Vector2(-111, 122), "to": Vector2(-111, 22), "width": 4.0},
	{"name": "C4 Lane", "from": Vector2(-45, 122), "to": Vector2(-45, 22), "width": 4.0},
	{"name": "C5 Lane", "from": Vector2(-31, 54), "to": Vector2(35, 54), "width": 4.0},
	{"name": "C5 Lane", "from": Vector2(-31, 90), "to": Vector2(35, 90), "width": 4.0},
	{"name": "C5 Lane", "from": Vector2(-31, 122), "to": Vector2(-31, 22), "width": 4.0},
	{"name": "C5 Lane", "from": Vector2(35, 122), "to": Vector2(35, 22), "width": 4.0},
]

## Paved strips you can ride on: the mini-plaza through the middle of each cluster.
const PAVED_AREAS := [
	Rect2(-109, -75, 62, 6),  # C1 mini-plaza
	Rect2(-29, -75, 62, 6),  # C2 mini-plaza
	Rect2(51, -75, 62, 6),  # C3 mini-plaza
	Rect2(-109, 69, 62, 6),  # C4 mini-plaza
	Rect2(-29, 69, 62, 6),  # C5 mini-plaza
]

## Solar car parks on the ring road next to each cluster (Session 26 adds the solar roofs).
const PARKING_AREAS := [
	Rect2(-96, -121, 36, 11),  # C1 solar car park
	Rect2(-16, -121, 36, 11),  # C2 solar car park
	Rect2(64, -121, 36, 11),  # C3 solar car park
	Rect2(-96, 110, 36, 11),  # C4 solar car park
	Rect2(-16, 110, 36, 11),  # C5 solar car park
]

## Bollards at the cluster lane entrances: cars can't get in, the bike can (2.8 m gap).
const BOLLARDS := [
	Vector2(-112.5, -120), Vector2(-109.5, -120), Vector2(-112.5, -24), Vector2(-109.5, -24), Vector2(-46.5, -120), Vector2(-43.5, -120), Vector2(-46.5, -24), Vector2(-43.5, -24), Vector2(-32.5, -120), Vector2(-29.5, -120), Vector2(-32.5, -24), Vector2(-29.5, -24), Vector2(33.5, -120), Vector2(36.5, -120), Vector2(33.5, -24), Vector2(36.5, -24), Vector2(47.5, -120), Vector2(50.5, -120), Vector2(47.5, -24), Vector2(50.5, -24), Vector2(113.5, -120), Vector2(116.5, -120), Vector2(113.5, -24), Vector2(116.5, -24), Vector2(-112.5, 120), Vector2(-109.5, 120), Vector2(-112.5, 24), Vector2(-109.5, 24), Vector2(-46.5, 120), Vector2(-43.5, 120), Vector2(-46.5, 24), Vector2(-43.5, 24), Vector2(-32.5, 120), Vector2(-29.5, 120), Vector2(-32.5, 24), Vector2(-29.5, 24), Vector2(33.5, 120), Vector2(36.5, 120), Vector2(33.5, 24), Vector2(36.5, 24),
]

## Plots for the buildings that come in Session 27 (flat for now).
## colour: the colour of the plot on the ground and the mini-map.
const PLOTS := [
	{"name": "Al Shams School", "area": Rect2(84, 37, 33, 70), "colour": Color(0.95, 0.85, 0.8, 1)},
	{"name": "Mosque", "area": Rect2(47, 37, 33, 70), "colour": Color(0.93, 0.92, 0.88, 1)},
	{"name": "Stables", "area": Rect2(133, -35, 40, 70), "colour": Color(0.86, 0.75, 0.55, 1)},
	{"name": "Building site", "area": Rect2(133, 67, 40, 40), "colour": Color(0.8, 0.78, 0.74, 1)},
]

## The big welcome sign by the gate road, ahead on the right as you start.
const WELCOME_SIGN := {
	"name": "Welcome to Wahat Al Shams",
	"arabic": "أهلاً بكم في واحة الشمس",
	"position": Vector3(-169, 0, 10),
	"facing": -90.0,
}

## Bilingual cluster signs at the lane entrances (Session 26 adds them; listed here now).
const CLUSTER_NAMES := {"C1": "المجموعة ١", "C2": "المجموعة ٢", "C3": "المجموعة ٣", "C4": "المجموعة ٤", "C5": "المجموعة ٥"}

## The tutorial's first order: an easy pizza to the first home in Cluster 1.
const TUTORIAL_ORDER := {"restaurant": "pizza", "villa": 101}

## Shops round the Plaza, fronts facing the middle. Session 27 adds Shawarma Supreme and
## Sunrise Bakery in the two empty south spots, and turns the mini market into a shop too.
const RESTAURANT_SIZE := Vector3(10.0, 5.0, 8.0)
const RESTAURANTS := [
	{"id": "pizza", "name": "Pizza", "arabic": "بيتزا", "food": "pizza",
			"colour": Color(0.8, 0.2, 0.15, 1), "position": Vector3(-156, 0, -24), "facing": 0.0},
	{"id": "gelato", "name": "Brain Freeze Gelato", "arabic": "برين فريز جيلاتو", "food": "ice cream",
			"colour": Color(0.86, 0.33, 0.56, 1), "position": Vector3(-140, 0, -27), "facing": 0.0},
	{"id": "boba", "name": "Boba Oasis", "arabic": "واحة البوبا", "food": "bubble tea",
			"colour": Color(0.47, 0.3, 0.66, 1), "position": Vector3(-124, 0, -24), "facing": 0.0},
]

## The mini market on the south side of the Plaza.
const SUPERMARKET := {
	"name": "Al Sarab Mini Market",
	"arabic": "ميني ماركت السراب",
	"position": Vector3(-140, 0, 29),
	"facing": 180.0,
	"size": Vector3(12.0, 5.0, 9.0),
}

## The 60 homes: 12 per cluster, numbered 1 to 12 inside each cluster.
## number: a unique id (cluster x 100 + house). house: the number on the door.
## address: what the phone and the mini-map show. kind: courtyard, garden or signature
## (the 3 house types, Session 26). Placeholder boxes until then.
const VILLA_SIZE := Vector3(11.0, 6.5, 11.0)
const VILLAS := [
	{"number": 101, "house": 1, "cluster": "C1", "address": "C1 · Villa 1", "kind": "courtyard", "position": Vector3(-100, 0, -98.5), "facing": 0.0},
	{"number": 102, "house": 2, "cluster": "C1", "address": "C1 · Villa 2", "kind": "courtyard", "position": Vector3(-78, 0, -98.5), "facing": 0.0},
	{"number": 103, "house": 3, "cluster": "C1", "address": "C1 · Villa 3", "kind": "courtyard", "position": Vector3(-56, 0, -98.5), "facing": 0.0},
	{"number": 104, "house": 4, "cluster": "C1", "address": "C1 · Villa 4", "kind": "courtyard", "position": Vector3(-100, 0, -81.5), "facing": 180.0},
	{"number": 105, "house": 5, "cluster": "C1", "address": "C1 · Villa 5", "kind": "courtyard", "position": Vector3(-78, 0, -81.5), "facing": 180.0},
	{"number": 106, "house": 6, "cluster": "C1", "address": "C1 · Villa 6", "kind": "garden", "position": Vector3(-56, 0, -81.5), "facing": 180.0},
	{"number": 107, "house": 7, "cluster": "C1", "address": "C1 · Villa 7", "kind": "courtyard", "position": Vector3(-100, 0, -62.5), "facing": 0.0},
	{"number": 108, "house": 8, "cluster": "C1", "address": "C1 · Villa 8", "kind": "courtyard", "position": Vector3(-78, 0, -62.5), "facing": 0.0},
	{"number": 109, "house": 9, "cluster": "C1", "address": "C1 · Villa 9", "kind": "courtyard", "position": Vector3(-56, 0, -62.5), "facing": 0.0},
	{"number": 110, "house": 10, "cluster": "C1", "address": "C1 · Villa 10", "kind": "courtyard", "position": Vector3(-100, 0, -45.5), "facing": 180.0},
	{"number": 111, "house": 11, "cluster": "C1", "address": "C1 · Villa 11", "kind": "courtyard", "position": Vector3(-78, 0, -45.5), "facing": 180.0},
	{"number": 112, "house": 12, "cluster": "C1", "address": "C1 · Villa 12", "kind": "signature", "position": Vector3(-56, 0, -45.5), "facing": 180.0},
	{"number": 201, "house": 1, "cluster": "C2", "address": "C2 · Villa 1", "kind": "courtyard", "position": Vector3(-20, 0, -98.5), "facing": 0.0},
	{"number": 202, "house": 2, "cluster": "C2", "address": "C2 · Villa 2", "kind": "courtyard", "position": Vector3(2, 0, -98.5), "facing": 0.0},
	{"number": 203, "house": 3, "cluster": "C2", "address": "C2 · Villa 3", "kind": "courtyard", "position": Vector3(24, 0, -98.5), "facing": 0.0},
	{"number": 204, "house": 4, "cluster": "C2", "address": "C2 · Villa 4", "kind": "courtyard", "position": Vector3(-20, 0, -81.5), "facing": 180.0},
	{"number": 205, "house": 5, "cluster": "C2", "address": "C2 · Villa 5", "kind": "courtyard", "position": Vector3(2, 0, -81.5), "facing": 180.0},
	{"number": 206, "house": 6, "cluster": "C2", "address": "C2 · Villa 6", "kind": "garden", "position": Vector3(24, 0, -81.5), "facing": 180.0},
	{"number": 207, "house": 7, "cluster": "C2", "address": "C2 · Villa 7", "kind": "courtyard", "position": Vector3(-20, 0, -62.5), "facing": 0.0},
	{"number": 208, "house": 8, "cluster": "C2", "address": "C2 · Villa 8", "kind": "courtyard", "position": Vector3(2, 0, -62.5), "facing": 0.0},
	{"number": 209, "house": 9, "cluster": "C2", "address": "C2 · Villa 9", "kind": "courtyard", "position": Vector3(24, 0, -62.5), "facing": 0.0},
	{"number": 210, "house": 10, "cluster": "C2", "address": "C2 · Villa 10", "kind": "courtyard", "position": Vector3(-20, 0, -45.5), "facing": 180.0},
	{"number": 211, "house": 11, "cluster": "C2", "address": "C2 · Villa 11", "kind": "courtyard", "position": Vector3(2, 0, -45.5), "facing": 180.0},
	{"number": 212, "house": 12, "cluster": "C2", "address": "C2 · Villa 12", "kind": "signature", "position": Vector3(24, 0, -45.5), "facing": 180.0},
	{"number": 301, "house": 1, "cluster": "C3", "address": "C3 · Villa 1", "kind": "courtyard", "position": Vector3(60, 0, -98.5), "facing": 0.0},
	{"number": 302, "house": 2, "cluster": "C3", "address": "C3 · Villa 2", "kind": "courtyard", "position": Vector3(82, 0, -98.5), "facing": 0.0},
	{"number": 303, "house": 3, "cluster": "C3", "address": "C3 · Villa 3", "kind": "courtyard", "position": Vector3(104, 0, -98.5), "facing": 0.0},
	{"number": 304, "house": 4, "cluster": "C3", "address": "C3 · Villa 4", "kind": "courtyard", "position": Vector3(60, 0, -81.5), "facing": 180.0},
	{"number": 305, "house": 5, "cluster": "C3", "address": "C3 · Villa 5", "kind": "courtyard", "position": Vector3(82, 0, -81.5), "facing": 180.0},
	{"number": 306, "house": 6, "cluster": "C3", "address": "C3 · Villa 6", "kind": "garden", "position": Vector3(104, 0, -81.5), "facing": 180.0},
	{"number": 307, "house": 7, "cluster": "C3", "address": "C3 · Villa 7", "kind": "courtyard", "position": Vector3(60, 0, -62.5), "facing": 0.0},
	{"number": 308, "house": 8, "cluster": "C3", "address": "C3 · Villa 8", "kind": "courtyard", "position": Vector3(82, 0, -62.5), "facing": 0.0},
	{"number": 309, "house": 9, "cluster": "C3", "address": "C3 · Villa 9", "kind": "courtyard", "position": Vector3(104, 0, -62.5), "facing": 0.0},
	{"number": 310, "house": 10, "cluster": "C3", "address": "C3 · Villa 10", "kind": "courtyard", "position": Vector3(60, 0, -45.5), "facing": 180.0},
	{"number": 311, "house": 11, "cluster": "C3", "address": "C3 · Villa 11", "kind": "courtyard", "position": Vector3(82, 0, -45.5), "facing": 180.0},
	{"number": 312, "house": 12, "cluster": "C3", "address": "C3 · Villa 12", "kind": "signature", "position": Vector3(104, 0, -45.5), "facing": 180.0},
	{"number": 401, "house": 1, "cluster": "C4", "address": "C4 · Villa 1", "kind": "courtyard", "position": Vector3(-100, 0, 45.5), "facing": 0.0},
	{"number": 402, "house": 2, "cluster": "C4", "address": "C4 · Villa 2", "kind": "courtyard", "position": Vector3(-78, 0, 45.5), "facing": 0.0},
	{"number": 403, "house": 3, "cluster": "C4", "address": "C4 · Villa 3", "kind": "courtyard", "position": Vector3(-56, 0, 45.5), "facing": 0.0},
	{"number": 404, "house": 4, "cluster": "C4", "address": "C4 · Villa 4", "kind": "courtyard", "position": Vector3(-100, 0, 62.5), "facing": 180.0},
	{"number": 405, "house": 5, "cluster": "C4", "address": "C4 · Villa 5", "kind": "courtyard", "position": Vector3(-78, 0, 62.5), "facing": 180.0},
	{"number": 406, "house": 6, "cluster": "C4", "address": "C4 · Villa 6", "kind": "garden", "position": Vector3(-56, 0, 62.5), "facing": 180.0},
	{"number": 407, "house": 7, "cluster": "C4", "address": "C4 · Villa 7", "kind": "courtyard", "position": Vector3(-100, 0, 81.5), "facing": 0.0},
	{"number": 408, "house": 8, "cluster": "C4", "address": "C4 · Villa 8", "kind": "courtyard", "position": Vector3(-78, 0, 81.5), "facing": 0.0},
	{"number": 409, "house": 9, "cluster": "C4", "address": "C4 · Villa 9", "kind": "courtyard", "position": Vector3(-56, 0, 81.5), "facing": 0.0},
	{"number": 410, "house": 10, "cluster": "C4", "address": "C4 · Villa 10", "kind": "courtyard", "position": Vector3(-100, 0, 98.5), "facing": 180.0},
	{"number": 411, "house": 11, "cluster": "C4", "address": "C4 · Villa 11", "kind": "courtyard", "position": Vector3(-78, 0, 98.5), "facing": 180.0},
	{"number": 412, "house": 12, "cluster": "C4", "address": "C4 · Villa 12", "kind": "signature", "position": Vector3(-56, 0, 98.5), "facing": 180.0},
	{"number": 501, "house": 1, "cluster": "C5", "address": "C5 · Villa 1", "kind": "courtyard", "position": Vector3(-20, 0, 45.5), "facing": 0.0},
	{"number": 502, "house": 2, "cluster": "C5", "address": "C5 · Villa 2", "kind": "courtyard", "position": Vector3(2, 0, 45.5), "facing": 0.0},
	{"number": 503, "house": 3, "cluster": "C5", "address": "C5 · Villa 3", "kind": "courtyard", "position": Vector3(24, 0, 45.5), "facing": 0.0},
	{"number": 504, "house": 4, "cluster": "C5", "address": "C5 · Villa 4", "kind": "courtyard", "position": Vector3(-20, 0, 62.5), "facing": 180.0},
	{"number": 505, "house": 5, "cluster": "C5", "address": "C5 · Villa 5", "kind": "courtyard", "position": Vector3(2, 0, 62.5), "facing": 180.0},
	{"number": 506, "house": 6, "cluster": "C5", "address": "C5 · Villa 6", "kind": "garden", "position": Vector3(24, 0, 62.5), "facing": 180.0},
	{"number": 507, "house": 7, "cluster": "C5", "address": "C5 · Villa 7", "kind": "courtyard", "position": Vector3(-20, 0, 81.5), "facing": 0.0},
	{"number": 508, "house": 8, "cluster": "C5", "address": "C5 · Villa 8", "kind": "courtyard", "position": Vector3(2, 0, 81.5), "facing": 0.0},
	{"number": 509, "house": 9, "cluster": "C5", "address": "C5 · Villa 9", "kind": "courtyard", "position": Vector3(24, 0, 81.5), "facing": 0.0},
	{"number": 510, "house": 10, "cluster": "C5", "address": "C5 · Villa 10", "kind": "courtyard", "position": Vector3(-20, 0, 98.5), "facing": 180.0},
	{"number": 511, "house": 11, "cluster": "C5", "address": "C5 · Villa 11", "kind": "courtyard", "position": Vector3(2, 0, 98.5), "facing": 180.0},
	{"number": 512, "house": 12, "cluster": "C5", "address": "C5 · Villa 12", "kind": "signature", "position": Vector3(24, 0, 98.5), "facing": 180.0},
]

# --- Decoration and obstacles (built by decor_builder and obstacle_builder) ---

## Palm trees round the Plaza and along the spine path (never on a road or path).
const PALM_TREES := [
	Vector3(-152, 0, -9), Vector3(-128, 0, -9), Vector3(-152, 0, 9), Vector3(-128, 0, 9),
	Vector3(-100, 0, -5), Vector3(-60, 0, -5), Vector3(-20, 0, -5), Vector3(20, 0, -5), Vector3(60, 0, -5), Vector3(100, 0, -5),
	Vector3(-80, 0, 5), Vector3(-40, 0, 5), Vector3(40, 0, 5), Vector3(80, 0, 5),
]

const PARKED_CAR_SIZE := Vector3(1.9, 1.5, 4.3)
## Parked cars in the solar car parks.
const PARKED_CARS := [
	{"position": Vector3(-90, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(-81, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(-69, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(-10, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(-1, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(11, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(70, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(79, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(91, 0, -115.5), "facing": 0.0, "bay": true},
	{"position": Vector3(-90, 0, 115.5), "facing": 180.0, "bay": true},
	{"position": Vector3(-81, 0, 115.5), "facing": 180.0, "bay": true},
	{"position": Vector3(-69, 0, 115.5), "facing": 180.0, "bay": true},
	{"position": Vector3(-10, 0, 115.5), "facing": 180.0, "bay": true},
	{"position": Vector3(-1, 0, 115.5), "facing": 180.0, "bay": true},
	{"position": Vector3(11, 0, 115.5), "facing": 180.0, "bay": true},
]

const SPEED_BUMP_SIZE := Vector3(8.0, 0.12, 0.5)
## Speed bumps on the ring road (none near the gate: the smoke test rides there).
## The smoke test rides over the FIRST bump in this list.
const SPEED_BUMPS := [
	{"position": Vector3(-100, 0, -126), "facing": 90.0},
	{"position": Vector3(40, 0, -126), "facing": 90.0},
	{"position": Vector3(-40, 0, 126), "facing": 90.0},
	{"position": Vector3(100, 0, 126), "facing": 90.0},
	{"position": Vector3(176, 0, -60), "facing": 0.0},
	{"position": Vector3(176, 0, 60), "facing": 0.0},
	{"position": Vector3(-176, 0, -70), "facing": 0.0},
	{"position": Vector3(-176, 0, 70), "facing": 0.0},
]

## Cats wander in the cluster mini-plazas.
const CATS := [
	{"area": Rect2(-92, -74.5, 6, 5), "colour": Color(0.93, 0.55, 0.2, 1)},  # C1 mini-plaza
	{"area": Rect2(-12, -74.5, 6, 5), "colour": Color(0.35, 0.35, 0.38, 1)},  # C2 mini-plaza
	{"area": Rect2(68, -74.5, 6, 5), "colour": Color(0.95, 0.93, 0.88, 1)},  # C3 mini-plaza
	{"area": Rect2(-92, 69.5, 6, 5), "colour": Color(0.15, 0.15, 0.17, 1)},  # C4 mini-plaza
	{"area": Rect2(-12, 69.5, 6, 5), "colour": Color(0.8, 0.62, 0.4, 1)},  # C5 mini-plaza
]

## Kids on scooters ride back and forth along the edge of the ring road and the spine path.
const SCOOTER_KIDS := [
	{"from": Vector3(-150, 0, -123.5), "to": Vector3(-20, 0, -123.5), "shirt": Color(0.2, 0.55, 0.9, 1)},
	{"from": Vector3(20, 0, 123.5), "to": Vector3(150, 0, 123.5), "shirt": Color(0.9, 0.3, 0.5, 1)},
	{"from": Vector3(-90, 0, 1.5), "to": Vector3(90, 0, 1.5), "shirt": Color(0.3, 0.75, 0.35, 1)},
]
