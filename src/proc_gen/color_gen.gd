class_name ColorGen
extends Node2D

@export var enabled: bool:
	set(value):
		enabled = value
		if enabled:
			generate_grid()
		else:
			for polys_1d in _polys:
				for poly in polys_1d as Array[Polygon2D]:
					poly.queue_free()

			_polys = []

@export var noise: NoiseTexture2D:
	set(value):
		noise = value
		generate_grid()

@export var grid_size: Vector2i = Vector2i(128, 128)
@export var cell_size: Vector2i = Vector2i(20, 20)

var _poly: Polygon2D
var _polys: Array[Array] = []


func _init() -> void:
	_poly = Polygon2D.new()
	_poly.polygon = [Vector2(0, 0), Vector2(cell_size.x, 0), Vector2(cell_size.x, cell_size.y), Vector2(0, cell_size.y)]


var sample_points: Array[Vector2] = [Vector2(0, 0), Vector2(200, 200), Vector2(21, 78)]
var samples: Array[float] = [0.0, 0.0, 0.0]
func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	var regen_grid: bool = false
	for i in sample_points.size():
		var sample: float = noise.get_noise().get_noise_2dv(sample_points[i])
		if sample != samples[i]:
			regen_grid = true
			samples[i] = sample

	if regen_grid:
		generate_grid()


## Generate the grid of arrows in the flow field
func generate_grid() -> void:
	if not enabled:
		return

	var gen_grid: bool = _polys.size() == 0
	if gen_grid:
		_polys.resize(grid_size.x)
	for i in grid_size.x:
		var i_array: Array = _polys[i]
		if gen_grid:
			i_array.resize(grid_size.y)
		for j in grid_size.y:
			if gen_grid:
				@warning_ignore("integer_division")
				i_array[j] = _generate_poly_at(Vector2i(i * cell_size.x + cell_size.x / 2, j * cell_size.y + cell_size.y / 2))
			_color_poly_to_noise(i_array[j], Vector2i(i, j))

		if gen_grid:
			_polys[i] = i_array


func _generate_poly_at(pos: Vector2i) -> Polygon2D:
	var new_poly: Polygon2D = _poly.duplicate()
	add_child(new_poly)
	new_poly.global_position = pos
	return new_poly


func _color_poly_to_noise(poly: Polygon2D, pos: Vector2i) -> void:
	var noise_value: float = noise.get_noise().get_noise_2dv(pos)
	poly.color = Color(0, 0, 0) if noise_value < 0.5 else Color(0, 0, 255)
