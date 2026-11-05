extends RefCounted
## Session 68 (PRD "Polish pass": details in the world). The PolishHooks autoload calls
## attach(world) once when the game world opens, after every builder is ready. It adds:
##   - WaterLook: edges for the new water's foam, pool light patterns (W2)
##   - RoadDecals: sand, tyre marks, manholes, oil spots, "SLOW" paint (W3)
##   - VfxAmbient: steam, mist, leaves, sprinklers, splashes, sand wisps (W4)
##   - VfxBursts: confetti, coins and a level-up ring (W5)
## The new delivery beam (W1) is made by DeliveryManager._make_marker() and the skid marks (W6)
## by the tyre dust, so they need nothing here. Each part has its own GameConfig switch.


static func attach(world: Node) -> void:
	WaterLook.attach(world)   # also puts the old water back when WATER_V2 is off
	if GameConfig.ROAD_DECALS:
		RoadDecals.attach(world)
	if GameConfig.VFX_AMBIENT:
		VfxAmbient.attach(world)
	if GameConfig.WORLD_BURSTS:
		VfxBursts.attach(world)
