class_name WanPort
extends PortNode

func get_real_parent() -> Node2D:
	return self

func _on_input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	pass

# Nothing to do here
func disconnect_port() -> void:
	pass


func set_connected_cable(_value: CableNode) -> void:
	pass


func get_is_port_connected() -> bool:
	return false
