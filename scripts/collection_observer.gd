extends Node
## Meeting a named animal means coming close to it, without needing to collide.
var delivery_manager: DeliveryManager
var _left := 0.0


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left > 0.0 or delivery_manager == null:
		return
	_left = 0.5
	var actor := delivery_manager.actor
	if actor == null:
		return
	for animal in get_tree().get_nodes_in_group("critter"):
		var id := str(animal.get_meta("collection_id", ""))
		if id != "" and animal is Node3D and actor.global_position.distance_to(animal.global_position) <= GameConfig.ANIMAL_MEET_DISTANCE:
			GameState.note_animal_met(id, str(animal.get_meta("collection_name", id)))
