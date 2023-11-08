extends Line2D

var port1 = null
var port2 = null
var cable_type = "copper"

func _ready():
	cable_type = get_node("/root/UiController").selected_cable_type
	if cable_type == "copper":
		texture = null
