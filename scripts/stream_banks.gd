class_name StreamBanks
extends RefCounted
## Session 63: the falaj (the stream) gets real banks (Louis: "the water too"): pebbles and
## stones along both edges, reeds and tall papyrus clumps, and lily pads (some with a pink
## flower) floating here and there. The water itself already flows (assets/shaders/water.gdshader).
## Nothing goes on the little bridges (WahatBuilder.bridge_spots) or the path crossings.
## Made of simple shapes in a few big meshes (one per 48 m), so it's cheap and works in the
## browser too. Not solid: you can still ride through the stream.

const PEBBLES := [Color(0.72, 0.69, 0.63), Color(0.6, 0.58, 0.55), Color(0.82, 0.77, 0.66), Color(0.5, 0.48, 0.46)]
const REED := [Color(0.36, 0.55, 0.22), Color(0.45, 0.62, 0.28), Color(0.3, 0.48, 0.2)]
const CATTAIL := Color(0.42, 0.26, 0.14)
const PAPYRUS := Color(0.48, 0.66, 0.3)
const PAD := Color(0.25, 0.52, 0.22)
const LILY := Color(0.98, 0.62, 0.78)
const CHUNK := 48.0
const WAHAT := preload("res://scripts/wahat_builder.gd")


## The stream's middle line at x (the same wiggle WahatBuilder draws).
static func centre_z(stream: Dictionary, x: float) -> float:
	return float(stream["z"]) + sin(x * 0.06) * 3.0


## True if x is on or next to a bridge or a path that crosses the stream.
static func near_crossing(map: Dictionary, x: float) -> bool:
	for spot: Vector3 in WAHAT.bridge_spots(map):
		if absf(x - spot.x) < spot.y * 0.5 + GameConfig.BRIDGE_EXTRA_LENGTH * 0.5 + 1.0:
			return true
	return false


## Builds it all. Returns {"reeds": n, "pads": n, "stones": n} for the tests.
static func build(parent: Node3D, map: Dictionary) -> Dictionary:
	var stream: Dictionary = map["STREAM"]
	var holder := Node3D.new()
	holder.name = "StreamBanks"
	parent.add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2563
	var half: float = float(stream["width"]) * 0.5
	var report := {"reeds": 0, "pads": 0, "stones": 0}
	var x: float = stream["from_x"]
	var end_x: float = stream["to_x"]
	while x < end_x:
		var kit := MeshKit.new()
		var stop := minf(x + CHUNK, end_x)
		var reed_x := x
		while x < stop:
			if not near_crossing(map, x):
				var z := centre_z(stream, x)
				for side in [-1.0, 1.0]:
					# Pebbles on the bank: small flat stones, a few per metre.
					for k in 3:
						var off := half + rng.randf_range(0.0, 0.7)
						kit.ball(rng.randf_range(0.06, 0.16), PEBBLES[rng.randi() % PEBBLES.size()],
								Vector3(x + rng.randf_range(-0.5, 0.5), 0.02, z + side * off), 0.45)
					if rng.randf() < 0.18:
						kit.ball(rng.randf_range(0.25, 0.45), PEBBLES[rng.randi() % PEBBLES.size()].darkened(0.1),
								Vector3(x, 0.05, z + side * (half + rng.randf_range(0.2, 0.6))), 0.55)
						report["stones"] += 1
				if rng.randf() < 0.2:
					# A lily pad on the water (some with a flower).
					var pad := Vector3(x + rng.randf_range(-0.4, 0.4), 0.047, z + rng.randf_range(-half + 0.45, half - 0.45))
					var size := rng.randf_range(0.22, 0.35)
					kit.cylinder(size, size, 0.012, PAD, pad, Basis(), 9)
					if rng.randf() < 0.35:
						kit.ball(0.07, LILY, pad + Vector3(0.05, 0.04, 0.03), 0.7)
					report["pads"] += 1
			x += 1.0
		# Reeds and papyrus along both banks.
		while reed_x < stop:
			if not near_crossing(map, reed_x) and rng.randf() < 0.75:
				var side := -1.0 if rng.randf() < 0.5 else 1.0
				var at := Vector3(reed_x, 0, centre_z(stream, reed_x) + side * (half + rng.randf_range(0.1, 0.5)))
				if rng.randf() < 0.2:
					_papyrus(kit, at, rng)
				else:
					_reeds(kit, at, rng)
				report["reeds"] += 1
			reed_x += GameConfig.STREAM_REED_SPACING * rng.randf_range(0.7, 1.3)
		var view := kit.finish("Banks")
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(view)
	holder.set_meta("report", report)
	return report


## A clump of thin reeds leaning out a little; some have brown cattail heads.
static func _reeds(kit: MeshKit, at: Vector3, rng: RandomNumberGenerator) -> void:
	for i in 7:
		var tall := rng.randf_range(0.7, 1.4)
		var lean := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.05, 0.3))
		var base := at + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		kit.box(Vector3(0.035, tall, 0.02), REED[i % REED.size()], base + lean * Vector3(0, tall * 0.5, 0), lean)
		if i < 2 and rng.randf() < 0.5:
			kit.cylinder(0.035, 0.035, 0.2, CATTAIL, base + lean * Vector3(0, tall + 0.05, 0), lean, 6)


## Papyrus: a few tall stems, each with a starburst of thin leaves on top.
static func _papyrus(kit: MeshKit, at: Vector3, rng: RandomNumberGenerator) -> void:
	for i in 4:
		var tall := rng.randf_range(1.5, 2.1)
		var lean := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.03, 0.15))
		var base := at + Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		kit.cylinder(0.015, 0.025, tall, REED[0], base + lean * Vector3(0, tall * 0.5, 0), lean, 5)
		var top := base + lean * Vector3(0, tall, 0)
		for k in 9:
			var fan := Basis(Vector3.UP, TAU * k / 9.0) * Basis(Vector3.RIGHT, 1.0)
			kit.box(Vector3(0.02, 0.4, 0.008), PAPYRUS, top + fan * Vector3(0, 0.2, 0), fan)
