## The three made-up food delivery companies you can ride for (Session 88).
## Each has a brand colour, a darker shade for text, an Arabic name, a perk and a logo.
## The logos are drawn by tools/logos/make_logos.gd, which also reads the colours and
## names from this list. Change a colour here, re-run that tool, and the logo follows.

const DEFAULT := "snackaroo"

const COMPANIES := [
	{
		"id": "snackaroo",
		"name": "Snackaroo",
		"arabic": "سناكارو",
		"colour": Color("#f28c28"),
		"dark": Color("#a8520c"),
		"perk": "+10% tips",
		"perk_long": "Customers tip 10% more",
		"logo": "res://assets/logos/snackaroo_256.png",
		"mark": "res://assets/logos/snackaroo_mark_256.png",
	},
	{
		"id": "zoomaroo",
		"name": "Zoomaroo",
		"arabic": "زوماروو",
		"colour": Color("#2fa84f"),
		"dark": Color("#1b7034"),
		"perk": "+20% wait time",
		"perk_long": "Customers wait 20% longer",
		"logo": "res://assets/logos/zoomaroo_256.png",
		"mark": "res://assets/logos/zoomaroo_mark_256.png",
	},
	{
		"id": "deliverooz",
		"name": "Deliverooz",
		"arabic": "ديليفيروز",
		"colour": Color("#14a3a3"),
		"dark": Color("#0b6666"),
		"perk": "-25% food damage",
		"perk_long": "Bigger box: 25% less food damage",
		"logo": "res://assets/logos/deliverooz_256.png",
		"mark": "res://assets/logos/deliverooz_mark_256.png",
	},
]
