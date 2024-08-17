class_name Simulation
extends Node2D

const cable_creator_scene = preload("res://src/cables/cable_creator.tscn")
const switch_scene = preload("res://src/endpoints/switch_node.tscn")
const house_scene = preload("res://src/endpoints/house_node.tscn")

var game_ui: GameUI # The game's UI so we can update things

var _network_sim: NetworkSim = NetworkSim.new()

func _ready() -> void:
	_network_sim.add_wan(%WANPort)
	_network_sim.connect("houses_allocated", _on_network_sim_houses_allocated)


func _physics_process(_delta: float) -> void:
	_network_sim.sim_step()


func request_cable_creation(request_port: PortNode) -> void:
	var cable_creator: CableCreator = cable_creator_scene.instantiate()
	add_child(cable_creator)
	cable_creator.init(request_port)


func add_cable_to_sim(cable: CableNode) -> void:
	_network_sim.add_cable(cable)


func add_cable(cable: CableNode) -> void:
	%Cables.add_child(cable)


func delete_cable(cable: CableNode) -> void:
	cable.port1.disconnect_port()
	cable.port2.disconnect_port()
	cable.queue_free()


func add_endpoint(endpoint: EndpointNode) -> void:
	_network_sim.add_endpoint(endpoint)


func create_switch() -> void:
	%Switches.add_child(switch_scene.instantiate())


func create_house() -> void:
	%Houses.add_child(house_scene.instantiate())


func _on_network_sim_houses_allocated(allocated: bool) -> void:
	if allocated:
		game_ui.hide_warning()
	else:
		game_ui.display_warning("Warning")
