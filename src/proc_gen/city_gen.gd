class_name CityGen
extends Node2D

@export var grid_size: Vector2i = Vector2i(32, 32)
@export var cell_size: Vector2i = Vector2i(40, 40)
@export var grid_cell_size: Vector2i = Vector2i(3, 3)
@export var road_thickness: int = 20

enum GridCellType {
	PARK,
	HOUSING,
	EMPTY,
}

var _grid: Array[Array] = []
var _poly: Polygon2D = Polygon2D.new()

var _generate_cell_timer: float = 30.0
var _generated_cells: int = 0


func _init() -> void:
	_poly.polygon = [Vector2(0, 0), Vector2(cell_size.x * grid_cell_size.x, 0), Vector2(cell_size.x * grid_cell_size.x, cell_size.y * grid_cell_size.y), Vector2(0, cell_size.y * grid_cell_size.y)]
	_poly.color = Color(0, 255, 0)

	# setup _grid
	for x in grid_size.x:
		var x_array: Array[GridCell] = []
		x_array.resize(grid_size.y)
		_grid.append(x_array)


func _ready() -> void:
	# generate_grid()
	_generate_grid_cell_at(0, 0)
	_generated_cells += 1
	pass


func _physics_process(delta: float) -> void:
	_generate_cell_timer += delta
	if _generate_cell_timer >= 30.0 and _generated_cells < grid_size.x * grid_size.y:
		while(not _generate_grid_cell_at(randi() % grid_size.x - grid_size.x / 2, randi() % grid_size.y - grid_size.x / 2)): pass
		_generated_cells += 1
		_generate_cell_timer = 0.0


func generate_grid() -> void:
	for x in range(-grid_size.x / 2, grid_size.x / 2):
		for y in range(-grid_size.y / 2, grid_size.y / 2):
			_generate_grid_cell_at(x, y)


func _generate_grid_cell_at(x: int, y: int) -> bool:
	if _grid[x][y] is GridCell:
		return false

	_grid[x][y] = _generate_grid_cell(GridCellType.EMPTY, cell_size * grid_cell_size * Vector2i(x, y) + Vector2i(x, y) * road_thickness)
	if x == 0 and y == 0:
		_grid[x][y] = _generate_grid_cell(GridCellType.EMPTY, cell_size * grid_cell_size * Vector2i(x, y) + Vector2i(x, y) * road_thickness)
	else:
		_grid[x][y] = _generate_grid_cell(GridCellType.values().filter(
				func(type: GridCellType): return not type in [GridCellType.EMPTY]
			).pick_random(),
			cell_size * grid_cell_size * Vector2i(x, y) + Vector2i(x, y) * road_thickness)

	return true


func _generate_grid_cell(type: GridCellType, cell_center: Vector2i) -> GridCell:
	var cells: Array[Array] = []
	if type == GridCellType.PARK:
		var park_node: Polygon2D = _poly.duplicate()
		park_node.global_position = cell_center - cell_size / 2
		%Parks.add_child(park_node)
		cells.append([park_node])
	else:
		cells.resize(grid_cell_size.x)
		for x in grid_cell_size.x:
			var x_array: Array[Node2D] = []
			x_array.resize(grid_cell_size.y)
			for y in grid_cell_size.y:
				var new_node: Node2D
				if type == GridCellType.HOUSING:
					new_node = Global.get_current_simulation().create_placed_house_at(cell_center + Vector2i(x, y) * cell_size)
				else:
					continue

				x_array[y] = new_node

			cells[x] = x_array

	var grid_cell: GridCell = GridCell.new()
	grid_cell.cells = cells
	grid_cell.type = type
	grid_cell.cell_center = cell_center
	return grid_cell


class GridCell:
	var cells: Array[Array] = []
	var type: GridCellType
	var cell_center: Vector2i
