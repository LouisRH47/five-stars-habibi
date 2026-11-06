class_name PoolDeck
extends RefCounted
## Session 81: makes a pool look like a real pool. Every pool (the community pool, the
## gym's lap pool and the two school pools) gets:
##   - a tiled stone deck round it (a tile picture made in code, mapped in world metres)
##   - a proper edge: a pale stone coping that sticks out a little over the water, with a
##     band of dark blue waterline tiles under it
##   - water a little below the edge, with the tiled floor and lane lines seen through it
##     (scripts/water_look.gd)
##   - steel ladders and lane ropes with floats
## The community pool also gets its loungers and umbrellas, the kids' area with a ring of
## floats and a mushroom fountain, a shower post by the gate and plants.
## DistrictDetail._pool() calls build(). Swimmers float at GameConfig.POOL_WATER_Y (the
## pool's node also has it as meta "water_y"). Nothing here is solid.

const COPING := Color(0.95, 0.94, 0.9)
const WATERLINE := Color(0.1, 0.32, 0.58)
const STEEL := Color(0.8, 0.82, 0.85)
const WHITE := Color(0.97, 0.97, 0.95)
const ROPE_END := Color(0.9, 0.15, 0.15)
const ROPE := [Color(0.1, 0.35, 0.85), Color(0.97, 0.97, 0.95)]
const CUSHIONS := [Color(0.16, 0.56, 0.61), Color(0.97, 0.97, 0.95), Color(0.95, 0.6, 0.25)]
const TOWELS := [Color(0.95, 0.45, 0.5), Color(0.98, 0.8, 0.25), Color(0.3, 0.65, 0.85)]
const UMBRELLAS := [Color(0.96, 0.64, 0.28), Color(0.16, 0.56, 0.61), Color(0.97, 0.95, 0.9)]
const POT := Color(0.72, 0.42, 0.28)
const LEAVES := [Color(0.25, 0.5, 0.22), Color(0.33, 0.6, 0.27)]
const FLOWERS := [Color(0.95, 0.4, 0.55), Color(1.0, 0.8, 0.2), Color(0.97, 0.97, 0.95)]
const TRUNK := Color(0.5, 0.38, 0.25)
const COPING_WIDTH := 0.35
const OVERHANG := 0.04   # how far the coping sticks out over the water

static var _tiles: StandardMaterial3D


## kind: "community", "lap" or "school". deck: the tiled area round the pool (bigger than area).
static func build(room: Node3D, area: Rect2, kind: String, deck: Rect2) -> void:
	room.set_meta("water_y", GameConfig.POOL_WATER_Y)
	room.set_meta("pool_area", area)
	var ropes: int = {"community": 3, "lap": 3, "school": 2}.get(kind, 0)
	var along_x := area.size.x >= area.size.y
	var spacing := (area.size.y if along_x else area.size.x) / (ropes + 1)
	_deck(room, area, deck)
	var water := WaterLook.pool(spacing, area.position.y if along_x else area.position.x, along_x)
	var surface := LowPoly.box(room, Vector3(area.size.x, 0.06, area.size.y), WHITE,
			Vector3(area.get_center().x, GameConfig.POOL_WATER_Y - 0.03, area.get_center().y))
	surface.name = "Water"  # StaticBatch leaves "Water" alone (it moves)
	surface.material_override = water
	var kit := MeshKit.new()
	_edge(kit, area)
	var rope_end := area.end.x - (8.5 if kind == "community" else 0.4)  # stop before the kids' area
	_ropes(kit, area, ropes, along_x, rope_end)
	var ladders := _ladder_spots(area, kind)
	for ladder: Array in ladders:
		_ladder(kit, ladder[0], ladder[1])
	var parts := {"ladders": ladders.size(), "ropes": ropes if along_x else 0, "loungers": 0, "umbrellas": 0, "showers": 0, "plants": 0}
	if kind == "community":
		_kids_area(room, kit, Vector2(area.end.x - 4.5, area.get_center().y))
		parts["loungers"] = 7
		parts["umbrellas"] = 6
		_loungers(kit, area, deck)
		room.set_meta("loungers", lounger_spots(area, deck))  # Session 92: for the sunbathers
		_shower(kit, Vector3(area.position.x + 6.5, GameConfig.POOL_DECK_Y, (area.end.y + COPING_WIDTH + deck.end.y) * 0.5))
		parts["showers"] = 1
		parts["plants"] = _plants(kit, deck)
	room.add_child(kit.finish("PoolDetails"))
	room.set_meta("pool_parts", parts)  # the smoke test checks these


## The four tiled strips of deck round the water (not under it, so they don't flicker).
static func _deck(room: Node3D, area: Rect2, deck: Rect2) -> void:
	var kit := MeshKit.new()
	var top := GameConfig.POOL_DECK_Y
	for strip: Rect2 in [Rect2(deck.position.x, deck.position.y, deck.size.x, area.position.y - deck.position.y),
			Rect2(deck.position.x, area.end.y, deck.size.x, deck.end.y - area.end.y),
			Rect2(deck.position.x, area.position.y, area.position.x - deck.position.x, area.size.y),
			Rect2(area.end.x, area.position.y, deck.end.x - area.end.x, area.size.y)]:
		if strip.size.x > 0.01 and strip.size.y > 0.01:
			kit.box(Vector3(strip.size.x, top, strip.size.y), WHITE, Vector3(strip.get_center().x, top * 0.5, strip.get_center().y))
	var view := kit.finish("PoolDeck")
	view.material_override = tile_material()
	room.add_child(view)


## The coping (stone edge) round the water, and the waterline tiles under it.
static func _edge(kit: MeshKit, area: Rect2) -> void:
	var outer := area.grow(COPING_WIDTH - OVERHANG)
	var inner := area.grow(-OVERHANG)
	var y := GameConfig.POOL_COPING_Y - 0.03
	for z: float in [outer.position.y + COPING_WIDTH * 0.5, outer.end.y - COPING_WIDTH * 0.5]:
		kit.box(Vector3(outer.size.x, 0.06, COPING_WIDTH), COPING, Vector3(outer.get_center().x, y, z))
	for x: float in [outer.position.x + COPING_WIDTH * 0.5, outer.end.x - COPING_WIDTH * 0.5]:
		kit.box(Vector3(COPING_WIDTH, 0.06, inner.size.y), COPING, Vector3(x, y, inner.get_center().y))
	var band := 0.1  # how tall the waterline tiles are (most of it under the water)
	var middle := GameConfig.POOL_WATER_Y + 0.05 - band * 0.5
	for z: float in [area.position.y + 0.015, area.end.y - 0.015]:
		kit.box(Vector3(area.size.x, band, 0.03), WATERLINE, Vector3(area.get_center().x, middle, z))
	for x: float in [area.position.x + 0.015, area.end.x - 0.015]:
		kit.box(Vector3(0.03, band, area.size.y), WATERLINE, Vector3(x, middle, area.get_center().y))


## Lane ropes: floats in short pieces, red near the ends, blue and white in the middle.
static func _ropes(kit: MeshKit, area: Rect2, count: int, along_x: bool, end_x: float) -> void:
	if not along_x:
		return  # every pool in the game is longer along x
	var spacing := area.size.y / (count + 1)
	var lying := Basis(Vector3.BACK, PI * 0.5)
	for k in range(1, count + 1):
		var z := area.position.y + k * spacing
		var x := area.position.x + 0.3
		var i := 0
		while x + 0.5 <= end_x:
			var colour: Color = ROPE_END if x - area.position.x < 2.5 or end_x - x < 3.0 else ROPE[(i / 2) % 2]
			kit.cylinder(0.055, 0.055, 0.46, colour, Vector3(x + 0.25, GameConfig.POOL_WATER_Y, z), lying, 6)
			x += 0.5
			i += 1
		for end in [area.position.x + 0.1, x + 0.1]:  # the hooks on the pool wall
			kit.box(Vector3(0.12, 0.08, 0.12), STEEL, Vector3(end, GameConfig.POOL_WATER_Y + 0.03, z))


## Where the ladders go: [spot on the pool's edge, direction into the water].
static func _ladder_spots(area: Rect2, kind: String) -> Array:
	var north := Vector2(0, 1)
	var south := Vector2(0, -1)
	match kind:
		"community":
			return [[Vector2(area.position.x + 2.5, area.position.y), north], [Vector2(area.end.x - 11.0, area.position.y), north],
					[Vector2(area.position.x + 2.5, area.end.y), south], [Vector2(area.end.x - 11.0, area.end.y), south]]
		"lap":
			return [[Vector2(area.position.x + 1.5, area.position.y), north], [Vector2(area.end.x - 1.5, area.end.y), south]]
	return [[Vector2(area.position.x + 1.5, area.position.y), north], [Vector2(area.end.x - 1.5, area.end.y), south]]


## A steel pool ladder: two rails that come up out of the water, bend over the edge and
## go down onto the deck.
static func _ladder(kit: MeshKit, edge: Vector2, into: Vector2) -> void:
	var side := Vector2(into.y, -into.x)
	var top := 0.9
	var across := Basis(Quaternion(Vector3.UP, Vector3(into.x, 0, into.y)))
	for s: float in [-0.25, 0.25]:
		var base := edge + side * s
		var wet := base + into * 0.14
		var dry := base - into * 0.4
		kit.cylinder(0.025, 0.025, top, STEEL, Vector3(wet.x, top * 0.5, wet.y))
		kit.cylinder(0.025, 0.025, 0.56, STEEL, Vector3((wet.x + dry.x) * 0.5, top, (wet.y + dry.y) * 0.5), across)
		var deck := GameConfig.POOL_DECK_Y
		kit.cylinder(0.025, 0.025, top - deck, STEEL, Vector3(dry.x, (top + deck) * 0.5, dry.y))
		kit.cylinder(0.06, 0.06, 0.02, STEEL, Vector3(dry.x, deck + 0.01, dry.y))


## The kids' area at the shallow end: lighter water, a ring of floats and a mushroom fountain.
static func _kids_area(room: Node3D, kit: MeshKit, centre: Vector2) -> void:
	var radius := 3.0
	var shallow := LowPoly.cylinder(room, radius - 0.05, radius - 0.05, 0.02, WHITE,
			Vector3(centre.x, GameConfig.POOL_WATER_Y, centre.y))  # its top is 1 cm over the water
	shallow.name = "KidsWater"
	shallow.material_override = WaterLook.kids_pool()
	var pieces := 36
	for i in pieces:
		var a := TAU * (i + 0.5) / pieces
		var at := Vector3(centre.x + cos(a) * radius, GameConfig.POOL_WATER_Y + 0.02, centre.y + sin(a) * radius)
		kit.cylinder(0.06, 0.06, radius * TAU / pieces * 0.9, ROPE_END if i % 2 == 0 else WHITE, at,
				Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, PI * 0.5), 6)
	var middle := Vector3(centre.x, GameConfig.POOL_WATER_Y, centre.y)
	kit.cylinder(0.08, 0.1, 1.3, WHITE, middle + Vector3(0, 0.65, 0))
	kit.cylinder(0.08, 0.85, 0.35, Color(0.98, 0.75, 0.2), middle + Vector3(0, 1.45, 0), Basis(), 10)
	kit.ball(0.12, Color(0.95, 0.4, 0.55), middle + Vector3(0, 1.66, 0))


## Loungers along the north side (where the old sunbeds were) with umbrellas between them.
static func _loungers(kit: MeshKit, area: Rect2, deck: Rect2) -> void:
	var y := GameConfig.POOL_DECK_Y
	var z := (deck.position.y + area.position.y - COPING_WIDTH) * 0.5
	var middle := area.get_center().x
	var spots := lounger_spots(area, deck)
	for i in spots.size():
		_lounger(kit, spots[i], i)
	for i in 6:
		_umbrella(kit, Vector3(middle - 15 + i * 6, y, z), UMBRELLAS[i % UMBRELLAS.size()])


## Session 92: the middle of each of the 7 loungers (on the deck, north of the pool).
static func lounger_spots(area: Rect2, deck: Rect2) -> Array[Vector3]:
	var z := (deck.position.y + area.position.y - COPING_WIDTH) * 0.5
	var spots: Array[Vector3] = []
	for i in 7:
		spots.append(Vector3(area.get_center().x - 18 + i * 6, GameConfig.POOL_DECK_Y, z))
	return spots


## One lounger (along x, its back raised at the +x end) on the deck at `at`.
static func _lounger(kit: MeshKit, at: Vector3, i: int) -> void:
	var cushion: Color = CUSHIONS[i % CUSHIONS.size()]
	for x: float in [-0.85, 0.85]:
		for z: float in [-0.3, 0.3]:
			kit.box(Vector3(0.05, 0.25, 0.05), WHITE, at + Vector3(x, 0.125, z))
	kit.box(Vector3(1.95, 0.06, 0.68), WHITE, at + Vector3(0, 0.28, 0))
	kit.box(Vector3(1.3, 0.08, 0.62), cushion, at + Vector3(-0.3, 0.35, 0))
	var tilt := deg_to_rad(40.0)
	kit.box(Vector3(0.7, 0.08, 0.62), cushion, at + Vector3(0.35 + cos(tilt) * 0.35, 0.33 + sin(tilt) * 0.35, 0),
			Basis(Vector3.BACK, tilt))
	if i % 3 != 1:  # a towel on most of them
		kit.box(Vector3(0.9, 0.02, 0.5), TOWELS[i % TOWELS.size()], at + Vector3(-0.4, 0.4, 0))


## A sun umbrella: a weighted base, a pole and a canopy with a frill round the edge.
static func _umbrella(kit: MeshKit, at: Vector3, colour: Color) -> void:
	kit.box(Vector3(0.45, 0.08, 0.45), Color(0.6, 0.6, 0.62), at + Vector3(0, 0.04, 0))
	kit.cylinder(0.03, 0.035, 2.4, WHITE.darkened(0.15), at + Vector3(0, 1.2, 0))
	kit.cylinder(0.03, 1.5, 0.5, colour, at + Vector3(0, 2.45, 0), Basis(), 8)
	kit.cylinder(1.5, 1.5, 0.12, colour.darkened(0.15), at + Vector3(0, 2.15, 0), Basis(), 8)
	kit.ball(0.06, WHITE, at + Vector3(0, 2.73, 0))


## The outdoor shower: a steel post with a head, a tap and a drain square on the deck.
static func _shower(kit: MeshKit, at: Vector3) -> void:
	kit.box(Vector3(0.9, 0.01, 0.9), Color(0.55, 0.57, 0.6), at + Vector3(0, 0.005, 0))
	kit.cylinder(0.05, 0.05, 2.3, STEEL, at + Vector3(0, 1.15, 0))
	kit.cylinder(0.025, 0.025, 0.45, STEEL, at + Vector3(0, 2.25, -0.22), Basis(Vector3.RIGHT, PI * 0.5))
	kit.cylinder(0.14, 0.1, 0.05, STEEL, at + Vector3(0, 2.2, -0.45))
	kit.box(Vector3(0.12, 0.06, 0.1), STEEL, at + Vector3(0, 1.05, -0.07))


## Plants in big pots in the deck's corners (two are little palms). Returns how many.
static func _plants(kit: MeshKit, deck: Rect2) -> int:
	var y := GameConfig.POOL_DECK_Y
	var corners := [Vector2(deck.position.x + 0.7, deck.position.y + 0.7), Vector2(deck.end.x - 0.7, deck.position.y + 0.7),
			Vector2(deck.position.x + 0.7, deck.end.y - 0.6), Vector2(deck.end.x - 0.7, deck.end.y - 0.6)]
	for i in corners.size():
		var at := Vector3(corners[i].x, y, corners[i].y)
		kit.cylinder(0.34, 0.26, 0.55, POT, at + Vector3(0, 0.275, 0), Basis(), 10)
		kit.cylinder(0.3, 0.3, 0.02, Color(0.3, 0.22, 0.15), at + Vector3(0, 0.54, 0), Basis(), 10)
		if i % 2 == 0:
			for k in 3:
				var a := TAU * k / 3.0
				kit.ball(0.32, LEAVES[k % 2], at + Vector3(cos(a) * 0.14, 0.82, sin(a) * 0.14))
			for k in 4:
				var a := TAU * k / 4.0 + 0.4
				kit.ball(0.06, FLOWERS[(i + k) % FLOWERS.size()], at + Vector3(cos(a) * 0.3, 0.98, sin(a) * 0.3))
		else:
			kit.cylinder(0.05, 0.08, 1.4, TRUNK, at + Vector3(0, 1.25, 0), Basis(), 6)
			for k in 6:
				var turn := Basis(Vector3.UP, TAU * k / 6.0) * Basis(Vector3.BACK, -0.45)
				kit.box(Vector3(0.95, 0.03, 0.2), LEAVES[k % 2], at + Vector3(0, 1.95, 0) + turn * Vector3(0.42, 0, 0), turn)
	return corners.size()


## The deck tile picture, made in code: 2 x 2 sandy stone tiles with thin grout lines,
## each tile a slightly different shade. One tile is GameConfig.POOL_TILE_SIZE metres.
static func tile_material() -> StandardMaterial3D:
	if _tiles != null:
		return _tiles
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGB8)
	var base := Color(0.9, 0.86, 0.78)
	var shades := [1.0, 0.95, 0.97, 0.93]
	for y in size:
		for x in size:
			var tile: int = (x * 2 / size) + (y * 2 / size) * 2
			var speck := float((x * 37 + y * 91) % 7) * 0.006
			var colour: Color = base * (shades[tile] - speck)
			if x % (size / 2) == 0 or y % (size / 2) == 0:
				colour = Color(0.68, 0.65, 0.58)
			image.set_pixel(x, y, colour)
	image.generate_mipmaps()
	_tiles = StandardMaterial3D.new()
	_tiles.albedo_texture = ImageTexture.create_from_image(image)
	_tiles.uv1_triplanar = true
	_tiles.uv1_world_triplanar = true
	_tiles.uv1_scale = Vector3.ONE / (GameConfig.POOL_TILE_SIZE * 2.0)
	_tiles.roughness = 0.8
	_tiles.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _tiles
