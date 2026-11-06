class_name RoomProps
## Interior bits built from basic shapes (Session 54), for things the free kits don't have:
## a glass drinks fridge, a bin, a big plant, warm hanging lamps, a menu board, tiled
## floors and glass. Each function adds the thing to "parent" and returns it.
## The front of each thing faces +Z unless it is turned (facing in degrees).

const GLASS := Color(0.62, 0.82, 0.9, 0.22)
const METAL := Color(0.22, 0.23, 0.25)
const STEEL := Color(0.72, 0.74, 0.76)
const LEAF := Color(0.24, 0.52, 0.27)
const POT := Color(0.78, 0.5, 0.33)
const WARM := Color(1.0, 0.82, 0.58)
const BOTTLES := [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.9), Color(0.95, 0.75, 0.2),
		Color(0.3, 0.75, 0.35), Color(0.95, 0.5, 0.15), Color(0.95, 0.95, 0.95)]

static var _glass: StandardMaterial3D
static var _floors: Dictionary = {}


## See-through glass, shared.
static func glass() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = GLASS
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.roughness = 0.08
		_glass.metallic_specular = 0.9
	return _glass


## A pane of glass (not solid). Returns the mesh.
static func pane(parent: Node3D, size: Vector3, spot: Vector3) -> MeshInstance3D:
	var view := LowPoly.box(parent, size, Color.WHITE, spot)
	view.material_override = glass()
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return view


## A tall glass-door drinks fridge full of coloured bottles. Solid.
static func drinks_fridge(parent: Node3D, spot: Vector3, facing := 0.0) -> Node3D:
	var holder := _holder(parent, spot, facing, "DrinksFridge")
	LowPoly.box(holder, Vector3(1.2, 2.1, 0.75), Color(0.94, 0.94, 0.95), Vector3(0, 1.05, 0))
	LowPoly.box(holder, Vector3(1.05, 1.7, 0.05), Color(0.12, 0.15, 0.2), Vector3(0, 1.05, 0.36))
	for row in 4:
		LowPoly.box(holder, Vector3(1.0, 0.03, 0.5), STEEL, Vector3(0, 0.32 + row * 0.42, 0.1))
		for i in 6:
			LowPoly.cylinder(holder, 0.05, 0.06, 0.3, BOTTLES[(i + row) % BOTTLES.size()],
					Vector3(-0.4 + i * 0.16, 0.49 + row * 0.42, 0.2))
	pane(holder, Vector3(1.05, 1.7, 0.03), Vector3(0, 1.05, 0.4))
	LowPoly.box(holder, Vector3(1.2, 0.25, 0.05), Color(0.16, 0.56, 0.61), Vector3(0, 2.0, 0.39))
	_solid(parent, holder, Vector3(1.2, 2.1, 0.75))
	return holder


## A steel bin with a swing lid.
static func bin(parent: Node3D, spot: Vector3) -> Node3D:
	var holder := _holder(parent, spot, 0.0, "Bin")
	LowPoly.cylinder(holder, 0.25, 0.22, 0.8, STEEL, Vector3(0, 0.4, 0))
	LowPoly.cylinder(holder, 0.27, 0.27, 0.06, METAL, Vector3(0, 0.83, 0))
	LowPoly.box(holder, Vector3(0.2, 0.04, 0.05), Color(0.1, 0.1, 0.1), Vector3(0, 0.87, 0.18))
	return holder


## A big leafy plant in a clay pot.
static func big_plant(parent: Node3D, spot: Vector3, leaf := LEAF) -> Node3D:
	var holder := _holder(parent, spot, 0.0, "Plant")
	LowPoly.cylinder(holder, 0.32, 0.24, 0.55, POT, Vector3(0, 0.27, 0))
	for i in 5:
		var a := i * TAU / 5.0
		var leaf_ball := LowPoly.sphere(holder, 0.3, 0.75, leaf.lightened(0.05 * i),
				Vector3(cos(a) * 0.2, 1.0 + (i % 2) * 0.25, sin(a) * 0.2))
		leaf_ball.rotation.z = cos(a) * 0.5
	LowPoly.sphere(holder, 0.32, 0.8, leaf, Vector3(0, 1.45, 0))
	return holder


## A warm hanging lamp: a cord from the ceiling and a glowing shade. top: the ceiling height.
static func pendant_lamp(parent: Node3D, spot: Vector3, shade := Color(0.15, 0.15, 0.16), top := 4.5) -> Node3D:
	var holder := _holder(parent, Vector3(spot.x, 0, spot.z), 0.0, "Lamp")
	var drop := 1.3
	LowPoly.cylinder(holder, 0.01, 0.01, drop, Color(0.1, 0.1, 0.1), Vector3(0, top - drop * 0.5, 0))
	LowPoly.cylinder(holder, 0.08, 0.32, 0.3, shade, Vector3(0, top - drop - 0.1, 0))
	var bulb := LowPoly.sphere(holder, 0.11, 0.22, WARM, Vector3(0, top - drop - 0.25, 0))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = WARM
	glow.emission_enabled = true
	glow.emission = WARM
	glow.emission_energy_multiplier = 3.0
	bulb.material_override = glow
	return holder


## A dark menu board with a bilingual title and lines of "Item ... price". Faces +Z.
static func menu_board(parent: Node3D, spot: Vector3, items: Array, tint: Color) -> Node3D:
	var holder := _holder(parent, spot, 0.0, "MenuBoard")
	var width := 4.2
	var height := 1.3
	LowPoly.box(holder, Vector3(width + 0.16, height + 0.16, 0.06), tint, Vector3(0, 0, -0.02))
	LowPoly.box(holder, Vector3(width, height, 0.08), Color(0.07, 0.08, 0.09), Vector3.ZERO)
	var title := SignText.make_label("القائمة · Menu", 30, Color(1, 0.86, 0.55), Color(0, 0, 0, 0), 0)
	title.position = Vector3(0, height * 0.5 - 0.2, 0.05)
	holder.add_child(title)
	for i in items.size():
		var column := i % 2
		var line := SignText.make_label(str(items[i]), 22, Color.WHITE, Color(0, 0, 0, 0), 0)
		line.position = Vector3(-width * 0.25 + column * width * 0.5, 0.12 - (i / 2) * 0.3, 0.05)
		holder.add_child(line)
	return holder


## A tiled floor material: square tiles of two colours (a checker or plain), with thin
## grout lines. tile: tile size in metres. pattern: "checker", "plain", "stripes",
## "star" (Arabic-style tiles), "planks" (wood floor), "talavera" (colourful painted tiles)
## or "metro" (white brick tiles).
static func floor_material(a: Color, b: Color, pattern := "checker", tile := 0.5, area := Vector2(12, 10)) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s" % [a, b, pattern, tile, area]
	if _floors.has(key):
		return _floors[key]
	var size := 32
	var picture := Image.create(size * 2, size * 2, false, Image.FORMAT_RGB8)
	for y in size * 2:
		for x in size * 2:
			picture.set_pixel(x, y, _floor_pixel(a, b, pattern, x, y, size))
	picture.generate_mipmaps()
	var made := StandardMaterial3D.new()
	made.albedo_texture = ImageTexture.create_from_image(picture)
	made.uv1_scale = Vector3(area.x / (tile * 2.0), area.y / (tile * 2.0), 1)
	made.roughness = 0.45 if pattern != "planks" else 0.75
	_floors[key] = made
	return made


static func _floor_pixel(a: Color, b: Color, pattern: String, x: int, y: int, size: int) -> Color:
	var gx := x % size
	var gy := y % size
	var grout := gx == 0 or gy == 0
	var odd := ((x / size) + (y / size)) % 2 == 1
	match pattern:
		"plain":
			return a.darkened(0.25) if grout else a
		"stripes":
			return a if (x / 8) % 2 == 0 else b
		"planks":
			var row := y / 16
			var shift := (row % 2) * 24
			var seam := (y % 16 == 0) or ((x + shift) % 48 == 0)
			return a.darkened(0.3) if seam else a.lerp(b, float((row * 7) % 5) / 8.0)
		"star":
			var cx := absi(gx - size / 2)
			var cy := absi(gy - size / 2)
			if grout:
				return b.darkened(0.3)
			if cx + cy < size / 3 or (cx < 3 or cy < 3) and cx + cy < size / 2:
				return b
			return a
		"talavera":  # colourful painted tiles, each a different colour with a flower dot
			if grout:
				return Color(0.95, 0.93, 0.88)
			var palette := [a, b, Color(0.96, 0.75, 0.2), Color(0.12, 0.5, 0.6)]
			var tile: Color = palette[((x / size) * 3 + (y / size) * 2 + (x / size) * (y / size)) % 4]
			var dot := absi(gx - size / 2) + absi(gy - size / 2) < size / 5
			return Color(0.98, 0.96, 0.9) if dot else tile
		"metro":  # white brick-shaped tiles with grey grout
			var row := y / 8
			var shift := (row % 2) * 8
			return b if (y % 8 == 0 or (x + shift) % 16 == 0) else a
		_:
			if grout:
				return Color(0.75, 0.75, 0.72)
			return b if odd else a


static func _holder(parent: Node3D, spot: Vector3, facing: float, name: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = name
	holder.position = spot
	holder.rotation_degrees.y = facing
	parent.add_child(holder, true)
	return holder


## A solid box for a holder, added to the nearest body above it (if any).
static func _solid(parent: Node3D, holder: Node3D, size: Vector3) -> void:
	var body: Node = parent
	while body != null and not body is CollisionObject3D:
		body = body.get_parent()
	if body == null:
		return
	var shape := LowPoly.solid_box(body as Node3D, size, Vector3.ZERO)
	var where := (body as Node3D).global_transform.affine_inverse() * holder.global_transform if holder.is_inside_tree() else _relative(body, holder)
	shape.transform = where.translated_local(Vector3(0, size.y * 0.5, 0))


static func _relative(body: Node, node: Node3D) -> Transform3D:
	var where := node.transform
	var parent := node.get_parent()
	while parent != body and parent is Node3D:
		where = (parent as Node3D).transform * where
		parent = parent.get_parent()
	return where
