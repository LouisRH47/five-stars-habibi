class_name ArenaHorse
extends RouteMover
## A scenic horse on the arena's fixed course. Its visible arc clears each jump.

var jumps: Array[Vector3] = []
var jump_height := 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	jump_height = 0.0
	for jump in jumps:
		var distance := Vector2(position.x - jump.x, position.z - jump.z).length()
		if distance < GameConfig.ARENA_JUMP_REACH:
			jump_height = maxf(jump_height, cos(distance / GameConfig.ARENA_JUMP_REACH * PI * 0.5) * GameConfig.ARENA_JUMP_HEIGHT)
	model.position.y += jump_height
	model.rotation.x = sin(jump_height / GameConfig.ARENA_JUMP_HEIGHT * PI) * -0.22 if jump_height > 0.0 else 0.0
