class_name WaiterArms
extends SkeletonModifier3D
## Session 90: the waiter's arms, on top of their walk or idle (it runs after PersonPose):
##   carrying: both hands hold a tray in front of the chest (walking or standing)
##   "wipe":   leaning over a table, the right hand wipes round and round with a cloth
##   "serve":  leaning forward a little, the tray goes down onto the table
## Made by RestaurantWaiter. Spots are in metres on the person (facing -Z, +X is right).

var person: Person
var pose: PersonPose
## What the waiter is doing (RestaurantWaiter.task) and whether they hold the tray.
var task := ""
var carrying := false
## 0 to 1 while putting the tray down ("serve").
var lower := 0.0
var _clock := 0.0


func _process_modification_with_delta(delta: float) -> void:
	if person == null or pose == null:
		return
	_clock += delta
	if task == "wipe":
		pose.turn("Spine", Vector3.RIGHT, deg_to_rad(-24.0))
		var t := _clock * 4.5
		var hand := Vector3(0.12 + sin(t) * 0.17, 0.83, -0.62 + cos(t) * 0.08)
		pose.reach("RightArm", "RightForeArm", "RightHand", hand, Vector3(0.5, -0.6, 0.6))
		pose.reach("LeftArm", "LeftForeArm", "LeftHand", Vector3(-0.26, 0.83, -0.5), Vector3(-0.5, -0.6, 0.6))
	elif carrying:
		if lower > 0.0:
			pose.turn("Spine", Vector3.RIGHT, deg_to_rad(-16.0 * lower))
		var y := lerpf(GameConfig.WAITER_TRAY_HEIGHT, 0.86, lower)
		var z := lerpf(-0.36, -0.55, lower)
		pose.reach("LeftArm", "LeftForeArm", "LeftHand", Vector3(-0.2, y - 0.03, z), Vector3(-0.6, -1.0, 0.4))
		pose.reach("RightArm", "RightForeArm", "RightHand", Vector3(0.2, y - 0.03, z), Vector3(0.6, -1.0, 0.4))
