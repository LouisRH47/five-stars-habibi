class_name Critter
extends AnimatableBody3D
## The shared part of everything that moves around Palm Grove by itself (cats, kids on
## scooters). It's solid, so the bike bumps into it. A slightly bigger invisible area
## notices when the bike touches it: then it tells the meters (food damage) and gets
## scared for a moment (scripts/cat.gd runs off, scripts/scooter_kid.gd stops).
## Scripts that extend this one move the body in _physics_process.

## Sent when the bike bumps into this one.
signal hit_by_bike

## Seconds left of being scared after a bump (0 = calm).
var scared_left := 0.0


func _init() -> void:
	# We move it ourselves by setting position each frame, so don't let physics overwrite it.
	sync_to_physics = false


## True while the bike is touching us (kids wait instead of pushing it along).
func bike_in_the_way() -> bool:
	var touch := get_node_or_null("Touch") as Area3D
	if touch == null:
		return false
	for body in touch.get_overlapping_bodies():
		if body.is_in_group("bike"):
			return true
	return false


## Adds the solid box and the slightly bigger "touch" area. size: width, height, length.
func make_body(size: Vector3) -> void:
	LowPoly.solid_box(self, size, Vector3(0, size.y * 0.5, 0))
	var touch := Area3D.new()
	touch.name = "Touch"
	var shape := BoxShape3D.new()
	shape.size = size + Vector3(0.5, 0.2, 0.5)
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.position.y = size.y * 0.5
	touch.add_child(holder)
	add_child(touch)
	touch.body_entered.connect(_on_touched)


## The bike touched us: knock the food (only once until we've calmed down), get scared.
func bumped_by(body: Node3D) -> void:
	if scared_left > 0.0:
		return
	scared_left = GameConfig.CRITTER_SCARED_TIME
	get_tree().call_group("meters", "hurt_food_critter")
	hit_by_bike.emit()
	_on_scared(body)


## Turns the body to face along a direction on the ground.
func face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)


## Overridden by cats and kids: what to do when bumped.
func _on_scared(_bike: Node3D) -> void:
	pass


func _on_touched(body: Node3D) -> void:
	if body.is_in_group("bike"):
		bumped_by(body)
