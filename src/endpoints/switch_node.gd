class_name SwitchNode
extends EndpointNode

## TODO
## Switches shouldn't be possible to overlap

var placed := false

func _process(_delta):
	if not placed:
		var old_position = global_position
		global_position = get_global_mouse_position().snapped(Vector2i(20, 20)) + Vector2(10, 10)
		if old_position - global_position != old_position:
			move_connected_cables(old_position - global_position)


func _input(event):
	if event.is_action_pressed("LClick"):
		placed = true
		get_node("/root/Main/Simulation").add_switch(self, global_position)
		set_process(false)
		set_process_input(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("RClick") or event.is_action_pressed("Cancel"):
		queue_free()


func move_connected_cables(position_diff: Vector2):
	for child in get_children():
		if child.has_method("move_connected_cable"):
			child.move_connected_cable(position_diff)
