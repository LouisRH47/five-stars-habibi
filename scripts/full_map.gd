class_name FullMap
extends CanvasLayer
## Session 67: press M for a full-screen map of the whole community. It shows the roads,
## parks, buildings and names (from the same data list the mini-map draws), where you are
## (white arrow), the pickup (orange P) and the drop-off (teal D) of the current order,
## and a legend. M or Esc closes it. The game is paused while it's open.
## Made by scripts/hud.gd; it borrows the mini-map's drawing (scripts/minimap.gd).

## The mini-map: where the map data, the bike and the order come from.
var minimap: Node

const SHADE := Color(0.03, 0.07, 0.08, 0.9)
const PANEL := Color(0.05882353, 0.1254902, 0.14901961, 0.95)
const TEAL := Color(0.16470589, 0.5568628, 0.6117647, 1)
const ORANGE := Color(0.9490196, 0.54901963, 0.15686275, 1)
const TEXT := Color(1, 0.95, 0.87, 1)
const NAME_COLOUR := Color(0.12, 0.2, 0.22, 1)
const HOME := Color(1.0, 0.95, 0.87, 1)
const MARGIN := 40.0
const LEGEND_WIDTH := 250.0

var _view: Control
var _font: Font
var _xform := Transform2D.IDENTITY
var _paused_by_me := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_font = ThemeDB.fallback_font
	var shade := ColorRect.new()
	shade.color = SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_view = Control.new()
	_view.name = "FullMapView"
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	_view.resized.connect(_view.queue_redraw)
	add_child(_view)


func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("full_map") or event.is_action_pressed("pause"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("full_map"):
		if open():
			get_viewport().set_input_as_handled()


## Opens the map (not while something else has paused the game). True if it opened.
func open() -> bool:
	if visible or minimap == null or get_tree().paused:
		return false
	get_tree().paused = true
	_paused_by_me = true
	visible = true
	_view.queue_redraw()
	return true


func close() -> void:
	if not visible:
		return
	visible = false
	if _paused_by_me:
		get_tree().paused = false
	_paused_by_me = false


func is_open() -> bool:
	return visible


## The data list's constants (ROADS, PLOTS, ...), shared with the mini-map.
func map_data() -> Dictionary:
	return minimap._map if minimap != null else {}


## World (x, z) to screen pixels: the whole community fits left of the legend, north up.
func world_xform() -> Transform2D:
	var half: Vector2 = map_data().get("MAP_HALF", Vector2(470, 250)) + Vector2(25, 15)
	var area := Rect2(Vector2(MARGIN, MARGIN + 30.0),
			_view.size - Vector2(MARGIN * 3.0 + LEGEND_WIDTH, MARGIN * 2.0 + 30.0))
	var zoom := minf(area.size.x / (half.x * 2.0), area.size.y / (half.y * 2.0))
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, area.get_center())


## Where a spot in the world is on the full map, in pixels.
func world_to_screen(spot: Vector3) -> Vector2:
	return world_xform() * Vector2(spot.x, spot.z)


## The labelled places: [name, world spot (Vector2)].
func place_names() -> Array:
	var map := map_data()
	var names: Array = []
	for cluster in map.get("CLUSTERS", []):
		names.append(["Cluster " + str(cluster["id"]).substr(1), cluster["centre"]])
	for plot in map.get("PLOTS", []):
		names.append([plot["name"], (plot["area"] as Rect2).get_center()])
	for key in ["BUS_STATION", "GYM"]:
		if map.has(key):
			var item: Dictionary = map[key]
			var at: Vector3 = item["position"]
			names.append([item["name"], Vector2(at.x, at.z)])
	if map.has("PLAZA"):
		names.append(["The Plaza", map["PLAZA"]["centre"]])
	if map.has("COMMUNITY_POOL"):
		names.append(["Community Pool", (map["COMMUNITY_POOL"] as Rect2).get_center()])
	if map.has("MAJLIS_GARDENS"):  # Session 66
		names.append(["Majlis Gardens", (map["MAJLIS_GARDENS"]["area"] as Rect2).get_center()])
	if map.has("BEEHIVES"):
		names.append(["Beekeeper", (map["BEEHIVES"] as Rect2).get_center() + Vector2(0, -6)])
	for gate in map.get("GATES", []):
		names.append([gate["name"], Vector2(gate["position"].x + 30.0, gate["position"].z)])
	names.append(["Green Spine", Vector2(130, -28)])
	return names


func _draw_view() -> void:
	if minimap == null:
		return
	_xform = world_xform()
	var title := "Wahat Al Shams"
	_text(title, Vector2(MARGIN, MARGIN + 6.0), 28, ORANGE, false)
	_text("M or Esc to close", Vector2(_view.size.x - MARGIN - LEGEND_WIDTH, MARGIN + 6.0), 18, TEXT, false)
	# The ground, parks, paving and roads, drawn exactly like the mini-map, in world metres.
	_view.draw_set_transform_matrix(_xform)
	_view.draw_rect(Rect2(Vector2(-490, -260), Vector2(980, 520)), _c("OUTSIDE"))
	minimap._draw_ground(_view)
	minimap._draw_roads(_view)
	var builder = minimap.place_builder
	if builder != null:
		for place in builder.villas:
			_view.draw_colored_polygon(minimap._block_corners(place["position"], place["facing"], builder.villa_size_of(place)), HOME)
		for place in builder.restaurants:
			_view.draw_colored_polygon(minimap._block_corners(place["position"], place["facing"], builder.restaurant_size_of(place)), place["colour"])
	var map := map_data()
	for key in ["MOSQUE", "SUPERMARKET"]:
		if map.has(key):
			_view.draw_colored_polygon(minimap._block_corners(map[key]["position"], map[key]["facing"], map[key]["size"]), _c("LANDMARK"))
	_view.draw_set_transform_matrix(Transform2D.IDENTITY)
	# Names on top, upright.
	for entry in place_names():
		_label(entry[0], _xform * entry[1], 15)
	if builder != null:
		for place in builder.restaurants:
			_label(place["name"], _xform * Vector2(place["position"].x, place["position"].z), 11)
	_draw_order_pins()
	_draw_you()
	_draw_legend()


func _draw_order_pins() -> void:
	var order := GameState.current_order
	var builder = minimap.place_builder
	if order == null or builder == null or GameState.stage == GameState.Stage.NONE:
		return
	if GameState.stage != GameState.Stage.TO_VILLA:
		_pin(_xform * _flat(builder.restaurant_door(order.restaurant_id)), ORANGE, "P", order.restaurant_name)
	_pin(_xform * _flat(builder.villa_door(order.villa_number)), TEAL, "D",
			order.map_address if order.map_address != "" else order.address)


## You: a white arrow pointing the way you face (or the walker when you're on foot).
func _draw_you() -> void:
	var body: Node3D = minimap.bike
	if body == null:
		return
	var at := _xform * _flat(body.global_position)
	var forward := -body.global_transform.basis.z
	var way := Vector2(forward.x, forward.z).normalized()
	if way == Vector2.ZERO:
		way = Vector2.UP
	var side := Vector2(-way.y, way.x)
	var arrow := PackedVector2Array([at + way * 14.0, at - way * 9.0 + side * 10.0, at - way * 4.0, at - way * 9.0 - side * 10.0])
	_view.draw_circle(at, 17.0, Color(0, 0, 0, 0.35))
	_view.draw_colored_polygon(arrow, Color.WHITE)
	arrow.append(arrow[0])
	_view.draw_polyline(arrow, _c("OUTLINE"), 2.0)
	_label("You", at + Vector2(0, -26), 15)


func _draw_legend() -> void:
	var box := Rect2(_view.size.x - MARGIN - LEGEND_WIDTH, MARGIN + 40.0, LEGEND_WIDTH, 320.0)
	_view.draw_rect(box, PANEL)
	_view.draw_rect(box, TEAL, false, 3.0)
	_text("Legend", box.position + Vector2(18, 34), 22, ORANGE, false)
	var rows := [
		["You", "arrow"], ["Pickup", "P"], ["Drop-off", "D"], ["Homes", _c("VILLA")],
		["Shops and restaurants", Color(0.55, 0.45, 0.4)], ["Roads", _c("ROAD")],
		["Parks and the spine", _c("GRASS")], ["Paving", _c("PAVING")]]
	var y := box.position.y + 70.0
	for row in rows:
		var icon := Vector2(box.position.x + 32.0, y)
		match row[1]:
			"arrow":
				_view.draw_colored_polygon(PackedVector2Array([icon + Vector2(0, -10), icon + Vector2(8, 8), icon + Vector2(0, 4), icon + Vector2(-8, 8)]), Color.WHITE)
			"P":
				_pin(icon, ORANGE, "P", "")
			"D":
				_pin(icon, TEAL, "D", "")
			_:
				_view.draw_rect(Rect2(icon - Vector2(10, 8), Vector2(20, 16)), row[1])
		_text(row[0], Vector2(box.position.x + 58.0, y + 6.0), 17, TEXT, false)
		y += 32.0


func _pin(at: Vector2, colour: Color, letter: String, name: String) -> void:
	_view.draw_circle(at, 13.0, _c("OUTLINE"))
	_view.draw_circle(at, 11.0, colour)
	_text(letter, at + Vector2(0, 6), 15, Color.WHITE, true)
	if name != "":
		_label(name, at + Vector2(0, 26), 14, colour)


## A name with a soft pale box behind it so it reads on any colour.
func _label(text: String, at: Vector2, size: int, colour := NAME_COLOUR) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var back := Rect2(at - Vector2(width * 0.5 + 4.0, size * 0.75), Vector2(width + 8.0, size * 1.3))
	_view.draw_rect(back, Color(1, 0.98, 0.92, 0.75 if colour == NAME_COLOUR else 0.95))
	_text(text, at + Vector2(0, size * 0.35), size, colour, true)


func _text(text: String, at: Vector2, size: int, colour: Color, centred: bool) -> void:
	var spot := at
	if centred:
		spot.x -= _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	_view.draw_string(_font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


## One of the mini-map's colours (scripts/minimap.gd), so both maps match.
func _c(colour_name: String) -> Color:
	return minimap.get_script().get_script_constant_map()[colour_name]


func _flat(spot: Vector3) -> Vector2:
	return Vector2(spot.x, spot.z)
