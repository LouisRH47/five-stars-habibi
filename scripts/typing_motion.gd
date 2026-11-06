class_name TypingMotion
extends Node
## Session 91: makes people at desks type: their hands tap up and down on the keyboard,
## the two hands out of step, with a short pause now and then (reading the screen).
## Meeting people move their hands less (now and then a small gesture). Only when the
## camera is near, so it costs nothing far away. DeskPeople.seat() sets the people up.

## [person, typing (true) or meeting (false)]
var people: Array = []
var _time := 0.0


func add(person: Person, typing: bool) -> void:
	people.append([person, typing])


func _process(delta: float) -> void:
	var room := get_parent() as Node3D
	var camera := get_viewport().get_camera_3d()
	if room == null or camera == null or camera.global_position.distance_to(room.global_position) > GameConfig.TYPING_AWAKE_DISTANCE:
		return
	_time += delta
	for i in people.size():
		var person := people[i][0] as Person
		var rest: Array = person.get_meta("hands_rest", [])
		if rest.size() < 2:
			continue
		var t := _time + i * 1.37
		for side in 2:
			var lift := 0.0
			if people[i][1]:
				var typing_now := fposmod(t, GameConfig.TYPING_BURST_SECONDS) < GameConfig.TYPING_BURST_SECONDS * 0.75
				if typing_now:
					lift = absf(sin(t * GameConfig.TYPING_TAPS_PER_SECOND * PI + side * 1.9)) * GameConfig.TYPING_TAP_HEIGHT
			else:
				lift = maxf(0.0, sin(t * 0.7 + side * 2.0) - 0.8) * 0.4  # now and then a small gesture
			person.pose.hands[side] = (rest[side] as Vector3) + Vector3(0, lift, 0)
