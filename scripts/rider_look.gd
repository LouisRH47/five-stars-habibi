class_name RiderLook
## Dresses the rider in one of the 3 looks from the application
## (PRD "3 character presets"). All three ride the same; only the look changes.
##   0 Classic: a cap, a hoodie, jeans, white trainers and a backpack
##   1 Sporty: a white helmet with stickers, a sports top, black leggings, running shoes
##   2 Chill: a bucket hat, sunglasses, shorts and canvas shoes
## Session 92: whatever the look, the rider wears the company's kit: the shirt in the
## company colour with its logo on the chest and the back, and the logo on the front of the
## cap, helmet or hat. The shoes are rounder, with soles and laces (scripts/shoes.gd).
## The rider is an animated Person (Session 29) with a "Helmet" that follows the head.
## make_rider() builds one; apply() dresses it. Used on the bike (Model/Rider), the
## walker, the start screen look cards and the clinic bed. The extra hats and bags of a
## look go in a "Look" node, so changing look removes the old ones.

const SKIN := Color(0.78, 0.58, 0.42, 1)
const HELMET_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)
const NONE := Color(0, 0, 0, 0)
## Each look's shoes: [colour, sole, laces].
const SHOES := [
	[Color(0.96, 0.96, 0.95), Color(0.55, 0.57, 0.6), Color(0.85, 0.2, 0.2)],
	[Color(0.12, 0.13, 0.15), Color(0.75, 0.95, 0.2), Color(0.97, 0.97, 0.95)],
	[Color(0.22, 0.32, 0.55), Color(0.95, 0.93, 0.86), Color(0.97, 0.97, 0.95)],
]


## A new rider (a Person named "Model") wearing the Snackaroo helmet.
static func make_rider() -> Person:
	var rider := Person.new()
	rider.name = "Model"
	var helmet := rider.follow("Head")
	helmet.name = "Helmet"
	var r := PeopleLooks.head_size(rider) * 0.66
	LowPoly.sphere(helmet, r, r * 1.35, HELMET_COLOUR, rider.head_spot() + Vector3(0, r * 0.2, 0.01))
	_shoes(rider, 0)
	return rider


## Changes `model` (a rider from make_rider()) to look number `look`.
## Session 88: the shirt is in your company's colour (company_id "" = the one you ride for).
static func apply(model: Node3D, look: int, company_id := "") -> void:
	var rider := model as Person
	var old := rider.get_node_or_null("Look")
	if old != null:
		old.free()
	var parts := Node3D.new()
	parts.name = "Look"
	rider.add_child(parts)
	var helmet := rider.get_node("Helmet") as Node3D
	var shell := helmet.get_child(0) as MeshInstance3D
	helmet.visible = true
	shell.material_override = null
	var head := rider.head_spot()
	var r := PeopleLooks.head_size(rider) * 0.66
	# This kit is also loaded while GameState itself is being compiled through the
	# map builders. Resolve the autoload at runtime to keep that dependency acyclic.
	var company := Companies.find(company_id) if company_id != "" else Companies.current()
	var logo := Companies.logo(company) if not company.is_empty() else null
	var dark: Color = company.get("dark", Color(0.6, 0.12, 0.12))
	var hat := rider.follow("Head", parts)
	hat.name = "HeadLogo"
	match look:
		0:  # Classic
			rider.paint({"skin": SKIN, "shirt": Color(0.32, 0.38, 0.48), "pants": Color(0.2, 0.25, 0.38)})
			helmet.visible = false
			_cap(rider, hat, dark)
			_sticker(hat, logo, head + Vector3(0, r * 0.78, -r * 0.84), 0.07, deg_to_rad(-30.0))
			var bag := PeopleLooks.backpack(rider, Color(0.15, 0.17, 0.2), parts)
			_sticker(bag, Companies.mark(company), rider.spot("Spine2") + Vector3(0, -0.1, 0.225), 0.22, 0.0, true)
		1:  # Sporty
			rider.paint({"skin": SKIN, "shirt": Color(0.75, 0.9, 0.2), "pants": Color(0.12, 0.12, 0.14)})
			shell.material_override = LowPoly.material(Color(0.95, 0.95, 0.97))
			var colours := [Color(0.95, 0.3, 0.3), Color(0.2, 0.55, 0.95), Color(0.98, 0.78, 0.1)]
			var spots := [Vector3(-0.95, 0.35, 0.1), Vector3(0.9, 0.4, 0.25), Vector3(0.0, 0.85, 0.25)]
			for i in 3:
				LowPoly.box(hat, Vector3.ONE * r * 0.35, colours[i], head + spots[i] * r)
			_sticker(hat, logo, head + Vector3(0, r * 0.5, -r * 1.0), 0.08, deg_to_rad(-30.0))
			_back_logo(rider, parts, company)
		2:  # Chill
			rider.paint({"skin": SKIN, "shirt": Color(0.95, 0.6, 0.65), "pants": Color(0.2, 0.5, 0.55)})
			helmet.visible = false
			var sand := Color(0.9, 0.84, 0.65)
			LowPoly.cylinder(hat, r * 1.5, r * 1.5, 0.02, sand, head + Vector3(0, r * 0.55, 0))      # brim
			LowPoly.cylinder(hat, r * 0.8, r * 0.95, r * 0.6, sand, head + Vector3(0, r * 0.85, 0))   # top
			LowPoly.cylinder(hat, r * 0.96, r * 0.96, r * 0.14, dark, head + Vector3(0, r * 0.62, 0))  # the band
			_sticker(hat, logo, head + Vector3(0, r * 0.85, -r * 0.92), 0.065, deg_to_rad(-12.0))
			LowPoly.box(hat, Vector3(r * 1.6, r * 0.28, 0.03), Color(0.05, 0.05, 0.05), head + Vector3(0, r * 0.05, -r * 0.95))  # sunglasses
			rider.repaint({"shins": SKIN})  # bare legs under the shorts
			_back_logo(rider, parts, company)
	_shoes(rider, look)
	if not company.is_empty():
		rider.repaint({"shirt": company["colour"]})
		var chest := rider.follow("Spine2", parts)
		chest.name = "ChestLogo"
		_sticker(chest, logo, rider.spot("Spine2") + GameConfig.RIDER_CHEST_LOGO, 0.085, deg_to_rad(8.0))
	var tree := Engine.get_main_loop() as SceneTree
	var state := tree.root.get_node_or_null("GameState") if tree != null else null
	if state != null:
		Wardrobe.apply(rider, state.equipped_cosmetics)


## A rounder cap: the crown, a curved peak to the front and a button on top.
static func _cap(rider: Person, holder: Node3D, colour: Color) -> void:
	var head := rider.head_spot()
	var r := PeopleLooks.head_size(rider) * 0.62
	LowPoly.sphere(holder, r * 0.95, r * 1.55, colour, head + Vector3(0, r * 0.5, 0.01))
	var peak := LowPoly.cylinder(holder, r * 0.72, r * 0.74, 0.018, colour.darkened(0.15), head + Vector3(0, r * 0.42, -r * 0.8))
	peak.scale = Vector3(1.0, 1.0, 0.85)
	peak.rotation.x = deg_to_rad(-8.0)  # the front edge tips down a little
	LowPoly.sphere(holder, r * 0.13, r * 0.12, colour.darkened(0.2), head + Vector3(0, r * 1.26, 0.01))


## The company's name and logo across the back of the shirt.
static func _back_logo(rider: Person, parts: Node3D, company: Dictionary) -> void:
	var back := rider.follow("Spine2", parts)
	back.name = "BackLogo"
	_sticker(back, Companies.mark(company), rider.spot("Spine2") + GameConfig.RIDER_BACK_LOGO, 0.24, deg_to_rad(-6.0), true)


## A flat picture (a logo) on `holder` at `spot`, `width` metres wide, facing forward (-Z),
## or backward (+Z) if back. tilt: radians it leans back (the front of a cap slopes).
static func _sticker(holder: Node3D, picture: Texture2D, spot: Vector3, width: float, tilt := 0.0,
		back := false) -> Sprite3D:
	if picture == null:
		return null
	var sticker := Sprite3D.new()
	sticker.name = "Logo"
	sticker.texture = picture
	sticker.pixel_size = width / picture.get_width()
	sticker.shaded = true
	sticker.double_sided = false
	sticker.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sticker.position = spot
	sticker.rotation = Vector3(tilt if back else -tilt, 0.0 if back else PI, 0)
	holder.add_child(sticker)
	return sticker


## The look's shoes (rounded, with soles and laces), replacing the old ones.
static func _shoes(rider: Person, look: int) -> void:
	for side in ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
		var holder := rider.get_node_or_null(side)
		if holder != null and (holder.has_node("Shoe") or holder.has_node("ShoeToe")):
			holder.free()
	var kit: Array = SHOES[clampi(look, 0, SHOES.size() - 1)]
	Shoes.put_on(rider, kit[0], kit[1], kit[2])
