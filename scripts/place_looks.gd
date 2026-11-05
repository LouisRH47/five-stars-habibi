class_name PlaceLooks
## Session 68: people dressed for where they are. All are the same animated Person
## (scripts/person.gd) in painted clothes, with small shapes that follow a bone.
## Each one gets meta "outfit" (the smoke test checks every place has its kind).
##   swimmer(i)        rash guard or bare top, swim shorts, sometimes a swim cap
##   lifeguard()       red top, yellow shorts, red cap, a rescue float
##   gym_goer(i)       sports top, leggings or shorts, trainers, towel and water bottle
##   pupil() teacher() school uniform and backpack / lanyard (from PeopleLooks)
##   rider() groom()   jodhpurs, helmet and boots (from PeopleLooks)
##   shopper(i)        casual clothes and a shopping bag
##   waiter(i)         white shirt, black trousers and an apron
##   commuter(i)       smart clothes with a backpack, or a suitcase beside them
##   jogger(i)         sports top, shorts, trainers
##   beekeeper()       white suit, wide hat and a dark veil, gloves
##   worker(i)         hi-vis vest and a hard hat
##   neighbour(i)      the 5 resident outfits (casual)

const SKINS := PeopleLooks.SKINS
const WHITE := Color(0.97, 0.97, 0.95)
const BLACK := Color(0.08, 0.08, 0.1)
const BRIGHT := [Color(0.95, 0.35, 0.45), Color(0.2, 0.6, 0.85), Color(0.3, 0.75, 0.55),
		Color(0.98, 0.7, 0.2), Color(0.6, 0.4, 0.8)]
const HI_VIS := Color(0.85, 1.0, 0.15)
const SAFETY_ORANGE := Color(1.0, 0.5, 0.1)


static func swimmer(i: int) -> Person:
	return dress_swimmer(Person.new(), i)


## Puts swimwear on someone already made (the pools' swimmers, scripts/district_detail.gd).
static func dress_swimmer(person: Person, i: int) -> Person:
	var skin: Color = SKINS[i % SKINS.size()]
	var suit: Color = BRIGHT[i % BRIGHT.size()]
	# Even numbers: bare top and swim shorts. Odd: a rash guard (swim top with sleeves).
	person.paint({"skin": skin, "shirt": skin if i % 2 == 0 else suit, "pants": skin})
	shorts(person, suit.darkened(0.25) if i % 2 == 0 else suit)
	if i % 3 == 1:
		swim_cap(person, suit.lightened(0.3))
	return _tag(person, "swimwear")


## with_float: holding the red rescue float (Session 81: the one on the tall chair hangs
## it on the chair and holds a whistle on a cord instead).
static func lifeguard(with_float := true) -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS.pick_random(), "shirt": Color(0.88, 0.12, 0.12), "pants": SKINS[1]})
	shorts(person, Color(1.0, 0.85, 0.1))
	PeopleLooks.cap(person, Color(0.88, 0.12, 0.12), person)
	var hand := person.follow("RightHand")
	if with_float:
		LowPoly.box(hand, Vector3(0.12, 0.7, 0.08), Color(0.95, 0.2, 0.15), _past_hand(person, "Right", 0.3))
	else:  # a silver whistle in the hand
		LowPoly.box(hand, Vector3(0.05, 0.035, 0.07), Color(0.82, 0.84, 0.86), _past_hand(person, "Right", 0.06))
	return _tag(person, "lifeguard")


static func gym_goer(i: int) -> Person:
	var person := Person.new()
	var top: Color = BRIGHT[(i + 1) % BRIGHT.size()]
	person.paint({"skin": SKINS[(i + 2) % SKINS.size()], "shirt": top, "pants": Color(0.12, 0.12, 0.15)})
	PeopleLooks.shoes(person, WHITE)
	var chest := person.follow("Spine2")
	var neck := person.spot("Neck")
	LowPoly.box(chest, Vector3(0.1, 0.03, 0.42), WHITE, neck + Vector3(0.12, -0.03, 0))  # towel over a shoulder
	var hand := person.follow("LeftHand")
	LowPoly.cylinder(hand, 0.035, 0.035, 0.2, Color(0.2, 0.7, 0.95), _past_hand(person, "Left", 0.08))  # water bottle
	return _tag(person, "gym")


static func pupil() -> Person:
	return _tag(PeopleLooks.school_kid(), "uniform")


static func teacher() -> Person:
	return _tag(PeopleLooks.teacher(), "lanyard")


static func rider() -> Person:
	return _tag(PeopleLooks.horse_rider(), "jodhpurs")


static func groom() -> Person:
	return _tag(PeopleLooks.groom(), "groom")


static func shopper(i: int) -> Person:
	var person := PeopleLooks.resident(i % PeopleLooks.RESIDENT_OUTFITS, i % SKINS.size())
	PeopleLooks.shoes(person, Color(0.3, 0.22, 0.15))
	var hand := person.follow("RightHand")
	LowPoly.box(hand, Vector3(0.3, 0.32, 0.12), BRIGHT[i % BRIGHT.size()], _past_hand(person, "Right", 0.2))
	return _tag(person, "shopping bag")


static func waiter(i: int) -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS[i % SKINS.size()], "shirt": WHITE, "pants": BLACK})
	PeopleLooks.shoes(person, BLACK)
	var hips := person.follow("Hips")
	var at := person.spot("Hips")
	LowPoly.box(hips, Vector3(0.36, 0.55, 0.03), [Color(0.45, 0.12, 0.15), Color(0.15, 0.35, 0.3)][i % 2],
			at + Vector3(0, -0.2, -0.14))
	return _tag(person, "apron")


static func commuter(i: int) -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS[(i + 1) % SKINS.size()], "shirt": [Color(0.75, 0.82, 0.9), WHITE, Color(0.4, 0.45, 0.5)][i % 3],
			"pants": Color(0.2, 0.22, 0.28)})
	PeopleLooks.shoes(person, Color(0.15, 0.1, 0.08))
	if i % 2 == 0:
		PeopleLooks.backpack(person, Color(0.15, 0.17, 0.2), person)
	else:  # a suitcase standing beside them, handle up
		LowPoly.box(person, Vector3(0.4, 0.55, 0.22), [Color(0.2, 0.35, 0.6), Color(0.6, 0.15, 0.2)][(i % 4) >> 1],
				Vector3(0.45, 0.3, -0.05))
		LowPoly.box(person, Vector3(0.04, 0.35, 0.04), Color(0.2, 0.2, 0.2), Vector3(0.45, 0.75, -0.05))
	return _tag(person, "luggage")


static func jogger(i: int) -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS[i % SKINS.size()], "shirt": BRIGHT[(i + 3) % BRIGHT.size()], "pants": SKINS[i % SKINS.size()]})
	shorts(person, Color(0.15, 0.15, 0.2))
	PeopleLooks.shoes(person, WHITE)
	return _tag(person, "sports")


static func beekeeper() -> Person:
	var person := Person.new()
	person.paint({"skin": SKINS[0], "shirt": WHITE, "pants": WHITE})
	PeopleLooks.boots(person, WHITE.darkened(0.15))
	var holder := person.follow("Head")
	var head := person.head_spot()
	var r := PeopleLooks.head_size(person) * 0.62
	LowPoly.cylinder(holder, r * 2.1, r * 2.1, 0.03, Color(0.95, 0.92, 0.82), head + Vector3(0, r * 0.9, 0))  # wide brim
	LowPoly.cylinder(holder, r * 0.95, r * 1.05, r * 0.7, Color(0.95, 0.92, 0.82), head + Vector3(0, r * 1.25, 0))
	var veil := LowPoly.cylinder(holder, r * 1.25, r * 1.4, r * 2.2, Color(0.12, 0.12, 0.12), head + Vector3(0, -r * 0.2, 0))
	veil.transparency = 0.35  # the dark mesh veil you can just see through
	for side in ["Left", "Right"]:
		var hand := person.follow(side + "Hand")
		LowPoly.sphere(hand, 0.07, 0.12, Color(0.92, 0.85, 0.6), person.spot(side + "Hand"))  # gloves
	return _tag(person, "bee suit")


static func worker(i: int) -> Person:
	return dress_worker(Person.new(), i)


## Puts work clothes, a hi-vis vest and a hard hat on someone already made (building sites).
static func dress_worker(person: Person, i: int) -> Person:
	person.paint({"skin": SKINS[(i + 1) % SKINS.size()], "shirt": [Color(0.3, 0.4, 0.55), Color(0.55, 0.45, 0.35)][i % 2],
			"pants": Color(0.25, 0.27, 0.3)})
	PeopleLooks.boots(person, Color(0.35, 0.25, 0.15))
	hi_vis(person)
	hard_hat(person, [Color(1.0, 0.85, 0.1), WHITE, SAFETY_ORANGE][i % 3])
	return _tag(person, "hi-vis")


static func neighbour(i: int) -> Person:
	var person := PeopleLooks.resident(i % PeopleLooks.RESIDENT_OUTFITS, (i * 3) % SKINS.size())
	PeopleLooks.shoes(person, Color(0.3, 0.22, 0.15))
	return _tag(person, "casual")


# --- Parts ---

## Swim or sports shorts: a short block on each thigh and one round the hips.
static func shorts(person: Person, colour: Color) -> void:
	for side in ["Left", "Right"]:
		var thigh := person.follow(side + "UpLeg")
		var top := person.spot(side + "UpLeg")
		var knee := person.spot(side + "Leg")
		LowPoly.box(thigh, Vector3(0.17, 0.24, 0.18), colour, top.lerp(knee, 0.28))
	var hips := person.follow("Hips")
	LowPoly.box(hips, Vector3(0.34, 0.14, 0.22), colour, person.spot("Hips") + Vector3(0, -0.02, 0))


static func swim_cap(person: Person, colour: Color) -> void:
	var holder := person.follow("Head")
	var r := PeopleLooks.head_size(person) * 0.62
	LowPoly.sphere(holder, r, r * 1.1, colour, person.head_spot() + Vector3(0, r * 0.35, 0.01))


## A bright vest with orange stripes over the top half of the body.
static func hi_vis(person: Person) -> void:
	var chest := person.follow("Spine1")
	var middle := (person.spot("Spine1") + person.spot("Spine2")) * 0.5
	LowPoly.box(chest, Vector3(0.38, 0.42, 0.25), HI_VIS, middle + Vector3(0, 0.02, 0))
	for y in [-0.08, 0.08]:
		LowPoly.box(chest, Vector3(0.39, 0.035, 0.26), SAFETY_ORANGE, middle + Vector3(0, y, 0))


static func hard_hat(person: Person, colour: Color) -> void:
	var holder := person.follow("Head")
	var head := person.head_spot()
	var r := PeopleLooks.head_size(person) * 0.64
	LowPoly.sphere(holder, r, r * 1.2, colour, head + Vector3(0, r * 0.4, 0.01))
	LowPoly.cylinder(holder, r * 1.25, r * 1.25, 0.03, colour, head + Vector3(0, r * 0.15, 0))


## A wide straw sun hat (gardeners).
static func sun_hat(person: Person) -> void:
	var holder := person.follow("Head")
	var head := person.head_spot()
	var r := PeopleLooks.head_size(person) * 0.62
	var straw := Color(0.9, 0.8, 0.5)
	LowPoly.cylinder(holder, r * 2.0, r * 2.0, 0.03, straw, head + Vector3(0, r * 0.75, 0))
	LowPoly.cylinder(holder, r * 0.85, r * 1.0, r * 0.75, straw, head + Vector3(0, r * 1.1, 0))
	LowPoly.cylinder(holder, r * 1.01, r * 1.01, r * 0.18, Color(0.35, 0.55, 0.3), head + Vector3(0, r * 0.85, 0))  # band


## A spot a little way past the hand along the forearm (where a held thing hangs).
static func _past_hand(person: Person, side: String, reach: float) -> Vector3:
	var hand := person.spot(side + "Hand")
	return hand + (hand - person.spot(side + "ForeArm")).normalized() * reach


static func _tag(person: Person, outfit: String) -> Person:
	person.set_meta("outfit", outfit)
	return person
