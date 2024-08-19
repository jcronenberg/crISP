class_name CableNode
extends Line2D

var port1: PortNode = null
var port2: PortNode = null
var cable_type: Global.CableTypes
var max_bandwidth: int = 1000
var cur_bandwidth: int = 0
@onready var cable_gradient = load("res://resources/cable_gradient.tres")

func _ready():
	cable_type = Global.selected_cable_type
	if cable_type == Global.CableTypes.COPPER:
		texture = null
		max_bandwidth = 250

func update_cur_bandwidth(bandwidth: int):
	cur_bandwidth = bandwidth
	default_color = cable_gradient.sample(float(cur_bandwidth) / max_bandwidth)