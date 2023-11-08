extends Node

class_name Simulation

enum CABLE_TYPES {
	COPPER,
	FIBER,
	}
enum MAX_CABLE_THROUGHPUT {
	COPPER = 250,
	FIBER = 1000,
	}

var SWITCH = {
	"type": "switch",
	"connected_nodes": [],
	}
var HOUSEHOLD = {
	"type": "household",
	"connected_nodes": [],
	"cur_bandwidth": 0,
	"max_bandwidth": 0,
	}
var CABLE = {
	"type": "cable",
	"cable_type": CABLE_TYPES.COPPER,
	"cur_bandwidth": 0,
	"con1": -1,
	"con2": -1,
	}

# Note the normal and nodes array should be kept in sync to allow a 1 to 1 mapping
var endpoints: Array = []
var endpoint_nodes: Array = []
var cables: Array = []
var cable_nodes: Array = []


func add_switch(switch_node):
	var new_switch = SWITCH.duplicate(true)
	endpoints.push_back(new_switch)
	endpoint_nodes.push_back(switch_node)


func add_cable(cable_node):
	var new_cable
	if cables.find(cable_node) == -1:
		new_cable = CABLE.duplicate()
		match cable_node.cable_type:
			"copper":
				new_cable["type"] = CABLE_TYPES.COPPER
			"fiber":
				new_cable["type"] = CABLE_TYPES.FIBER

		cables.push_back(new_cable)
		cable_nodes.push_back(cable_node)
	else:
		new_cable = cable_nodes[cables.find(cable_node)]
		endpoints[new_cable["con1"]]["connected_nodes"].erase(new_cable["con2"])
		endpoints[new_cable["con2"]]["connected_nodes"].erase(new_cable["con1"])

	new_cable["con1"] = endpoint_nodes.find(cable_node.port1.get_node("../.."))
	# if con2 is WANPort, Note WANPort is always 0 and WANPort never is con1 since it is always the end of a cable
	if endpoint_nodes.find(cable_node.port2) != -1:
		new_cable["con2"] = 0
	else:
		new_cable["con2"] = endpoint_nodes.find(cable_node.port2.get_node("../.."))
	endpoints[new_cable["con1"]]["connected_nodes"].push_back(new_cable["con2"])
	endpoints[new_cable["con2"]]["connected_nodes"].push_back(new_cable["con1"])


var delta_sum := 0.0
func _physics_process(delta):
	delta_sum += delta
	if delta_sum >= 1.0:
		delta_sum = 0.0
		print(endpoint_nodes)
		print(cables)


func _ready():
	set_name("Simulation")

	# Add WANPort as first endpoint
	endpoint_nodes.push_back(get_node("/root/Main/WANPort"))
	endpoints.push_back({"type": "wan_port", "connected_nodes": []})
