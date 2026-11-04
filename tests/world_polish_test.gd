extends SceneTree
## Session 68: water, beam, road wear and particles (docs/polish_plan.md W1 to W6).
## Builds Wahat Al Shams and checks:
##   - W1 the delivery beam: hidden with no order or an offer, orange on the way to the
##     restaurant, teal on the way to the customer, a burst at each stop, the ring shrinks
##     when you're close, no collision; with MARKER_V2 off the old cylinder comes back
##   - W2 the water: pools say kind 1 with their size, the stream knows its shape, the
##     fountain has its own water (kind 2); pool light patterns are off on Graphics Low
##   - W3 the decals: within budget per Graphics level (Low: 64 in view, 8 per ground chunk),
##     every one on a road or in a car park, thin, fading, never on a parked car
##   - W4 particles: within VFX_MAX_PARTICLES on Low, Medium and High; steam at a pizza pick-up
##   - W5 confetti on a 5-star delivery that finishes (even while the game is paused)
##   - W6 skid marks when braking hard on the road, gone after 20 s
## Run it:  Godot --path . --headless -s tests/world_polish_test.gd
var _failed := false
var _world: Node3D
var _dm: Node   # DeliveryManager (untyped: its script needs the GameState autoload)


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	_failed = _failed or not ok
	print("PASS: " if ok else "FAIL: ", message)


func _run() -> void:
	var start := Time.get_ticks_msec()
	var state := root.get_node("GameState")
	state.hired = true
	state.tutorial_done = true
	state.tutorial_running = false
	Settings.graphics = 1
	_world = load("res://scenes/wahat_al_shams.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 4:
		await process_frame
	await physics_frame
	for node in _world.get_children():
		if _is(node, "delivery_manager.gd"):
			_dm = node
	var hooks := root.get_node("PolishHooks")
	_check("res://scripts/polish/world_extras.gd" in hooks.attached, "the polish hooks ran world_extras.gd")
	_dm.set_physics_process(false)   # no surprise orders while we test
	await _check_marker()
	_check_old_marker()
	_check_water()
	_check_decals()
	await _check_particles()
	await _check_confetti()
	_check_skids()
	print("took %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	print("RESULT: ", "FAIL world_polish" if _failed else "PASS world_polish")
	quit(1 if _failed else 0)


func _check_marker() -> void:
	var gs := root.get_node("GameState")
	gs.reset()
	gs.hired = true
	gs.start_shift()
	var marker: Node3D = _dm._marker if _is(_dm._marker, "arrival_marker.gd") else null
	_check(marker != null, "the delivery beam is the new ArrivalMarker")
	if marker == null:
		return
	_check(marker.find_children("*", "CollisionObject3D", true, false).is_empty(), "the beam has no collision")
	_check(not marker.visible, "no beam with no order")
	var order: Order = _dm.make_order("pizza", 0)
	gs.offer_order(order)
	_check(not marker.visible, "no beam while the order is only offered")
	gs.accept_offer()
	await process_frame
	_check(marker.visible and marker.step == gs.Stage.TO_RESTAURANT, "the beam shows on the way to the restaurant")
	_check(marker.colour.is_equal_approx(UiPalette.ORANGE), "orange for the pick-up")
	_check(marker.ring_view != null and marker.sparkles != null and marker.sparkles.emitting, "it has a ring and rising sparkles")
	var bursts: int = marker.bursts
	var door := marker.global_position
	gs.pick_up()
	await process_frame
	var teal_hue := absf(marker.colour.h - UiPalette.TEAL.h) < 0.02
	_check(marker.visible and marker.step == gs.Stage.TO_VILLA and teal_hue and marker.colour.v > 0.6,
			"teal on the way to the customer (%s)" % marker.colour)
	var burst := _dm.get_node_or_null("MarkerBurst") as Node3D
	_check(marker.bursts == bursts + 1 and burst != null and burst.global_position.distance_to(door) < 0.1,
			"the ring bursts at the restaurant when you pick up")
	var far: float = marker.ring_radius(30.0, 0.0)
	var near: float = marker.ring_radius(3.0, 0.0)
	var pulse: float = marker.ring_radius(30.0, 0.25)
	_check(is_equal_approx(far, GameConfig.BEAM_RING_RADIUS) and is_equal_approx(near, GameConfig.BEAM_RING_NEAR_RADIUS)
			and absf(pulse - far * (1.0 + GameConfig.BEAM_RING_PULSE)) < 0.01,
			"the ring is %.1f m far away, %.1f m close and pulses (%.2f)" % [far, near, pulse])
	gs.meter_time = 100.0
	gs.meter_freshness = 100.0
	gs.meter_damage = 100.0
	gs.deliver()
	await process_frame
	_check(not marker.visible and marker.bursts == bursts + 2, "delivered: the beam bursts and goes away")
	var wait := Time.get_ticks_msec()
	while is_instance_valid(burst) and Time.get_ticks_msec() - wait < 4000:
		await process_frame
	_check(not is_instance_valid(burst), "the burst clears itself up")


## The old cylinder: DeliveryManager's own code with MARKER_V2 switched off.
func _check_old_marker() -> void:
	var source: String = load("res://scripts/delivery_manager.gd").source_code
	var old := GDScript.new()
	old.source_code = source.replace("class_name DeliveryManager", "").replace("GameConfig.MARKER_V2", "false")
	var ok := old.reload() == OK
	var manager: Node = old.new() if ok else null
	var beam: MeshInstance3D = manager._make_marker() if ok else null
	_check(beam != null and not _is(beam, "arrival_marker.gd") and beam.mesh is CylinderMesh
			and is_equal_approx((beam.mesh as CylinderMesh).top_radius, GameConfig.MARKER_RADIUS),
			"with MARKER_V2 off the old orange cylinder comes back")
	if beam != null:
		beam.free()
	if manager != null:
		manager.free()


func _check_water() -> void:
	var look: Node = _world.get_node_or_null("WaterLook")
	_check(look != null, "WaterLook is in the world")
	if look == null:
		return
	var new_water := preload("res://assets/shaders/water.gdshader")
	for id in ["LapPool/PoolWater", "CommunityPool/PoolWater", "CommunityPool/KidsWater"]:
		var water := _world.get_node_or_null("DistrictDetail/" + id) as MeshInstance3D
		var mat := water.material_override as ShaderMaterial if water != null else null
		var half := Vector2((water.mesh as BoxMesh).size.x, (water.mesh as BoxMesh).size.z) * 0.5 if water != null else Vector2.ZERO
		_check(mat != null and mat.shader == new_water and mat.get_shader_parameter("kind") == 1
				and (mat.get_shader_parameter("edge_half") as Vector2).is_equal_approx(half), "%s: pool water with its size %s" % [id, half])
	var stream := _world.get_node("WahatBuilder/Stream").get_child(0) as MeshInstance3D
	var stream_mat := stream.material_override as ShaderMaterial
	var shape: Vector4 = stream_mat.get_shader_parameter("stream_shape")
	_check(stream_mat.shader == new_water and stream_mat.get_shader_parameter("kind") == 0 and is_equal_approx(shape.w, 1.5),
			"the stream knows its middle line and width (%s)" % shape)
	var basin := _world.get_node("PlazaBuilder/Fountain/Water") as MeshInstance3D
	var basin_mat := basin.material_override as ShaderMaterial
	_check(basin_mat != stream_mat and basin_mat.get_shader_parameter("kind") == 2
			and is_equal_approx((basin_mat.get_shader_parameter("edge_half") as Vector2).x, (basin.mesh as CylinderMesh).top_radius),
			"the fountain has its own round water")
	var pool_mat := (_world.get_node("DistrictDetail/LapPool/PoolWater") as MeshInstance3D).material_override as ShaderMaterial
	Settings.graphics = 0
	look.apply_graphics()
	var low_off: bool = pool_mat.get_shader_parameter("caustics") == false
	Settings.graphics = 1
	look.apply_graphics()
	_check(low_off and pool_mat.get_shader_parameter("caustics") == true, "pool light patterns: off on Low, on on Medium")


func _check_decals() -> void:
	var wear: Node = _world.get_node_or_null("RoadDecals")
	_check(wear != null and wear.decals.size() > 100, "road wear decals were laid (%d)" % (wear.decals.size() if wear else 0))
	if wear == null:
		return
	var counts := {}
	for kind in wear.kinds:
		counts[kind] = int(counts.get(kind, 0)) + 1
	var all_kinds := ["sand_drift", "tyre_arc", "manhole", "drain", "oil_spot", "slow_ar_en", "zebra"]
	_check(all_kinds.all(func(k): return counts.has(k)) and (counts.has("crack") or counts.has("patch")),
			"every kind of wear is there: %s" % counts)
	var off_road: Array = []
	var thick := true
	for decal: Decal in wear.decals:
		var spot := Vector2(decal.position.x, decal.position.z)
		if not wear.on_road_or_car_park(spot):
			off_road.append(decal.name)
		thick = thick and is_equal_approx(decal.size.y, GameConfig.DECAL_THICKNESS) and decal.distance_fade_enabled \
				and decal.normal_fade >= 0.5
	_check(off_road.is_empty(), "every decal is on a road or in a car park (off: %s)" % [off_road.slice(0, 5)])
	_check(thick, "every decal is a thin box that fades with distance and only paints flat ground")
	var map: Dictionary = load("res://data/wahat_al_shams.gd").get_script_constant_map()
	var on_car: Array = []
	for i in wear.decals.size():
		var p: Vector3 = wear.decals[i].position
		for car: Dictionary in map["PARKED_CARS"]:
			var c: Vector3 = car["position"]
			if Vector2(c.x - p.x, c.z - p.z).length() < GameConfig.DECAL_CAR_GAP + 1.0:
				on_car.append(wear.decals[i].name)
	_check(on_car.is_empty(), "no decal under a parked car (%s)" % [on_car.slice(0, 5)])
	# Most in view at once, from spots every 20 m over the map, for each Graphics level.
	var half: Vector2 = map["MAP_HALF"]
	for level in 3:
		var most := 0
		for x in range(-int(half.x), int(half.x) + 1, 20):
			for z in range(-int(half.y), int(half.y) + 1, 20):
				most = maxi(most, wear.count_near(Vector2(x, z), level))
		_check(most <= GameConfig.DECAL_MAX_NEAR[level], "Graphics %d: at most %d decals in view (limit %d)" % [level, most, GameConfig.DECAL_MAX_NEAR[level]])
	var per_cell := {}
	var low_count := 0
	for i in wear.decals.size():
		if wear.on_low[i]:
			low_count += 1
			var p: Vector3 = wear.decals[i].position
			var cell := Vector2i(floori(p.x / 48.0), floori(p.z / 48.0))
			per_cell[cell] = int(per_cell.get(cell, 0)) + 1
	var worst: int = per_cell.values().max() if not per_cell.is_empty() else 0
	_check(low_count < wear.decals.size() and worst <= GameConfig.DECAL_LOW_PER_CELL,
			"Low keeps %d of %d, at most %d in one ground chunk" % [low_count, wear.decals.size(), worst])
	Settings.graphics = 0
	wear.apply_graphics()
	var hidden: int = wear.decals.filter(func(d: Decal) -> bool: return not d.visible).size()
	var fade_low: float = wear.decals[0].distance_fade_begin
	Settings.graphics = 1
	wear.apply_graphics()
	_check(hidden == wear.decals.size() - low_count and is_equal_approx(fade_low, GameConfig.DECAL_FADE_BEGIN[0])
			and is_equal_approx(wear.decals[0].distance_fade_begin, GameConfig.DECAL_FADE_BEGIN[1]),
			"Graphics Low hides the extra ones and fades sooner")


func _check_particles() -> void:
	var vfx: Node = _world.get_node_or_null("VfxAmbient")
	_check(vfx != null and vfx.emitters.size() >= 10, "ambient particle effects were placed (%d)" % (vfx.emitters.size() if vfx else 0))
	if vfx == null:
		return
	var plaza: Vector2 = load("res://data/wahat_al_shams.gd").PLAZA["centre"]
	var spots := [Vector3(plaza.x, 2, plaza.y), Vector3(115, 2, -18), Vector3(285, 2, -22), Vector3(-212, 2, -205),
			Vector3(100, 2, -59), Vector3(-130, 2, 22)]
	for level in 3:
		Settings.graphics = level
		var most := 0
		var low_ok := true
		for spot: Vector3 in spots:
			vfx.test_eye = spot
			vfx.apply_graphics()
			most = maxi(most, vfx.live_total())
			if level == 0:
				for e: Dictionary in vfx.emitters:
					if (e["node"] as GPUParticles3D).emitting and e["level"] > 0:
						low_ok = false
		_check(most <= GameConfig.VFX_MAX_PARTICLES[level] and most > 0,
				"Graphics %d: at most %d particles at once (limit %d)" % [level, most, GameConfig.VFX_MAX_PARTICLES[level]])
		if level == 0:
			_check(low_ok, "Low only runs the fountain mist and the pick-up steam")
	Settings.graphics = 1
	vfx.test_eye = Vector3(plaza.x, 2, plaza.y)
	vfx.apply_graphics()
	var mist := vfx.emitters.filter(func(e): return (e["node"] as Node).name == "FountainMist")
	_check(not mist.is_empty() and (mist[0]["node"] as GPUParticles3D).emitting, "mist round the fountain when you're near")
	vfx.test_eye = Vector3(5000, 0, 5000)
	vfx.apply_graphics()
	_check(vfx.live_total() == 0, "nothing runs when the camera is far from all of them")
	vfx.test_eye = Vector3.INF
	# Steam at a pizza pick-up.
	var gs := root.get_node("GameState")
	gs.reset()
	gs.hired = true
	gs.start_shift()
	gs.offer_order(_dm.make_order("pizza", 0))
	gs.accept_offer()
	gs.pick_up()
	await process_frame
	var steam := _dm.actor.find_children("PickupSteam*", "GPUParticles3D", false, false)
	_check(not steam.is_empty() and (steam[0] as GPUParticles3D).emitting, "steam rises from the bag at a pizza pick-up")
	gs.reset()


func _check_confetti() -> void:
	var bursts: Node = _world.get_node_or_null("VfxBursts")
	_check(bursts != null, "VfxBursts is in the world")
	if bursts == null:
		return
	var gs := root.get_node("GameState")
	gs.hired = true
	gs.start_shift()
	gs.offer_order(_dm.make_order("pizza", 0))
	gs.accept_offer()
	gs.pick_up()
	gs.meter_time = 100.0
	gs.meter_freshness = 100.0
	gs.meter_damage = 100.0
	var before: int = bursts.made["confetti"]
	gs.deliver()
	var confetti: GPUParticles3D = bursts.last_burst
	_check(gs.last_result["stars"] >= 5.0 and bursts.made["confetti"] == before + 1 and confetti != null
			and confetti.name.begins_with("Confetti") and confetti.emitting, "a 5-star delivery makes one confetti burst")
	paused = true   # the Delivered card pauses the game; the confetti still finishes
	var wait := Time.get_ticks_msec()
	while is_instance_valid(confetti) and Time.get_ticks_msec() - wait < 3000:
		await process_frame
	paused = false
	_check(not is_instance_valid(confetti), "the confetti finishes and clears itself up (paused game)")
	var coins: GPUParticles3D = bursts.coins(Vector3(0, 1, 0))
	var ring: GPUParticles3D = bursts.level_ring(Vector3(0, 0, 0))
	_check(coins.amount == GameConfig.TIP_COINS and ring.amount > 0 and bursts.made["coins"] >= 1 and bursts.made["level_ring"] >= 1,
			"coins for a tip and a ring of light for a level-up")
	gs.reset()


func _check_skids() -> void:
	var bike := _world.get_node("Bike")
	var dust := bike.get_node("TyreDust")
	bike.set_parked(false)
	bike.fallen_left = 0.0
	bike.wrecked = false
	bike.speed = 8.0
	# On the ring road (asphalt, not sand), riding east and braking hard.
	var start := Vector3(-100, bike.global_position.y, -205)
	for i in 30:
		bike.global_position = start + Vector3(i * 0.1, 0, 0)
		dust._brake_left = 0.4
		dust._check_left = 1.0
		dust.on_sand = false
		dust._physics_process(0.016)
	var made: int = dust.skid_marks.size()
	_check(made >= 5 and made <= GameConfig.SKID_MAX[Settings.graphics], "braking hard leaves skid marks (%d)" % made)
	var mark: Decal = dust.skid_marks[0] if made > 0 else null
	_check(mark != null and absf(mark.global_position.z - start.z) < 0.8 and mark.modulate.a > 0.5, "the skid mark is on the road under the tyre")
	dust._update_skids(10.0, false)
	var halfway: float = mark.modulate.a if is_instance_valid(mark) else 0.0
	dust._update_skids(GameConfig.SKID_LIFETIME, false)
	_check(halfway > 0.1 and halfway < GameConfig.SKID_DARKNESS * 0.6 and dust.skid_marks.is_empty(),
			"skid marks fade and are gone after %d s" % GameConfig.SKID_LIFETIME)


## True if node runs the script with this file name (no class names: those scripts need the
## GameState autoload, which a test script can't see when it's first read).
func _is(node: Object, file: String) -> bool:
	return node != null and node.get_script() != null and str(node.get_script().resource_path).ends_with(file)
