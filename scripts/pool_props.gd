class_name PoolProps
## Session 60: everything on the community pool deck, laid out like a real community pool:
## a row of 10 sun loungers along the long side with 4 umbrellas between them (5 people lying
## or sitting with a drink), the kids' pool right next to the loungers with 2 shade sails over
## it, the lifeguard on a tall chair in the middle of the other long side, an outdoor shower,
## a small changing hut, a bilingual pool rules sign by the gate and 2 palms in planters.
## Sizes from the plan's Appendix H (lounger 1.95 x 0.7, umbrella 2.5 across, chair 1.8 m).

const WHITE := Color(0.97, 0.97, 0.95)
const CUSHION := Color(0.15, 0.55, 0.65)
const UMBRELLA := Color(0.96, 0.62, 0.25)
const SAIL := Color(0.96, 0.94, 0.88)
const STEEL := Color(0.72, 0.74, 0.78)
const RED := Color(0.85, 0.2, 0.18)
const WOOD := Color(0.6, 0.42, 0.26)
const PALM_SCENE := preload("res://scenes/palm_tree.tscn")
const LOUNGER_STEP := 1.2   # metres between the two loungers of a pair
const PAIR_STEP := 3.2      # metres from one pair to the next (an umbrella stands in the gap)
## Which loungers have someone on them: lying down or sitting up with a drink.
const SUNBATHERS := {0: "lie", 2: "sit", 3: "lie", 6: "lie", 8: "sit"}


## Adds it all to the pool. detail: COMMUNITY_POOL_DETAIL from the data.
static func dress(pool: Pool, detail: Dictionary) -> void:
	var water: Rect2 = detail["water"]
	var kids: Rect2 = detail["kids"]
	var row_z: float = detail["loungers_z"]
	# 5 pairs of loungers with an umbrella between the pairs, ending right by the kids' pool.
	var start := kids.position.x - 2.0 - (LOUNGER_STEP + PAIR_STEP) * 4.0 - LOUNGER_STEP
	var people_left := int(detail["lounging"])
	for pair in 5:
		var x := start + pair * (LOUNGER_STEP + PAIR_STEP)
		for i in 2:
			var number := pair * 2 + i
			var who: String = SUNBATHERS.get(number, "") if people_left > 0 else ""
			if who != "":
				people_left -= 1
			_lounger(pool, Vector3(x + i * LOUNGER_STEP, 0, row_z), who, number)
		if pair < 4:
			_umbrella(pool, Vector3(x + LOUNGER_STEP + PAIR_STEP * 0.5, 0, row_z - 0.3))
	for i in 2:
		_sail(pool, kids, i)
	var chair: Vector2 = detail["lifeguard"]
	_lifeguard_chair(pool, Vector3(chair.x, 0, chair.y))
	var shower: Vector2 = detail["shower"]
	_shower(pool, Vector3(shower.x, 0, shower.y))
	_hut(pool, detail["hut"])
	var gate: Vector2 = detail["gate"]
	_rules_sign(pool, Vector3(gate.x + 2.6, 0, gate.y - 0.35))
	# Two little tables with chairs on the deck by the kids' pool, for the parents.
	for spot in [Vector3(kids.position.x + 1.5, 0, kids.end.y + 4.0), Vector3(kids.position.x + 5.5, 0, kids.end.y + 4.6)]:
		_table(pool, spot)
	var area := pool.area
	for corner in [Vector3(area.position.x + 1.4, 0, area.position.y + 1.4), Vector3(area.position.x + 1.4, 0, area.end.y - 1.4)]:
		_palm_planter(pool, corner)


## A sun lounger (1.95 long, feet towards the water) with someone lying or sitting on it.
static func _lounger(pool: Pool, spot: Vector3, who: String, number: int) -> void:
	var lounger := StaticBody3D.new()
	lounger.name = "Lounger"
	lounger.position = spot
	pool.add_child(lounger, true)
	var deck := GameConfig.POOL_DECK_Y
	for z in [-0.85, 0.85]:
		for x in [-0.3, 0.3]:
			LowPoly.box(lounger, Vector3(0.05, 0.3, 0.05), WHITE, Vector3(x, deck + 0.15, z))
	LowPoly.box(lounger, Vector3(0.7, 0.06, 1.3), WHITE, Vector3(0, deck + 0.32, 0.3))
	LowPoly.box(lounger, Vector3(0.64, 0.05, 1.25), CUSHION, Vector3(0, deck + 0.37, 0.3))
	# The back rest at the end away from the water: tilted up, or laid flat to sunbathe.
	var tilt := 0.0 if who == "lie" else deg_to_rad(-35.0)
	var lift := 0.0 if who == "lie" else 0.18
	var back := LowPoly.box(lounger, Vector3(0.7, 0.06, 0.66), WHITE, Vector3(0, deck + 0.32 + lift, -0.63))
	back.rotation.x = tilt
	var pad := LowPoly.box(lounger, Vector3(0.64, 0.05, 0.62), CUSHION, Vector3(0, deck + 0.37 + lift, -0.62))
	pad.rotation.x = tilt
	LowPoly.solid_box(lounger, Vector3(0.7, 0.5, 1.95), Vector3(0, 0.25, 0))
	if who == "":
		return
	var person := PeopleLooks.resident(2 + number % 3, number % 4)
	person.paint({"skin": PeopleLooks.SKINS[number % 4], "shirt": [Color(0.95, 0.4, 0.5), Color(0.2, 0.5, 0.8), Color(0.98, 0.8, 0.3)][number % 3],
			"pants": Color(0.15, 0.25, 0.5)})
	person.name = "Sunbather"
	if who == "lie":
		# On their back, head on the back rest (towards -z), feet towards the water.
		var holder := Node3D.new()
		holder.position = Vector3(0, deck + 0.4, 0.0)
		holder.rotation.y = PI
		lounger.add_child(holder, true)
		person.rotation.x = PI * 0.5
		person.position = Vector3(0, 0.1, -person.spot("Hips").y)
		holder.add_child(person, true)
		person.play("lie")
	else:
		# Sitting on the side of the lounger with a drink, looking at the water (+z).
		person.position = Vector3(0.05, deck + 0.45 - person.spot("Hips").y + 0.05, 0.35)
		person.rotation.y = PI
		lounger.add_child(person, true)
		person.play("sit")
		var hand := person.follow("RightHand")
		var cup := LowPoly.cylinder(hand, 0.04, 0.035, 0.12, [Color(0.95, 0.55, 0.15), Color(0.9, 0.3, 0.4)][number % 2],
				person.spot("RightHand") + Vector3(0, 0.05, 0))
		cup.name = "Drink"


## A small round table with two chairs and a little umbrella.
static func _table(pool: Pool, spot: Vector3) -> void:
	var table := StaticBody3D.new()
	table.name = "PoolTable"
	table.position = spot
	pool.add_child(table, true)
	var deck := GameConfig.POOL_DECK_Y
	LowPoly.cylinder(table, 0.4, 0.4, 0.04, WHITE, Vector3(0, deck + 0.74, 0))
	LowPoly.cylinder(table, 0.04, 0.04, 0.72, STEEL, Vector3(0, deck + 0.37, 0))
	LowPoly.cylinder(table, 0.02, 0.02, 1.5, WHITE, Vector3(0, deck + 1.4, 0))
	LowPoly.cylinder(table, 0.0, 0.9, 0.3, CUSHION, Vector3(0, deck + 2.2, 0))
	for side in [-1.0, 1.0]:
		LowPoly.box(table, Vector3(0.42, 0.04, 0.42), WHITE, Vector3(side * 0.7, deck + 0.45, 0))
		LowPoly.box(table, Vector3(0.04, 0.4, 0.42), WHITE, Vector3(side * 0.9, deck + 0.65, 0))
		for leg in [-0.17, 0.17]:
			LowPoly.box(table, Vector3(0.03, 0.45, 0.03), STEEL, Vector3(side * 0.7 + leg, deck + 0.22, 0.17))
			LowPoly.box(table, Vector3(0.03, 0.45, 0.03), STEEL, Vector3(side * 0.7 + leg, deck + 0.22, -0.17))
	LowPoly.solid_box(table, Vector3(1.8, 0.8, 0.8), Vector3(0, 0.4, 0))


## A big pool umbrella: 2.4 m tall, 2.5 m across.
static func _umbrella(pool: Pool, spot: Vector3) -> void:
	var holder := StaticBody3D.new()
	holder.name = "Umbrella"
	holder.position = spot
	pool.add_child(holder, true)
	LowPoly.cylinder(holder, 0.25, 0.3, 0.12, STEEL, Vector3(0, GameConfig.POOL_DECK_Y + 0.06, 0))
	LowPoly.cylinder(holder, 0.03, 0.03, 2.3, WHITE, Vector3(0, 1.2, 0))
	LowPoly.cylinder(holder, 0.0, 1.25, 0.45, UMBRELLA, Vector3(0, 2.2, 0))
	LowPoly.solid_cylinder(holder, 0.25, 1.0, Vector3(0, 0.5, 0))


## A triangle of shade cloth on posts over the kids' pool. which: 0 or 1 (west or east half).
static func _sail(pool: Pool, kids: Rect2, which: int) -> void:
	var x0 := kids.position.x - 0.6 + which * (kids.size.x * 0.5 + 1.1)   # posts never share a spot
	var x1 := x0 + kids.size.x * 0.5 + 0.6
	var corners := [Vector3(x0, 3.4, kids.position.y - 0.6), Vector3(x1, 2.8, kids.position.y - 0.6),
			Vector3((x0 + x1) * 0.5, 3.0, kids.end.y + 0.6)]
	if which == 1:
		corners[0].y = 2.8
		corners[1].y = 3.4
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for corner in corners:
		tool.add_vertex(corner)
	tool.generate_normals()
	var sail := MeshInstance3D.new()
	sail.name = "ShadeSail"
	sail.mesh = tool.commit()
	var cloth := LowPoly.material(SAIL).duplicate() as StandardMaterial3D
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	sail.material_override = cloth
	pool.add_child(sail, true)
	var posts := StaticBody3D.new()
	posts.name = "SailPosts"
	pool.add_child(posts, true)
	for corner: Vector3 in corners:
		var foot := Vector3(corner.x, 0, corner.z)
		# The posts stand on the deck just outside the kids' pool (never in the water).
		LowPoly.cylinder(posts, 0.05, 0.06, corner.y + 0.1, STEEL, foot + Vector3(0, (corner.y + 0.1) * 0.5, 0))
		LowPoly.solid_cylinder(posts, 0.08, corner.y, foot + Vector3(0, corner.y * 0.5, 0))


## The lifeguard's tall chair (1.8 m) with the lifeguard sitting on it, looking at the pool.
static func _lifeguard_chair(pool: Pool, spot: Vector3) -> void:
	var chair := StaticBody3D.new()
	chair.name = "LifeguardChair"
	chair.position = spot
	pool.add_child(chair, true)
	for x in [-0.4, 0.4]:
		for z in [-0.35, 0.35]:
			var leg := LowPoly.box(chair, Vector3(0.07, 1.9, 0.07), WHITE, Vector3(x, 0.95, z))
			leg.rotation.x = deg_to_rad(6.0 * signf(z))
		for y in [0.45, 0.9, 1.35]:
			LowPoly.box(chair, Vector3(0.06, 0.05, 0.7), WHITE, Vector3(x, y, 0))
	LowPoly.box(chair, Vector3(0.85, 0.06, 0.6), WHITE, Vector3(0, 1.5, 0))
	LowPoly.box(chair, Vector3(0.85, 0.5, 0.06), WHITE, Vector3(0, 1.78, 0.3))
	LowPoly.box(chair, Vector3(0.5, 0.35, 0.06), RED, Vector3(0, 0.9, 0.38))   # a red rescue float
	LowPoly.solid_box(chair, Vector3(0.9, 1.9, 0.8), Vector3(0, 0.95, 0))
	var guard := Person.new()
	guard.name = "Lifeguard"
	guard.paint({"skin": PeopleLooks.SKINS[1], "shirt": RED, "pants": Color(0.98, 0.85, 0.2)})
	PeopleLooks.cap(guard, RED, guard)
	guard.position = Vector3(0, 1.58 - guard.spot("Hips").y + 0.05, 0.05)
	chair.add_child(guard, true)   # people face -z, so the lifeguard looks north over the pool
	guard.play("sit")


## The outdoor shower: a steel post with a shower head and a drain tray.
static func _shower(pool: Pool, spot: Vector3) -> void:
	var shower := StaticBody3D.new()
	shower.name = "OutdoorShower"
	shower.position = spot
	pool.add_child(shower, true)
	LowPoly.box(shower, Vector3(1.0, 0.04, 1.0), Color(0.6, 0.62, 0.65), Vector3(0, GameConfig.POOL_DECK_Y + 0.02, 0))
	LowPoly.cylinder(shower, 0.05, 0.06, 2.3, STEEL, Vector3(0, 1.15, -0.4))
	LowPoly.box(shower, Vector3(0.05, 0.05, 0.4), STEEL, Vector3(0, 2.28, -0.22))
	LowPoly.cylinder(shower, 0.14, 0.04, 0.08, STEEL, Vector3(0, 2.22, -0.05))
	LowPoly.solid_cylinder(shower, 0.1, 2.3, Vector3(0, 1.15, -0.4))


## A small white changing hut (4 x 3 m) with a door and a bilingual sign.
static func _hut(pool: Pool, plot: Rect2) -> void:
	var hut := StaticBody3D.new()
	hut.name = "ChangingHut"
	hut.position = Vector3(plot.get_center().x, 0, plot.get_center().y)
	pool.add_child(hut, true)
	var size := Vector3(plot.size.x, 2.6, plot.size.y)
	LowPoly.box(hut, size, WHITE, Vector3(0, size.y * 0.5, 0))
	LowPoly.solid_box(hut, size, Vector3(0, size.y * 0.5, 0))
	LowPoly.box(hut, Vector3(size.x + 0.4, 0.15, size.z + 0.4), Color(0.16, 0.56, 0.61), Vector3(0, size.y + 0.07, 0))
	for x in [-0.9, 0.9]:   # two doors on the side facing the pool (+z)
		LowPoly.box(hut, Vector3(0.8, 2.0, 0.06), WOOD, Vector3(x, 1.0, size.z * 0.5 + 0.03))
	var face := SignText.make_face("غرف تبديل الملابس", "Changing rooms", SignText.fit_size("غرف تبديل الملابس", "Changing rooms", 40, size.x - 0.4), Color.WHITE,
			Color(0.16, 0.56, 0.61), 4)
	face.position = Vector3(0, 2.35, size.z * 0.5 + 0.08)
	hut.add_child(face)


## The pool rules sign on two posts by the gate, readable from the path (it faces +z).
static func _rules_sign(pool: Pool, spot: Vector3) -> void:
	var holder := StaticBody3D.new()
	holder.name = "PoolRulesSign"
	holder.position = spot
	pool.add_child(holder, true)
	for x in [-0.6, 0.6]:
		LowPoly.box(holder, Vector3(0.07, 1.9, 0.07), STEEL, Vector3(x, 0.95, 0))
	LowPoly.box(holder, Vector3(1.5, 1.0, 0.05), Color(0.1, 0.35, 0.55), Vector3(0, 1.5, 0))
	var title := SignText.make_face("قواعد المسبح", "Pool rules", 36, Color.WHITE)
	title.position = Vector3(0, 1.82, 0.035)
	holder.add_child(title, true)
	var rules := SignText.make_label("Shower first · No running\nNo glass · Kids with an adult", 20, Color.WHITE, Color(0, 0, 0, 0), 0)
	rules.position = Vector3(0, 1.37, 0.035)
	holder.add_child(rules, true)
	var arabic := SignText.make_label("الاستحمام أولاً · ممنوع الركض", 20, Color.WHITE, Color(0, 0, 0, 0), 0)
	arabic.position = Vector3(0, 1.12, 0.035)
	holder.add_child(arabic, true)
	LowPoly.solid_box(holder, Vector3(1.4, 1.9, 0.1), Vector3(0, 0.95, 0))


## A date palm in a round planter.
static func _palm_planter(pool: Pool, spot: Vector3) -> void:
	var planter := StaticBody3D.new()
	planter.name = "PalmPlanter"
	planter.position = spot
	pool.add_child(planter, true)
	LowPoly.cylinder(planter, 0.75, 0.65, 0.6, Color(0.85, 0.8, 0.7), Vector3(0, 0.3, 0))
	LowPoly.cylinder(planter, 0.68, 0.68, 0.04, Color(0.4, 0.3, 0.2), Vector3(0, 0.6, 0))
	LowPoly.solid_cylinder(planter, 0.75, 0.6, Vector3(0, 0.3, 0))
	var palm: Node3D = PALM_SCENE.instantiate()
	palm.position = spot + Vector3(0, 0.5, 0)
	pool.add_child(palm, true)
	palm.setup(int(spot.x))
