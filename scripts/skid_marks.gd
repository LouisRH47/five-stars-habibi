extends Node3D
## Session 61: faint, short skid marks from the back tyre, only after a hard brake.
## A mark is a thin dark strip on the ground along where the back wheel went for about
## half a second. It stays a few seconds, then fades out and is removed. At most a few
## marks exist at once. The bike adds this in its _ready(); numbers in game_config.gd.

const BACK_WHEEL := Vector3(0, 0, 0.62)   # where the back tyre touches, in the bike's space
const COLOUR := Color(0.07, 0.07, 0.07)

## The marks on the ground now: {view, points, age, material}.
var marks: Array = []

var _bike: Node3D
var _drawing_left := 0.0
var _current: Dictionary = {}


func _ready() -> void:
	top_level = true  # marks stay where they were made
	global_transform = Transform3D.IDENTITY
	_bike = get_parent()
	if _bike.has_signal("hard_braked"):
		_bike.hard_braked.connect(start_mark)


## A new mark starts at the back wheel (called when the rider brakes hard).
func start_mark() -> void:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(COLOUR, GameConfig.SKID_MARK_ALPHA)
	mat.roughness = 1.0
	var view := MeshInstance3D.new()
	view.name = "SkidMark"
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.material_override = mat
	add_child(view)
	_current = {"view": view, "points": [], "age": 0.0, "material": mat}
	marks.append(_current)
	while marks.size() > GameConfig.SKID_MARK_MAX:
		marks.pop_front()["view"].queue_free()
	_drawing_left = GameConfig.SKID_MARK_TIME
	add_point(_wheel_spot())


func _physics_process(delta: float) -> void:
	for mark: Dictionary in marks.duplicate():
		mark["age"] += delta
		var fade := clampf((mark["age"] - GameConfig.SKID_MARK_HOLD) / GameConfig.SKID_MARK_FADE, 0.0, 1.0)
		mark["material"].albedo_color.a = GameConfig.SKID_MARK_ALPHA * (1.0 - fade)
		if fade >= 1.0:
			mark["view"].queue_free()
			marks.erase(mark)
			if mark == _current:
				_current = {}
				_drawing_left = 0.0
	if _drawing_left <= 0.0 or _current.is_empty():
		return
	_drawing_left -= delta
	if absf(float(_bike.get("speed"))) < 1.0 or _bike.get("fallen_left") > 0.0:
		_drawing_left = 0.0
		return
	add_point(_wheel_spot())


## Adds a point to the newest mark (skips points too close together) and redraws it.
func add_point(spot: Vector3) -> void:
	if _current.is_empty():
		return
	var points: Array = _current["points"]
	if not points.is_empty() and (points.back() as Vector3).distance_to(spot) < 0.2:
		return
	points.append(spot)
	if points.size() < 2:
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in points.size() - 1:
		var a: Vector3 = points[k]
		var b: Vector3 = points[k + 1]
		var side := (b - a).cross(Vector3.UP).normalized() * GameConfig.SKID_MARK_WIDTH * 0.5
		for v in [a + side, a - side, b + side, b + side, a - side, b - side]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(v)
	_current["view"].mesh = tool.commit()


## The ground right under the back wheel, plus a hair so the mark sits on top.
func _wheel_spot() -> Vector3:
	var spot := _bike.global_transform * BACK_WHEEL
	if is_inside_tree():
		var ray := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 0.8, spot + Vector3.DOWN * 1.0)
		if _bike is CollisionObject3D:
			ray.exclude = [(_bike as CollisionObject3D).get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			spot.y = hit["position"].y
	# Roads are flat meshes 5 cm above the ground (no collision), so lift onto them.
	spot.y = maxf(spot.y, 0.0) + RoadMesh.ASPHALT_TOP + 0.012
	return spot
