class_name GameClock
extends RefCounted
## Shared minute-by-minute clock text for the HUD and event messages. Only the display is stepped;
## deliveries, sunlight and events still use GameState's continuous game time.


static func format_time(hour: float) -> String:
	# A tiny tolerance keeps exact boundaries stable after floating-point arithmetic.
	var minutes := floori((hour * 60.0 + 0.000001) / GameConfig.CLOCK_STEP_MINUTES) * GameConfig.CLOCK_STEP_MINUTES
	minutes = posmod(minutes, 24 * 60)
	var hour_24 := minutes / 60
	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	return "%d:%02d %s" % [hour_12, minutes % 60, "AM" if hour_24 < 12 else "PM"]
