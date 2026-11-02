class_name Order
extends RefCounted
## One food order: where to pick it up, what it is, where to take it and what it pays.
## Orders are made by the DeliveryManager and kept in GameState.

var restaurant_id := ""    # matches an "id" in data/test_area_places.gd
var restaurant_name := ""  # shown on the phone, e.g. "Boba Oasis"
var food := ""             # "pizza", "ice cream" or "bubble tea"
var villa_number := 0      # the house number to deliver to
var pay := 0               # Dh you get for delivering it
var note := ""             # a short note from the customer, usually empty
var boring := false        # a boring order (you skipped too many): lowest pay, no tip


## A one-line summary, handy for printing while testing.
func describe() -> String:
	return "%s from %s to villa %d, %d Dh" % [food, restaurant_name, villa_number, pay]
