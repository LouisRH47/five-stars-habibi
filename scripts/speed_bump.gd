extends Area3D
## One speed bump right across a road: a low yellow hump with black stripes.
## It is NOT solid on purpose. A flat bump only 12 cm high would catch the bike's box
## collider in odd ways and could even get it stuck. Instead this is a trigger area:
## when the bike rides onto it, it calls the bike's hit_speed_bump(), and the bike hops,
## the camera shakes and the bike slows down (more when you're fast). That's how the bike
## "collides with bumps" (BUILD_PLAN Session 6); parked cars are properly solid.
## DecorBuilder places one of these (scenes/speed_bump.tscn) for every bump in the data
## list and calls setup(). The bump runs across local X; you ride over it along local Z.

const YELLOW := Color(0.98, 0.78, 0.1, 1)
const BLACK := Color(0.1, 0.1, 0.1, 1)
const STRIPE_WIDTH := 0.6     # about how wide each yellow or black band is
const ROAD_TOP := 0.04        # the road surface height (MapBuilder.ROAD_THICKNESS)
const TRIGGER_HEIGHT := 1.0   # the invisible trigger box reaches this high


## Builds the bump. size: width (across the road), height, depth (along the road).
func setup(size: Vector3) -> void:
	var middle_y := ROAD_TOP + size.y * 0.5
	LowPoly.box(self, size, YELLOW, Vector3(0, middle_y, 0))
	# Black bands on every other stripe. An odd number, so both ends are yellow.
	var count := roundi(size.x / STRIPE_WIDTH)
	if count % 2 == 0:
		count += 1
	var stripe := size.x / float(count)
	# A hair bigger than the yellow box, so the colours don't flicker where they meet.
	var band := Vector3(stripe, size.y + 0.004, size.z + 0.02)
	for i in count:
		if i % 2 == 1:
			var x := -size.x * 0.5 + stripe * (float(i) + 0.5)
			LowPoly.box(self, band, BLACK, Vector3(x, middle_y, 0))

	# The invisible trigger over the whole bump. It notices bodies but doesn't block them.
	var trigger := BoxShape3D.new()
	trigger.size = Vector3(size.x, TRIGGER_HEIGHT, size.z)
	var shape := CollisionShape3D.new()
	shape.shape = trigger
	shape.position.y = TRIGGER_HEIGHT * 0.5
	add_child(shape)
	body_entered.connect(_on_body_entered)


## body_entered only fires once until the body has fully left the area,
## so riding slowly over the bump never counts twice.
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("bike") and body.has_method("hit_speed_bump"):
		body.hit_speed_bump()
