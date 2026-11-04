class_name InteriorRoom
extends RefCounted
## Session 58: a Plaza restaurant's room, rebuilt the way real ones are laid out (PRD
## "Looks pass", Interiors; Appendix B). 12 m wide, 10 m deep, a 4.5 m ceiling, the glass
## front (ShopFront) on the Plaza side. Dining at the front (about 75% of the room), the
## counter line at 7.2 m in, the kitchen behind it with the menu board on the back wall.
## The room's own parts come from InteriorVenues (Session 58) and InteriorVenuesB (59).
## Room directions: x from -6 (left, seen from the door) to +6; z from +5 (glass) to -5.
## GameConfig.INTERIORS_LOOKS_PASS = false brings back the old plain room (VenueBuilder).

const FLOOR_TOP := 0.01


## Builds the whole room for a restaurant in RESTAURANTS (it has a "row").
static func build(place: Dictionary, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var id: String = place.get("id", "")
	body.set_meta("walk_in", true)
	body.set_meta("venue_type", place.get("venue_type", id))
	body.set_meta("interior_looks", true)
	body.set_meta("room_size", size)
	body.set_meta("pickup", pickup(place))
	body.add_to_group("interior_room")   # the follow camera comes closer in here
	var p := InteriorParts.new(body, place, size)
	var style := InteriorVenues.style(id)
	_shell(p, style)
	ShopFront.build(body, place, size)
	if id in ["thai", "sushi", "tacos", "burger"]:
		InteriorVenuesB.build(p)
	else:
		InteriorVenues.build(p)
	_fill_light(p, style.get("cool", false))
	_sound(p)
	var queue := CounterQueue.new()
	queue.name = "CounterQueue"
	queue.setup(p, pickup(place), style.get("till", Vector3(2.8, 0, -1.5)))
	body.add_child(queue)
	p.finish()
	return body


## Where you stand to pick up an order here (room directions), from InteriorMenus.
static func pickup(place: Dictionary) -> Vector3:
	return InteriorMenus.PICKUP.get(place.get("id", ""), Vector3(0, 0, -1.45))


## Floor tiles, side and back walls (with a lower band), the ceiling. The front is ShopFront.
static func _shell(p: InteriorParts, style: Dictionary) -> void:
	var half := p.size * 0.5
	var a: Color = style["floor"][0]
	var b: Color = style["floor"][1]
	var tile: float = style.get("tile", 0.5)
	var pattern: String = style.get("pattern", "checker")
	var nx := roundi(p.size.x / tile)
	var nz := roundi(p.size.z / tile)
	for i in nx:
		for k in nz:
			var colour := a
			match pattern:
				"checker":
					colour = a if (i + k) % 2 == 0 else b
				"planks":
					colour = a.lerp(b, float((i * 7 + (k / 4) * 3) % 5) / 4.0)
				"border":
					colour = b if i == 0 or k == 0 or i == nx - 1 or k == nz - 1 else a
				_:
					colour = a.lerp(b, float((i * 3 + k * 5) % 4) / 6.0)
			var w := tile * (0.98 if pattern != "planks" else 1.0)
			p.box(Vector3(w, 0.04, tile * 0.98), colour, Vector3(-half.x + (i + 0.5) * tile, FLOOR_TOP - 0.02, -half.z + (k + 0.5) * tile))
	# The grout under the tiles. Session 59: raised to just under the tile tops, so the Plaza
	# paving under the room no longer shows through the gaps as light lines.
	p.box(Vector3(p.size.x, 0.01, p.size.z), b.darkened(0.4), Vector3(0, FLOOR_TOP - 0.01, 0))
	var wall: Color = style["wall"]
	var band: Color = style.get("band", wall.darkened(0.15))
	var shared := shared_sides(p.place, p.size) if GameConfig.INTERIOR_REVIEW_FIXES else []
	for side in [-1.0, 1.0]:
		if side in shared:
			# Review fix: two shops in a pair are 12 m apart, so their 0.25 m side walls (centred
			# on the room's edge) filled exactly the same space and flickered into each other
			# (pale stripes on the wall). A shared wall is now only the inner half, up to the edge.
			p.solid(Vector3(0.125, p.size.y, p.size.z), wall, Vector3(side * (half.x - 0.0625), half.y, 0))
			continue
		p.solid(Vector3(0.25, p.size.y, p.size.z), wall, Vector3(side * half.x, half.y, 0))
		p.box(Vector3(0.02, 1.1, p.size.z - 0.3), band, Vector3(side * (half.x - 0.135), 0.55, 0))
	p.solid(Vector3(p.size.x, p.size.y, 0.25), style.get("back", wall), Vector3(0, half.y, -half.z))
	p.solid(Vector3(p.size.x + 0.2, 0.25, p.size.z + 0.2), style.get("ceiling", Color(0.93, 0.92, 0.9)), Vector3(0, p.size.y + 0.12, 0))


## Review fix: the sides (-1 left, +1 right, in room directions) where the next shop in the
## row (a restaurant or one of the two shops) is built right against this one, sharing the wall.
static func shared_sides(place: Dictionary, size: Vector3) -> Array:
	var out: Array = []
	if not place.has("row"):
		return out
	var me: Vector3 = place.get("position", Vector3.ZERO)
	var turn := deg_to_rad(float(place.get("facing", 0.0)))
	for side in [-1.0, 1.0]:
		var edge := me + Vector3(side * size.x * 0.5, 0, 0).rotated(Vector3.UP, turn)
		for other: Dictionary in WahatAlShams.RESTAURANTS + WahatAlShams.SHOPS:
			if other.get("id", "") == place.get("id", "") or not other.has("row"):
				continue
			var there: Vector3 = other["position"]
			var width: float = (other.get("size", WahatAlShams.RESTAURANT_SIZE) as Vector3).x
			if absf(there.z - me.z) < 0.1 and absf(absf(there.x - edge.x) - width * 0.5) < 0.05 \
					and signf(there.x - edge.x) == signf(edge.x - me.x):
				out.append(side)
	return out


## A soft light over the whole room, always on (the lamps add warm pools near you).
static func _fill_light(p: InteriorParts, cool: bool) -> void:
	var fill := OmniLight3D.new()
	fill.name = "InteriorLight"
	fill.position = Vector3(0, p.size.y - 0.5, 0.5)
	fill.light_color = Color(0.95, 0.97, 1.0) if cool else Color(1.0, 0.9, 0.78)
	fill.light_energy = 1.0 if cool else 0.7
	fill.omni_range = maxf(p.size.x, p.size.z) * 0.8
	fill.shadow_enabled = false
	p.body.add_child(fill)


## The room's own quiet sound. It plays from inside, so it fades in as you come in.
static func _sound(p: InteriorParts) -> void:
	var file := "res://assets/audio/%s.wav" % InteriorMenus.SOUNDS.get(p.id, "")
	if not ResourceLoader.exists(file):
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "RoomSound"
	var stream := load(file) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD   # like Sounds.looping()
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.bus = "Ambience"
	player.volume_db = GameConfig.INTERIOR_SOUND_DB
	player.unit_size = 3.0
	player.max_distance = GameConfig.INTERIOR_SOUND_RANGE
	player.position = Vector3(0, 2.0, -2.0)
	player.autoplay = true
	p.body.add_child(player)
	p.motion.sound = player
