class_name ProcGen
extends Node

@export var grid_size: Vector2i = Vector2i(32, 32):
	set(value):
		grid_size = value
		_calc_edges()
@export var cell_size: Vector2 = Vector2(40, 40):
	set(value):
		cell_size = value
		_calc_edges()
# @export var grid_cell_size: Vector2i = Vector2i(3, 3)
@export var road_thickness: int = 20
@export var position: Vector2 = Vector2(0, 0)
# @export var buildings: Array[Pseudo3DFake3DBuilding]
@export var noise: FastNoiseLite:
	set(value):
		noise = value
		# noise.changed.connect(generate_grid)
		# if Global.current_simulation:
		# 	generate_grid()
enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT,
	}
const DIRECTION_VECTORS = [
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
	]
@export var direction: Direction = Direction.UP:
	set(value):
		direction = value
		generate_grid()
var _direction_vector: Vector2:
	get():
		return DIRECTION_VECTORS[direction]
@export var deviation_factor: float:
	set(value):
		deviation_factor = value
@export var point_resolution: int:
	set(value):
		point_resolution = value

enum GridCellType {
	PARK,
	HOUSING,
	EMPTY,
	}

# Values are from -1 to 1, though most seem to be between -0.5 to 0.5.
var grid_weights: Dictionary = {
	GridCellType.HOUSING: 0.3,
	GridCellType.PARK: 1,
	}

var _grid: Array[Array] = []

var _generated_cells: int = 0

@onready var _city: City3D = get_parent()

var _borders: Array[Vector2] = [Vector2(-1024, -1024), Vector2(1024, 1024)]

var _major_streets_vert: Array[Array] = []
var _major_streets_horiz: Array[Array] = []
var _grid_edges: PackedVector2Array
var _min: Vector2
var _max: Vector2


func _init() -> void:
	_calc_edges()


func _calc_edges() -> void:
	var diff: Vector2 = (Vector2(grid_size.x, grid_size.y) * cell_size) / 2
	_grid_edges = [position - diff,
			position - Vector2(diff.x, -diff.y),
			position + diff,
			position + Vector2(diff.x, -diff.y)]
	_min = _grid_edges[0]
	_max = _grid_edges[2]



func _ready() -> void:
	# _city.ready.connect(generate_grid)
	# _draw_line(Vector2(0, 0), Vector2(0, 100), 10)

	generate_grid()
	pass


func generate_grid() -> void:
	if not noise:
		push_error("No noise set")
		return

	_draw_grid_outline()
	# print(_line_through_noise(Vector2(0, _min.y)))
	_draw_multisegment_line(_line_through_noise(Vector2(0, _max.y)))
	return
# Vertical lines
	var cur_start_pos: Vector2 = _borders[0]
	while cur_start_pos.x <= _borders[1].x:
		var to: Vector2 = Vector2(cur_start_pos.x, _borders[1].y)
		_draw_line(cur_start_pos, to, 2)
		_major_streets_vert.append([cur_start_pos, to])
		cur_start_pos.x += randi_range(40, 60)

	# Horizontal lines
	cur_start_pos = _borders[0]
	while cur_start_pos.y <= _borders[1].y:
		var to: Vector2 = Vector2(_borders[1].x, cur_start_pos.y)
		_draw_line(cur_start_pos, to, 2)
		_major_streets_horiz.append([cur_start_pos, to])
		cur_start_pos.y += randi_range(40, 60)

	# return
	# Draw intersection points
	var mult_mesh: MultiMeshInstance3D = $MultiMeshInstance3D
	mult_mesh.multimesh.instance_count = 16384
	var i: int = 0
	for street_vert in _major_streets_vert:
		for street_horiz in _major_streets_horiz:
			# print(street_vert[0], street_vert[1], street_horiz[0], street_horiz[1])
			var intersection: Variant = Geometry2D.segment_intersects_segment(street_vert[0], street_vert[1], street_horiz[0], street_horiz[1])
			if intersection:
				# print(intersection)
				mult_mesh.multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(intersection.x, 0.5, intersection.y)))
				i += 1


func _draw_multisegment_line(points: PackedVector2Array) -> void:
	var previous_vertices: PackedVector2Array
	for i in points.size() - 1:
		var vertices: PackedVector2Array = _line_vertices(points[i], points[i + 1], 2)
		_draw_line_from_vertices(vertices, Color.YELLOW)
		# if previous_vertices:
		# 	_draw_line_from_vertices([previous_vertices[2], previous_vertices[1], vertices[0], vertices[3]], Color.RED)
		# 	for point: Vector2 in [vertices[2]]:
		# 		add_child(_flat_3d_circle_mesh(point, 0.5))

		previous_vertices = vertices
		# _draw_line(points[i], points[i + 1], 2)
		add_child(_flat_3d_circle_mesh(points[i], 1))
		# _draw_line(points[i], points[i + 1], 2)



func _line_through_noise(from: Vector2) -> PackedVector2Array:
	var current_point: Vector2 = from
	var ret: PackedVector2Array = [from]
	current_point += _direction_vector.rotated(deg_to_rad(noise.get_noise_2dv(current_point) * 45)) * point_resolution
	print(current_point)
	current_point = current_point.clamp(_min, _max)
	print(current_point)
	ret.append(current_point)
	while (current_point.x > _min.x and current_point.x < _max.x and
			current_point.y > _min.y and current_point.y < _max.y):
		current_point += _direction_vector.rotated(deg_to_rad(noise.get_noise_2dv(current_point) * 45)) * point_resolution
		current_point = current_point.clamp(_min, _max)
		ret.append(current_point)
	# while current_point.x < _gri
	# var distance_vec: Vector2 = grid_size
	# var diff: Vector2 = 
	print(ret)
	return ret


func _draw_grid_outline() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	for i in _grid_edges.size() - 1:
		_draw_line(_grid_edges[i], _grid_edges[i + 1], 5)

	_draw_line(_grid_edges[_grid_edges.size() - 1], _grid_edges[0], 5)


func _draw_line(from: Vector2, to: Vector2, width: float) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW

	var vertices: PackedVector2Array = _line_vertices(from, to, width)

	var mesh: MeshInstance3D = _flat_3d_mesh_from_2d_outlines(vertices)
	mesh.material_override = material

	add_child(mesh)


func _draw_line_from_vertices(vertices: PackedVector2Array, color: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	var mesh: MeshInstance3D = _flat_3d_mesh_from_2d_outlines(vertices)
	mesh.material_override = material
	add_child(mesh)


func _line_vertices(from: Vector2, to: Vector2, width: float) -> PackedVector2Array:
	var diff: Vector2 = to - from
	var normal: Vector2 = diff.rotated(TAU/4).normalized()
	var offset: Vector2 = normal * width * 0.5
	return [from + offset, to + offset, to - offset, from - offset]


func _flat_3d_circle_mesh(pos: Vector2, radius: float) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.height = 0
	sphere.radius = radius
	mesh_instance.mesh = sphere
	mesh_instance.position = Vector3(pos.x, -0.1, pos.y)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	mesh_instance.material_override = material
	return mesh_instance


func _flat_3d_mesh_from_2d_outlines(points: PackedVector2Array) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = flat_3d_mesh_from_2d_outlines(points)
	return mesh_instance


static func flat_3d_mesh_from_2d_outlines(points: PackedVector2Array) -> ArrayMesh:
	# Convert the 2d outline into all required triangles to construct a 2d polygon.
	var triangulated_points: PackedInt32Array = Geometry2D.triangulate_polygon(points)
	if triangulated_points.size() == 0:
		print("Failed to triangulate")
		return null

	var triangle_points: PackedVector3Array = []
	# Store all the triangles with a height of 0.
	for point in triangulated_points:
		triangle_points.append(Vector3(points[point].x, 0, points[point].y))

	# Convert the triangles to a mesh via SurfaceTool.
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle_point in triangle_points:
		st.add_vertex(triangle_point)

	# Create mesh and return it.
	return st.commit()
