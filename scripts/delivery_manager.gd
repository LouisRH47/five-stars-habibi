class_name DeliveryManager
extends Node
## Runs the delivery loop: new orders pop up, E accepts, Q skips, ride to the
## glowing beam at the restaurant, E picks up, ride to the beam at the villa, E delivers.
## The order itself and the money live in GameState. This script only decides when
## things happen. Numbers are in scripts/game_config.gd.
## Keys come in through _unhandled_input, so nothing happens while the game is paused.

## The bike, to check how close it is to the next door.
@export var bike: Node3D
## Knows where every restaurant and villa door is.
@export var place_builder: PlaceBuilder

## Seconds an order waits on the phone before it counts as skipped.
## Starts at the GameConfig value. The smoke test shortens it so it doesn't wait 30 s.
var offer_timeout := GameConfig.ORDER_OFFER_TIMEOUT

var _offer_left := 0.0
var _wait_left := GameConfig.ORDER_NEXT_DELAY
var _marker: MeshInstance3D


func _ready() -> void:
	_marker = _make_marker()
	add_child(_marker)
	GameState.order_stage_changed.connect(_on_stage_changed)
	_on_stage_changed(GameState.stage)


func _physics_process(delta: float) -> void:
	if GameState.tutorial_running:
		return  # the tutorial hands out its own order, and it never runs out
	if GameState.stage == GameState.Stage.NONE:
		_wait_left -= delta
		if _wait_left <= 0.0:
			_wait_left = GameConfig.ORDER_NEXT_DELAY
			offer_now()
	elif GameState.stage == GameState.Stage.OFFERED:
		_offer_left -= delta
		if _offer_left <= 0.0:
			skip()  # ignoring an order counts as skipping it (PRD)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if GameState.stage == GameState.Stage.OFFERED:
			accept()
		else:
			try_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("skip_order"):
		skip()
		get_viewport().set_input_as_handled()


## Makes a new order and puts it on the phone right away. Returns null if you
## already have an order. The timer calls this, and so does the smoke test.
func offer_now() -> Order:
	if GameState.stage != GameState.Stage.NONE or place_builder == null or not GameState.shift_open():
		return null  # also no new orders once the shift clock has run out
	var order := make_order()
	GameState.offer_order(order)
	return order


## Picks a random restaurant and villa. If you skip a lot (acceptance rate under
## 70%), you get a boring order instead: a short ride for the lowest pay (PRD).
## restaurant_id and villa_number pick an exact order (the tutorial uses this).
func make_order(restaurant_id := "", villa_number := 0) -> Order:
	var restaurant: Dictionary = place_builder.restaurants.pick_random()
	for place in place_builder.restaurants:
		if place["id"] == restaurant_id:
			restaurant = place
	var from := place_builder.restaurant_door(restaurant["id"])
	var boring := GameState.acceptance_rate() < GameConfig.ORDER_LOW_ACCEPTANCE and villa_number == 0
	var villa: Dictionary = place_builder.villas.pick_random()
	for place in place_builder.villas:
		if place["number"] == villa_number:
			villa = place
	if boring:
		villa = _short_ride_villa(from)
	var to := place_builder.villa_door(villa["number"])

	var order := Order.new()
	order.restaurant_id = restaurant["id"]
	order.restaurant_name = restaurant["name"]
	order.food = restaurant["food"]
	order.villa_number = villa["number"]
	order.boring = boring
	order.pay = GameConfig.ORDER_PAY_MIN if boring else _pay_for(from.distance_to(to))
	# Some customers add a short note, like "Leave it at the door, please".
	if randf() < GameConfig.ORDER_LEAVE_AT_DOOR_CHANCE:
		order.leave_at_door = true
		order.note = GameConfig.ORDER_LEAVE_AT_DOOR_NOTE
	elif randf() < GameConfig.ORDER_NOTE_CHANCE:
		order.note = GameConfig.ORDER_NOTES.pick_random()
	return order


## E on a new order.
func accept() -> bool:
	return GameState.accept_offer()


## Q on a new order (also used when the offer runs out of time).
func skip() -> bool:
	return GameState.skip_offer()


## E near the restaurant picks up; E near the villa delivers.
## Returns false if you're not close enough to the right door.
func try_interact() -> bool:
	if not is_near_target():
		return false
	if GameState.stage == GameState.Stage.TO_RESTAURANT:
		return GameState.pick_up()
	return GameState.deliver()


## True when the bike is within INTERACT_RADIUS of the door you need to go to next.
func is_near_target() -> bool:
	var stage := GameState.stage
	if bike == null or (stage != GameState.Stage.TO_RESTAURANT and stage != GameState.Stage.TO_VILLA):
		return false
	var gap := bike.global_position - target_door()
	gap.y = 0.0  # only the distance along the ground counts
	return gap.length() <= GameConfig.INTERACT_RADIUS


## Where you need to ride next: the restaurant door, then the villa door.
func target_door() -> Vector3:
	var order := GameState.current_order
	if order == null or place_builder == null:
		return Vector3.ZERO
	if GameState.stage == GameState.Stage.TO_RESTAURANT:
		return place_builder.restaurant_door(order.restaurant_id)
	return place_builder.villa_door(order.villa_number)


## Seconds left before the order on the phone counts as skipped (0 if there isn't one).
func time_left_on_offer() -> float:
	if GameState.stage != GameState.Stage.OFFERED:
		return 0.0
	return maxf(_offer_left, 0.0)


func _on_stage_changed(stage: int) -> void:
	if stage == GameState.Stage.NONE:
		_wait_left = GameConfig.ORDER_NEXT_DELAY
	elif stage == GameState.Stage.OFFERED:
		_offer_left = offer_timeout
	# One beam, over the door you need to ride to next.
	_marker.visible = stage == GameState.Stage.TO_RESTAURANT or stage == GameState.Stage.TO_VILLA
	if _marker.visible:
		_marker.global_position = target_door() + Vector3.UP * GameConfig.MARKER_HEIGHT * 0.5


func _pay_for(metres: float) -> int:
	var pay := roundi(GameConfig.ORDER_PAY_BASE + metres * GameConfig.ORDER_PAY_PER_METRE)
	return clampi(pay, GameConfig.ORDER_PAY_MIN, GameConfig.ORDER_PAY_MAX)


## One of the villas closest to the given restaurant door (for boring orders).
func _short_ride_villa(from: Vector3) -> Dictionary:
	var villas: Array = place_builder.villas.duplicate()
	villas.sort_custom(func(a, b): return place_builder.villa_door(a["number"]).distance_to(from) < place_builder.villa_door(b["number"]).distance_to(from))
	return villas.slice(0, GameConfig.ORDER_BORING_CHOICES).pick_random()


## A tall, see-through, glowing orange beam. It has no collision, so you ride right into it.
func _make_marker() -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = GameConfig.MARKER_COLOUR
	var mesh := CylinderMesh.new()
	mesh.top_radius = GameConfig.MARKER_RADIUS
	mesh.bottom_radius = GameConfig.MARKER_RADIUS
	mesh.height = GameConfig.MARKER_HEIGHT
	mesh.material = material
	var beam := MeshInstance3D.new()
	beam.mesh = mesh
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The beam jumps from door to door, so don't smooth (slide) it between physics steps.
	beam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	beam.visible = false
	return beam
