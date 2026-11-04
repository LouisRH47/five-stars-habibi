class_name InteriorMachines
extends RefCounted
## Session 58: the special machines no free pack has, built from simple shapes at real
## sizes (Appendix H) and checked against photos of real ones: the mosaic pizza dome oven,
## the gelato case, the two-group espresso machine and its grinders, the pastry case, the
## shawarma spit and the stone manakish oven. Each sits on the floor or on a counter top,
## never in the air. "front" is the side customers see: local +z, turned by facing (degrees).

const STEEL := Color(0.72, 0.74, 0.77)
const DARK := Color(0.12, 0.12, 0.13)
const FIRE := Color(1.0, 0.45, 0.1)
const BRICK := Color(0.62, 0.3, 0.2)
const STONE := Color(0.76, 0.69, 0.58)


## Turns a spot on the machine into a spot in the room.
static func _at(origin: Vector3, facing: float, local: Vector3) -> Vector3:
	return origin + local.rotated(Vector3.UP, deg_to_rad(facing))


static func _turn(facing: float) -> Basis:
	return Basis(Vector3.UP, deg_to_rad(facing))


## Fire in an oven mouth: a glowing back, three flames that wobble and a flickering light.
static func _fire(p: InteriorParts, origin: Vector3, facing: float, mouth: Vector3, width: float, height: float) -> void:
	p.glow(Vector3(width, height, 0.04), FIRE, _at(origin, facing, mouth + Vector3(0, 0, -0.25)), 2.2).basis = _turn(facing)
	for k in 3:
		var flame := Node3D.new()
		flame.position = _at(origin, facing, mouth + Vector3((k - 1) * width * 0.28, -height * 0.5, -0.18))
		p.body.add_child(flame)
		var cone := p.glow(Vector3.ONE, Color(1.0, 0.7, 0.2), Vector3.ZERO, 3.0, flame)
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = width * 0.12
		mesh.height = height * 0.8
		mesh.radial_segments = 6
		cone.mesh = mesh
		cone.position.y = height * 0.4
		p.motion.flames.append(flame)
	var light := OmniLight3D.new()
	light.name = "FireGlow"
	light.position = _at(origin, facing, mouth + Vector3(0, 0, 0.3))
	light.light_color = Color(1.0, 0.55, 0.25)
	light.light_energy = 1.4
	light.set_meta("energy", 1.4)
	light.omni_range = 3.2
	p.inside.add_child(light)
	p.motion.fires.append(light)
	var embers := CPUParticles3D.new()
	embers.name = "Embers"
	embers.position = _at(origin, facing, mouth + Vector3(0, -height * 0.3, -0.1))
	embers.amount = 10
	embers.lifetime = 1.4
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3(width * 0.3, 0.02, 0.05)
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 20.0
	embers.gravity = Vector3(0, 0.3, 0)
	embers.initial_velocity_min = 0.1
	embers.initial_velocity_max = 0.3
	embers.scale_amount_min = 0.5
	var dot := SphereMesh.new()
	dot.radius = 0.012
	dot.height = 0.024
	var hot := StandardMaterial3D.new()
	hot.emission_enabled = true
	hot.emission = Color(1, 0.6, 0.2)
	hot.albedo_color = Color(1, 0.6, 0.2)
	dot.material = hot
	embers.mesh = dot
	p.inside.add_child(embers)


## 1000 Pizza: a round dome oven 1.6 m across and 1.8 m tall, covered in small red and
## gold mosaic tiles, on a brick base with logs stacked underneath, an arched mouth
## (0.6 x 0.35 m) with fire inside, and a chimney pipe up to the ceiling.
static func pizza_oven(p: InteriorParts, origin: Vector3, facing: float) -> void:
	p.machines.append(["pizza oven", origin])
	var t := _turn(facing)
	# A round brick base with a stone rim, and logs stacked in front of it.
	p.cyl(0.8, 0.8, 0.9, BRICK, origin + Vector3(0, 0.45, 0), Basis(), 16)
	LowPoly.solid_cylinder(p.body, 0.8, 1.8, origin + Vector3(0, 0.9, 0))
	p.cyl(0.84, 0.84, 0.08, STONE, origin + Vector3(0, 0.92, 0), Basis(), 16)
	for row in 3:
		for k in 4 - row:
			p.cyl(0.07, 0.07, 0.32, Color(0.45, 0.3, 0.18), _at(origin, facing, Vector3(-0.24 + k * 0.16 + row * 0.08, 0.07 + row * 0.13, 0.95)), t * Basis(Vector3.RIGHT, PI * 0.5), 6)
	# The dome: a half ball, then the mosaic tiles on it.
	var centre := origin + Vector3(0, 0.96, 0)
	p.kit.ball(0.78, Color(0.75, 0.2, 0.16), centre, 1.08)
	for ring in 7:
		var up := (ring + 0.5) / 7.0 * PI * 0.5
		var around := maxi(6, int(26 * cos(up)))
		for k in around:
			var a := TAU * (k + (ring % 2) * 0.5) / around
			var out := Vector3(cos(a) * cos(up), sin(up) * 1.08, sin(a) * cos(up)).normalized()
			var gold := (k + ring) % 3 == 0
			var tile_at := centre + Vector3(cos(a) * cos(up) * 0.8, sin(up) * 0.86, sin(a) * cos(up) * 0.8)
			p.box(Vector3(0.11, 0.11, 0.02), Color(0.95, 0.75, 0.25) if gold else Color(0.82, 0.16, 0.14), tile_at, Basis.looking_at(-out, Vector3.UP if absf(out.y) < 0.95 else Vector3.FORWARD))
	# The arched mouth, a stone frame round it, and the fire inside.
	var mouth := Vector3(0, 1.15, 0.72)
	p.box(Vector3(0.86, 0.5, 0.24), STONE, _at(origin, facing, mouth + Vector3(0, 0.0, 0.0)), t)
	p.box(Vector3(0.6, 0.35, 0.26), Color(0.05, 0.03, 0.02), _at(origin, facing, mouth + Vector3(0, -0.05, 0.01)), t)
	p.cyl(0.3, 0.3, 0.26, Color(0.05, 0.03, 0.02), _at(origin, facing, mouth + Vector3(0, 0.12, 0.01)), t * Basis(Vector3.RIGHT, PI * 0.5), 10)
	_fire(p, origin, facing, mouth + Vector3(0, -0.05, 0.1), 0.5, 0.28)
	# The chimney pipe from the top of the dome to the ceiling.
	var top := 0.96 + 0.86
	p.cyl(0.12, 0.12, p.size.y - top, STEEL, origin + Vector3(0, top + (p.size.y - top) * 0.5, 0), Basis(), 10)
	p.counter_tops.append([Rect2(origin.x - 0.8, origin.z - 0.8, 1.6, 1.6), 0.96])


## Brain Freeze: the curved glass gelato case, 3 m long, 1 m deep, 1.2 m tall, with 12 tubs
## in 2 rows and a little flavour tag in front of each (Appendix B).
static func gelato_case(p: InteriorParts, origin: Vector3, facing: float, flavours: Array) -> void:
	p.machines.append(["gelato case", origin])
	var t := _turn(facing)
	p.box(Vector3(3.0, 0.85, 1.0), Color(0.97, 0.95, 0.95), origin + Vector3(0, 0.425, 0))
	LowPoly.solid_box(p.body, Vector3(3.0, 1.2, 0.85), _at(origin, facing, Vector3(0, 0.6, -0.08)))
	p.box(Vector3(3.02, 0.55, 0.03), p.brand, _at(origin, facing, Vector3(0, 0.45, 0.51)), t)
	for k in 6:
		p.box(Vector3(0.36, 0.08, 0.02), Color(1, 1, 1), _at(origin, facing, Vector3(-1.25 + k * 0.5, 0.2, 0.53)), t)
	p.box(Vector3(2.9, 0.04, 0.9), Color(0.75, 0.8, 0.85), origin + Vector3(0, 0.86, 0))
	var colours := [Color(0.6, 0.8, 0.35), Color(1.0, 0.72, 0.2), Color(0.4, 0.24, 0.14), Color(0.95, 0.45, 0.55),
			Color(0.98, 0.94, 0.8), Color(0.98, 0.95, 0.5), Color(0.75, 0.7, 0.62), Color(0.85, 0.6, 0.3),
			Color(0.97, 0.97, 0.95), Color(0.65, 0.92, 0.75), Color(0.5, 0.45, 0.8), Color(0.55, 0.38, 0.22)]
	for i in 12:
		var row := i / 6
		var k := i % 6
		var spot := Vector3(-1.2 + k * 0.48, 0.92, 0.18 - row * 0.4)
		p.box(Vector3(0.42, 0.1, 0.32), STEEL, _at(origin, facing, spot), t)
		p.kit.ball(0.17, colours[i], _at(origin, facing, spot + Vector3(0, 0.08, 0)), 0.55)
		var tag := SignText.make_label(str(flavours[i]), 9, Color(0.15, 0.15, 0.18), Color(0, 0, 0, 0), 0)
		tag.position = _at(origin, facing, spot + Vector3(0, 0.0, 0.17 + (0.4 if row == 1 else 0.0) * 0.0) + Vector3(0, 0.08, 0.0))
		tag.rotation.y = deg_to_rad(facing)
		tag.rotation.x = -0.5
		tag.name = "FlavourTag"
		tag.add_to_group("flavour_tag")
		var card := Vector3(0, 0.98, 0.37) if row == 0 else Vector3(0, 0.98, -0.03)
		if row == 1 and GameConfig.INTERIOR_REVIEW_FIXES:
			# Review fix: the back row's tags were hidden behind the front row's gelato. Now
			# they stand on little picks in the back tubs, above the front row (under the glass top).
			card = Vector3(0, 1.13, -0.07)
			p.box(Vector3(0.012, 0.1, 0.012), Color(0.85, 0.85, 0.85), _at(origin, facing, Vector3(spot.x, 1.06, -0.09)), t)
		tag.position = _at(origin, facing, Vector3(spot.x, card.y + 0.02, card.z + 0.012))
		p.box(Vector3(0.36, 0.08, 0.01), Color.WHITE, _at(origin, facing, Vector3(spot.x, card.y, card.z)), t * Basis(Vector3.RIGHT, -0.5))
		p.body.add_child(tag)
	# The curved glass front (two sloped panes) and a glass top shelf.
	p.glass(Vector3(3.0, 0.32, 0.02), _at(origin, facing, Vector3(0, 0.98, 0.49)), t)
	p.glass(Vector3(3.0, 0.02, 0.6), _at(origin, facing, Vector3(0, 1.2, 0.2)), t * Basis(Vector3.RIGHT, 0.0))
	p.glass(Vector3(3.0, 0.3, 0.02), _at(origin, facing, Vector3(0, 1.08, 0.42)), t * Basis(Vector3.RIGHT, -0.6))
	for x in [-1.5, 1.5]:
		p.box(Vector3(0.04, 0.35, 0.6), STEEL, _at(origin, facing, Vector3(x, 1.03, 0.2)), t)
	p.counter_tops.append([Rect2(origin.x - 1.5, origin.z - 0.5, 3.0, 1.0).abs(), 1.21])


## Spill the Brew: a two-group espresso machine (0.75 wide, 0.55 deep, 0.5 tall), chrome
## with red sides, on the counter top at `top`. The group heads and steam wands face the
## barista (local -z); the side the customers see has the logo plate. Cups on the warmer.
static func espresso_machine(p: InteriorParts, top: Vector3, facing: float) -> void:
	p.machines.append(["espresso machine", top])
	var t := _turn(facing)
	var red := Color(0.78, 0.12, 0.12)
	p.box(Vector3(0.75, 0.04, 0.55), DARK, top + Vector3(0, 0.02, 0))
	p.box(Vector3(0.65, 0.42, 0.5), STEEL, top + Vector3(0, 0.25, 0))
	for x in [-0.36, 0.36]:
		p.box(Vector3(0.04, 0.44, 0.54), red, _at(top, facing, Vector3(x, 0.25, 0)), t)
	p.box(Vector3(0.72, 0.04, 0.52), Color(0.85, 0.86, 0.88), top + Vector3(0, 0.48, 0))
	p.box(Vector3(0.4, 0.12, 0.01), red, _at(top, facing, Vector3(0, 0.3, 0.255)), t)
	# Barista side: two group heads with handles (portafilters), a drip tray and two gauges.
	for x in [-0.17, 0.17]:
		p.cyl(0.05, 0.05, 0.07, STEEL, _at(top, facing, Vector3(x, 0.22, -0.28)), t, 8)
		p.box(Vector3(0.03, 0.03, 0.16), DARK, _at(top, facing, Vector3(x, 0.17, -0.36)), t)
		p.cyl(0.05, 0.04, 0.04, STEEL, _at(top, facing, Vector3(x, 0.17, -0.28)), t, 8)
		p.cyl(0.04, 0.035, 0.07, Color.WHITE, _at(top, facing, Vector3(x, 0.08, -0.29)), t, 8)
		p.cyl(0.04, 0.04, 0.02, Color.WHITE, _at(top, facing, Vector3(x, 0.38, -0.26)), t * Basis(Vector3.RIGHT, PI * 0.5), 8)
	p.box(Vector3(0.6, 0.03, 0.14), DARK, _at(top, facing, Vector3(0, 0.05, -0.3)), t)
	for x in [-0.3, 0.3]:
		p.cyl(0.008, 0.008, 0.22, STEEL, _at(top, facing, Vector3(x, 0.2, -0.3)), t * Basis(Vector3.RIGHT, 0.25), 6)
	# Cups stacked upside down on the cup warmer.
	for row in 2:
		for k in 5:
			p.cyl(0.035, 0.03, 0.06, Color.WHITE, top + _turn(facing) * Vector3(-0.24 + k * 0.12, 0.53 + row * 0.06, -0.08 + row * 0.12), Basis(), 8)
	var steam := CPUParticles3D.new()
	steam.name = "Steam"
	steam.position = _at(top, facing, Vector3(0.3, 0.12, -0.32))
	steam.amount = 8
	steam.lifetime = 1.6
	steam.direction = Vector3(0, 1, 0)
	steam.spread = 15.0
	steam.gravity = Vector3(0, 0.15, 0)
	steam.initial_velocity_min = 0.15
	steam.initial_velocity_max = 0.3
	steam.scale_amount_min = 0.6
	steam.scale_amount_max = 1.6
	var puff := SphereMesh.new()
	puff.radius = 0.04
	puff.height = 0.08
	var mist := StandardMaterial3D.new()
	mist.albedo_color = Color(1, 1, 1, 0.35)
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = mist
	steam.mesh = puff
	p.inside.add_child(steam)


## A coffee grinder (0.2 wide, 0.6 tall) on the counter top, with a hopper of beans.
static func grinder(p: InteriorParts, top: Vector3, facing: float) -> void:
	p.machines.append(["grinder", top])
	var t := _turn(facing)
	p.box(Vector3(0.2, 0.06, 0.26), DARK, top + Vector3(0, 0.03, 0))
	p.box(Vector3(0.16, 0.3, 0.2), Color(0.2, 0.2, 0.22), top + Vector3(0, 0.21, 0))
	p.box(Vector3(0.05, 0.07, 0.08), STEEL, _at(top, facing, Vector3(0, 0.12, -0.12)), t)
	p.cyl(0.09, 0.05, 0.22, Color(0.82, 0.86, 0.9), top + Vector3(0, 0.47, 0), Basis(), 10)
	p.cyl(0.07, 0.04, 0.12, Color(0.32, 0.2, 0.12), top + Vector3(0, 0.43, 0), Basis(), 10)
	p.cyl(0.095, 0.095, 0.02, DARK, top + Vector3(0, 0.59, 0), Basis(), 10)


## A glass pastry case on the counter (1.2 wide, 0.6 deep, 0.5 tall) with croissants and
## cookies on the bottom shelf and 3 cakes on stands on the top.
static func pastry_case(p: InteriorParts, top: Vector3, facing: float) -> void:
	p.machines.append(["pastry case", top])
	var t := _turn(facing)
	p.box(Vector3(1.2, 0.06, 0.6), Color(0.4, 0.27, 0.17), top + Vector3(0, 0.03, 0))
	p.box(Vector3(1.16, 0.02, 0.56), Color(0.9, 0.9, 0.92), top + Vector3(0, 0.27, 0))
	p.box(Vector3(1.2, 0.03, 0.6), Color(0.4, 0.27, 0.17), top + Vector3(0, 0.5, 0))
	p.glass(Vector3(1.2, 0.42, 0.02), _at(top, facing, Vector3(0, 0.28, 0.29)), t)
	for x in [-0.59, 0.59]:
		p.glass(Vector3(0.02, 0.42, 0.58), _at(top, facing, Vector3(x, 0.28, 0)), t)
	p.counter_tops.append([Rect2(top.x - 0.6, top.z - 0.6, 1.2, 1.2), top.y + 0.06])
	p.counter_tops.append([Rect2(top.x - 0.6, top.z - 0.6, 1.2, 1.2), top.y + 0.28])
	var lower := top + Vector3(0, 0.06, 0)
	for k in 4:
		p.prop("kenney_food/croissant", _at(lower, facing, Vector3(-0.45 + k * 0.13, 0, 0.1)) - Vector3(0, GameConfig.KIT_COUNTER_HEIGHT, 0), facing + 90.0, "counter")
	for k in 5:
		p.cyl(0.045, 0.045, 0.015, Color(0.72, 0.5, 0.28), _at(lower, facing, Vector3(0.15 + k * 0.09, 0.008, 0.12)), t, 8)
		p.cyl(0.045, 0.045, 0.015, Color(0.55, 0.35, 0.2), _at(lower, facing, Vector3(0.15 + k * 0.09, 0.008, -0.06)), t, 8)
	var upper := top + Vector3(0, 0.28, 0)
	for k in 3:
		var stand := _at(upper, facing, Vector3(-0.38 + k * 0.38, 0, 0))
		p.cyl(0.03, 0.03, 0.05, Color(0.92, 0.92, 0.94), stand + Vector3(0, 0.025, 0), Basis(), 8)
		p.cyl(0.13, 0.13, 0.01, Color(0.92, 0.92, 0.94), stand + Vector3(0, 0.055, 0), Basis(), 12)
		p.counter_tops.append([Rect2(stand.x - 0.13, stand.z - 0.13, 0.26, 0.26), stand.y + 0.06])
		p.prop("kenney_food/cake", stand + Vector3(0, 0.06 - GameConfig.KIT_COUNTER_HEIGHT, 0), facing, "counter")


## Shawarma Supreme: one vertical spit, 0.4 m across the meat and 1 m tall, on a 0.9 m steel
## stand, with the glowing heater behind it. The meat turns (VenueMotion).
static func shawarma_spit(p: InteriorParts, origin: Vector3, facing: float, chicken: bool) -> void:
	p.machines.append(["shawarma spit", origin])
	var t := _turn(facing)
	p.solid(Vector3(0.7, 0.9, 0.6), STEEL, origin + Vector3(0, 0.45, 0))
	p.box(Vector3(0.66, 0.04, 0.5), DARK, origin + Vector3(0, 0.92, 0))
	p.counter_tops.append([Rect2(origin.x - 0.35, origin.z - 0.35, 0.7, 0.7), 0.9])
	p.box(Vector3(0.62, 1.15, 0.12), Color(0.3, 0.3, 0.32), _at(origin, facing, Vector3(0, 1.5, -0.27)), t)
	p.glow(Vector3(0.5, 1.0, 0.02), Color(1.0, 0.35, 0.12), _at(origin, facing, Vector3(0, 1.48, -0.2)), 2.0).basis = t
	p.cyl(0.015, 0.015, 1.25, STEEL, origin + Vector3(0, 1.55, 0), Basis(), 6)
	p.cyl(0.12, 0.12, 0.03, STEEL, origin + Vector3(0, 2.07, 0), Basis(), 10)
	var meat := Node3D.new()
	meat.name = "Spit"
	meat.position = origin + Vector3(0, 1.45, 0)
	p.inside.add_child(meat)
	var colour := Color(0.82, 0.55, 0.25) if chicken else Color(0.5, 0.26, 0.13)
	var cone := LowPoly.cylinder(meat, 0.2, 0.14, 1.0, colour, Vector3.ZERO)
	(cone.mesh as CylinderMesh).radial_segments = 9
	for k in 4:
		LowPoly.box(meat, Vector3(0.05, 0.9, 0.06), colour.darkened(0.25), Vector3(0.17, 0, 0).rotated(Vector3.UP, k * TAU / 4.0))
	p.motion.spits.append(meat)


## Bread & Zaatar: the arched stone manakish oven, 2.2 m wide, 1.6 m tall, with a wide low
## mouth (1.2 x 0.3 m) and fire glow, and a copper hood up to the ceiling. It is 1 m deep
## here (real ones are about 1.4 m) so the baker has room in front of it in our 2 m kitchen.
static func manakish_oven(p: InteriorParts, origin: Vector3, facing: float, depth := 1.0) -> void:
	p.machines.append(["manakish oven", origin])
	var t := _turn(facing)
	var f := depth * 0.5
	p.solid(Vector3(2.2, 1.5, depth), STONE, origin + Vector3(0, 0.75, 0))
	# The arched top: a half cylinder (squashed) across the front.
	p.cyl(0.3, 1.1, 0.35, STONE.darkened(0.08), origin + Vector3(0, 1.67, 0), Basis(), 14)
	# Stone blocks on the front, in two colours, leaving the mouth open.
	for row in 5:
		for k in 6:
			if row in [2, 3] and k in [1, 2, 3, 4]:
				continue  # the mouth
			var shade := STONE.darkened(0.12 if (row + k) % 2 == 0 else 0.0).lerp(Color(0.85, 0.75, 0.6), 0.2)
			p.box(Vector3(0.34, 0.27, 0.03), shade, _at(origin, facing, Vector3(-0.92 + k * 0.37 + (row % 2) * 0.08, 0.16 + row * 0.29, f + 0.015)), t)
	var mouth := Vector3(0, 0.88, f + 0.01)
	p.box(Vector3(1.3, 0.06, 0.24), Color(0.55, 0.5, 0.45), _at(origin, facing, mouth + Vector3(0, -0.2, 0.1)), t)
	p.box(Vector3(1.2, 0.3, 0.04), Color(0.05, 0.03, 0.02), _at(origin, facing, mouth), t)
	_fire(p, origin, facing, mouth + Vector3(0, 0.0, 0.04), 1.0, 0.24)
	for k in 3:
		p.cyl(0.14, 0.14, 0.015, Color(0.88, 0.7, 0.42), _at(origin, facing, mouth + Vector3(-0.35 + k * 0.35, -0.13, -0.12)), t, 10)
	# The copper hood and its flue up to the ceiling.
	var hood_y := 2.3
	p.box(Vector3(2.0, 0.5, depth * 0.9), Color(0.72, 0.45, 0.25), _at(origin, facing, Vector3(0, hood_y, 0.05)), t)
	var flue := p.size.y - origin.y - hood_y - 0.25
	p.cyl(0.18, 0.18, flue, Color(0.72, 0.45, 0.25), origin + Vector3(0, hood_y + 0.25 + flue * 0.5, 0), Basis(), 10)


## A long peel (pizza or bread) that the cook slides into the oven now and then.
## rest: where it lies on the prep side; reach: where it goes in the oven.
static func peel(p: InteriorParts, rest: Vector3, reach: Vector3, facing: float, food_colour: Color, round := true, handle_length := 1.4) -> void:
	var holder := Node3D.new()
	holder.name = "Peel"
	holder.position = rest
	p.inside.add_child(holder)
	var t := _turn(facing)
	var head := LowPoly.box(holder, Vector3(0.36, 0.015, 0.36), Color(0.75, 0.6, 0.4), Vector3.ZERO)
	head.basis = t
	var handle := LowPoly.cylinder(holder, 0.015, 0.015, handle_length, Color(0.6, 0.45, 0.3), t * Vector3(0, 0, 0.15 + handle_length * 0.5))
	handle.basis = t * Basis(Vector3.RIGHT, PI * 0.5)
	var food := LowPoly.cylinder(holder, 0.15, 0.15, 0.02, food_colour, Vector3(0, 0.018, 0))
	if not round:
		food.scale = Vector3(1.2, 1, 0.8)
	p.motion.peels.append({"node": holder, "from": rest, "to": reach, "every": GameConfig.PIZZA_PEEL_EVERY, "offset": float(p.seats)})
