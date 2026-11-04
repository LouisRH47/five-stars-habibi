class_name PlazaRows
extends RefCounted
## Session 57: the Plaza's two shop rows above the ground floor (PRD "Looks pass", The Plaza).
## The shops themselves (rooms, glass fronts, signs) come from PlaceBuilder; this builds
## what's round them, from PLAZA_ROWS in data/wahat_al_shams.gd:
## - a 4 m storeroom behind every shop (you can't go in),
## - three floors of flats on top, joined into ONE mesh per row, running over the
##   passages too: sand walls, windows with white sills, small balconies on the middle
##   floor, lighter bands between the floors, a parapet with AC boxes and solar panels,
## - a lamp under the flats in every passage (on after sunset),
## - Wahat Pharmacy, a shop you can't enter (scenery only).
## Heights are in game_config.gd (Session 57).

const WALL := Color(0.9, 0.81, 0.64)       # sand-coloured flats
const BAND := Color(0.97, 0.94, 0.87)      # lighter bands, sills and the cornice
const STORE := Color(0.95, 0.9, 0.8)       # storerooms: the same cream as the shops
const GLASS := Color(0.25, 0.37, 0.45)
const FRAME := Color(0.98, 0.97, 0.95)
const ROOF := Color(0.78, 0.75, 0.69)
const AC := Color(0.8, 0.82, 0.82)
const FAN := Color(0.3, 0.32, 0.34)
const SOLAR := Color(0.13, 0.22, 0.4)
const SERVICE := Color(0.45, 0.5, 0.52)
const ROOM_DEPTH := 10.0                   # the public room; the rest of the row is storeroom


static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "PlazaRows"
	parent.add_child(holder)
	for row: Dictionary in map.get("PLAZA_ROWS", []):
		holder.add_child(_row(row))
	var landscape: Dictionary = map.get("PLAZA_LANDSCAPE", {})
	for spot: Vector3 in landscape.get("passage_lights", []):
		_passage_lamp(holder, spot)
	var glow := NightGlow.new()
	glow.name = "NightGlow"
	holder.add_child(glow)
	return holder


## The ground floor's height, the roof's height and the top of the parapet.
static func heights() -> Vector3:
	var roof := GameConfig.PLAZA_GROUND_FLOOR + GameConfig.PLAZA_FLAT_FLOORS * GameConfig.PLAZA_FLOOR_HEIGHT
	return Vector3(GameConfig.PLAZA_GROUND_FLOOR, roof, roof + GameConfig.PLAZA_PARAPET)


## +1 for a row whose fronts face +z (the north row), -1 for the south row.
static func front_sign(row: Dictionary) -> float:
	return 1.0 if is_zero_approx(float(row["facing"])) else -1.0


static func _row(row: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = String(row["name"]).replace(" ", "")
	body.set_meta("plaza_row", true)
	var s := front_sign(row)
	var f: float = row["front_z"]
	var depth: float = row["depth"]
	var back := f - s * depth
	var x0: float = row["from_x"]
	var x1: float = row["to_x"]
	var kit := MeshKit.new()
	var h := heights()
	# Storerooms behind each shop (a little wider, so the passage walls are flush).
	for unit: Dictionary in row["units"]:
		if unit["kind"] == "passage":
			continue
		var a: float = unit["from_x"] - 0.125
		var b: float = unit["to_x"] + 0.125
		var z := (f - s * ROOM_DEPTH + back) * 0.5
		var size := Vector3(b - a, h.x, depth - ROOM_DEPTH)
		kit.box(size, STORE, Vector3((a + b) * 0.5, h.x * 0.5, z))
		LowPoly.solid_box(body, size, Vector3((a + b) * 0.5, h.x * 0.5, z))
		# The back: a grey service door and a high storeroom window, so it isn't a blank wall.
		var door_x := (a + b) * 0.5 + (b - a) * 0.25
		kit.box(Vector3(1.1, 2.2, 0.08), SERVICE, Vector3(door_x, 1.1, back - s * 0.03))
		kit.box(Vector3(1.3, 2.35, 0.05), FRAME, Vector3(door_x, 1.15, back - s * 0.01))
		kit.box(Vector3(2.6, 0.55, 0.06), GLASS, Vector3((a + b) * 0.5 - (b - a) * 0.2, 3.3, back - s * 0.03))
		if unit["kind"] == "scenery":
			body.add_child(_scenery_shop(unit, row))
	_flats(kit, x0, x1, f, back, s, h)
	var view := kit.finish("Flats")
	body.add_child(view)
	return body


## Three floors of flats over the whole row, as one mesh.
static func _flats(kit: MeshKit, x0: float, x1: float, f: float, back: float, s: float, h: Vector3) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var cz := (f + back) * 0.5
	var depth := absf(f - back)
	var tall := h.y - h.x
	kit.box(Vector3(length, tall, depth), WALL, Vector3(cx, h.x + tall * 0.5, cz))
	# The cornice over the shops and a lighter band at every floor.
	kit.box(Vector3(length + 0.5, 0.26, depth + 0.7), BAND, Vector3(cx, h.x + 0.13, cz))
	for k in range(1, GameConfig.PLAZA_FLAT_FLOORS):
		kit.box(Vector3(length + 0.12, 0.18, depth + 0.12), BAND, Vector3(cx, h.x + k * GameConfig.PLAZA_FLOOR_HEIGHT, cz))
	# The parapet round the roof, with a white coping on top.
	for edge in [[Vector3(length, GameConfig.PLAZA_PARAPET, 0.25), Vector3(cx, 0, f - s * 0.125)],
			[Vector3(length, GameConfig.PLAZA_PARAPET, 0.25), Vector3(cx, 0, back + s * 0.125)],
			[Vector3(0.25, GameConfig.PLAZA_PARAPET, depth - 0.5), Vector3(x0 + 0.125, 0, cz)],
			[Vector3(0.25, GameConfig.PLAZA_PARAPET, depth - 0.5), Vector3(x1 - 0.125, 0, cz)]]:
		var size: Vector3 = edge[0]
		var at: Vector3 = edge[1]
		kit.box(size, WALL, at + Vector3(0, h.y + GameConfig.PLAZA_PARAPET * 0.5, 0))
		var coping := Vector3(size.x + 0.1, 0.07, 0.35) if size.x > 1.0 else Vector3(0.35, 0.07, size.z + 0.1)
		kit.box(coping, BAND, at + Vector3(0, h.z + 0.035, 0))
	kit.box(Vector3(length - 0.5, 0.02, depth - 0.5), ROOF, Vector3(cx, h.y + 0.01, cz))
	# Windows (with white frames and sills) front and back, balconies on the middle floor.
	var spacing := GameConfig.PLAZA_WINDOW_SPACING
	var count := int(length / spacing)
	var start := cx - (count - 1) * spacing * 0.5
	for face in [[f, s], [back, -s]]:
		var z: float = face[0]
		var out: float = face[1]
		for k in GameConfig.PLAZA_FLAT_FLOORS:
			var base := h.x + k * GameConfig.PLAZA_FLOOR_HEIGHT
			for i in count:
				var x := start + i * spacing
				var balcony: bool = k == 1 and i % 2 == 0
				_window(kit, Vector3(x, base, z), Vector3(0, 0, out), balcony)
	for end in [[x0, -1.0], [x1, 1.0]]:
		for k in GameConfig.PLAZA_FLAT_FLOORS:
			var base := h.x + k * GameConfig.PLAZA_FLOOR_HEIGHT
			for side in [-1.0, 1.0]:
				_window(kit, Vector3(end[0], base, cz + side * depth * 0.25), Vector3(end[1], 0, 0), false)
	# On the roof: AC boxes near the back, solar panels tilted to the sun near the front.
	for i in int(length / 6.0):
		var x := x0 + 3.0 + i * 6.0
		var at := Vector3(x, h.y + 0.37, back + s * 2.0)
		kit.box(Vector3(1.0, 0.7, 0.8), AC, at)
		kit.cylinder(0.28, 0.28, 0.03, FAN, at + Vector3(0, 0.36, 0), Basis(), 8)
	var tilt := Basis(Vector3.RIGHT, -s * deg_to_rad(18.0))
	for line in [3.2, 5.4]:
		for i in int((length - 2.0) / 2.0):
			var x := x0 + 2.0 + i * 2.0
			kit.box(Vector3(1.8, 0.05, 1.0), SOLAR, Vector3(x, h.y + 0.5, f - s * line), tilt)
			kit.box(Vector3(0.06, 0.45, 0.06), FAN, Vector3(x, h.y + 0.24, f - s * line))


## One flats window (1.4 x 1.6 m) with a white frame and sill. at: x/z on the wall face and
## the floor's height. out: which way the wall faces. balcony: add a small balcony.
static func _window(kit: MeshKit, at: Vector3, out: Vector3, balcony: bool) -> void:
	var size: Vector2 = GameConfig.PLAZA_WINDOW
	var across := Vector3(absf(out.z), 0, absf(out.x))   # along the wall
	var turn := Basis() if absf(out.z) > 0.5 else Basis(Vector3.UP, PI * 0.5)
	var tall := size.y + (0.6 if balcony else 0.0)       # a balcony window is a door
	var bottom := at.y + (0.15 if balcony else 0.9)
	var middle := Vector3(at.x, bottom + tall * 0.5, at.z)
	kit.box(Vector3(size.x + 0.16, tall + 0.16, 0.06), FRAME, middle + out * 0.01, turn)
	kit.box(Vector3(size.x, tall, 0.08), GLASS, middle + out * 0.03, turn)
	if not balcony:
		kit.box(Vector3(size.x + 0.3, 0.08, 0.22), BAND, Vector3(at.x, bottom - 0.04, at.z) + out * 0.11, turn)
		return
	kit.box(Vector3(2.2, 0.14, 1.1), BAND, Vector3(at.x, at.y + 0.07, at.z) + out * 0.55, turn)
	kit.box(Vector3(2.2, 0.55, 0.06), BAND, Vector3(at.x, at.y + 0.42, at.z) + out * 1.07, turn)
	kit.box(Vector3(2.2, 0.05, 0.06), FRAME, Vector3(at.x, at.y + 1.05, at.z) + out * 1.07, turn)
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.05, 0.36, 0.05), FRAME, Vector3(at.x, at.y + 0.86, at.z) + across * side * 1.05 + out * 1.07, turn)
		kit.box(Vector3(0.06, 0.05, 1.1), FRAME, Vector3(at.x, at.y + 1.05, at.z) + across * side * 1.07 + out * 0.55, turn)


## A lamp under the flats in a passage: a lit panel, plus a real light after sunset.
static func _passage_lamp(holder: Node3D, spot: Vector3) -> void:
	var panel := LowPoly.box(holder, Vector3(0.5, 0.05, 1.4), Color(1, 0.95, 0.82), spot)
	panel.name = "PassageLamp"
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(1, 0.96, 0.85)
	lit.emission_enabled = true
	lit.emission = Color(1, 0.88, 0.62)
	lit.emission_energy_multiplier = 0.0
	panel.material_override = lit
	panel.set_meta("static_batch_dynamic", true)
	panel.add_to_group("plaza_glow")
	var light := OmniLight3D.new()
	light.name = "PassageLight"
	light.position = spot + Vector3(0, -0.4, 0)
	light.light_color = Color(1, 0.86, 0.6)
	light.light_energy = 1.4
	light.omni_range = 7.0
	light.visible = false
	light.add_to_group("plaza_night_light")
	holder.add_child(light)


## Wahat Pharmacy: a shop front with frosted glass and a locked door, shelves inside.
static func _scenery_shop(unit: Dictionary, row: Dictionary) -> StaticBody3D:
	var s := front_sign(row)
	var width: float = unit["to_x"] - unit["from_x"]
	var size := Vector3(width, GameConfig.PLAZA_GROUND_FLOOR, ROOM_DEPTH)
	var shop := StaticBody3D.new()
	shop.name = "Pharmacy"
	shop.set_meta("scenery_shop", unit["id"])
	shop.position = Vector3((unit["from_x"] + unit["to_x"]) * 0.5, 0, float(row["front_z"]) - s * ROOM_DEPTH * 0.5)
	shop.rotation_degrees.y = row["facing"]
	for side in [-1.0, 1.0]:
		LowPoly.box(shop, Vector3(0.25, size.y, size.z), STORE, Vector3(side * width * 0.5, size.y * 0.5, 0))
		LowPoly.solid_box(shop, Vector3(0.25, size.y, size.z), Vector3(side * width * 0.5, size.y * 0.5, 0))
	LowPoly.box(shop, Vector3(width, size.y, 0.25), STORE, Vector3(0, size.y * 0.5, -size.z * 0.5))
	LowPoly.box(shop, Vector3(width, 0.06, size.z), Color(0.92, 0.93, 0.92), Vector3(0, 0.03, 0))
	for i in 3:
		LowPoly.box(shop, Vector3(width - 2.0, 0.05, 0.5), Color(0.96, 0.96, 0.96), Vector3(0, 0.6 + i * 0.6, -size.z * 0.5 + 0.5))
	var place := {"id": unit["id"], "name": unit["name"], "arabic": unit["arabic"], "colour": unit["colour"]}
	ShopFront.build(shop, place, size, false)
	return shop
