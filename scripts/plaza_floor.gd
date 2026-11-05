class_name PlazaFloor
extends RefCounted
## Session 77: the Plaza's one square paved floor. It runs from the bike shop to Dune Drip and
## from the north restaurant row to the south row, so every door, both shops and the café
## tables stand on paving. A round hole in the middle leaves room for the sunken square
## (its steps and fountain stay where they were). The "aprons" go round Dune Drip to the
## buggy park behind it. The floor is the CC0 square_concrete_pavers photo (Poly Haven).
## PlazaBuilder calls build(); is_paved() tells anyone whether a spot is on this floor.

const TEXTURE := "res://assets/textures/square_concrete_pavers_diff_1k.jpg"
const SEGMENTS := 64   # how round the hole is

static var _material: StandardMaterial3D = null


## Builds the floor (one mesh, named "Plaza") under `parent`. top: its height (metres);
## lip: how far the edge of the hole drops to the top step.
static func build(parent: Node3D, plaza: Dictionary, top: float, lip: float) -> MeshInstance3D:
	var centre: Vector2 = plaza["centre"]
	var hole: float = plaza["sunken_radius"]
	var area: Rect2 = plaza["floor"]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Round the hole in short pieces. Each piece joins the hole's edge to the square's edge
	# straight out from the middle; the square's corners are extra pieces so none is cut off.
	var angles: Array[float] = []
	for i in SEGMENTS:
		angles.append(TAU * i / SEGMENTS)
	for corner: Vector2 in [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]:
		angles.append(fposmod((corner - centre).angle(), TAU))
	angles.sort()
	for i in angles.size():
		var a := angles[i]
		var b := angles[(i + 1) % angles.size()]
		var da := Vector2.from_angle(a)
		var db := Vector2.from_angle(b)
		var ia := centre + da * hole
		var ib := centre + db * hole
		var oa := _to_edge(area, centre, da)
		var ob := _to_edge(area, centre, db)
		_quad(tool, _at(ia, top), _at(ib, top), _at(ob, top), _at(oa, top), Vector3.UP)
		# The low wall round the hole's edge, down to the top step, facing the fountain.
		var low := top - lip
		var inward := -Vector3(da.x + db.x, 0, da.y + db.y).normalized()
		_quad(tool, _at(ia, low), _at(ia, top), _at(ib, top), _at(ib, low), inward)
	for apron: Rect2 in plaza.get("aprons", []):
		_quad(tool, _at(apron.position, top), _at(Vector2(apron.end.x, apron.position.y), top),
				_at(apron.end, top), _at(Vector2(apron.position.x, apron.end.y), top), Vector3.UP)
	var view := MeshInstance3D.new()
	view.name = "Plaza"
	view.mesh = tool.commit()
	view.material_override = material()
	parent.add_child(view)
	return view


## The pavers material: the photo repeated every PLAZA_PAVER_TILE metres across the world
## ("world triplanar"), so it never stretches, tinted warm like the buildings.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_texture = load(TEXTURE)
		_material.albedo_color = GameConfig.PLAZA_PAVER_TINT
		_material.roughness = 0.9
		_material.uv1_triplanar = true
		_material.uv1_world_triplanar = true
		_material.uv1_scale = Vector3.ONE / GameConfig.PLAZA_PAVER_TILE
		_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _material


## Is this spot (x, z) on the paved Plaza floor (and not down in the sunken square)?
static func is_paved(map: Dictionary, spot: Vector2) -> bool:
	var plaza: Dictionary = map.get("PLAZA", {})
	if plaza.is_empty() or spot.distance_to(plaza["centre"]) < plaza["sunken_radius"]:
		return false
	if plaza.has("floor") and (plaza["floor"] as Rect2).has_point(spot):
		return true
	for apron: Rect2 in plaza.get("aprons", []):
		if apron.has_point(spot):
			return true
	return false


## Where a line from the middle going `direction` leaves the square.
static func _to_edge(area: Rect2, centre: Vector2, direction: Vector2) -> Vector2:
	var best := INF
	if direction.x > 0.0001:
		best = minf(best, (area.end.x - centre.x) / direction.x)
	elif direction.x < -0.0001:
		best = minf(best, (area.position.x - centre.x) / direction.x)
	if direction.y > 0.0001:
		best = minf(best, (area.end.y - centre.y) / direction.y)
	elif direction.y < -0.0001:
		best = minf(best, (area.position.y - centre.y) / direction.y)
	return centre + direction * best


static func _at(spot: Vector2, height: float) -> Vector3:
	return Vector3(spot.x, height, spot.y)


## Two triangles for a 4-cornered face whose front faces `normal`. Godot shows a triangle's
## front when its corners go round clockwise, so the order is flipped when needed.
static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for tri: Array in [[a, b, c], [a, c, d]]:
		var p: Vector3 = tri[0]
		var q: Vector3 = tri[1]
		var r: Vector3 = tri[2]
		var corners := [p, q, r] if (q - p).cross(r - p).dot(normal) < 0.0 else [p, r, q]
		tool.set_normal(normal)
		for corner: Vector3 in corners:
			tool.add_vertex(corner)
