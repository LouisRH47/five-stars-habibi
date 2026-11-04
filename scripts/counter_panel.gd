extends Node
## Shared order handoff panel for restaurant counters and reception desks.
var _panel: SidePanel
var _delivery: Node
var _places: PlaceBuilder
var _staff: Person
var _bag: Node3D

func _ready() -> void:
	# The side panel also runs while paused: keep its visibility in sync with modals.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_delivery = get_parent().get_node("DeliveryManager")
	_places = get_parent().get_node("PlaceBuilder")
	_panel = SidePanel.new()
	add_child(_panel)
	# Delivery can pause the tree before the next frame. Remove the old handoff now.
	GameState.order_stage_changed.connect(func(_stage): _close())
	GameState.shift_ended.connect(func(_summary): _close())


func _process(_delta: float) -> void:
	var order := GameState.current_order
	if get_tree().paused or order == null or not _delivery.on_foot or not _delivery.is_near_target():
		_close()
		return
	var room: Node3D
	var title := ""
	if GameState.stage == GameState.Stage.TO_RESTAURANT:
		room = _places.get_node_or_null("Restaurant_" + order.restaurant_id)
		title = order.restaurant_name
	elif GameState.stage == GameState.Stage.TO_VILLA and order.villa_number in [903, 904]:
		room = _places.get_node_or_null("Institute" if order.villa_number == 903 else "Gym")
		title = order.address
	# Session 61: the farm stall's farmer hands over orders too ("counter_handoff").
	if room == null or not (room.get_meta("walk_in", false) or room.get_meta("counter_handoff", false)):
		_close()
		return
	_panel.show_counter(title, "%s\n%s" % [order.food.capitalize(), "Hold E to collect your delivery" if GameState.stage == GameState.Stage.TO_RESTAURANT else "Hold E to hand over the food"], _delivery.hold_progress())
	_panel.footer.text = "Hold E to complete the handoff"
	if CounterQueue.wait_left > 0.0 and GameState.stage == GameState.Stage.TO_RESTAURANT:
		# Session 58: a short queue. Wait your turn (2 to 4 seconds).
		_panel.footer.text = "Wait a moment: %d in front of you" % maxi(CounterQueue.ahead, 1)
	if _staff == null:
		_staff = room.get_node_or_null("CounterStaff")
		if _staff != null:
			var hand := _staff.follow("RightHand")
			_bag = LowPoly.box(hand, Vector3(0.23, 0.3, 0.16), Color(0.94, 0.57, 0.2), _staff.spot("RightHand"))
	if _staff != null and _delivery.hold_progress() > 0.02:
		_staff.play("wave")


func _close() -> void:
	_panel.hide_panel()
	if _staff != null and is_instance_valid(_staff):
		_staff.play("idle")
	_staff = null
	if _bag != null and is_instance_valid(_bag):
		_bag.queue_free()
	_bag = null
