extends Node2D

var is_port_connected := false
## kind of an ugly hack to not register the click if it was connected to another port
var just_connected := false

func set_is_port_connected(state):
	is_port_connected = state
	if state:
		for child in get_children():
			if not child.connected_cable:
				child.use_parent_material = false
	else:
		for child in get_children():
			child.use_parent_material = true
