class_name InteriorMenus
## Session 58/59: data for the walk-in rooms (Appendix B of docs/looks_pass_detailed_plan.md).
## The menu board of every place (real items with their prices in Dh), where you stand to
## pick up an order (room directions: x left/right seen from the door, z from +5 at the glass
## to -5 at the back wall), the room's sound and how many seats it needs at least.
## Change prices or items here; the boards are made from this list.

const MENUS := {
	"pizza": [["Margherita", 32], ["Pepperoni", 38], ["Diavola", 40], ["Four cheese", 42], ["Garlic bread", 15]],
	"gelato": [["1 scoop", 12], ["2 scoops", 18], ["3 scoops", 24], ["Cone or cup", "free"], ["Toppings", 3]],
	"boba": [["Flat white", 18], ["Cappuccino", 18], ["Iced latte", 20], ["Croissant", 12], ["Cake slice", 22]],
	"shawarma": [["Chicken shawarma", 14], ["Meat shawarma", 16], ["Shawarma plate", 28], ["Fries", 8], ["Fresh juice", 12]],
	"bakery": [["Zaatar manakish", 8], ["Cheese manakish", 12], ["Spinach fatayer", 6], ["Khubz bag", 5], ["Mixed box", 30]],
	"market": [["Fruit box", 25], ["Water 6 pack", 9]],
	"thai": [["Pad thai", 38], ["Green curry", 42], ["Satay", 30], ["Mango sticky rice", 24]],
	"sushi": [["Salmon roll", 28], ["California roll", 26], ["Nigiri set", 40], ["Miso", 10]],
	"tacos": [["Tacos (3)", 30], ["Quesadilla", 32], ["Guacamole", 18], ["Churros", 15]],
	"burger": [["Classic", 35], ["Cheese", 38], ["Smash double", 45], ["Fries", 12]],
}

## The 12 gelato flavours, one tag in front of each tub (2 rows of 6).
const FLAVOURS := ["Pistachio", "Mango", "Chocolate", "Strawberry", "Vanilla", "Lemon",
		"Cookies", "Caramel", "Coconut", "Mint", "Blueberry", "Date"]

## Where you stand to pick up the order (the pickup end of the counter, not the till).
const PICKUP := {
	"pizza": Vector3(-3.0, 0, -1.45),
	"gelato": Vector3(-1.0, 0, 3.65),
	"boba": Vector3(-3.0, 0, -1.45),
	"shawarma": Vector3(1.85, 0, 1.6),
	"bakery": Vector3(-3.0, 0, -1.05),
	"market": Vector3(3.5, 0, 2.0),
	"thai": Vector3(-3.0, 0, -1.45),
	"sushi": Vector3(3.6, 0, -1.45),
	"tacos": Vector3(-3.0, 0, -1.45),
	"burger": Vector3(-3.0, 0, -1.45),
}

## Each room's own quiet sound loop (made by tools/make_sounds.py).
const SOUNDS := {
	"pizza": "room_oven", "gelato": "room_freezer", "boba": "room_espresso", "shawarma": "room_grill",
	"bakery": "room_bakery", "market": "room_tills", "thai": "room_wok", "sushi": "room_sushi",
	"tacos": "room_grill", "burger": "room_grill", "bikes": "room_workshop", "clothes": "room_music",
}

## The least seats each room must have (the plan says 20 or more; the supermarket has none).
const MIN_SEATS := {"pizza": 20, "gelato": 20, "boba": 20, "shawarma": 20, "bakery": 20, "market": 0,
		"thai": 20, "sushi": 20, "tacos": 20, "burger": 20}
