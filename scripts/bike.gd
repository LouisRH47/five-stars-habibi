extends CharacterBody3D
## The player's bicycle.
## W / Up arrow = pedal, S / Down arrow = brake (then roll backwards),
## A / D or Left / Right = steer, Space = handbrake, Shift = sprint, R = nearby recovery,
## B = ring the bell (Session 29).
## The look (wheels, pedals, handlebars, kickstand and the rider) is built in code by
## scripts/bike_model.gd; this script moves those parts.
## Tuning numbers are in scripts/game_config.gd.

## Sent when the bike hits something. strength is 0 (tiny tap) to 1 (full-speed, head-on).
signal bumped(strength: float)
## Sent when the bike rides over a speed bump. strength is 0 (crawling) to 1 (full speed
## or faster). The camera shakes on it. Session 8's damage meter can listen to it too
## ("bubble tea hates speed bumps").
signal went_over_bump(strength: float)
## Sent once each time you slam on the brakes (S or Space) while going faster than
## HARD_BRAKE_MIN_KMH. The damage meter listens to it (drinks spill).
signal hard_braked
## Sent when you crash (Session 12). big = false: you fall off and get back on after
## the authored fall finishes. A major impact goes to the clinic after that fall.
## Cats and kids cause a small crash unless the rocket boost is active.
signal crashed(big: bool)
## The visible fall has finished. The clinic waits for this instead of cutting away at impact.
signal fall_completed(big: bool, impact: Dictionary)
## Sent when you ring the bell with B (Session 29). Sounds plays the ring.
signal bell_rung

## Words for the moving life on the map (Session 30), by the start of their node name.
const LIFE_WORDS := {"Buggy": "a golf buggy", "Horse": "a horse", "Person": "someone walking",
		"Gardener": "a gardener", "Kid": "a kid", "Duck": "a duck"}

## Current speed in metres per second. Positive = forwards.
var speed := 0.0
## Sprint energy, 0 to STAMINA_MAX.
var stamina := GameConfig.STAMINA_MAX
## True after stamina runs out, until it refills to STAMINA_TIRED_UNTIL.
var tired := false
## True while actually sprinting this frame.
var sprinting := false
## How many speed bumps you've ridden over since the game started.
var bumps_taken := 0
## Seconds left lying on the ground after a small crash (0 = riding).
var fallen_left := 0.0
## True after a big crash, until the CrashManager puts you back at the start.
var wrecked := false
## True while you're walking (Session 19): the bike stands on its stand, no rider, no keys.
var parked := false
## The last crash (Session 23, for the clinic screen): what you hit and how fast.
var last_crash := {"what": "a wall", "kmh": 0.0}
## How far the pedals have turned, in radians (Session 29; the smoke test watches it).
var crank_angle := 0.0
## How far the kickstand is down: 0 = folded up (riding), 1 = down (parked).
var kickstand_down := 0.0
## Two bags on the bike (Session 32, big family order): top speed is lower and the steering
## wobbles a bit. The DeliveryManager switches it on at pickup and off at the door.
var heavy_load := false:
	set(on):
		heavy_load = on
		_show_extra_bag(on)

## Equipment is injected by the shop/state layer; physics keeps no persistent ownership.
var upgrade_levels: Dictionary = {}
var boost_active: bool:
	get:
		return _boost_left > 0.0
var boost_cooldown_left := 0.0
var fall_kind := ""
var fall_progress := 0.0
var _boost_left := 0.0
var _flames: Node3D
var _fall_active := false
var _fall_big := false
var _fall_elapsed := 0.0
var _fall_duration := 0.0
var _rider_home := Transform3D.IDENTITY
var _fall_rider_start := Transform3D.IDENTITY
var _safe_transform := Transform3D.IDENTITY

# Where the wheels meet a speed bump, in metres ridden after the bike's collision box
# first touches it. The box front is 0.85 m ahead of the bike's middle, the front wheel
# 0.55 m, and a bump is 0.5 m deep: so the front wheel is on top of the bump from 0.3 to
# 0.8 m, and the back wheel (1.1 m further back) from 1.4 to 1.9 m.
const HOP_FRONT_START := 0.3
const HOP_REAR_START := 1.4
const HOP_END := 2.2          # both wheels are off the bump again
const HOP_WHEEL_RISE := 1.0   # metres a wheel is going up and down (bump + round wheel edge)
const WHEEL_BASE := 1.1       # metres between the two wheels

var _steer := 0.0
var _wobble_time := 0.0      # seconds of riding with a heavy load (for the wobble)
var _extra_bag: Node3D       # the second bag, on the handlebars (big family orders)
var _braking := false        # true while a brake key is held (so a long press counts once)
var _bump_cooldown := 0.0
var _crash_grace := 0.0  # Session 52: no new fall right after getting back up
var _start_transform: Transform3D
var _hop_active := false     # true while the bike is going over a speed bump
var _hop_dist := 0.0         # metres ridden since the bike touched the bump
var _hop_time := 0.0         # seconds since the bike touched the bump
var _hop_height := 0.0       # metres of extra springy bounce (0 when crawling)
var _hop_backwards := false  # true if we went over it rolling backwards

var _handlebar_turn := 0.0  # radians the handlebars are turned (follows the steering)
@onready var _model: Node3D = $Model
var _front_wheel: Node3D
var _rear_wheel: Node3D
var _fork: Node3D
var _crank: Node3D
var _kickstand: Node3D
var _rider: Person


func _ready() -> void:
	# A fresh shift and clinic recovery use the original spawn.
	_start_transform = global_transform
	_safe_transform = global_transform
	# Speed bumps (scripts/speed_bump.gd) look for this group.
	add_to_group("bike")
	# Build the bicycle and the rider on it (Session 29).
	BikeModel.build(_model)
	_front_wheel = _model.get_node("Fork/FrontWheel")
	_rear_wheel = _model.get_node("RearWheel")
	_fork = _model.get_node("Fork")
	_crank = _model.get_node("Crank")
	_kickstand = _model.get_node("Kickstand")
	_rider = _model.get_node("Rider")
	_rider_home = _rider.transform
	_rider.play("pedal")
	# Dress the rider in the look picked on the application (Session 14).
	RiderLook.apply(_rider, GameState.rider_look)
	# Dust puffs from the back tyre on sand and when braking hard (Session 31).
	var dust := preload("res://scripts/tyre_dust.gd").new()
	dust.name = "TyreDust"
	add_child(dust)
	# Session 61: faint, short skid marks after a hard brake, which fade away.
	var skid := preload("res://scripts/skid_marks.gd").new()
	skid.name = "SkidMarks"
	add_child(skid)
	var wind := preload("res://scripts/ride_wind.gd").new()
	wind.name = "RideWind"
	wind.bike = self
	add_child(wind)


func _physics_process(delta: float) -> void:
	boost_cooldown_left = maxf(boost_cooldown_left - delta, 0.0)
	_boost_left = maxf(_boost_left - delta, 0.0)
	_crash_grace = maxf(_crash_grace - delta, 0.0)
	if _flames != null:
		_flames.visible = boost_active
		_flames.scale = Vector3.ONE * (0.9 + sin(Time.get_ticks_msec() * 0.04) * 0.1)
	if _fall_active:
		_step_fall(delta)
		return
	if Input.is_action_just_pressed("reset_bike") and fallen_left <= 0.0 and not wrecked:
		recover_nearby()
		return
	if InputMap.has_action("rocket_boost") and Input.is_action_just_pressed("rocket_boost"):
		activate_boost()
	if Input.is_action_just_pressed("ring_bell") and not parked:
		ring_bell()
	_move_parts(delta)
	if wrecked:
		return
	if parked:
		_stand(delta)
		return
	_update_stamina_and_speed(delta)
	_update_steering(delta)
	_move(delta)
	_update_lean(delta)
	_update_hop(delta)
	_spin_wheels(delta)
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)


## Puts the bike back where it started for a new shift or clinic recovery.
func reset_to_start() -> void:
	global_transform = _start_transform
	_safe_transform = _start_transform
	_restore_rider()
	velocity = Vector3.ZERO
	speed = 0.0
	fallen_left = 0.0
	wrecked = false
	_crash_grace = 0.0
	if parked:
		set_parked(false)
	_model.rotation.z = 0.0
	_hop_active = false
	_model.position.y = 0.0
	_model.rotation.x = 0.0
	_model.position = Vector3.ZERO
	_boost_left = 0.0
	_fall_active = false
	fall_progress = 0.0
	fall_kind = ""


## R recovers locally instead of teleporting a completed job back to the shops.
func recover_nearby() -> void:
	if _fall_active or wrecked:
		return
	var origin := global_position
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = $CollisionShape3D.shape
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var space := get_world_3d().direct_space_state
	var choices: Array[Vector3] = []
	if _safe_transform.origin.distance_to(origin) <= 8.0:
		choices.append(_safe_transform.origin + global_basis.z * 1.5)
	for radius in [1.5, 3.0, 5.0, 8.0]:
		for step in range(8):
			var angle := step * TAU / 8.0
			choices.append(origin + Vector3(cos(angle), 0, sin(angle)) * radius)
	choices.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_squared_to(origin) < b.distance_squared_to(origin))
	for candidate in choices:
		var ground_query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 4.0, candidate - Vector3.UP * 6.0)
		ground_query.exclude = [get_rid()]
		var ground := space.intersect_ray(ground_query)
		if ground.is_empty() or (ground["normal"] as Vector3).y < 0.6:
			continue
		if absf(float(ground["position"].y) - origin.y) > 1.5 or CrashImpact.category_for(ground["collider"]) == "vehicle":
			continue
		candidate.y = ground["position"].y + 0.04
		query.transform = Transform3D(global_basis.orthonormalized(), candidate + Vector3.UP * 0.9)
		if not space.intersect_shape(query, 1).is_empty():
			continue
		var passage := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.85, candidate + Vector3.UP * 0.85)
		passage.exclude = [get_rid()]
		if not space.intersect_ray(passage).is_empty():
			continue # Recovery may back out of trouble, but cannot skip through a wall or rail.
		global_position = candidate
		velocity = Vector3.ZERO
		speed = 0.0
		_safe_transform = global_transform
		reset_physics_interpolation()
		return


func configure_upgrades(levels: Dictionary) -> void:
	upgrade_levels = levels.duplicate()
	stamina = minf(stamina, stamina_capacity())


func stamina_capacity() -> float:
	return GameConfig.STAMINA_MAX * (1.0 + 0.1 * clampi(int(upgrade_levels.get("stamina", 0)), 0, 10))


func bell_range() -> float:
	return GameConfig.BELL_HEAR_RANGE * (2.0 if int(upgrade_levels.get("bell", 0)) > 0 else 1.0)


func maximum_speed_kmh(sprint := false) -> float:
	if boost_active:
		return GameConfig.BOOST_SPEED_KMH
	var maximum := GameConfig.BIKE_SPRINT_MAX_SPEED_KMH if sprint else GameConfig.BIKE_MAX_SPEED_KMH
	maximum += float(upgrade_levels.get("aluminium", 0)) + 2.0 * float(upgrade_levels.get("carbon", 0))
	return maximum * (GameConfig.FAMILY_SPEED_SHARE if heavy_load else 1.0)


func boost_ready() -> bool:
	return int(upgrade_levels.get("rocket", 0)) > 0 and boost_cooldown_left <= 0.0 and not parked and not wrecked and not _fall_active


func activate_boost() -> bool:
	if not boost_ready():
		return false
	_boost_left = GameConfig.BOOST_DURATION
	boost_cooldown_left = GameConfig.BOOST_DURATION + GameConfig.BOOST_COOLDOWN
	if _flames == null:
		_flames = Node3D.new()
		_flames.name = "RocketFlames"
		_model.add_child(_flames)
		for colour in [Color(1, 0.22, 0.03), Color(1, 0.8, 0.1)]:
			var flame := LowPoly.cylinder(_flames, 0.0, 0.16, 0.85, colour, Vector3(0, 0.65, 1.05))
			flame.rotation.x = PI * 0.5
			flame.scale = Vector3.ONE * (0.65 if colour.g > 0.5 else 1.0)
	_flames.visible = true
	return true


## Parks the bike (true) while you walk, or takes it off the stand (false).
## Parked: the rider on it disappears (you're the walker now) and it leans on its stand.
func set_parked(on: bool) -> void:
	parked = on
	if on:
		_boost_left = 0.0
	speed = 0.0
	velocity = Vector3.ZERO
	_rider.visible = not on  # you're the walker now
	if not on:
		RiderLook.apply(_rider, GameState.rider_look)  # in case the look changed
	_model.rotation.z = deg_to_rad(GameConfig.PARKED_LEAN_DEG) if on else 0.0


## B: ring ring! People nearby look up and wave, cats and kids get out of the way.
## Everything that listens is in the "hears_bell" group and checks how far away it is.
func ring_bell() -> void:
	bell_rung.emit()
	get_tree().call_group("hears_bell", "hear_bell", self)


## Moves the bike's parts: handlebars follow the steering, the kickstand drops when
## parked, and the rider's hands and feet stay on the grips and pedals.
func _move_parts(delta: float) -> void:
	var steer_to := deg_to_rad(GameConfig.HANDLEBAR_MAX_DEG) * _steer if not parked else 0.0
	_handlebar_turn = lerpf(_handlebar_turn, steer_to, 1.0 - exp(-GameConfig.HANDLEBAR_SMOOTHING * delta))
	_fork.rotation.y = _handlebar_turn
	kickstand_down = move_toward(kickstand_down, 1.0 if parked else 0.0, GameConfig.KICKSTAND_SPEED * delta)
	_kickstand.rotation = Vector3(deg_to_rad(-85.0), 0, 0).lerp(Vector3(deg_to_rad(15.0), 0, deg_to_rad(-20.0)), kickstand_down)
	if not _rider.visible:
		return
	var to_rider := _rider.transform.affine_inverse()
	for i in 2:
		var pedal := _crank.get_node("PedalLeft" if i == 0 else "PedalRight") as Node3D
		_rider.pose.feet[i] = to_rider * (_crank.transform * pedal.position + Vector3(0, 0.07, 0.03))
		var grip := _fork.transform * BikeModel.grip_spot(-1.0 if i == 0 else 1.0)
		_rider.pose.hands[i] = to_rider * (grip + Vector3(0, 0.03, 0.04))
	_rider.pose.lean = GameConfig.RIDER_LEAN_DEG


## Standing still on the stand: only gravity, no keys.
func _stand(delta: float) -> void:
	speed = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		# Standing on its kickstand: don't move at all, so a cat, kid or buggy that walks
		# into it can't slide it along.
		velocity.y = 0.0
		return
	velocity.y -= GameConfig.GRAVITY * delta
	move_and_slide()


## A speed bump calls this when the bike rides onto it (scripts/speed_bump.gd).
## The bike hops (only the model, not the physics body), and loses speed if it was fast.
func hit_speed_bump() -> void:
	var kmh := absf(speed) * 3.6
	var strength := clampf(kmh / GameConfig.BIKE_MAX_SPEED_KMH, 0.0, 1.0)
	# Nothing lost at or under the safe speed, the most lost at full speed (rewards slowing down).
	var too_fast := clampf((kmh - GameConfig.SPEED_BUMP_SAFE_KMH)
			/ (GameConfig.BIKE_MAX_SPEED_KMH - GameConfig.SPEED_BUMP_SAFE_KMH), 0.0, 1.0)
	speed *= lerpf(1.0, GameConfig.SPEED_BUMP_SPEED_KEEP, too_fast)
	# The wheels always roll up over the bump; going fast adds a springy bounce on top.
	_hop_height = lerpf(0.0, GameConfig.SPEED_BUMP_HOP_MAX - GameConfig.SPEED_BUMP_HEIGHT, strength)
	_hop_active = true
	_hop_dist = 0.0
	_hop_time = 0.0
	_hop_backwards = speed < 0.0
	bumps_taken += 1
	went_over_bump.emit(strength)


## Session 75: riding over a low kerb (KerbBumps calls this): the wheels roll up over it,
## a small shake and a little speed lost. Never a crash.
func hit_kerb() -> void:
	var ratio := clampf(absf(speed) * 3.6 / GameConfig.BIKE_MAX_SPEED_KMH, 0.0, 1.0)
	speed *= GameConfig.KERB_SPEED_KEEP
	if not _hop_active:
		_hop_height = 0.0
		_hop_active = true
		_hop_dist = 0.0
		_hop_time = 0.0
		_hop_backwards = speed < 0.0
	if ratio > 0.2:
		bumped.emit(GameConfig.KERB_SHAKE * ratio)


func _update_stamina_and_speed(delta: float) -> void:
	var pedal := Input.get_action_strength("move_forward")
	var brake := Input.get_action_strength("move_back")
	# A rider can brake while still holding W. Brake input always wins.
	if brake > 0.0 or Input.is_action_pressed("handbrake"):
		pedal = 0.0

	sprinting = pedal > 0.0 and Input.is_action_pressed("sprint") and not tired and stamina > 0.0 and not boost_active
	if sprinting:
		stamina = maxf(stamina - GameConfig.STAMINA_DRAIN_PER_SEC * delta, 0.0)
		if stamina <= 0.0:
			tired = true
	else:
		var refill := GameConfig.STAMINA_REFILL_PEDALLING if pedal > 0.0 else GameConfig.STAMINA_REFILL_COASTING
		stamina = minf(stamina + refill * delta, stamina_capacity())
		if tired and stamina >= GameConfig.STAMINA_TIRED_UNTIL:
			tired = false

	var braking_now := (brake > 0.0 and pedal == 0.0) or Input.is_action_pressed("handbrake")
	if braking_now and not _braking and speed * 3.6 > GameConfig.HARD_BRAKE_MIN_KMH:
		hard_braked.emit()
	_braking = braking_now

	var max_kmh := maximum_speed_kmh(sprinting)
	var accel := GameConfig.BIKE_SPRINT_ACCELERATION if sprinting else GameConfig.BIKE_ACCELERATION
	var max_speed := max_kmh / 3.6

	if boost_active and brake == 0.0 and not Input.is_action_pressed("handbrake"):
		speed = max_speed
	elif pedal > 0.0:
		if speed > max_speed:
			# Just stopped sprinting: ease back down to normal top speed.
			speed = move_toward(speed, max_speed, GameConfig.BIKE_COAST_DRAG * delta)
		else:
			# Gentle start: you gain speed fastest from a standstill and slower near the top.
			var ease_off := 1.0 - 0.6 * clampf(speed / max_speed, 0.0, 1.0)
			speed = move_toward(speed, max_speed, accel * pedal * ease_off * delta)
	elif brake > 0.0:
		if speed > 0.1:
			speed = move_toward(speed, 0.0, GameConfig.BIKE_BRAKE * (1.35 if int(upgrade_levels.get("brakes", 0)) > 0 else 1.0) * brake * delta)
		else:
			var reverse_speed := -GameConfig.BIKE_REVERSE_SPEED_KMH / 3.6
			speed = move_toward(speed, reverse_speed, GameConfig.BIKE_ACCELERATION * delta)
	else:
		speed = move_toward(speed, 0.0, GameConfig.BIKE_COAST_DRAG * delta)

	if Input.is_action_pressed("handbrake"):
		speed = move_toward(speed, 0.0, GameConfig.BIKE_HANDBRAKE * delta)


func _update_steering(delta: float) -> void:
	_steer = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	var speed_ratio := clampf(absf(speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
	if heavy_load:
		_wobble(delta, speed_ratio)
	if _steer == 0.0:
		return
	# You can't turn while standing still, and turning is a bit gentler at top speed.
	var grip := clampf(speed_ratio * 3.0, 0.0, 1.0) * lerpf(1.0, 0.6, speed_ratio)
	var turn := deg_to_rad(GameConfig.BIKE_STEER_DEG_PER_SEC) * _steer * grip * delta
	if speed < 0.0:
		turn = -turn  # steering flips when rolling backwards, like a real bike
	rotate_y(turn)


func _move(delta: float) -> void:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	var incoming := velocity
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GameConfig.GRAVITY * delta
	move_and_slide()

	# Safety net: if the bike somehow falls off the world, put it back.
	if global_position.y < GameConfig.WORLD_FALL_RESET_Y:
		global_transform = _safe_transform
		recover_nearby()
		return

	# Riding into a wall or box slows you down. Head-on hits slow you the most.
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var normal := hit.get_normal()
		if absf(normal.y) < 0.5:
			var head_on := absf(forward.dot(normal))
			if _check_crash(head_on, hit.get_collider(), incoming, normal, hit.get_collider_velocity()):
				return
			var strength := head_on * clampf(absf(speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
			speed *= lerpf(1.0, GameConfig.BIKE_BUMP_SPEED_KEEP, head_on)
			if strength >= GameConfig.BUMP_MIN_STRENGTH and _bump_cooldown <= 0.0:
				_bump_cooldown = GameConfig.BUMP_COOLDOWN
				bumped.emit(strength)
			break
	if is_on_floor() and get_slide_collision_count() <= 1 and not _fall_active and not wrecked:
		_safe_transform = global_transform


## Was that a crash? Returns true if it was (the bike stops). Small: fall off for a bit.
## Big: a solid thing (not a cat or kid) hit fast and fairly straight on.
func _check_crash(head_on: float, thing: Object, incoming := Vector3.ZERO,
		normal := Vector3.ZERO, other_velocity := Vector3.ZERO) -> bool:
	if _fall_active or wrecked or fallen_left > 0.0:
		return false
	# The optional inputs keep direct smoke-test calls meaningful; actual collision
	# handling always supplies the pre-slide velocity and collider's velocity.
	if incoming.length_squared() < 0.000001:
		incoming = -global_basis.z * speed
	if normal.length_squared() < 0.000001:
		var forward := incoming.normalized()
		var side := Vector3.UP.cross(forward)
		normal = -forward * head_on + side * sqrt(maxf(1.0 - head_on * head_on, 0.0))
	var impact := CrashImpact.capture(incoming, normal, thing, other_velocity, boost_active)
	if not impact["crash"]:
		return false
	# Just got back up: small knocks don't make you fall again (a big hit still does).
	if _crash_grace > 0.0 and not impact["big"]:
		return false
	last_crash = impact.duplicate(true)
	bumped.emit(clampf(float(impact["score"]) / GameConfig.CRASH_CRITICAL_SCORE, 0.0, 1.0))
	_begin_fall(impact)
	return true


func _begin_fall(impact: Dictionary) -> void:
	last_crash = impact.duplicate(true)
	# Coverage belongs to this collision, even if the rider changes the phone
	# setting while the fall is playing and before the clinic resolves its bill.
	last_crash["insured_at_impact"] = GameState.insurance_on
	_fall_active = true
	_fall_big = bool(impact["big"])
	fall_kind = impact["fall"]
	fall_progress = 0.0
	_fall_elapsed = 0.0
	_fall_duration = GameConfig.CRASH_FALL_DURATIONS[fall_kind]
	fallen_left = _fall_duration
	wrecked = _fall_big
	_boost_left = 0.0
	sprinting = false
	speed = 0.0
	velocity = Vector3.ZERO
	_hop_active = false
	_model.position = Vector3.ZERO
	_model.rotation = Vector3.ZERO
	_fall_rider_start = _rider.transform
	_rider.reparent(self, true)
	_fall_rider_start = _rider.transform
	_rider.play("lie")
	crashed.emit(_fall_big)


## A bounded authored trajectory: visibly separate rider/bike, then recover or clinic.
## Nothing here calls move_and_slide, so tumbling contacts cannot create another accident.
func _step_fall(delta: float) -> void:
	speed = 0.0
	velocity = Vector3.ZERO
	_fall_elapsed += delta
	fallen_left = maxf(_fall_duration - _fall_elapsed, 0.0)
	fall_progress = clampf(_fall_elapsed / _fall_duration, 0.0, 1.0)
	var landing := fall_progress if _fall_big else minf(fall_progress / 0.8, 1.0)
	var ease := 1.0 - pow(1.0 - landing, 3.0)
	var side: float = last_crash["side"]
	var local_normal: Vector3 = global_basis.inverse() * (last_crash["normal"] as Vector3)
	var local_direction: Vector3 = global_basis.inverse() * (last_crash["direction"] as Vector3)
	var slide := local_direction.slide(local_normal)
	var intensity := clampf(float(last_crash["score"]) / GameConfig.CRASH_SEVERE_SCORE,
			GameConfig.CRASH_FORCE_SCALE.x, GameConfig.CRASH_FORCE_SCALE.y)
	var travel := (local_normal * 0.55 + slide.normalized() * 0.8) * intensity
	var destination := _fall_rider_start.origin + travel
	destination.y = 0.35
	var rider_rotation := Vector3.ZERO
	var lift := 0.0
	if fall_kind == "tip":
		destination = _fall_rider_start.origin + Vector3(side * 0.55 * intensity, 0, 0)
		destination.y = 0.4
		rider_rotation.z = deg_to_rad(70.0) * side * ease
		lift = sin(landing * PI) * 0.18 * intensity
	elif fall_kind == "skid":
		destination += Vector3(side * 0.8 * intensity, 0, 0)
		rider_rotation = Vector3(0, side * ease * 0.45, side * PI * 0.5 * ease)
		lift = sin(landing * PI) * 0.35 * intensity
	else:
		# One forward somersault and a quarter turn to a horizontal landing.
		rider_rotation = Vector3(PI * 2.5 * ease, side * 0.35 * ease, side * 0.2 * ease)
		lift = sin(landing * PI) * intensity
	_rider.position = _fall_rider_start.origin.lerp(destination, ease) + Vector3.UP * lift
	_rider.rotation = rider_rotation
	_keep_above_ground(_rider)
	_model.position = Vector3(side * 0.2 * ease, 0, 0) + travel * ease * 0.2
	_model.rotation = Vector3(sin(landing * PI) * (0.6 if fall_kind == "tumble" else 0.1), 0, side * deg_to_rad(82.0) * ease)
	_keep_above_ground(_model)
	# A small final portion of a recoverable fall is a readable getting-up motion.
	if not _fall_big and fall_progress > 0.8:
		var get_up := smoothstep(0.8, 1.0, fall_progress)
		_rider.position = _rider.position.lerp(_rider_home.origin, get_up)
		_rider.rotation *= 1.0 - get_up
		_keep_above_ground(_rider)
		_model.position *= 1.0 - get_up
		_model.rotation *= 1.0 - get_up
		_keep_above_ground(_model)
	if fall_progress >= 1.0:
		_fall_active = false
		fallen_left = 0.0
		if not _fall_big:
			_restore_rider()
			_model.position = Vector3.ZERO
			_model.rotation = Vector3.ZERO
			_bump_cooldown = GameConfig.BUMP_COOLDOWN
			_step_back_after_fall()
		fall_completed.emit(_fall_big, last_crash.duplicate(true))


## Session 52: after a small fall, move the bike a little away from what it hit and give a
## short grace time, so you don't fall straight off again (the old "crash loop").
func _step_back_after_fall() -> void:
	_crash_grace = GameConfig.CRASH_GRACE_TIME
	var away: Vector3 = last_crash.get("normal", Vector3.ZERO)
	away.y = 0.0
	if away.length_squared() < 0.0001 or not is_inside_tree():
		return
	move_and_collide(away.normalized() * GameConfig.CRASH_PUSH_BACK)
	_safe_transform = global_transform


func _restore_rider() -> void:
	if _rider == null or not is_instance_valid(_rider):
		return
	if _rider.get_parent() != _model:
		_rider.reparent(_model, false)
	_rider.transform = _rider_home
	_rider.visible = true
	_rider.play("pedal")


## Keep the whole visible body above the ground while its authored roll turns it.
## The bone mesh's AABB is conservative, so this also avoids feet/head clipping.
func _keep_above_ground(visual: Node3D) -> void:
	var ground_y := global_position.y + 0.03
	var lowest := INF
	for part in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := part as MeshInstance3D
		if not mesh.visible:
			continue
		var bounds := mesh.get_aabb()
		for corner in range(8):
			lowest = minf(lowest, (mesh.global_transform * bounds.get_endpoint(corner)).y)
	if lowest < ground_y:
		visual.global_position.y += ground_y - lowest


## Heavy load (big family order): the front sways gently left and right while you ride,
## more the faster you go. FAMILY_WOBBLE_DEG is how far it sways at full speed.
func _wobble(delta: float, speed_ratio: float) -> void:
	_wobble_time += delta
	var sway := TAU * GameConfig.FAMILY_WOBBLE_SPEED
	rotate_y(deg_to_rad(GameConfig.FAMILY_WOBBLE_DEG) * sway * cos(_wobble_time * sway) * speed_ratio * delta)


## The second bag hangs on the handlebars while heavy_load is on.
func _show_extra_bag(on: bool) -> void:
	if _extra_bag == null and on and _model != null and _model.has_node("Fork"):
		_extra_bag = LowPoly.box(_model.get_node("Fork"), Vector3(0.32, 0.3, 0.26),
				BikeModel.BOX, Vector3(0, 0.86, -0.22))
		_extra_bag.name = "ExtraBag"
	if _extra_bag != null:
		_extra_bag.visible = on


## A few words for what you hit, for the clinic screen ("a parked car").
static func what_is(thing: Object) -> String:
	var node := thing as Node
	for _i in 3:  # the name may be on the thing or the node it belongs to
		if node == null:
			break
		var n := String(node.name)
		if n.begins_with("ParkedCar"):
			return "a parked car"
		if n.begins_with("Villa"):
			return "a villa wall"
		if n.begins_with("Palm"):
			return "a palm tree"
		if n.begins_with("Restaurant"):
			return "a restaurant"
		if n == "Mosque":
			return "the mosque"
		if n == "Supermarket":
			return "the mini market"
		if n.begins_with("Horse_") or n == "Groom":  # Session 33: horses crossing
			return "a horse" if n.begins_with("Horse") else "a groom with horses"
		if n == "RoadWorks":
			return "road works"
		if node.is_in_group("critter"):
			for start in LIFE_WORDS:
				if n.begins_with(start):
					return LIFE_WORDS[start]
			return "a cat" if n.begins_with("Cat") else "a kid on a scooter"
		node = node.get_parent()
	return "a wall"


func _update_lean(delta: float) -> void:
	# Lean into turns: more lean when going faster. Only the model leans, not the physics body.
	var speed_ratio := clampf(absf(speed) / (GameConfig.BIKE_MAX_SPEED_KMH / 3.6), 0.0, 1.0)
	var target_lean := deg_to_rad(GameConfig.BIKE_LEAN_MAX_DEG) * _steer * speed_ratio
	var follow := 1.0 - exp(-GameConfig.BIKE_LEAN_SMOOTHING * delta)
	_model.rotation.z = lerpf(_model.rotation.z, target_lean, follow)


func _update_hop(delta: float) -> void:
	# The speed-bump bounce. It follows the distance ridden, not the clock, so each wheel
	# rolls up over the bump exactly while it is on it, at any speed: nose up while the
	# front wheel is on it, nose down while the back wheel is. If you stop on the bump,
	# the bike just stays up there until you move on.
	# Only the model moves; the physics body stays on the ground, so is_on_floor() and
	# the camera don't notice.
	if not _hop_active:
		return
	_hop_dist += absf(speed) * delta
	_hop_time += delta
	if _hop_dist > HOP_END:
		_hop_active = false
		_model.position.y = 0.0
		_model.rotation.x = 0.0
		return
	var front := _wheel_lift(_hop_dist, HOP_FRONT_START)
	var back := _wheel_lift(_hop_dist, HOP_REAR_START)
	if _hop_backwards:
		# Rolling backwards, the back wheel reaches the bump first.
		var first := front
		front = back
		back = first
	# Going fast adds a spring bounce on top: a big hop, then a smaller one, dying away.
	var wave := 0.0
	if _hop_time < GameConfig.SPEED_BUMP_HOP_TIME:
		var done := _hop_time / GameConfig.SPEED_BUMP_HOP_TIME  # 0 at the start, 1 at the end
		wave = sin(done * TAU) * (1.0 - done)
	_model.position.y = (front + back) * 0.5 + _hop_height * absf(wave)
	# Tip the model so each wheel sits on its own height (positive = nose up, as the
	# front of the bike is -Z), plus a little extra tip from the spring bounce.
	var size := _hop_height / GameConfig.SPEED_BUMP_HOP_MAX
	_model.rotation.x = atan2(front - back, WHEEL_BASE) \
			+ deg_to_rad(GameConfig.SPEED_BUMP_TILT_DEG) * size * wave


## How high one wheel is lifted by the bump after riding dist metres, for a wheel that
## reaches the bump at start: rises to SPEED_BUMP_HEIGHT on top of it, then back to 0.
func _wheel_lift(dist: float, start: float) -> float:
	var t := clampf((dist - start + 0.25) / HOP_WHEEL_RISE, 0.0, 1.0)
	return GameConfig.SPEED_BUMP_HEIGHT * clampf(sin(t * PI), 0.0, 1.0)


func _spin_wheels(delta: float) -> void:
	# Wheels turn with the ground speed. The wheel meshes are tipped on their side,
	# so spinning around their local Y axis rolls them forwards.
	var turn := speed / GameConfig.WHEEL_RADIUS * delta
	_front_wheel.rotate_object_local(Vector3.UP, -turn)
	_rear_wheel.rotate_object_local(Vector3.UP, -turn)
	# The pedals go round with the wheels, slower (the gears), and stay flat.
	crank_angle += turn / GameConfig.PEDAL_GEAR
	_crank.rotation.x = -crank_angle
	for pedal in _crank.get_children():
		if pedal.name.begins_with("Pedal"):
			(pedal as Node3D).rotation.x = crank_angle
