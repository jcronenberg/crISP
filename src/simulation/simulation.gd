class_name Simulation
extends Node2D

const cable_node_scene = preload("res://src/cables/cable_node.tscn")
const switch_scene = preload("res://src/endpoints/switch_node.tscn")
const house_scene = preload("res://src/endpoints/house_node.tscn")

var game_ui: GameUI # The game's UI so we can update things

var sim_change_happened: bool = true # Used to indicate that a change happened
# and we need to simulate

var _network_sim: NetworkSim = NetworkSim.new()
# var _network_sim_worker_thread: Thread = Thread.new()

func _ready() -> void:
	_network_sim.add_wan(%WANPort)
	_network_sim.connect("houses_allocated", _on_network_sim_houses_allocated)


func _physics_process(_delta: float) -> void:
	# if not _network_sim_worker_thread.is_alive():
	# 	if _network_sim_worker_thread.is_started():
	# 		_network_sim_worker_thread.wait_to_finish()
	# 	_network_sim_worker_thread.start(_network_sim.sim_step)
	if sim_change_happened:
		_network_sim.sim_step()
		sim_change_happened = false


func request_cable_creation(request_port: PortNode) -> void:
	var new_cable: CableNode = cable_node_scene.instantiate()
	new_cable.port1 = request_port
	%Cables.add_child(new_cable)


func add_cable_to_sim(cable: CableNode) -> void:
	sim_change_happened = true

	_network_sim.add_cable(cable)


func add_cable(cable: CableNode) -> void:
	%Cables.add_child(cable)


func delete_cable(cable: CableNode) -> void:
	sim_change_happened = true

	cable.port1.disconnect_port()
	cable.port2.disconnect_port()
	_network_sim.delete_cable(cable)
	cable.queue_free()


func add_endpoint(endpoint: EndpointNode) -> void:
	sim_change_happened = true

	_network_sim.add_endpoint(endpoint)


func create_switch() -> void:
	%Switches.add_child(switch_scene.instantiate())


func create_house() -> void:
	%Houses.add_child(house_scene.instantiate())


func create_placed_house_at(pos: Vector2i) -> HouseNode:
	sim_change_happened = true

	var new_house: HouseNode = house_scene.instantiate()
	new_house.global_position = pos
	add_endpoint(new_house)
	%Houses.add_child(new_house)
	new_house.placed = true
	new_house.set_process(false)
	new_house.set_process_input(false)
	return new_house


func _on_network_sim_houses_allocated(allocated: bool) -> void:
	if allocated:
		game_ui.hide_warning()
	else:
		game_ui.display_warning("Warning")
