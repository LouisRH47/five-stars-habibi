class_name PhoneOfferCard
extends RefCounted
## Session 70: the new-order parts of the phone (PRD "Polish pass", Phone). The phone keeps
## its own rows (the pick-up and drop-off line, the food chips, the note); this adds:
##   top:    the pay, big ("15 Dh"), and "1.2 km · about 3 min"
##   bottom: [Q] skip ... "18 s left" ... the E key in a ring that runs down over 30 s
## For a choice of two orders it also fills the two small cards ("1" and "2").

var top: VBoxContainer       # "OfferTop": pay and distance
var actions: HBoxContainer   # "OfferActions": skip key, time left, countdown ring
var pay: Label
var trip: Label
var time_left: Label
var skip_text: Label
var ring: CountdownRing


## Builds the two parts into the phone's rows: top just above `before`, actions just after `after`.
func build(rows: VBoxContainer, before: Control, after: Control) -> void:
	top = VBoxContainer.new()
	top.name = "OfferTop"
	top.add_theme_constant_override("separation", -10)
	top.visible = false
	pay = _label(UiPalette.FONT_BIG, UiPalette.INK)
	pay.name = "Pay"
	pay.theme_type_variation = &"BigNumber"
	top.add_child(pay)
	trip = _label(UiPalette.FONT_BODY, UiPalette.TEAL)
	trip.name = "Trip"
	top.add_child(trip)
	rows.add_child(top)
	rows.move_child(top, before.get_index())

	actions = HBoxContainer.new()
	actions.name = "OfferActions"
	actions.add_theme_constant_override("separation", 8)
	actions.visible = false
	var skip_key := Keycap.new()
	skip_key.name = "SkipKey"
	skip_key.key_text = "Q"
	skip_key.key_size = 30.0
	skip_key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(skip_key)
	skip_text = _label(UiPalette.FONT_BODY, UiPalette.INK)
	skip_text.text = "skip"
	skip_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(skip_text)
	time_left = _label(UiPalette.FONT_BODY, Color(0.36, 0.42, 0.44))
	time_left.name = "TimeLeft"
	time_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(time_left)
	ring = CountdownRing.new()
	ring.name = "Ring"
	actions.add_child(ring)
	rows.add_child(actions)
	rows.move_child(actions, after.get_index() + 1)


## Shows one order: its pay and how far it is (from where you are, via the restaurant).
func show_order(order: Order, metres: float) -> void:
	_set_text(pay, "%d Dh" % order.pay)
	_set_text(trip, trip_text(metres))
	_set_text(skip_text, "skip")
	ring.key_text = "E"


## Two orders to choose from: no big pay (each card has its own), the ring shows seconds.
func show_choice() -> void:
	_set_text(skip_text, "skip both")
	if ring.key_text != "":
		ring.key_text = ""


## The ring and the "18 s left" text. In the tutorial the order never runs out.
func set_time(seconds: float, total: float, endless: bool) -> void:
	var secs := ceili(seconds)
	ring.value = 1.0 if endless or total <= 0.0 else seconds / total
	ring.seconds_left = 99 if endless else secs
	_set_text(time_left, "no rush" if endless else "%d s left" % secs)


## "1.2 km · about 3 min" (or "450 m · about 2 min"), at the PRD's normal pace.
static func trip_text(metres: float) -> String:
	var minutes := maxi(1, roundi(metres / 1000.0 / GameConfig.OFFER_PACE_KMH * 60.0))
	return "%s · about %d min" % [distance_text(metres), minutes]


## 180 m (to the nearest 10 m) under a kilometre, then 1.2 km.
static func distance_text(metres: float) -> String:
	if metres >= 1000.0:
		return "%.1f km" % (snappedf(metres, 100.0) / 1000.0)
	return "%d m" % roundi(snappedf(metres, 10.0))


## Straight line from you to the restaurant, plus the restaurant to the villa (rounded to 0.1 km
## on the card). from: where you are now.
static func route_metres(places: PlaceBuilder, order: Order, from: Vector3) -> float:
	if places == null or order == null:
		return 0.0
	var shop := places.restaurant_approach(order.restaurant_id)
	var home := places.villa_approach(order.villa_number)
	return Vector2(from.x, from.z).distance_to(Vector2(shop.x, shop.z)) \
			+ Vector2(shop.x, shop.z).distance_to(Vector2(home.x, home.z))


## The text inside one of the two choice cards (it must keep "m route": tests read it).
static func choice_text(order: Order, metres: float, better: bool) -> String:
	var kind: String = GameConfig.SPECIAL_NAMES.get(order.special, "")
	var extra: Array[String] = []
	if order.regular != "":
		extra.append("♥ " + order.regular)
	elif order.special == "fragile":
		extra.append("Tip-friendly")
	if kind != "":
		extra.append(kind)
	if better:
		extra.append("Better offer")
	var text := "%s → %s\n%s · %s route" % [order.restaurant_name, order.map_address if order.map_address != "" else order.address,
			order.food.capitalize(), distance_text(metres)]
	if not extra.is_empty():
		text += "\n" + "  ·  ".join(extra)
	if order.special != "":
		text += "\n" + order.requirement_text()
	return text


func _label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label


## Only touch the label when the text really changes (no needless layout work each frame).
func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text
