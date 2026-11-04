class_name CarParkBuilder
extends RefCounted
## Session 62: builds every solar car park from CAR_PARKS in the map data (the layout is made
## by tools/carpark_layout.py): asphalt with the painted bay lines and aisle arrows, a solar
## roof over every row (one shared roof over each back-to-back pair, with its posts down the
## middle line), kerbstones, the grass verge and grass beds, two electric car chargers and a
## bilingual car park sign. The ring road's kerbs are built here too.
## DistrictTraffic calls build(); the parked cars come from DecorBuilder (one solid body each)
## and CarParkCars (how they look).

const WHITE := Color(0.96, 0.96, 0.92)
const SOLAR := Color(0.11, 0.2, 0.33)
const GRID := Color(0.62, 0.66, 0.7)
const METAL := Color(0.55, 0.57, 0.6)
const CHARGER := Color(0.93, 0.94, 0.95)
const TEAL := Color(0.12, 0.55, 0.6)
const SIGN_BLUE := Color(0.1, 0.3, 0.62)
const PAD_TOP := 0.03       # asphalt top (just under the roads, like the old car parks)
const LINE_TOP := 0.045     # painted lines sit on the asphalt
const GRASS_TOP := 0.05     # grass beds and the verge


## Builds everything. Returns how many solar roofs were built.
static func build(parent: Node3D, map: Dictionary) -> int:
	var holder := Node3D.new()
	holder.name = "CarParks"
	parent.add_child(holder)
	var roofs := 0
	for i in map.get("CAR_PARKS", []).size():
		var park: Dictionary = map["CAR_PARKS"][i]
		_asphalt(holder, park, i)
		var lines := MeshKit.new()   # one mesh of paint per car park
		_paint(lines, park)
		holder.add_child(lines.finish("BayLines_%d" % i))
		for roof: Dictionary in park["roofs"]:
			holder.add_child(solar_roof(roof, roofs))
			roofs += 1
		for j in park["chargers"].size():
			_charger(holder, park["chargers"][j], park["north"], "EVCharger_%d_%d" % [i, j])
		_sign(holder, park, i)
	for area: Rect2 in map.get("CARPARK_GARDENS", []):
		var bed := LowPoly.box(holder, Vector3(area.size.x, 0.04, area.size.y), Color(0.47, 0.66, 0.34),
				Vector3(area.get_center().x, GRASS_TOP - 0.02, area.get_center().y))
		bed.name = "GrassBed"
		bed.material_override = TerrainMaterials.make("grass")
	Kerbs.build(holder, map.get("CARPARK_KERBS", []), "CarParkKerbs")
	Kerbs.build(holder, Kerbs.ring_segments(map), "RingRoadKerbs")
	return roofs


## The asphalt: one slab over the rows and aisles (stylized asphalt texture, Session 55).
## The aisle openings through the verge are built by DistrictTraffic._build_access.
static func _asphalt(holder: Node3D, park: Dictionary, index: int) -> void:
	var area: Rect2 = park["area"]
	var z0: float = park["first_bay_z"]
	var z1: float = area.end.y if park["north"] else area.position.y
	var middle := Vector3(area.get_center().x, PAD_TOP * 0.5, (z0 + z1) * 0.5)
	var pad := LowPoly.box(holder, Vector3(area.size.x, PAD_TOP, absf(z1 - z0)), Color(0.33, 0.34, 0.36), middle)
	pad.name = "CarParkAsphalt_%d" % index
	pad.material_override = TerrainMaterials.make("road")


## White bay lines (one across the back of every bay pair and between bays), the middle
## line of each back-to-back pair, and two-way arrows down every aisle.
static func _paint(kit: MeshKit, park: Dictionary) -> void:
	var w: float = GameConfig.CARPARK_LINE_WIDTH
	for row: Dictionary in park["rows"]:
		var area: Rect2 = row["area"]
		for b in int(row["bays"]) + 1:
			var z := area.position.y + b * 2.5
			kit.box(Vector3(area.size.x, 0.01, w), WHITE, Vector3(area.get_center().x, LINE_TOP - 0.005, z))
	for roof: Dictionary in park["roofs"]:
		if roof["double"]:
			var area: Rect2 = roof["area"]
			kit.box(Vector3(w, 0.01, area.size.y), WHITE, Vector3(roof["high_x"], LINE_TOP - 0.005, area.get_center().y))
	for aisle: Rect2 in park["aisles"]:
		var z: float = park["first_bay_z"]
		var end: float = park["last_bay_z"]
		var step: float = GameConfig.CARPARK_ARROW_EVERY * (1.0 if park["north"] else -1.0)
		z += step * 0.5
		while (z < end - 4.0) if park["north"] else (z > end + 4.0):
			_arrow(kit, Vector3(aisle.get_center().x - aisle.size.x * 0.25, LINE_TOP - 0.005, z), 1.0)
			_arrow(kit, Vector3(aisle.get_center().x + aisle.size.x * 0.25, LINE_TOP - 0.005, z), -1.0)
			z += step
		# a white give-way line where the aisle meets the ring road
		var ring_z: float = park["ring_z"] + (0.6 if park["north"] else -0.6)
		kit.box(Vector3(aisle.size.x, 0.01, 0.3), WHITE, Vector3(aisle.get_center().x, LINE_TOP + 0.01, ring_z))


## A painted arrow, pointing along +z (way = 1) or -z (way = -1).
static func _arrow(kit: MeshKit, at: Vector3, way: float) -> void:
	kit.box(Vector3(0.18, 0.01, 1.6), WHITE, at)
	var tip := at + Vector3(0, 0, way * 0.8)
	for side in [-1.0, 1.0]:
		var turn := Basis(Vector3.UP, side * way * deg_to_rad(35.0))
		kit.box(Vector3(0.18, 0.01, 0.8), WHITE, tip + turn * Vector3(0, 0, -way * 0.35), turn)


## One solar roof over a row (or a back-to-back pair): dark panels with a thin grid, low at
## the aisle side (2.6 m) and high at the back (3.0 m), on posts every few bays.
static func solar_roof(roof: Dictionary, number: int) -> StaticBody3D:
	var area: Rect2 = roof["area"]
	var body := StaticBody3D.new()
	body.name = "SolarRoof_%d" % number
	body.set_meta("impact_category", "metal")
	body.set_meta("impact_name", "a solar roof post")
	var centre := area.get_center()
	body.position = Vector3(centre.x, 0, centre.y)
	var kit := MeshKit.new()
	var high_x: float = float(roof["high_x"]) - centre.x
	var low: float = GameConfig.CARPARK_ROOF_LOW
	var high: float = GameConfig.CARPARK_ROOF_HIGH
	var edges: Array[float] = [area.position.x - centre.x, area.end.x - centre.x]
	var slopes: Array = []
	if roof["double"]:
		slopes = [[edges[0], high_x], [edges[1], high_x]]
	else:
		slopes = [[edges[1] if absf(edges[0] - high_x) < absf(edges[1] - high_x) else edges[0], high_x]]
	var length := area.size.y
	for slope: Array in slopes:
		var xa: float = slope[0]
		var xb: float = slope[1]
		var run := xb - xa
		var angle := atan((high - low) / run)
		var turn := Basis(Vector3.BACK, angle)
		var wide := sqrt(run * run + (high - low) * (high - low))
		var mid := Vector3((xa + xb) * 0.5, (low + high) * 0.5 + 0.05, 0)
		kit.box(Vector3(wide, 0.1, length), SOLAR, mid, turn)
		var cells := maxi(2, roundi(wide / 1.05))
		for c in range(1, cells):
			var u := -wide * 0.5 + wide * c / cells
			kit.box(Vector3(0.035, 0.02, length), GRID, mid + turn * Vector3(u, 0.06, 0), turn)
		var across := roundi(length / 1.7)
		for c in range(across + 1):
			var v := -length * 0.5 + length * c / across
			kit.box(Vector3(wide, 0.02, 0.04), GRID, mid + turn * Vector3(0, 0.06, v), turn)
		for u in [-wide * 0.5 + 0.06, wide * 0.5 - 0.06]:   # frame along both long edges
			kit.box(Vector3(0.12, 0.16, length), METAL, mid + turn * Vector3(u, -0.1, 0), turn)
		var posts := _post_spots(length, int(roof.get("bays", roundi(length / 2.5))))
		for z in posts:   # a beam under the panel at every post
			kit.box(Vector3(wide, 0.12, 0.12), METAL, mid + turn * Vector3(0, -0.12, z), turn)
	# the posts: down the middle line of a pair, or along the back of a single row (on its kerb)
	var post_x := high_x
	if not roof["double"]:
		post_x += 0.1 * signf(high_x)
	for z in _post_spots(length, roundi(length / 2.5)):
		var spot := Vector3(post_x, high * 0.5, z)
		kit.box(Vector3(0.16, high, 0.16), METAL, spot)
		kit.box(Vector3(0.4, 0.05, 0.4), METAL, Vector3(post_x, 0.025, z))
		LowPoly.solid_box(body, Vector3(0.16, high, 0.16), spot)
	body.add_child(kit.finish("Roof"))
	return body


## Where the posts stand along a roof of this length: on a bay line every few bays.
static func _post_spots(length: float, bays: int) -> Array[float]:
	var spots: Array[float] = []
	var every: int = GameConfig.CARPARK_POST_EVERY
	var b := 0
	while b <= bays:
		spots.append(-length * 0.5 + 0.25 + b * 2.5)
		b += every
	if bays % every != 0:
		spots.append(-length * 0.5 + 0.25 + bays * 2.5)
	return spots


## An electric car charger on a post, by the end of a row, its screen facing the bays.
static func _charger(holder: Node3D, spot: Vector3, north: bool, title: String) -> void:
	var body := StaticBody3D.new()
	body.name = title
	body.position = spot
	body.rotation.y = 0.0 if north else PI
	body.set_meta("impact_category", "metal")
	body.set_meta("impact_name", "a car charger")
	holder.add_child(body)
	var kit := MeshKit.new()
	kit.box(Vector3(0.4, 1.5, 0.28), CHARGER, Vector3(0, 0.75, 0))
	kit.box(Vector3(0.32, 0.4, 0.02), Color(0.08, 0.1, 0.12), Vector3(0, 1.15, 0.15))
	kit.box(Vector3(0.42, 0.1, 0.3), TEAL, Vector3(0, 1.52, 0))
	kit.box(Vector3(0.06, 0.06, 0.02), Color(0.3, 0.95, 0.4), Vector3(0.1, 0.85, 0.15))
	kit.cylinder(0.03, 0.03, 0.5, Color(0.1, 0.1, 0.1), Vector3(-0.24, 0.9, 0.1))
	body.add_child(kit.finish("Look"))
	LowPoly.solid_box(body, Vector3(0.4, 1.5, 0.28), Vector3(0, 0.75, 0))


## A bilingual sign by the entrance: a big white P and the car park's name, facing the ring road.
static func _sign(holder: Node3D, park: Dictionary, index: int) -> void:
	var place: Dictionary = park["sign"]
	var body := StaticBody3D.new()
	body.name = "CarParkSign_%d" % index
	body.position = place["position"]
	body.rotation_degrees.y = place["facing"]
	body.set_meta("impact_category", "metal")
	body.set_meta("impact_name", "a car park sign")
	holder.add_child(body)
	var kit := MeshKit.new()
	for x in [-1.1, 1.1]:
		kit.box(Vector3(0.1, 2.9, 0.1), METAL, Vector3(x, 1.45, 0))
	kit.box(Vector3(2.6, 1.3, 0.08), SIGN_BLUE, Vector3(0, 2.25, 0))
	kit.box(Vector3(0.7, 0.7, 0.1), WHITE, Vector3(-0.85, 2.25, 0))
	body.add_child(kit.finish("Board"))
	for x in [-1.1, 1.1]:
		LowPoly.solid_box(body, Vector3(0.1, 2.9, 0.1), Vector3(x, 1.45, 0))
	var p := SignText.make_label("P", 110, SIGN_BLUE, Color(0, 0, 0, 0), 0)
	p.position = Vector3(-0.85, 2.25, 0.06)
	body.add_child(p)
	var arabic: String = park["arabic"]
	var english: String = park["name"]
	var size := SignText.fit_size(arabic, english, 30, 1.6)
	var face := SignText.make_face(arabic, english, size, Color.WHITE)
	face.position = Vector3(0.4, 2.25, 0.06)
	body.add_child(face)
