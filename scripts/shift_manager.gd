class_name ShiftManager
extends Node
## Runs the shift (PRD "Shifts"): 8:00 AM–6:00 PM takes 10 active minutes. When it runs out,
## no new orders pop up; if you're carrying an order you still finish it, and the shift
## ends right after you drop it off. A big crash ends the shift too (after the clinic).
## Then the summary screen shows (scripts/shift_screen.gd). The data lives in GameState.

## Puts the bike back at the start for the next shift.
@export var bike: Node3D
## Shows the clock and the end-of-shift summary.
@export var shift_screen: Node
## The clinic: after a big crash the shift ends once you close it.
@export var clinic: Node
## The Delivered card (Session 22): at the end of a shift, the summary comes after it.
@export var delivered_card: Node

## How long a shift is. Starts at the GameConfig value; the smoke test shortens it.
var shift_length := GameConfig.SHIFT_LENGTH

var _end_after_clinic := false


func _ready() -> void:
	GameState.order_delivered.connect(_on_order_delivered)
	GameState.big_crashed.connect(func(_bills): _end_after_clinic = true)
	if bike != null and bike.has_signal("crashed"):
		bike.crashed.connect(func(_big): GameState.note_crash())  # the "No crashes" goal
	if bike != null and bike.has_signal("knocked"):
		bike.knocked.connect(GameState.pay_crash_bill)  # and for a bump
	if bike != null and bike.has_signal("fall_completed"):
		bike.fall_completed.connect(_on_fall_completed)
	if clinic != null:
		clinic.closed.connect(_on_clinic_closed)
	if shift_screen != null:
		shift_screen.next_shift_pressed.connect(start_next_shift)


func _physics_process(delta: float) -> void:
	if GameState.shift_clock_out or GameState.tutorial_running:
		return  # the clock waits while the tutorial runs
	GameState.shift_time_left = maxf(GameState.shift_time_left - delta * GameConfig.SHIFT_LENGTH / shift_length, 0.0)
	if GameState.shift_time_left <= 0.0:
		GameState.clock_out()
		if GameState.current_order == null and not _fall_in_progress():
			end_shift()


## Ends the shift now and shows the summary.
func end_shift() -> void:
	var summary := GameState.end_shift()
	if shift_screen != null:
		shift_screen.show_summary(summary)


## The "Start next shift" button: fresh clock, bike back at the start. Session 86: the short
## loading screen covers the jump back to the start.
func start_next_shift() -> void:
	var screen := LoadingScreen.make(true)
	get_tree().root.add_child(screen)
	screen.set_progress(1, 3, "Clocking in...")
	var walking := get_parent().get_node_or_null("OnFoot")
	if walking != null:
		walking.get_on(true)
	GameState.start_shift()
	if bike != null:
		bike.reset_to_start()
	screen.set_progress(2, 3, "Pumping up the tyres...")
	screen.finish()


func _on_order_delivered(_order: Order) -> void:
	if not GameState.shift_clock_out:
		return
	# The last order of the shift is done. The Delivered card shows first, then the summary.
	if delivered_card != null:
		delivered_card.closed.connect(end_shift, CONNECT_ONE_SHOT)
	else:
		end_shift()


func _on_clinic_closed() -> void:
	if _end_after_clinic:
		_end_after_clinic = false
		end_shift()


## Don't pause the world for a summary while a crash animation still needs to finish.
func _fall_in_progress() -> bool:
	return bike != null and (bike.get("fallen_left") > 0.0 or bike.get("wrecked") == true)


func _on_fall_completed(big: bool, _impact: Dictionary) -> void:
	if not big and GameState.shift_clock_out and GameState.current_order == null:
		if clinic != null and clinic.get("showing") == true:
			_end_after_clinic = true  # Session 87: a fall's clinic visit first, then the summary
		else:
			end_shift()
