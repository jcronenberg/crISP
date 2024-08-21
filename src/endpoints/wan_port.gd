class_name WanPort
extends PortNode

func get_real_parent():
	return self

func _input_event(_viewport, _event, _shape_idx) -> void:
	pass

# Nothing to do here
func disconnect_port() -> void:
	pass


func set_connected_cable(_value: CableNode) -> void:
	pass


func set_is_port_connected(_value: bool) -> void:
	pass
