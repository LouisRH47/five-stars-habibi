class_name InteriorMachinesB
extends RefCounted
## Session 59: more machines built from shapes (no CC0 pack has them): the Thai wok range,
## the decorated tuk-tuk, the sushi bar with its moving belt and fish case, the flat grill
## and the fryer. Like InteriorMachines, "front" is local +z, turned by facing (degrees),
## and everything stands on the floor or a counter top.

const STEEL := Color(0.72, 0.74, 0.77)
const DARK := Color(0.12, 0.12, 0.13)


static func _at(origin: Vector3, facing: float, local: Vector3) -> Vector3:
	return origin + local.rotated(Vector3.UP, deg_to_rad(facing))


## A small flame (glowing cone that wobbles) under a wok or on a grill.
static func _flame(p: InteriorParts, at: Vector3, height := 0.14, colour := Color(1.0, 0.55, 0.15)) -> void:
	var flame := Node3D.new()
	flame.position = at
	p.inside.add_child(flame)
	var cone := p.glow(Vector3.ONE, colour, Vector3.ZERO, 3.0, flame)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.11
	mesh.height = height
	mesh.radial_segments = 8
	cone.mesh = mesh
	cone.position.y = height * 0.5
	p.motion.flames.append(flame)


static func _light(p: InteriorParts, at: Vector3, colour: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = colour
	light.light_energy = energy
	light.set_meta("energy", energy)
	light.omni_range = 3.0
	p.inside.add_child(light)
	p.motion.fires.append(light)


## Tok Tok Thai: a wok range (width x 0.9 m high x 0.75 m deep) against the back wall with
## a wok over a flame on every burner. The middle wok is tossed (it bobs up and down).
static func wok_range(p: InteriorParts, origin: Vector3, width: float, woks: int) -> void:
	p.machines.append(["wok range", origin])
	p.solid(Vector3(width, 0.85, 0.75), STEEL, origin + Vector3(0, 0.425, 0))
	p.box(Vector3(width + 0.02, 0.05, 0.77), DARK, origin + Vector3(0, 0.875, 0))
	p.box(Vector3(width, 0.5, 0.04), STEEL.darkened(0.1), origin + Vector3(0, 1.15, -0.36))   # splash back
	p.counter_tops.append([Rect2(origin.x - width * 0.5, origin.z - 0.375, width, 0.75), 0.9])
	for k in woks:
		var x := origin.x - width * 0.5 + (k + 0.5) * width / woks
		var ring := Vector3(x, 0.9, origin.z + 0.05)
		p.cyl(0.16, 0.16, 0.02, DARK, ring + Vector3(0, 0.01, 0), Basis(), 12)
		_flame(p, ring + Vector3(0, 0.0, 0))
		var wok := Node3D.new()
		wok.name = "Wok"
		wok.position = ring + Vector3(0, 0.1, 0)
		wok.set_meta("rest_y", wok.position.y)
		p.inside.add_child(wok)
		var pan := LowPoly.cylinder(wok, 0.26, 0.08, 0.13, Color(0.2, 0.2, 0.22), Vector3.ZERO)
		(pan.mesh as CylinderMesh).radial_segments = 14
		LowPoly.box(wok, Vector3(0.04, 0.03, 0.35), Color(0.3, 0.2, 0.12), Vector3(0, 0.05, 0.4))
		for n in 5:
			LowPoly.sphere(wok, 0.05, 0.06, [Color(0.95, 0.8, 0.45), Color(0.85, 0.4, 0.2), Color(0.3, 0.6, 0.25)][n % 3],
					Vector3(-0.1 + n * 0.05, 0.07, (n % 2) * 0.06 - 0.03))
		if k == woks / 2:
			p.motion.knives.append(wok)   # the cook tosses this one
	_light(p, origin + Vector3(0, 1.1, 0.5), Color(1.0, 0.55, 0.25), 1.0)


## A decorated tuk-tuk (2.6 m long, 1.3 m wide, 1.8 m tall), a photo spot inside the
## restaurant. Its front looks along facing. Returns the passenger bench spot.
static func tuk_tuk(p: InteriorParts, origin: Vector3, facing: float) -> Vector3:
	p.machines.append(["tuk-tuk", origin])
	var t := Basis(Vector3.UP, deg_to_rad(facing))
	var body := p.brand
	var gold := Color(0.95, 0.75, 0.2)
	var f := func(local: Vector3) -> Vector3: return _at(origin, facing, local)
	# Wheels: one at the front, two at the back.
	for spot in [Vector3(0, 0.22, 1.05), Vector3(-0.6, 0.22, -0.8), Vector3(0.6, 0.22, -0.8)]:
		p.cyl(0.22, 0.22, 0.14, DARK, f.call(spot), t * Basis(Vector3.FORWARD, PI * 0.5), 12)
		p.cyl(0.1, 0.1, 0.15, Color(0.75, 0.75, 0.78), f.call(spot), t * Basis(Vector3.FORWARD, PI * 0.5), 8)
	# The floor, the cab's nose, the passenger bench and the roof on four posts.
	p.box(Vector3(1.25, 0.2, 2.1), body, f.call(Vector3(0, 0.42, -0.15)), t)
	p.box(Vector3(0.9, 0.75, 0.35), body, f.call(Vector3(0, 0.85, 0.95)), t)
	p.box(Vector3(0.8, 0.06, 0.3), gold, f.call(Vector3(0, 1.25, 0.95)), t)
	p.box(Vector3(0.75, 0.35, 0.03), Color(0.7, 0.85, 0.9), f.call(Vector3(0, 1.45, 0.92)), t)
	p.box(Vector3(0.7, 0.05, 0.05), Color(0.3, 0.3, 0.3), f.call(Vector3(0, 1.15, 0.76)), t)   # handlebar
	p.box(Vector3(0.5, 0.3, 0.4), DARK, f.call(Vector3(0, 0.67, 0.45)), t)                    # driver's seat
	p.box(Vector3(1.15, 0.15, 0.55), Color(0.85, 0.15, 0.2), f.call(Vector3(0, 0.6, -0.65)), t)   # the bench
	p.box(Vector3(1.15, 0.55, 0.12), Color(0.85, 0.15, 0.2), f.call(Vector3(0, 0.9, -0.95)), t)
	for x in [-0.6, 0.6]:
		for z in [-1.05, 0.75]:
			p.box(Vector3(0.05, 1.35, 0.05), gold, f.call(Vector3(x, 1.18, z)), t)
	p.box(Vector3(1.35, 0.08, 2.1), Color(0.15, 0.55, 0.3), f.call(Vector3(0, 1.88, -0.15)), t)
	for k in 8:   # colourful stripes and a garland of little balls round the roof
		p.box(Vector3(0.02, 0.18, 0.26), [gold, Color(0.2, 0.5, 0.85), Color(0.9, 0.3, 0.5), Color(0.95, 0.95, 0.9)][k % 4], f.call(Vector3(0.63, 0.42, -1.05 + k * 0.27)), t)
		p.box(Vector3(0.02, 0.18, 0.26), [gold, Color(0.2, 0.5, 0.85), Color(0.9, 0.3, 0.5), Color(0.95, 0.95, 0.9)][k % 4], f.call(Vector3(-0.63, 0.42, -1.05 + k * 0.27)), t)
		p.kit.ball(0.05, [Color(1, 0.4, 0.1), gold, Color(0.9, 0.2, 0.6)][k % 3], f.call(Vector3(0.66, 1.8, -1.05 + k * 0.26)), 1.0)
		p.kit.ball(0.05, [Color(1, 0.4, 0.1), gold, Color(0.9, 0.2, 0.6)][k % 3], f.call(Vector3(-0.66, 1.8, -1.05 + k * 0.26)), 1.0)
	var across := absf(sin(deg_to_rad(facing))) > 0.7   # turned side-on: its length runs along x
	LowPoly.solid_box(p.body, Vector3(2.6, 1.9, 1.3) if across else Vector3(1.3, 1.9, 2.6), origin + Vector3(0, 0.95, 0))
	# The sign on the roof reads from the door (+z), whichever way the tuk-tuk points.
	p.sign("التقط صورة", "Photo spot!", origin + Vector3(0, 2.15, 0), 0.0, Color.WHITE, Color(0.85, 0.15, 0.2), 22)
	return f.call(Vector3(0, 0, -0.65))


## Sushi You: the sushi bar. A ring-shaped counter (outer size `size_xz`, 1.0 m high, the
## ring 0.75 m wide) with the chefs in the well in the middle and a belt of coloured
## plates running round its top at 0.3 m/s (VenueMotion). Returns the stool spots.
static func sushi_bar(p: InteriorParts, centre: Vector3, size_xz: Vector2, plates: int) -> Array:
	p.machines.append(["sushi bar", centre])
	var height := 1.0
	var ring := 0.75
	var wood := Color(0.78, 0.62, 0.42)
	var half := size_xz * 0.5
	var sides := [
		Rect2(centre.x - half.x, centre.z + half.y - ring, size_xz.x, ring),     # front
		Rect2(centre.x - half.x, centre.z - half.y, size_xz.x, ring),            # back
		Rect2(centre.x - half.x, centre.z - half.y + ring, ring, size_xz.y - ring * 2),   # left end
		Rect2(centre.x + half.x - ring, centre.z - half.y + ring, ring, size_xz.y - ring * 2)]   # right end
	for k in sides.size():
		var rect: Rect2 = sides[k]
		if k == 3:
			rect = Rect2(rect.position.x, rect.position.y + 0.5, rect.size.x, rect.size.y - 0.5)   # a gap for the chefs
		p.counter(rect, wood.darkened(0.25), wood, height)
	# The belt: a dark band round the top, with a steel edge.
	var inset := 0.32
	var loop := Curve3D.new()
	var a := Vector2(half.x - inset, half.y - inset)
	var y := height + 0.01   # the belt lies on the bar top; the plates ride on the belt
	for corner in [Vector2(-a.x, a.y), Vector2(a.x, a.y), Vector2(a.x, -a.y), Vector2(-a.x, -a.y), Vector2(-a.x, a.y)]:
		loop.add_point(Vector3(centre.x + corner.x, height + 0.02, centre.z + corner.y))
	loop.bake_interval = 0.05
	for side in [[Vector3(size_xz.x - inset * 2 + 0.24, 0.02, 0.24), Vector3(0, y, a.y)], [Vector3(size_xz.x - inset * 2 + 0.24, 0.02, 0.24), Vector3(0, y, -a.y)],
			[Vector3(0.24, 0.02, size_xz.y - inset * 2), Vector3(-a.x, y, 0)], [Vector3(0.24, 0.02, size_xz.y - inset * 2), Vector3(a.x, y, 0)]]:
		p.box(side[0], Color(0.2, 0.2, 0.22), Vector3(centre.x, 0, centre.z) + side[1])
	p.motion.belt_path = loop
	var colours := [Color(0.9, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.95, 0.8, 0.2), Color(0.3, 0.7, 0.35), Color(0.95, 0.95, 0.92)]
	var length := loop.get_baked_length()
	for i in plates:
		var plate := Node3D.new()
		plate.name = "BeltPlate"
		plate.add_to_group("belt_plate")
		p.inside.add_child(plate)
		var dish := LowPoly.cylinder(plate, 0.1, 0.08, 0.025, colours[i % colours.size()], Vector3(0, 0.012, 0))
		(dish.mesh as CylinderMesh).radial_segments = 10
		for n in 2:
			LowPoly.cylinder(plate, 0.03, 0.03, 0.035, Color(0.12, 0.15, 0.12), Vector3(-0.035 + n * 0.07, 0.042, 0))
			LowPoly.cylinder(plate, 0.02, 0.02, 0.036, [Color(1.0, 0.55, 0.4), Color(0.98, 0.95, 0.9), Color(0.95, 0.8, 0.3)][i % 3], Vector3(-0.035 + n * 0.07, 0.043, 0))
		var along := length * i / plates
		p.motion.belt.append({"node": plate, "along": along})
		plate.position = loop.sample_baked(along)
	# The glass fish case on the chefs' side of the front counter.
	var case_at := Vector3(centre.x - 0.6, height, centre.z + half.y - ring + 0.12)
	p.box(Vector3(1.4, 0.04, 0.22), Color(0.85, 0.88, 0.9), case_at + Vector3(0, 0.02, 0))
	for k in 5:
		p.box(Vector3(0.22, 0.04, 0.12), [Color(1.0, 0.55, 0.4), Color(0.85, 0.2, 0.25), Color(0.98, 0.95, 0.9), Color(1.0, 0.6, 0.45), Color(0.9, 0.3, 0.3)][k], case_at + Vector3(-0.55 + k * 0.27, 0.06, 0))
	p.glass(Vector3(1.4, 0.18, 0.02), case_at + Vector3(0, 0.13, 0.11))
	p.glass(Vector3(1.4, 0.02, 0.22), case_at + Vector3(0, 0.22, 0))
	p.counter_tops.append([Rect2(case_at.x - 0.7, case_at.z - 0.11, 1.4, 0.22), height + 0.04])
	# Stools all round the outside.
	var stools: Array = []
	var count_x := int((size_xz.x - 0.6) / 0.7)
	for k in count_x:
		var x := centre.x - half.x + 0.3 + (k + 0.5) * (size_xz.x - 0.6) / count_x
		stools.append([Vector3(x, 0, centre.z + half.y + 0.45), 180.0])
		stools.append([Vector3(x, 0, centre.z - half.y - 0.45), 0.0])
	for k in 2:
		stools.append([Vector3(centre.x - half.x - 0.45, 0, centre.z - 0.4 + k * 0.8), 90.0])
	return stools


## A flat grill (plancha) on its steel cabinet, 1.4 x 0.9 x 0.7 m, with food sizzling on it.
## food: "patty" (burgers) or "tortilla" (tacos). Smoke rises off it.
static func flat_grill(p: InteriorParts, origin: Vector3, facing: float, food: String) -> void:
	p.machines.append(["flat grill", origin])
	var t := Basis(Vector3.UP, deg_to_rad(facing))
	p.solid(Vector3(1.4, 0.85, 0.7), STEEL, origin + Vector3(0, 0.425, 0))
	p.box(Vector3(1.38, 0.05, 0.66), Color(0.15, 0.15, 0.16), origin + Vector3(0, 0.875, 0))
	p.box(Vector3(1.4, 0.18, 0.03), STEEL, _at(origin, facing, Vector3(0, 0.98, -0.34)), t)
	p.counter_tops.append([Rect2(origin.x - 0.7, origin.z - 0.35, 1.4, 0.7), 0.9])
	for k in 6:
		var spot := _at(origin, facing, Vector3(-0.5 + (k % 3) * 0.4, 0.91, -0.12 + (k / 3) * 0.25))
		if food == "patty":
			p.cyl(0.075, 0.075, 0.025, Color(0.42, 0.24, 0.14), spot, Basis(), 10)
		else:
			p.cyl(0.11, 0.11, 0.008, Color(0.95, 0.85, 0.6), spot, Basis(), 12)
	var smoke := CPUParticles3D.new()
	smoke.name = "GrillSmoke"
	smoke.position = origin + Vector3(0, 0.95, 0)
	smoke.amount = 10
	smoke.lifetime = 2.0
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	smoke.emission_box_extents = Vector3(0.5, 0.01, 0.2)
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 10.0
	smoke.gravity = Vector3(0, 0.1, 0)
	smoke.initial_velocity_min = 0.1
	smoke.initial_velocity_max = 0.25
	smoke.scale_amount_max = 2.0
	var puff := SphereMesh.new()
	puff.radius = 0.05
	puff.height = 0.1
	var mist := StandardMaterial3D.new()
	mist.albedo_color = Color(0.9, 0.9, 0.9, 0.25)
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = mist
	smoke.mesh = puff
	p.inside.add_child(smoke)


## A two-basket fryer, 0.6 x 0.9 x 0.7 m.
static func fryer(p: InteriorParts, origin: Vector3) -> void:
	p.machines.append(["fryer", origin])
	p.solid(Vector3(0.6, 0.88, 0.7), STEEL, origin + Vector3(0, 0.44, 0))
	p.counter_tops.append([Rect2(origin.x - 0.3, origin.z - 0.35, 0.6, 0.7), 0.88])
	for dx in [-0.14, 0.14]:
		p.box(Vector3(0.24, 0.02, 0.4), Color(0.75, 0.6, 0.2), origin + Vector3(dx, 0.875, 0))
		p.box(Vector3(0.2, 0.1, 0.28), Color(0.55, 0.55, 0.57), origin + Vector3(dx, 0.92, -0.05))   # the basket, in the oil
		p.box(Vector3(0.02, 0.02, 0.25), DARK, origin + Vector3(dx, 0.96, 0.2))
