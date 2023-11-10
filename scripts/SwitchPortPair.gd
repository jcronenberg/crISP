extends Node2D

var is_port_connected := false

func set_is_port_connected(state):
	is_port_connected = state
	if state:
		for child in get_children():
			if not child.connected_cable:
				child.use_parent_material = false
	else:
		for child in get_children():
			child.use_parent_material = true


func move_connected_cable(position_diff: Vector2):
	for child in get_children():
		if not child.connected_cable:
			continue
		var point_id
		if child.connected_cable.port1 == child:
			point_id = 0
		else:
			point_id = child.connected_cable.get_point_count() - 1
		child.connected_cable.set_point_position(point_id, child.connected_cable.get_point_position(point_id) - position_diff)
