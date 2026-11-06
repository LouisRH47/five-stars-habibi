class_name CourtSpacing
## Session 92: keeps the players on a court or pitch from running into each other. Two
## players chasing the same ball used to end up on the same spot, so their bodies were in
## the same place and flickered through each other. spread() pushes any two that are
## closer than `gap` metres apart, half each, every frame.


## holders: the players' holders (Node3D, all on the same parent).
static func spread(holders: Array, gap: float) -> void:
	for a in holders.size():
		for b in range(a + 1, holders.size()):
			var one := holders[a] as Node3D
			var two := holders[b] as Node3D
			var apart := Vector2(two.position.x - one.position.x, two.position.z - one.position.z)
			var length := apart.length()
			if length >= gap:
				continue
			# Exactly on top of each other: pick a side (the same one every time).
			var way := apart / length if length > 0.001 else Vector2(1, 0).rotated(a * 1.3 + b)
			var push := way * (gap - length) * 0.5
			one.position -= Vector3(push.x, 0, push.y)
			two.position += Vector3(push.x, 0, push.y)


## The holders of a list of people.
static func holders_of(people: Array) -> Array:
	return people.map(func(person: Node3D) -> Node3D: return person.get_parent() as Node3D)
