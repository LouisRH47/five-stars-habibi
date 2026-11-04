class_name EventManager
extends Node3D
## Random events (Session 33, PRD "Random events"): road works and horses crossing.
## At the start of each shift it plans 1 or 2 events at random times (never more than 2,
## and only one at a time). Before each one the phone warns you for a few seconds, then:
##   Road works: cones, two barriers and a small digger close a stretch of a cluster lane
##     or the ring road for 1 to 2 in-game hours (scripts/road_works.gd). The mini-map shows
##     a cone. Only places on the ROAD_WORKS list are used: the smoke test checks that each
##     one leaves every home and shop door reachable. They never pop up close to you or
##     your parked bike, so you can't get shut in.
##   Horses crossing: a groom leads 2 or 3 horses across a road near the stables
##     (scripts/horse_crossing.gd). Riding into them is a small crash.
## The places come from the map's data list (data/wahat_al_shams.gd); maps without them
## (the test area) have no events. Numbers: game_config.gd, Random events.

## Sent when the phone starts warning about an event (kind: ROAD_WORKS or HORSES).
signal warned(kind: String, place: String)
signal event_started(kind: String, place: String)
signal event_ended(kind: String)
## Sent when road works go up or come down (the play-test bot re-plans its routes).
signal road_works_changed

const ROAD_WORKS := "road_works"
const HORSES := "horses"

## Knows the map's data list.
@export var place_builder: PlaceBuilder
## Road works never start close to the bike or the rider on foot.
@export var bike: Node3D
@export var walker: Node3D
## Shows the warning and what's going on.
@export var phone: Node
## Shows the cone where the road works are.
@export var minimap: Node

## False: no new events start by themselves (the smoke test turns this off).
var enabled := true
## The events still to come this shift, in order: {"kind": ..., "hour": in-game hour}.
var plan: Array = []
## How many events have started this shift.
var started_this_shift := 0
## The event going on now ("" = none), and the one the phone is warning about.
var active_kind := ""
var warning_kind := ""
## Where the coming or current event is (for the phone).
var place_name := ""
## The in-game hour the road works come down.
var road_works_end_hour := 0.0
## The road works (a StaticBody3D) and the horses (a HorseCrossing), while they're up.
var road_works: Node3D
var crossing: HorseCrossing

var _works_list: Array = []
var _crossings: Array = []
var _choice := -1     # which line of the data list the coming event uses
var _warn_left := 0.0


func _ready() -> void:
	if place_builder != null and place_builder.data != null:
		var map := place_builder.data.get_script_constant_map()
		_works_list = map.get("ROAD_WORKS", [])
		_crossings = map.get("HORSE_CROSSINGS", [])
	GameState.shift_started.connect(_on_shift_started)
	_on_shift_started()


## True if this map has places for events.
func has_events() -> bool:
	return not _works_list.is_empty() or not _crossings.is_empty()


## The road works places and horse crossings on this map (for the smoke test).
func road_works_places() -> Array:
	return _works_list


func _physics_process(delta: float) -> void:
	tick(delta)


## Runs the events by one step: the warning countdown, the horses walking, the road works
## coming down when their time is up, and starting the next planned event when it's time.
func tick(delta: float) -> void:
	if warning_kind != "":
		_warn_left -= delta
		if _warn_left <= 0.0:
			_begin()
	elif active_kind == ROAD_WORKS:
		if GameState.clock_hours() >= road_works_end_hour:
			end_event()
	elif active_kind == HORSES:
		if not crossing.step(delta):
			end_event()
	elif enabled and not plan.is_empty() and not GameState.tutorial_running \
			and not GameState.shift_clock_out and GameState.clock_hours() >= plan[0]["hour"]:
		if warn(plan[0]["kind"]):  # if nowhere is safe right now, try again next frame
			plan.pop_front()


## True while an event is coming (being warned about) or going on.
func busy() -> bool:
	return active_kind != "" or warning_kind != ""


## Makes this shift's plan: 1 or 2 events of different kinds at random times, in order,
## at least EVENT_GAP_HOURS apart.
func make_plan() -> Array:
	var kinds := []
	if not _works_list.is_empty():
		kinds.append(ROAD_WORKS)
	if not _crossings.is_empty():
		kinds.append(HORSES)
	kinds.shuffle()
	var count := mini(randi_range(GameConfig.EVENTS_PER_SHIFT_MIN, GameConfig.EVENTS_PER_SHIFT_MAX), kinds.size())
	var made := []
	var span := (GameConfig.EVENT_LATEST_HOUR - GameConfig.EVENT_EARLIEST_HOUR) / maxf(count, 1)
	for i in count:
		var hour := GameConfig.EVENT_EARLIEST_HOUR + span * (i + randf())
		if i > 0:
			hour = maxf(hour, made[i - 1]["hour"] + GameConfig.EVENT_GAP_HOURS)
		made.append({"kind": kinds[i], "hour": hour})
	return made


## Starts the phone warning for an event of this kind. index: which place on the list
## (-1 = pick one at random that's safe right now). Returns false if it can't: another
## event is coming or going on, the shift already had its 2 events, or nowhere is safe.
func warn(kind: String, index := -1) -> bool:
	if busy() or started_this_shift >= GameConfig.EVENTS_PER_SHIFT_MAX:
		return false
	_choice = index if index >= 0 else _pick(kind)
	if _choice < 0:
		return false
	warning_kind = kind
	_warn_left = GameConfig.EVENT_WARNING_TIME
	if kind == ROAD_WORKS:
		place_name = _works_list[_choice]["name"]
		_tell_phone("Heads up! Road works on %s soon. Find another way." % place_name, true)
	else:
		place_name = _crossings[_choice]["name"]
		_tell_phone("Heads up! Horses crossing %s soon. Wait or go round." % place_name, true)
	warned.emit(kind, place_name)
	return true


## Takes down whatever is going on now (road works or horses).
func end_event() -> void:
	var kind := active_kind
	if road_works != null:
		road_works.get_parent().remove_child(road_works)  # out of the physics world right now
		road_works.queue_free()
		road_works = null
		road_works_changed.emit()
	if crossing != null:
		remove_child(crossing)
		crossing.queue_free()
		crossing = null
	if minimap != null:
		minimap.road_works_at = []
	_tell_phone("", false)
	active_kind = ""
	if kind != "":
		event_ended.emit(kind)


## Stops everything: the warning, the event and the plan (a new shift, or the smoke test).
func clear_all() -> void:
	warning_kind = ""
	end_event()
	plan = []


func _on_shift_started() -> void:
	clear_all()
	started_this_shift = 0
	plan = make_plan() if has_events() else []


## The warning is over: the event starts (if it's still safe; otherwise somewhere else).
func _begin() -> void:
	var kind := warning_kind
	warning_kind = ""
	var safe := _clear_of_you(_works_list[_choice]) if kind == ROAD_WORKS else _clear_of_line(_crossings[_choice])
	if not safe:  # you rode up to it while the phone was warning: somewhere else then
		_choice = _pick(kind)
		if _choice < 0:
			_tell_phone("", false)  # nowhere safe right now: no event after all
			return
		place_name = (_works_list if kind == ROAD_WORKS else _crossings)[_choice]["name"]
	started_this_shift += 1
	active_kind = kind
	if kind == ROAD_WORKS:
		var works: Dictionary = _works_list[_choice]
		road_works = RoadWorks.build(self, works)
		var hours := randf_range(GameConfig.ROAD_WORKS_HOURS.x, GameConfig.ROAD_WORKS_HOURS.y)
		road_works_end_hour = GameState.clock_hours() + hours
		if minimap != null:
			minimap.road_works_at = [works["centre"]]
		_tell_phone("Road works: %s closed till %s" % [place_name, _clock_text(road_works_end_hour)], false)
		road_works_changed.emit()
	else:
		var line: Dictionary = _crossings[_choice]
		crossing = HorseCrossing.new()
		crossing.name = "HorseCrossing"
		add_child(crossing)
		crossing.setup(line["from"], line["to"], randi_range(GameConfig.HORSE_COUNT.x, GameConfig.HORSE_COUNT.y))
		_tell_phone("Horses crossing %s. Wait or go round." % place_name, false)
	event_started.emit(kind, place_name)


## A random place on the list for this kind of event that's safe right now (-1 = none).
func _pick(kind: String) -> int:
	var choices := []
	var places := _works_list if kind == ROAD_WORKS else _crossings
	for i in places.size():
		if (kind == HORSES and _clear_of_line(places[i])) or (kind == ROAD_WORKS and _clear_of_you(places[i])):
			choices.append(i)
	return -1 if choices.is_empty() else choices.pick_random()


## True if the bike and the rider on foot are both well away from these road works.
func _clear_of_you(works: Dictionary) -> bool:
	for thing in [bike, walker]:
		if thing != null and thing.is_inside_tree() and thing.visible:
			var spot := Vector2(thing.global_position.x, thing.global_position.z)
			if spot.distance_to(works["centre"]) < GameConfig.EVENT_CLEAR_DISTANCE:
				return false
	return true


## True if the bike and the rider on foot are off the horses' way (they'd appear on top).
func _clear_of_line(line: Dictionary) -> bool:
	for thing in [bike, walker]:
		if thing != null and thing.is_inside_tree() and thing.visible:
			var spot: Vector3 = thing.global_position * Vector3(1, 0, 1)
			var near := Geometry3D.get_closest_point_to_segment(spot, line["from"], line["to"])
			if spot.distance_to(near) < GameConfig.HORSE_CLEAR_DISTANCE:
				return false
	return true


func _tell_phone(text: String, warning: bool) -> void:
	if phone != null and phone.has_method("show_event"):
		phone.show_event(text, warning)


## 13.5 -> "13:30".
func _clock_text(hour: float) -> String:
	var minutes := roundi(minf(hour, GameConfig.SHIFT_END_HOUR) * 60.0)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]
