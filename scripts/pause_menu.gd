extends CanvasLayer
## Esc pauses and resumes the game. Shows a "Paused" panel with a Quit button.
## This node keeps running while the game is paused (process_mode = Always).


func _ready() -> void:
	visible = false
	$Panel/Margin/Rows/Buttons/Resume.pressed.connect(_resume)
	$Panel/Margin/Rows/Buttons/Quit.pressed.connect(get_tree().quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	get_tree().paused = true
	visible = true


func _resume() -> void:
	get_tree().paused = false
	visible = false
