class_name NetworkSim
## TODO
## When a house couldn't get a connection it still up to the point where the allocation failed allocated
## bandwidth until that cable. So e.g. if path is [5, 2, 0] and 5 is successful but 2 not then 5 would still
## get allocated 50. Not a trivial change because theoretically we would need to go back and change already
## allocated bandwidth. However I don't think this is a priority as the plan currently is to start a fail
## countdown when a house isn't connected anyway, so this enhancement would only really help in identifying
## issues in the network a bit better.
## (does this really ever matter? I think actually not because it still goes through all the houses one by one
## and tries to connect for every house, so they actually shouldn't cannibalize because if there is a path
## it will get allocated, so it should always connect as many houses as possible, because we go through the
## houses one by one. It should only matter if we somehow go through houses in parallel, but I don't think
## this will ever be necessary and I think we would run into many other race conditions anyway then)
##
## Maybe don't make this a node and instead control the simulation steps from the outside.

signal houses_allocated(allocated: bool)

var endpoints: Array[Endpoint] = []
var cables: Array[Cable] = []
var houses: Array[House] = []
var houses_allocated_state: bool = true # Used to detect changes and then emit houses_allocated
var id_counter: int = 1 # Start at 1 because 0 is WAN
var path_calculator: NetworkAStar = NetworkAStar.new()


## Runs a single step of the simulation
func sim_step() -> void:
	reset_bandwidth_state()
	allocate_houses()


## Add the wan port
func add_wan(wan_node: WanPort) -> void:
	# Add WANPort as first endpoint
	var wan: Endpoint = WanEndpoint.new()
	wan.node_ref = wan_node
	endpoints.append(wan)
	path_calculator.add_point(0, Vector2(0, 0))


func add_endpoint(endpoint: EndpointNode) -> void:
	var new_endpoint: Endpoint
	if endpoint is SwitchNode:
		new_endpoint = Switch.new()
	elif endpoint is HouseNode:
		new_endpoint = House.new()
		houses.append(new_endpoint)

	new_endpoint.sim_id = id_counter
	new_endpoint.node_ref = endpoint
	id_counter += 1
	endpoints.append(new_endpoint)
	# Position shouldn't matter because of our own heuristics in NetworkAStar
	path_calculator.add_point(new_endpoint.sim_id, Vector2(1, 1))


func add_cable(cable: CableNode) -> void:
	var new_cable: Cable
	match cable.cable_type:
		Global.CableTypes.COPPER:
			new_cable = CopperCable.new()
		Global.CableTypes.FIBER:
			new_cable = FiberCable.new()
		_:
			push_error("Invalid cable type")
			return

	new_cable.node_ref = cable
	new_cable.endpoint1_id = _find_endpoint_id_by_node(cable.port1.get_real_parent())
	new_cable.endpoint2_id = _find_endpoint_id_by_node(cable.port2.get_real_parent())
	endpoints[new_cable.endpoint1_id].add_cable(new_cable)
	endpoints[new_cable.endpoint2_id].add_cable(new_cable)
	cables.append(new_cable)


func connect_cable(cable: Cable) -> void:
	# If cables connect to the same node it would throw an error
	# It's useless anyway and shouldn't have any effect if we just
	# don't add it to path_calculator
	if cable.endpoint1_id == cable.endpoint2_id:
		return
	path_calculator.connect_points(cable.endpoint1_id, cable.endpoint2_id)


# TODO how to not allocate for any cable if max can't be allocated
func allocate_house_bandwidth(house: House) -> bool:
	while house.connected_bandwidth < house.bandwidth:
		var path: PackedInt64Array = path_calculator.get_id_path(house.sim_id, 0)
		if path.size() == 0:
			return false
		var cable_path: Array[Cable] = get_cables_for_path(path)
		if cable_path.size() == 0:
			continue

		var possible_bandwidth: int = _get_possible_bandwidth_for_path(cable_path)
		var to_allocate_bandwidth: int = house.bandwidth - house.connected_bandwidth
		if to_allocate_bandwidth > possible_bandwidth:
			to_allocate_bandwidth = possible_bandwidth

		for cable in cable_path:
			cable.add_bandwidth(to_allocate_bandwidth)

		house.connected_bandwidth += to_allocate_bandwidth

	return true


func get_cables_for_path(path: PackedInt64Array) -> Array[Cable]:
	var cables_array: Array[Cable] = []
	for i in path.size() - 1:
		var found_free_cable: bool = false
		for cable in endpoints[path[i]].connected_cables:
			# if not found_free_cable and cable.endpoint1_id == path[i + 1] or cable.endpoint2_id == path[i + 1]:
			if cable.endpoint1_id == path[i + 1] or cable.endpoint2_id == path[i + 1]:
				if cable.get_free_bandwidth() <= 0:
					continue
				cables_array.append(cable)
				found_free_cable = true
				break

		if not found_free_cable:
			path_calculator.disconnect_points(path[i], path[i + 1])
			return []

	return cables_array


func delete_cable(cable_node: CableNode) -> void:
	for cable in cables:
		if cable.node_ref == cable_node:
			endpoints[cable.endpoint1_id].remove_cable(cable)
			endpoints[cable.endpoint2_id].remove_cable(cable)
			cables.erase(cable)


func reset_bandwidth_state() -> void:
	for cable in cables:
		cable.cur_bandwidth = 0
		connect_cable(cable)
	for house in houses:
		house.connected_bandwidth = 0


func allocate_houses() -> void:
	var allocation_successful: bool = true
	for house in houses:
		if not allocate_house_bandwidth(house):
			house.set_allocated(false)
			allocation_successful = false
		else:
			house.set_allocated(true)

	if allocation_successful and not houses_allocated_state:
		houses_allocated_state = true
		# Call to main_thread
		emit_signal("houses_allocated", true)
	elif not allocation_successful and houses_allocated_state:
		houses_allocated_state = false
		# Call to main_thread
		emit_signal("houses_allocated", false)


func _get_possible_bandwidth_for_path(path: Array[Cable]) -> int:
	# Double get_free_bandwidth for first node, but everything else is annoying
	# and I'm not sure what is actually more efficient, but may be more optimizable
	var possible_bandwidth: int = path[0].get_free_bandwidth()
	for cable in path:
		var free_bandwidth: int = cable.get_free_bandwidth()

		if possible_bandwidth > free_bandwidth:
			possible_bandwidth = free_bandwidth
	return possible_bandwidth


func _find_endpoint_id_by_node(node: Node2D) -> int:
	for endpoint in endpoints:
		if endpoint.node_ref == node:
			return endpoint.sim_id

	return -1


## A simple fewest hops pathfinder
##
## Simply replaces all the path finding cost heuristic calculations of [AStar2D]
## to always return 0 thus it basically ignores the coordinates and always
## calculates fewest hops which is exactly what we want for a simple network.
class NetworkAStar extends AStar2D:

	func _compute_cost(_from_id: int, _to_id: int) -> float:
		return 0


	func _estimate_cost(_from_id: int, _to_id: int) -> float:
		return 0


class Endpoint:
	var node_ref: Node2D
	var connected_cables: Array[Cable] = []
	var sim_id: int = -1


	func add_cable(cable: Cable) -> void:
		connected_cables.append(cable)


	func remove_cable(cable: Cable) -> void:
		connected_cables.erase(cable)


class WanEndpoint extends Endpoint:

	func _init():
		sim_id = 0


	func add_cable(cable: Cable) -> void:
		connected_cables.append(cable)


class Switch extends Endpoint:
	pass


class House extends Endpoint:
	var bandwidth: int = 100 # hardcoded for now
	var connected_bandwidth: int = 0
	var _allocated: bool:
		set = set_allocated


	# Return true if main_thread was called
	func set_allocated(value: bool) -> void:
		if _allocated == value:
			return

		_allocated = value
		# Call to main_thread
		node_ref.set_allocated_state(value)


class Cable:
	var node_ref: CableNode
	var endpoint1_id: int
	var endpoint2_id: int
	var max_bandwidth: int:
		set = set_max_bandwidth
	var cur_bandwidth: int:
		set = set_cur_bandwidth


	func set_max_bandwidth(value: int) -> void:
		max_bandwidth = value


	func set_cur_bandwidth(value: int) -> void:
		if cur_bandwidth == value:
			return
		cur_bandwidth = value
		# Call to main_thread
		node_ref.update_cur_bandwidth(cur_bandwidth)


	## Returns false if [param value] can't be allocated, nothing will be added in that scenario.
	func add_bandwidth(value: int) -> bool:
		if cur_bandwidth + value > max_bandwidth:
			return false

		cur_bandwidth += value
		return true


	func get_free_bandwidth() -> int:
		return max_bandwidth - cur_bandwidth


class CopperCable extends Cable:

	func _init():
		max_bandwidth = 250


class FiberCable extends Cable:

	func _init():
		max_bandwidth = 1000
