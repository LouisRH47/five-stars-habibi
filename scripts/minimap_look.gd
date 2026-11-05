class_name MinimapLook
extends RefCounted
## Session 70: the nicer mini-map drawing (GameConfig.MINIMAP_V2). scripts/minimap.gd keeps
## the map itself (the cached ground, roads and buildings, the zoom and the turning); this
## draws what goes on top of it each frame:
##   - house numbers, skipping any that would sit on top of another one
##   - round logo pins for the restaurants and shops (the made-up logos in assets/logos)
##   - the drop-off pin with its house number (or the restaurant's logo before pick-up)
##   - an arrow on the ring when the stop is off the map
##   - you, as an arrow (it turns when the map is North up)
## and, on the ring over the map: the dark compass ring with N, E, S, W and the
## "Villa 7 · 180 m" pill under the map.

const RING := Color(0.07, 0.13, 0.15, 1)
const RING_EDGE := Color(1, 1, 1, 0.35)
const NUMBER := Color(0.2, 0.26, 0.27, 0.9)
const KERB := Color(0.97, 0.93, 0.84, 1)

var map: CanvasLayer
var _logos := {}        # restaurant or shop id -> Texture2D
var _logo_spots: Array = []  # [world spot (x, z), id]


func _init(owner: CanvasLayer) -> void:
	map = owner
	var places: PlaceBuilder = map.place_builder
	if places != null:
		for place in places.restaurants:
			_add_logo(str(place["id"]), Vector2(place["position"].x, place["position"].z))


func _add_logo(id: String, spot: Vector2) -> void:
	var path := "res://assets/logos/%s_badge.svg" % id
	if not ResourceLoader.exists(path):
		return
	if not _logos.has(id):
		_logos[id] = load(path)
	_logo_spots.append([spot, id])


## The panel round the map: dark, so it reads as one thick compass ring.
func style_panel() -> void:
	var panel: PanelContainer = map.get_node("Panel")
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.bg_color = RING
	style.border_color = RING
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	# Logos are drawn small: smooth them (mipmaps) instead of letting them sparkle.
	map._view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for entry: Array in map._shop_icons:
		if entry.size() > 3:
			_add_logo(str(entry[3]), entry[0])


## Roads get a pale kerb on both sides (drawn once, in the cached ground layer).
static func draw_kerbs(canvas: CanvasItem, roads: Array, width: float) -> void:
	for road in roads:
		var road_width: float = road.get("width", width)
		if road_width < 6.0:
			continue
		var along: Vector2 = (road["to"] - road["from"]).normalized() * road_width * 0.5
		canvas.draw_line(road["from"] - along, road["to"] + along, KERB, road_width + 1.6)


# --- The ring over the map ---

func draw_ring() -> void:
	var ring: Control = map._ring
	var centre := ring.size * 0.5
	var width := GameConfig.MINIMAP_RING_WIDTH
	var outer := ring.size.x * 0.5
	ring.draw_arc(centre, outer - width * 0.5, 0.0, TAU, 96, RING, width + 1.0, true)
	ring.draw_arc(centre, outer - width, 0.0, TAU, 96, RING_EDGE, 1.5, true)
	if map.bike == null:
		return
	var xform: Transform2D = map._map_xform
	var font: Font = map._font
	var letters := [["N", Vector2.UP], ["E", Vector2.RIGHT], ["S", Vector2.DOWN], ["W", Vector2.LEFT]]
	for item: Array in letters:
		var way: Vector2 = xform.basis_xform(item[1]).normalized()
		var spot: Vector2 = centre + way * (outer - width * 0.5)
		var north: bool = item[0] == "N"
		var size := 17 if north else 13
		var colour := UiPalette.ORANGE if north else Color(1, 1, 1, 0.8)
		_centred(ring, font, item[0], spot, size, colour)
	if map.has_target():
		_draw_edge_arrow(ring, xform)
		_draw_target_pill(ring, centre, outer)


## Off the map: an orange arrow on the ring, pointing the way to go.
func _draw_edge_arrow(ring: Control, xform: Transform2D) -> void:
	var door: Vector3 = map.delivery_manager.target_door()
	var exact := xform * Vector2(door.x, door.z)
	if map.pin_spot(exact).distance_to(exact) <= 0.5:
		return
	# The ring sits over the map's little viewport, offset by nothing: same pixel spots.
	var centre: Vector2 = map._view.size * 0.5
	var way := (exact - centre).normalized()
	var spot: Vector2 = arrow_spot(exact) + (ring.size - map._view.size) * 0.5
	var side := Vector2(-way.y, way.x)
	var tip := PackedVector2Array([spot + way * 12.0, spot - way * 8.0 + side * 10.0, spot - way * 3.0, spot - way * 8.0 - side * 10.0])
	ring.draw_colored_polygon(tip, UiPalette.ORANGE)
	tip.append(tip[0])
	ring.draw_polyline(tip, Color.WHITE, 1.5, true)


## "C3 · Villa 45 · 180 m" in a dark pill sitting on the bottom of the ring.
func _draw_target_pill(ring: Control, centre: Vector2, outer: float) -> void:
	var door: Vector3 = map.delivery_manager.target_door()
	var at: Vector3 = map.bike.global_position
	var metres := Vector2(at.x - door.x, at.z - door.z).length()
	var text := "%s  ·  %s" % [map.target_label(), PhoneOfferCard.distance_text(metres)]
	var font: Font = map._font
	var size := 16
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 28.0
	var box := Rect2(Vector2(centre.x - width * 0.5, centre.y + outer - 18.0), Vector2(width, 30.0))
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.TEAL
	style.border_color = RING
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	ring.draw_style_box(style, box)
	_centred(ring, font, text, box.get_center(), size, Color.WHITE)


# --- On the map (pixels, upright) ---

func draw_map(xform: Transform2D) -> void:
	var view: Control = map._view
	_draw_numbers(view, xform)
	_draw_logos(view, xform)
	map._draw_road_works(xform)
	_draw_target(view, xform)
	map._draw_parked_bike(xform)
	_draw_player(view)


## House numbers, but never two on top of each other (the nearest one wins).
func _draw_numbers(view: Control, xform: Transform2D) -> void:
	var bounds := Rect2(Vector2.ZERO, view.size).grow(-6.0)
	var taken := {}
	var centre := view.size * 0.5
	for entry: Array in map._number_candidates:
		var spot: Vector2 = xform * entry[0]
		if not bounds.has_point(spot) or spot.distance_to(centre) > centre.x - GameConfig.MINIMAP_RING_WIDTH - 8.0:
			continue
		var cell := Vector2i(floori(spot.x / 20.0), floori(spot.y / 13.0))
		if taken.has(cell) or taken.has(cell + Vector2i(1, 0)) or taken.has(cell - Vector2i(1, 0)):
			continue
		taken[cell] = true
		map._text(entry[1], spot, map.NUMBER_SIZE, NUMBER)


func _draw_logos(view: Control, xform: Transform2D) -> void:
	var centre := view.size * 0.5
	var reach := centre.x - GameConfig.MINIMAP_RING_WIDTH - 4.0
	var half := GameConfig.MINIMAP_LOGO_SIZE * 0.5
	for entry: Array in _logo_spots:
		var spot: Vector2 = xform * entry[0]
		if spot.distance_to(centre) > reach:
			continue
		view.draw_circle(spot + Vector2(0, 1.5), half + 2.5, Color(0, 0, 0, 0.3))
		view.draw_circle(spot, half + 1.5, Color.WHITE)
		view.draw_texture_rect(_logos[entry[1]], Rect2(spot - Vector2(half, half), Vector2(half, half) * 2.0), false)


func _draw_target(view: Control, xform: Transform2D) -> void:
	if not map.has_target():
		return
	var door: Vector3 = map.delivery_manager.target_door()
	var exact := xform * Vector2(door.x, door.z)
	var spot: Vector2 = map.pin_spot(exact)
	var centre := view.size * 0.5
	if spot.distance_to(exact) > 0.5:
		return  # off the map: the arrow is drawn on the ring (draw_ring), over the map's edge
	# On the map: a pin standing on the door, with the house number (or the logo) in its head.
	var head := spot - Vector2(0, 18)
	view.draw_colored_polygon(PackedVector2Array([spot, head + Vector2(-8, 6), head + Vector2(8, 6)]), map.OUTLINE)
	view.draw_circle(head, 13.0, map.OUTLINE)
	view.draw_circle(head, 11.0, UiPalette.ORANGE)
	view.draw_circle(spot, 3.0, map.OUTLINE)
	if GameState.stage == GameState.Stage.TO_VILLA:
		map._text(map._house_number(), head, map.NUMBER_SIZE, Color.WHITE)
	else:
		var id := str(GameState.current_order.restaurant_id)
		if _logos.has(id):
			view.draw_texture_rect(_logos[id], Rect2(head - Vector2(9, 9), Vector2(18, 18)), false)


## Where the edge arrow sits for a stop at this map spot: on the ring, the way to go.
func arrow_spot(exact: Vector2) -> Vector2:
	var centre: Vector2 = map._view.size * 0.5
	return centre + (exact - centre).normalized() * (centre.x - GameConfig.MINIMAP_RING_WIDTH * 0.5 - 4.0)


## You: a white arrow in the middle. Heading-up: always up. North-up: it turns with you.
func _draw_player(view: Control) -> void:
	var c := view.size * 0.5
	var turn := 0.0
	if Settings.minimap_north_up and map.bike != null:
		var forward: Vector3 = -map.bike.global_transform.basis.z
		turn = Vector2(forward.x, forward.z).angle() + PI * 0.5
	var shape := [Vector2(0, -12), Vector2(9, 9), Vector2(0, 4), Vector2(-9, 9)]
	var arrow := PackedVector2Array()
	for point: Vector2 in shape:
		arrow.append(c + point.rotated(turn))
	view.draw_circle(c, 15.0, Color(1, 1, 1, 0.25))
	view.draw_colored_polygon(arrow, UiPalette.TEAL)
	arrow.append(arrow[0])
	view.draw_polyline(arrow, Color.WHITE, 2.0, true)


func _centred(canvas: CanvasItem, font: Font, text: String, centre: Vector2, size: int, colour: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := centre + Vector2(-width * 0.5, font.get_ascent(size) * 0.5 - 1.0)
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
