extends Line2D

var port1 = null
var port2 = null
var type = "copper"

func _ready():
	type = get_node("/root/UiController").selected_cable_type
	if type == "copper":
		texture = null
