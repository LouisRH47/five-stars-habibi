class_name CustomerSpawner
extends Node3D
## When you deliver, the customer comes out of the villa's front door and says a line
## (scripts/customer.gd, lines from data/customer_lines.gd). Session 32: at the school it's a
## teacher or a kid, at the stables a rider or a groom, and regulars say their own lines.
## For "leave it at the door" orders nobody comes out: a food bag is left on the doorstep
## for a few seconds instead.

## Knows where every villa is and which way it faces.
@export var place_builder: PlaceBuilder

const CUSTOMER_SCRIPT := preload("res://scripts/customer.gd")
const LINES_SCRIPT := preload("res://data/customer_lines.gd")
const BAG_COLOUR := Color(0.9490196, 0.54901963, 0.15686275, 1)  # Snackaroo orange

## The last one made (a customer or a bag), for the smoke test.
var last_spawned: Node3D


func _ready() -> void:
	GameState.order_delivered.connect(_on_order_delivered)


## A random line with the rider's name filled in.
static func pick_line(rider_name: String) -> String:
	return fill_line(LINES_SCRIPT.LINES.pick_random(), rider_name)


## What this order's customer says (Session 32): a regular says one of their own lines,
## a teacher, kid, rider or groom one of theirs, anyone else a random line.
static func line_for(order: Order, rider_name: String) -> String:
	if LINES_SCRIPT.REGULAR_STAGES.has(order.regular_id):
		var lines: Array = LINES_SCRIPT.REGULAR_STAGES[order.regular_id][GameState.regular_stage(order.regular_id)]
		return fill_line(lines.pick_random(), rider_name)
	if LINES_SCRIPT.SPOT_LINES.has(order.who):
		return fill_line(LINES_SCRIPT.SPOT_LINES[order.who].pick_random(), rider_name)
	return pick_line(rider_name)


## Puts the rider's name where a line says {name} ("habibi" if there's no name yet).
static func fill_line(line: String, rider_name: String) -> String:
	return line.replace("{name}", rider_name if rider_name != "" else GameConfig.DEFAULT_RIDER_NAME)


func _on_order_delivered(order: Order) -> void:
	var villa := _villa(order.villa_number)
	if villa.is_empty() or place_builder == null:
		return
	var angle := deg_to_rad(villa["facing"])
	var front := Vector3(sin(angle), 0.0, cos(angle))
	var wall: Vector3 = villa["position"] + front * place_builder.villa_size_of(villa).z * 0.5
	if order.leave_at_door:
		last_spawned = _leave_bag(wall + front * 0.5)
		return
	var customer := Node3D.new()
	customer.set_script(CUSTOMER_SCRIPT)
	customer.name = "Customer"
	if villa.get("interior", false):
		wall = place_builder.villa_door(order.villa_number) - front * 0.8
	customer.position = wall - front * 0.2  # just inside the door
	customer.rotation.y = angle             # facing out of the house (+Z = front)
	add_child(customer)
	var line := line_for(order, GameState.rider_name)
	GameState.note_customer_line(line)
	customer.setup(line, order.who, order.look)
	last_spawned = customer


func _leave_bag(spot: Vector3) -> Node3D:
	var bag := Node3D.new()
	bag.name = "LeftBag"
	bag.position = spot
	add_child(bag)
	LowPoly.box(bag, Vector3(0.4, 0.35, 0.3), BAG_COLOUR, Vector3(0, 0.175, 0))
	LowPoly.box(bag, Vector3(0.3, 0.12, 0.03), Color(1, 1, 1, 1), Vector3(0, 0.42, 0))  # handle
	get_tree().create_timer(GameConfig.PARCEL_STAYS_TIME, false).timeout.connect(bag.queue_free)
	return bag


func _villa(number: int) -> Dictionary:
	if place_builder == null:
		return {}
	for villa in place_builder.villas:
		if villa["number"] == number:
			return villa
	return {}
