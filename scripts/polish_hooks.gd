extends Node
## Session 66: lets each polish session add its extras to the game world without editing the
## same files. When the world scene opens (in the game or in a test), every file in PARTS that
## exists is loaded and its `static func attach(world: Node) -> void` is called once.
## The names are fixed here so parallel sessions never edit this list.

const WORLD_SCENE := "res://scenes/wahat_al_shams.tscn"
const PARTS := [
	"res://scripts/polish/look_extras.gd",   # Session 67
	"res://scripts/polish/world_extras.gd",  # Session 68
	"res://scripts/polish/hud_extras.gd",    # Session 69
	"res://scripts/polish/phone_extras.gd",  # Session 70
	"res://scripts/polish/screen_extras.gd", # Session 71
]

## Which parts ran for the last world (tests read it).
var attached: Array[String] = []
## The last world the parts were attached to (tests read it).
var last_world: Node = null
## The list used when a world opens. Always PARTS in the game; a test may swap in its own list.
var parts: Array = PARTS


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	# A test script can add the world before this autoload is ready: catch that one too.
	for node in get_tree().root.get_children():
		_on_node_added(node)


func _on_node_added(node: Node) -> void:
	if node.scene_file_path == WORLD_SCENE:
		_attach.call_deferred(node)


func _attach(world: Node) -> void:
	if not is_instance_valid(world) or not world.is_inside_tree():
		return
	if world.has_meta("polish_hooks_done"):
		return  # once per world, even if it's moved in the tree
	world.set_meta("polish_hooks_done", true)
	attached.clear()
	last_world = world
	if not GameConfig.POLISH_HOOKS_ON:
		return
	attach_parts(world, parts)


## Calls attach(world) on each script in paths that exists. Also used by tests (for example on
## the flat test area, or with a test part) so they don't need the whole map.
func attach_parts(world: Node, paths: Array) -> void:
	for path: String in paths:
		if not ResourceLoader.exists(path):
			continue
		var part: Script = load(path)
		if part == null:
			continue
		part.call("attach", world)  # the part's static func attach(world)
		attached.append(path)
