class_name StreetDetails
extends Node3D
## Looks pass Session 58: things along the streets and lanes inside the ring road:
##   street lamps that light up at sunset (scripts/sunset_lights.gd), every ~30 m on the
##   inside roads (the ring road keeps its own light posts), in the spine planters along
##   the spine road; bins beside some of them; bilingual street name signs (Arabic +
##   English, blue like Dubai's); and bike racks at the Plaza, gym, institute, farm stall,
##   bee farm and school gate. Road markings and kerbs are RoadMesh's (Session 61).
## PlazaBuilder makes this. Spots are checked with ClearSpots so nothing lands on a road,
## a doorstep, a home or another thing. All poles are solid.

const POLE := Color(0.25, 0.27, 0.29)
const BIN := Color(0.2, 0.42, 0.3)
const SIGN_BLUE := Color(0.1, 0.25, 0.55)
const RACK := Color(0.7, 0.72, 0.74)
const LAMP_SPACING := 30.0
const LAMP_ROADS := ["Spine Loop", "Plaza Road", "Institute Back Road", "C1 Lane", "C2 Lane",
		"C3 Lane", "C4 Lane", "C5 Lane"]
## Arabic for the street name signs.
const STREET_NAMES := {
	"Spine Road": "طريق الحديقة",
	"Spine Loop": "الطريق الدائري الداخلي",
	"Plaza Road": "طريق الساحة",
	"Institute Back Road": "طريق المعهد",
	"C1 Lane": "ممر المجموعة ١", "C2 Lane": "ممر المجموعة ٢", "C3 Lane": "ممر المجموعة ٣",
	"C4 Lane": "ممر المجموعة ٤", "C5 Lane": "ممر المجموعة ٥",
}

var lamps := 0
var bins := 0
var signs := 0
var racks := 0
## Where each lamp's glowing head is (world), for the MultiMesh and the tests.
var lamp_heads: Array[Transform3D] = []
var _map: Dictionary
var _clear: ClearSpots
var _body: StaticBody3D


static func make(map: Dictionary, clear: ClearSpots) -> StreetDetails:
	var details := StreetDetails.new()
	details.name = "StreetDetails"
	details._map = map
	details._clear = clear
	details._build()
	return details


func _build() -> void:
	_body = StaticBody3D.new()
	_body.name = "StreetFurniture"
	add_child(_body)
	_spine_lamps()
	for road: Dictionary in _map.get("ROADS", []):
		if road["name"] in LAMP_ROADS:
			_lamps_along(road)
	_street_signs()
	_bike_racks()
	_lamp_glow()
	var lights := SunsetLights.new()
	lights.name = "SunsetLights"
	add_child(lights)
	set_meta("counts", {"lamps": lamps, "bins": bins, "signs": signs, "racks": racks})


## Lamps in the planters on both sides of the spine road, halfway between the palms.
func _spine_lamps() -> void:
	if not _map.has("SPINE_TRACKS"):
		return
	var spec: Dictionary = _map["SPINE_TRACKS"]
	var z: float = spec["road_half"] + spec["planter"] * 0.5
	var x: float = spec["from_x"] + 22.5
	var side := 1.0
	while x < spec["to_x"] - 5.0:
		var spot := Vector2(x, z * side)
		if _clear.is_free(spot, 0.4, true):
			_lamp(spot, Vector2(0, -side), true)
		x += LAMP_SPACING
		side = -side


## Lamps every LAMP_SPACING metres on one side of a road (the other side if blocked).
func _lamps_along(road: Dictionary) -> void:
	var a: Vector2 = road["from"]
	var b: Vector2 = road["to"]
	var length := a.distance_to(b)
	if length < 12.0:
		return
	var along := (b - a) / length
	var out := Vector2(-along.y, along.x)
	var half: float = road.get("width", 6.0) * 0.5
	var t := fmod(absf(a.x * 0.37 + a.y * 0.61), LAMP_SPACING * 0.5) + 6.0
	var i := 0
	while t < length - 6.0:
		for side in [1.0, -1.0]:
			var spot: Vector2 = a + along * t + out * side * (half + 1.0)
			if _clear.is_free(spot, 0.5):
				_lamp(spot, -out * side, i % 2 == 0)
				break
		t += LAMP_SPACING
		i += 1


## One street lamp at `spot`, its arm reaching over the road (`toward`). with_bin: a bin too.
func _lamp(spot: Vector2, toward: Vector2, with_bin: bool) -> void:
	var holder := Node3D.new()
	holder.name = "StreetLamp%d" % lamps
	holder.position = Vector3(spot.x, 0, spot.y)
	holder.rotation.y = atan2(toward.x, toward.y)  # local +Z points over the road
	_body.add_child(holder)
	var height: float = GameConfig.STREET_LAMP_HEIGHT
	LowPoly.cylinder(holder, 0.16, 0.2, 0.3, POLE, Vector3(0, 0.15, 0))
	LowPoly.cylinder(holder, 0.06, 0.09, height, POLE, Vector3(0, height * 0.5, 0))
	LowPoly.box(holder, Vector3(0.07, 0.07, 1.3), POLE, Vector3(0, height - 0.05, 0.6))
	LowPoly.box(holder, Vector3(0.3, 0.12, 0.55), POLE, Vector3(0, height - 0.12, 1.2))
	var shape := LowPoly.solid_cylinder(_body, 0.15, 2.4, holder.position + Vector3(0, 1.2, 0))
	shape.name = "LampPole%d" % lamps
	lamp_heads.append(Transform3D(holder.basis, holder.position + holder.basis * Vector3(0, height - 0.19, 1.2)))
	_clear.add(spot, 1.0)
	lamps += 1
	if with_bin:
		var along := Vector2(toward.y, -toward.x)
		for side in [1.0, -1.0]:
			var bin_spot: Vector2 = spot + along * 1.7 * side
			if _clear.is_free(bin_spot, 0.35):
				_bin(bin_spot)
				break


## A green street bin with a dark lid.
func _bin(spot: Vector2) -> void:
	var at := Vector3(spot.x, 0, spot.y)
	var bin := LowPoly.cylinder(_body, 0.26, 0.22, 0.9, BIN, at + Vector3(0, 0.45, 0))
	bin.name = "StreetBin%d" % bins
	LowPoly.cylinder(_body, 0.29, 0.29, 0.08, Color(0.12, 0.14, 0.13), at + Vector3(0, 0.94, 0))
	LowPoly.box(_body, Vector3(0.22, 0.05, 0.04), Color(0.9, 0.9, 0.88), at + Vector3(0, 0.75, 0.24))
	LowPoly.solid_cylinder(_body, 0.28, 1.0, at + Vector3(0, 0.5, 0))
	_clear.add(spot, 0.5)
	bins += 1


## The glowing undersides of every lamp head: one MultiMesh, lit at sunset.
func _lamp_glow() -> void:
	var glow := BoxMesh.new()
	glow.size = Vector3(0.26, 0.03, 0.48)
	glow.material = SunsetLights.lamp_material()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = glow
	many.instance_count = lamp_heads.size()
	for i in lamp_heads.size():
		many.set_instance_transform(i, lamp_heads[i])
	var view := MultiMeshInstance3D.new()
	view.name = "LampGlow"
	view.multimesh = many
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)


## Street name signs at the start and end of each named road (and each cluster lane).
func _street_signs() -> void:
	var seen := {}
	for road: Dictionary in _map.get("ROADS", []):
		var name: String = road["name"]
		if not STREET_NAMES.has(name):
			continue
		var a: Vector2 = road["from"]
		var b: Vector2 = road["to"]
		if a.distance_to(b) < 30.0:
			continue
		var key := "%s|%d|%d" % [name, roundi(a.x / 20.0), roundi(a.y / 20.0)]
		if seen.has(key) or seen.get(name, 0) >= 3:
			continue
		var along := (b - a).normalized()
		var out := Vector2(-along.y, along.x)
		var half: float = road.get("width", 6.0) * 0.5
		for t in [8.0, 14.0]:
			var placed := false
			for side in [-1.0, 1.0]:
				var spot: Vector2 = a + along * t + out * side * (half + 1.2)
				if _clear.is_free(spot, 0.6, name == "Spine Road"):
					_sign(spot, along, name)
					placed = true
					break
			if placed:
				seen[key] = true
				seen[name] = seen.get(name, 0) + 1
				break


## A post with a blue bilingual name plate, readable from both directions along the road.
func _sign(spot: Vector2, along: Vector2, name: String) -> void:
	var holder := Node3D.new()
	holder.name = "StreetSign%d" % signs
	holder.position = Vector3(spot.x, 0, spot.y)
	holder.rotation.y = atan2(along.x, along.y)  # the plate faces along the road
	_body.add_child(holder)
	LowPoly.cylinder(holder, 0.045, 0.05, 2.9, POLE, Vector3(0, 1.45, 0))
	var arabic: String = STREET_NAMES[name]
	var width := maxf(1.6, SignText.text_width(name, 34) + 0.4)
	LowPoly.box(holder, Vector3(width, 0.62, 0.05), SIGN_BLUE, Vector3(0, 2.6, 0))
	LowPoly.box(holder, Vector3(width + 0.06, 0.04, 0.06), Color.WHITE, Vector3(0, 2.92, 0))
	var faces := SignText.make_two_faces(arabic, name, SignText.fit_size(arabic, name, 34, width - 0.2), Color.WHITE, 0.05)
	faces.position = Vector3(0, 2.6, 0)
	holder.add_child(faces)
	LowPoly.solid_cylinder(_body, 0.1, 2.0, holder.position + Vector3(0, 1.0, 0))
	_clear.add(spot, 0.8)
	signs += 1


## Bike racks: rows of steel hoops near the places riders stop.
func _bike_racks() -> void:
	var wanted: Array = []  # [spot, facing degrees]
	if _map.has("PLAZA"):
		var centre: Vector2 = _map["PLAZA"]["centre"]
		for a in [45.0, 135.0, 225.0, 315.0]:
			wanted.append([centre + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 36.0, -a + 90.0])
	if _map.has("GYM"):
		var gym: Vector3 = _map["GYM"]["position"]
		var size: Vector3 = _map["GYM"]["size"]
		wanted.append([Vector2(gym.x + size.x * 0.5 + 4.0, gym.z - size.z * 0.5 - 1.0), 0.0])
	if _map.has("INSTITUTE"):
		var inst: Vector3 = _map["INSTITUTE"]["position"]
		var size: Vector3 = _map["INSTITUTE"]["size"]
		for side in [-1.0, 1.0]:
			wanted.append([Vector2(inst.x + size.z * 0.5 + 5.0, inst.z + side * (size.x * 0.5 + 2.0)), 0.0])
	for shop: Dictionary in _map.get("RESTAURANTS", []):
		if shop.get("style", "") == "stall":
			var p: Vector3 = shop["position"]
			var facing: float = shop["facing"]
			var front := Vector2(sin(deg_to_rad(facing)), cos(deg_to_rad(facing)))
			var side := Vector2(front.y, -front.x)
			wanted.append([Vector2(p.x, p.z) + front * 5.5 + side * 8.5, facing + 90.0])
	if _map.has("SCHOOL"):
		var gate_x: float = _map["SCHOOL"]["gate_x"]
		var top: float = (_map["SCHOOL"]["area"] as Rect2).position.y
		wanted.append([Vector2(gate_x + 12.0, top - 13.0), 0.0])
	var nudges: Array[Vector2] = [Vector2.ZERO]
	for r in [2.0, 4.0, 6.0]:
		for k in 8:
			nudges.append(Vector2(cos(k * PI / 4.0), sin(k * PI / 4.0)) * r)
	for want: Array in wanted:
		var spot: Vector2 = want[0]
		for nudge in nudges:
			if _clear.is_free(spot + nudge, 1.3):
				_rack(spot + nudge, want[1])
				break


## A bike rack: five hoops on a base rail, along local X.
func _rack(spot: Vector2, facing: float) -> void:
	var holder := Node3D.new()
	holder.name = "BikeRack%d" % racks
	holder.position = Vector3(spot.x, 0, spot.y)
	holder.rotation_degrees.y = facing
	_body.add_child(holder)
	LowPoly.box(holder, Vector3(3.2, 0.06, 0.12), RACK, Vector3(0, 0.05, 0))
	for i in 5:
		var x := -1.4 + i * 0.7
		for side in [-0.3, 0.3]:
			LowPoly.box(holder, Vector3(0.05, 0.75, 0.05), RACK, Vector3(x, 0.42, side))
		LowPoly.box(holder, Vector3(0.05, 0.05, 0.65), RACK, Vector3(x, 0.8, 0))
	var shape := LowPoly.solid_box(_body, Vector3(3.2, 0.9, 0.7), holder.position + Vector3(0, 0.45, 0))
	shape.rotation.y = holder.rotation.y
	_clear.add(spot, 1.8)
	racks += 1
