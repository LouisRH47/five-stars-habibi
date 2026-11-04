class_name CarParkCars
extends Node3D
## Session 62: how the parked cars in the car parks look. There are about 400 of them, so
## instead of 400 separate car models (thousands of draw calls) every car park draws all its
## cars of one kind in one go (a MultiMesh). Each car gets its own paint colour: the shader
## swaps the Kenney paint colour for the car's colour and keeps windows, lights and wheels.
## The solid part of each car (what the bike bumps into) is still its own ParkedCar_<n>
## body from DecorBuilder. GameConfig.CARPARK_CAR_BATCH = false goes back to one model per car.

const CAR_MODEL := preload("res://scripts/parked_car.gd")
const PAINT_SHADER := preload("res://assets/shaders/car_paint.gdshader")
const ATLAS := "res://assets/cars/kenney_car_kit/Textures/colormap.png"

## Cars drawn (for the tests).
var drawn := 0
static var _meshes: Dictionary = {}


## cars: the PARKED_CARS list; size: PARKED_CAR_SIZE (the car's length is size.z).
func build(cars: Array, size: Vector3) -> void:
	var groups := {}
	for car: Dictionary in cars:
		if not car.has("park"):
			continue
		var key := Vector2i(int(car["park"]), int(car.get("model", 0)))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(car)
	for key: Vector2i in groups:
		var list: Array = groups[key]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_custom_data = true
		multi.mesh = car_mesh(key.y, size)
		multi.instance_count = list.size()
		for i in list.size():
			var car: Dictionary = list[i]
			var turn := Basis(Vector3.UP, deg_to_rad(float(car["facing"])))
			multi.set_instance_transform(i, Transform3D(turn, car["position"]))
			multi.set_instance_custom_data(i, car.get("paint", Color.WHITE))
		var view := MultiMeshInstance3D.new()
		view.name = "Cars_%d_%d" % [key.x, key.y]
		view.multimesh = multi
		view.visibility_range_end = GameConfig.CARPARK_CAR_VIEW_RANGE
		view.visibility_range_end_margin = 20.0
		view.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(view)
		drawn += list.size()


## One Kenney car as a single mesh: surface 0 the body (painted by the shader), surface 1 the
## wheels. Scaled so it's as long as the parked car's solid box, standing on the ground.
static func car_mesh(model: int, size: Vector3) -> ArrayMesh:
	var key := "%d_%.2f" % [model, size.z]
	if _meshes.has(key):
		return _meshes[key]
	var scene: Node3D = CAR_MODEL.MODELS[model % CAR_MODEL.MODELS.size()].instantiate()
	var box := CAR_MODEL._bounds(scene)
	var scale := size.z / box.size.z if box.size.z > 0.01 else 1.0
	var root := Transform3D(Basis().scaled(Vector3.ONE * scale), Vector3(0, -box.position.y * scale, 0))
	var body := SurfaceTool.new()
	var wheels := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	wheels.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wheel_material: Material = null
	var body_mesh: Mesh = null
	for part: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var spot := Transform3D()
		var node: Node = part
		while node != scene:
			spot = (node as Node3D).transform * spot
			node = node.get_parent()
		var tool := body if String(part.name) == "body" else wheels
		for s in part.mesh.get_surface_count():
			tool.append_from(part.mesh, s, root * spot)
		if String(part.name) == "body":
			body_mesh = part.mesh
		else:
			wheel_material = part.mesh.surface_get_material(0)
	var mesh := body.commit()
	wheels.commit(mesh)
	var paint := ShaderMaterial.new()
	paint.shader = PAINT_SHADER
	var atlas: Texture2D = load(ATLAS)
	paint.set_shader_parameter("atlas", atlas)
	var cell := paint_cell(body_mesh, atlas)
	paint.set_shader_parameter("paint_rect", Vector4(cell.position.x, cell.position.y, cell.end.x, cell.end.y))
	paint.set_shader_parameter("paint_light", cell_light(atlas, cell))
	mesh.surface_set_material(0, paint)
	if mesh.get_surface_count() > 1:
		mesh.surface_set_material(1, wheel_material)
	scene.free()
	_meshes[key] = mesh
	return mesh


## The part of the colour atlas the car's paint comes from: the colour strip (32 x 128 pixels)
## that covers the most of the body, not counting the grey ones (tyres, bumpers, underside).
static func paint_cell(mesh: Mesh, atlas: Texture2D) -> Rect2:
	var area := {}
	if mesh == null:
		return Rect2()
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if index.is_empty():
		for i in points.size():
			index.append(i)
	for t in range(0, index.size() - 2, 3):
		var a := points[index[t]]
		var b := points[index[t + 1]]
		var c := points[index[t + 2]]
		var uv := (uvs[index[t]] + uvs[index[t + 1]] + uvs[index[t + 2]]) / 3.0
		var key := Vector2i(floori(uv.x * 16.0), floori(uv.y * 4.0))
		area[key] = area.get(key, 0.0) + (b - a).cross(c - a).length() * 0.5
	var keys := area.keys()
	keys.sort_custom(func(x: Vector2i, y: Vector2i): return area[x] > area[y])
	var image := _image(atlas)
	for key: Vector2i in keys:
		var cell := Rect2(key.x / 16.0, key.y / 4.0, 1.0 / 16.0, 1.0 / 4.0)
		if image == null:
			return cell
		var colour := image.get_pixelv(Vector2i(cell.get_center() * Vector2(image.get_size())))
		if colour.s > 0.3:
			return cell
	return Rect2(keys[0].x / 16.0, keys[0].y / 4.0, 1.0 / 16.0, 1.0 / 4.0) if not keys.is_empty() else Rect2()


static func _image(atlas: Texture2D) -> Image:
	var image := atlas.get_image() if atlas != null else null
	if image != null and image.is_compressed():
		image.decompress()
	return image


## How light the paint cell is on average (the shader keeps the cell's shading round it).
static func cell_light(atlas: Texture2D, cell: Rect2) -> float:
	var image := _image(atlas)
	if image == null or cell.size == Vector2.ZERO:
		return 0.6
	var total := 0.0
	var count := 0
	var size := Vector2(image.get_width(), image.get_height())
	for i in 8:
		for j in 8:
			var p := (cell.position + cell.size * Vector2((i + 0.5) / 8.0, (j + 0.5) / 8.0)) * size
			var c := image.get_pixelv(Vector2i(p))
			total += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			count += 1
	return maxf(total / count, 0.05)
