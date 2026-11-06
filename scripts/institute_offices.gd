class_name InstituteOffices
extends RefCounted
## Session 91: the rooms on the C Institute's second floor, along the back glass:
##   the meeting room (left end): a long table, a big glowing screen on the end wall,
##     five people round the table and one presenting (6 people)
##   four glass-walled offices: white desks, office chairs, people typing on laptops
##   a lounge corner (right end) with a couch, and plants all along the balcony
## Glass walls are solid (each room has an open doorway onto the balcony walkway).
## Room metres like InstituteUpstairs (the floor is at InstituteUpstairs.FLOOR2).

const DESK := Color(0.96, 0.96, 0.95)
const DESK_LEG := Color(0.25, 0.26, 0.28)
const FRAME := Color(0.93, 0.93, 0.92)
const TABLE := Color(0.72, 0.52, 0.32)
const SCREEN_BLUE := Color(0.06, 0.16, 0.32)
const BARS := [Color(0.95, 0.55, 0.25), Color(0.25, 0.75, 0.75), Color(0.95, 0.8, 0.3), Color(0.4, 0.8, 0.45)]

const FRONT := -11.5         # the glass wall between the rooms and the walkway (z)
const WALL_HIGH := 2.9       # how tall the glass walls are
## The rooms from left to right: [x from, x to, how many people at desks].
const ROOMS := [[-22.85, -12.5, 0], [-12.5, -4.5, 2], [-4.5, 3.5, 1], [3.5, 11.5, 2], [11.5, 18.5, 1]]
const DOOR_WIDE := 1.4


## Builds the rooms, people and plants into the institute `body`. Returns the TypingMotion.
static func build(body: StaticBody3D) -> TypingMotion:
	var y := InstituteUpstairs.FLOOR2
	var motion := TypingMotion.new()
	motion.name = "TypingMotion"
	body.add_child(motion)
	var rooms := Node3D.new()
	rooms.name = "Offices"
	body.add_child(rooms)
	for i in ROOMS.size():
		var room: Array = ROOMS[i]
		_walls(body, rooms, room[0], room[1], y, i)
		if i == 0:
			_meeting_room(body, room[0], room[1], y, motion)
		else:
			_office(body, rooms, room[0], room[1], y, room[2], i, motion)
	_lounge_and_plants(body, y)
	body.set_meta("desk_people", _count(body, "DeskPerson"))
	body.set_meta("meeting_people", _count(body, "MeetingPerson"))
	return motion


## A room's glass front (with a doorway) and its glass wall on the right-hand side.
static func _walls(body: StaticBody3D, rooms: Node3D, from: float, to: float, y: float, i: int) -> void:
	var door := lerpf(from, to, 0.78) if i > 0 else to - 1.6
	var back := InstituteUpstairs.BACK
	VenueParts.glass_run(body, Vector3(from, 0, FRONT), Vector3(door - DOOR_WIDE * 0.5, 0, FRONT), WALL_HIGH, 2.0, y, true, FRAME)
	VenueParts.glass_run(body, Vector3(door + DOOR_WIDE * 0.5, 0, FRONT), Vector3(to, 0, FRONT), WALL_HIGH, 2.0, y, true, FRAME)
	LowPoly.box(rooms, Vector3(DOOR_WIDE + 0.2, 0.08, 0.16), FRAME, Vector3(door, y + 2.3, FRONT))
	RoomProps.pane(rooms, Vector3(DOOR_WIDE, WALL_HIGH - 2.34, 0.06), Vector3(door, y + (WALL_HIGH + 2.34) * 0.5, FRONT))
	LowPoly.box(rooms, Vector3(to - from, 0.06, 0.14), FRAME, Vector3((from + to) * 0.5, y + WALL_HIGH + 0.03, FRONT))
	if to < InstituteUpstairs.INNER - 1.0:
		VenueParts.glass_run(body, Vector3(to, 0, back), Vector3(to, 0, FRONT), WALL_HIGH, 2.0, y, true, FRAME)
		LowPoly.box(rooms, Vector3(0.14, 0.06, FRONT - back), FRAME, Vector3(to, y + WALL_HIGH + 0.03, (FRONT + back) * 0.5))
	# A frosted strip across the glass at eye height, with the room's name.
	var strip := LowPoly.box(rooms, Vector3(minf(to - from, 4.0), 0.12, 0.02), Color(0.9, 0.95, 0.97), Vector3(from + 2.4, y + 1.5, FRONT + 0.1))
	strip.name = "FrostStrip%d" % i
	var name := SignText.make_label("Meeting room" if i == 0 else "Office %d" % i, 16, Color(0.2, 0.25, 0.3), Color(0, 0, 0, 0), 0)
	name.position = Vector3(from + 1.2, y + 1.75, FRONT + 0.12)
	rooms.add_child(name)


## An office: white desks facing the walkway, people typing, a plant and a shelf.
static func _office(body: StaticBody3D, rooms: Node3D, from: float, to: float, y: float, people: int, i: int, motion: TypingMotion) -> void:
	var middle := (from + to) * 0.5
	var seat_z := -15.2
	var spots := [middle - 1.7, middle + 1.7] if people == 2 else [middle - 0.6]
	for k in spots.size():
		var x: float = spots[k]
		_desk(body, rooms, Vector3(x, y, seat_z + 0.66))
		var person := PeopleLooks.resident((i * 2 + k) % 5, (i + k * 2) % PeopleLooks.SKINS.size()) if (i + k) % 3 != 1 else PeopleLooks.teacher()
		person.name = "DeskPerson%d_%d" % [i, k]
		DeskPeople.seat(body, person, Vector3(x, y, seat_z), 180.0, 0.74, 0.42, true)
		motion.add(person, true)
	if people == 1:  # a visitor chair and a whiteboard in the one-person offices
		DeskPeople.chair(rooms, Vector3(middle - 0.6, y, -13.2), 0.0)
		var board := LowPoly.box(rooms, Vector3(2.2, 1.1, 0.04), Color.WHITE, Vector3(middle + 1.6, y + 1.6, InstituteUpstairs.BACK + 0.12))
		board.name = "Whiteboard%d" % i
		for line in 3:
			LowPoly.box(rooms, Vector3(1.4 - line * 0.3, 0.03, 0.01), [Color(0.2, 0.4, 0.8), Color(0.85, 0.3, 0.25), Color(0.2, 0.6, 0.35)][line],
					Vector3(middle + 1.4, y + 1.85 - line * 0.22, InstituteUpstairs.BACK + 0.15))
	RoomProps.big_plant(rooms, Vector3(to - 0.6, y, InstituteUpstairs.BACK + 0.6))
	Props.kit("furniture/shelf_A_big", rooms, Vector3(from + 0.9, y, InstituteUpstairs.BACK + 0.35), 0.0, 1.0)


## A white desk (1.6 x 0.8, 0.74 high) with dark legs; its middle at `at` on the floor.
static func _desk(body: StaticBody3D, holder: Node3D, at: Vector3) -> void:
	LowPoly.box(holder, Vector3(1.6, 0.04, 0.8), DESK, at + Vector3(0, 0.72, 0))
	for x: float in [-0.74, 0.74]:
		LowPoly.box(holder, Vector3(0.05, 0.7, 0.7), DESK_LEG, at + Vector3(x, 0.35, 0))
	LowPoly.solid_box(body, Vector3(1.6, 0.74, 0.8), at + Vector3(0, 0.37, 0))


## The meeting room: a long wooden table, five people round it, one presenting at the screen.
static func _meeting_room(body: StaticBody3D, from: float, to: float, y: float, motion: TypingMotion) -> void:
	var holder := Node3D.new()
	holder.name = "MeetingRoom"
	body.add_child(holder)
	var middle := Vector3(from + 6.0, y, -14.7)
	LowPoly.box(holder, Vector3(4.4, 0.06, 1.5), TABLE, middle + Vector3(0, 0.71, 0))
	for x: float in [-1.6, 1.6]:
		LowPoly.box(holder, Vector3(0.08, 0.68, 1.1), DESK_LEG, middle + Vector3(x, 0.34, 0))
	LowPoly.solid_box(body, Vector3(4.4, 0.74, 1.5), middle + Vector3(0, 0.37, 0))
	# Three people on the back side (facing the walkway) and two on the front side.
	var seats := [[-1.5, -1.2, 180.0], [0.0, -1.2, 180.0], [1.5, -1.2, 180.0], [-0.8, 1.2, 0.0], [0.8, 1.2, 0.0]]
	for k in seats.size():
		var s: Array = seats[k]
		var person := PeopleLooks.resident((k + 1) % 5, (k * 3) % PeopleLooks.SKINS.size()) if k != 2 else PeopleLooks.teacher()
		person.name = "MeetingPerson%d" % k
		DeskPeople.seat(body, person, middle + Vector3(s[0], 0, s[1]), s[2], 0.74, 0.6, k == 1)
		motion.add(person, k == 1)
		if k != 1:
			LowPoly.box(holder, Vector3(0.22, 0.015, 0.3), Color.WHITE, middle + Vector3(s[0] + 0.25, 0.745, s[1] * 0.55))  # a notepad
	# The presenter stands by the screen, talking with their hands, facing the table.
	var presenter := PeopleLooks.resident(0, 1)
	presenter.name = "MeetingPerson5"
	presenter.position = Vector3(from + 1.4, y, -12.9)
	presenter.rotation_degrees.y = -70.0  # looking at the table
	body.add_child(presenter, true)
	presenter.pose.talking = true
	_screen(holder, from, y)
	RoomProps.big_plant(holder, Vector3(to - 0.7, y, InstituteUpstairs.BACK + 0.6))


## A big glowing screen on the room's end wall with a chart and a title.
static func _screen(holder: Node3D, from: float, y: float) -> void:
	var x := from + 0.12
	LowPoly.box(holder, Vector3(0.08, 1.6, 2.8), Color(0.08, 0.08, 0.1), Vector3(x, y + 1.6, -14.7))
	var glass := LowPoly.box(holder, Vector3(0.02, 1.45, 2.65), SCREEN_BLUE, Vector3(x + 0.05, y + 1.6, -14.7))
	glass.name = "MeetingScreen"
	glass.material_override = VenueParts.glow(SCREEN_BLUE, 1.0)
	for k in 4:  # a little bar chart
		var high := 0.25 + k * 0.15
		var bar := LowPoly.box(holder, Vector3(0.01, high, 0.3), BARS[k], Vector3(x + 0.065, y + 1.0 + high * 0.5, -15.5 + k * 0.45))
		bar.material_override = VenueParts.glow(BARS[k], 1.2)
	var title := SignText.make_label("Solar roofs · Phase 2", 20, Color.WHITE, Color(0, 0, 0, 0), 0)
	title.position = Vector3(x + 0.07, y + 2.1, -14.7)
	title.rotation_degrees.y = 90.0  # reads from inside the room (+X)
	holder.add_child(title)


## A couch in the right-hand corner, plants along the balcony and in the corners.
static func _lounge_and_plants(body: StaticBody3D, y: float) -> void:
	var plants := Node3D.new()
	plants.name = "UpstairsPlants"
	body.add_child(plants)
	Props.kit("furniture/couch", plants, Vector3(20.7, y, InstituteUpstairs.BACK + 1.0), 180.0, 1.0)
	LowPoly.solid_box(body, Vector3(2.2, 0.9, 1.0), Vector3(20.7, y + 0.45, InstituteUpstairs.BACK + 1.0))
	Props.kit("furniture/table_low", plants, Vector3(20.7, y, InstituteUpstairs.BACK + 2.6), 0.0, 1.0)
	var spots := [Vector3(-20.5, y, -7.7), Vector3(-8.0, y, -7.7), Vector3(5.0, y, -7.7), Vector3(22.2, y, -12.0),
			Vector3(22.2, y, 3.0), Vector3(22.2, y, 9.5), Vector3(22.2, y, -6.3)]
	for spot: Vector3 in spots:
		RoomProps.big_plant(plants, spot)
		LowPoly.solid_cylinder(body, 0.35, 1.0, spot + Vector3(0, 0.5, 0))
	body.set_meta("upstairs_plants", spots.size() + ROOMS.size())


static func _count(body: Node, prefix: String) -> int:
	var found := 0
	for child in body.get_children():
		if str(child.name).begins_with(prefix):
			found += 1
	return found
