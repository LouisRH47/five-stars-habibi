class_name ArenaHorse
extends RouteMover
## A scenic horse on the arena's fixed course. Its visible arc clears each jump.
## Session 73: riders take turns (scripts/stable_life.gd). The route starts at the rider's
## waiting spot (point 0); when it gets back there after a round, it waits (holding = true)
## until StableLife sends it off again.

var jumps: Array[Vector3] = []
var jump_height := 0.0
## True while it stands at its waiting spot.
var holding := false
## Stop at the waiting spot after each round (StableLife's riders do).
var takes_turns := false
## Rounds of the course finished.
var rounds := 0


func _physics_process(delta: float) -> void:
	if holding:
		_clock += delta
		moving = false
		# Stand facing the course (north, -Z) while waiting.
		rotation.y = lerp_angle(rotation.y, 0.0, minf(1.0, delta * 2.0))
		if model.visible:
			LifeLooks.animate(self, delta, _clock)
	else:
		var heading_for := _next
		super._physics_process(delta)
		if takes_turns and heading_for == 0 and _next != 0:
			holding = true  # back at the waiting spot
			rounds += 1
	if not model.visible:
		model.position.y = 0.0  # (LifeLooks only sets the bob while it's drawn)
	jump_height = 0.0
	for jump in jumps:
		var distance := Vector2(position.x - jump.x, position.z - jump.z).length()
		if distance < GameConfig.ARENA_JUMP_REACH:
			jump_height = maxf(jump_height, cos(distance / GameConfig.ARENA_JUMP_REACH * PI * 0.5) * GameConfig.ARENA_JUMP_HEIGHT)
	model.position.y += jump_height
	model.rotation.x = sin(jump_height / GameConfig.ARENA_JUMP_HEIGHT * PI) * -0.22 if jump_height > 0.0 else 0.0


## Sends it off on its round (from its waiting spot).
func go() -> void:
	holding = false

