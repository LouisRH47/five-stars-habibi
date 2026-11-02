extends Node3D
## Builds the Session 9 moving obstacles when the game starts, from the CATS and
## SCOOTER_KIDS lists in data/palm_grove.gd. Node names: Cat_<n>, ScooterKid_<n>
## (n counts from 0 in list order). The smoke test checks they were all built.

## The map data to build from (set in the scene): data/palm_grove.gd.
@export var data: Script

const CAT_SCRIPT := preload("res://scripts/cat.gd")
const KID_SCRIPT := preload("res://scripts/scooter_kid.gd")

var cats: Array = []
var kids: Array = []


func _ready() -> void:
	if data == null:
		push_error("ObstacleBuilder has no data list set in the scene")
		return
	var map := data.get_script_constant_map()
	cats = map.get("CATS", [])
	kids = map.get("SCOOTER_KIDS", [])
	for i in cats.size():
		var cat := AnimatableBody3D.new()
		cat.set_script(CAT_SCRIPT)
		cat.name = "Cat_%d" % i
		add_child(cat)
		cat.setup(cats[i]["area"], cats[i]["colour"])
	for i in kids.size():
		var kid := AnimatableBody3D.new()
		kid.set_script(KID_SCRIPT)
		kid.name = "ScooterKid_%d" % i
		add_child(kid)
		kid.setup(kids[i]["from"], kids[i]["to"], kids[i]["shirt"])
