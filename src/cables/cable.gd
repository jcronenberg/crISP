extends Line2D

var port1 = null
var port2 = null
var cable_type := "fiber"
var max_bandwidth := 1000
var cur_bandwidth := 0
@onready var cable_gradient = load("res://resources/cable_gradient.tres")

func _ready():
	cable_type = get_node("/root/UiController").selected_cable_type
	if cable_type == "copper":
		texture = null
		max_bandwidth = 250

func update_cur_bandwidth(bandwidth: int):
	cur_bandwidth = bandwidth
	default_color = cable_gradient.sample(float(cur_bandwidth) / max_bandwidth)
