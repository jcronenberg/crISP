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
