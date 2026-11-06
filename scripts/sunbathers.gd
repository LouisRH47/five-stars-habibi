class_name Sunbathers
extends Node3D
## Session 92: people in swimwear lying on the loungers at the community pool (every
## other lounger, GameConfig.SUNBATHERS of them); one of them is reading a book. Made by
## PlaceCrowds, which hides the far ones and stops animating them (cheap).
## The loungers are PoolDeck's (the pool node has their spots as meta "loungers"): each
## lies along x with its back raised at the +x end, so the head goes there.

## Everyone lying on a lounger.
var people: Array[Person] = []


## Fills the loungers of the community pool. Returns [Person, Graphics level] for each.
## map: the map data (where the pool and its fence are, if the pool isn't built yet).
func build(map: Dictionary, world: Node) -> Array:
	var made: Array = []
	var spots: Array = []
	for node in world.find_children("*CommunityPool*", "Node3D", true, false):
		if node.has_meta("loungers"):
			spots = node.get_meta("loungers")
			break
	if spots.is_empty() and map.has("COMMUNITY_POOL") and map.has("POOL_GATE"):
		var deck := (map["POOL_GATE"]["fence"] as Rect2).grow(-0.1)  # like DistrictDetail._pool()
		spots = PoolDeck.lounger_spots(map["COMMUNITY_POOL"], deck)
	var count := mini(GameConfig.SUNBATHERS, (spots.size() + 1) / 2)
	for i in count:
		var person := _sunbather(spots[i * 2], i)
		made.append([person, 0 if i < 2 else 1])
	return made


## Someone lying back on the lounger whose middle is `at`.
func _sunbather(at: Vector3, i: int) -> Person:
	var person := PlaceLooks.swimmer(i + 3)
	person.name = "Sunbather%d" % i
	person.set_meta("outfit", "swimwear")
	person.set_meta("sunbather", true)
	var holder := Node3D.new()
	holder.name = "Lounger%d" % i
	# Tip the person back: their legs lie along -x, their back on the raised end (+x).
	var tilt := deg_to_rad(GameConfig.LOUNGE_HIP_DEG)
	var along_back := Vector3(cos(tilt), sin(tilt), 0)   # up the backrest
	var face_up := Vector3(-sin(tilt), cos(tilt), 0)      # where their front looks
	holder.basis = Basis(Vector3(0, 0, -1), along_back, -face_up)
	holder.position = at + GameConfig.SUNBATHER_HIPS
	add_child(holder)
	holder.add_child(person)
	person.position = -person.spot("Hips")
	person.pose.reading = i == 1
	person.play("lounge")
	if person.pose.reading:
		LoungePose.add_book(person, [Color(0.2, 0.45, 0.75), Color(0.85, 0.3, 0.25)][i % 2])
	people.append(person)
	return person
