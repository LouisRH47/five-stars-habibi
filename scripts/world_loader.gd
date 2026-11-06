class_name WorldLoader
extends Node
## Session 86: builds the world behind the loading screen a few steps per frame, so the game
## never freezes and you never see a half-built map.
##
## How it works: the map scene is read from disk on a background thread, then made, then its
## parts (WahatBuilder, PlazaBuilder, PlaceBuilder, the bike, the HUD...) are put into the game
## one after the other, in the same order as in the scene. A big builder lists its work as
## named steps (its build_steps() function: [["Laying the roads", callable], ...]) and the
## loader runs as many steps as fit in GameConfig.LOADING_FRAME_BUDGET_MS, then lets the
## screen draw a frame. Work a builder normally does "at the end of the frame" (its
## finish_steps()) runs after every part is in. Then the finished world draws a few frames
## hidden behind the screen (so its shaders are ready), the game starts and the screen fades.
##
## Built any other way (the tests, the editor) the builders run all their steps at once in
## _ready, exactly as before. Builders ask WorldLoader.is_staged(self) to know which.

## The world is ready, the screen has faded away and the game is running.
signal finished(world: Node)

const STAGED_META := "staged_build"

## Friendly names for the plain parts of the scene (the rest show "Getting things ready...").
const PART_NAMES := {
	"WorldEnvironment": "Lighting the sky...", "SpineBuilder": "Planting the green spine...",
	"LandmarkBuilder": "Building the mosque and the school...", "DecorBuilder": "Parking the cars...",
	"DistrictTraffic": "Starting the traffic...", "Bike": "Pumping up the tyres...",
	"HUD": "Charging your phone...", "LifeBuilder": "Waking up the neighbours...",
	"ObstacleBuilder": "Letting the cats out...", "EventManager": "Checking today's news...",
}

var scene_path := ""
var replace_current := true
var screen: LoadingScreen
var world: Node
## Every step's name in the order it ran (the tests read it).
var done_names: Array[String] = []
var total_steps := 0
## The longest gap between two frames while building, in ms (the tests read it).
var longest_frame_ms := 0
## How long each step took, in ms (the tests print the slowest).
var step_ms: Dictionary = {}
var _step_started := 0
var _frame_start := 0


## Starts loading the scene at `path` behind a new loading screen. Normally the current scene
## (the start screen) is freed first; tests pass replace_current = false to keep theirs.
static func open(tree: SceneTree, path: String, replace_current_scene := true) -> WorldLoader:
	var loader := WorldLoader.new()
	loader.name = "WorldLoader"
	loader.scene_path = path
	loader.replace_current = replace_current_scene
	loader.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(loader)
	loader._run.call_deferred()
	return loader


## True while the loader is building `builder` (it then only lists its steps in _ready).
static func is_staged(builder: Node) -> bool:
	var parent := builder.get_parent()
	return parent != null and parent.has_meta(STAGED_META)


## Runs a list of steps straight away (the normal build).
static func run_steps(steps: Array) -> void:
	for step: Array in steps:
		step[1].call()


func _run() -> void:
	var tree := get_tree()
	screen = LoadingScreen.make()
	tree.root.add_child(screen)
	if replace_current and tree.current_scene != null:
		tree.current_scene.queue_free()
	screen.set_progress(0, 1, "Unpacking the map...")
	ResourceLoader.load_threaded_request(scene_path)
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await tree.process_frame
	var packed := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if packed == null:
		push_error("WorldLoader could not load " + scene_path)
		screen.queue_free()
		queue_free()
		return
	_frame_start = Time.get_ticks_msec()
	world = packed.instantiate()
	world.set_meta(STAGED_META, true)
	# Plan every step first, so the screen can say "step X of N".
	var parts := world.get_children()
	var plan: Array = []
	total_steps = 1
	for part in parts:
		world.remove_child(part)
		var steps: Array = part.build_steps() if part.has_method("build_steps") else []
		var finish: Array = part.finish_steps() if part.has_method("finish_steps") else []
		plan.append([part, steps, finish])
		total_steps += maxi(1, steps.size()) + finish.size()
	_tick("Unrolling the desert...")
	tree.paused = true  # nothing moves (and the shift clock waits) until the world is ready
	tree.root.add_child(world)
	if replace_current:
		tree.current_scene = world
	tree.root.move_child(self, -1)  # the loader sees key presses first, so Esc waits too
	var last_was_plain := false
	for entry: Array in plan:
		var part: Node = entry[0]
		var steps: Array = entry[1]
		# A run of plain parts goes in together: their "end of frame" work then sees all of them,
		# as in a normal build.
		if steps.is_empty() and last_was_plain:
			_add(part)
			_tick(PART_NAMES.get(String(part.name), "Getting things ready..."))
			continue
		await _breathe()
		_add(part)
		last_was_plain = steps.is_empty()
		if last_was_plain:
			_tick(PART_NAMES.get(String(part.name), "Getting things ready..."))
		for step: Array in steps:
			await _breathe()
			step[1].call()
			_tick(step[0])
	for entry: Array in plan:
		for step: Array in entry[2]:
			await _breathe()
			await step[1].call()
			_tick(step[0])
	# Let the finished world draw a few frames behind the screen, so its shaders are compiled
	# before you see it (no stutter on the first look round).
	for i in GameConfig.LOADING_WARM_FRAMES:
		await _next_frame()
	world.remove_meta(STAGED_META)
	await screen.finish()
	tree.paused = false  # the clock starts once you can see the world
	finished.emit(world)
	queue_free()


func _input(_event: InputEvent) -> void:
	# While loading, keys and clicks don't reach the half-built game (Esc can't open the menu).
	get_viewport().set_input_as_handled()


func _add(part: Node) -> void:
	# Taken out and put back by hand, so its owner is set again afterwards (no warning).
	var owner_was := part.owner
	part.owner = null
	world.add_child(part)
	part.owner = owner_was


func _tick(step_name: String) -> void:
	var now := Time.get_ticks_msec()
	step_ms[step_name] = step_ms.get(step_name, 0) + now - maxi(_step_started, _frame_start)
	_step_started = now
	done_names.append(step_name)
	screen.set_progress(done_names.size(), total_steps, step_name)


## Lets the screen draw if this frame has used up its building time.
func _breathe() -> void:
	if Time.get_ticks_msec() - _frame_start >= GameConfig.LOADING_FRAME_BUDGET_MS:
		await _next_frame()


func _next_frame() -> void:
	longest_frame_ms = maxi(longest_frame_ms, Time.get_ticks_msec() - _frame_start)
	await get_tree().process_frame
	_frame_start = Time.get_ticks_msec()
