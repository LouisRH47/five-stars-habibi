class_name ShiftManager
extends Node
## Runs the shift (PRD "Shifts"): the clock counts down 8 active minutes. When it runs out,
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
		if GameState.current_order == null:
			end_shift()


## Ends the shift now and shows the summary.
func end_shift() -> void:
	var summary := GameState.end_shift()
	if shift_screen != null:
		shift_screen.show_summary(summary)


## The "Start next shift" button: fresh clock, bike back at the start.
func start_next_shift() -> void:
	GameState.start_shift()
	if bike != null:
		bike.reset_to_start()


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
