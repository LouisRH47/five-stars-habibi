extends StaticBody3D
## One parked car (Session 29: a real low-poly car from Kenney's free CC0 Car Kit,
## assets/cars/, see CREDITS.md). It's solid (one box, the same size as before), so the
## bike bumps into it. The nose is the +Z side (like the front of a villa), so "facing"
## in the data list is the way the car points.
## DecorBuilder places one of these (scenes/parked_car.tscn) for every car in the
## data list and calls setup().
## Session 79: the car parks hold about 300 cars, so the car's look is drawn by a
## ParkedCarBatch (one MultiMesh per model) instead of a copy of the model per car. The
## solid box stays on each car. GameConfig.PARKED_CARS_BATCHED switches this off.

## The cars to pick from, by the car's number so neighbours differ. No logos on them.
const MODELS := [
	preload("res://assets/cars/kenney_car_kit/sedan.glb"),
	preload("res://assets/cars/kenney_car_kit/suv.glb"),
	preload("res://assets/cars/kenney_car_kit/hatchback-sports.glb"),
	preload("res://assets/cars/kenney_car_kit/suv-luxury.glb"),
	preload("res://assets/cars/kenney_car_kit/van.glb"),
]
## The Kenney cars point their nose this way (turned so it matches our +Z).
const MODEL_TURN := 0.0


var _size := Vector3.ONE
var _model := 0
var _batched := false


## Builds the car. size: width, height, length in metres (from the data list).
## colour_index: picks the car model.
func setup(size: Vector3, colour_index: int) -> void:
	# One solid box for the whole car.
	LowPoly.solid_box(self, size, Vector3(0, size.y * 0.5, 0))
	_size = size
	_model = colour_index % MODELS.size()
	if GameConfig.PARKED_CARS_BATCHED:
		_batched = true
		var marker := Node3D.new()  # the look is in the batch; this marks which model it is
		marker.name = "Model"
		marker.set_meta("batched_model", MODELS[_model].resource_path)
		add_child(marker)
		return
	var car: Node3D = MODELS[colour_index % MODELS.size()].instantiate()
	car.name = "Model"
	car.rotation.y = MODEL_TURN
	add_child(car)
	# Scale the model so it is as long as the solid box, and stands on the ground.
	var box := _bounds(car)
	if box.size.z > 0.01:
		car.scale = Vector3.ONE * size.z / box.size.z
		car.position.y = -box.position.y * car.scale.y


func _ready() -> void:
	if _batched:  # placed now: hand the car's look to the batch next to it
		ParkedCarBatch.for_parent(get_parent()).add(MODELS[_model], transform, _size)


## The box around every mesh in the model (in the model's own space, before scaling).
static func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var spot := Transform3D()
		var node: Node = mesh
		while node != model:
			spot = (node as Node3D).transform * spot
			node = node.get_parent()
		var part := spot * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box
