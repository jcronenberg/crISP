class_name ProcGen
extends Node

@export var grid_size: Vector2i = Vector2i(32, 32)
@export var cell_size: Vector2i = Vector2i(40, 40)
@export var grid_cell_size: Vector2i = Vector2i(3, 3)
@export var road_thickness: int = 20
# @export var buildings: Array[Pseudo3DFake3DBuilding]
@export var noise: FastNoiseLite:
	set(value):
		noise = value
		# if Global.current_simulation:
		# 	generate_grid()

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

var _major_steets_vert: Array[Array] = []
var _major_steets_horiz: Array[Array] = []


func _ready() -> void:
	_city.ready.connect(generate_grid)
	# _draw_line(Vector2(0, 0), Vector2(100, 100), 10)
	pass


func generate_grid() -> void:
	if not noise:
		push_error("No noise set")
		return

	# Vertical lines
	var cur_start_pos: Vector2 = _borders[0]
	while cur_start_pos.x <= _borders[1].x:
		var to: Vector2 = Vector2(cur_start_pos.x, _borders[1].y)
		_draw_line(cur_start_pos, to, 2)
		_major_steets_vert.append([cur_start_pos, to])
		cur_start_pos.x += randi_range(40, 60)

	# Horizontal lines
	cur_start_pos = _borders[0]
	while cur_start_pos.y <= _borders[1].y:
		var to: Vector2 = Vector2(_borders[1].x, cur_start_pos.y)
		_draw_line(cur_start_pos, to, 2)
		_major_steets_horiz.append([cur_start_pos, to])
		cur_start_pos.y += randi_range(40, 60)

	# Draw intersection points
	var mult_mesh: MultiMeshInstance3D = $MultiMeshInstance3D
	mult_mesh.multimesh.instance_count = 16384
	var i: int = 0
	for street_vert in _major_steets_vert:
		for street_horiz in _major_steets_horiz:
			print(street_vert[0], street_vert[1], street_horiz[0], street_horiz[1])
			var intersection: Variant = Geometry2D.segment_intersects_segment(street_vert[0], street_vert[1], street_horiz[0], street_horiz[1])
			if intersection:
				print(intersection)
				mult_mesh.multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(intersection.x, 0.5, intersection.y)))
				i += 1


func _draw_line(from: Vector2, to: Vector2, width: float) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: PackedVector2Array = PackedVector2Array()
	var diff: Vector2 = to - from
	var normal: Vector2 = diff.rotated(TAU/4).normalized()
	var offset: Vector2 = normal * width * 0.5
	vertices = [from + offset, to + offset, to - offset, from - offset]
	var new_vertices: PackedVector3Array = []
	var triangulated: PackedInt32Array = Geometry2D.triangulate_polygon(vertices)
	for point in triangulated:
		new_vertices.append(Vector3(vertices[point].x, 0, vertices[point].y))

	for vertice in new_vertices:
		st.add_vertex(vertice)

	mesh_instance.mesh = st.commit()
	mesh_instance.material_override = material

	add_child(mesh_instance)
