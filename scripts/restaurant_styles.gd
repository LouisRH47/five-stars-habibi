class_name RestaurantStyles
## The look of each restaurant room (looks pass): floor tiles, wall and accent colours,
## lamp shades, the menu board, what's on the tables and the background sound.
## The things only one shop has (ovens, grills, the sushi belt) are in
## scripts/restaurant_recipes.gd. Keys are the venue_type of each restaurant in the data.

const BLACK := Color(0.1, 0.1, 0.11)
const WHITE := Color(0.96, 0.96, 0.94)

const STYLES := {
	"pizza": {
		"floor": "checker", "floor_a": WHITE, "floor_b": BLACK, "tile": 0.4,
		"wall": Color(0.96, 0.92, 0.84), "accent": Color(0.8, 0.14, 0.12), "tint": Color(0.78, 0.16, 0.13),
		"lamp": Color(0.8, 0.14, 0.12), "dish": "code:pizza", "sound": "room_pizza.wav",
		"menu": ["Margherita  25 Dh", "Pepperoni  29 Dh", "Four cheese  31 Dh", "Garlic bread  12 Dh"],
	},
	"gelato": {
		"floor": "checker", "floor_a": Color(1.0, 0.84, 0.88), "floor_b": Color(0.82, 0.95, 0.89), "tile": 0.4,
		"wall": WHITE, "accent": Color(0.95, 0.5, 0.65), "tint": Color(0.93, 0.48, 0.63),
		"lamp": Color(0.98, 0.8, 0.86), "dish": "code:sundae", "sound": "room_gelato.wav",
		"chair": "furniture/chair_A_wood",
		"menu": ["1 scoop  12 Dh", "2 scoops  20 Dh", "Cone or cup", "Milkshake  18 Dh"],
	},
	"boba": {
		"floor": "plain", "floor_a": Color(0.86, 0.83, 0.78), "floor_b": Color(0.7, 0.68, 0.64), "tile": 0.6,
		"wall": Color(0.97, 0.94, 0.9), "accent": Color(0.62, 0.3, 0.52), "tint": Color(0.66, 0.3, 0.55),
		"lamp": Color(0.95, 0.9, 0.8), "dish": "code:boba", "sound": "room_boba.wav",
		"chair": "furniture/chair_A_wood",
		"menu": ["Milk tea  16 Dh", "Taro  18 Dh", "Mango  18 Dh", "Karak or coffee  10 Dh"],
	},
	"shawarma": {
		"floor": "star", "floor_a": Color(0.95, 0.9, 0.8), "floor_b": Color(0.14, 0.42, 0.55), "tile": 0.5,
		"wall": Color(0.97, 0.93, 0.85), "accent": Color(0.14, 0.42, 0.55), "tint": Color(0.2, 0.42, 0.62),
		"lamp": Color(0.75, 0.55, 0.25), "dish": "code:wrap", "sound": "room_shawarma.wav",
		"menu": ["Chicken shawarma  12 Dh", "Beef shawarma  15 Dh", "Fries  8 Dh", "Garlic sauce  2 Dh"],
	},
	"bakery": {
		"floor": "checker", "floor_a": Color(0.97, 0.93, 0.85), "floor_b": Color(0.74, 0.45, 0.35), "tile": 0.35,
		"wall": Color(0.98, 0.94, 0.88), "accent": Color(0.62, 0.32, 0.3), "tint": Color(0.6, 0.3, 0.3),
		"lamp": Color(0.95, 0.85, 0.7), "dish": "code:cake", "sound": "room_bakery.wav",
		"chair": "furniture/chair_A_wood",
		"menu": ["Zaatar manakish  7 Dh", "Cheese manakish  9 Dh", "Birthday cake  85 Dh", "Kunafa  15 Dh"],
	},
}


## The style for one venue type (an empty one if it has none).
static func style(kind: String) -> Dictionary:
	return STYLES.get(kind, {})


## True if this venue type uses the new restaurant room (Session 54).
static func has_room(kind: String) -> bool:
	return STYLES.has(kind)
