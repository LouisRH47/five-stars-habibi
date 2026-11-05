extends RefCounted
## Session 69: links the HUD to the world's DeliveryManager once the world is built, so the
## hold-E ring (scripts/hold_ring.gd) can read the same hold progress as the phone's bar.
## Everything else of Session 69 lives in the HUD, meters and shift screen scripts themselves.
## Switch: GameConfig.HOLD_RING (the rest have their own switches, see game_config.gd).


static func attach(world: Node) -> void:
	if not GameConfig.HOLD_RING:
		return
	var hud := world.get_node_or_null("HUD")
	var delivery := world.get_node_or_null("DeliveryManager")
	if hud != null and delivery != null and "delivery_manager" in hud:
		hud.delivery_manager = delivery
