class_name Face
## Session 83: simple eyes (a white with a dark pupil) and a smile on every person's face.
## The face is one small mesh that follows the head bone (Person.follow), shared by
## everyone with the same head size, and it is only drawn when you're close
## (FACE_SHOW_DISTANCE), so hundreds of people stay cheap.

const WHITE := Color(0.97, 0.97, 0.95)
const PUPIL := Color(0.08, 0.06, 0.05)
const MOUTH := Color(0.42, 0.14, 0.12)
## The head the numbers below were measured on (a grown-up, Person.new()).
const GROWN_UP_HEAD := 0.293

static var _meshes := {}  # one face mesh per head size


## Puts eyes and a smile on `person`. Returns the holder that follows the head.
static func add(person: Person) -> Node3D:
	var head := person.follow("Head")
	head.name = "Face"
	var view := MeshInstance3D.new()
	view.name = "Eyes"
	var size := PeopleLooks.head_size(person)
	var key := snappedf(size, 0.005)
	if not _meshes.has(key):
		_meshes[key] = _make(size / GROWN_UP_HEAD)
	view.mesh = _meshes[key]
	view.material_override = MeshKit.material()
	view.position = person.head_spot()
	view.visibility_range_end = GameConfig.FACE_SHOW_DISTANCE
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	head.add_child(view)
	return head


## The face mesh for a head `scale` times a grown-up's, around the middle of the head.
static func _make(scale: float) -> Mesh:
	var kit := MeshKit.new()
	var front: float = -GameConfig.FACE_FRONT * scale
	var eye_y: float = GameConfig.FACE_EYE_HEIGHT * scale
	for side in [-1.0, 1.0]:
		var eye := Vector3(side * GameConfig.FACE_EYE_GAP * 0.5, eye_y, front) * Vector3(scale, 1, 1)
		kit.box(Vector3(0.03, 0.026, 0.008) * scale, WHITE, eye)
		kit.box(Vector3(0.016, 0.022, 0.008) * scale, PUPIL, eye + Vector3(0, -0.002, -0.004) * scale)
	# The smile: a flat middle and two corners turned up.
	var mouth := Vector3(0, GameConfig.FACE_MOUTH_HEIGHT * scale, front + 0.004 * scale)
	kit.box(Vector3(0.036, 0.011, 0.01) * scale, MOUTH, mouth)
	for side in [-1.0, 1.0]:
		kit.box(Vector3(0.024, 0.011, 0.01) * scale, MOUTH, mouth + Vector3(side * 0.026, 0.007, 0.002) * scale,
				Basis(Vector3.BACK, side * 0.55))
	var view := kit.finish()
	var mesh := view.mesh
	view.free()
	return mesh
