class_name Shoes
## Session 92: rounded shoes. Each shoe is two pieces, so it bends with the foot when
## people walk and run: the back (heel to the ball of the foot) follows the foot bone, the
## front (the toes) follows the toe bone. Before, one stiff box stuck out when the toes bent.
## sole: a different colour along the bottom (Color(0, 0, 0, 0) = none). laces: three laces
## across the top (the player's trainers). Every piece is one small mesh, shared by everyone
## with the same shoes and size, with the shared vertex-colour material (cheap).

## The model's foot (a grown-up): ankle to the ball of the foot, and the toes (metres).
const FOOT_LENGTH := 0.171
const TOE_LENGTH := 0.072

static var _meshes := {}


## Shoes on both feet.
static func put_on(person: Person, colour: Color, sole := Color(0, 0, 0, 0), laces := Color(0, 0, 0, 0)) -> void:
	for side in ["Left", "Right"]:
		one(person, side, colour, sole, laces)


## One shoe on the "Left" or "Right" foot. Returns the holder that follows the foot.
static func one(person: Person, side: String, colour: Color, sole := Color(0, 0, 0, 0),
		laces := Color(0, 0, 0, 0)) -> Node3D:
	person.repaint({"shoes": colour})  # the feet themselves too (they never lag behind)
	var ankle := person.spot(side + "Foot")
	var ball := person.spot(side + "ToeBase")
	var tip := person.spot(side + "Toe_End")
	var key := "%s|%s|%s|%s|%s" % [side, colour, sole, laces, snappedf(ankle.distance_to(tip), 0.001)]
	if not _meshes.has(key):
		_meshes[key] = [_back(ankle, ball, colour, sole, laces), _front(ball, tip, colour, sole)]
	var foot := person.follow(side + "Foot")
	var toes := person.follow(side + "ToeBase")
	for part in [[foot, 0, "Shoe"], [toes, 1, "ShoeToe"]]:
		var view := MeshInstance3D.new()
		view.name = part[2]
		view.mesh = _meshes[key][part[1]]
		view.material_override = MeshKit.material()
		(part[0] as Node3D).add_child(view)
	return foot


## From behind the heel to the ball of the foot: an egg shape round the foot, with the
## sole under it and the laces on top. Sizes are measured round the model's foot (metres
## across, up and along the foot from the ankle), scaled with the person (`grow`).
static func _back(ankle: Vector3, ball: Vector3, colour: Color, sole: Color, laces: Color) -> Mesh:
	var along := (ball - ankle).normalized()
	var up := (Vector3.UP - along * along.dot(Vector3.UP)).normalized()
	var turn := Basis.looking_at(along, up)  # its -Z points along the foot
	var grow := ankle.distance_to(ball) / FOOT_LENGTH
	var middle := ankle + (up * -0.03 + along * 0.04) * grow
	var half := Vector3(GameConfig.SHOE_WIDTH * 0.5, GameConfig.SHOE_HEIGHT * 0.5, 0.13) * grow
	var kit := MeshKit.new()
	kit.ball(1.0, colour, middle, 1.0, turn * Basis.from_scale(half))
	if sole.a > 0.0:
		kit.box(Vector3(half.x * 1.5, 0.024 * grow, half.z * 1.5), sole, middle - up * half.y * 0.78, turn)
	if laces.a > 0.0:
		for k in 3:  # across the top of the foot, in front of the ankle
			var d := (0.02 + k * 0.028) * grow
			var top := half.y * sqrt(maxf(1.0 - pow(d / half.z, 2.0), 0.0))
			kit.box(Vector3(half.x * 0.9, 0.012, 0.014) * Vector3(1, grow, grow), laces,
					middle + along * d + up * (top - 0.002), turn)
	return _mesh(kit)


## The toes: a smaller rounded cap, with the sole under it.
static func _front(ball: Vector3, tip: Vector3, colour: Color, sole: Color) -> Mesh:
	var along := (tip - ball).normalized()
	var up := (Vector3.UP - along * along.dot(Vector3.UP)).normalized()
	var turn := Basis.looking_at(along, up)
	var grow := ball.distance_to(tip) / TOE_LENGTH
	var middle := ball + (up * 0.012 + along * 0.032) * grow
	var half := Vector3(GameConfig.SHOE_WIDTH * 0.48, 0.042, 0.062) * grow
	var kit := MeshKit.new()
	kit.ball(1.0, colour, middle, 1.0, turn * Basis.from_scale(half))
	if sole.a > 0.0:
		kit.box(Vector3(half.x * 1.5, 0.024 * grow, half.z * 1.3), sole, middle - up * half.y * 0.72, turn)
	return _mesh(kit)


static func _mesh(kit: MeshKit) -> Mesh:
	var view := kit.finish()
	var mesh := view.mesh
	view.free()
	return mesh
