class_name SwitchPort
extends PortNode


func get_real_parent() -> Node2D:
	return get_parent()


func move_connected_cable(position_diff: Vector2) -> void:
	if not connected_cable:
		return
	var point_id
	if connected_cable.port1 == self:
		point_id = 0
	else:
		point_id = connected_cable.get_point_count() - 1
	connected_cable.set_point_position(point_id, connected_cable.get_point_position(point_id) - position_diff)
