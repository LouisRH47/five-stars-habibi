class_name Farmer
extends Person
## Session 61: the farmer behind the Wahat Farm Stall counter. A straw hat, a green check
## shirt and an apron. He turns to look at you when you walk up, and he's the one who hands
## you the order (the farm stall calls him "CounterStaff", so the counter side panel finds
## him, like the staff in a restaurant).

const SHIRT := Color(0.35, 0.55, 0.3)
const TROUSERS := Color(0.42, 0.33, 0.24)
const STRAW := Color(0.9, 0.78, 0.45)
const APRON := Color(0.55, 0.38, 0.22)

## The way he faces when nobody's there (radians, set by the stall).
var rest_facing := 0.0
var _check_left := 0.0
var _look_at := Vector3.INF


func _init() -> void:
	super()
	paint({"skin": PeopleLooks.SKINS[1], "shirt": SHIRT, "pants": TROUSERS, "hair": Color(0.25, 0.22, 0.2)})
	var hat := follow("Head")
	var head := head_spot()
	var r := PeopleLooks.head_size(self) * 0.6
	LowPoly.cylinder(hat, r * 1.9, r * 1.9, 0.02, STRAW, head + Vector3(0, r * 0.45, 0))      # the wide brim
	LowPoly.cylinder(hat, r * 0.85, r * 1.0, r * 0.8, STRAW, head + Vector3(0, r * 0.8, 0))   # the crown
	LowPoly.cylinder(hat, r * 1.01, r * 1.01, r * 0.18, Color(0.45, 0.3, 0.15), head + Vector3(0, r * 0.5, 0))
	var chest := follow("Spine1")
	var hips := spot("Hips")
	LowPoly.box(chest, Vector3(0.36, 0.55, 0.02), APRON, hips + Vector3(0, 0.12, -0.13))
	name = "Farmer"


func _process(delta: float) -> void:
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.3
		_look_at = Vector3.INF
		var watch: Array = get_tree().get_nodes_in_group("bike")
		var scene := get_tree().current_scene
		if scene != null and scene.get_node_or_null("Walker") is Node3D:
			watch.append(scene.get_node("Walker"))
		for who: Node3D in watch:
			if who.is_visible_in_tree() and who.global_position.distance_to(global_position) < GameConfig.FARMER_LOOK_RANGE:
				_look_at = who.global_position
	var want := rest_facing
	if _look_at != Vector3.INF:
		var way := _look_at - global_position
		var local := (get_parent() as Node3D).global_transform.basis.inverse() * way if get_parent() is Node3D else way
		want = atan2(-local.x, -local.z)
		# Only turn so far: he stays behind his counter.
		var gap := wrapf(want - rest_facing, -PI, PI)
		want = rest_facing + clampf(gap, -1.0, 1.0)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * 3.0, 0.0, 1.0))
