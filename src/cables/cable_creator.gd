class_name CableCreator
extends Node2D

const cable_scene = preload("res://src/cables/cable_node.tscn")
var cable: CableNode = null
var cur_point := 0

func _input(event):
	if event.is_action_pressed("LClick"):
		# Check if position under cursor is possible endpoint
		var space_rid := get_world_2d().space
		var space_state := PhysicsServer2D.space_get_direct_state(space_rid)
		var query := PhysicsPointQueryParameters2D.new()
		query.collide_with_areas = true
		query.position = get_global_mouse_position()
		if Input.is_action_pressed("SnapToGrid"):
			query.position = query.position.snapped(Vector2i(20, 20))
		query.collide_with_bodies = false
		var nodes = space_state.intersect_point(query)
		for node in nodes:
			if node["collider"] is WanPort or node["collider"] is PortNode and not node["collider"].is_port_connected:
				if node["collider"] is not WanPort:
					node["collider"].connected_cable = cable
					node["collider"].is_port_connected = true
				cable.port2 = node["collider"]
				cable.set_point_position(cur_point, node["collider"].global_position - cable.global_position)
				# Cable setup is finished, add to simulation and free creator
				Global.get_current_simulation().add_cable_to_sim(cable)
				queue_free()
				return
			# Invalid because point is a endpoint but not free
			elif "is_endpoint" in node["collider"]:
				return

		cable.add_point(Vector2(0, 0))
		cur_point = cur_point + 1

	if event.is_action_pressed("RClick") and cur_point > 1:
		cable.remove_point(cur_point)
		cur_point = cur_point - 1
	elif event.is_action_pressed("RClick"):
		cable.port1.is_port_connected = false
		cable.queue_free()
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_pos: Vector2 = get_global_mouse_position()
	if Input.is_action_pressed("SnapToGrid"):
		cursor_pos = cursor_pos.snapped(Vector2i(20, 20))
	cable.set_point_position(cur_point, cursor_pos - cable.global_position)


func init(caller_port: PortNode) -> void:
	if not cable:
		cable = cable_scene.instantiate()
		Global.get_current_simulation().add_cable(cable)
		cable.global_position = caller_port.global_position
		cable.add_point(Vector2(0, 0))
		cur_point = 1
	else:
		cur_point = cable.get_point_count() - 1
	cable.port1 = caller_port
	caller_port.connected_cable = cable
