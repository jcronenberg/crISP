class_name PortNode
extends Area2D

const is_endpoint = true
var connected_cable: CableNode = null:
	set = set_connected_cable
var is_port_connected: bool = false:
	set = set_is_port_connected

func get_real_parent():
	push_error("Shouldn't have been called without overwrite")

func _input_event(_viewport, event, _shape_idx) -> void:
	if (
			event.is_action_pressed("LClick")
			and not is_port_connected
			and Global.cursor_mode == Global.CursorModes.CABLE
			):
		Global.get_current_simulation().request_cable_creation(self)
		is_port_connected = true
	elif (
			event.is_action_pressed("LClick")
			and connected_cable
			and Global.cursor_mode == Global.CursorModes.DELETE_CABLE
			):
		Global.get_current_simulation().delete_cable(connected_cable)


func disconnect_port() -> void:
	connected_cable = null
	is_port_connected = false


func set_connected_cable(value: CableNode) -> void:
	connected_cable = value


# Needed so we can override it in WanPort and always set it to true there
func set_is_port_connected(value: bool) -> void:
	is_port_connected = value
