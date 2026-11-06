class_name PlazaWalls
extends RefCounted
## Session 78: the blank walls you see from the Plaza get the same look as the two shops.
##   - each Plaza restaurant's two side walls (the row ends face the shops, the others face
##     the gaps between restaurants): a plinth, flat columns, two window bays with a
##     mashrabiya screen above each, a band in the restaurant's colour and a cornice
##   - the ends of the upper floors over the restaurant rows: two rows of windows, a band
##     and corner trims
## DistrictDetail calls build() after it makes the upper floors. Everything visible is ONE
## mesh; the flat columns get real collision. The restaurants' fronts and insides don't change.

const SHELL := 0.125   # half the thickness of a restaurant's outside wall
const NEAR_PLAZA := 90.0  # restaurants this close to the Plaza middle are dressed


## blocks: the node holding the upper floors (each a StaticBody3D with one big box).
static func build(blocks: Node3D, map: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "PlazaWalls"
	var kit := MeshKit.new()
	var walls := 0
	var centre := Vector2.ZERO
	if map.has("PLAZA"):
		centre = map["PLAZA"]["centre"]
	var size: Vector3 = map.get("RESTAURANT_SIZE", Vector3(18, 8, 16))
	for place: Dictionary in map.get("RESTAURANTS", []):
		var p: Vector3 = place["position"]
		if not place.get("interior", false) or Vector2(p.x, p.z).distance_to(centre) > NEAR_PLAZA:
			continue
		var tint: Color = RestaurantStyles.style(place["id"]).get("tint", place.get("colour", WallTrim.WALL))
		var where := Transform3D(Basis(Vector3.UP, deg_to_rad(place["facing"])), p)
		for s in [-1.0, 1.0]:
			_side_wall(kit, body, where, s, size, tint)
			walls += 1
	for upper in blocks.get_children():
		if upper is StaticBody3D and upper != body:
			walls += _upper_ends(kit, upper as StaticBody3D)
	body.add_child(kit.finish("PlazaWallTrim"))
	body.set_meta("walls", walls)
	blocks.add_child(body)
	return body


## One side wall of a restaurant (s = -1 left, +1 right, seen from the front).
static func _side_wall(kit: MeshKit, body: StaticBody3D, where: Transform3D, s: float, size: Vector3, tint: Color) -> void:
	var x := s * (size.x * 0.5 + SHELL)
	var half_z := size.z * 0.5 + SHELL
	var out := where.basis * Vector3(s, 0, 0)
	var turn := WallTrim.turn_for(out)
	var top := size.y
	# Bands along the whole wall: plinth, the restaurant's colour, cornice.
	for band: Array in [[0.0, 0.55, 0.08, WallTrim.PLINTH], [4.4, 4.9, 0.06, tint],
			[top - 0.45, top - 0.2, 0.22, WallTrim.TRIM], [top - 0.2, top, 0.12, WallTrim.TRIM]]:
		var stick: float = band[2]
		var spot := where * Vector3(x + s * (stick * 0.5 - 0.02), (band[0] + band[1]) * 0.5, 0)
		kit.box(Vector3(half_z * 2 + stick * 2, band[1] - band[0], stick + 0.04), band[3], spot, turn)
	for z in [-half_z + 0.3, 0.0, half_z - 0.3]:
		var spot := where * Vector3(x, 0, z)
		WallTrim.pier(kit, spot, out, 0.6, top - 0.45, 0.2)
		WallTrim.pier_shape(body, spot, out, 0.6, top - 0.45, 0.2)
	for z in [-4.0, 4.0]:
		WallTrim.window(kit, where * Vector3(x, 2.2, z), out, 1.4, 2.2)
		WallTrim.screen(kit, where * Vector3(x, 6.3, z), out, 1.2, 1.3)


## Windows and trims on both ends of one upper floor block. Returns how many ends.
static func _upper_ends(kit: MeshKit, upper: StaticBody3D) -> int:
	var size := Vector3.ZERO
	var middle := Vector3.ZERO
	for view in upper.get_children():
		if view is MeshInstance3D and (view as MeshInstance3D).mesh is BoxMesh:
			var box := (view as MeshInstance3D).mesh as BoxMesh
			if box.size.y > size.y:
				size = box.size
				middle = upper.position + (view as MeshInstance3D).position
	if size.y < 4.0:
		return 0
	var bottom := middle.y - size.y * 0.5
	for s in [-1.0, 1.0]:
		var face: float = middle.x + s * size.x * 0.5
		var out := Vector3(s, 0, 0)
		var turn := WallTrim.turn_for(out)
		for z in [-5.0, 0.0, 5.0]:
			for y in [2.0, 4.5]:
				WallTrim.window(kit, Vector3(face, bottom + y, middle.z + z), out, 1.3, 1.3)
		# Session 90: level with the homes' trim between the floors (scripts/plaza_homes.gd).
		kit.box(Vector3(size.z + 0.1, 0.14, 0.12), WallTrim.TRIM, Vector3(face + s * 0.04, bottom + GameConfig.PLAZA_HOME_STOREY, middle.z), turn)
		for z in [-1.0, 1.0]:  # corner trims, top to bottom
			var spot := Vector3(face + s * 0.04, bottom + size.y * 0.5, middle.z + z * (size.z * 0.5 - 0.2))
			kit.box(Vector3(0.4, size.y, 0.12), WallTrim.PIER, spot, turn)
	return 2
