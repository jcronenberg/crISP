extends Node2D

var cable_scene = preload("res://scenes/cable.tscn")
var cable = null
var cur_point := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var cable_root = get_node("/root/Main/Cables")
	if not cable:
		cable = cable_scene.instantiate()
		cable_root.add_child(cable)
		cable.global_position = self.global_position
		cable.add_point(Vector2(0, 0))
		cur_point = 1
	else:
		cur_point = cable.get_point_count() - 1

func _input(event):
	if event.is_action_pressed("LClick"):
		# Check if position under cursor is possible endpoint
		var space_rid := get_world_2d().space
		var space_state := PhysicsServer2D.space_get_direct_state(space_rid)
		var query := PhysicsPointQueryParameters2D.new()
		query.collide_with_areas = true
		query.position = get_global_mouse_position()
		query.collide_with_bodies = false
		var nodes = space_state.intersect_point(query)
		#print(nodes) # debug
		for node in nodes:
			if node["collider"].name == "WANPort" or "is_endpoint" in node["collider"] and not node["collider"].get_parent().is_port_connected:
				if node["collider"].name != "WANPort":
					node["collider"].connected_cable = cable
					node["collider"].get_parent().set_is_port_connected(true)
				cable.port2 = node["collider"]
				cable.set_point_position(cur_point, node["collider"].global_position - cable.global_position)
				# Cable setup is finished, add to simulation and free creator
				get_node("/root/Main/Simulation").add_cable(cable)
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
		cable.port1.get_parent().set_is_port_connected(false)
		cable.queue_free()
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_pos = get_global_mouse_position()
	cable.set_point_position(cur_point, (cursor_pos - cable.global_position).snapped(Vector2i(20, 20)))


func init(caller_port):
	cable.port1 = caller_port
	caller_port.connected_cable = cable
