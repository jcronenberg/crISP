class_name PortNode
extends Area2D

const is_endpoint = true
var connected_cable: CableNode = null:
	set = set_connected_cable
var is_port_connected: bool:
	get = get_is_port_connected


func _ready() -> void:
	connect("input_event", _on_input_event)


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if (
			event.is_action_pressed("Use")
			and not is_port_connected
			and Global.cursor_mode == Global.CursorModes.CABLE
			):
		Global.current_simulation.request_cable_creation(self)
		viewport.set_input_as_handled()


func _exit_tree() -> void:
	if connected_cable:
		connected_cable.queue_free()


func get_real_parent() -> Node2D:
	push_error("Shouldn't have been called without overwrite")
	return null


func set_connected_cable(value: CableNode) -> void:
	connected_cable = value


func get_is_port_connected() -> bool:
	return true if connected_cable else false
