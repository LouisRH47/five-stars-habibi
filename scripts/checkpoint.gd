extends Node3D
## Scenery checkpoint: cars raise the boom, cyclists have a permanent side gap.
var _barrier: StaticBody3D
var _boom: Node3D
var _guard: Person
var _raised := false
var _wave_left := 0.0

func _ready() -> void:
	var booth := StaticBody3D.new()
	booth.position = Vector3(-8, 0, 0)
	add_child(booth)
	LowPoly.box(booth, Vector3(3, 3, 3), Color(0.95, 0.9, 0.8), Vector3(0, 1.5, 0))
	LowPoly.box(booth, Vector3(3.2, 0.2, 3.2), Color.TEAL, Vector3(0, 3.1, 0))
	LowPoly.solid_box(booth, Vector3(3, 3, 3), Vector3(0, 1.5, 0))
	LowPoly.box(booth, Vector3(2, 1.1, 0.1), Color(0.3, 0.55, 0.66), Vector3(0, 1.9, 1.55))
	_barrier = StaticBody3D.new()
	_barrier.name = "Barrier"
	add_child(_barrier)
	_boom = Node3D.new()
	_boom.position = Vector3(-3.5, 1.1, 0)
	_barrier.add_child(_boom)
	for i in 14:
		LowPoly.box(_boom, Vector3(0.5, 0.18, 0.2), Color.RED if i % 2 == 0 else Color.WHITE, Vector3(i * 0.5 + 0.25, 0, 0))
	LowPoly.solid_box(_barrier, Vector3(7, 1.2, 0.25), Vector3(0, 1.1, 0))
	_guard = PeopleLooks.resident(2, 2)
	_guard.position = Vector3(-5.4, 0, 1)
	_guard.rotation.y = PI
	add_child(_guard)
	set_meta("bike_gap", 1.5)


func _process(delta: float) -> void:
	var car_near := false
	for vehicle: Node3D in get_tree().get_nodes_in_group("traffic_vehicle"):
		if global_position.distance_to(vehicle.global_position) < 14:
			car_near = true
	if car_near != _raised:
		_raised = car_near
		for shape: CollisionShape3D in _barrier.find_children("*", "CollisionShape3D", true, false):
			shape.set_deferred("disabled", _raised)
	_boom.rotation.z = move_toward(_boom.rotation.z, -PI * 0.46 if _raised else 0.0, delta * 2.0)
	_wave_left -= delta
	for bike: Node3D in get_tree().get_nodes_in_group("bike"):
		if _wave_left <= 0 and global_position.distance_to(bike.global_position) < 20:
			_guard.play("wave")
			_wave_left = 6.0
	if _wave_left < 3 and _guard.action == "wave":
		_guard.play("idle")
