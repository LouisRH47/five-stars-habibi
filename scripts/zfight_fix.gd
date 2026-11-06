class_name ZFightFix
extends RefCounted
## Session 52: stops flicker ("z-fighting").
## When two boxes have a face in exactly the same place, facing the same way, with
## different colours, the graphics card can't tell which is in front, so it flickers
## when the camera moves (the speed bump stripes, a gate pillar on a wall, a roof trim).
## find() lists those pairs; apply() fixes each one by making the smaller box a few
## millimetres bigger in that direction, so it wins cleanly. Run before StaticBatch.bake.
## tests/coplanar_test.gd checks the whole map has none left.

## Faces closer than this (metres) count as "in the same place".
const EPS := 0.004
## Overlaps smaller than this (square metres) are too small to see.
const MIN_AREA := 0.02
## How much the smaller box grows on each side (metres).
const GROW := 0.006
const CELL := 8.0


## Every flat-sided box in `root`: [MeshInstance3D, world AABB, colour key].
static func boxes(root: Node) -> Array:
	var found: Array = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if not part.mesh is BoxMesh:
			continue
		var xf := part.global_transform
		if not _axis_aligned(xf.basis):
			continue
		var box := part.mesh as BoxMesh
		found.append([part, xf * AABB(-box.size * 0.5, box.size), _colour_key(part, box)])
	return found


## Pairs that would flicker: [index a, index b, axis (0 x, 1 y, 2 z), text].
static func find(list: Array) -> Array:
	var grid := {}
	for i in list.size():
		var aabb: AABB = list[i][1]
		for gx in range(floori(aabb.position.x / CELL), floori(aabb.end.x / CELL) + 1):
			for gz in range(floori(aabb.position.z / CELL), floori(aabb.end.z / CELL) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				grid[key].append(i)
	var seen := {}
	var pairs: Array = []
	for key in grid:
		var cell: Array = grid[key]
		for a in cell.size():
			for b in range(a + 1, cell.size()):
				var i: int = mini(cell[a], cell[b])
				var j: int = maxi(cell[a], cell[b])
				var pair := Vector2i(i, j)
				if seen.has(pair):
					continue
				seen[pair] = true
				if list[i][2] == list[j][2]:
					continue
				var hit := shared_face(list[i][1], list[j][1])
				if not hit.is_empty():
					pairs.append([i, j, hit["axis"], hit["text"]])
	return pairs


## Fixes every flickering pair under `root`. Returns how many boxes it changed.
## Growing one box can line it up with a third one, so it goes round a few times.
static func apply(root: Node) -> int:
	var total := 0
	for round in 4:
		var changed := _apply_once(root)
		total += changed
		if changed == 0:
			break
	return total


## One round of apply() (Session 86: the loading screen does one round per step).
static func apply_once(root: Node) -> int:
	return _apply_once(root)


static func _apply_once(root: Node) -> int:
	var list := boxes(root)
	var pairs := find(list)
	var grown := {}
	for pair in pairs:
		var a: Array = list[pair[0]]
		var b: Array = list[pair[1]]
		var axis: int = pair[2]
		# Grow the smaller one (the stripe, the door, the trim), not the wall it sits on.
		var small: Array = a if _face_area(a[1], axis) <= _face_area(b[1], axis) else b
		var part: MeshInstance3D = small[0]
		var key := "%d:%d" % [part.get_instance_id(), axis]
		if grown.has(key):
			continue
		grown[key] = true
		_grow(part, axis)
	return grown.size()


## {"axis", "text"} if A and B have a same-direction face in the same place, else {}.
## Bottoms resting on the ground can't be seen, so they're left alone.
static func shared_face(a: AABB, b: AABB) -> Dictionary:
	var names := ["x", "y", "z"]
	for axis in 3:
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		var overlap_u := minf(a.end[u], b.end[u]) - maxf(a.position[u], b.position[u])
		var overlap_v := minf(a.end[v], b.end[v]) - maxf(a.position[v], b.position[v])
		if overlap_u <= 0.0 or overlap_v <= 0.0 or overlap_u * overlap_v < MIN_AREA:
			continue
		if absf(a.end[axis] - b.end[axis]) < EPS:
			return {"axis": axis, "text": "+%s face at %.3f" % [names[axis], a.end[axis]]}
		if axis == 1:
			continue  # bottoms are hidden (underground or inside something)
		if absf(a.position[axis] - b.position[axis]) < EPS:
			return {"axis": axis, "text": "-%s face at %.3f" % [names[axis], a.position[axis]]}
	return {}


static func _grow(part: MeshInstance3D, world_axis: int) -> void:
	var box := part.mesh as BoxMesh
	var basis := part.global_transform.basis
	for local in 3:
		var column: Vector3 = basis[local].normalized()
		if absf(column[world_axis]) > 0.99:
			var size: float = box.size[local] * part.scale[local]
			if size <= 0.0:
				return
			var s := part.scale
			s[local] *= (size + GROW * 2.0) / size
			part.scale = s
			return


static func _face_area(aabb: AABB, axis: int) -> float:
	return aabb.size[(axis + 1) % 3] * aabb.size[(axis + 2) % 3]


static func _axis_aligned(basis: Basis) -> bool:
	for column in [basis.x, basis.y, basis.z]:
		var c: Vector3 = column.normalized().abs()
		if maxf(c.x, maxf(c.y, c.z)) < 0.9999:
			return false
	return true


static func _colour_key(part: MeshInstance3D, box: BoxMesh) -> String:
	var material: Material = part.material_override
	if material == null:
		material = box.material
	if material == null:
		return "none"
	var standard := material as BaseMaterial3D
	if standard == null:
		return str(material.get_instance_id())
	var texture := ""
	if standard.albedo_texture != null:
		texture = standard.albedo_texture.resource_path
	return standard.albedo_color.to_html() + texture
