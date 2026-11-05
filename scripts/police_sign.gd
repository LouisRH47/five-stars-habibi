class_name PoliceSign
## Session 65: the made-up community police sign (like the real "monitored area" signs,
## but no real police badge): a white board on a grey pole, a red "Attention / تنبيه"
## header with a camera icon, a made-up emblem (a gold star over a little dhow on a navy
## disc) and the words "5-Star Habibi Police: Area is monitored by Habibi Smart Home
## Security" in English and Arabic. One at each cluster entrance and a few beside the
## spine's red tracks (ClusterSigns places them). It reads from its front (+Z).

const BOARD := Vector3(1.1, 1.6, 0.04)
const MIDDLE := 2.05                  # metres from the ground to the middle of the board
const WHITE := Color(0.98, 0.98, 0.97)
const RED := Color(0.8, 0.1, 0.1)
const NAVY := Color(0.1, 0.18, 0.4)
const GOLD := Color(0.93, 0.74, 0.2)
const INK := Color(0.12, 0.14, 0.2)
const POLE := Color(0.6, 0.62, 0.64)

const ENGLISH := ["5-Star Habibi Police", "Area is monitored by", "Habibi Smart Home Security"]
const ARABIC := ["شرطة حبيبي الخمس نجوم", "المنطقة مراقبة من قبل", "أمن حبيبي للمنازل الذكية"]


## One sign (not yet added to the scene). Its foot is at (0, 0, 0).
static func make() -> StaticBody3D:
	var body := StaticBody3D.new()
	var kit := MeshKit.new()
	var half := Vector2(BOARD.x, BOARD.y) * 0.5
	var top := MIDDLE + half.y
	kit.cylinder(0.045, 0.05, top, POLE, Vector3(0, top * 0.5, -0.05), Basis(), 8)
	kit.box(BOARD, WHITE, Vector3(0, MIDDLE, 0))
	kit.box(BOARD + Vector3(0.04, 0.04, -0.02), POLE, Vector3(0, MIDDLE, -0.01))  # metal edge
	var front := BOARD.z * 0.5 + 0.004
	# The red header band, and a camera on it (body, lens, the bracket it hangs from).
	var header_y := top - 0.17
	kit.box(Vector3(BOARD.x, 0.3, 0.006), RED, Vector3(0, header_y, front))
	var cam := Vector3(-half.x + 0.17, header_y, front + 0.01)
	kit.box(Vector3(0.18, 0.1, 0.02), WHITE, cam)
	kit.box(Vector3(0.05, 0.08, 0.02), WHITE, cam + Vector3(0.1, -0.02, 0))
	kit.cylinder(0.03, 0.03, 0.02, INK, cam + Vector3(-0.04, 0, 0.012), Basis(Vector3.RIGHT, PI * 0.5), 10)
	kit.box(Vector3(0.025, 0.07, 0.02), WHITE, cam + Vector3(0.0, 0.08, 0))
	# The emblem: a navy disc with a gold rim, a gold star and a dhow (hull and sail).
	var badge := Vector3(0, header_y - 0.33, front)
	var flat := Basis(Vector3.RIGHT, PI * 0.5)
	kit.cylinder(0.155, 0.155, 0.006, GOLD, badge, flat, 16)
	kit.cylinder(0.135, 0.135, 0.006, NAVY, badge + Vector3(0, 0, 0.004), flat, 16)
	var star := badge + Vector3(0, 0.055, 0.008)
	for k in 2:  # two squares turned 45 degrees make an eight-pointed star
		kit.box(Vector3(0.06, 0.06, 0.004), GOLD, star, Basis(Vector3.BACK, PI * 0.25 * k))
	var hull := badge + Vector3(0, -0.07, 0.008)
	kit.box(Vector3(0.15, 0.025, 0.004), GOLD, hull)
	kit.box(Vector3(0.04, 0.025, 0.004), GOLD, hull + Vector3(0.085, 0.01, 0), Basis(Vector3.BACK, 0.5))
	kit.box(Vector3(0.008, 0.08, 0.004), WHITE, hull + Vector3(-0.005, 0.05, 0))  # mast
	kit.cylinder(0.04, 0.04, 0.004, WHITE, hull + Vector3(0.02, 0.05, 0), Basis(Vector3.BACK, PI * 0.5) * flat, 3)  # sail
	body.add_child(kit.finish("Sign"))
	LowPoly.solid_cylinder(body, 0.08, top, Vector3(0, top * 0.5, -0.05))
	# The words.
	var z := front + 0.012
	_line(body, "Attention", 34, WHITE, Vector3(0.12, header_y + 0.05, z))
	_line(body, "تنبيه", 30, WHITE, Vector3(0.12, header_y - 0.08, z))
	var y := badge.y - 0.24
	for i in ENGLISH.size():
		var size := ClusterSigns._fit(ENGLISH[i], 24 if i == 0 else 20, BOARD.x - 0.14)
		_line(body, ENGLISH[i], size, NAVY if i == 0 else INK, Vector3(0, y, z))
		y -= 0.11 if i == 0 else 0.1
	y -= 0.03
	for i in ARABIC.size():
		var size := ClusterSigns._fit(ARABIC[i], 24 if i == 0 else 21, BOARD.x - 0.14)
		_line(body, ARABIC[i], size, NAVY if i == 0 else INK, Vector3(0, y, z))
		y -= 0.11
	body.set_meta("police_sign", true)
	return body


static func _line(body: Node3D, words: String, size: int, colour: Color, at: Vector3) -> void:
	var label := SignText.make_label(words, size, colour, Color(0, 0, 0, 0), 0)
	label.position = at
	body.add_child(label)
