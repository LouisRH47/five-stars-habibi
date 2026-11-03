extends CanvasLayer
## The mini-map (bottom left). It turns with you: the way you're riding is always "up",
## and you're the white arrow in the middle. It draws the roads, the roundabout, the
## villas with their house numbers and the restaurants straight from the map's data list
## (the same list PlaceBuilder builds from), so moving a villa moves it here too.
## During an order an orange pin marks the next stop, with the villa number (or the
## restaurant name) and how far away it is. If the stop is off the map, the pin sits on
## the edge and points the way. The little "N" on the edge shows where north is.
## Sizes and zoom are in the Mini-map block of scripts/game_config.gd.

## The bike: the map is centred on it and turns with it.
@export var bike: Node3D
## Where the next stop is (and whether there is one).
@export var delivery_manager: DeliveryManager
## Knows every villa and restaurant, and which data list the map came from.
@export var place_builder: PlaceBuilder

const OUTSIDE := Color(0.62, 0.53, 0.38, 1)       # desert outside the walls
const GROUND := Color(0.91, 0.83, 0.65, 1)        # sand inside
const WALL := Color(0.98, 0.93, 0.8, 1)
const ROAD := Color(0.36, 0.37, 0.4, 1)
const GRASS := Color(0.45, 0.65, 0.35, 1)
const PAVING := Color(0.8, 0.74, 0.62, 1)
const LANDMARK := Color(0.95, 0.9, 0.78, 1)       # mosque and mini market
const VILLA := Color(1.0, 0.95, 0.87, 1)
const VILLA_NUMBER := Color(0.12, 0.2, 0.22, 1)
const TARGET := Color(0.9490196, 0.54901963, 0.15686275, 1)  # same orange as the beam
const PLAYER := Color(1, 1, 1, 1)
const OUTLINE := Color(0.06, 0.13, 0.15, 1)
const NUMBER_SIZE := 12
const LABEL_SIZE := 15
const BAR_HEIGHT := 26.0  # the strip along the bottom that names the next stop

## The parked bike while you walk (Session 19), drawn as a little bike; null while riding.
var parked_bike: Node3D
## Where road works are (Session 33): a cone is drawn at each spot (x, z). Set by EventManager.
var road_works_at: Array = []

var _map: Dictionary = {}  # the data list's constants, e.g. _map["ROADS"]
var _font: Font
var _static_root: Node2D
var _land: Node2D
var _background: Control
var _map_xform := Transform2D.IDENTITY
var _home_labels: Array = []
var _number_candidates: Array = []
var _target_buildings := {}
var _last_candidate_position := Vector2(INF, INF)
var _candidate_revision := 0
var _number_widths := {}
var _ascents := {}

## Individual canvas items let the renderer cull off-map groups of buildings.
## Their draw commands are recorded once, rather than rebuilding 500 polygons per frame.
class BuildingChunk extends Node2D:
	var polygons: Array[PackedVector2Array] = []
	var colours: Array[Color] = []
	func _draw() -> void:
		for i in polygons.size():
			draw_colored_polygon(polygons[i], colours[i])

@onready var _view: Control = $Panel/Margin/Window/View/Map
var _ring: Control


func _ready() -> void:
	_font = ThemeDB.fallback_font
	$Panel.custom_minimum_size = Vector2.ONE * GameConfig.MINIMAP_SIZE
	if place_builder != null and place_builder.data != null:
		_map = place_builder.data.get_script_constant_map()
	var viewport := _view.get_viewport() as SubViewport
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_build_static_map()
	_view.draw.connect(_draw_map)
	# Round, like the mockup (Session 20): the map is drawn into its own little viewport,
	# which ui/round_mask.gdshader cuts to a circle, with a white ring on top.
	_ring = Control.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(func(): _ring.draw_arc(_ring.size * 0.5, _ring.size.x * 0.5 - 2.0, 0.0, TAU, 96, PLAYER, 4.0, true))
	$Panel/Margin.add_child(_ring)
	_ring.resized.connect(_ring.queue_redraw)
	_view.resized.connect(_background.queue_redraw)
	_ring.queue_redraw()
	if bike != null:
		_map_xform = _world_xform(bike.get_global_transform_interpolated())
		_static_root.transform = _map_xform
		_refresh_number_candidates()


func _process(_delta: float) -> void:
	if not visible or bike == null:
		return
	_map_xform = _world_xform(bike.get_global_transform_interpolated())
	_static_root.transform = _map_xform
	_refresh_number_candidates()
	_view.queue_redraw()


## Where a spot in the world shows up on the mini-map, in pixels from its top-left corner.
## Can be outside the map if the spot is far away.
func world_to_map(spot: Vector3) -> Vector2:
	return _world_xform(bike.global_transform) * Vector2(spot.x, spot.z)


## True while there's a stop to ride to (after accepting, until you drop off).
func has_target() -> bool:
	var stage := GameState.stage
	return delivery_manager != null and GameState.current_order != null \
			and (stage == GameState.Stage.TO_RESTAURANT or stage == GameState.Stage.TO_VILLA)


## The text on the pin: the villa number, or the restaurant name before pickup.
func target_label() -> String:
	if not has_target():
		return ""
	var order := GameState.current_order
	if GameState.stage == GameState.Stage.TO_RESTAURANT:
		return order.restaurant_name
	return order.map_address if order.map_address != "" else order.address


## Where the pin is drawn: on the stop itself, or pinned to the edge if it's off the map.
func target_on_map() -> Vector2:
	return pin_spot(world_to_map(delivery_manager.target_door()))


## Turns world spots (x, z) into mini-map pixels: the bike in the middle, its heading up.
func _world_xform(bike_xform: Transform3D) -> Transform2D:
	var forward := -bike_xform.basis.z
	var heading := Vector2(forward.x, forward.z)
	var turn := 0.0 if heading.length() < 0.001 else -PI * 0.5 - heading.angle()
	var zoom := _view.size.x / GameConfig.MINIMAP_METRES_ACROSS
	var spot := Vector2(bike_xform.origin.x, bike_xform.origin.z)
	return Transform2D(turn, Vector2(zoom, zoom), 0.0, _view.size * 0.5) * Transform2D(0.0, -spot)


## Where a pin for this map spot is drawn: on it, or pinned to the edge if it's off the map.
func pin_spot(spot: Vector2) -> Vector2:
	# The map is round (Session 20): keep pins inside the circle, clear of the name strip.
	var centre := _view.size * 0.5
	var reach := centre.x - GameConfig.MINIMAP_EDGE_INSET
	var away := spot - centre
	if away.length() > reach:
		away = away.normalized() * reach
	var floor_y := _view.size.y - BAR_HEIGHT - GameConfig.MINIMAP_EDGE_INSET * 0.5
	var pin := centre + away
	if pin.y > floor_y:
		pin.y = floor_y
	return pin


func _draw_map() -> void:
	if bike == null:
		return
	# Smooth position (physics interpolation is on), so the map doesn't jitter.
	var xform := _map_xform
	_view.draw_set_transform_matrix(xform)
	_draw_target_building()
	_draw_gps_route()
	_view.draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_villa_numbers(xform)
	_draw_road_works(xform)
	_draw_north(xform)
	_draw_target(xform)
	_draw_parked_bike(xform)
	_draw_player()


# --- Drawn in world metres (the map transform is on) ---

func _draw_ground(canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = _view
	var half := Vector2.ZERO
	if _map.has("HALF_SIZE"):
		half = Vector2.ONE * _map["HALF_SIZE"]
	elif _map.has("MAP_HALF"):
		half = _map["MAP_HALF"]
	if half != Vector2.ZERO:
		canvas.draw_rect(Rect2(-half, half * 2.0), GROUND)
		canvas.draw_rect(Rect2(-half, half * 2.0), WALL, false, 2.0)
	for plot in _map.get("PLOTS", []):
		canvas.draw_rect(plot["area"], plot["colour"])
	if _map.has("SPINE"):
		canvas.draw_rect(_map["SPINE"], GRASS)
	if _map.has("PLAZA"):
		canvas.draw_circle(_map["PLAZA"]["centre"], _map["PLAZA"]["radius"], PAVING)
	for area in _map.get("PAVED_AREAS", []):
		canvas.draw_rect(area, PAVING)
	if _map.has("PARK"):
		canvas.draw_rect(_map["PARK"]["area"], GRASS)
	for area in _map.get("PARK_PATHS", []):
		canvas.draw_rect(area, PAVING)
	for area in _map.get("PARKING_AREAS", []):
		canvas.draw_rect(area, ROAD)


func _draw_roads(canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = _view
	var width: float = _map.get("ROAD_WIDTH", 8.0)
	for road in _map.get("ROADS", []):
		# One road-width longer, like the real roads, so corners are filled in.
		var road_width: float = road.get("width", width)
		var along: Vector2 = (road["to"] - road["from"]).normalized() * road_width * 0.5
		canvas.draw_line(road["from"] - along, road["to"] + along, ROAD if road_width >= 6.0 else PAVING.darkened(0.2), road_width)
	if _map.has("ROUNDABOUT_CENTRE"):
		canvas.draw_circle(_map["ROUNDABOUT_CENTRE"], _map["ROUNDABOUT_RADIUS"], ROAD)
		canvas.draw_circle(_map["ROUNDABOUT_CENTRE"], _map["ROUNDABOUT_ISLAND_RADIUS"], GRASS)


func _build_static_map() -> void:
	_background = Control.new()
	_background.name = "MapBackground"
	_background.show_behind_parent = true
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_background)
	_background.draw.connect(func(): _background.draw_rect(Rect2(Vector2.ZERO, _view.size), OUTSIDE))
	_static_root = Node2D.new()
	_static_root.name = "StaticMap"
	_static_root.show_behind_parent = true
	_view.add_child(_static_root)
	_land = Node2D.new()
	_land.name = "GroundAndRoads"
	_static_root.add_child(_land)
	_land.draw.connect(func(): _draw_ground(_land); _draw_roads(_land))
	var chunks := {}
	for key in ["MOSQUE", "SUPERMARKET"]:
		if _map.has(key):
			_cache_block(chunks, _map[key]["position"], _map[key]["facing"], _map[key]["size"], LANDMARK)
	if place_builder == null:
		return
	for place in place_builder.villas:
		var size := place_builder.villa_size_of(place)
		_cache_block(chunks, place["position"], place["facing"], size, VILLA)
		_target_buildings[int(place["number"])] = [place["position"], place["facing"], size]
		if not PlaceBuilder.is_spot(place):
			_home_labels.append([Vector2(place["position"].x, place["position"].z), str(place.get("house", place["number"]))])
	for place in place_builder.restaurants:
		_cache_block(chunks, place["position"], place["facing"], place_builder.restaurant_size_of(place), place["colour"])
	_background.queue_redraw()
	_land.queue_redraw()


func _cache_block(chunks: Dictionary, spot: Vector3, facing: float, size: Vector3, colour: Color) -> void:
	var cell := Vector2i(floori(spot.x / 64.0), floori(spot.z / 64.0))
	if not chunks.has(cell):
		var chunk := BuildingChunk.new()
		chunk.name = "Buildings_%d_%d" % [cell.x, cell.y]
		chunk.position = Vector2(cell) * 64.0 + Vector2.ONE * 32.0
		_static_root.add_child(chunk)
		chunks[cell] = chunk
	var chunk := chunks[cell] as BuildingChunk
	chunk.polygons.append(_block_corners(spot, facing, size, chunk.position))
	chunk.colours.append(colour)


func _refresh_number_candidates() -> void:
	var at := Vector2(bike.global_position.x, bike.global_position.z)
	if at.distance_squared_to(_last_candidate_position) < 25.0:
		return
	_last_candidate_position = at
	_candidate_revision += 1
	_number_candidates.clear()
	# Include the square viewport's diagonal plus the five-metre movement allowance.
	var radius := GameConfig.MINIMAP_METRES_ACROSS * 0.75 + 6.0
	for entry: Array in _home_labels:
		if at.distance_squared_to(entry[0]) <= radius * radius:
			_number_candidates.append(entry)


func _draw_target_building() -> void:
	if not has_target() or GameState.stage != GameState.Stage.TO_VILLA:
		return
	var number: int = GameState.current_order.villa_number
	if _target_buildings.has(number):
		var building: Array = _target_buildings[number]
		_draw_block(building[0], building[1], building[2], TARGET)


## A building seen from above: width across its front, depth front to back, turned to face its way.
func _draw_block(spot: Vector3, facing_deg: float, size: Vector3, colour: Color) -> void:
	_view.draw_colored_polygon(_block_corners(spot, facing_deg, size), colour)


func _block_corners(spot: Vector3, facing_deg: float, size: Vector3, origin := Vector2.ZERO) -> PackedVector2Array:
	var angle := deg_to_rad(facing_deg)
	var front := Vector2(sin(angle), cos(angle)) * size.z * 0.5
	var side := Vector2(cos(angle), -sin(angle)) * size.x * 0.5
	var middle := Vector2(spot.x, spot.z) - origin
	return PackedVector2Array([middle + front + side, middle + front - side,
			middle - front - side, middle - front + side])


# --- Drawn in pixels (upright, so text never turns upside down) ---

func _draw_villa_numbers(xform: Transform2D) -> void:
	var bounds := Rect2(Vector2.ZERO, _view.size).grow(-6.0)
	for entry: Array in _number_candidates:
		var spot: Vector2 = xform * entry[0]
		if bounds.has_point(spot):
			_text(entry[1], spot, NUMBER_SIZE, VILLA_NUMBER)


func _draw_north(xform: Transform2D) -> void:
	var north := xform.basis_xform(Vector2.UP).normalized()
	var spot := _view.size * 0.5 + north * (_view.size.x * 0.5 - 18.0)
	_view.draw_circle(spot, 9.0, OUTLINE)
	_text("N", spot, NUMBER_SIZE, PLAYER)


func _draw_target(xform: Transform2D) -> void:
	if not has_target():
		return
	var door := delivery_manager.target_door()
	var exact := xform * Vector2(door.x, door.z)
	var spot := pin_spot(exact)
	if spot.distance_to(exact) > 0.5:
		# Off the map: an arrow on the edge pointing the way to go.
		var way := (exact - _view.size * 0.5).normalized()
		var side := Vector2(-way.y, way.x)
		_view.draw_colored_polygon(PackedVector2Array([spot + way * 11.0, spot - way * 7.0 + side * 8.0,
				spot - way * 7.0 - side * 8.0]), TARGET)
	else:
		# On the map: an orange pin, with the house number in it when it's a villa.
		var to_villa := GameState.stage == GameState.Stage.TO_VILLA
		_view.draw_circle(spot, 12.0 if to_villa else 8.0, OUTLINE)
		_view.draw_circle(spot, 10.0 if to_villa else 6.0, TARGET)
		if to_villa:
			_text(_house_number(), spot, NUMBER_SIZE, PLAYER)
	# The strip along the bottom: where to go and how far it is.
	var metres := roundi(Vector2(bike.global_position.x - door.x, bike.global_position.z - door.z).length())
	var name := target_label()
	var bar := Rect2(_view.size.x * 0.15, _view.size.y - BAR_HEIGHT - 10.0, _view.size.x * 0.7, BAR_HEIGHT)
	_view.draw_rect(bar, OUTLINE)
	_text("%s   %d m" % [name, metres], bar.get_center(), LABEL_SIZE, TARGET)


## The parked bike: a teal dot with a white ring (pinned to the edge if it's far away).
func _draw_parked_bike(xform: Transform2D) -> void:
	if parked_bike == null:
		return
	var spot := pin_spot(xform * Vector2(parked_bike.global_position.x, parked_bike.global_position.z))
	_view.draw_circle(spot, 8.0, PLAYER)
	_view.draw_circle(spot, 6.0, Color(0.16470589, 0.5568628, 0.6117647, 1))
	_text("B", spot, NUMBER_SIZE - 2, PLAYER)


## The number on the door of the villa you're going to (inside its cluster).
func _house_number() -> String:
	for place in place_builder.villas:
		if place["number"] == GameState.current_order.villa_number:
			return "" if PlaceBuilder.is_spot(place) else str(place.get("house", place["number"]))
	return ""


## You: a white arrow in the middle, always pointing up (the way you're riding).
func _draw_player() -> void:
	var c := _view.size * 0.5
	var arrow := PackedVector2Array([c + Vector2(0, -11), c + Vector2(8, 8), c + Vector2(0, 4), c + Vector2(-8, 8)])
	_view.draw_colored_polygon(arrow, PLAYER)
	arrow.append(arrow[0])
	_view.draw_polyline(arrow, OUTLINE, 1.5)


## Text centred on a spot.
func _text(text: String, centre: Vector2, size: int, colour: Color) -> void:
	var width := 0.0
	if size == NUMBER_SIZE:
		if not _number_widths.has(text):
			_number_widths[text] = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		width = _number_widths[text]
	else:
		width = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if not _ascents.has(size):
		_ascents[size] = _font.get_ascent(size)
	var baseline := centre + Vector2(-width * 0.5, _ascents[size] * 0.5 - 1.0)
	_view.draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


## Road works (Session 33): a little orange cone with a white stripe, on a dark circle.
func _draw_road_works(xform: Transform2D) -> void:
	for at: Vector2 in road_works_at:
		var spot := xform * at
		if spot.distance_to(_view.size * 0.5) > _view.size.x * 0.5 - 8.0:
			continue  # only while it's on the map
		_view.draw_circle(spot, 11.0, OUTLINE)
		_view.draw_colored_polygon(PackedVector2Array([spot + Vector2(0, -8), spot + Vector2(6, 6),
				spot + Vector2(-6, 6)]), TARGET)
		_view.draw_line(spot + Vector2(-3.5, 1), spot + Vector2(3.5, 1), PLAYER, 2.0)
		_view.draw_line(spot + Vector2(-8, 7), spot + Vector2(8, 7), TARGET, 2.0)


## The line uses exactly the collision-safe route shown on the ground.
func _draw_gps_route() -> void:
	if GameState.upgrade_level("gps") <= 0 or delivery_manager == null:
		return
	var gps := delivery_manager.get_node_or_null("GPSRoute") as GPSRoute
	if gps == null or gps.points.size() < 2:
		return
	for index in gps.points.size() - 1:
		_view.draw_line(gps.points[index], gps.points[index + 1], Color(0.1, 0.95, 0.9), 1.0, true)
