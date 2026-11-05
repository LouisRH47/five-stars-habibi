class_name WaterLook
extends Node
## Session 68 (W2): gives each water its shape so the new water shader
## (assets/shaders/water.gdshader) knows where the edges are, for the foam:
##   - the stream: its wiggly middle line and width, from STREAM in the map data
##   - the fountain's basin and bowl: their own copy of the water (kind 2) with the radius
##   - the pools (scripts/pool.gd already says kind 1): half the water's size
## Pool light patterns (caustics) are off on Graphics Low. With GameConfig.WATER_V2 off, all
## of them go back to the old water (assets/shaders/water_v1.gdshader).
## world_extras.gd adds this to the world.

const NEW_WATER := preload("res://assets/shaders/water.gdshader")
const OLD_WATER := preload("res://assets/shaders/water_v1.gdshader")

## Every water material it looked after (tests read them).
var materials: Array[ShaderMaterial] = []


static func attach(world: Node) -> WaterLook:
	var look := WaterLook.new()
	look.name = "WaterLook"
	world.add_child(look)
	look.dress(world)
	return look


func _ready() -> void:
	add_to_group("graphics")   # Settings.apply() calls apply_graphics() on this group


func dress(world: Node) -> void:
	var stream := world.get_node_or_null("WahatBuilder/Stream")
	var fountain := world.get_node_or_null("PlazaBuilder/Fountain")
	var map := _map(world)
	if fountain != null:
		for part in ["Water", "BowlWater"]:
			var dish := fountain.get_node_or_null(part) as MeshInstance3D
			if dish != null and dish.material_override is ShaderMaterial:
				dish.material_override = _fountain_water(dish)
	if stream != null and map.has("STREAM"):
		for piece in stream.get_children():
			if piece is MeshInstance3D and piece.material_override is ShaderMaterial:
				_stream_water(piece.material_override, map["STREAM"])
	var detail := world.get_node_or_null("DistrictDetail")
	var pools: Array = detail.pools if detail != null and "pools" in detail else world.find_children("*", "Pool", true, false)
	for pool: Node in pools:
		for id in ["PoolWater", "KidsWater"]:
			var water := pool.get_node_or_null(id) as MeshInstance3D
			if water != null and water.material_override is ShaderMaterial and water.mesh is BoxMesh:
				_pool_water(water)
	apply_graphics()


## Graphics Low: no light patterns in the pools.
func apply_graphics() -> void:
	for look in materials:
		look.set_shader_parameter("caustics", Settings.graphics > 0)


func _fountain_water(dish: MeshInstance3D) -> ShaderMaterial:
	var look: ShaderMaterial = dish.material_override.duplicate()
	var radius: float = (dish.mesh as CylinderMesh).top_radius if dish.mesh is CylinderMesh else 1.0
	look.set_shader_parameter("kind", 2)
	# The middle column is 0.45 m wide at the basin and 0.2 m at the bowl, plus a bit of churn.
	look.set_shader_parameter("edge_half", Vector2(radius, 0.6 if radius > 1.5 else 0.3))
	look.set_shader_parameter("foam_width", 0.22)
	look.set_shader_parameter("see_through", 0.0)
	look.set_shader_parameter("deep_at", 0.9)
	look.set_shader_parameter("floor_gap", 0.005)
	_keep(look)
	return look


func _stream_water(look: ShaderMaterial, stream: Dictionary) -> void:
	# The same wiggle as WahatBuilder._build_stream: z = z0 + 3 * sin(x * 0.06).
	look.set_shader_parameter("kind", 0)
	look.set_shader_parameter("stream_shape", Vector4(stream["z"], 3.0, 0.06, float(stream["width"]) * 0.5))
	look.set_shader_parameter("foam_width", 0.32)
	look.set_shader_parameter("deep_at", 1.1)
	look.set_shader_parameter("floor_gap", 0.028)
	look.set_shader_parameter("see_through", 0.0)   # the pieces overlap: see-through would show the joins
	_keep(look)


func _pool_water(water: MeshInstance3D) -> void:
	var look: ShaderMaterial = water.material_override
	var size: Vector3 = (water.mesh as BoxMesh).size
	look.set_shader_parameter("kind", 1)
	look.set_shader_parameter("edge_half", Vector2(size.x, size.z) * 0.5)
	look.set_shader_parameter("foam_width", 0.28)
	look.set_shader_parameter("deep_at", 2.2)
	look.set_shader_parameter("floor_gap", 0.05)
	_keep(look)


func _keep(look: ShaderMaterial) -> void:
	if not GameConfig.WATER_V2:
		look.shader = OLD_WATER
	if not look in materials:
		materials.append(look)


static func _map(world: Node) -> Dictionary:
	var builder := world.get_node_or_null("WahatBuilder")
	if builder != null and builder.get("data") != null:
		return (builder.data as Script).get_script_constant_map()
	return {}
