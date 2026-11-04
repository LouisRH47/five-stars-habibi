class_name ShopFront
extends RefCounted
## Session 57: the outside of a Plaza shop (PRD "Looks pass", The Plaza).
## Glass from the ground to 3.2 m so you can see inside, a sliding glass door, a sign band
## across the top with the shop's own logo (assets/logos/, made by tools/make_logos.py)
## and its Arabic and English names (lit up after sunset), a striped awning in the shop's
## colour, and 2 to 4 outside tables with umbrellas, with people eating at about half.
## Grand Groceries gets a supermarket front instead: two doors, trolleys, offer posters.
## The front is the shop's +Z side (like every venue). Numbers: game_config.gd, Session 57.

const FRAME := Color(0.17, 0.19, 0.21)
const PLINTH := Color(0.3, 0.31, 0.33)
const WALL := Color(0.95, 0.9, 0.8)        # the same cream as the venue walls
const WHITE := Color(0.98, 0.97, 0.94)
const METAL := Color(0.62, 0.64, 0.66)
const TABLE_TOP := Color(0.93, 0.92, 0.88)
const CHAIR := Color(0.24, 0.25, 0.27)
## How many outside tables each restaurant has (2 to 4).
const TABLES := {"pizza": 4, "gelato": 2, "boba": 4, "shawarma": 2, "bakery": 3,
		"thai": 4, "sushi": 2, "tacos": 4, "burger": 3}
const TABLE_X := {2: [-3.8, 3.8], 3: [-4.2, 2.6, 5.0], 4: [-5.0, -2.6, 2.6, 5.0]}
const TABLE_OUT := 2.6      # metres in front of the glass
const BENCH_OUT := 4.4      # the bench at the edge of the terrace, looking out at the Plaza

static var _glass: StandardMaterial3D
static var _frosted: StandardMaterial3D


## Builds the front onto `body` (a venue or shop). place: its data (id, name, arabic,
## colour). size: the room (width, height, depth). opens: false for a shop you can't enter.
static func build(body: StaticBody3D, place: Dictionary, size: Vector3, opens := true) -> Node3D:
	var front := Node3D.new()
	front.name = "ShopFront"
	body.add_child(front)
	body.set_meta("plaza_front", true)
	var id: String = place.get("id", "")
	var brand: Color = place.get("colour", Color(0.16, 0.56, 0.61))
	var f := size.z * 0.5
	var w := size.x
	var top := GameConfig.PLAZA_GLASS_TOP
	var door_w := GameConfig.PLAZA_DOOR_WIDTH
	var market := id == "market"
	var doors: Array[float] = [0.0]
	if market:
		doors.append(w * 0.5 - 4.0)
	var kit := MeshKit.new()
	# Glass between the doors, on a dark plinth, with thin frame posts.
	var edges: Array[float] = [-w * 0.5 + 0.13]
	for x in doors:
		edges.append(x - door_w * 0.5)
		edges.append(x + door_w * 0.5)
	edges.append(w * 0.5 - 0.13)
	var glass := glass_material(opens)
	for i in range(0, edges.size(), 2):
		var a: float = edges[i]
		var b: float = edges[i + 1]
		var mid := (a + b) * 0.5
		kit.box(Vector3(b - a, 0.3, 0.14), PLINTH, Vector3(mid, 0.15, f + 0.02))
		var pane := LowPoly.box(front, Vector3(b - a, top - 0.3, 0.03), WHITE, Vector3(mid, 0.3 + (top - 0.3) * 0.5, f))
		pane.material_override = glass
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		LowPoly.solid_box(body, Vector3(b - a, top, 0.2), Vector3(mid, top * 0.5, f))
		var posts := maxi(1, ceili((b - a) / 2.2))
		for k in posts + 1:
			kit.box(Vector3(0.08, top, 0.1), FRAME, Vector3(a + (b - a) * k / posts, top * 0.5, f))
	kit.box(Vector3(w - 0.26, 0.1, 0.12), FRAME, Vector3(0, top, f))
	for x in doors:
		var transom := LowPoly.box(front, Vector3(door_w, top - 2.65, 0.03), WHITE, Vector3(x, 2.6 + (top - 2.6) * 0.5, f))
		transom.material_override = glass
		kit.box(Vector3(door_w, 0.08, 0.1), FRAME, Vector3(x, 2.6, f))
		var door := SlidingDoor.new()
		door.name = "SlidingDoor"
		door.width = door_w
		door.height = 2.56
		door.locked = not opens
		door.position = Vector3(x, 0.02, f - 0.1)
		front.add_child(door)
		door.build(glass, FRAME)
	# The wall between the glass and the flats, and the lit sign band on it.
	kit.box(Vector3(w, size.y - top, 0.24), WALL, Vector3(0, top + (size.y - top) * 0.5, f - 0.12))
	_sign_band(front, place, w, f, top, brand, market)
	_awning(kit, w, f, top, brand, market)
	if market:
		_market_extras(front, kit, body, w, f)
	elif TABLES.has(id):
		_tables(front, kit, body, id, f, brand)
	if opens:
		# Session 53 rule: benches outside the shops look out at the Plaza, not at the glass.
		Props.bench(body, Vector3(-8.0 if market else 3.5, 0, f + BENCH_OUT), 0)
	var view := kit.finish("FrontParts")
	front.add_child(view)
	return front


## The see-through glass (the pharmacy's is frosted, so you can't see in).
static func glass_material(clear := true) -> StandardMaterial3D:
	if clear and _glass != null:
		return _glass
	if not clear and _frosted != null:
		return _frosted
	var made := StandardMaterial3D.new()
	made.albedo_color = Color(0.62, 0.82, 0.9, 0.22) if clear else Color(0.9, 0.95, 0.94, 0.75)
	made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	made.roughness = 0.08
	made.metallic_specular = 0.8
	if clear:
		_glass = made
	else:
		_frosted = made
	return made


## The sign band: the shop's colour, its round logo on the left, Arabic over English.
## Its material lights up after sunset (NightGlow), and the letters always shine.
static func _sign_band(front: Node3D, place: Dictionary, w: float, f: float, top: float, brand: Color, big: bool) -> void:
	var band_h := GameConfig.PLAZA_SIGN_BAND
	var y := top + 0.12 + band_h * 0.5
	var band := LowPoly.box(front, Vector3(w - 0.3, band_h, 0.22), brand, Vector3(0, y, f + 0.11))
	band.name = "SignBand"
	var lit := StandardMaterial3D.new()
	lit.albedo_color = brand
	lit.roughness = 0.6
	lit.emission = brand
	lit.emission_enabled = true
	lit.emission_energy_multiplier = 0.0
	band.material_override = lit
	band.set_meta("static_batch_dynamic", true)   # NightGlow changes its brightness
	band.add_to_group("plaza_glow")
	var logo_path := "res://assets/logos/%s_badge.svg" % place.get("id", "")
	var logo_size := band_h - 0.14
	if ResourceLoader.exists(logo_path):
		var badge := MeshInstance3D.new()
		badge.name = "Logo"
		var quad := QuadMesh.new()
		quad.size = Vector2(logo_size, logo_size)
		badge.mesh = quad
		var picture := StandardMaterial3D.new()
		picture.albedo_texture = load(logo_path)
		picture.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		picture.alpha_scissor_threshold = 0.5
		picture.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		picture.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		badge.material_override = picture
		badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		badge.position = Vector3(-w * 0.5 + 0.2 + logo_size * 0.5 + 0.1, y, f + 0.225)
		front.add_child(badge)
	var arabic: String = place.get("arabic", "")
	var english: String = place.get("name", "")
	var room := w - 0.6 - logo_size - 0.5
	var font_size := SignText.fit_size(arabic, english, 84 if big else 70, room)
	var face := SignText.make_face(arabic, english, font_size, Color.WHITE, brand.darkened(0.45), 5)
	face.name = "BilingualSign"
	face.position = Vector3(logo_size * 0.5 + 0.05, y - 0.02, f + 0.226)
	front.add_child(face)


## A striped awning (the shop's colour and white) under the sign band, with a short flap.
static func _awning(kit: MeshKit, w: float, f: float, top: float, brand: Color, market: bool) -> void:
	var depth := GameConfig.PLAZA_AWNING_DEPTH
	var drop := 0.38
	var tilt := atan2(drop, depth)
	var turn := Basis(Vector3.RIGHT, tilt)
	var across := w - 0.5
	var stripes := maxi(4, roundi(across / 0.75))
	var stripe := across / stripes
	var long := sqrt(depth * depth + drop * drop)
	var second := WHITE if not market else Color(0.9, 0.97, 0.9)
	for i in stripes:
		var colour: Color = brand if i % 2 == 0 else second
		var x := -across * 0.5 + stripe * (i + 0.5)
		kit.box(Vector3(stripe, 0.05, long), colour, Vector3(x, top + 0.04 - drop * 0.5, f + depth * 0.5), turn)
		kit.box(Vector3(stripe, 0.26, 0.03), colour, Vector3(x, top + 0.04 - drop - 0.13, f + depth))
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.04, 0.04, long), FRAME, Vector3(side * across * 0.5, top - drop * 0.5 + 0.01, f + depth * 0.5), turn)


## Outside tables with umbrellas in the shop's colour; someone eats at about half of them.
static func _tables(front: Node3D, kit: MeshKit, body: StaticBody3D, id: String, f: float, brand: Color) -> void:
	var count: int = TABLES[id]
	var seed_number := absi(id.hash())
	for i in count:
		var x: float = TABLE_X[count][i]
		var at := Vector3(x, 0, f + TABLE_OUT)
		kit.cylinder(0.38, 0.38, 0.04, TABLE_TOP, at + Vector3(0, 0.74, 0), Basis(), 10)
		kit.cylinder(0.04, 0.04, 0.72, METAL, at + Vector3(0, 0.36, 0), Basis(), 6)
		kit.cylinder(0.22, 0.25, 0.03, METAL, at + Vector3(0, 0.015, 0), Basis(), 8)
		# The umbrella: a pole through the table and a cone in the shop's colour.
		kit.cylinder(0.025, 0.025, 2.2, WHITE, at + Vector3(0, 1.1, 0), Basis(), 6)
		kit.cylinder(0.0, 1.05, 0.42, brand, at + Vector3(0, 2.3, 0), Basis(), 8)
		kit.cylinder(1.05, 1.05, 0.12, brand.darkened(0.15), at + Vector3(0, 2.05, 0), Basis(), 8)
		for side in [-1.0, 1.0]:
			var seat := at + Vector3(0, 0, side * 0.72)
			kit.box(Vector3(0.42, 0.05, 0.42), CHAIR, seat + Vector3(0, 0.45, 0))
			kit.box(Vector3(0.42, 0.42, 0.04), CHAIR, seat + Vector3(0, 0.68, side * 0.2))
			for leg in [Vector3(-0.18, 0, -0.18), Vector3(0.18, 0, -0.18), Vector3(-0.18, 0, 0.18), Vector3(0.18, 0, 0.18)]:
				kit.box(Vector3(0.03, 0.44, 0.03), CHAIR, seat + leg + Vector3(0, 0.22, 0))
		LowPoly.solid_cylinder(body, 0.42, 0.8, at + Vector3(0, 0.4, 0))
		# About half the tables have someone eating (always the same ones for the same shop).
		if (seed_number + i) % 2 == 0:
			var diner := PeopleLooks.resident((seed_number + i) % 5, (seed_number / 7 + i) % 4)
			diner.name = "OutsideDiner"
			var side := -1.0 if (seed_number + i) % 4 == 0 else 1.0
			diner.position = at + Vector3(0, -0.45, side * 0.72)
			diner.rotation.y = PI if side < 0.0 else 0.0   # facing the table
			body.add_child(diner)
			if diner.can_do("sit"):
				diner.play("sit")
			kit.cylinder(0.12, 0.12, 0.02, WHITE, at + Vector3(0.05, 0.77, side * 0.18), Basis(), 8)


## Grand Groceries: trolleys lined up, a basket stand by the door and offer posters.
static func _market_extras(front: Node3D, kit: MeshKit, body: StaticBody3D, w: float, f: float) -> void:
	# The trolley bay: a low rail and 8 trolleys pushed into each other.
	var bay := Vector3(-w * 0.5 + 5.5, 0, f + 1.6)
	kit.box(Vector3(4.2, 0.06, 0.06), METAL, bay + Vector3(0, 0.9, -0.45))
	kit.box(Vector3(4.2, 0.06, 0.06), METAL, bay + Vector3(0, 0.9, 0.45))
	for x in [-2.05, 2.05]:
		kit.box(Vector3(0.06, 0.9, 1.0), METAL, bay + Vector3(x, 0.45, 0))
	for i in GameConfig.PLAZA_TROLLEYS:
		var at := bay + Vector3(-1.6 + i * 0.42, 0, 0)
		kit.box(Vector3(0.75, 0.04, 0.5), METAL, at + Vector3(0, 0.35, 0))           # bottom rack
		kit.box(Vector3(0.7, 0.45, 0.04), METAL, at + Vector3(0, 0.75, -0.24))      # sides
		kit.box(Vector3(0.7, 0.45, 0.04), METAL, at + Vector3(0, 0.75, 0.24))
		kit.box(Vector3(0.04, 0.5, 0.5), Color(0.2, 0.62, 0.32), at + Vector3(0.32, 0.95, 0))   # green handle end
		for corner in [Vector3(-0.3, 0, -0.2), Vector3(0.3, 0, -0.2), Vector3(-0.3, 0, 0.2), Vector3(0.3, 0, 0.2)]:
			kit.cylinder(0.05, 0.05, 0.04, FRAME, at + corner + Vector3(0, 0.05, 0), Basis(Vector3.RIGHT, PI * 0.5), 6)
	LowPoly.solid_box(body, Vector3(4.2, 1.0, 1.0), bay + Vector3(0, 0.5, 0))
	# A stand of green shopping baskets by the main door.
	var stand := Vector3(-2.2, 0, f + 0.55)
	kit.box(Vector3(0.5, 0.06, 0.4), METAL, stand + Vector3(0, 0.03, 0))
	for k in 5:
		kit.box(Vector3(0.46, 0.08, 0.36), Color(0.18, 0.62, 0.31), stand + Vector3(0, 0.12 + k * 0.1, 0))
	# Offer posters inside the windows.
	for poster: Array in [[-6.5, "فواكه طازجة", "Fresh fruit", Color(1, 0.84, 0.25)], [4.0, "٢ بـ ١٠ درهم", "2 for 10 Dh", Color(0.95, 0.3, 0.25)]]:
		var x: float = poster[0]
		kit.box(Vector3(1.5, 1.1, 0.03), poster[3], Vector3(x, 1.75, f - 0.06))
		var face := SignText.make_face(poster[1], poster[2], 30, Color(0.1, 0.12, 0.14))
		face.name = "OfferPoster"
		face.position = Vector3(x, 1.75, f - 0.04)
		front.add_child(face)
