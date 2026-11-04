class_name VillaBuilder
extends RefCounted
## The house kit (Session 26): builds one Wahat Al Shams home in code, like
## docs/villa_types.svg. Cream two-storey L-shape, flat roof with a parapet (low wall) round
## the roof terrace, tilted solar panels on posts, a wind tower (barjeel) with slots, small
## deep windows, a wooden door with the house number and a low courtyard wall with a gap.
## Three kinds: "courtyard" (the normal home), "garden" (big lawn and a tree) and
## "signature" (bigger, with a wooden mashrabiya screen).
## The extras that make every home different (buggy, bikes, toys, pool...) are in
## scripts/villa_extras.gd. Everything is picked from the home's number, so it's always
## the same. All the visible parts are merged into ONE mesh per home (fast to draw).
##
## Inside a home, x runs across the front and +z points out of the front door. The front
## wall is at z = +half the VILLA_SIZE depth, so the door spot stays where it always was.

const WALLS := [Color(0.95, 0.91, 0.84), Color(0.93, 0.87, 0.75), Color(0.96, 0.93, 0.87)]
const TRIM := Color(0.89, 0.84, 0.74)        # window frames, roof edges
const PLINTH := Color(0.8, 0.74, 0.63)       # the darker strip along the bottom
const TERRACE := Color(0.82, 0.68, 0.55)     # roof terrace tiles
const GLASS := Color(0.36, 0.49, 0.54)
const PANEL := Color(0.18, 0.29, 0.42)       # solar panels
const PANEL_LINE := Color(0.55, 0.62, 0.7)
const POST := Color(0.42, 0.42, 0.4)
const SLOT := Color(0.3, 0.26, 0.2)          # dark slots in the wind tower
const WOOD := Color(0.54, 0.35, 0.17)
const SCREEN_WOOD := Color(0.79, 0.64, 0.42) # the mashrabiya
const PAVING := Color(0.87, 0.82, 0.72)
const LAWN := Color(0.45, 0.66, 0.32)
const PLATE := Color(0.16470589, 0.5568628, 0.6117647, 1)
## Door colours: mostly wood, some painted.
const DOOR_COLOURS := [Color(0.54, 0.35, 0.17), Color(0.4, 0.25, 0.12), Color(0.62, 0.42, 0.22),
		Color(0.16, 0.45, 0.48), Color(0.3, 0.42, 0.25), Color(0.2, 0.3, 0.5), Color(0.7, 0.33, 0.2)]

## The kit everything visible goes into, and the solid body for the walls.
var kit := MeshKit.new()
var body: StaticBody3D
var rng := RandomNumberGenerator.new()
## -1 when this home is built mirror-image (courtyard on the left instead of the right).
var side := 1.0
var kind := "courtyard"
## Joined homes have no detached side yard: all features stay inside their exact plot.
var row_mode := false
var wall := Color.WHITE
## The parts of the home, as rectangles seen from above (x, z, width, depth) and heights.
var main := Rect2()
var annex := Rect2()
var yard := Rect2()
var roof := 0.0
var annex_roof := 0.0
## Short words for what this home got (door colour, buggy...), for the smoke test.
var extras: PackedStringArray = []


## Builds a home for one entry in the data list. size: VILLA_SIZE.
static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var maker := VillaBuilder.new()
	return maker._make(place, size)


func _make(place: Dictionary, size: Vector3) -> StaticBody3D:
	rng.seed = int(place["number"]) * 7919 + 13
	kind = place.get("kind", "courtyard")
	row_mode = place.get("row_mode", false)
	body = StaticBody3D.new()
	body.name = "Villa%d" % place["number"]
	body.position = place["position"]
	body.rotation_degrees = Vector3(0.0, place["facing"], 0.0)
	side = -1.0 if rng.randf() < GameConfig.HOUSE_FLIP_CHANCE else 1.0
	wall = WALLS[rng.randi() % WALLS.size()]
	_plan(size)
	_block(main, roof, true)
	_block(annex, annex_roof, false)
	_front_door(size.z * 0.5, int(place["house"]))
	_windows()
	_solar_canopy()
	_wind_tower(Vector3(annex.end.x - 0.9, annex_roof, annex.position.y + 0.9), roof + 1.2 - annex_roof)
	if kind == "garden":
		_lawn()
	else:
		_courtyard()
	if kind == "signature":
		_mashrabiya(Vector3(main.get_center().x if row_mode else -3.0,
				GameConfig.HOUSE_STOREY + 1.35, main.end.y))
	if row_mode:
		_row_extras()
	else:
		VillaExtras.add_all(self)
	body.add_child(kit.finish("House"))
	body.set_meta("kind", kind)
	body.set_meta("house", int(place["house"]))
	body.set_meta("extras", ",".join(extras))
	body.set_meta("parts", kit.part_count())
	body.set_meta("row_mode", row_mode)
	return body


## A deliberately simpler version of the same silhouette, used for distant joined rows.
## It keeps the L-shape, roof, solar canopy and wind tower, without tiny props/windows.
static func build_far(place: Dictionary, size: Vector3) -> MeshInstance3D:
	var maker := VillaBuilder.new()
	maker.rng.seed = int(place["number"]) * 7919 + 13
	maker.kind = place.get("kind", "courtyard")
	maker.row_mode = place.get("row_mode", false)
	maker.side = -1.0 if maker.rng.randf() < GameConfig.HOUSE_FLIP_CHANCE else 1.0
	maker.wall = WALLS[maker.rng.randi() % WALLS.size()]
	maker._plan(size)
	for part in [[maker.main, maker.roof], [maker.annex, maker.annex_roof]]:
		var area: Rect2 = part[0]
		var height: float = part[1]
		maker.box(Vector3(area.size.x, height, area.size.y), maker.wall,
				Vector3(area.get_center().x, height * 0.5, area.get_center().y))
		maker.box(Vector3(area.size.x, 0.18, area.size.y), TRIM,
				Vector3(area.get_center().x, height + 0.09, area.get_center().y))
	var panel_spot := Vector3(maker.main.get_center().x, maker.roof + 0.9, maker.main.get_center().y)
	maker.box(Vector3(maker.main.size.x - 0.7, 0.12, maker.main.size.y * 0.4), PANEL,
			panel_spot, Basis(Vector3.RIGHT, 0.15))
	maker.box(Vector3(0.9, 1.6, 0.9), maker.wall,
			Vector3(maker.annex.end.x - 0.7, maker.annex_roof + 0.8, maker.annex.position.y + 0.7))
	var view := maker.kit.finish("FarHouse")
	return view


## Works out where the main block, the one-floor annex and the courtyard (or lawn) go.
func _plan(size: Vector3) -> void:
	var half := size * 0.5
	roof = GameConfig.HOUSE_STOREY * 2.0
	annex_roof = GameConfig.HOUSE_ANNEX_HEIGHT
	if row_mode:
		# Frontage exactly matches the row pitch and depth exactly meets the other
		# back-to-back home. Garden/signature identity changes the courtyard and details,
		# not the plot boundary, so neighbouring homes never overlap or leave a gap.
		var main_width := size.x * (0.62 if kind != "signature" else 0.68)
		main = Rect2(-half.x, -half.z, main_width, size.z)
		annex = Rect2(main.end.x, -half.z, size.x - main_width, size.z * 0.5)
		yard = Rect2(main.end.x, 0.0, annex.size.x, half.z)
		if kind == "signature":
			roof += 0.4
			annex_roof += 0.2
		return
	match kind:
		"signature":
			var deep := GameConfig.SIGNATURE_EXTRA_DEPTH
			var right := half.x + GameConfig.SIGNATURE_EXTRA_WIDTH
			roof += 0.4
			annex_roof += 0.2
			main = Rect2(-half.x, -half.z - deep, 8.5, size.z + deep)
			annex = Rect2(main.end.x, main.position.y, right - main.end.x, size.z + deep - 6.5)
			yard = Rect2(main.end.x, annex.end.y, annex.size.x, half.z - annex.end.y)
		"garden":
			main = Rect2(-half.x, -half.z, 7.0, size.z)
			annex = Rect2(main.end.x, -half.z, half.x - main.end.x, 3.5)
			yard = Rect2(main.end.x, annex.end.y, half.x + GameConfig.HOUSE_SIDE_YARD - main.end.x, half.z - annex.end.y)
		_:
			main = Rect2(-half.x, -half.z, 7.0, size.z)
			annex = Rect2(main.end.x, -half.z, half.x - main.end.x, half.z)
			yard = Rect2(main.end.x, 0.0, annex.size.x, half.z)


## A block of the house: walls, a darker plinth, the floor line, the roof terrace and parapet.
func _block(area: Rect2, height: float, terrace: bool) -> void:
	var middle := Vector3(area.get_center().x, height * 0.5, area.get_center().y)
	box(Vector3(area.size.x, height, area.size.y), wall, middle)
	solid(Vector3(area.size.x, height, area.size.y), middle)
	box(Vector3(area.size.x + 0.08, 0.35, area.size.y + 0.08), PLINTH, Vector3(middle.x, 0.175, middle.z))
	if height > GameConfig.HOUSE_STOREY + 1.0:
		box(Vector3(area.size.x + 0.1, 0.12, area.size.y + 0.1), TRIM, Vector3(middle.x, GameConfig.HOUSE_STOREY + 0.1, middle.z))
	if terrace:
		box(Vector3(area.size.x - 0.4, 0.04, area.size.y - 0.4), TERRACE, Vector3(middle.x, height + 0.02, middle.z))
	# The parapet: four low walls round the roof edge, with a trim on top.
	var p := GameConfig.HOUSE_PARAPET
	var t := 0.22
	for along_x in [true, false]:
		for end in [-1.0, 1.0]:
			var length: float = area.size.x if along_x else area.size.y
			var size := Vector3(length, p, t) if along_x else Vector3(t, p, length)
			var spot := middle + (Vector3(0, 0, end * (area.size.y - t) * 0.5) if along_x
					else Vector3(end * (area.size.x - t) * 0.5, 0, 0))
			spot.y = height + p * 0.5
			box(size, wall, spot)
			box(size + Vector3(0.06, 0.06 - p, 0.06), TRIM, spot + Vector3(0, p * 0.5, 0))


## The wooden door in the middle of the front wall, its frame, a step, a little shade over
## it and the house-number plate.
func _front_door(front: float, house: int) -> void:
	var colour: Color = DOOR_COLOURS[rng.randi() % DOOR_COLOURS.size()]
	extras.append("door%d" % DOOR_COLOURS.find(colour))
	var wide := 1.8 if kind == "signature" else 1.2
	box(Vector3(wide, 2.3, 0.1), colour, Vector3(0, 1.15, front + 0.03))
	box(Vector3(0.05, 2.1, 0.12), colour.darkened(0.3), Vector3(0, 1.1, front + 0.04))
	box(Vector3(0.08, 0.08, 0.14), Color(0.85, 0.75, 0.4), Vector3(wide * 0.3, 1.1, front + 0.1))
	for x in [-wide * 0.5 - 0.1, wide * 0.5 + 0.1]:
		box(Vector3(0.2, 2.5, 0.2), TRIM, Vector3(x, 1.25, front + 0.06))
	box(Vector3(wide + 0.8, 0.14, 0.8), TRIM, Vector3(0, 2.6, front + 0.4))
	box(Vector3(wide + 0.6, 0.12, 0.5), PLINTH, Vector3(0, 0.06, front + 0.25))
	# The number plate above the door, facing the lane.
	box(Vector3(1.1, 0.75, 0.06), PLATE, Vector3(0, 3.1, front + 0.03))
	var label := SignText.make_label(str(house), GameConfig.HOUSE_NUMBER_FONT, Color.WHITE, Color(0, 0, 0, 0), 0)
	label.name = "Number"
	label.position = Vector3(0, 3.1, front + 0.07)
	if row_mode:
		label.visibility_range_end = 65.0
	body.add_child(label)


## Small deep windows: glass set back inside a thick frame.
func _windows() -> void:
	var up := GameConfig.HOUSE_STOREY
	var front := main.end.y
	var floors := [1.5, up + 1.4]
	for y in floors:
		if kind != "signature" or y < up:  # upstairs, the signature villa has its mashrabiya here
			window(Vector3(main.position.x + 1.0 if row_mode else -3.5, y, front), Vector3.BACK, 1.0, 1.2)
		window(Vector3(main.position.x, y, main.get_center().y - 1.5), Vector3.LEFT, 0.9, 1.1)
		window(Vector3(main.position.x, y, main.get_center().y + 2.5), Vector3.LEFT, 0.9, 1.1)
		window(Vector3(main.get_center().x, y, main.position.y), Vector3.FORWARD, 1.2, 1.2)
	if kind != "signature":
		window(Vector3(0, floors[1], front), Vector3.BACK, 0.8, 1.0)
	window(Vector3(annex.get_center().x, 1.5, annex.end.y), Vector3.BACK, 1.0, 1.1)


## One window on a wall. spot: middle of the window on the wall. out: which way the wall faces.
func window(spot: Vector3, out: Vector3, w: float, h: float) -> void:
	var turn := Basis(Vector3.UP, atan2(out.x, out.z))
	var parts := [[Vector3(w, h, 0.04), GLASS, Vector3(0, 0, 0.02)],
			[Vector3(w + 0.4, 0.16, 0.28), TRIM, Vector3(0, h * 0.5 + 0.08, 0.14)],
			[Vector3(w + 0.4, 0.12, 0.32), TRIM, Vector3(0, -h * 0.5 - 0.06, 0.16)],
			[Vector3(0.18, h, 0.26), TRIM, Vector3(-w * 0.5 - 0.09, 0, 0.13)],
			[Vector3(0.18, h, 0.26), TRIM, Vector3(w * 0.5 + 0.09, 0, 0.13)]]
	for part in parts:
		box(part[0], part[1], spot + turn * (part[2] as Vector3), turn)


## Tilted solar panels on four posts over half of the roof terrace: the front or the back half.
func _solar_canopy() -> void:
	var on_front := rng.randf() < 0.5
	extras.append("panels_front" if on_front else "panels_back")
	var inset := 0.5
	var z0 := main.get_center().y if on_front else main.position.y + inset
	var z1 := main.end.y - inset if on_front else main.get_center().y
	var x0 := main.position.x + inset
	var x1 := main.end.x - inset
	var low := roof + 0.9
	var high := roof + 1.5
	for x in [x0 + 0.1, x1 - 0.1]:
		box(Vector3(0.1, high - roof, 0.1), POST, Vector3(x, (roof + high) * 0.5, z0 + 0.1))
		box(Vector3(0.1, low - roof, 0.1), POST, Vector3(x, (roof + low) * 0.5, z1 - 0.1))
	var depth := z1 - z0
	var tilt := Basis(Vector3.RIGHT, atan2(high - low, depth))
	var middle := Vector3((x0 + x1) * 0.5, (low + high) * 0.5 + 0.05, (z0 + z1) * 0.5)
	var slope := Vector2(depth, high - low).length()
	box(Vector3(x1 - x0 + 0.2, 0.08, slope), PANEL, middle, tilt)
	var x := x0 + 1.2
	while x < x1 - 0.5:
		box(Vector3(0.04, 0.02, slope), PANEL_LINE, middle + tilt * Vector3(x - middle.x, 0.05, 0), tilt)
		x += 1.2


## The wind tower (barjeel): a tall square tower with slots near the top to catch the breeze.
func _wind_tower(base: Vector3, height: float) -> void:
	var w := 1.1
	box(Vector3(w, height, w), wall, base + Vector3(0, height * 0.5, 0))
	box(Vector3(w + 0.16, 0.14, w + 0.16), TRIM, base + Vector3(0, height + 0.07, 0))
	for out in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
		var turn := Basis(Vector3.UP, atan2(out.x, out.z))
		for across in [-0.22, 0.22]:
			var spot: Vector3 = base + Vector3(0, height - 0.75, 0) + turn * Vector3(across, 0, w * 0.5 + 0.01)
			box(Vector3(0.16, 0.9, 0.04), SLOT, spot, turn)


## The low courtyard wall with a gap to walk in, and paving inside.
func _courtyard() -> void:
	var h := GameConfig.HOUSE_COURTYARD_WALL
	var t := 0.3
	var gap_x := yard.position.x + 0.5
	var gap_w := 1.2
	box(Vector3(yard.size.x, 0.04, yard.size.y), PAVING, Vector3(yard.get_center().x, 0.02, yard.get_center().y))
	var front := yard.end.y - t
	var pieces := [Rect2(gap_x + gap_w, front, yard.end.x - gap_x - gap_w, t),
			Rect2(yard.end.x - t, yard.position.y, t, yard.size.y)]
	if gap_x > yard.position.x + 0.05:
		pieces.append(Rect2(yard.position.x, front, gap_x - yard.position.x, t))
	for piece: Rect2 in pieces:
		var size := Vector3(piece.size.x, h, piece.size.y if piece.size.y > t else t)
		var spot := Vector3(piece.get_center().x, h * 0.5, piece.position.y + size.z * 0.5)
		box(size, wall, spot)
		box(size + Vector3(0.08, 0.08 - h, 0.08), TRIM, spot + Vector3(0, h * 0.5, 0))
		solid(size, spot)


## The garden villa's big lawn and a shade tree, with a low hedge along the front.
func _lawn() -> void:
	box(Vector3(yard.size.x, 0.04, yard.size.y), LAWN, Vector3(yard.get_center().x, 0.02, yard.get_center().y))
	var hedge := Vector3(yard.size.x - 1.4, 0.8, 0.5)
	var hedge_spot := Vector3(yard.end.x - hedge.x * 0.5, 0.4, yard.end.y - 0.3)
	box(hedge, LAWN.darkened(0.25), hedge_spot)
	solid(hedge, hedge_spot)
	var tree := Vector3(yard.get_center().x if row_mode else yard.end.x - 1.8, 0, yard.position.y + 1.4)
	box(Vector3(0.35, 2.6, 0.35), WOOD, tree + Vector3(0, 1.3, 0))
	solid(Vector3(0.5, 2.6, 0.5), tree + Vector3(0, 1.3, 0))
	var crown := minf(1.6, yard.size.x * 0.4) if row_mode else 1.6
	kit_ball(crown, LAWN.darkened(0.15), tree + Vector3(0, 3.4, 0), 0.8)
	kit_ball(crown * 0.7, LAWN.darkened(0.05), tree + Vector3(0.3 if row_mode else 0.6, 4.1, 0.4), 0.8)


## Roof and courtyard details for terraced homes. Detached-house side props would
## protrude into a neighbour, so these use safe spots within the home's own footprint.
func _row_extras() -> void:
	var ac_count := 1 + rng.randi() % 2
	extras.append("ac_roof%d" % ac_count)
	for i in ac_count:
		box(Vector3(0.7, 0.55, 0.65), Color(0.75, 0.76, 0.78),
				Vector3(main.position.x + 0.7 + i * 0.85, roof + 0.28, main.position.y + 0.7))
	var pots := 1 + int(rng.randi() % 2)
	extras.append("pots%d" % pots)
	for i in pots:
		var x := -1.4 if i == 0 else 1.4
		kit_cylinder(0.2, 0.15, 0.4, Color(0.72, 0.42, 0.28), Vector3(x, 0.2, main.end.y + 0.25))
		kit_ball(0.3, LAWN.darkened(0.1), Vector3(x, 0.65, main.end.y + 0.25))
	if kind != "garden":
		var tree := Vector3(yard.get_center().x, 0, yard.position.y + 0.85)
		box(Vector3(0.15, 1.6, 0.15), WOOD, tree + Vector3(0, 0.8, 0))
		kit_ball(minf(0.75, yard.size.x * 0.3), LAWN, tree + Vector3(0, 1.9, 0), 0.8)
		extras.append("olive")
	if rng.randf() < GameConfig.HOUSE_TOYS_CHANCE:
		kit_ball(0.16, Color(0.9, 0.3, 0.3), Vector3(yard.get_center().x, 0.16, yard.end.y - 0.7))
		extras.append("toyball")
	if kind == "signature":
		var spot := Vector3(yard.get_center().x, 0, yard.position.y + 2.1)
		var width := minf(2.2, yard.size.x - 0.5)
		box(Vector3(width, 0.12, 1.4), Color(0.96, 0.96, 0.94), spot + Vector3(0, 0.06, 0))
		box(Vector3(width - 0.2, 0.03, 1.2), Color(0.35, 0.72, 0.88), spot + Vector3(0, 0.13, 0))
		extras.append("pool")


## The wooden mashrabiya screen: a lattice of thin slats in a frame, on the upstairs front.
func _mashrabiya(spot: Vector3) -> void:
	var w := 3.0
	var h := 1.9
	box(Vector3(w, h, 0.06), SLOT, spot + Vector3(0, 0, 0.03))
	box(Vector3(w + 0.3, 0.16, 0.5), SCREEN_WOOD.darkened(0.2), spot + Vector3(0, h * 0.5 + 0.12, 0.25))
	box(Vector3(w + 0.2, 0.12, 0.4), SCREEN_WOOD.darkened(0.2), spot + Vector3(0, -h * 0.5 - 0.06, 0.2))
	var x := -w * 0.5
	while x <= w * 0.5 + 0.01:
		box(Vector3(0.07, h, 0.1), SCREEN_WOOD, spot + Vector3(x, 0, 0.14))
		x += 0.3
	var y := -h * 0.5 + 0.2
	while y < h * 0.5:
		box(Vector3(w, 0.07, 0.1), SCREEN_WOOD, spot + Vector3(0, y, 0.14))
		y += 0.3


# --- Small helpers. They mirror everything when the home is built mirror-image. ---

## A visible box (part of the merged house mesh).
func box(size: Vector3, colour: Color, spot: Vector3, turn := Basis()) -> void:
	kit.box(size, colour, _mirror(spot), _mirror_turn(turn))


## A visible cylinder (part of the merged house mesh).
func kit_cylinder(top: float, bottom: float, height: float, colour: Color, spot: Vector3,
		turn := Basis(), segments := 8) -> void:
	kit.cylinder(top, bottom, height, colour, _mirror(spot), _mirror_turn(turn), segments)


## A visible ball (part of the merged house mesh).
func kit_ball(radius: float, colour: Color, spot: Vector3, squash := 1.0) -> void:
	kit.ball(radius, colour, _mirror(spot), squash)


## An invisible solid box the bike bumps into.
func solid(size: Vector3, spot: Vector3) -> void:
	LowPoly.solid_box(body, size, _mirror(spot))


func _mirror(spot: Vector3) -> Vector3:
	return Vector3(spot.x * side, spot.y, spot.z)


func _mirror_turn(turn: Basis) -> Basis:
	if side > 0.0:
		return turn
	var flip := Basis.from_scale(Vector3(-1, 1, 1))
	return flip * turn * flip
