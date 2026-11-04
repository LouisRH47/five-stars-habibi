class_name PeopleLooks
## Ready-made people (Session 29), all the same animated Person in different clothes:
##   resident(n):  the 5 customer outfits (white kandura, black abaya, t-shirt, red hoodie,
##                 green top with a cap)
##   teacher():    lanyard with a card, and a folder in one hand
##   school_kid(): smaller, school uniform and a little backpack
##   horse_rider() and groom(): riding helmet and boots
## Session 32: teachers and kids come to the school gate, riders and grooms to the stable
## office, as customers (scripts/customer.gd).
## Hats and bags are simple shapes that follow a bone (Person.follow()).

const SKINS := [Color(0.85, 0.66, 0.5), Color(0.7, 0.5, 0.35), Color(0.5, 0.35, 0.25), Color(0.93, 0.78, 0.65)]
const WHITE := Color(0.97, 0.97, 0.95)
const BLACK := Color(0.08, 0.08, 0.1)
## How many resident outfits there are.
const RESIDENT_OUTFITS := 5


## A resident in outfit number `outfit` (0 to 4) with skin colour number `skin`.
static func resident(outfit: int, skin: int = -1) -> Person:
	var person := Person.new()
	var tone: Color = SKINS[skin if skin >= 0 else randi() % SKINS.size()]
	match outfit % RESIDENT_OUTFITS:
		0:  # white kandura and ghutra (head cloth) with a black agal (the ring)
			person.paint({"skin": tone, "shirt": WHITE, "pants": WHITE})
			head_cloth(person, WHITE, true)
		1:  # black abaya and shayla (head scarf)
			person.paint({"skin": tone, "shirt": BLACK, "pants": BLACK})
			head_cloth(person, BLACK, false)
		2:  # t-shirt and jeans
			person.paint({"skin": tone, "shirt": Color(0.2, 0.45, 0.75), "pants": Color(0.25, 0.3, 0.45)})
		3:  # red hoodie
			person.paint({"skin": tone, "shirt": Color(0.85, 0.35, 0.3), "pants": Color(0.3, 0.3, 0.32)})
		4:  # green top and a cap
			person.paint({"skin": tone, "shirt": Color(0.35, 0.6, 0.4), "pants": Color(0.85, 0.8, 0.68)})
			cap(person, Color(0.95, 0.9, 0.8), person)
	return person


## A teacher with a lanyard and a folder.
static func teacher() -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS.pick_random(), "shirt": Color(0.7, 0.82, 0.92), "pants": Color(0.35, 0.36, 0.4)})
	shoes(person, Color(0.25, 0.18, 0.12))
	var chest := person.follow("Spine2")
	var neck := person.spot("Neck")
	for side in [-1.0, 1.0]:  # the cord, from the neck down to the card
		var cord := LowPoly.box(chest, Vector3(0.015, 0.26, 0.015), Color(0.15, 0.4, 0.8), neck + Vector3(0.05 * side, -0.12, -0.12))
		cord.rotation.z = 0.25 * side
	LowPoly.box(chest, Vector3(0.08, 0.1, 0.01), WHITE, neck + Vector3(0, -0.28, -0.14))  # the card
	var hand := person.follow("LeftHand")
	LowPoly.box(hand, Vector3(0.24, 0.03, 0.3), Color(0.9, 0.3, 0.25), person.spot("LeftHand") + Vector3(-0.05, -0.04, 0))
	return person


## A school kid in uniform with a little backpack.
static func school_kid() -> Person:
	var person := Person.new(GameConfig.KID_HEIGHT)
	person.paint({"skin": SKINS.pick_random(), "shirt": WHITE, "pants": Color(0.15, 0.2, 0.4)})
	backpack(person, Color(0.95, 0.75, 0.15), person, 0.7)
	shoes(person, BLACK)
	return person


## Someone riding a horse at the stables: riding helmet, cream jodhpurs, black boots.
static func horse_rider() -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS.pick_random(), "shirt": Color(0.15, 0.2, 0.35), "pants": Color(0.92, 0.88, 0.78)})
	riding_helmet(person, BLACK)
	boots(person, BLACK)
	return person


## A groom who looks after the horses: work polo, riding helmet and brown boots.
static func groom() -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS.pick_random(), "shirt": Color(0.25, 0.45, 0.3), "pants": Color(0.45, 0.38, 0.3)})
	riding_helmet(person, Color(0.3, 0.22, 0.15))
	boots(person, Color(0.35, 0.22, 0.12))
	return person


# --- Parts (each follows a bone; spots are on the person standing straight) ---

## How big the head is (metres from the bottom of the skull to the top).
static func head_size(person: Person) -> float:
	return person.spot("Head").distance_to(person.spot("HeadTop_End"))


## A head cloth: a ghutra (white, with the black agal ring) or a shayla (black scarf).
static func head_cloth(person: Person, colour: Color, agal: bool) -> Node3D:
	var holder := person.follow("Head")
	var head := person.head_spot()
	var r := head_size(person) * 0.62
	# Keep the front of the face open. A full sphere around the skull hid nearly all
	# of the face and made the kandura/abaya outfits appear to have no head.
	LowPoly.sphere(holder, r, r * 0.75, colour, head + Vector3(0, r * 0.65, 0))
	LowPoly.box(holder, Vector3(r * 2.0, r * 2.4, r * 0.6), colour, head + Vector3(0, -r * 0.7, r * 0.75))  # down the back
	for side in [-1.0, 1.0]:
		LowPoly.box(holder, Vector3(r * 0.25, r * 1.65, r * 1.0), colour,
				head + Vector3(side * r * 0.92, -r * 0.25, r * 0.25))
	if agal:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r * 0.75
		torus.outer_radius = r * 0.95
		torus.rings = 12
		torus.ring_segments = 6
		torus.material = LowPoly.material(BLACK)
		ring.mesh = torus
		ring.position = head + Vector3(0, r * 0.75, r * 0.2)
		holder.add_child(ring)
	return holder


## A baseball cap with its peak to the front.
static func cap(person: Person, colour: Color, parent: Node3D) -> Node3D:
	var holder := person.follow("Head", parent)
	var head := person.head_spot()
	var r := head_size(person) * 0.6
	LowPoly.sphere(holder, r, r * 1.1, colour, head + Vector3(0, r * 0.45, 0.01))
	LowPoly.box(holder, Vector3(r * 1.4, r * 0.12, r * 1.0), colour, head + Vector3(0, r * 0.4, -r * 1.2))
	return holder


## Sunglasses (Session 53): two lenses, a bridge, a thin top bar and two arms back to the
## ears, sized to the head and centred on it, so they don't stick out on one side like the old
## single black bar did. The face is towards -z.
static func sunglasses(person: Person, colour: Color, parent: Node3D = null) -> Node3D:
	var holder := person.follow("Head", parent)
	holder.name = "Sunglasses"
	var head := person.head_spot()
	var s := head_size(person)
	var front := -s * 0.5
	var y := -s * 0.13
	var lens := Vector3(s * 0.3, s * 0.15, s * 0.03)
	for side in [-1.0, 1.0]:
		LowPoly.box(holder, lens, colour, head + Vector3(side * s * 0.18, y, front))
		# The arm runs back along the side of the head to the ear.
		LowPoly.box(holder, Vector3(s * 0.025, s * 0.035, s * 0.5), colour,
				head + Vector3(side * s * 0.36, y + s * 0.05, front + s * 0.25))
	LowPoly.box(holder, Vector3(s * 0.74, s * 0.035, s * 0.035), colour, head + Vector3(0, y + s * 0.07, front))  # top bar
	LowPoly.box(holder, Vector3(s * 0.08, s * 0.03, s * 0.03), colour, head + Vector3(0, y + s * 0.02, front))   # bridge
	return holder


## A rounded riding helmet with a small peak.
static func riding_helmet(person: Person, colour: Color) -> Node3D:
	var holder := person.follow("Head")
	var head := person.head_spot()
	var r := head_size(person) * 0.64
	LowPoly.sphere(holder, r, r * 1.6, colour, head + Vector3(0, r * 0.25, 0.01))
	LowPoly.box(holder, Vector3(r * 1.2, r * 0.1, r * 0.6), colour, head + Vector3(0, r * 0.05, -r * 1.05))
	return holder


## A backpack on the upper back. size: 1 for a grown-up.
static func backpack(person: Person, colour: Color, parent: Node3D, size := 1.0) -> Node3D:
	var holder := person.follow("Spine2", parent)
	LowPoly.box(holder, Vector3(0.32, 0.38, 0.14) * size, colour, person.spot("Spine2") + Vector3(0, -0.12 * size, 0.15 * size))
	return holder


## Boots up to the middle of the shin, on both feet.
static func boots(person: Person, colour: Color) -> void:
	for side in ["Left", "Right"]:
		var foot := shoes_on(person, side, colour)
		var ankle := person.spot(side + "Foot")
		var tall := (person.spot(side + "Leg").y - ankle.y) * 0.55
		LowPoly.box(foot, Vector3(0.13, tall, 0.14), colour, ankle + Vector3(0, tall * 0.5 - 0.03, 0.01))


## Shoes on both feet (the model has bare feet).
static func shoes(person: Person, colour: Color) -> void:
	for side in ["Left", "Right"]:
		shoes_on(person, side, colour)


## One shoe on the "Left" or "Right" foot. Returns its holder.
static func shoes_on(person: Person, side: String, colour: Color) -> Node3D:
	var foot := person.follow(side + "Foot")
	var ankle := person.spot(side + "Foot")
	var toes := person.spot(side + "Toe_End")
	# Line the shoe up with the foot, from the heel (just behind the ankle) to the toes.
	var along := (toes - ankle).normalized()
	var up := (Vector3.UP - along * along.dot(Vector3.UP)).normalized()
	var shoe := LowPoly.box(foot, Vector3(0.12, 0.09, ankle.distance_to(toes) + 0.1), colour,
			(ankle + toes) * 0.5 - along * 0.04 - up * 0.03)
	shoe.basis = Basis.looking_at(along, up)
	return foot
