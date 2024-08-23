class_name CableNode
extends Line2D

const cable_gradient = preload("res://resources/cable_gradient.tres")

var port1: PortNode = null:
	set(port):
		port1 = port
		port.connected_cable = self
		global_position = port.global_position
		cable_add_point(port.global_position)
var port2: PortNode = null
var cable_type: Global.CableTypes:
	set(value):
		cable_type = value
		if value == Global.CableTypes.COPPER:
			max_bandwidth = 250
			texture = null
		elif value == Global.CableTypes.FIBER:
			max_bandwidth = 1000
var max_bandwidth: int
var cur_bandwidth: int = 0
var being_edited: bool = true:
	set(value):
		being_edited = value
		set_process(value)
		set_process_input(value)


func _ready() -> void:
	cable_type = Global.selected_cable_type


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Use"):
		# Check if position under cursor is possible endpoint
		var space_rid: RID = get_world_2d().space
		var space_state: PhysicsDirectSpaceState2D = PhysicsServer2D.space_get_direct_state(space_rid)
		var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
		query.collide_with_areas = true
		query.position = get_global_mouse_position()
		if Input.is_action_pressed("SnapToGrid"):
			query.position = query.position.snapped(Vector2i(20, 20))
		query.collide_with_bodies = false
		var nodes: Array[Dictionary] = space_state.intersect_point(query)
		for node in nodes:
			if node["collider"] is PortNode and not node["collider"].is_port_connected:
				var collider: PortNode = node["collider"]
				# stop _process, otherwise we run into a race condition
				# where _process also tries to set the last point's position
				being_edited = false

				# Connect to port
				collider.connected_cable = self

				port2 = collider
				cable_set_point_position(points.size() - 1, collider.global_position - global_position)

				# Add collision
				set_cable_collision()

				# Setup is finished, add to simulation
				Global.current_simulation.add_cable_to_sim(self)

				# Set input as handled so we don't select the cable immediately
				get_viewport().set_input_as_handled()
				return
			# Invalid because point is an endpoint but not free
			elif "is_endpoint" in node["collider"]:
				return

		# Add new point, position doesn't matter, it get's set by _process
		cable_add_point(Vector2(0, 0))
	elif event.is_action_pressed("Cancel"):
		queue_free()
	elif event.is_action_pressed("Back") and points.size() > 2:
		cable_remove_point(points.size() - 1)
	elif event.is_action_pressed("Back"):
		queue_free()


func _process(_delta: float) -> void:
	var cursor_pos: Vector2 = get_global_mouse_position()
	if Input.is_action_pressed("SnapToGrid"):
		cursor_pos = cursor_pos.snapped(Vector2i(20, 20))
	cable_set_point_position(points.size() - 1, cursor_pos - global_position)


func _exit_tree() -> void:
	if port1 and is_instance_valid(port1):
		port1.connected_cable = null
	if port2 and is_instance_valid(port2):
		port2.connected_cable = null
	Global.current_simulation.delete_cable(self)
	Global.current_simulation.unselect_node(self)


## Wrapper, that adds the point to both the cable and the outline
func cable_add_point(point: Vector2) -> void:
	add_point(point)
	%Outline.add_point(point)


## Wrapper, that sets a point's position on both the cable and the outline
func cable_set_point_position(point_index: int, point: Vector2) -> void:
	set_point_position(point_index, point)
	%Outline.set_point_position(point_index, point)


## Wrapper, that removes the point from both the cable and the outline
func cable_remove_point(point_index: int) -> void:
	remove_point(point_index)
	%Outline.remove_point(point_index)


func update_cur_bandwidth(bandwidth: int) -> void:
	cur_bandwidth = bandwidth
	var bandwidth_color: Color = cable_gradient.sample(float(cur_bandwidth) / max_bandwidth)
	default_color = bandwidth_color
	for port: PortNode in [port1, port2]:
		if port is SwitchPort:
			port.material.set_shader_parameter("color", bandwidth_color)


func set_cable_collision() -> void:
	# Free existing collision areas
	for child in get_children():
		if child is not Area2D:
			continue
		child.queue_free()

	# Add new collision areas
	var line_collision_area: Area2D = cable_line_collision_area()
	line_collision_area.connect("input_event", _on_line_collision_input_event)
	add_child(line_collision_area)
	var point_collision_area: Area2D = cable_point_collision_area()
	point_collision_area.connect("input_event", _on_point_collision_input_event)
	add_child(point_collision_area)


func cable_line_collision_area() -> Area2D:
	var area: Area2D = Area2D.new()
	for poly in rotated_rectangle_points():
		area.add_child(poly)

	return area


func cable_point_collision_area() -> Area2D:
	var area: Area2D = Area2D.new()
	for point in points:
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = width / 2
		collision_shape.shape = circle
		collision_shape.global_position = point
		area.add_child(collision_shape)

	return area


func rotated_rectangle_points() -> Array[CollisionPolygon2D]:
	var col_polys: Array[CollisionPolygon2D] = []
	for i in points.size() - 1:
		var poly: CollisionPolygon2D = CollisionPolygon2D.new()
		var start: Vector2 = points[i]
		var end: Vector2 = points[i + 1]
		var diff: Vector2 = end - start
		var normal: Vector2 = diff.rotated(TAU/4).normalized()
		var offset: Vector2 = normal * width * 0.5
		poly.polygon = [start + offset, end + offset, end - offset, start - offset]
		col_polys.append(poly)

	return col_polys


func highlight(state: bool) -> void:
	if being_edited or is_queued_for_deletion():
		return
	%Outline.visible = state
	z_index = 1 if state else 0


func _generic_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton or not event.pressed:
		return

	elif event.is_action_pressed("Use"):
		Global.current_simulation.select_node(self)


func _on_line_collision_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	_generic_input(event)
	viewport.set_input_as_handled()


# TODO allow moving of points
func _on_point_collision_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	_generic_input(event)
	viewport.set_input_as_handled()
