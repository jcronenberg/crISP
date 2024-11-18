class_name Simulation
extends Node2D

const cable_node_scene = preload("res://src/cables/cable_node.tscn")
const switch_scene = preload("res://src/endpoints/switch_node.tscn")
const house_scene = preload("res://src/endpoints/house_node.tscn")

var game_ui: GameUI # The game's UI so we can update things

var sim_change_happened: bool = true # Used to indicate that a change happened
# and we need to simulate

var selected_nodes: Array[Node2D]: # The nodes currently selected
	set(value):
		for prev_selected_node in selected_nodes:
			prev_selected_node.highlight(false)
		selected_nodes = value
		game_ui.toggle_delete_cable_button_visibility(selected_nodes.size() > 0)

var _network_sim: NetworkSim = NetworkSim.new()
# var _network_sim_worker_thread: Thread = Thread.new()

func _ready() -> void:
	_setup_new_net_sim()


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
	_network_sim.add_cable(cable)
	sim_change_happened = true


func add_cable(cable: CableNode) -> void:
	%Cables.add_child(cable)


func delete_cable(cable: CableNode) -> void:
	_network_sim.delete_cable(cable)
	cable.queue_free()
	sim_change_happened = true


func add_endpoint(endpoint: EndpointNode) -> void:
	_network_sim.add_endpoint(endpoint)
	sim_change_happened = true


func remove_endpoint(endpoint: EndpointNode) -> void:
	_network_sim.delete_endpoint(endpoint)
	sim_change_happened = true


func create_switch() -> void:
	%Switches.add_child(switch_scene.instantiate())


func create_house() -> void:
	%Houses.add_child(house_scene.instantiate())


func create_placed_house_at(pos: Vector2i) -> HouseNode:
	var new_house: HouseNode = house_scene.instantiate()
	new_house.global_position = pos
	add_endpoint(new_house)
	%Houses.add_child(new_house)
	new_house.placed = true
	new_house.set_process(false)
	new_house.set_process_input(false)

	sim_change_happened = true

	return new_house


## Select a node, if the SelectMultiple action is pressed it gets added to the current selection
func select_node(node: Node2D) -> void:
	if Input.is_action_pressed("SelectMultiple"):
		selected_nodes.append(node)
	else:
		selected_nodes = [node]

	game_ui.toggle_delete_cable_button_visibility(selected_nodes.size() > 0)

	node.highlight(true)


func unselect_node(node: Node2D) -> void:
	if node in selected_nodes:
		selected_nodes.erase(node)
		if is_instance_valid(node):
			node.highlight(false)

	game_ui.toggle_delete_cable_button_visibility(selected_nodes.size() > 0)


func delete_selected_nodes() -> void:
	for selected_node in selected_nodes:
		selected_node.queue_free()

	selected_nodes = []


func reset_all() -> void:
	for child in %Houses.get_children():
		child.queue_free()

	for child in %Cables.get_children():
		child.queue_free()

	for child in %Parks.get_children():
		child.queue_free()

	for child in %Switches.get_children():
		child.queue_free()

	_network_sim = NetworkSim.new()
	_setup_new_net_sim()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Use") and not Input.is_action_pressed("SelectMultiple"):
		var space_rid: RID = get_world_2d().space
		var space_state: PhysicsDirectSpaceState2D = PhysicsServer2D.space_get_direct_state(space_rid)
		var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
		query.collide_with_areas = true
		query.position = get_global_mouse_position()
		if Input.is_action_pressed("SnapToGrid"):
			query.position = query.position.snapped(Vector2i(20, 20))
		query.collide_with_bodies = false
		var nodes: Array[Dictionary] = space_state.intersect_point(query)
		if nodes.size() == 0:
			selected_nodes = []


func _on_network_sim_houses_allocated(allocated: bool) -> void:
	if allocated:
		game_ui.hide_warning()
	else:
		game_ui.display_warning("Warning")


func _setup_new_net_sim() -> void:
	_network_sim.add_wan(%WANPort)
	if not _network_sim.houses_allocated.is_connected(_on_network_sim_houses_allocated):
		_network_sim.houses_allocated.connect(_on_network_sim_houses_allocated)
