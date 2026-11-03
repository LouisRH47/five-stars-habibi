class_name VenueMotion
extends Node
## Small kitchen motions stop with ordinary gameplay and need no physics bodies.
var spit: Node3D
var plates: Array[Node3D] = []

func _process(delta: float) -> void:
	if spit != null:
		spit.rotate_y(delta * 0.7)
	for plate in plates:
		plate.position.x += delta * 0.45
		if plate.position.x > 3.7:
			plate.position.x = -0.6
