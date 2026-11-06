class_name Props
## Small low-poly things built in code and used all over Wahat Al Shams (Session 27):
## benches, playgrounds, fences, cooling towers, horses and donkeys.
## Each function adds the new thing to "parent" and returns it.

const WOOD := Color(0.6, 0.42, 0.26, 1)
const METAL := Color(0.3, 0.32, 0.35, 1)
const STONE := Color(0.9, 0.85, 0.74, 1)
const RUBBER := Color(0.85, 0.42, 0.3, 1)      # the soft red ground under a playground
const SLIDE := Color(0.98, 0.78, 0.2, 1)
const PLAY_FRAME := Color(0.16470589, 0.5568628, 0.6117647, 1)  # the game's teal


## A wooden bench on stone legs. facing: the way you look when you sit (degrees, 0 = south).
static func bench(parent: Node3D, spot: Vector3, facing: float) -> StaticBody3D:
	var body := _body(parent, spot, facing)
	LowPoly.box(body, Vector3(1.8, 0.08, 0.5), WOOD, Vector3(0, 0.45, 0))
	LowPoly.box(body, Vector3(1.8, 0.4, 0.06), WOOD, Vector3(0, 0.72, -0.24))
	for x in [-0.75, 0.75]:
		LowPoly.box(body, Vector3(0.12, 0.45, 0.45), STONE, Vector3(x, 0.22, 0))
	LowPoly.solid_box(body, Vector3(1.8, 0.9, 0.5), Vector3(0, 0.45, 0))
	return body


## A small playground on soft red ground: a slide and a swing frame. size: the ground (x, z).
static func playground(parent: Node3D, middle: Vector3, size: Vector2) -> StaticBody3D:
	var body := _body(parent, middle, 0.0)
	LowPoly.box(body, Vector3(size.x, 0.03, size.y), RUBBER, Vector3(0, 0.03, 0))
	# The slide: a little tower with a roof, and the slide coming down.
	var tower := Vector3(-size.x * 0.25, 0, 0)
	for x in [-0.6, 0.6]:
		for z in [-0.6, 0.6]:
			LowPoly.box(body, Vector3(0.12, 2.4, 0.12), PLAY_FRAME, tower + Vector3(x, 1.2, z))
	LowPoly.box(body, Vector3(1.4, 0.1, 1.4), WOOD, tower + Vector3(0, 1.2, 0))
	LowPoly.cylinder(body, 0.0, 1.1, 0.7, SLIDE, tower + Vector3(0, 2.75, 0))
	var slide := LowPoly.box(body, Vector3(0.7, 0.08, 2.6), SLIDE, tower + Vector3(0, 0.65, 1.8))
	slide.rotation.x = deg_to_rad(25.0)
	LowPoly.solid_box(body, Vector3(1.4, 2.4, 1.4), tower + Vector3(0, 1.2, 0))
	# The swings: an A-frame with two seats on chains.
	var swing := Vector3(size.x * 0.25, 0, 0)
	for x in [-1.3, 1.3]:
		for z in [-0.5, 0.5]:
			var leg := LowPoly.box(body, Vector3(0.1, 2.3, 0.1), PLAY_FRAME, swing + Vector3(x, 1.1, z * 0.6))
			leg.rotation.x = deg_to_rad(12.0 * signf(z))
		LowPoly.solid_box(body, Vector3(0.3, 2.2, 1.0), swing + Vector3(x, 1.1, 0))
	LowPoly.box(body, Vector3(2.8, 0.1, 0.1), PLAY_FRAME, swing + Vector3(0, 2.2, 0))
	for x in [-0.6, 0.6]:
		LowPoly.box(body, Vector3(0.02, 1.6, 0.02), METAL, swing + Vector3(x - 0.2, 1.4, 0))
		LowPoly.box(body, Vector3(0.02, 1.6, 0.02), METAL, swing + Vector3(x + 0.2, 1.4, 0))
		LowPoly.box(body, Vector3(0.5, 0.05, 0.25), RUBBER.darkened(0.3), swing + Vector3(x, 0.6, 0))
	return body


## A fence from one spot to another (x, z): posts and two rails. Solid unless solid = false.
static func fence(parent: Node3D, from: Vector2, to: Vector2, height: float, colour: Color,
		solid := true) -> StaticBody3D:
	var middle := (from + to) * 0.5
	var length := from.distance_to(to)
	var way := to - from
	var body := StaticBody3D.new()
	body.position = Vector3(middle.x, 0, middle.y)
	body.rotation.y = atan2(way.x, way.y)  # the fence runs along its own Z
	parent.add_child(body)
	var posts := maxi(1, ceili(length / 2.5))
	for i in posts + 1:
		var z := -length * 0.5 + length * float(i) / posts
		LowPoly.box(body, Vector3(0.12, height, 0.12), colour, Vector3(0, height * 0.5, z))
	for y in [height * 0.45, height * 0.9]:
		LowPoly.box(body, Vector3(0.06, 0.1, length), colour, Vector3(0, y, 0))
	if solid:
		LowPoly.solid_box(body, Vector3(0.3, height, length), Vector3(0, height * 0.5, 0))
	return body


## A cooling tower for a cluster mini-plaza: a tall sand-coloured tower with slots at the top
## (like a wind tower) and a misting ring that cools the air round the benches.
static func cooling_tower(parent: Node3D, spot: Vector3) -> StaticBody3D:
	var body := _body(parent, spot, 0.0)
	var sand := Color(0.88, 0.76, 0.58, 1)
	LowPoly.box(body, Vector3(2.4, 7.0, 2.4), sand, Vector3(0, 3.5, 0))
	LowPoly.box(body, Vector3(2.8, 0.3, 2.8), sand.darkened(0.1), Vector3(0, 7.15, 0))
	for side in 4:
		var a := side * PI * 0.5
		var out := Vector3(sin(a), 0, cos(a)) * 1.21
		for i in 3:
			var slot := LowPoly.box(body, Vector3(0.35, 1.4, 0.05), Color(0.25, 0.2, 0.15, 1),
					out + Vector3(cos(a), 0, -sin(a)) * (i - 1) * 0.6 + Vector3(0, 6.0, 0))
			slot.rotation.y = a
	LowPoly.cylinder(body, 1.9, 1.9, 0.15, METAL, Vector3(0, 2.6, 0))  # the misting ring
	LowPoly.solid_box(body, Vector3(2.4, 7.0, 2.4), Vector3(0, 3.5, 0))
	return body


## A horse (big = true) or a donkey, standing still. Just to look at: not solid.
static func animal(parent: Node3D, spot: Vector3, facing: float, colour: Color, big: bool) -> Node3D:
	var holder := Node3D.new()
	holder.position = spot
	holder.rotation_degrees.y = facing
	holder.scale = Vector3.ONE * (1.0 if big else 0.75)
	parent.add_child(holder)
	var dark := colour.darkened(0.35)
	LowPoly.box(holder, Vector3(0.6, 0.7, 1.7), colour, Vector3(0, 1.35, 0))         # body
	for x in [-0.22, 0.22]:
		for z in [-0.65, 0.65]:
			LowPoly.box(holder, Vector3(0.14, 1.0, 0.14), colour, Vector3(x, 0.5, z))  # legs
	var neck := LowPoly.box(holder, Vector3(0.3, 0.9, 0.35), colour, Vector3(0, 1.9, 0.85))
	neck.rotation.x = deg_to_rad(30.0)
	LowPoly.box(holder, Vector3(0.3, 0.3, 0.7), colour, Vector3(0, 2.25, 1.3))       # head
	LowPoly.box(holder, Vector3(0.08, 0.5, 0.5), dark, Vector3(0, 2.05, 0.75))       # mane
	var ears := 0.18 if big else 0.4  # donkeys have long ears
	for x in [-0.1, 0.1]:
		LowPoly.box(holder, Vector3(0.06, ears, 0.06), dark, Vector3(x, 2.45 + ears * 0.5, 1.05))
	var tail := LowPoly.box(holder, Vector3(0.1, 0.8, 0.1), dark, Vector3(0, 1.2, -0.9))
	tail.rotation.x = deg_to_rad(-20.0)
	return holder


static func _body(parent: Node3D, spot: Vector3, facing: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = spot
	body.rotation_degrees.y = facing
	parent.add_child(body)
	return body


# ---------------- Session 53: models from the free CC0 kits ----------------
# The kits live in assets/kits/<pack>/ (glTF, see CREDITS.md). Props.kit() places one model
# by name; Props.bake_kits() then joins every kit model in a room into one mesh per kit,
# so a full restaurant costs only a couple of draws.

## Short pack names and their folders. A name can be "chair_A" (looked up in this order)
## or "furniture/chair_A_wood" to pick the pack.
const KIT_PACKS := {
	"restaurant": "res://assets/kits/kaykit_restaurant_bits/",
	"furniture": "res://assets/kits/kaykit_furniture_bits/",
}
## Kit models are drawn up to this far away (metres); further off they are hidden.
const KIT_DRAW_DISTANCE := 90.0

static var _kit_parts: Dictionary = {}       # name -> [[mesh, transform], ...]
static var _kit_materials: Dictionary = {}   # pack -> the one shared material


## Places one kit model. rotation: degrees round Y (or a Vector3 of degrees).
## size: a number (same in every direction) or a Vector3. Returns the holder node.
static func kit(name: String, parent: Node3D, spot: Vector3, rotation = 0.0, size = 1.0) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Kit_" + name.get_file()
	holder.position = spot
	holder.rotation_degrees = rotation if rotation is Vector3 else Vector3(0, float(rotation), 0)
	holder.scale = size if size is Vector3 else Vector3.ONE * float(size)
	holder.set_meta("kit_prop", name)
	parent.add_child(holder, true)
	var pack := kit_pack(name)
	for part: Array in kit_parts(name):
		var view := MeshInstance3D.new()
		view.mesh = part[0]
		view.transform = part[1]
		view.material_override = kit_material(pack)
		view.visibility_range_end = KIT_DRAW_DISTANCE
		holder.add_child(view)
	return holder


## True if a model with this name is in one of the kits.
static func has_kit(name: String) -> bool:
	return kit_pack(name) != ""


## Which pack a model is in ("" if none).
static func kit_pack(name: String) -> String:
	if "/" in name:
		var pack := name.get_slice("/", 0)
		return pack if KIT_PACKS.has(pack) and ResourceLoader.exists(KIT_PACKS[pack] + name.get_file() + ".gltf") else ""
	for pack: String in KIT_PACKS:
		if ResourceLoader.exists(KIT_PACKS[pack] + name + ".gltf"):
			return pack
	return ""


## The meshes in one model and where they sit in it. Loaded once, then shared.
static func kit_parts(name: String) -> Array:
	if _kit_parts.has(name):
		return _kit_parts[name]
	var parts: Array = []
	var pack := kit_pack(name)
	if pack == "":
		push_error("No kit model called " + name)
		_kit_parts[name] = parts
		return parts
	var scene := load(KIT_PACKS[pack] + name.get_file() + ".gltf") as PackedScene
	var model := scene.instantiate() as Node3D
	for view: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var where := view.transform
		var node := view.get_parent()
		while node != model and node is Node3D:
			where = (node as Node3D).transform * where
			node = node.get_parent()
		parts.append([view.mesh, where])
	model.free()
	_kit_parts[name] = parts
	return parts


## One shared material per kit: every model in a kit is painted from the same picture.
static func kit_material(pack: String) -> StandardMaterial3D:
	if not _kit_materials.has(pack):
		var picture := "restaurantbits_texture.png" if pack == "restaurant" else "furniturebits_texture.png"
		var made := StandardMaterial3D.new()
		made.albedo_texture = load(KIT_PACKS[pack] + picture)
		made.roughness = 0.8
		_kit_materials[pack] = made
	return _kit_materials[pack]


## Joins every kit model under root (that isn't marked as moving) into one mesh per kit.
## The holders are removed; root keeps meta "kit_props" (how many) and "kit_names".
static func bake_kits(root: Node3D) -> int:
	var tools := {}
	var names: Array = []
	var holders: Array[Node] = []
	for holder: Node in root.find_children("*", "Node3D", true, false):
		if not holder.has_meta("kit_prop") or _moving(holder, root):
			continue
		var pack := kit_pack(holder.get_meta("kit_prop"))
		if not tools.has(pack):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[pack] = tool
		for view: MeshInstance3D in holder.get_children():
			var where := _local_to(root, view)
			for surface in view.mesh.get_surface_count():
				tools[pack].append_from(view.mesh, surface, where)
		names.append(holder.get_meta("kit_prop"))
		holders.append(holder)
	for pack: String in tools:
		var view := MeshInstance3D.new()
		view.name = "KitBatch_" + pack
		view.mesh = tools[pack].commit()
		view.material_override = kit_material(pack)
		view.visibility_range_end = KIT_DRAW_DISTANCE
		root.add_child(view)
	for holder in holders:
		holder.get_parent().remove_child(holder)
		holder.free()
	root.set_meta("kit_props", root.get_meta("kit_props", 0) + names.size())
	root.set_meta("kit_names", root.get_meta("kit_names", []) + names)
	return names.size()


static func _moving(node: Node, root: Node) -> bool:
	while node != null and node != root:
		if node.get_meta("static_batch_dynamic", false):
			return true
		node = node.get_parent()
	return false


static func _local_to(root: Node, node: Node3D) -> Transform3D:
	var where := node.transform
	var parent := node.get_parent()
	while parent != root and parent is Node3D:
		where = (parent as Node3D).transform * where
		parent = parent.get_parent()
	return where
