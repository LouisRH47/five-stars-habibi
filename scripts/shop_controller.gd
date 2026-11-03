class_name ShopController
extends Node
## Hold E at either shop's counter on foot. Browse and dress a real 3D preview,
## then commit the whole cart together. Closing a preview never changes saved clothes.

@export var bike: Node3D
@export var camera: Camera3D
@export var walker: Node3D

var showing := false
var active_shop := ""
var cart: ShopCart
var panel: SidePanel
var _places: Array = []
var _category := 0
var _selected := 0
var _hold := 0.0
var _need_release := false
var _preview: Node3D
var _preview_camera: Camera3D
var _preview_equipped := {}
var _hidden := {}
var _status := ""
var _prompt: Label
var _prompt_layer: CanvasLayer
var _dragging := false
var _state: Node


func configure(shops: Array) -> void:
	_places = shops


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state = get_tree().root.get_node("GameState")
	if walker == null:
		walker = get_parent().get_node_or_null("Walker")
	cart = ShopCart.new(_state)
	panel = SidePanel.new()
	add_child(panel)
	_prompt_layer = CanvasLayer.new()
	_prompt_layer.layer = 20
	add_child(_prompt_layer)
	_prompt = Label.new()
	_prompt.position = Vector2(620, 940)
	_prompt.add_theme_font_size_override("font_size", 25)
	_prompt.add_theme_color_override("font_color", Color(1, 0.86, 0.56))
	_prompt_layer.add_child(_prompt)
	apply_equipment()


func _process(delta: float) -> void:
	if showing:
		if _preview != null and not _dragging:
			_preview.rotate_y(GameConfig.SHOP_PREVIEW_TURN_SPEED * delta)
		return
	_prompt.visible = false
	if get_tree().paused:
		return
	if not Input.is_action_pressed("interact"):
		_need_release = false
		_hold = 0.0
	var id := nearby_shop()
	if id == "":
		_hold = 0.0
		return
	_prompt.visible = true
	_prompt.text = "Hold E · %s" % ("Pedal Point Bikes" if id == "bikes" else "Dune Drip")
	if Input.is_action_pressed("interact") and not _need_release:
		_hold += delta
		_prompt.text += "  %d%%" % mini(100, roundi(_hold / GameConfig.SHOP_HOLD_TIME * 100))
		if _hold >= GameConfig.SHOP_HOLD_TIME:
			open_shop(id)
			_need_release = true


func nearby_shop() -> String:
	if walker == null or walker.get("active") != true:
		return ""
	for place: Dictionary in _places:
		var counter := _shop_transform(place) * (ShopInterior.COUNTER + Vector3(0, 0, 1.0))
		if Vector2(walker.global_position.x - counter.x, walker.global_position.z - counter.z).length() <= GameConfig.SHOP_INTERACT_DISTANCE:
			return place["id"]
	return ""


func _input(event: InputEvent) -> void:
	if not showing:
		# Prevent a shop-counter E press from also accepting a phone order.
		if not get_tree().paused and nearby_shop() != "" and event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed and event.position.x > 550
	elif event is InputEventMouseMotion and _dragging and _preview != null:
		_preview.rotate_y(event.relative.x * 0.01)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				close_shop()
			KEY_E:
				add_selected()
			KEY_C:
				checkout()
			KEY_W, KEY_UP, KEY_LEFT:
				_change_category(-1)
			KEY_S, KEY_DOWN, KEY_RIGHT:
				_change_category(1)
			KEY_A:
				select_item(_selected - 1)
			KEY_D:
				select_item(_selected + 1)
		get_viewport().set_input_as_handled()


func open_shop(id: String) -> bool:
	if showing or get_tree().paused or _place(id).is_empty():
		return false
	showing = true
	active_shop = id
	_category = 0
	_selected = 0
	_hold = 0.0
	_status = ""
	cart.clear()
	_preview_equipped = _state.equipped_cosmetics.duplicate()
	_prompt.visible = false
	for name in ["HUD", "Phone", "Minimap", "MetersPanel"]:
		var node := get_parent().get_node_or_null(name)
		if node != null:
			_hidden[node] = node.visible
			node.visible = false
	_build_preview()
	get_tree().paused = true
	select_item(0)
	return true


func close_shop() -> void:
	if not showing:
		return
	showing = false
	cart.clear()
	panel.hide_panel()
	_dragging = false
	_need_release = true
	if _preview != null:
		_preview.free()
		_preview = null
	if _preview_camera != null:
		_preview_camera.free()
		_preview_camera = null
	if camera != null:
		camera.make_current()
	for node in _hidden:
		if is_instance_valid(node):
			node.visible = _hidden[node]
	_hidden.clear()
	get_tree().paused = false
	apply_equipment()


func _categories() -> Array:
	return ["upgrades", "paint", "box"] if active_shop == "bikes" else GearCatalog.TYPES


func _items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in GearCatalog.items(active_shop):
		if item["category"] == _categories()[_category]:
			result.append(item)
	return result


func _change_category(direction: int) -> void:
	_category = posmod(_category + direction, _categories().size())
	_selected = 0
	select_item(0)


func select_item(index: int) -> void:
	var list := _items()
	_selected = posmod(index, list.size())
	var item := list[_selected]
	if item["slot"] != "upgrade":
		_preview_equipped[item["slot"]] = item["id"]
		_dress_preview()
	_status = item["description"]
	_refresh()


func add_selected() -> Dictionary:
	var item := _items()[_selected]
	var result := cart.add(item["id"])
	_status = "Added %s to your cart." % item["name"] if result["ok"] else result["error"]
	_refresh()
	return result


func checkout() -> Dictionary:
	var result := cart.checkout()
	_status = "Bought and equipped. Enjoy your ride!" if result["ok"] else result["error"]
	if result["ok"]:
		_preview_equipped = _state.equipped_cosmetics.duplicate()
		apply_equipment()
		_dress_preview()
	_refresh()
	return result


func _refresh() -> void:
	panel.visible = true
	panel.clear_rows()
	var category: String = _categories()[_category]
	panel.heading.text = "%s\n%s" % [_place(active_shop)["name"], _place(active_shop)["arabic"]]
	panel.detail.text = "‹  %s · Rider Level %d  ›\n%s" % [GearCatalog.TYPE_NAMES[category], _state.level(), _status]
	panel.add_row("‹ Previous type", "W / ↑", false, func(): _change_category(-1))
	panel.add_row("Next type ›", "S / ↓", false, func(): _change_category(1))
	var list := _items()
	for i in list.size():
		var item := list[i]
		var level: int = _state.upgrade_level(item["id"])
		var owned: bool = level >= int(item.get("max", 1)) if item["slot"] == "upgrade" else _state.owned_items.has(item["id"])
		var status := "Owned" if owned else "%d Dh · NEW" % GearCatalog.price(item, level)
		if _state.level() < item["level"]:
			status = "Lv %d · %d Dh" % [item["level"], GearCatalog.price(item, level)]
		elif item.get("collection", false) and _state.owned_collection_rewards.is_empty():
			status = "Complete a cluster"
		var title: String = item["name"]
		if item["id"] == "stamina":
			title += " (%d/10)" % level
		panel.add_row(title, status, i == _selected, select_item.bind(i))
	var quoted := cart.quote()
	var total: int = quoted.get("total", 0)
	var names: Array[String] = []
	for id in cart.entries:
		names.append(GearCatalog.find(id)["name"])
	panel.add_row("E · Add selected", "Cart %d" % cart.entries.size(), false, add_selected)
	panel.add_row("C · Checkout", "%d Dh" % total, false, checkout)
	if not cart.entries.is_empty():
		panel.add_row("Clear cart", "", false, func(): cart.clear(); _refresh())
	panel.add_row("Esc · Leave shop", "", false, close_shop)
	panel.footer.text = "Cart: %s\nTotal %d Dh · Wallet %d Dh\nA/D try · W/S type · drag to turn\nE cart · C checkout · Esc leave" % [", ".join(names) if not names.is_empty() else "empty", total, _state.money]
	panel.progress.visible = false


func _build_preview() -> void:
	var place := _place(active_shop)
	var transform := _shop_transform(place)
	_preview = Node3D.new()
	_preview.name = "ShopPreview"
	get_parent().add_child(_preview)
	_preview.global_position = transform * (ShopInterior.PREVIEW + Vector3(0, 0.6 if active_shop == "bikes" else 0, 0))
	_preview.global_basis = transform.basis * Basis(Vector3.UP, PI * 0.5 if active_shop == "bikes" else PI)
	if active_shop == "bikes":
		BikeModel.build(_preview)
		_preview.get_node("Rider").free()
	else:
		var rider := RiderLook.make_rider()
		rider.name = "PreviewRider"
		_preview.add_child(rider)
	_dress_preview()
	_preview_camera = Camera3D.new()
	_preview_camera.name = "ShopCamera"
	_preview_camera.fov = 50
	get_parent().add_child(_preview_camera)
	_preview_camera.global_position = transform * Vector3(1.0, 1.9, 3.2)
	_preview_camera.look_at(transform * (ShopInterior.PREVIEW + Vector3(-1.4, 1.0, 0)), Vector3.UP)
	_preview_camera.make_current()


func _dress_preview() -> void:
	if _preview == null:
		return
	if active_shop == "bikes":
		Wardrobe.apply_bike(_preview, _preview_equipped)
	else:
		var rider := _preview.get_node("PreviewRider") as Person
		RiderLook.apply(rider, _state.rider_look)
		Wardrobe.apply(rider, _preview_equipped)


func apply_equipment() -> void:
	if bike != null:
		if bike.has_method("configure_upgrades"):
			bike.configure_upgrades(_state.upgrade_levels)
		var model := bike.get_node_or_null("Model") as Node3D
		if model != null:
			Wardrobe.apply_bike(model, _state.equipped_cosmetics)
			var rider := model.get_node_or_null("Rider")
			if rider is Person:
				RiderLook.apply(rider, _state.rider_look)
	if walker != null:
		var person := walker.get_node_or_null("Model")
		if person is Person:
			RiderLook.apply(person, _state.rider_look)


func _place(id: String) -> Dictionary:
	for place: Dictionary in _places:
		if place["id"] == id:
			return place
	return {}


func _shop_transform(place: Dictionary) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(float(place["facing"]))), place["position"])
