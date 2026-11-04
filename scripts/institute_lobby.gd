class_name InstituteLobby
## Session 61: the C Institute lobby (the PRD's approved design). In the building's own
## directions +z is the front (it faces the spine, east) and -z the back:
##   - two storeys tall, glass on both long sides so you see right through
##   - a balcony walkway along the back at 5 m with a glass railing, and a staircase up to it
##   - wide wooden stepped seats with cushions, people on laptops, all facing the talk
##     screen, which changes during the shift (scripts/institute_screen.gd)
##   - hanging plants, a wood-slat ceiling
##   - a curved white reception desk in front of a big "C" logo wall (the drop-off)

const CREAM := Color(0.95, 0.92, 0.86)
const WHITE := Color(0.98, 0.98, 0.97)
const TEAL := Color(0.16, 0.56, 0.61)
const WOOD := Color(0.72, 0.52, 0.32)
const DARK := Color(0.12, 0.13, 0.15)
const STONE := Color(0.86, 0.83, 0.77)
const GLASS := Color(0.46, 0.7, 0.77)
const CUSHIONS := [Color(0.95, 0.55, 0.3), TEAL, Color(0.95, 0.8, 0.3), Color(0.55, 0.35, 0.6)]
const BALCONY_Y := 5.0
const BALCONY_DEPTH := 3.6
const TIERS := 4
const TIER_RISE := 0.45
const TIER_DEPTH := 1.4


## Builds it. place: the VILLAS entry. size: 46 x 14 x 36.
static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", "institute")
	body.set_meta("lobby", true)
	_shell(body, place, size)
	var counter: Vector3 = place.get("counter", VenueBuilder.counter_local(size))
	_reception(body, counter, place)
	_balcony(body, size)
	_talk_area(body, size)
	_ceiling(body, size)
	return body


## Floor, cream end walls, glass front and back (a doorway in the front), roof, signs, lights.
static func _shell(body: StaticBody3D, place: Dictionary, size: Vector3) -> void:
	var half := size * 0.5
	LowPoly.box(body, Vector3(size.x, 0.06, size.z), STONE, Vector3(0, 0.03, 0))
	for side in [-1.0, 1.0]:
		_solid(body, Vector3(0.3, size.y, size.z), Vector3(side * half.x, half.y, 0), CREAM)
	for z in [-half.z, half.z]:
		var door := 4.0 if z > 0 else 0.0
		for side in [-1.0, 1.0]:
			var wing := half.x - door * 0.5
			var pane := _solid(body, Vector3(wing, size.y, 0.2), Vector3(side * (door * 0.5 + wing * 0.5), half.y, z), GLASS)
			pane.name = "FrontGlass" if z > 0 else "BackGlass"
			pane.material_override = _clear()
			pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 12:   # white mullions and the floor line of the upper storey
			var x := -half.x + (i + 0.5) * size.x / 12.0
			if absf(x) > 2.3:
				LowPoly.box(body, Vector3(0.14, size.y, 0.26), WHITE, Vector3(x, half.y, z))
		LowPoly.box(body, Vector3(size.x, 0.35, 0.3), WHITE, Vector3(0, BALCONY_Y, z))
	# Above the doorway: solid band with the bilingual name, and a canopy over the door.
	LowPoly.box(body, Vector3(4.2, size.y - 3.4, 0.3), CREAM, Vector3(0, 3.4 + (size.y - 3.4) * 0.5, half.z))
	for x in [-2.1, 2.1]:
		LowPoly.box(body, Vector3(0.2, 3.4, 0.35), DARK, Vector3(x, 1.7, half.z))
	for x in [-3.0, 3.0]:   # the sliding doors, open
		var slide := LowPoly.box(body, Vector3(2.0, 3.2, 0.06), GLASS, Vector3(x, 1.6, half.z - 0.35))
		slide.material_override = _clear()
	LowPoly.box(body, Vector3(10.0, 0.25, 3.0), TEAL, Vector3(0, 3.6, half.z + 1.4))
	LowPoly.box(body, Vector3(size.x + 0.4, 0.4, size.z + 0.4), WHITE, Vector3(0, size.y + 0.2, 0))
	for z in [half.z + 0.25, -half.z - 0.25]:
		var font := SignText.fit_size(place.get("arabic", ""), place.get("name", "C Institute"), 90, 14.0)
		var sign := SignText.make_face(place.get("arabic", ""), place.get("name", "C Institute"), font, Color.WHITE, TEAL, 8)
		sign.name = "BilingualSign"
		sign.position = Vector3(0, size.y - 2.2, z)
		sign.rotation.y = 0.0 if z > 0 else PI
		body.add_child(sign, true)
	for i in 3:
		var light := OmniLight3D.new()
		light.name = "LobbyLight"
		light.position = Vector3(-14 + i * 14, 9.0, 0)
		light.light_color = Color(1.0, 0.92, 0.8)
		light.light_energy = 2.2
		light.omni_range = 18.0
		light.shadow_enabled = false
		body.add_child(light, true)


## The curved white reception desk (you stand at `counter`), the staff member and the logo wall.
static func _reception(body: StaticBody3D, counter: Vector3, place: Dictionary) -> void:
	var desk_z := counter.z - 1.2
	var radius := 2.6
	for i in 9:   # pieces round a circle, each turned along it, so they join into one curve
		var a := deg_to_rad(-60.0 + i * 15.0)
		var at := Vector3(sin(a) * radius, 0.55, desk_z - radius + cos(a) * radius)
		var piece := LowPoly.box(body, Vector3(0.76, 1.1, 0.5), WHITE, at)
		piece.rotation.y = a
		piece.name = "ReceptionDesk"
		var solid := LowPoly.solid_box(body, Vector3(0.76, 1.1, 0.5), at)
		solid.rotation.y = a
		var top := LowPoly.box(body, Vector3(0.8, 0.05, 0.62), WOOD, at + Vector3(0, 0.575, 0))
		top.rotation.y = a
	var staff := PeopleLooks.teacher()
	staff.name = "CounterStaff"
	staff.position = Vector3(0, 0, desk_z - 1.4)
	staff.rotation.y = PI
	body.add_child(staff, true)
	# The logo wall: a white wall with a big teal "C" ring and the name.
	var wall_z := desk_z - 3.4
	var logo_wall := _solid(body, Vector3(8.0, 4.6, 0.4), Vector3(0, 2.3, wall_z), WHITE)
	logo_wall.name = "LogoWall"
	for i in 18:
		var a := deg_to_rad(45.0 + i * 15.0)   # a ring with a gap on the right: a "C"
		var piece := LowPoly.box(body, Vector3(0.38, 0.42, 0.12), TEAL, Vector3(cos(a) * 1.3, 2.9 + sin(a) * 1.3, wall_z + 0.25))
		piece.rotation.z = a + PI * 0.5
		piece.name = "LogoC"
	var name := SignText.make_face(place.get("arabic", ""), place.get("name", "C Institute"), 64, DARK)
	name.position = Vector3(0, 1.0, wall_z + 0.22)
	body.add_child(name, true)
	# Two lounge corners in the open lobby: low sofas round a coffee table, and big plants.
	for corner in [Vector3(7.0, 0, 1.0), Vector3(12.0, 0, -7.0)]:
		_lounge(body, corner)
	for at in [Vector3(-3.0, 0, 15.5), Vector3(16.0, 0, 15.5), Vector3(4.0, 0, -12.0)]:
		LowPoly.cylinder(body, 0.5, 0.4, 0.8, WHITE, at + Vector3.UP * 0.4)
		LowPoly.sphere(body, 0.8, 2.0, Color(0.28, 0.55, 0.26), at + Vector3.UP * 1.7)
		LowPoly.solid_cylinder(body, 0.5, 0.8, at + Vector3.UP * 0.4)


## Low sofas on three sides of a round coffee table, with one person on a laptop.
static func _lounge(body: StaticBody3D, at: Vector3) -> void:
	LowPoly.cylinder(body, 0.6, 0.6, 0.06, WOOD, at + Vector3(0, 0.42, 0))
	LowPoly.cylinder(body, 0.08, 0.1, 0.4, DARK, at + Vector3(0, 0.2, 0))
	for k in 3:
		var a := k * PI * 0.5 - PI * 0.5
		var seat := at + Vector3(cos(a) * 1.5, 0, sin(a) * 1.5)
		var sofa := LowPoly.box(body, Vector3(2.0, 0.42, 0.85), Color(0.3, 0.42, 0.5), seat + Vector3(0, 0.21, 0))
		sofa.rotation.y = -a + PI * 0.5
		var solid := LowPoly.solid_box(body, Vector3(2.0, 0.42, 0.85), seat + Vector3(0, 0.21, 0))
		solid.rotation.y = -a + PI * 0.5
		var back := LowPoly.box(body, Vector3(2.0, 0.45, 0.2), Color(0.25, 0.36, 0.44), seat + Vector3(cos(a) * 0.38, 0.62, sin(a) * 0.38))
		back.rotation.y = -a + PI * 0.5
	var reader := PeopleLooks.resident(2, 1)
	reader.name = "LoungeReader"
	reader.position = at + Vector3(0, 0.46 - reader.spot("Hips").y + 0.05, -1.45)
	reader.rotation.y = PI   # faces the coffee table
	body.add_child(reader, true)
	reader.play("laptop")


## The balcony walkway along the back glass at 5 m, its glass railing, and the stairs up.
static func _balcony(body: StaticBody3D, size: Vector3) -> void:
	var half := size * 0.5
	var edge := -half.z + BALCONY_DEPTH
	LowPoly.box(body, Vector3(size.x - 0.4, 0.3, BALCONY_DEPTH), WHITE, Vector3(0, BALCONY_Y, -half.z + BALCONY_DEPTH * 0.5))
	LowPoly.box(body, Vector3(size.x - 0.4, 0.04, BALCONY_DEPTH - 0.1), WOOD, Vector3(0, BALCONY_Y + 0.17, -half.z + BALCONY_DEPTH * 0.5))
	var rail := LowPoly.box(body, Vector3(size.x - 0.4, 1.0, 0.04), GLASS, Vector3(0, BALCONY_Y + 0.7, edge))
	rail.material_override = _clear()
	rail.name = "GlassRailing"
	LowPoly.box(body, Vector3(size.x - 0.4, 0.06, 0.08), Color(0.75, 0.77, 0.8), Vector3(0, BALCONY_Y + 1.22, edge))
	for i in 6:   # slim columns holding it up
		var x := -half.x + 4.0 + i * (size.x - 8.0) / 5.0
		_solid(body, Vector3(0.3, BALCONY_Y, 0.3), Vector3(x, BALCONY_Y * 0.5, edge - 0.3), WHITE)
	# The staircase against the side wall, rising towards the balcony.
	var steps := 26
	var bottom_z := edge + 10.0
	for i in steps:
		var rise := BALCONY_Y * (i + 1) / steps
		var z := bottom_z - (i + 0.5) * (bottom_z - edge) / steps
		LowPoly.box(body, Vector3(1.8, rise, (bottom_z - edge) / steps + 0.01), WHITE if i % 2 == 0 else Color(0.94, 0.94, 0.93),
				Vector3(half.x - 1.1, rise * 0.5, z))
		LowPoly.box(body, Vector3(1.8, 0.04, (bottom_z - edge) / steps), WOOD, Vector3(half.x - 1.1, rise + 0.02, z))
	LowPoly.solid_box(body, Vector3(1.8, BALCONY_Y, bottom_z - edge), Vector3(half.x - 1.1, BALCONY_Y * 0.5, (bottom_z + edge) * 0.5))
	var stair_rail := LowPoly.box(body, Vector3(0.04, 1.0, bottom_z - edge + 1.0), GLASS, Vector3(half.x - 2.05, 0, (bottom_z + edge) * 0.5))
	stair_rail.material_override = _clear()
	stair_rail.rotation.x = atan2(BALCONY_Y, bottom_z - edge)
	stair_rail.position.y = BALCONY_Y * 0.5 + 0.9
	# Someone on the balcony looking down at the talk.
	var watcher := PeopleLooks.resident(2, 2)
	watcher.name = "BalconyVisitor"
	watcher.position = Vector3(-10.0, BALCONY_Y + 0.19, edge - 0.6)
	watcher.rotation.y = PI * 0.75
	body.add_child(watcher, true)


## The stepped wooden seats with cushions and people on laptops, facing the talk screen.
static func _talk_area(body: StaticBody3D, size: Vector3) -> void:
	var half := size * 0.5
	var screen_x := -half.x + 0.25
	var first := -half.x + 7.0          # the lowest step, nearest the screen
	var length := 13.0
	var middle_z := -1.5
	for i in TIERS:
		var x := first + (i + 0.5) * TIER_DEPTH
		var top := TIER_RISE * (i + 1)
		var tier := _solid(body, Vector3(TIER_DEPTH, top, length), Vector3(x, top * 0.5, middle_z), WOOD)
		tier.name = "SteppedSeat"
		LowPoly.box(body, Vector3(0.04, 0.02, length), WOOD.darkened(0.25), Vector3(x - TIER_DEPTH * 0.5, top + 0.005, middle_z))
		for c in 5:
			var cushion := Vector3(x + 0.1, top + 0.05, middle_z - length * 0.5 + 1.3 + c * 2.6)
			LowPoly.box(body, Vector3(0.75, 0.1, 0.75), CUSHIONS[(i + c) % CUSHIONS.size()], cushion)
			if (i + c) % 3 == 0 and i < 3:
				_laptop_person(body, cushion + Vector3(0, 0.05, 0), i * 5 + c)
	# The talk screen on the end wall, with the speaker's little stage in front of it.
	var screen := Node3D.new()
	screen.name = "TalkScreen"
	screen.set_script(preload("res://scripts/institute_screen.gd"))
	screen.position = Vector3(screen_x + 0.1, 4.6, middle_z)
	screen.rotation.y = PI * 0.5
	body.add_child(screen, true)
	LowPoly.box(body, Vector3(0.12, 4.6, 8.2), DARK, Vector3(screen_x, 4.6, middle_z))
	LowPoly.box(body, Vector3(3.0, 0.3, 6.0), WOOD.darkened(0.2), Vector3(screen_x + 1.8, 0.15, middle_z))
	var speaker := PeopleLooks.teacher()
	speaker.name = "Speaker"
	speaker.position = Vector3(screen_x + 2.4, 0.3, middle_z + 1.5)
	speaker.rotation.y = -PI * 0.5   # faces the seats (+x)
	body.add_child(speaker, true)
	# Hanging plants over the seats and the lobby.
	for i in 8:
		var at := Vector3(-16.0 + i * 4.6, 0, -8.0 + (i % 3) * 6.0)
		var drop := 3.0 + (i % 2) * 1.5
		LowPoly.box(body, Vector3(0.02, drop, 0.02), DARK, Vector3(at.x, size.y - 0.4 - drop * 0.5, at.z))
		var pot_y := size.y - 0.4 - drop
		LowPoly.cylinder(body, 0.35, 0.25, 0.4, WHITE, Vector3(at.x, pot_y, at.z))
		LowPoly.sphere(body, 0.5, 0.6, Color(0.3, 0.58, 0.28), Vector3(at.x, pot_y + 0.3, at.z))
		for k in 4:
			var vine := LowPoly.box(body, Vector3(0.06, 1.0, 0.06), Color(0.25, 0.5, 0.22),
					Vector3(at.x + cos(k * 1.6) * 0.32, pot_y - 0.45, at.z + sin(k * 1.6) * 0.32))
			vine.rotation.z = cos(k * 1.6) * 0.15


## Someone sitting on a cushion with a laptop, facing the screen (-x).
static func _laptop_person(body: StaticBody3D, seat: Vector3, number: int) -> void:
	var who := PeopleLooks.resident(number % 5, number % 4)
	who.name = "LaptopPerson"
	who.position = seat + Vector3(0, -who.spot("Hips").y + 0.08, 0)
	who.rotation.y = PI * 0.5
	body.add_child(who, true)
	who.play("laptop")
	var lap := Vector3(0, who.spot("Hips").y + 0.06, -0.42)
	LowPoly.box(who, Vector3(0.34, 0.02, 0.24), Color(0.75, 0.77, 0.8), lap)
	var lid := LowPoly.box(who, Vector3(0.34, 0.22, 0.015), Color(0.75, 0.77, 0.8), lap + Vector3(0, 0.11, -0.12))
	lid.rotation.x = deg_to_rad(-15.0)
	LowPoly.box(who, Vector3(0.3, 0.18, 0.005), Color(0.55, 0.8, 0.95), lap + Vector3(0, 0.11, -0.11))


## The wood-slat ceiling under the roof.
static func _ceiling(body: StaticBody3D, size: Vector3) -> void:
	var x := -size.x * 0.5 + 0.4
	while x < size.x * 0.5 - 0.2:
		LowPoly.box(body, Vector3(0.12, 0.18, size.z - 0.4), WOOD, Vector3(x, size.y - 0.35, 0))
		x += 0.55


static func _solid(body: StaticBody3D, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	LowPoly.solid_box(body, size, at)
	return LowPoly.box(body, size, colour, at)


static var _glass: StandardMaterial3D

static func _clear() -> StandardMaterial3D:
	if _glass == null:
		_glass = LowPoly.material(GLASS).duplicate() as StandardMaterial3D
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.albedo_color.a = 0.24
	return _glass
