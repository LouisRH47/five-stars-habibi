class_name PoolSwimmers
extends Node3D
## Session 81 (people): swimmers in every pool (the community pool, the gym's lap pool and
## the two school pools). Most swim laps up and down their lane (front crawl or
## breaststroke, head out of the water, turning round at each end); a couple rest with
## their arms on the edge and look around. They all wear swimwear (PlaceLooks.dress_swimmer).
## Made by PlaceCrowds, which also hides far swimmers and stops animating them (cheap).
## The pools come from the map data (COMMUNITY_POOL, LAP_POOL) so they fit the pool deck.

## The school's two pools (the same spots as in scripts/district_detail.gd).
const SCHOOL_POOLS := [Rect2(-349.0, 98.0, 18.0, 11.0), Rect2(-326.0, 98.0, 18.0, 11.0)]

## Everyone swimming laps: {"person", "holder", "area": Rect2, "along_x", "speed", "turn_left"}.
var lappers: Array = []
## Everyone resting at the edge: {"person", "holder", "bob"}.
var resters: Array = []

var _number := 0  # the next swimmer's number (for their swimwear and stroke)
var _water := GameConfig.SWIM_WATER_Y  # how high the water is in the pool being filled


## Fills the pools in the map data. Returns every swimmer as [Person, Graphics level] so
## PlaceCrowds can hide the far ones. world: where to find the pool nodes, which say how
## high their water is (meta "water_y", from the pool builder).
func build(map: Dictionary, world: Node = null) -> Array:
	var made: Array = []
	if map.has("COMMUNITY_POOL"):
		_water = water_height(world, "CommunityPool")
		# The lap swimmers keep out of the kids' splash area at the east end (+X).
		var pool: Rect2 = map["COMMUNITY_POOL"]
		var laps := Rect2(pool.position, pool.size - Vector2(GameConfig.SWIM_KIDS_AREA, 0.0))
		made += fill(laps, GameConfig.SWIM_COMMUNITY_LAPS, 0, 0)
		made += fill(pool, 0, GameConfig.SWIM_COMMUNITY_RESTING, 0)
	if map.has("LAP_POOL"):
		_water = water_height(world, "LapPool")
		made += fill(map["LAP_POOL"], GameConfig.SWIM_LAP_POOL_LAPS, 0, 0)
	if map.has("SCHOOL"):
		_water = water_height(world, "SchoolPool")
		for pool: Rect2 in SCHOOL_POOLS:
			made += fill(pool, GameConfig.SWIM_SCHOOL_LAPS, GameConfig.SWIM_SCHOOL_RESTING, 1)
	return made


## How high the water is in the pool node called `pool_name` (its meta "water_y"), or
## GameConfig.SWIM_WATER_Y if there's no such pool or it doesn't say.
static func water_height(world: Node, pool_name: String) -> float:
	if world != null:
		for node in world.find_children("*" + pool_name + "*", "Node3D", true, false):
			if node.has_meta("water_y"):
				return float(node.get_meta("water_y"))
	return GameConfig.SWIM_WATER_Y


## Puts `laps` lap swimmers (one per lane) and `resting` people at the edge into one pool.
func fill(area: Rect2, laps: int, resting: int, level: int) -> Array:
	var made: Array = []
	var along_x := area.size.x >= area.size.y  # the swimmers go along the long side
	var length := area.size.x if along_x else area.size.y
	var width := area.size.y if along_x else area.size.x
	for lane in laps:
		var across := (lane + 0.5) / laps * width
		var start := randf_range(2.0, length - 2.0)
		var spot := Vector2(area.position.x + start, area.position.y + across) if along_x \
				else Vector2(area.position.x + across, area.position.y + start)
		var heading := 1.0 if lane % 2 == 0 else -1.0
		made.append([_lapper(area, along_x, spot, heading), level + lane / 3])
	for i in resting:
		# On the long side nearest +Z (or +X), spread out, facing the edge.
		var share := (i + 1.0) / (resting + 1.0) * 0.6 + 0.2
		var spot := Vector2(area.position.x + share * area.size.x, area.end.y - GameConfig.SWIM_REST_GAP) if along_x \
				else Vector2(area.end.x - GameConfig.SWIM_REST_GAP, area.position.y + share * area.size.y)
		made.append([_rester(spot, 0.0 if along_x else 90.0), level])
	return made


## A swimmer lying face down at the water, heading along +X/+Z (heading 1) or back (-1).
func _lapper(area: Rect2, along_x: bool, spot: Vector2, heading: float) -> Person:
	var person := _swimmer("Swimmer")
	var holder := _holder(spot, _water)
	# A holder faces -Z; turn it so its front points along the lane.
	holder.rotation.y = (-PI * 0.5 if heading > 0.0 else PI * 0.5) if along_x else (PI if heading > 0.0 else 0.0)
	# Tip the person forward so they lie on the water, head end a little higher.
	person.rotation.x = -deg_to_rad(90.0 - GameConfig.SWIM_BODY_TILT_DEG)
	var neck := person.basis * person.spot("Neck")
	person.position = Vector3(-neck.x, GameConfig.SWIM_NECK_ABOVE_WATER - neck.y, -neck.z)
	holder.add_child(person)
	person.pose.stroke = "breast" if _number % 3 == 0 else "crawl"
	person.pose.stroke_start = randf()
	person.play("swim")
	lappers.append({"person": person, "holder": holder, "area": area, "along_x": along_x,
			"speed": GameConfig.SWIM_SPEED * randf_range(0.85, 1.15), "turn_left": 0.0, "water": _water})
	return person


## Someone standing in the water at the edge, forearms on the edge, looking about.
func _rester(spot: Vector2, facing: float) -> Person:
	var person := _swimmer("PoolResting")
	var holder := _holder(spot, _water)
	holder.rotation_degrees.y = facing + 180.0  # turn round to face the edge (it's behind +Z)
	person.position.y = GameConfig.SWIM_SHOULDERS_ABOVE_WATER - person.spot("LeftArm").y
	holder.add_child(person)
	var edge := GameConfig.SWIM_EDGE_ABOVE_WATER - person.position.y  # the edge's top, on the person
	var hands: Array[Vector3] = [Vector3(-0.16, edge, -0.42), Vector3(0.16, edge, -0.42)]
	person.pose.hands = hands
	person.play("rest")
	resters.append({"person": person, "holder": holder, "bob": randf() * TAU, "water": _water,
			"look_at": 0.0, "look_left": randf_range(1.0, 4.0)})
	return person


func _swimmer(name_start: String) -> Person:
	var person := PlaceLooks.swimmer(_number)
	person.name = "%s%d" % [name_start, _number]
	_number += 1
	return person


func _holder(spot: Vector2, height: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = Vector3(spot.x, height, spot.y)
	add_child(holder)
	return holder


func _process(delta: float) -> void:
	for swimmer: Dictionary in lappers:
		var person: Person = swimmer["person"]
		if person.process_mode == Node.PROCESS_MODE_DISABLED or not person.visible:
			continue  # far away: they hold still (PlaceCrowds decides)
		_swim(swimmer, person, delta)
	for rester: Dictionary in resters:
		var person: Person = rester["person"]
		if person.process_mode == Node.PROCESS_MODE_DISABLED or not person.visible:
			continue
		_bob_and_look(rester, person, delta)


## Moves a lap swimmer along its lane, and turns it round at the end of the pool.
func _swim(swimmer: Dictionary, person: Person, delta: float) -> void:
	var holder: Node3D = swimmer["holder"]
	var speed: float = swimmer["speed"]
	if person.pose.stroke == "breast":
		speed *= PoolPoses.breaststroke_push(PoolPoses.stroke_part(person.pose))
	var turn_left: float = swimmer["turn_left"]
	if turn_left > 0.0:  # turning round at the wall: slow, in a small half circle
		turn_left -= delta
		holder.rotation.y += PI * delta / GameConfig.SWIM_TURN_TIME
		speed *= 0.35
	var forward := -holder.global_basis.z
	holder.position += forward * speed * delta
	holder.position.y = swimmer["water"] + sin(person.pose.clock * 3.0) * 0.015
	var area: Rect2 = swimmer["area"]
	if turn_left <= 0.0:
		var ahead := Vector2(holder.position.x, holder.position.z) + Vector2(forward.x, forward.z) * GameConfig.SWIM_TURN_GAP
		if not area.grow(-0.4).has_point(ahead):
			turn_left = GameConfig.SWIM_TURN_TIME
	swimmer["turn_left"] = turn_left


## A resting swimmer bobs gently in the water and now and then looks somewhere else.
func _bob_and_look(rester: Dictionary, person: Person, delta: float) -> void:
	var holder: Node3D = rester["holder"]
	holder.position.y = rester["water"] + sin(person.pose.clock * 1.3 + rester["bob"]) * 0.02
	rester["look_left"] -= delta
	if rester["look_left"] <= 0.0:
		rester["look_left"] = randf_range(2.0, 5.0)
		rester["look_at"] = randf_range(-60.0, 60.0)
	person.pose.look = move_toward(person.pose.look, rester["look_at"], 50.0 * delta)
