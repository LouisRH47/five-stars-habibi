extends Node3D
## Builds the things in the green spine and the cluster mini-plazas (Session 27), from
## data/wahat_al_shams.gd: 6 white greenhouse domes, farm beds, beehives, a donkey pen,
## a basketball court and a playground; and in every cluster a cooling tower, a small
## playground and benches. The Farm Stall itself is a shop, so PlaceBuilder builds it.
## Domes, hoops, the pen fence and play things are solid; beds and the court are flat.

## The map data to build from (set in the scene): data/wahat_al_shams.gd.
@export var data: Script

const DOME := Color(0.97, 0.97, 0.95, 1)
const DOME_RIB := Color(0.82, 0.84, 0.85, 1)
const SOIL := Color(0.45, 0.32, 0.22, 1)
const CROPS := [Color(0.35, 0.62, 0.25, 1), Color(0.5, 0.72, 0.3, 1), Color(0.9, 0.45, 0.2, 1)]
const COURT := Color(0.75, 0.4, 0.28, 1)
const COURT_LINE := Color(0.97, 0.97, 0.95, 1)
const HIVE := Color(0.98, 0.85, 0.35, 1)
const PEN := Color(0.6, 0.42, 0.26, 1)
const STRAW := Color(0.9, 0.78, 0.45, 1)

var _map: Dictionary = {}


func _ready() -> void:
	if data == null:
		push_error("SpineBuilder has no data list set in the scene")
		return
	_map = data.get_script_constant_map()
	for i in _map["SPINE_DOMES"].size():
		_build_dome(_map["SPINE_DOMES"][i], _map["DOME_RADIUS"]).name = "Dome_%d" % i
	for i in _map["FARM_BEDS"].size():
		_build_beds(_map["FARM_BEDS"][i], i)
	_build_hives(_map["BEEHIVES"])
	_build_pen(_map["DONKEY_PEN"])
	_build_court(_map["BASKETBALL_COURT"])
	var play: Rect2 = _map["PLAYGROUND"]
	PlaygroundKit.build(self, _ground(play.get_center()), play.size)  # Session 71: the rounded Blender playground
	for mini in _map["MINI_PLAZAS"]:
		Props.cooling_tower(self, mini["tower"])
		PlaygroundKit.build(self, mini["playground"], Vector2(6, 4.5))
		for bench in mini["benches"]:
			Props.bench(self, bench["position"], bench["facing"])


## A white greenhouse dome: a squashed ball with ribs, a door, on a low ring wall. Solid.
func _build_dome(spot: Vector3, radius: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = spot
	add_child(body)
	LowPoly.cylinder(body, radius, radius, 0.5, DOME_RIB, Vector3(0, 0.25, 0))
	LowPoly.sphere(body, radius, radius * 1.5, DOME, Vector3(0, 0.5, 0))
	# Session 52: the ribs are thin slices of a slightly bigger dome, so they follow its
	# curve instead of sticking out as flat boards. None crosses the door (at +Z).
	for i in 3:
		var rib := LowPoly.sphere(body, radius + 0.04, (radius + 0.04) * 1.5, DOME_RIB, Vector3(0, 0.5, 0))
		rib.scale.x = 0.08 / (radius * 2.0)
		rib.rotation.y = PI / 6.0 + PI * i / 3.0
	# The door sits in a small porch that pokes out of the dome, so nothing cuts through it.
	var door_z := radius + 0.15
	LowPoly.box(body, Vector3(1.8, 2.5, 1.0), DOME_RIB, Vector3(0, 1.25, door_z - 0.45))
	LowPoly.box(body, Vector3(1.2, 2.0, 0.1), Color(0.3, 0.45, 0.35, 1), Vector3(0, 1.0, door_z + 0.1))
	LowPoly.solid_cylinder(body, radius, 3.0, Vector3(0, 1.5, 0))
	return body


## Rows of farm beds: brown soil strips with little green and orange plants. Flat.
func _build_beds(area: Rect2, variant: int) -> void:
	var rows := maxi(1, floori(area.size.y / 2.2))
	for row in rows:
		var z := area.position.y + 1.1 + row * 2.2
		LowPoly.box(self, Vector3(area.size.x, 0.25, 1.4), SOIL, Vector3(area.get_center().x, 0.12, z))
		var x := area.position.x + 0.8
		var i := 0
		while x < area.end.x - 0.5:
			LowPoly.sphere(self, 0.3, 0.4, CROPS[(row + i + variant) % CROPS.size()], Vector3(x, 0.4, z))
			x += 1.3
			i += 1


## Beehives: little yellow boxes on legs, in two rows.
func _build_hives(area: Rect2) -> void:
	for row in 2:
		for i in 4:
			var spot := Vector3(area.position.x + 1.0 + i * 2.3, 0, area.position.y + 1.5 + row * 4.0)
			LowPoly.box(self, Vector3(0.1, 0.4, 0.1), Props.WOOD, spot + Vector3(0, 0.2, 0))
			LowPoly.box(self, Vector3(0.7, 0.7, 0.6), HIVE, spot + Vector3(0, 0.75, 0))
			LowPoly.box(self, Vector3(0.85, 0.1, 0.75), Color(0.95, 0.95, 0.92, 1), spot + Vector3(0, 1.15, 0))


## The donkey pen: a wooden fence round a patch of straw and a water trough.
func _build_pen(pen: Dictionary) -> void:
	var area: Rect2 = pen["area"]
	LowPoly.box(self, Vector3(area.size.x, 0.02, area.size.y), STRAW, _ground(area.get_center()) + Vector3(0, 0.02, 0))
	var a := area.position
	var b := Vector2(area.end.x, area.position.y)
	var c := area.end
	var d := Vector2(area.position.x, area.end.y)
	for side in [[a, b], [b, c], [c, d], [d, a]]:
		Props.fence(self, side[0], side[1], 1.2, PEN)
	LowPoly.box(self, Vector3(2.0, 0.5, 0.6), Props.WOOD, _ground(area.get_center()) + Vector3(-area.size.x * 0.3, 0.25, 0))
	# The donkeys themselves stroll round the pen: scripts/ambient_motion.gd (Session 30).


## The basketball court: a red court with white lines and a hoop at each end.
func _build_court(area: Rect2) -> void:
	var middle := _ground(area.get_center())
	LowPoly.box(self, Vector3(area.size.x, 0.04, area.size.y), COURT, middle + Vector3(0, 0.03, 0))
	LowPoly.box(self, Vector3(0.1, 0.01, area.size.y - 1.0), COURT_LINE, middle + Vector3(0, 0.055, 0))
	LowPoly.cylinder(self, 1.6, 1.6, 0.01, COURT_LINE, middle + Vector3(0, 0.055, 0))
	LowPoly.cylinder(self, 1.45, 1.45, 0.012, COURT, middle + Vector3(0, 0.06, 0))
	for side in [-1.0, 1.0]:
		var hoop := StaticBody3D.new()
		hoop.position = middle + Vector3(side * (area.size.x * 0.5 - 0.6), 0, 0)
		add_child(hoop)
		LowPoly.box(hoop, Vector3(0.15, 3.2, 0.15), Props.METAL, Vector3(0, 1.6, 0))
		LowPoly.box(hoop, Vector3(0.08, 1.0, 1.6), COURT_LINE, Vector3(-side * 0.3, 3.2, 0))
		LowPoly.cylinder(hoop, 0.25, 0.25, 0.04, Color(0.95, 0.4, 0.1, 1), Vector3(-side * 0.65, 2.9, 0))
		LowPoly.solid_box(hoop, Vector3(0.3, 3.2, 0.3), Vector3(0, 1.6, 0))


func _ground(spot: Vector2) -> Vector3:
	return Vector3(spot.x, 0, spot.y)
