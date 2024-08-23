class_name SwitchNode
extends EndpointNode

## TODO
## Switches shouldn't be possible to overlap

var placed: bool = false:
	set(value):
		placed = value
		set_process(not value)
		set_process_input(not value)
		if value:
			move_connected_cables(Vector2.ZERO, true)

func _process(_delta: float) -> void:
	if not placed:
		var old_position: Vector2 = global_position
		var place_pos: Vector2 = get_global_mouse_position()
		if Input.is_action_pressed("SnapToGrid"):
			place_pos = place_pos.snapped(Vector2i(20, 20))
		global_position = place_pos
		if old_position - global_position != old_position:
			move_connected_cables(old_position - global_position)


func _exit_tree() -> void:
	Global.current_simulation.remove_endpoint(self)
	Global.current_simulation.unselect_node(self)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Use") and not placed:
		placed = true
		Global.current_simulation.add_endpoint(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Back") or event.is_action_pressed("Cancel"):
		queue_free()


## [param final] is if the position is final (so the collision of the cables should be updated)
func move_connected_cables(position_diff: Vector2, final: bool = false) -> void:
	for child in get_children():
		if child.has_method("move_connected_cable"):
			child.move_connected_cable(position_diff, final)


func highlight(state: bool) -> void:
	if is_queued_for_deletion():
		return

	%Outline.visible = state
	%SelectedUI.visible = state
	z_index = 1 if state else 0


func _on_switch_body_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("Use"):
		Global.current_simulation.select_node(self)


func _on_delete_button_pressed() -> void:
	queue_free()


func _on_move_button_pressed() -> void:
	placed = false
