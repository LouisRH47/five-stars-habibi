class_name GroceryRoom
extends RefCounted
## Grand Groceries as a real little supermarket (looks pass, Session 55). Same shell as the
## restaurant rooms (scripts/restaurant_room.gd: 12 x 10 m inside, glass front, sliding
## doors, storeroom behind), and inside:
##   Back wall: a row of glass drinks fridges
##   Right half: 3 shelf units with hanging bilingual aisle signs and yellow price strips
##   Left half: 2 checkouts with belts and a cashier (you pick up at checkout 1), a sweets
##   rack and the bread shelf; the fruit and veg stand at the front by the window
##   By the door: baskets and trolleys. Shoppers with trolleys and baskets.
## The front is local +Z.

const WHITE := Color(0.96, 0.96, 0.94)
const GREEN := Color(0.2, 0.55, 0.3)
const STEEL := Color(0.72, 0.74, 0.76)
const DARK := Color(0.12, 0.13, 0.14)
const PRICE := Color(1.0, 0.85, 0.1)
const AISLES := [["1", "Snacks", "وجبات خفيفة"], ["2", "Rice and pasta", "أرز ومعكرونة"], ["3", "Home", "المنزل"]]
const PRODUCTS := [
	[Color(0.95, 0.3, 0.2), Color(0.98, 0.75, 0.2), Color(0.3, 0.55, 0.9), Color(0.9, 0.5, 0.75)],
	[Color(0.95, 0.92, 0.8), Color(0.85, 0.6, 0.3), Color(0.9, 0.2, 0.15), Color(0.3, 0.6, 0.35)],
	[Color(0.3, 0.7, 0.9), Color(0.95, 0.95, 0.97), Color(0.6, 0.4, 0.8), Color(0.4, 0.8, 0.5)],
]
## Checkout 1 (where you collect) and checkout 2: the middle of each checkout counter.
const CHECKOUTS := [Vector3(-2.6, 0, 2.4), Vector3(-4.8, 0, 2.4)]


static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var style: Dictionary = RestaurantStyles.style("market")
	var tint: Color = style["tint"]
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", "market")
	body.set_meta("interior_style", "supermarket")
	body.set_meta("signature", "supermarket")
	body.set_meta("room_rect", RestaurantRoom.room_rect(size))
	body.set_meta("ceiling", RestaurantRoom.CEILING)
	var spot: Vector3 = style["counter_spot"]
	body.set_meta("counter_spot", spot)
	body.set_meta("queue_spots", [CHECKOUTS[0] + Vector3(-0.4, 0, 1.0), CHECKOUTS[0] + Vector3(-0.4, 0, 1.8)])
	body.set_meta("queue_exit", Vector3(0.6, 0, size.z * 0.5 + 1.5))
	body.add_to_group("venue_room")
	var motion := VenueMotion.new()
	motion.name = "Motion"
	body.add_child(motion)
	RestaurantRoom.shell(body, size, tint, style)
	RestaurantRoom.outside(body, place, size, tint)
	var back := size.z * 0.5 - RestaurantRoom.ROOM_DEPTH
	fridges(body, back)
	for i in 3:
		shelf_unit(body, Vector3(3.0, 0, -0.2 + i * 2.0), i)
	fruit_and_veg(body, Vector3(-4.0, 0, 6.3))
	bread_shelf(body, Vector3(-5.6, 0, -0.6))
	for i in 2:
		checkout(body, CHECKOUTS[i], i == 0)
	sweets_rack(body, Vector3(-0.9, 0, 2.4))
	baskets_and_trolleys(body)
	shoppers(body, motion)
	lights(body)
	RoomProps.bin(body, Vector3(1.9, 0, 7.5))
	RoomProps.big_plant(body, Vector3(5.45, 0, 7.4))
	RestaurantRoom.sound(body, style.get("sound", ""))
	RestaurantRoom.queue_people(body)
	for i in range(1, 3):
		body.get_node("QueuePerson%d" % i).position = body.get_meta("queue_spots")[i - 1]
	Props.bake_kits(body)
	RestaurantRoom.draw_people_near(body)
	return body


## The back wall: eight glass drinks fridges side by side.
static func fridges(body: StaticBody3D, back: float) -> void:
	for i in 8:
		var fridge := RoomProps.drinks_fridge(body, Vector3(-4.2 + i * 1.2, 0, back + 0.4))
		fridge.name = "DrinksFridge"
	var sign := SignText.make_face("مشروبات باردة", "Cold drinks", 30, WHITE)
	sign.position = Vector3(0, 3.2, back + 0.06)
	body.add_child(sign)
	LowPoly.box(body, Vector3(4.0, 0.8, 0.04), GREEN, Vector3(0, 3.2, back + 0.02))


## A shelf unit (2 sided, 4 shelves of products) with its aisle sign hanging above.
static func shelf_unit(body: StaticBody3D, at: Vector3, aisle: int) -> void:
	var unit := Node3D.new()
	unit.name = "ShelfUnit%d" % (aisle + 1)
	unit.position = at
	body.add_child(unit)
	var length := 4.6
	RestaurantRoom.block(body, Vector3(length, 1.8, 0.7), WHITE.darkened(0.05), at + Vector3(0, 0.9, 0))
	LowPoly.box(unit, Vector3(length, 0.1, 0.06), DARK, Vector3(0, 0.05, 0.36))
	LowPoly.box(unit, Vector3(length, 0.1, 0.06), DARK, Vector3(0, 0.05, -0.36))
	var colours: Array = PRODUCTS[aisle]
	for level in 4:
		var y := 0.25 + level * 0.42
		for side in [-1.0, 1.0]:
			LowPoly.box(unit, Vector3(length, 0.03, 0.04), PRICE, Vector3(0, y - 0.03, side * 0.37))
			for k in 11:
				var colour: Color = colours[(k + level + int(side)) % colours.size()]
				var tall := 0.22 + ((k + level) % 3) * 0.05
				if aisle == 1 and k % 3 == 0:  # bags of rice lying down
					LowPoly.box(unit, Vector3(0.36, 0.14, 0.24), colour, Vector3(-2.05 + k * 0.41, y + 0.07, side * 0.22))
				elif aisle == 2 and k % 2 == 0:  # bottles of cleaner
					LowPoly.cylinder(unit, 0.07, 0.08, tall + 0.06, colour, Vector3(-2.05 + k * 0.41, y + (tall + 0.06) * 0.5, side * 0.22))
				else:
					LowPoly.box(unit, Vector3(0.3, tall, 0.22), colour, Vector3(-2.05 + k * 0.41, y + tall * 0.5, side * 0.22))
	# The hanging bilingual aisle sign (readable from both sides), on two wires.
	var number: String = AISLES[aisle][0]
	var hang := Vector3(0, 3.5, 0)
	for x in [-0.8, 0.8]:
		LowPoly.box(unit, Vector3(0.01, 0.9, 0.01), DARK, hang + Vector3(x, 0.55, 0))
	LowPoly.box(unit, Vector3(2.0, 0.55, 0.05), GREEN, hang)
	var faces := SignText.make_two_faces(AISLES[aisle][2] + " " + number, number + "  " + AISLES[aisle][1], 22, WHITE, 0.05)
	faces.name = "AisleSign"
	faces.position = hang
	unit.add_child(faces)


## Sloped crates of fruit and veg from the restaurant kit on a wooden stand.
static func fruit_and_veg(body: StaticBody3D, at: Vector3) -> void:
	var stand := Node3D.new()
	stand.name = "FruitAndVeg"
	stand.position = at
	body.add_child(stand)
	RestaurantRoom.block(body, Vector3(3.0, 0.7, 1.6), Color(0.6, 0.42, 0.26), at + Vector3(0, 0.35, 0))
	var crates := ["restaurant/crate_tomatoes", "restaurant/crate_lettuce", "restaurant/crate_carrots",
			"restaurant/crate_onions", "restaurant/crate_potatoes", "restaurant/crate_tomatoes"]
	for i in 6:
		var spot := Vector3(-1.0 + (i % 3) * 1.0, 0.72 + (i / 3) * 0.12, -0.35 + (i / 3) * 0.7)
		Props.kit(crates[i], stand, spot, Vector3(-12.0 if i >= 3 else 12.0, 0, 0), 0.45)
	var sign := SignText.make_face("فواكه وخضار", "Fruit and veg", 20, WHITE)
	sign.position = Vector3(0, 1.6, 0.85)
	stand.add_child(sign)
	LowPoly.box(stand, Vector3(1.6, 0.45, 0.04), GREEN, Vector3(0, 1.6, 0.82))
	for x in [-0.7, 0.7]:
		LowPoly.box(stand, Vector3(0.04, 0.9, 0.04), DARK, Vector3(x, 1.15, 0.82))


## The bread shelf on the left wall, facing into the shop.
static func bread_shelf(body: StaticBody3D, at: Vector3) -> void:
	var shelf := Node3D.new()
	shelf.name = "BreadShelf"
	shelf.position = at
	shelf.rotation_degrees.y = 90.0
	body.add_child(shelf)
	RestaurantRoom.block(body, Vector3(0.6, 1.9, 2.2), Color(0.6, 0.42, 0.26), at + Vector3(0, 0.95, 0))
	for level in 4:
		for k in 5:
			var loaf := LowPoly.sphere(shelf, 0.1, 0.16, Color(0.85, 0.6, 0.3).darkened(0.05 * (k % 3)), Vector3(-0.85 + k * 0.42, 0.4 + level * 0.42, 0.25))
			loaf.scale = Vector3(1.8, 1, 1)
	var sign := SignText.make_face("خبز", "Bread", 22, WHITE)
	sign.position = Vector3(0, 2.15, 0.31)
	shelf.add_child(sign)


## A checkout: a counter with a moving-belt top, a till, and (at checkout 1) the cashier.
static func checkout(body: StaticBody3D, at: Vector3, open: bool) -> void:
	var name := "Checkout1" if open else "Checkout2"
	var holder := Node3D.new()
	holder.name = name
	holder.position = at
	body.add_child(holder)
	RestaurantRoom.block(body, Vector3(1.9, 0.9, 0.75), WHITE.darkened(0.1), at + Vector3(0, 0.45, 0))
	LowPoly.box(holder, Vector3(1.3, 0.03, 0.55), DARK, Vector3(-0.25, 0.92, 0))
	for k in 6:  # the belt's ridges
		LowPoly.box(holder, Vector3(0.02, 0.035, 0.55), Color(0.25, 0.25, 0.27), Vector3(-0.8 + k * 0.22, 0.925, 0))
	LowPoly.box(holder, Vector3(0.4, 0.3, 0.35), DARK, Vector3(0.65, 1.05, -0.1))
	LowPoly.box(holder, Vector3(0.3, 0.2, 0.04), Color(0.3, 0.8, 0.9) if open else DARK, Vector3(0.65, 1.3, -0.08))
	# The checkout number on a little pole.
	LowPoly.cylinder(holder, 0.025, 0.025, 1.4, STEEL, Vector3(0.9, 1.6, -0.3))
	LowPoly.box(holder, Vector3(0.5, 0.35, 0.05), GREEN if open else Color(0.5, 0.5, 0.5), Vector3(0.9, 2.4, -0.3))
	var label := SignText.make_label("1" if open else "2", 40, WHITE, Color(0, 0, 0, 0), 0)
	label.position = Vector3(0.9, 2.4, -0.27)
	holder.add_child(label)
	if open:
		var cashier := RestaurantRoom.staff(body, at + Vector3(0.2, 0, -0.85), GREEN)
		cashier.set_meta("checkout", 1)
		for i in 3:  # shopping on the belt
			LowPoly.box(holder, Vector3(0.16, 0.2, 0.12), PRODUCTS[i][i], Vector3(-0.7 + i * 0.25, 1.04, 0))
	else:
		var closed := SignText.make_face("مغلق", "Closed", 14, WHITE)
		closed.position = Vector3(-0.3, 1.1, 0.0)
		closed.rotation.x = -0.4
		holder.add_child(closed)


## A rack of sweets by the checkouts.
static func sweets_rack(body: StaticBody3D, at: Vector3) -> void:
	var rack := Node3D.new()
	rack.name = "SweetsRack"
	rack.position = at
	body.add_child(rack)
	RestaurantRoom.block(body, Vector3(1.2, 1.4, 0.5), STEEL, at + Vector3(0, 0.7, 0))
	var sweets := [Color(0.95, 0.3, 0.4), Color(0.4, 0.25, 0.15), Color(0.98, 0.8, 0.2), Color(0.5, 0.8, 0.95), Color(0.6, 0.35, 0.75)]
	for level in 4:
		for k in 5:
			LowPoly.box(rack, Vector3(0.18, 0.22, 0.04), sweets[(k + level) % sweets.size()], Vector3(-0.45 + k * 0.22, 0.3 + level * 0.3, 0.27))


static func baskets_and_trolleys(body: StaticBody3D) -> void:
	for i in 4:  # a stack of red baskets by the door
		basket(body, Vector3(2.4, 0.12 + i * 0.12, 7.4))
	for i in 3:  # trolleys lined up
		trolley(body, Vector3(3.6 + i * 0.35, 0, 7.3), 0.0)


static func basket(parent: Node3D, spot: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Basket"
	holder.position = spot
	parent.add_child(holder, true)
	LowPoly.box(holder, Vector3(0.5, 0.22, 0.34), Color(0.85, 0.15, 0.15), Vector3(0, 0, 0))
	LowPoly.box(holder, Vector3(0.04, 0.2, 0.3), DARK, Vector3(0, 0.18, 0))
	return holder


static func trolley(parent: Node3D, spot: Vector3, facing: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Trolley"
	holder.position = spot
	holder.rotation_degrees.y = facing
	parent.add_child(holder, true)
	LowPoly.box(holder, Vector3(0.5, 0.45, 0.8), STEEL, Vector3(0, 0.75, 0))
	LowPoly.box(holder, Vector3(0.44, 0.4, 0.74), Color(0.55, 0.57, 0.6), Vector3(0, 0.78, 0))
	LowPoly.box(holder, Vector3(0.5, 0.04, 0.04), Color(0.85, 0.15, 0.15), Vector3(0, 1.05, 0.45))
	for x in [-0.2, 0.2]:
		for z in [-0.3, 0.3]:
			LowPoly.cylinder(holder, 0.05, 0.05, 0.04, DARK, Vector3(x, 0.05, z))
		LowPoly.box(holder, Vector3(0.03, 0.5, 0.03), STEEL, Vector3(x, 0.3, 0.38))
	return holder


## Shoppers: one pushing a trolley up and down aisle 2, one with a basket, one at the fruit.
static func shoppers(body: StaticBody3D, motion: VenueMotion) -> void:
	var walker := PeopleLooks.resident(1)
	walker.name = "Shopper"
	walker.position = Vector3(3.0, 0, 0.8)
	walker.rotation_degrees.y = -90.0
	body.add_child(walker, true)
	var cart := trolley(walker, Vector3(0, 0, -0.75), 0.0)
	cart.rotation_degrees.y = 180.0
	walker.play("walk", 0.6)
	walker.set_meta("static_batch_dynamic", true)
	motion.pacers.append([walker, Vector3(1.2, 0, 0.8), Vector3(4.8, 0, 0.8), 0.6])
	var browser := PeopleLooks.resident(4)
	browser.name = "Shopper"
	browser.position = Vector3(3.4, 0, 2.8)
	browser.rotation_degrees.y = 0.0
	body.add_child(browser, true)
	var hand := browser.follow("RightHand")
	basket(hand, browser.spot("RightHand") + Vector3(0, -0.15, 0)).scale = Vector3.ONE * 0.8
	var picker := PeopleLooks.resident(0)
	picker.name = "Shopper"
	picker.position = Vector3(-4.4, 0, 4.9)
	picker.rotation_degrees.y = 180.0  # looking at the fruit
	body.add_child(picker, true)
	trolley(body, Vector3(-5.3, 0, 4.7), 0.0)


## Bright, cool strip lights along the ceiling and two room lights.
static func lights(body: StaticBody3D) -> void:
	for i in 4:
		var strip := RestaurantRecipes.glow_box(body, Vector3(0.25, 0.05, 7.0), Color(0.95, 0.97, 1.0),
				Vector3(-4.5 + i * 3.0, RestaurantRoom.CEILING - 0.05, 3.0), 1.5)
		strip.name = "LampStrip%d" % (i + 1)
	for z in [1.0, 5.5]:
		var light := OmniLight3D.new()
		light.name = "InteriorLight" if z > 2.0 else "KitchenLight"
		light.position = Vector3(0, RestaurantRoom.CEILING - 0.5, z)
		light.light_color = Color(0.97, 0.97, 1.0)
		light.light_energy = 1.6
		light.omni_range = 9.0
		light.shadow_enabled = z > 2.0
		light.shadow_blur = 2.0
		light.distance_fade_enabled = true
		light.distance_fade_begin = 40.0
		light.distance_fade_shadow = 18.0
		light.distance_fade_length = 10.0
		body.add_child(light)
