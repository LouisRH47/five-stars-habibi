extends Node3D
## Builds the street-name signs and the welcome sign when the game starts, from the
## data list in data/palm_grove.gd. Every sign is Arabic on top, English below.
## Each road gets a sign near each end (StreetSign_<road>_<end>, e.g. StreetSign_0_1),
## standing beside the road and turned along it, readable from both sides.
## If the first spot is on a road, a building, a door or too near the wall, the sign
## moves to the other side of the road, then a bit further from the end.

## The map data to build from (set in the scene): data/palm_grove.gd.
@export var data: Script

const POLE_COLOUR := Color(0.6, 0.62, 0.65, 1)       # grey metal
const PLATE_COLOUR := Color(0.06, 0.38, 0.52, 1)      # blue-teal, like Dubai street signs
const WELCOME_COLOUR := Color(0.16470589, 0.5568628, 0.6117647, 1)  # the game's teal
const FRAME_COLOUR := Color(0.95, 0.88, 0.74, 1)      # light sandstone
const TEXT_COLOUR := Color(1, 1, 1, 1)

const POLE_HEIGHT := 3.2
const POLE_RADIUS := 0.06
const PLATE_HEIGHT := 0.9
const PLATE_THICKNESS := 0.06
const PLATE_MIN_WIDTH := 2.4
const PLATE_FONT_SIZE := 48
const SIGN_INWARD := 3.0     # metres in from the road end, past the crossing road's edge
const SIGN_SIDE := 1.5       # metres out from the road edge
const SIGN_STEP := 2.0       # how far to move the sign along the road if a spot is no good
const KEEP_CLEAR := 1.5      # metres kept free around buildings and the welcome sign
const ROAD_CLEAR := 1.0      # metres kept free from road edges and the roundabout
const DOOR_CLEAR := 3.5      # metres kept free around door spots (where you press E)
const WALL_CLEAR := 1.5      # metres kept free from the community wall

const WELCOME_SIZE := Vector3(6.0, 2.2, 0.15)  # the board: width, height, thickness
const WELCOME_BOTTOM := 1.2  # metres from the ground to the bottom of the board
const WELCOME_FONT_SIZE := 110

## The roads read from the data (the smoke test checks every one got its signs).
var roads: Array = []

# The constants from the data script, e.g. _map["ROADS"].
var _map: Dictionary = {}
# Ground boxes to keep clear of, as Rect2 in world x/z, and door spots as Vector2.
var _blocked: Array[Rect2] = []
var _doors: Array[Vector2] = []
var _placed: Array[Vector2] = []


func _ready() -> void:
	if data == null:
		push_error("SignBuilder has no data list set in the scene")
		return
	_map = data.get_script_constant_map()
	roads = _map["ROADS"]
	var welcome: Dictionary = _map["WELCOME_SIGN"]
	_collect_obstacles(welcome)
	_build_welcome(welcome)
	for i in roads.size():
		var road: Dictionary = roads[i]
		var from: Vector2 = road["from"]
		var to: Vector2 = road["to"]
		_build_street_sign("StreetSign_%d_0" % i, road, to, from)
		_build_street_sign("StreetSign_%d_1" % i, road, from, to)


## Remembers where the buildings, door spots and the welcome sign are.
func _collect_obstacles(welcome: Dictionary) -> void:
	var lists := [["VILLAS", "VILLA_SIZE"], ["RESTAURANTS", "RESTAURANT_SIZE"]]
	for pair in lists:
		var size: Vector3 = _map[pair[1]]
		for place in _map[pair[0]]:
			var spot: Vector3 = place["position"]
			var facing: float = place["facing"]
			_blocked.append(_footprint(spot, facing, Vector3(size.x, 0, size.z)))
			var door := PlaceBuilder.door_point(spot, facing, size)
			_doors.append(Vector2(door.x, door.z))
	var welcome_spot: Vector3 = welcome["position"]
	var welcome_facing: float = welcome["facing"]
	_blocked.append(_footprint(welcome_spot, welcome_facing, WELCOME_SIZE))


## The ground box under something, in world x/z. Only works for square-on turns (0, 90, 180).
func _footprint(spot: Vector3, facing_deg: float, size: Vector3) -> Rect2:
	var across := size.x
	var deep := size.z
	if absf(sin(deg_to_rad(facing_deg))) > 0.5:
		across = size.z
		deep = size.x
	return Rect2(spot.x - across * 0.5, spot.z - deep * 0.5, across, deep)


## A street sign near the end "end" of the road (the other end is "other").
func _build_street_sign(sign_name: String, road: Dictionary, end: Vector2, other: Vector2) -> void:
	var half_width: float = _map["ROAD_WIDTH"] * 0.5
	var along := (end - other).normalized()   # riding towards this end
	var right := Vector2(-along.y, along.x)   # the right-hand side of the road
	var spot := Vector2.INF
	var first := Vector2.INF
	for step in 6:
		var back := end - along * (half_width + SIGN_INWARD + SIGN_STEP * step)
		for side in [1.0, -1.0]:
			var candidate: Vector2 = back + right * (half_width + SIGN_SIDE) * side
			if first == Vector2.INF:
				first = candidate
			if _is_clear(candidate):
				spot = candidate
				break
		if spot != Vector2.INF:
			break
	if spot == Vector2.INF:
		push_warning("No clear spot for the %s sign, using the first one" % road["name"])
		spot = first
	_placed.append(spot)

	var english: String = road["name"]
	var arabic: String = road["arabic"]
	var font_size := SignText.fit_size(arabic, english, PLATE_FONT_SIZE, 4.0)
	var wide := maxf(SignText.text_width(english, font_size),
			SignText.text_width(arabic, roundi(font_size * SignText.ARABIC_SCALE)))
	var plate_width := maxf(PLATE_MIN_WIDTH, wide + 0.4)

	var holder := StaticBody3D.new()
	holder.name = sign_name
	holder.position = Vector3(spot.x, 0.0, spot.y)
	# Turned so the plate runs along the road: its faces look across the road.
	holder.rotation.y = atan2(right.x, right.y)
	add_child(holder)
	_add_pole(holder, Vector3.ZERO, POLE_HEIGHT)
	var plate_y := POLE_HEIGHT - PLATE_HEIGHT * 0.5
	_add_box(holder, Vector3(plate_width, PLATE_HEIGHT, PLATE_THICKNESS), PLATE_COLOUR,
			Vector3(0, plate_y, 0))
	var faces := SignText.make_two_faces(arabic, english, font_size, TEXT_COLOUR, PLATE_THICKNESS)
	faces.position.y = plate_y
	holder.add_child(faces)


## True if a street sign can stand here: not on a road or the roundabout, not in or
## next to a building, not on a door spot, not by the wall, not next to another sign.
func _is_clear(spot: Vector2) -> bool:
	var limit: float = _map["HALF_SIZE"] - WALL_CLEAR
	if absf(spot.x) > limit or absf(spot.y) > limit:
		return false
	var half_width: float = _map["ROAD_WIDTH"] * 0.5
	for road in _map["ROADS"]:
		var from: Vector2 = road["from"]
		var to: Vector2 = road["to"]
		var along := (to - from).normalized()
		var length := from.distance_to(to)
		var offset := spot - from
		# Roads are drawn half a road width longer at each end.
		var past_end := maxf(maxf(-half_width - offset.dot(along), 0.0), offset.dot(along) - length - half_width)
		var past_side := maxf(absf(offset.cross(along)) - half_width, 0.0)
		if Vector2(past_end, past_side).length() < ROAD_CLEAR:
			return false
	var centre: Vector2 = _map["ROUNDABOUT_CENTRE"]
	var ring: float = _map["ROUNDABOUT_RADIUS"]
	if spot.distance_to(centre) < ring + ROAD_CLEAR:
		return false
	for box in _blocked:
		if box.grow(KEEP_CLEAR).has_point(spot):
			return false
	for door in _doors:
		if spot.distance_to(door) < DOOR_CLEAR:
			return false
	for other in _placed:
		if spot.distance_to(other) < 3.0:
			return false
	return true


## The big welcome sign: a board on two posts, bilingual on both sides.
func _build_welcome(welcome: Dictionary) -> void:
	var holder := StaticBody3D.new()
	holder.name = "WelcomeSign"
	holder.position = welcome["position"]
	var facing: float = welcome["facing"]
	holder.rotation_degrees.y = facing
	add_child(holder)
	var post_x := WELCOME_SIZE.x * 0.5 - 0.4
	var top := WELCOME_BOTTOM + WELCOME_SIZE.y
	_add_pole(holder, Vector3(-post_x, 0, 0), top + 0.2)
	_add_pole(holder, Vector3(post_x, 0, 0), top + 0.2)
	var board_y := WELCOME_BOTTOM + WELCOME_SIZE.y * 0.5
	# A sandstone frame behind the teal board, and a solid box so you bump into it.
	var frame := Vector3(WELCOME_SIZE.x + 0.3, WELCOME_SIZE.y + 0.3, WELCOME_SIZE.z * 0.6)
	_add_box(holder, frame, FRAME_COLOUR, Vector3(0, board_y, 0))
	_add_box(holder, WELCOME_SIZE, WELCOME_COLOUR, Vector3(0, board_y, 0))
	_add_shape(holder, frame, Vector3(0, board_y, 0))
	var english: String = welcome["name"]
	var arabic: String = welcome["arabic"]
	var font_size := SignText.fit_size(arabic, english, WELCOME_FONT_SIZE, WELCOME_SIZE.x - 0.6)
	var faces := SignText.make_two_faces(arabic, english, font_size, TEXT_COLOUR, WELCOME_SIZE.z)
	faces.position.y = board_y
	holder.add_child(faces)


## A thin round pole standing at "spot", with a small solid cylinder so you bump it.
func _add_pole(holder: Node3D, spot: Vector3, height: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = POLE_RADIUS
	mesh.bottom_radius = POLE_RADIUS
	mesh.height = height
	mesh.material = _material(POLE_COLOUR)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = spot + Vector3(0, height * 0.5, 0)
	holder.add_child(view)
	var cylinder := CylinderShape3D.new()
	cylinder.radius = POLE_RADIUS * 2.0
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = view.position
	holder.add_child(shape)


func _add_box(holder: Node3D, size: Vector3, colour: Color, spot: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(colour)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = spot
	holder.add_child(view)


func _add_shape(holder: Node3D, size: Vector3, spot: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = spot
	holder.add_child(shape)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	return material
