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
	# Session 55
	"thai": {
		"floor": "planks", "floor_a": Color(0.3, 0.19, 0.11), "floor_b": Color(0.42, 0.27, 0.15), "tile": 0.5,
		"wall": Color(0.95, 0.88, 0.74), "accent": Color(0.72, 0.12, 0.1), "tint": Color(0.68, 0.14, 0.12),
		"lamp_spots": [], "dish": "restaurant/food_stew", "dish_size": 0.26, "sound": "room_thai.wav",
		"chair": "furniture/chair_A_wood",
		"menu": ["Pad thai  32 Dh", "Green curry  35 Dh", "Spring rolls  18 Dh", "Mango sticky rice  22 Dh"],
	},
	"sushi": {
		"floor": "planks", "floor_a": Color(0.8, 0.66, 0.46), "floor_b": Color(0.7, 0.55, 0.37), "tile": 0.5,
		"wall": Color(0.96, 0.94, 0.89), "accent": Color(0.12, 0.18, 0.36), "tint": Color(0.14, 0.22, 0.42),
		"lamp_spots": [], "dish": "code:sushi", "sound": "room_sushi.wav", "own_tables": true,
		"chair": "furniture/chair_A_wood",
		"menu": ["Salmon roll  28 Dh", "Tuna nigiri  24 Dh", "Miso soup  10 Dh", "Belt plates  8-20 Dh"],
	},
	"tacos": {
		"floor": "checker", "floor_a": Color(0.8, 0.45, 0.3), "floor_b": Color(0.97, 0.92, 0.82), "tile": 0.4,
		"wall": Color(0.98, 0.86, 0.56), "accent": Color(0.1, 0.55, 0.55), "tint": Color(0.85, 0.3, 0.24),
		"lamp": Color(0.1, 0.55, 0.55), "dish": "code:taco", "sound": "room_tacos.wav",
		"chair": "furniture/chair_A_wood",
		"menu": ["Chicken tacos  26 Dh", "Beef burrito  34 Dh", "Nachos  22 Dh", "Churros  14 Dh"],
	},
	"burger": {
		"floor": "checker", "floor_a": WHITE, "floor_b": BLACK, "tile": 0.3,
		"wall": WHITE, "accent": Color(1.0, 0.35, 0.62), "tint": Color(0.18, 0.18, 0.2),
		"lamp": BLACK, "dish": "restaurant/food_burger", "dish_size": 0.22, "sound": "room_burger.wav",
		"chair": "restaurant/chair_B", "uniform": Color(1.0, 0.35, 0.62),
		"menu": ["Classic burger  32 Dh", "Double cheese  42 Dh", "Fries  12 Dh", "Milkshake  18 Dh"],
	},
	# Grand Groceries is a supermarket (scripts/grocery_room.gd): you collect at checkout 1.
	"market": {
		"floor": "plain", "floor_a": Color(0.93, 0.93, 0.91), "floor_b": Color(0.8, 0.8, 0.78), "tile": 0.6,
		"wall": WHITE, "accent": Color(0.2, 0.55, 0.3), "tint": Color(0.2, 0.55, 0.3),
		"sound": "room_market.wav", "supermarket": true, "counter_spot": Vector3(-1.8, 0, 3.9),
	},
}


## The style for one venue type (an empty one if it has none).
static func style(kind: String) -> Dictionary:
	return STYLES.get(kind, {})


## True if this venue type uses the new restaurant room (Session 54).
static func has_room(kind: String) -> bool:
	return STYLES.has(kind)
