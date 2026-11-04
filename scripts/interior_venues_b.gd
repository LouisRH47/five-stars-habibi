class_name InteriorVenuesB
extends RefCounted
## Session 59: Tok Tok Thai, Sushi You, Mario Bonito and Burgerology inside (Appendix B).
## Until Session 59 they get the plain Session 58 template: counter, kitchen, menu, seats.

static func build(p: InteriorParts) -> void:
	InteriorVenues.counter_line(p, -4.0, 4.0, p.brand, Color(0.9, 0.9, 0.88), 2.8, Vector3(1.0, 0, -3.8))
	InteriorVenues.back_counters(p, -5.6, 4.4)
	InteriorVenues.kitchen_fridge(p, 5.3)
	p.menu_board(Vector3(0, 3.2, -4.84), 4.0, InteriorMenus.MENUS.get(p.id, []))
	InteriorDining.standard(p, 1.0, Color(0.4, 0.3, 0.2), p.brand, "kenney_furniture/chair", "kenney_food/plate")
	InteriorVenues.extras(p, Vector3(5.35, 0, -1.6), [Vector3(-5.45, 0, -1.6)],
			[Vector3(-3.6, 0, 1.2), Vector3(2.6, 0, 1.2), Vector3(-3.6, 0, -0.6), Vector3(2.6, 0, 3.0)], p.brand)
