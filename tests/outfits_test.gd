extends SceneTree
## Session 83: every outfit's clothes stay on the body. It builds each outfit (swimwear, gym
## kit, uniforms, jodhpurs, hi-vis, bee suit, waiters, commuters...), plays standing,
## walking and sitting (and swimming for swimwear), and checks each piece of clothing
## (hats, shorts, vests, aprons, boots, bags...) still touches the bone it hangs on in
## every frame, so nothing floats off or gets left behind. It also checks the people
## are built facing the right way, so a cap's peak and a face are at the front.
## Run: Godot --path . --headless -s tests/outfits_test.gd
var failures: Array[String] = []
var checks := 0

## The bone each bone's piece is measured along (from the bone to this one).
const ALONG := {
	"Head": "HeadTop_End", "Neck": "Head", "Spine2": "Neck", "Spine1": "Spine2", "Spine": "Spine1",
	"Hips": "Spine", "LeftUpLeg": "LeftLeg", "RightUpLeg": "RightLeg", "LeftLeg": "LeftFoot",
	"RightLeg": "RightFoot", "LeftFoot": "LeftToe_End", "RightFoot": "RightToe_End",
	"LeftArm": "LeftForeArm", "RightArm": "RightForeArm", "LeftForeArm": "LeftHand",
	"RightForeArm": "RightHand", "LeftHand": "LeftHandIndex2", "RightHand": "RightHandIndex2",
}
## About how thick the body is round each bone (metres from the bone to the skin).
const BODY := {"Head": 0.13, "Neck": 0.07, "Spine2": 0.15, "Spine1": 0.15, "Spine": 0.14, "Hips": 0.14,
	"UpLeg": 0.08, "Leg": 0.06, "Foot": 0.05, "Arm": 0.05, "ForeArm": 0.045, "Hand": 0.04}
## How far (metres) a piece may sit beyond its own size and the skin before it "floats".
const SLACK := 0.03


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, label: String, detail := "") -> void:
	checks += 1
	if not ok:
		failures.append(label)
	print("PASS: " if ok else "FAIL: ", label, " ", detail)


func _run() -> void:
	# Loaded here (not named at the top) so the test starts even before the game's
	# autoloads are known to every script.
	var people: Script = load("res://scripts/people_looks.gd")
	var places: Script = load("res://scripts/place_looks.gd")
	var life: Script = load("res://scripts/life_looks.gd")
	var rider: Script = load("res://scripts/rider_look.gd")
	var outfits := {
		"kandura": func(): return people.resident(0, 0),
		"abaya": func(): return people.resident(1, 1),
		"t-shirt": func(): return people.resident(2, 2),
		"hoodie": func(): return people.resident(3, 3),
		"cap": func(): return people.resident(4, 0),
		"swimwear (bare top)": func(): return places.swimmer(0),
		"swimwear (rash guard, cap)": func(): return places.swimmer(1),
		"lifeguard": func(): return places.lifeguard(),
		"lifeguard (whistle)": func(): return places.lifeguard(false),
		"gym kit": func(): return places.gym_goer(0),
		"school uniform": func(): return places.pupil(),
		"teacher": func(): return places.teacher(),
		"jodhpurs": func(): return places.rider(),
		"groom": func(): return places.groom(),
		"shopper": func(): return places.shopper(1),
		"waiter": func(): return places.waiter(0),
		"commuter (backpack)": func(): return places.commuter(0),
		"commuter (suitcase)": func(): return places.commuter(1),
		"jogger": func(): return places.jogger(0),
		"bee suit": func(): return places.beekeeper(),
		"hi-vis": func(): return places.worker(0),
		"kid": func(): return life.kid(),
		"gardener": func(): return life.gardener(1.0)[1],
		"rider": func(): return rider.make_rider(),
	}
	var x := 0.0
	var all: Array = []
	for name: String in outfits:
		var person: Node3D = outfits[name].call()
		if person.get_parent() != null:
			person.get_parent().remove_child(person)
		person.position = Vector3(x, 0, 0)
		x += 2.0
		root.add_child(person)
		all.append([name, person])
	_check_facing(all[0][1])
	for action in ["idle", "walk", "sit", "jog"]:
		await _check_action(all, action)
	var swimmers := all.filter(func(entry): return str(entry[0]).begins_with("swimwear"))
	await _check_action(swimmers, "swim")
	for entry in all:
		entry[1].queue_free()
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " outfits · ", checks, " checks · ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)


## People are built facing -Z, legs and shoulders side by side, so clothes placed "in
## front" (a cap's peak, the face, an apron) really are in front.
func _check_facing(person: Node3D) -> void:
	var hips: Vector3 = person.spot("RightUpLeg") - person.spot("LeftUpLeg")
	var shoulders: Vector3 = person.spot("RightArm") - person.spot("LeftArm")
	_expect(hips.x > 0.1 and absf(hips.z) < 0.02 and shoulders.x > 0.2 and absf(shoulders.z) < 0.03,
			"people are built standing straight: left to right is +X, the front is -Z",
			"hips %s shoulders %s" % [hips, shoulders])


## Plays `action` on everyone and watches each piece of clothing for 40 frames.
func _check_action(all: Array, action: String) -> void:
	var worst := {}  # outfit name -> [how far past its size the worst piece got, which piece]
	var watchers := {}
	for entry in all:
		var person: Node3D = entry[1]
		person.play(action)
		worst[entry[0]] = [-1.0, ""]
		watchers[person] = _measure.bind(person, worst, entry[0])
		person.skeleton.skeleton_updated.connect(watchers[person])
	for i in 40:
		await process_frame
	for entry in all:
		var person: Node3D = entry[1]
		person.skeleton.skeleton_updated.disconnect(watchers[person])
		var result: Array = worst[entry[0]]
		_expect(result[0] <= SLACK, "%s: the clothes stay on the body (%s)" % [entry[0], action],
				"worst %.2f m off: %s" % [result[0], result[1]])


## For each piece of clothing: how far it is from the bone it follows, beyond its own size.
func _measure(person: Node3D, worst: Dictionary, outfit: String) -> void:
	var skeleton: Skeleton3D = person.skeleton
	for holder: Node in person.find_children("*", "Node3D", true, false):
		if not holder.has_meta("bone"):
			continue
		var bone: int = holder.get_meta("bone")
		var bone_name := skeleton.get_bone_name(bone)
		var tip := skeleton.find_bone(ALONG.get(bone_name, ""))
		var a := _bone_on_map(person, bone)
		var b := _bone_on_map(person, tip) if tip >= 0 else a
		for piece: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
			if piece.mesh == null or not piece.is_visible_in_tree():
				continue
			var box := piece.mesh.get_aabb()
			var middle := piece.global_transform * box.get_center()
			var size := (piece.global_basis * (box.size * 0.5)).length()
			var off := _to_segment(middle, a, b) - size - _body(bone_name)
			if off > worst[outfit][0]:
				worst[outfit] = [off, "%s on %s" % [piece.name, bone_name]]


## How thick the body is round a bone ("LeftUpLeg" -> "UpLeg").
func _body(bone_name: String) -> float:
	return BODY.get(bone_name.trim_prefix("Left").trim_prefix("Right"), 0.05)


func _bone_on_map(person: Node3D, bone: int) -> Vector3:
	return person.global_transform * (person.skeleton_to_me * person.skeleton.get_bone_global_pose(bone).origin)


func _to_segment(point: Vector3, a: Vector3, b: Vector3) -> float:
	var line := b - a
	if line.length_squared() < 0.000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(line) / line.length_squared(), 0.0, 1.0)
	return point.distance_to(a + line * t)
