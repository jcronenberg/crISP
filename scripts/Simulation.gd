extends Node

class_name Simulation

enum CABLE_TYPES {
	COPPER,
	FIBER,
	}
enum MAX_CABLE_BANDWIDTH {
	COPPER = 250,
	FIBER = 1000,
	}

var SWITCH = {
	"type": "switch",
	"connected_nodes": [],
	"cables": [],
	}
var HOUSE = {
	"type": "house",
	"cables": [],
	"cur_bandwidth": 0,
	"max_bandwidth": 0,
	"allocated_bandwidth": false,
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
var houses: Array = []

var path_calculator: AStar2D = AStar2D.new()


func add_switch(switch_node, pos: Vector2):
	var new_switch = SWITCH.duplicate(true)
	path_calculator.add_point(endpoints.size(), pos)
	endpoints.push_back(new_switch)
	endpoint_nodes.push_back(switch_node)


func add_house(house_node, pos: Vector2):
	var new_house = HOUSE.duplicate(true)
	new_house["cur_bandwidth"] = 100
	new_house["max_bandwidth"] = 100
	path_calculator.add_point(endpoints.size(), pos)
	endpoints.push_back(new_house)
	endpoint_nodes.push_back(house_node)
	houses.push_back(new_house)


func add_cable(cable_node):
	var new_cable
	if cables.find(cable_node) == -1:
		new_cable = CABLE.duplicate()
		match cable_node.cable_type:
			"copper":
				new_cable["cable_type"] = CABLE_TYPES.COPPER
			"fiber":
				new_cable["cable_type"] = CABLE_TYPES.FIBER

		cables.push_back(new_cable)
		cable_nodes.push_back(cable_node)
	else:
		new_cable = cable_nodes[cables.find(cable_node)]
		endpoints[new_cable["con1"]]["connected_nodes"].erase(new_cable["con2"])
		endpoints[new_cable["con2"]]["connected_nodes"].erase(new_cable["con1"])

	new_cable["con1"] = endpoint_nodes.find(cable_node.port1.get_real_parent())
	# if con2 is WANPort, Note WANPort is always 0 and WANPort never is con1 since it is always the end of a cable
	if endpoint_nodes.find(cable_node.port2) != -1:
		new_cable["con2"] = 0
	else:
		new_cable["con2"] = endpoint_nodes.find(cable_node.port2.get_node("../.."))

	path_calculator.connect_points(new_cable["con1"], new_cable["con2"])
	endpoints[new_cable["con1"]]["cables"].push_back(new_cable)
	endpoints[new_cable["con2"]]["cables"].push_back(new_cable)
	for con in ["con1", "con2"]:
		if endpoints[new_cable[con]]["type"] == "house":
			allocate_house_bandwidth(endpoints[new_cable[con]])
	# if endpoints[new_cable["con2"]]["wan_connections"].size() > 0:
	# 	endpoints[new_cable["con1"]]["wan_connections"].push_back(new_cable["con2"])
	# 	update_wan_connections(new_cable["con1"], true)

	# if endpoints[new_cable["con1"]]["wan_connections"].size() > 0:
	# 	endpoints[new_cable["con2"]]["wan_connections"].push_back(new_cable["con1"])
	# 	update_wan_connections(new_cable["con2"], true)


func allocate_house_bandwidth(house):
	var path = path_calculator.get_id_path(endpoints.find(house), 0)
	for i in path.size() - 1:
		if allocate_bandwidth(path[i], path[i + 1], house["cur_bandwidth"]) == 0:
			house["bandwidth_allocated"] = true
		else:
			print("Over bandwidth limit")


# returns left over bandwidth
func allocate_bandwidth(from_endpoint_idx: int, to_endpoint_idx: int, bandwidth: int) -> int:
	for cable in endpoints[from_endpoint_idx]["cables"]:
		for con in ["con1", "con2"]:
			if cable[con] == to_endpoint_idx:
				var max_bandwidth
				match cable["cable_type"]:
					CABLE_TYPES.COPPER:
						max_bandwidth = MAX_CABLE_BANDWIDTH.COPPER
					CABLE_TYPES.FIBER:
						max_bandwidth = MAX_CABLE_BANDWIDTH.FIBER
				var new_bandwidth = cable["cur_bandwidth"]
				new_bandwidth += bandwidth
				if new_bandwidth > max_bandwidth:
					bandwidth = new_bandwidth - max_bandwidth
					cable["cur_bandwidth"] = max_bandwidth
				else:
					cable["cur_bandwidth"] = new_bandwidth
					return 0

	return bandwidth


func free_bandwidth(from_endpoint_idx: int, to_endpoint_idx: int, bandwidth: int):
	for cable in endpoints[from_endpoint_idx]["cables"]:
		for con in ["con1", "con2"]:
			if cable[con] == to_endpoint_idx:
				var new_bandwidth = cable[con]["cur_bandwidth"]
				new_bandwidth -= bandwidth
				if new_bandwidth < 0:
					bandwidth = abs(new_bandwidth)
					cable[con]["cur_bandwidth"] = 0
				else:
					cable[con]["cur_bandwidth"] = new_bandwidth
					return


func update_wan_connections(idx: int, wan_connected: bool):
	for connected_node_idx in endpoints[idx]["connected_nodes"]:
		if connected_node_idx == idx:
			continue
		if wan_connected and endpoints[connected_node_idx]["wan_connections"].find(idx) == -1:
			endpoints[connected_node_idx]["wan_connections"].push_back(idx)
			update_wan_connections(connected_node_idx, wan_connected)
		elif not wan_connected and endpoints[connected_node_idx]["wan_connections"].find(idx) >= 0:
			endpoints[connected_node_idx]["wan_connections"].erase(idx)
			update_wan_connections(connected_node_idx, wan_connected)


var delta_sum := 0.0
func _physics_process(delta):
	delta_sum += delta
	if delta_sum >= 1.0:
		delta_sum = 0.0
		# print("endpoints: ", endpoints)
		# print("cables: ", cables)
		# for i in endpoints.size():
		# 	print("shortest path for endpoint: ", i)
		# 	print(path_calculator.get_id_path(i, 0))
		# print()


func _ready():
	set_name("Simulation")

	# Add WANPort as first endpoint
	endpoint_nodes.push_back(get_node("/root/Main/WANPort"))
	endpoints.push_back({"type": "wan_port", "connected_nodes": [], "cables": [], "path_pos": Vector2(0, 0)})
	path_calculator.add_point(0, Vector2(0, 0))
