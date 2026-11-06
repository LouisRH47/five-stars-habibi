class_name PlaygroundKit
extends Node3D
## Session 71: the rounded playgrounds made in Blender (tools/blender/make_playground.py:
## play_slide, play_swings, play_climber, play_spinner, play_springer in assets/models/).
## build() lays a soft rubber floor with rounded corners (play_surface.png) and places the
## pieces for the size of the playground, with kids on the swings, the roundabout and the
## spring rider. This node (one per playground) swings the swings, turns the roundabout and
## rocks the spring rider, only while you're near enough to see it.
## Used by SpineBuilder (the spine playground and the cluster plazas) and DistrictDetail
## (the two school playgrounds) instead of the old Props.playground.

const KERB := Color(0.56, 0.84, 0.71)  # the soft mint edge round the floor
const PIECE_VIEW := 170.0               # metres: the pieces aren't drawn further away than this
const KID_SEAT := 0.06                  # how far above a seat a kid's hips sit

## [node, kind, phase]: the moving parts ("swing", "spin", "rock").
var parts: Array = []
## The kids on the pieces (for the smoke test and the distance check).
var kids: Array[Person] = []

var _clock := 0.0
var _near := true
var _check_left := 0.0

static var _scenes := {}
static var _paint: StandardMaterial3D


## The one material for every piece: it takes the colours painted on the mesh in Blender.
static func paint_material() -> StandardMaterial3D:
	if _paint == null:
		_paint = StandardMaterial3D.new()
		_paint.vertex_color_use_as_albedo = true  # the colours are linear (as glTF stores them)
		_paint.roughness = 0.6
	return _paint


## A playground: the floor (size: x and z, metres) with its middle at `middle`. Returns the
## solid body, like Props.playground did.
static func build(parent: Node3D, middle: Vector3, size: Vector2) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Playground"
	body.position = middle
	parent.add_child(body)
	var kit := PlaygroundKit.new()
	kit.name = "PlaygroundKit"
	body.add_child(kit)
	var corner := minf(size.x, size.y) * 0.3
	kit._rounded_slab(size + Vector2(0.5, 0.5), corner + 0.25, 0.05, null, KERB)
	kit._rounded_slab(size, corner, 0.07, SurfaceTextures.make("play_surface"), Color.WHITE)
	var half := size * 0.5
	if size.x < 9.0:  # a cluster plaza: a small slide, the roundabout and a spring rider
		# The kids run along the -z edge (PLAY_KIDS), so the solid pieces keep to the +z side.
		kit._piece("play_slide", body, Vector3(-half.x + 1.25, 0, 0.75), 0.0, 0.75, Vector3(1.05, 2.2, 1.05))
		kit._piece("play_spinner", body, Vector3(half.x - 1.05, 0, 1.2), 0.0, 1.0, Vector3.ZERO, 0.85)
		kit._piece("play_springer", body, Vector3(half.x - 1.3, 0, -0.85), 180.0, 1.0)
	elif size.x < 18.0:  # the school playgrounds
		kit._piece("play_slide", body, Vector3(-half.x + 1.7, 0, -half.y * 0.5), 0.0, 1.0, Vector3(1.4, 2.3, 1.4))
		kit._piece("play_swings", body, Vector3(half.x * 0.5 + 0.2, 0, -half.y * 0.5 + 0.2), 0.0, 1.0, Vector3(3.4, 2.3, 0.4))
		kit._piece("play_spinner", body, Vector3(-half.x * 0.4, 0, half.y * 0.5), 0.0, 1.0, Vector3.ZERO, 0.85)
		kit._piece("play_climber", body, Vector3(half.x * 0.5, 0, half.y * 0.5), 0.0, 1.0, Vector3.ZERO, 1.35)
		kit._piece("play_springer", body, Vector3(0.3, 0, 0.6), 90.0, 1.0)
	else:  # the big one in the spine
		kit._piece("play_slide", body, Vector3(-half.x + 2.0, 0, -half.y * 0.4), 0.0, 1.0, Vector3(1.4, 2.3, 1.4))
		kit._piece("play_swings", body, Vector3(-0.5, 0, -half.y * 0.45), 0.0, 1.0, Vector3(3.4, 2.3, 0.4))
		kit._piece("play_climber", body, Vector3(half.x * 0.55, 0, -half.y * 0.3), 0.0, 1.0, Vector3.ZERO, 1.35)
		kit._piece("play_spinner", body, Vector3(-half.x * 0.45, 0, half.y * 0.5), 0.0, 1.0, Vector3.ZERO, 0.85)
		kit._piece("play_springer", body, Vector3(1.5, 0, half.y * 0.5), 90.0, 1.0)
		kit._piece("play_springer", body, Vector3(3.5, 0, half.y * 0.5), 90.0, 1.0)
	return body


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.25
		var camera := get_viewport().get_camera_3d()
		var gap := global_position.distance_to(camera.global_position) if camera != null else 0.0
		_near = gap < GameConfig.PEOPLE_ANIMATE_DISTANCE * 1.5
		var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
		for kid in kids:
			PlaceCrowds.apply_detail(kid, gap, far)
	if not _near:
		return
	_clock += delta
	for part: Array in parts:
		var node: Node3D = part[0]
		var t: float = _clock + part[2]
		match part[1]:
			"swing":
				node.rotation.x = sin(t * 1.9) * 0.45
			"spin":
				node.rotation.y = t * 0.9
			"rock":
				node.rotation.z = sin(t * 3.1) * 0.12
				node.rotation.x = sin(t * 2.3) * 0.06


## Puts one Blender piece at `at` (on the floor), turned `facing` degrees, scaled `grow`.
## solid: a solid box (size) round its middle, or a solid round post of radius `round`.
func _piece(file: String, body: StaticBody3D, at: Vector3, facing: float, grow: float,
		solid := Vector3.ZERO, round := 0.0) -> Node3D:
	if not _scenes.has(file):
		_scenes[file] = load("res://assets/models/%s.glb" % file)
	var piece := (_scenes[file] as PackedScene).instantiate() as Node3D
	piece.name = file.capitalize().replace(" ", "")
	piece.position = at + Vector3(0, 0.07, 0)  # stands on the rubber floor
	piece.rotation_degrees.y = facing
	piece.scale = Vector3.ONE * grow
	body.add_child(piece)
	for view: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
		view.visibility_range_end = PIECE_VIEW
		view.material_override = paint_material()
	if solid != Vector3.ZERO:
		LowPoly.solid_box(body, solid, at + Vector3(0, solid.y * 0.5, 0))
	elif round > 0.0:
		LowPoly.solid_cylinder(body, round, 0.6 if file == "play_spinner" else 1.4, at + Vector3(0, 0.3 if file == "play_spinner" else 0.7, 0))
	var phase := randf() * TAU
	match file:
		"play_swings":
			for i in 2:
				var seat := piece.find_child("Seat_%d" % i, true, false) as Node3D
				if seat == null:
					continue
				parts.append([seat, "swing", phase + i * 1.3])
				if i == 0:
					_sit_kid(seat, Vector3(0, 0.58 - 2.2, 0), 0.0)
		"play_spinner":
			var spin := piece.find_child("Spin", true, false) as Node3D
			if spin != null:
				parts.append([spin, "spin", phase])
				var kid := _add_kid(spin, Vector3(0.45, 0.32 - spin.position.y, 0.0), 90.0)
				kid.play("idle")
		"play_springer":
			var rocker := piece.find_child("Rider", true, false) as Node3D
			if rocker != null:
				parts.append([rocker, "rock", phase])
				if kids.size() < 3:
					_sit_kid(rocker, Vector3(-0.2, 0.79 - rocker.position.y, 0), -90.0)
	return piece


## A kid sitting on a seat (its top at `seat` on `node`), facing `facing` degrees.
func _sit_kid(node: Node3D, seat: Vector3, facing: float) -> void:
	var kid := _add_kid(node, seat, facing)
	kid.play("sit")
	kid.position.y = KID_SEAT - kid.spot("Hips").y


func _add_kid(node: Node3D, at: Vector3, facing: float) -> Person:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = facing
	node.add_child(holder)
	var kid := LifeLooks.kid()
	kid.set_meta("outfit", "kid at play")
	holder.add_child(kid)
	kids.append(kid)
	return kid


## A flat slab with rounded corners (just to look at), its top `height` above the ground.
func _rounded_slab(size: Vector2, corner: float, height: float, material: Material, colour: Color) -> void:
	var outline := PackedVector2Array()
	var half := size * 0.5
	corner = minf(corner, minf(half.x, half.y))
	var centres := [Vector2(half.x - corner, half.y - corner), Vector2(-half.x + corner, half.y - corner),
			Vector2(-half.x + corner, -half.y + corner), Vector2(half.x - corner, -half.y + corner)]
	for c in 4:
		for step in 7:
			var a := (c + step / 6.0) * PI * 0.5
			outline.append(centres[c] + Vector2(cos(a), sin(a)) * corner)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := outline.size()
	for i in count:
		var a := outline[i]
		var b := outline[(i + 1) % count]
		# The top (a fan from the middle) and the edge band down to the ground.
		# (Godot draws the side whose corners go round clockwise.)
		tool.set_normal(Vector3.UP)
		tool.add_vertex(Vector3(0, height, 0))
		tool.add_vertex(Vector3(a.x, height, a.y))
		tool.add_vertex(Vector3(b.x, height, b.y))
		var out := Vector3(a.x + b.x, 0, a.y + b.y).normalized()
		tool.set_normal(out)
		tool.add_vertex(Vector3(a.x, height, a.y))
		tool.add_vertex(Vector3(b.x, 0, b.y))
		tool.add_vertex(Vector3(b.x, height, b.y))
		tool.add_vertex(Vector3(a.x, height, a.y))
		tool.add_vertex(Vector3(a.x, 0, a.y))
		tool.add_vertex(Vector3(b.x, 0, b.y))
	var view := MeshInstance3D.new()
	view.name = "PlayFloor" if material != null else "PlayKerb"
	view.mesh = tool.commit()
	view.material_override = material if material != null else LowPoly.material(colour)
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(view)
