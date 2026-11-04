extends SceneTree
## Focused crash rules and fall/clinic integration. Run with an isolated user-data copy.

var _failures := 0
var _count := 0
var _crashes := 0
var _completed := 0


func _initialize() -> void:
	root.get_node("GameState").save_path = "user://crash_impact_test_save.json"
	_run.call_deferred()


func _run() -> void:
	var wall := StaticBody3D.new()
	wall.name = "VillaWall"
	root.add_child(wall)
	var direct := CrashImpact.capture(Vector3(0, 0, -8), Vector3.BACK, wall)
	var scrape := CrashImpact.capture(Vector3(0, 0, -8), Vector3(1, 0, 0.3).normalized(), wall)
	_check("head-on hits have more severity than equally fast wall scrapes", direct["score"] > scrape["score"]
			and CrashImpact.quote(direct)["hospital"] > CrashImpact.quote(scrape)["hospital"])
	var soft := StaticBody3D.new()
	soft.add_to_group("critter")
	root.add_child(soft)
	var soft_hit := CrashImpact.capture(Vector3(0, 0, -8), Vector3.BACK, soft)
	_check("people/animals retain the forgiving minor-crash policy", not soft_hit["big"] and soft_hit["fall"] == "tip")
	_check("harder obstacles produce higher severity", direct["score"] > soft_hit["score"])
	var moving_toward := CrashImpact.capture(Vector3(0, 0, -8), Vector3.BACK, wall, Vector3(0, 0, 3))
	var moving_away := CrashImpact.capture(Vector3(0, 0, -8), Vector3.BACK, wall, Vector3(0, 0, -3))
	_check("moving obstacles use relative impact velocity", moving_toward["score"] > direct["score"] and moving_away["score"] < direct["score"])
	var last_total := -1
	var last_insured := -1
	for band in ["minor", "moderate", "severe", "critical"]:
		var quote := CrashImpact.quote({"severity": band})
		_check("%s quote has a bounded insured contribution" % band, quote["insured"] >= 0 and quote["insured"] <= quote["hospital"] + quote["repair"])
		_check("%s quote increases with severity" % band, quote["hospital"] + quote["repair"] > last_total and quote["insured"] > last_insured)
		last_total = quote["hospital"] + quote["repair"]
		last_insured = quote["insured"]
	var boost_soft := CrashImpact.capture(Vector3(0, 0, -22), Vector3.BACK, soft, Vector3.ZERO, true)
	_check("the active rocket forces a major crash even on a soft collision", boost_soft["big"] and CrashImpact.quote(boost_soft)["hospital"] > 0)

	var gs: Node = root.get_node("GameState")
	gs.reset()
	gs.money = 500
	var covered: Dictionary = gs.big_crash(direct)
	_check("the boss covers the first major crash", covered["boss"] and covered["paid"] == 0 and gs.money == 500)
	gs.boss_paid_crash = true
	gs.insurance_on = true
	var insured: Dictionary = gs.big_crash(direct)
	_check("insurance uses this impact's capped share", insured["paid"] == CrashImpact.quote(direct)["insured"])
	gs.insurance_on = false
	var full: Dictionary = gs.big_crash(direct)
	_check("uninsured riders pay this impact's treatment and repair", full["paid"] == CrashImpact.quote(direct)["hospital"] + CrashImpact.quote(direct)["repair"])

	var bike: Node3D = load("res://scenes/bike.tscn").instantiate()
	root.add_child(bike)
	bike.crashed.connect(func(_big): _crashes += 1)
	bike.fall_completed.connect(func(_big, _impact): _completed += 1)
	var clinic: CanvasLayer = load("res://scripts/clinic_screen.gd").new()
	clinic.bike = bike
	root.add_child(clinic)
	gs.reset()
	gs.money = 500
	var pizza := Order.new()
	pizza.food = "pizza"
	gs.offer_order(pizza)
	bike.speed = 8.0
	_check("a hard collision starts a major authored fall", bike._check_crash(1.0, wall) and bike.wrecked and bike.fall_kind == "tumble")
	_check("the rider separates from the bike during the fall", bike._rider.get_parent() == bike)
	_check("hospital and billing wait for the fall", not clinic.showing and gs.money == 500 and not gs.boss_paid_crash)
	_check("bounce contacts cannot create another accident", not bike._check_crash(1.0, wall) and _crashes == 1)
	bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["tumble"] * 0.5)
	_check("the tumble has a visible moving pose before the clinic", bike._rider.rotation.length() > 0.5 and bike.fall_progress > 0.0 and not clinic.showing)
	bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["tumble"])
	_check("one completed fall opens one clinic visit", clinic.showing and paused and _completed == 1 and _crashes == 1)
	_check("the clinic explains impact severity", clinic.last_bills.has("severity") and "km/h" in clinic._story.text)
	_check("the clinic hides the cancellation badge when the rider has only an offer", not clinic._tag.visible)
	_check("a crash clears the pending offer without adding a zero-star job",
			gs.offered_orders.is_empty() and gs.offered_order == null and gs.history.is_empty())
	clinic.close()
	_check("clinic recovery restores the seated rider", not paused and not bike.wrecked and bike._rider.get_parent() == bike._model)

	gs.offer_order(pizza)
	gs.accept_offer()
	clinic.open(gs.big_crash(direct), true)
	_check("the clinic shows the cancellation badge for an accepted order", clinic._tag.visible)
	_check("a crash records one zero-star cancellation for the accepted order",
			gs.history.size() == 1 and gs.history[0]["cancelled"] and gs.history[0]["stars"] == 0.0)
	clinic.close()
	gs.reset()
	bike.speed = 3.0
	_check("a low-speed collision selects a gentle fall", bike._check_crash(1.0, wall) and bike.fall_kind == "tip" and not bike.wrecked)
	bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["tip"] + 0.1)
	_check("minor falls return control without a clinic bill", bike.fallen_left == 0.0 and not clinic.showing and not gs.boss_paid_crash)
	var scrape_hit := CrashImpact.capture(Vector3(0, 0, -8), Vector3(1, 0, 0.5).normalized(), wall)
	bike._begin_fall(scrape_hit)
	_check("an oblique impact selects the sideways skid", bike.fall_kind == "skid")
	bike._step_fall(GameConfig.CRASH_FALL_DURATIONS["skid"] + 0.1)
	if clinic.showing:
		clinic.close()
	gs.reset()
	bike.configure_upgrades({"rocket": 1})
	_check("owned rocket can fire once", bike.activate_boost() and bike.boost_active and not bike.boost_ready())
	_check("rocket has the required speed and recharge", bike.maximum_speed_kmh() == GameConfig.BOOST_SPEED_KMH
			and bike.boost_cooldown_left == GameConfig.BOOST_DURATION + GameConfig.BOOST_COOLDOWN)
	_check("rocket cannot fire a second time during cooldown", not bike.activate_boost())
	bike.reset_to_start()
	bike.set_parked(true)
	_check("rocket cannot fire on a parked bike", not bike.activate_boost())
	bike.set_parked(false)
	bike.speed = 5.0
	Input.action_press("move_forward")
	Input.action_press("move_back")
	bike._update_stamina_and_speed(0.1)
	Input.action_release("move_forward")
	Input.action_release("move_back")
	_check("braking wins when pedal and brake are both held", bike.speed < 5.0)
	var wind: Node = bike.get_node("RideWind")
	bike.speed = GameConfig.BIKE_MAX_SPEED_KMH / 3.6
	wind._process(2.0)
	var cruising_db: float = wind._player.volume_db
	_check("riding wind rises with speed on the Settings Effects bus", wind.intensity > 0.0 and wind._player.bus == "Effects")
	bike.speed = GameConfig.BIKE_SPRINT_MAX_SPEED_KMH / 3.6
	bike.sprinting = true
	wind._process(2.0)
	_check("sprinting makes the wind stronger", wind._player.volume_db > cruising_db)
	Settings.volumes["Effects"] = 0.0
	Settings.apply()
	_check("the Effects setting mutes riding wind", AudioServer.is_bus_mute(AudioServer.get_bus_index(wind._player.bus)))
	Settings.volumes["Effects"] = 0.8
	Settings.apply()
	paused = true
	wind._process(0.1)
	_check("riding wind stops while the game is paused", wind.intensity == 0.0 and not wind._player.playing)
	paused = false
	bike.speed = 0.0
	wind._process(0.1)
	_check("riding wind is silent when stopped", wind.intensity == 0.0 and wind._player.volume_db == -80.0)
	bike.sprinting = false
	# Recovery stays local and cannot be used to jump through a solid wall/horse rail.
	var floor_body := StaticBody3D.new()
	root.add_child(floor_body)
	LowPoly.solid_box(floor_body, Vector3(30, 1, 30), Vector3(0, -0.5, 0))
	LowPoly.solid_box(wall, Vector3(0.2, 2, 15), Vector3(0, 1, 0))
	bike.position = Vector3(-1, 0.04, 0)
	bike._safe_transform = bike.global_transform
	await physics_frame
	await physics_frame
	var recovery_origin := bike.position
	bike.recover_nearby()
	_check("R recovers to a nearby clear place", bike.position.distance_to(recovery_origin) <= 1.7 and bike.position.distance_to(recovery_origin) > 0.5)
	_check("R cannot skip through a wall or horse rail", bike.position.x < -0.3)
	clinic.free()
	bike.free()
	soft.free()
	wall.free()
	floor_body.free()
	gs._save_waiting = false
	SaveGame.delete(gs.save_path)
	print("CRASH RESULT: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _count])
	quit(0 if _failures == 0 else 1)


func _check(label: String, good: bool) -> void:
	_count += 1
	print("%s: %s" % ["PASS" if good else "FAIL", label])
	if not good:
		_failures += 1
