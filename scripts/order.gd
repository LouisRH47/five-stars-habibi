class_name Order
extends RefCounted
## One food order: where to pick it up, what it is, where to take it and what it pays.
## Orders are made by the DeliveryManager and kept in GameState.

var restaurant_id := ""    # matches an "id" in data/test_area_places.gd
var restaurant_name := ""  # shown on the phone, e.g. "Boba Oasis"
var food := ""             # "pizza", "ice cream" or "bubble tea"
var villa_number := 0      # the villa's id in the data list (Wahat Al Shams: cluster x 100 + house)
var address := ""          # what the phone shows, e.g. "C3 · Villa 7" (or "Villa 7" on the test area)
var pay := 0               # Dh you get for delivering it
var note := ""             # a short note from the customer, usually empty
var leave_at_door := false # nobody comes out: leave the bag on the doorstep (Session 11)
var boring := false        # a boring order (you skipped too many): lowest pay, no tip
# Session 32: special orders, regulars, school and stables orders.
var base_pay := 0          # the pay before the special order's extra (pay - base_pay = the extra)
var special := ""          # "", "rush", "fragile", "neighbour" or "family" (GameConfig.SPECIAL_KINDS)
var regular := ""          # the regular customer's name (e.g. "Auntie Mariam"), or "" for anyone else
var regular_id := ""       # the regular's id in REGULARS (e.g. "mariam")
var who := "resident"      # who comes to the door: resident, teacher, kid, rider or groom
var look := -1             # a regular's own outfit (PeopleLooks.resident), -1 = random
var cluster := ""          # the home's cluster ("C2"), "" for the school, stables and the test area
var lunch := false         # a school order from the lunch rush (11:30 to 12:30)
var neighbour_done := false  # a neighbour order already sent on to the house next door


## A one-line summary, handy for printing while testing.
func describe() -> String:
	var extra := ""
	if special != "":
		extra += " [%s]" % special
	if regular != "":
		extra += " [regular: %s]" % regular
	return "%s from %s to %s, %d Dh%s" % [food, restaurant_name, address, pay, extra]
