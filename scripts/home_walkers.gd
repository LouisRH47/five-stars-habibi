class_name HomeWalkers
extends Node3D
## Session 68: now and then someone walks out of a restaurant near you, walks along the
## paths to a nearby home in one of the clusters and goes in through the front door
## (scripts/home_walker.gd). Nobody vanishes in plain sight. The route comes from the same
## map scan the GPS uses (scripts/navigation_grid.gd), shared, scanned a bit each frame.
## Only walkers near the camera are fully animated; further away they slide along holding
## their pose, and past the life view distance they're hidden. Made by CustomerSpawner.
## Numbers: the "people who live here" block in scripts/game_config.gd.

var place_builder: PlaceBuilder
## The map scan (shared with the GPS). The smoke test can hand in its own.
var grid: NavigationGrid
## Everyone walking home right now.
var walkers: Array[HomeWalker] = []

var _spawn_left := 4.0
var _check_left := 0.0
var _count := 0


func _physics_process(_delta: float) -> void:
	if place_builder == null or not place_builder.data.get_script_constant_map().has("MAP_HALF"):
		return
	if grid == null:
		grid = NavigationGrid.cached(get_world_3d(), place_builder.data.get_script_constant_map()["MAP_HALF"],
				_ignore(), true, place_builder)
	if not grid.scan_complete:
		grid.scan_next(get_world_3d(), _ignore(), GameConfig.GPS_SCAN_CELLS_PER_FRAME)


func _process(delta: float) -> void:
	walkers.assign(walkers.filter(func(w) -> bool: return is_instance_valid(w) and not w.inside))
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.25
		_update_detail()
	_spawn_left -= delta
	if _spawn_left > 0.0:
		return
	_spawn_left = GameConfig.HOME_WALKER_EVERY
	if walkers.size() >= GameConfig.HOME_WALKER_MAX or grid == null or not grid.scan_complete:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var near: Array = place_builder.restaurants.filter(func(r: Dictionary) -> bool:
		return r["position"].distance_to(camera.global_position) < GameConfig.HOME_WALKER_NEAR)
	if near.is_empty():
		return
	var shop: Dictionary = near.pick_random()
	spawn_from(shop["id"], nearby_home(shop["position"]))


## A home near `spot` (one of the HOME_WALKER_HOME_CHOICES closest). Short walks keep the
## route search small, so working it out never makes the game stutter.
func nearby_home(spot: Vector3) -> int:
	var homes: Array = place_builder.villas.filter(func(v: Dictionary) -> bool: return v.get("kind", "") != "spot")
	homes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["position"].distance_squared_to(spot) < b["position"].distance_squared_to(spot))
	return homes.slice(0, GameConfig.HOME_WALKER_HOME_CHOICES).pick_random()["number"]


## Sends someone out of restaurant `id` to walk home to villa `number`. Null if there's
## no way there (or the map scan isn't done).
func spawn_from(id: String, number: int) -> HomeWalker:
	var route := route_for(id, number)
	if route.is_empty():
		return null
	var walker := HomeWalker.new()
	walker.name = "HomeWalker_%d" % _count
	_count += 1
	add_child(walker)
	var who := PlaceLooks.shopper(_count)
	who.set_meta("outfit", "walking home")
	walker.setup(who, route, route[route.size() - 2], number)
	walkers.append(walker)
	return walker


## The corners from just inside the restaurant to just inside the home's front door.
func route_for(id: String, number: int) -> Array[Vector3]:
	var route: Array[Vector3] = []
	var shop := _restaurant(id)
	var home := _villa(number)
	if shop.is_empty() or home.is_empty() or grid == null or not grid.scan_complete:
		return route
	var size := place_builder.restaurant_size_of(shop)
	if shop.get("interior", false):
		route.append(VenueBuilder.world_point(shop, Vector3(0, 0, size.z * 0.5 - 1.5)))
	var out := place_builder.restaurant_approach(id)
	var lane := place_builder.villa_approach(number)
	var corners := grid.path(Vector2(out.x, out.z), Vector2(lane.x, lane.z))
	if corners.is_empty():
		return []
	route.append(out)
	for corner in corners:
		route.append(Vector3(corner.x, 0, corner.y))
	route.append(lane)
	var angle := deg_to_rad(home["facing"])
	var front := Vector3(sin(angle), 0, cos(angle))
	var wall: Vector3 = home["position"] + front * place_builder.villa_size_of(home).z * 0.5
	route.append(place_builder.villa_door(number))
	route.append(wall)  # the front door (it's in the wall)
	route.append(wall - front * GameConfig.HOME_WALKER_DOOR_FADE)  # inside: hidden by the house
	for i in route.size():
		route[i].y = 0.0
	return route


func _update_detail() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var far: float = GameConfig.LIFE_VIEW_DISTANCE[clampi(Settings.graphics, 0, 2)]
	var space := get_world_3d().direct_space_state
	for walker in walkers:
		var gap := walker.global_position.distance_to(camera.global_position)
		PlaceCrowds.apply_detail(walker.person, gap, far)
		if gap < GameConfig.PEOPLE_ANIMATE_DISTANCE:
			# Near you: stand on the real ground (the Plaza's sunken square, kerbs).
			var at := walker.global_position
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.5, at + Vector3.DOWN * 2.0, 1, _ignore_rids()))
			walker.person.position.y = (hit["position"].y - at.y) if not hit.is_empty() and absf(hit["position"].y) < 1.0 else 0.0


func _ignore() -> Array:
	var list: Array = []
	for watched in ["Bike", "Walker"]:
		var node := get_parent().get_parent().get_node_or_null(watched) if get_parent() != null else null
		if node != null:
			list.append(node)
	return list


func _ignore_rids() -> Array[RID]:
	var rids: Array[RID] = []
	for node in _ignore():
		if node is CollisionObject3D:
			rids.append(node.get_rid())
	return rids


func _restaurant(id: String) -> Dictionary:
	for place in place_builder.restaurants:
		if place["id"] == id:
			return place
	return {}


func _villa(number: int) -> Dictionary:
	for place in place_builder.villas:
		if place["number"] == number:
			return place
	return {}
