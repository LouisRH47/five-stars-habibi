class_name UiJuice
extends RefCounted
## Session 66: small UI animations used by every screen. They all run while the game is paused,
## and "Less motion" (Settings.reduce_motion) turns shakes off and makes pops quicker.

static func _tween(node: Node) -> Tween:
	return node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

## Grows from 80% with a little overshoot.
static func pop_in(c: Control, time := UiPalette.PANEL_TIME) -> Tween:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * 0.8
	var t := _tween(c)
	t.tween_property(c, "scale", Vector2.ONE, time * (0.5 if Settings.reduce_motion else 1.0)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## Squash on click: 95% then back.
static func press(c: Control) -> Tween:
	c.pivot_offset = c.size * 0.5
	var t := _tween(c)
	t.tween_property(c, "scale", Vector2.ONE * 0.95, UiPalette.FAST * 0.5)
	t.tween_property(c, "scale", Vector2.ONE, UiPalette.FAST).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## Counts a number up on a label: fmt like "%d Dh".
static func count_up(label: Label, from: float, to: float, time := UiPalette.REVEAL, fmt := "%d") -> Tween:
	var t := _tween(label)
	t.tween_method(func(v: float): label.text = fmt % roundi(v), from, to, time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return t

## Shakes sideways (does nothing with Less motion).
static func shake(c: Control, pixels := 4.0, time := 0.25) -> Tween:
	var t := _tween(c)
	if Settings.reduce_motion:
		t.tween_interval(0.0)  # an empty tween is an error in Godot: give it a zero-length step
		return t
	var start := c.position
	for i in 5:
		t.tween_property(c, "position:x", start.x + (pixels if i % 2 == 0 else -pixels) * (1.0 - i / 5.0), time / 6.0)
	t.tween_property(c, "position", start, time / 6.0)
	return t

## Slides in from an offset (e.g. Vector2(320, 0) = from the right).
static func slide_in(c: Control, offset: Vector2, time := UiPalette.PANEL_TIME) -> Tween:
	var end := c.position
	c.position = end + offset
	var t := _tween(c)
	t.tween_property(c, "position", end, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t
