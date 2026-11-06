class_name CarParkBuilder
extends RefCounted
## Session 79 (and the Session 77 buggy park): builds every car park in the data list
## (PARKING_LOTS in data/wahat_al_shams.gd, made by tools/build_wahat_data.py) the same way:
##   asphalt where DecorBuilder hasn't paved already ("pads"),
##   white lines between the bays and painted arrows in the aisles,
##   a solar roof on posts over every row of bays,
##   a pay machine where the data puts one, and parked buggies in the buggy park.
## The parked cars themselves are ParkedCars from DecorBuilder (PARKED_CARS).
## DistrictDetail calls build(). Each car park is a node "CarPark_<name>" with its counts
## kept as meta ("bays", "roofs", "posts", "arrows") for the smoke test.

const ASPHALT := Color(0.36, 0.37, 0.39, 1)  # the same grey as DecorBuilder's car park pads
const LINE := Color(0.95, 0.95, 0.93, 1)
const PANEL := Color(0.12, 0.19, 0.34, 1)    # dark blue solar panels
const PANEL_LINE := Color(0.55, 0.62, 0.72, 1)
const METAL := Color(0.8, 0.82, 0.84, 1)
const TEAL := Color(0.16, 0.56, 0.61, 1)
const PAD := 0.03            # pads are 3 cm thick, just under the roads (4 cm)
const PAINT := PAD + 0.004   # the lines sit 4 mm on top of the pad
const BAY := 2.6             # bay width in metres (the data's BAY_WIDTH)


## Builds every car park under `parent`. Returns the holder node "CarParks".
static func build(parent: Node3D, map: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "CarParks"
	parent.add_child(holder)
	for lot: Dictionary in map.get("PARKING_LOTS", []):
		_build_lot(holder, lot)
	return holder


static func _build_lot(holder: Node3D, lot: Dictionary) -> void:
	var node := Node3D.new()
	node.name = "CarPark_" + String(lot["name"]).replace(" ", "").replace("-", "_")
	holder.add_child(node)
	for pad: Rect2 in lot.get("pads", []):
		var middle := pad.get_center()
		# Session 82: the same asphalt photo as the roads (SurfaceTextures "road"), not flat grey.
		SurfaceTextures.slab(node, "road", pad.size, Vector3(middle.x, PAD, middle.y), PAD)
	var paint := MeshKit.new()  # all the lines and arrows of this car park: one mesh
	var roofs := MeshKit.new()  # all its roofs and posts: one more mesh
	var posts := StaticBody3D.new()  # the posts are solid, the roofs are too high to hit
	posts.name = "RoofPosts"
	node.add_child(posts)
	var counts := {"bays": 0, "roofs": 0, "posts": 0, "arrows": 0}
	for row: Dictionary in lot["rows"]:
		_bay_lines(paint, row)
		counts["bays"] += (row["bays"] as Array).size()
		counts["posts"] += _roof(roofs, posts, row)
		counts["roofs"] += 1
	for arrow: Dictionary in lot.get("arrows", []):
		_arrow(paint, arrow["position"], arrow["facing"])
		counts["arrows"] += 1
	var lines := paint.finish()
	lines.name = "Markings"
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(lines)
	var tops := roofs.finish()
	tops.name = "SolarRoofs"
	node.add_child(tops)
	if lot.has("pay_machine"):
		var spot: Vector3 = lot["pay_machine"]
		LowPoly.box(node, Vector3(0.5, 1.4, 0.4), TEAL, spot + Vector3(0, 0.7, 0)).name = "PayMachine"
		LowPoly.solid_box(posts, Vector3(0.5, 1.4, 0.4), spot + Vector3(0, 0.7, 0))
	for buggy: Dictionary in lot.get("buggies", []):
		_parked_buggy(node, buggy)
	for key: String in counts:
		node.set_meta(key, counts[key])


## The row's direction from one bay to the next, and where its noses point.
static func _row_axes(row: Dictionary) -> Array:
	var facing := deg_to_rad(row["facing"])
	var nose := Vector2(sin(facing), cos(facing))
	var bays: Array = row["bays"]
	var along := Vector2(nose.y, -nose.x)
	if bays.size() > 1:
		along = ((bays[1] as Vector2) - (bays[0] as Vector2)).normalized()
	return [along, nose]


## A white line between every two bays (and at both ends), as long as a bay is deep.
static func _bay_lines(paint: MeshKit, row: Dictionary) -> void:
	var axes := _row_axes(row)
	var along: Vector2 = axes[0]
	var bays: Array = row["bays"]
	var depth: float = row["depth"]
	var turn := Basis(Vector3.UP, deg_to_rad(row["facing"]))
	var size := Vector3(GameConfig.CAR_PARK_LINE_WIDTH, 0.008, depth - 0.2)
	for k in bays.size() + 1:
		var spot: Vector2 = (bays[0] as Vector2) + along * (BAY * (k - 0.5))
		paint.box(size, LINE, Vector3(spot.x, PAINT, spot.y), turn)


## A painted arrow on the ground pointing `facing` (degrees, 0 = +z): a stem and a head.
static func _arrow(paint: MeshKit, at: Vector2, facing: float) -> void:
	var turn := Basis(Vector3.UP, deg_to_rad(facing))
	var forward := turn * Vector3.BACK
	var spot := Vector3(at.x, PAINT, at.y)
	paint.box(Vector3(0.25, 0.008, 2.0), LINE, spot - forward * 0.5, turn)
	for side in [-1.0, 1.0]:
		var wing := turn * Basis(Vector3.UP, -side * 0.65)  # the two sides of the head meet at the tip
		paint.box(Vector3(0.25, 0.008, 1.1), LINE, spot + forward * 0.55 + turn * Vector3(side * 0.32, 0, 0), wing)


## A solar roof over one row: dark blue panels on a light metal frame, leaning a little,
## on posts along the row's nose line (between bays, so the cars fit). Returns how many posts.
static func _roof(roofs: MeshKit, posts: StaticBody3D, row: Dictionary) -> int:
	var axes := _row_axes(row)
	var along: Vector2 = axes[0]
	var nose: Vector2 = axes[1]
	var bays: Array = row["bays"]
	var depth: float = row["depth"]
	var middle := ((bays[0] as Vector2) + (bays[-1] as Vector2)) * 0.5
	var length := bays.size() * BAY + 0.3
	var height := GameConfig.CAR_PARK_ROOF_HEIGHT
	var turn := Basis(Vector3.UP, deg_to_rad(row["facing"]))  # local x along the row, z to the noses
	var lean := turn * Basis(Vector3.RIGHT, GameConfig.CAR_PARK_ROOF_TILT)
	var top := Vector3(middle.x, height, middle.y)
	roofs.box(Vector3(length, 0.08, depth + 0.4), PANEL, top, lean)
	for k in range(1, bays.size()):  # thin light lines between the panels
		var x := -length * 0.5 + 0.15 + k * BAY
		roofs.box(Vector3(0.04, 0.02, depth + 0.3), PANEL_LINE, top + lean * Vector3(x, 0.05, 0), lean)
	for z in [-1.0, 0.0, 1.0]:  # beams under the panels, along the row
		roofs.box(Vector3(length, 0.12, 0.12), METAL, top + lean * Vector3(0, -0.1, z * (depth * 0.5 - 0.1)), lean)
	if not row.get("posts", true):
		return 0  # the row parked nose to nose with this one has the posts
	var count := 0
	var foot := middle + nose * (depth * 0.5 - 0.12)
	var step := GameConfig.CAR_PARK_POST_EVERY
	var ends := range(0, bays.size() + 1, step)
	if ends.back() != bays.size():
		ends.append(bays.size())
	# The nose side of the roof is the low side; the posts reach up to just under it.
	var tall := height + (lean * Vector3(0, 0, depth * 0.5 - 0.12)).y - 0.1
	for k: int in ends:
		var shift := along * (BAY * (k - bays.size() * 0.5))
		var spot := foot + shift
		roofs.box(Vector3(0.16, tall, 0.16), METAL, Vector3(spot.x, tall * 0.5, spot.y))
		# A cross beam from the post back under the roof.
		roofs.box(Vector3(0.12, 0.12, depth), METAL, top + Vector3(shift.x, -0.16, shift.y), lean)
		LowPoly.solid_box(posts, Vector3(0.16, tall, 0.16), Vector3(spot.x, tall * 0.5, spot.y))
		count += 1
	return count


## A golf buggy parked in a bay, nose to the bay's front. Solid, like the parked cars.
static func _parked_buggy(node: Node3D, buggy: Dictionary) -> void:
	var parts := LifeLooks.buggy(GameConfig.PARKED_BUGGY_COLOUR)
	var model: Node3D = parts[0]
	(parts[1] as Node).free()  # nobody sits in a parked buggy
	var body := StaticBody3D.new()
	body.name = "ParkedBuggy_%d" % node.get_child_count()
	var spot: Vector2 = buggy["position"]
	body.position = Vector3(spot.x, 0, spot.y)
	body.rotation_degrees.y = buggy["facing"] + 180.0  # the buggy model faces -z
	node.add_child(body)
	body.add_child(model)
	LowPoly.solid_box(body, Vector3(1.3, 1.9, 2.4), Vector3(0, 0.95, 0))
