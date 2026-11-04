class_name InteriorParts
extends RefCounted
## Session 58: the toolbox for building one walk-in room (PRD "Looks pass", Interiors).
## One InteriorParts is made per room. Every plain coloured shape goes into one MeshKit
## (one mesh, one draw call for the whole room); glass, glowing and moving parts are their
## own nodes. People, lamps and moving parts go under "Inside", which VenueMotion hides
## when the camera is far away (Appendix I: only nearby rooms are busy).
## Room directions: x from -6 (left, seen from the door) to +6, z from +5 (the glass front)
## to -5 (the back wall), y up from the floor (0) to the ceiling (4.5).

var body: StaticBody3D
var kit := MeshKit.new()
var inside: Node3D
var motion: VenueMotion
var place: Dictionary
var id := ""
var brand := Color.WHITE
var size := Vector3(12, 4.5, 10)
var seats := 0
## Counter tops [Rect2 (x, z, w, d), top height], so the test can check things sit on one.
var counter_tops: Array = []
## Machines built from shapes [name, where its bottom is], so the test can check none float.
var machines: Array = []
var _many := {}    # model -> [spots, facings]: food and cups drawn together at the end
var _number := 0   # a steady "random" number per room, so the same seats always have diners


func _init(room: StaticBody3D, data: Dictionary, room_size: Vector3) -> void:
	body = room
	place = data
	id = data.get("id", "")
	brand = data.get("colour", Color(0.5, 0.5, 0.5))
	size = room_size
	_number = absi(id.hash())
	inside = Node3D.new()
	inside.name = "Inside"
	body.add_child(inside)
	motion = VenueMotion.new()
	motion.name = "VenueMotion"
	motion.inside = inside
	body.add_child(motion)


## Turns everything put in the MeshKit into the room's mesh. Call once, at the end.
func finish() -> void:
	for model in _many:
		props(model, _many[model][0], _many[model][1], "counter")
	var view := kit.finish("InteriorParts")
	body.add_child(view)
	body.set_meta("counter_tops", counter_tops)
	body.set_meta("machines", machines)
	body.set_meta("seats", seats)


## A plain box (no collision). turn: an optional rotation about its own middle.
func box(box_size: Vector3, colour: Color, at: Vector3, turn := Basis()) -> void:
	kit.box(box_size, colour, at, turn)


## A box you can't walk through.
func solid(box_size: Vector3, colour: Color, at: Vector3) -> void:
	kit.box(box_size, colour, at)
	LowPoly.solid_box(body, box_size, at)


func cyl(top: float, bottom: float, height: float, colour: Color, at: Vector3, turn := Basis(), sides := 10) -> void:
	kit.cylinder(top, bottom, height, colour, at, turn, sides)


## A counter: rect is its footprint (x, z, width, depth) on the floor. The top is a
## slightly bigger slab in top_colour; the counter is solid and its top is remembered.
func counter(rect: Rect2, colour: Color, top_colour: Color, height := GameConfig.INTERIOR_COUNTER_HEIGHT) -> void:
	var mid := Vector3(rect.get_center().x, 0, rect.get_center().y)
	solid(Vector3(rect.size.x, height - 0.05, rect.size.y), colour, mid + Vector3(0, (height - 0.05) * 0.5, 0))
	box(Vector3(rect.size.x + 0.04, 0.05, rect.size.y + 0.04), top_colour, mid + Vector3(0, height - 0.025, 0))
	box(Vector3(rect.size.x - 0.04, 0.1, rect.size.y - 0.1), Color(0.12, 0.12, 0.13), mid + Vector3(0, 0.05, 0))  # dark kick plate
	counter_tops.append([rect.grow(0.02), height])


## A model from the free packs (KitProps). fit: the size you want in metres (w, h, d);
## leave it zero to keep the model's own real size. The bottom still sits on its snap.
func prop(model: String, at: Vector3, facing := 0.0, snap := "", fit := Vector3.ZERO, parent: Node = null) -> Node3D:
	var holder := KitProps.place(parent if parent != null else body, model, at, facing, 1.0, snap)
	if holder == null or fit == Vector3.ZERO:
		return holder
	var real := KitProps.size_of(model)
	var stretch := Vector3(fit.x / maxf(real.x, 0.001), fit.y / maxf(real.y, 0.001), fit.z / maxf(real.z, 0.001))
	var inner := holder.get_node("Model") as Node3D
	inner.scale *= stretch
	inner.position *= stretch
	return holder


## Many copies of one model, drawn together (chairs, stools, food on tables).
func props(model: String, spots: Array, facings: Array = [], snap := "") -> void:
	if not spots.is_empty():
		KitProps.place_many(body, model, spots, facings, 1.0, snap)


## A seat. Somebody eats at about half of them (always the same seats in the same room).
## at: the seat's spot on the floor; facing: degrees the sitter looks (0 = towards +z);
## seat_y: how high the seat is.
func seat(at: Vector3, facing: float, seat_y := 0.46, food := "") -> bool:
	seats += 1
	var marker := Marker3D.new()
	marker.name = "Seat%d" % seats
	marker.position = at
	marker.rotation.y = deg_to_rad(facing)
	marker.add_to_group("interior_seat")
	inside.add_child(marker)
	if (_number / 3 + seats * 37) % 100 >= int(GameConfig.INTERIOR_DINER_SHARE * 100.0):
		return false
	var diner := PeopleLooks.resident((_number + seats) % PeopleLooks.RESIDENT_OUTFITS, (seats + _number / 5) % 4)
	diner.name = "Diner%d" % seats
	var hips := diner.spot("Hips").y
	# Our people face -Z, so turn them half round more than the facing (0 = looks along +z).
	var turn := deg_to_rad(facing) + PI
	diner.position = at + Vector3(0, seat_y + 0.06 - hips, 0) + Vector3(0, 0, 0.08).rotated(Vector3.UP, turn)
	diner.rotation.y = turn
	diner.add_to_group("interior_diner")
	inside.add_child(diner)
	diner.play("sit")
	for part: GeometryInstance3D in diner.find_children("*", "GeometryInstance3D", true, false):
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # cheaper, and lamps are soft anyway
	if food != "":
		motion.add_eater(diner)
	return true


## A food model on a table or counter top that is `top` metres high (drawn with the others).
func food_on(model: String, at: Vector3, top: float, facing := 0.0) -> void:
	if not _many.has(model):
		_many[model] = [[], []]
	_many[model][0].append(Vector3(at.x, top - GameConfig.KIT_COUNTER_HEIGHT, at.z))
	_many[model][1].append(facing)


## A person working here. who: "cook", "cashier", "staff"... at: where they stand; facing:
## degrees they look. The one at the pickup spot is called CounterStaff (the counter panel
## gives them the bag to hand over).
func worker(node_name: String, at: Vector3, facing: float, outfit := 2, direct := false) -> Person:
	var person := PeopleLooks.resident(2 + outfit % 3, (_number + outfit) % 4)   # t-shirt outfits under the cap
	person.paint({"shirt": brand.darkened(0.1), "pants": Color(0.16, 0.16, 0.18)})
	PeopleLooks.cap(person, brand.lightened(0.3), person)
	person.name = node_name
	person.position = at
	person.rotation.y = deg_to_rad(facing) + PI
	person.add_to_group("interior_staff")
	(body if direct else inside).add_child(person)
	return person


## A warm hanging lamp: a cord, a shade and a light. shadows: only one lamp per room casts
## soft shadows (and only on Medium and High).
func lamp(at: Vector3, shade: Color, shadows := false, cool := false) -> void:
	var drop := 0.9
	box(Vector3(0.02, drop, 0.02), Color(0.1, 0.1, 0.1), Vector3(at.x, size.y - drop * 0.5, at.z))
	cyl(0.08, 0.26, 0.22, shade, Vector3(at.x, size.y - drop - 0.1, at.z), Basis(), 10)
	var bulb := OmniLight3D.new()
	bulb.name = "Lamp"
	bulb.position = Vector3(at.x, size.y - drop - 0.3, at.z)
	bulb.light_color = Color(0.9, 0.95, 1.0) if cool else Color(1.0, 0.82, 0.6)
	bulb.light_energy = GameConfig.INTERIOR_LAMP_ENERGY
	bulb.omni_range = GameConfig.INTERIOR_LAMP_RANGE
	bulb.shadow_enabled = false
	bulb.set_meta("soft_shadow", shadows)
	bulb.add_to_group("interior_lamp")
	inside.add_child(bulb)
	motion.lamps.append(bulb)


## The menu board: a dark board on the back wall with the logo, the items and their prices
## in Dh (Appendix B). centre: the middle of its face; items: [["Margherita", 32], ...].
func menu_board(centre: Vector3, width: float, items: Array, height := 1.2, board := Color(0.1, 0.1, 0.11), ink := Color.WHITE) -> Node3D:
	box(Vector3(width + 0.1, height + 0.1, 0.05), brand.darkened(0.2), centre + Vector3(0, 0, -0.04))
	box(Vector3(width, height, 0.04), board, centre)
	var holder := Node3D.new()
	holder.name = "MenuBoard"
	holder.position = centre + Vector3(0, 0, 0.03)
	holder.add_to_group("menu_board")
	holder.set_meta("items", items)
	holder.set_meta("width", width)
	body.add_child(holder)
	var badge := _logo(holder, minf(height - 0.2, 0.9))
	badge.position = Vector3(-width * 0.5 + 0.12 + (height - 0.2) * 0.5, 0, 0)
	var columns := 2 if items.size() > 3 else 1
	var rows := ceili(items.size() / float(columns))
	var left := -width * 0.5 + height + 0.05
	var column_w := (width * 0.5 - 0.1 - left) / columns
	var spacing := 0.3
	var font_size := 19
	if GameConfig.MENU_TEXT_FIT:
		# Review fix: pick 2 columns or 1, whichever gives the bigger text that fits (on
		# narrow boards long names ran into their prices: "Zaatar manakish8 Dh").
		var best := -1
		for cols: int in ([2, 1] if items.size() > 3 else [1]):
			var r := ceili(items.size() / float(cols))
			var gap := minf(0.3, (height - 0.15) / r)
			var w := (width * 0.5 - 0.1 - left) / cols
			var size := menu_font_size(items, w, gap)
			if size > best:
				best = size
				columns = cols
				rows = r
				spacing = gap
				column_w = w
		font_size = best
	holder.set_meta("font_size", font_size)
	holder.set_meta("columns", columns)
	for i in items.size():
		var item: Array = items[i]
		var col := i / rows
		var row := i % rows
		var y := (rows - 1) * 0.5 * spacing - row * spacing
		var name_label := SignText.make_label(str(item[0]), font_size, ink, Color(0, 0, 0, 0), 0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.position = Vector3(left + col * column_w, y, 0)
		holder.add_child(name_label)
		var price_text := _price_text(item[1])
		var price := SignText.make_label(price_text, font_size, Color(1.0, 0.82, 0.35) if board.v < 0.5 else ink.lerp(Color(0.8, 0.1, 0.1), 0.6), Color(0, 0, 0, 0), 0)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price.position = Vector3(left + (col + 1) * column_w - 0.15, y, 0)
		holder.add_child(price)
	return holder


static func _price_text(price) -> String:
	return str(price) if price is String else "%s Dh" % str(price)


## Review fix: the biggest font (up to MENU_TEXT_MAX) at which every line's name and price
## fit side by side in one column (with a gap) and the rows (row_gap apart) don't touch. Before, every board used 19,
## which you couldn't read from the door (letters about 6 cm tall on a 4 m board).
static func menu_font_size(items: Array, column_w: float, row_gap := 0.3) -> int:
	var size := GameConfig.MENU_TEXT_MAX
	while size > 19:
		var fits := size * SignText.PIXEL_SIZE * 1.25 <= row_gap   # one line's height fits its row
		for item: Array in items:
			var wide := SignText.text_width(str(item[0]), size) + SignText.text_width(_price_text(item[1]), size) + 0.15
			if wide > column_w - 0.15:
				fits = false
		if fits:
			return size
		size -= 1
	return 19


## The shop's round logo (assets/logos/<id>_badge.svg) on a little square, or nothing.
func _logo(parent: Node3D, across: float) -> Node3D:
	var badge := MeshInstance3D.new()
	badge.name = "Logo"
	var path := "res://assets/logos/%s_badge.svg" % id
	if not ResourceLoader.exists(path):
		parent.add_child(badge)
		return badge
	var quad := QuadMesh.new()
	quad.size = Vector2(across, across)
	badge.mesh = quad
	var picture := StandardMaterial3D.new()
	picture.albedo_texture = load(path)
	picture.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	picture.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	badge.material_override = picture
	badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(badge)
	return badge


## Review fix: a thin cord from `bottom` straight up to the ceiling (for hanging signs).
func cord(bottom: Vector3, colour := Color(0.3, 0.3, 0.3)) -> void:
	var length := size.y - bottom.y + 0.01
	box(Vector3(0.015, length, 0.015), colour, Vector3(bottom.x, bottom.y + length * 0.5 - 0.01, bottom.z))


## Where the top of a sign's backing board is, for a sign made by sign() at height y.
static func sign_top(y: float, font_size: int) -> float:
	return y + (font_size * 0.012 + 0.08) * 0.5


## A small bilingual sign (pickup, till, aisle signs). It reads from +z unless turned.
func sign(arabic: String, english: String, at: Vector3, facing := 0.0, colour := Color.WHITE, back := Color(0, 0, 0, 0), font_size := 26) -> Node3D:
	if back.a > 0.0:
		var w := maxf(SignText.text_width(english, font_size), SignText.text_width(arabic, roundi(font_size * 1.15))) + 0.2
		box(Vector3(w, font_size * 0.012 + 0.08, 0.03), back, at + Vector3(0, 0, -0.025).rotated(Vector3.UP, deg_to_rad(facing)), Basis(Vector3.UP, deg_to_rad(facing)))
	var face := SignText.make_face(arabic, english, font_size, colour)
	face.name = "Sign"
	face.position = at
	face.rotation.y = deg_to_rad(facing)
	body.add_child(face)
	return face


## A glowing panel (fire glow, lit menu, fridge light). Not merged, so it can shine.
func glow(glow_size: Vector3, colour: Color, at: Vector3, energy := 1.5, parent: Node3D = null) -> MeshInstance3D:
	var view := LowPoly.box(parent if parent != null else body, glow_size, colour, at)
	var lit := StandardMaterial3D.new()
	lit.albedo_color = colour
	lit.emission_enabled = true
	lit.emission = colour
	lit.emission_energy_multiplier = energy
	view.material_override = lit
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return view


## A see-through glass part (display cases, fridge doors).
func glass(glass_size: Vector3, at: Vector3, turn := Basis()) -> MeshInstance3D:
	var view := LowPoly.box(body, glass_size, Color.WHITE, at)
	view.basis = turn
	view.material_override = ShopFront.glass_material(true)
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.add_to_group("interior_glass")
	return view


## A tall glass-door drinks fridge (0.7 x 2.0 x 0.7, Appendix H) full of coloured bottles.
## facing: degrees its door looks (0 = towards +z).
func drinks_fridge(at: Vector3, facing := 0.0, frame := Color(0.85, 0.86, 0.88)) -> void:
	var turn := Basis(Vector3.UP, deg_to_rad(facing))
	var f := func(local: Vector3) -> Vector3: return at + turn * local
	solid(Vector3(0.7, 2.0, 0.7), frame, at + Vector3(0, 1.0, 0))
	box(Vector3(0.6, 0.25, 0.02), brand, f.call(Vector3(0, 1.85, 0.36)), turn)
	for shelf in 4:
		var y := 0.35 + shelf * 0.38
		box(Vector3(0.58, 0.02, 0.02), Color(0.7, 0.7, 0.72), f.call(Vector3(0, y, 0.34)), turn)
		for k in 5:
			var colour: Color = [Color(0.9, 0.2, 0.2), Color(0.95, 0.6, 0.1), Color(0.2, 0.6, 0.3), Color(0.25, 0.45, 0.85), Color(0.95, 0.85, 0.3)][(k + shelf) % 5]
			cyl(0.03, 0.035, 0.24, colour, f.call(Vector3(-0.22 + k * 0.11, y + 0.13, 0.3)), turn, 6)
	glow(Vector3(0.56, 1.5, 0.01), Color(0.85, 0.95, 1.0), f.call(Vector3(0, 0.95, 0.355)), 0.25).basis = turn
	glass(Vector3(0.62, 1.6, 0.02), f.call(Vector3(0, 0.95, 0.37)), turn)


## A potted plant in a corner (kit model), and a bin by the door.
func plant(at: Vector3, big := true) -> void:
	prop("kenney_furniture/pottedPlant" if big else "kenney_furniture/plantSmall1", at, 0.0, "floor")


func bin(at: Vector3) -> void:
	prop("kenney_furniture/trashcan", at, 0.0, "floor")


## A till on a counter top (screen and a card reader). facing: towards the staff.
func till(at: Vector3, facing := 180.0) -> void:
	var turn := Basis(Vector3.UP, deg_to_rad(facing))
	box(Vector3(0.36, 0.1, 0.3), Color(0.18, 0.18, 0.2), at + Vector3(0, 0.05, 0))
	box(Vector3(0.05, 0.22, 0.05), Color(0.2, 0.2, 0.22), at + Vector3(0, 0.2, 0))
	box(Vector3(0.34, 0.22, 0.03), Color(0.1, 0.1, 0.12), at + turn * Vector3(0, 0.33, 0.02), turn * Basis(Vector3.RIGHT, -0.3))
	glow(Vector3(0.3, 0.18, 0.005), Color(0.4, 0.75, 0.95), at + turn * Vector3(0, 0.33, 0.04), 0.8).basis = turn * Basis(Vector3.RIGHT, -0.3)
	box(Vector3(0.09, 0.03, 0.14), Color(0.1, 0.1, 0.12), at + turn * Vector3(0.28, 0.02, -0.1), turn)
