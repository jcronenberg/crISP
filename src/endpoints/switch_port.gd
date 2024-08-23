class_name SwitchPort
extends PortNode


func get_real_parent() -> Node2D:
	return get_parent()


func move_connected_cable(position_diff: Vector2, final: bool) -> void:
	if not connected_cable:
		return
	var point_id: int
	if connected_cable.port1 == self:
		point_id = 0
	else:
		point_id = connected_cable.get_point_count() - 1
	connected_cable.cable_set_point_position(point_id, connected_cable.get_point_position(point_id) - position_diff)
	if final:
		connected_cable.set_cable_collision()


func set_connected_cable(value: CableNode) -> void:
	connected_cable = value

	# Reset color if we are no longer connected
	if not is_port_connected:
		material.set_shader_parameter("color", Color(0, 1, 0))


func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	# If the port was clicked to add a cable it should not select the switch
	var pre_port_connected: bool = is_port_connected
	super(viewport, event, shape_idx)
	if event.is_action_pressed("Use") and not pre_port_connected:
		Global.current_simulation.unselect_node(get_parent())
