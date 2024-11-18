class_name HouseNode
extends EndpointNode

var placed := false


## Colors the house either red (state: true) or black (state: false)
func set_allocated_state(state: bool) -> void:
	if state:
		material.set_shader_parameter("color", Color(0, 1, 0)) # green
	else:
		material.set_shader_parameter("color", Color(1, 0, 0)) # red


func _process(_delta: float) -> void:
	if not placed:
		global_position = get_global_mouse_position()
		var place_pos: Vector2 = get_global_mouse_position()
		if Input.is_action_pressed("SnapToGrid"):
			place_pos = place_pos.snapped(Vector2i(20, 20))
		global_position = place_pos


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Use"):
		placed = true
		Global.current_simulation.add_endpoint(self)
		set_process(false)
		set_process_input(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Back") or event.is_action_pressed("Cancel"):
		queue_free()
