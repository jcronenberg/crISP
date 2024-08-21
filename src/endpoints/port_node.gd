class_name PortNode
extends Area2D

const is_endpoint = true
var connected_cable: CableNode = null:
	set = set_connected_cable
var is_port_connected: bool:
	get = get_is_port_connected

func get_real_parent():
	push_error("Shouldn't have been called without overwrite")

func _input_event(_viewport, event, _shape_idx) -> void:
	if (
			event.is_action_pressed("LClick")
			and not is_port_connected
			and Global.cursor_mode == Global.CursorModes.CABLE
			):
		Global.get_current_simulation().request_cable_creation(self)


func set_connected_cable(value: CableNode) -> void:
	connected_cable = value


func get_is_port_connected() -> bool:
	return true if connected_cable else false
