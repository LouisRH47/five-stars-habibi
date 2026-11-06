class_name PlazaLife
extends Node3D
## Looks pass Session 58: more going on in the Plaza.
##   café tables with parasols outside every restaurant (some with people at them)
##   a juice kiosk with a striped canopy, the juice seller and someone buying
##   string lights on poles round the sunken square, lit at sunset (SunsetLights)
##   more people strolling round the Plaza (only moving while you're close)
## PlazaBuilder makes this.

const PAVING_TOP := 0.02          # the Plaza paving top (PlazaBuilder.PAVING_TOP)
const POLE := Color(0.22, 0.22, 0.24)
const WIRE := Color(0.12, 0.12, 0.12)
const STRING_POLES := 12
const STRING_RADIUS := 23.5
const STRING_HEIGHT := 4.4
const STROLL_RADIUS := 27.0
const STROLL_SPEED := 1.0         # metres per second
const ACTIVE_DISTANCE := 70.0     # strollers move only when the camera is this close

var tables := 0
var sitters := 0
var bulbs := 0
var strollers: Array[Person] = []
var _centre := Vector2.ZERO
var _map: Dictionary
var _clear: ClearSpots
var _body: StaticBody3D
var _angles: Array[float] = []
var _lights: SunsetLights
var _people: Array[Person] = []
var _awake := true


static func make(map: Dictionary, clear: ClearSpots) -> PlazaLife:
	var life := PlazaLife.new()
	life.name = "PlazaLife"
	life._map = map
	life._clear = clear
	life._centre = map["PLAZA"]["centre"]
	life._build()
	return life


func _build() -> void:
	_body = StaticBody3D.new()
	_body.name = "PlazaFurniture"
	add_child(_body)
	_lights = SunsetLights.new()
	_lights.name = "SunsetLights"
	add_child(_lights)
	for shop: Dictionary in _map.get("RESTAURANTS", []):
		if shop.get("interior", false):
			_cafe_tables(shop)
	_juice_kiosk()
	_string_lights()
	_strollers()
	set_meta("counts", {"tables": tables, "sitters": sitters, "bulbs": bulbs, "strollers": strollers.size()})


## Two round tables with chairs and a parasol in the shop's colour, in front of the glass.
func _cafe_tables(shop: Dictionary) -> void:
	var p: Vector3 = shop["position"]
	var facing := deg_to_rad(shop["facing"])
	var size: Vector3 = shop.get("size", _map.get("RESTAURANT_SIZE", Vector3(18, 8, 16)))
	var front := Vector3(sin(facing), 0, cos(facing))
	var side := Vector3(cos(facing), 0, -sin(facing))
	var tint: Color = shop.get("colour", Color(0.6, 0.3, 0.3))
	for k in [-1.0, 1.0]:
		var at: Vector3 = p + front * (size.z * 0.5 + 3.4) + side * k * 7.6
		var spot := Vector2(at.x, at.z)
		if not _clear.is_free(spot, 1.2):
			continue
		_clear.add(spot, 1.6)
		var holder := Node3D.new()
		holder.name = "CafeTable%d" % tables
		holder.position = Vector3(at.x, PAVING_TOP if _on_paving(spot) else 0.0, at.z)
		holder.rotation.y = facing
		_body.add_child(holder)
		Props.kit("restaurant/table_round_A_small", holder, Vector3.ZERO, 0.0, 0.72)
		for c in [-1.0, 1.0]:
			Props.kit("restaurant/chair_A", holder, Vector3(c * 0.85, 0, 0), -90.0 * c, 0.68)
		LowPoly.cylinder(holder, 0.03, 0.03, 2.3, POLE, Vector3(0, 1.15, 0))
		var parasol := LowPoly.cylinder(holder, 0.05, 1.4, 0.45, tint.lightened(0.15) if tables % 2 == 0 else Color(0.97, 0.95, 0.9), Vector3(0, 2.35, 0))
		parasol.name = "Parasol"
		LowPoly.cylinder(holder, 0.07, 0.07, 0.4, Color(0.96, 0.95, 0.92), Vector3(0.1, 0.92, 0.05))  # a drink
		var shape := LowPoly.solid_cylinder(_body, 1.2, 1.0, holder.position + Vector3(0, 0.5, 0))
		shape.name = "CafeTableSolid%d" % tables
		if (tables + int(absf(p.x))) % 3 != 0:
			var diner := PlaceLooks.shopper(tables) if tables % 2 == 0 else PlaceLooks.neighbour(tables)
			diner.name = "CafeSitter%d" % sitters
			diner.rotation.y = facing - PI * 0.5
			var hips := diner.spot("Hips")
			diner.position = holder.position + side * -0.85 + Vector3(0, 0.47, 0) - diner.basis * hips
			add_child(diner)
			diner.play("sit")
			_near_only(diner)
			sitters += 1
		tables += 1
	Props.bake_kits(_body)


func _on_paving(spot: Vector2) -> bool:
	if _map["PLAZA"].has("floor"):  # Session 77: the square floor
		return PlazaFloor.is_paved(_map, spot)
	var r := spot.distance_to(_centre)
	return r > _map["PLAZA"]["sunken_radius"] and r < _map["PLAZA"]["radius"]


## A juice kiosk on the west side of the Plaza paving.
func _juice_kiosk() -> void:
	var spot := Vector2.ZERO
	var found := false
	for a in [180.0, 200.0, 160.0, 0.0, 20.0, 340.0]:
		var try := _centre + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 36.0
		if _clear.is_free(try, 2.6):
			spot = try
			found = true
			break
	if not found:
		return
	_clear.add(spot, 3.2)
	var kiosk := Node3D.new()
	kiosk.name = "JuiceKiosk"
	kiosk.position = Vector3(spot.x, PAVING_TOP, spot.y)
	var toward := _centre - spot
	kiosk.rotation.y = atan2(toward.x, toward.y)  # the counter faces the middle of the Plaza
	_body.add_child(kiosk)
	var green := Color(0.35, 0.65, 0.25)
	var orange := Color(0.98, 0.6, 0.15)
	LowPoly.box(kiosk, Vector3(3.0, 1.05, 1.6), Color(0.97, 0.95, 0.9), Vector3(0, 0.525, 0.3))
	LowPoly.box(kiosk, Vector3(3.1, 0.06, 1.75), Color(0.6, 0.42, 0.25), Vector3(0, 1.08, 0.35))
	LowPoly.box(kiosk, Vector3(3.0, 0.25, 0.05), orange, Vector3(0, 0.8, 1.11))
	LowPoly.box(kiosk, Vector3(3.0, 2.6, 0.12), Color(0.97, 0.95, 0.9), Vector3(0, 1.3, -1.1))
	for x in [-1.45, 1.45]:
		LowPoly.box(kiosk, Vector3(0.1, 2.9, 0.1), POLE, Vector3(x, 1.45, 1.05))
		LowPoly.box(kiosk, Vector3(0.1, 2.9, 0.1), POLE, Vector3(x, 1.45, -1.05))
	for i in 8:  # the striped canopy
		var stripe := LowPoly.box(kiosk, Vector3(0.42, 0.05, 2.9), green if i % 2 == 0 else Color.WHITE, Vector3(-1.47 + i * 0.42, 3.0, 0.2))
		stripe.rotation.x = deg_to_rad(10.0)
	for i in 10:  # bottles and oranges on the counter
		var x := -1.3 + i * 0.28
		if i % 2 == 0:
			LowPoly.cylinder(kiosk, 0.05, 0.06, 0.26, [orange, Color(0.95, 0.3, 0.35), Color(0.6, 0.85, 0.3)][i % 3], Vector3(x, 1.24, 0.6))
		else:
			LowPoly.sphere(kiosk, 0.08, 0.16, orange, Vector3(x, 1.19, 0.65))
	LowPoly.box(kiosk, Vector3(2.6, 0.55, 0.06), green.darkened(0.3), Vector3(0, 2.45, 1.12))
	var sign := SignText.make_face("عصير طازج", "Fresh Juice", 34, Color.WHITE)
	sign.position = Vector3(0, 2.45, 1.16)
	kiosk.add_child(sign)
	var bulbs_row := Node3D.new()
	kiosk.add_child(bulbs_row)
	for i in 7:
		var bulb := LowPoly.sphere(bulbs_row, 0.06, 0.12, Color.WHITE, Vector3(-1.35 + i * 0.45, 2.78, 1.45))
		bulb.material_override = SunsetLights.bulb_material()
	var solid := LowPoly.solid_box(_body, Vector3(3.2, 1.3, 2.4), kiosk.position + Vector3(0, 0.65, 0))
	solid.rotation.y = kiosk.rotation.y
	var seller := PeopleLooks.resident(2, 2)
	seller.paint({"shirt": green, "pants": Color(0.2, 0.2, 0.22)})
	PeopleLooks.cap(seller, green, seller)
	seller.name = "JuiceSeller"
	seller.position = kiosk.position + kiosk.basis * Vector3(0, 0, -0.5)
	seller.rotation.y = kiosk.rotation.y + PI
	add_child(seller)
	_near_only(seller)
	var buyer := PlaceLooks.shopper(5)
	buyer.name = "JuiceBuyer"
	buyer.position = kiosk.position + kiosk.basis * Vector3(0.6, 0, 1.75)
	buyer.rotation.y = kiosk.rotation.y
	add_child(buyer)
	_near_only(buyer)


## Poles round the sunken square with strings of bulbs between them (lit at sunset).
func _string_lights() -> void:
	var holder := Node3D.new()
	holder.name = "StringLights"
	_body.add_child(holder)
	var tops: Array[Vector3] = []
	for i in STRING_POLES:
		var a := TAU * (i + 0.5) / STRING_POLES
		var spot := _centre + Vector2(cos(a), sin(a)) * STRING_RADIUS
		var at := Vector3(spot.x, PAVING_TOP, spot.y)
		LowPoly.cylinder(holder, 0.05, 0.08, STRING_HEIGHT, POLE, at + Vector3(0, STRING_HEIGHT * 0.5, 0))
		LowPoly.cylinder(holder, 0.12, 0.14, 0.12, POLE, at + Vector3(0, 0.06, 0))
		LowPoly.solid_cylinder(_body, 0.12, 2.0, at + Vector3(0, 1.0, 0))
		tops.append(at + Vector3(0, STRING_HEIGHT - 0.1, 0))
	var points: Array[Vector3] = []
	var wire := PackedVector3Array()
	for i in STRING_POLES:
		var a := tops[i]
		var b := tops[(i + 1) % STRING_POLES]
		var count := int(a.distance_to(b) / 0.6)
		var last := a
		for k in range(1, count + 1):
			var t := float(k) / count
			var p := a.lerp(b, t) + Vector3(0, -GameConfig.STRING_LIGHT_SAG * 4.0 * t * (1.0 - t), 0)
			wire.append(last)
			wire.append(p)
			last = p
			if k < count:
				points.append(p + Vector3(0, -0.07, 0))
	var lines := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = wire
	lines.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var wire_view := MeshInstance3D.new()
	wire_view.name = "Wire"
	wire_view.mesh = lines
	wire_view.material_override = LowPoly.material(WIRE)
	wire_view.set_meta("static_batch_dynamic", true)
	add_child(wire_view)
	var bulb := SphereMesh.new()
	bulb.radius = 0.06
	bulb.height = 0.13
	bulb.radial_segments = 6
	bulb.rings = 3
	bulb.material = SunsetLights.bulb_material()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = bulb
	many.instance_count = points.size()
	for i in points.size():
		many.set_instance_transform(i, Transform3D(Basis(), points[i]))
	var view := MultiMeshInstance3D.new()
	view.name = "Bulbs"
	view.multimesh = many
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	bulbs = points.size()
	# A few real warm lights over the square (Medium and High only, at sunset).
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		var light := OmniLight3D.new()
		light.name = "StringGlow%d" % i
		light.position = Vector3(_centre.x + cos(a) * STRING_RADIUS * 0.8, STRING_HEIGHT - 0.6, _centre.y + sin(a) * STRING_RADIUS * 0.8)
		light.light_color = Color(1.0, 0.8, 0.5)
		light.omni_range = 16.0
		light.set_meta("full_energy", 1.2)
		light.distance_fade_enabled = true
		light.distance_fade_begin = 90.0
		light.distance_fade_length = 20.0
		light.visible = false
		add_child(light)
		_lights.lights.append(light)


## People strolling slowly round the Plaza paving (the other way round to the shoppers).
func _strollers() -> void:
	for i in GameConfig.PLAZA_STROLLERS:
		var person := PlaceLooks.neighbour(i + 3) if i % 2 == 0 else PlaceLooks.shopper(i + 7)
		person.name = "Stroller%d" % i
		add_child(person)
		_angles.append(TAU * i / GameConfig.PLAZA_STROLLERS)
		strollers.append(person)
		person.play("walk")
		_near_only(person)
	_place_strollers()


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var near := Vector2(camera.global_position.x, camera.global_position.z).distance_to(_centre) < ACTIVE_DISTANCE
	if near != _awake:
		_awake = near
		for person in _people:
			person.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
	if not near:
		return
	for i in _angles.size():
		_angles[i] -= delta * STROLL_SPEED / STROLL_RADIUS
	_place_strollers()


func _place_strollers() -> void:
	for i in strollers.size():
		var a := _angles[i]
		var r := STROLL_RADIUS + (i % 2) * 1.2
		var person := strollers[i]
		person.position = Vector3(_centre.x + cos(a) * r, PAVING_TOP, _centre.y + sin(a) * r)
		var way := Vector2(sin(a), -cos(a))  # moving clockwise
		person.rotation.y = atan2(-way.x, -way.y)  # people face -Z


## People here are only drawn when you're fairly close (keeps Low graphics fast).
func _near_only(person: Person) -> void:
	_people.append(person)
	for part: MeshInstance3D in person.find_children("*", "MeshInstance3D", true, false):
		part.visibility_range_end = GameConfig.ROOM_PEOPLE_DRAW_DISTANCE
