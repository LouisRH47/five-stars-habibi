class_name LoungePose
## Session 92: lying back on a sun lounger ("lounge"), made in code like the other poses in
## scripts/person_pose.gd. On the person (standing straight) the legs go forward a little
## (the hips bend 40 degrees) and stay straight; Sunbathers then tips the whole person back
## so the legs lie along the cushion and the back rests on the raised end.
##   pose.reading = true: both hands hold a book up in front of the chest, the head bent
##   down a little to read it. Otherwise the arms rest by the sides.


static func apply(pose: PersonPose) -> void:
	var skeleton := pose.get_skeleton()
	for bone in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head"]:
		var i := skeleton.find_bone(bone)
		skeleton.set_bone_pose_rotation(i, skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
	var hips := skeleton.find_bone("Hips")
	skeleton.set_bone_pose_position(hips, skeleton.get_bone_rest(hips).origin)
	var bend := deg_to_rad(GameConfig.LOUNGE_HIP_DEG)
	var leg := Vector3(0, -cos(bend), -sin(bend))
	for side in [-1.0, 1.0]:
		var name := "Left" if side < 0.0 else "Right"
		pose.point(name + "UpLeg", name + "Leg", leg + Vector3(side * 0.05, 0, 0))
		pose.point(name + "Leg", name + "Foot", leg + Vector3(side * 0.03, 0, 0.04))
		pose.point(name + "Foot", name + "ToeBase", Vector3(side * 0.35, 0.45, -0.85))  # toes to the sky
		if not pose.reading:
			pose.point(name + "Arm", name + "ForeArm", Vector3(side * 0.22, -1, 0.05))
			pose.point(name + "ForeArm", name + "Hand", Vector3(side * 0.12, -1, -0.12))
	if pose.reading:
		var book := book_spot(pose.person)
		for side in [-1.0, 1.0]:
			var name := "Left" if side < 0.0 else "Right"
			pose.reach(name + "Arm", name + "ForeArm", name + "Hand", book + Vector3(side * 0.11, -0.05, 0.03),
					Vector3(side, -1.0, 0.6))
		pose.turn("Neck", Vector3.RIGHT, deg_to_rad(-12.0))  # looking down at the book
		pose.turn("Head", Vector3.RIGHT, deg_to_rad(-10.0))
		# Turning the page now and then: the right hand lifts a little.
	pose.turn("Head", Vector3.UP, deg_to_rad(8.0) * sin(pose.clock * 0.3 + pose.own_time))


## Where the reader holds the book (metres on the person): in front of the chest.
static func book_spot(person: Person) -> Vector3:
	return Vector3(0, person.spot("Spine2").y + GameConfig.LOUNGE_BOOK_UP, -GameConfig.LOUNGE_BOOK_OUT)


## An open book (two covers and the pages) held at book_spot(), facing the reader.
static func add_book(person: Person, colour: Color) -> Node3D:
	var book := Node3D.new()
	book.name = "Book"
	book.position = book_spot(person)
	book.rotation.x = deg_to_rad(65.0)  # tipped back towards the face
	person.add_child(book)
	for side in [-1.0, 1.0]:
		var half := LowPoly.box(book, Vector3(0.13, 0.19, 0.012), colour, Vector3(side * 0.062, 0, 0))
		half.rotation.y = side * deg_to_rad(12.0)
		var pages := LowPoly.box(book, Vector3(0.12, 0.175, 0.016), Color(0.97, 0.96, 0.9), Vector3(side * 0.06, 0, -0.012))
		pages.rotation.y = side * deg_to_rad(12.0)
	return book
