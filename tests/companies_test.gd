extends SceneTree
## Session 88: the three delivery companies. Their list and logos, the three perks, switching
## company in the phone (50 Dh, keeps stars and level), old saves becoming Snackaroo, and the
## logo on the delivery box.
##   Godot --path . --headless -s tests/companies_test.gd

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.save_path = "user://companies_test_save.json"
	gs.new_game()
	var ids: Array = Companies.all().map(func(c: Dictionary) -> String: return c["id"])
	_check(ids == ["snackaroo", "zoomaroo", "deliverooz"], "three companies, Snackaroo first: %s" % [ids])
	for entry: Dictionary in Companies.all():
		_check(Companies.logo(entry) != null and load(entry["mark"]) != null, "%s has a logo and a word mark" % entry["name"])
		_check(entry["arabic"] != "" and entry["perk"] != "", "%s has an Arabic name and a perk" % entry["name"])
	_check(Companies.current()["id"] == "snackaroo", "a new game rides for Snackaroo")
	# The perks.
	_check(Companies.tip_with_perk(10, "snackaroo") == 11 and Companies.tip_with_perk(10, "zoomaroo") == 10
			and Companies.tip_with_perk(0, "snackaroo") == 0, "Snackaroo: tips 10% bigger")
	_check(is_equal_approx(Companies.wait_share("zoomaroo"), 1.2) and is_equal_approx(Companies.wait_share("snackaroo"), 1.0),
			"Zoomaroo: customers wait 20% longer")
	_check(is_equal_approx(Companies.damage_share("deliverooz"), 0.75) and is_equal_approx(Companies.damage_share("zoomaroo"), 1.0),
			"Deliverooz: 25% less food damage")
	# Hiring with a company, and switching.
	gs.hire("Lina", "Oman", 1, "zoomaroo")
	_check(gs.company == "zoomaroo" and Companies.current()["name"] == "Zoomaroo", "the application's choice is saved")
	gs.money = 40
	_check(not gs.switch_company("deliverooz") and gs.company == "zoomaroo", "can't switch without 50 Dh")
	gs.money = 120
	gs.xp = 300
	var heard := [""]
	gs.company_changed.connect(func(id: String): heard[0] = id)
	_check(gs.switch_company("deliverooz") and gs.company == "deliverooz" and gs.money == 70 and gs.xp == 300
			and heard[0] == "deliverooz", "switching costs 50 Dh and keeps your XP")
	_check(not gs.switch_company("deliverooz"), "switching to the company you're with does nothing")
	# Save and load keep it; an old save without a company is Snackaroo.
	gs.save_game()
	gs.company = "snackaroo"
	gs.load_game()
	_check(gs.company == "deliverooz", "the company is saved and loaded")
	var old := FileAccess.open(gs.save_path, FileAccess.WRITE)
	old.store_string(JSON.stringify({"rider_name": "Old", "hired": true, "money": 5}))
	old.close()
	gs.load_game()
	_check(gs.company == "snackaroo", "an old save (no company) rides for Snackaroo")
	# The box carries the logo and the colour.
	gs.company = "zoomaroo"
	var model := Node3D.new()
	root.add_child(model)
	BikeModel.build(model)
	var box := model.get_node("DeliveryBox") as MeshInstance3D
	var sticker := box.get_node_or_null("BoxLogo0") as Sprite3D
	_check(sticker != null and sticker.texture == Companies.logo(Companies.find("zoomaroo")), "the Zoomaroo logo is on the box")
	_check((box.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Companies.find("zoomaroo")["colour"]), "the box is Zoomaroo green")
	model.free()
	gs.new_game()
	SaveGame.delete(gs.save_path)
	print("RESULT: " + ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		_failed = true
