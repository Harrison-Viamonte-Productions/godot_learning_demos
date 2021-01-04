class_name GridObj
extends Object

const GRID_NULL: int = -1;

var grid: Array = []
var size: Vector2 = Vector2.ZERO
var position: Vector2 = Vector2.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new();

func _init(_size: Vector2):
	rng.randomize()
	size = _size
	clear()

func set_random_seed(var new_seed: int):
	rng.set_seed(new_seed)

func get_random_seed() -> int:
	return rng.get_seed()

func map_to_tilemap(map: TileMap):
	for x in size.x:
		for y in size.y:
			map.set_cell(x + position.x, y+position.y, grid[x][y])

func get_size() -> Rect2:
	return Rect2(position, size)

func set_pos(_pos: Vector2):
	position = _pos

func get_pos() -> Vector2:
	return position

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < size.x and y < size.y

func is_in_bounds_vec(cell: Vector2) -> bool:
	return is_in_bounds(cell.x, cell.y)

func get_cell(x: int, y: int):
	if !is_in_bounds(x, y):
		return -1
	return grid[x][y]

func set_cell(x: int, y: int, val):
	grid[x][y] = val

func get_cellv(vec: Vector2):
	return get_cell(vec.x, vec.y)
	
func set_cellv(vec: Vector2, val):
	grid[vec.x][vec.y] = val

func set_cellsv(cells: Array, value):
	for cell in cells:
		if is_in_bounds_vec(cell):
			set_cellv(cell, value)

func filter_cells_by_val(val) -> Array: # Returns an array of vector2 with all the cells that have some specific value
	var cells: Array = [];
	for x in range(size.x):
		for y in range(size.y):
			if grid[x][y] == val:
				cells.append(Vector2(x, y));
	return cells;

func get_used_cells() -> Array:
	var cells: Array = []
	for x in size.x:
		for y in size.y:
			if grid[x][y] != GRID_NULL:
				cells.append(Vector2(x, y))
	return cells

func get_unused_cells() -> Array:
	return filter_cells_by_val(GRID_NULL)

func get_cells() -> Array:
	var cells: Array = []
	for x in size.x:
		for y in size.y:
			cells.append(Vector2(x, y))
	
	return cells

func get_cells_to_fit_grid(fit_grid, margin: int = 0, allow_id: int = -1) -> Array:  #fit_grid being a GridObj
	var start_pos: Vector2 =  fit_grid.get_size().position

	assert(start_pos.x >= 0 and start_pos.y >= 0)

	var fit_size: Vector2 = fit_grid.get_size().size+Vector2(margin, margin)
	var end_pos: Vector2 = start_pos+fit_size
	var cells: Array
	
	for x in size.x:
		for y in size.y:
			if x >= margin and y >= margin and end_pos.x+x <= size.x and end_pos.y+y <= size.y:
				var can_fit: bool = true
				for i in range(x, end_pos.x+x):  # Check if this whole block it's empty now
					for k in range(y, end_pos.y+y):
						if grid[i][k] != allow_id:
							can_fit = false
							break
				if can_fit:
					cells.append(Vector2(x, y))
	return cells

# Mutable data, I prefer this for performance over creating a local copy of the array
func substract_from_cells(cells: Array, ignore_id: int = GRID_NULL) -> Array:
	var copy_cells: Array = cells.duplicate(true) # To don't modify the parameter directly
	for x in size.x:
		for y in size.y:
			if grid[x][y] == ignore_id:
				continue
			var i: int =  copy_cells.find(Vector2(x+position.x, y+position.y))
			if i != -1:
				copy_cells.remove(i)
	return copy_cells

func merge_with_grid(merge_grid): #merge_grid being a GridObj
	var start_pos: Vector2 =  merge_grid.get_size().position
	var merge_size: Vector2 = merge_grid.get_size().size
	var end_pos: Vector2 = start_pos+merge_size

	assert(start_pos.x >= 0 and start_pos.y >= 0 and end_pos.x <= size.x and end_pos.y <= size.y)
	
	for x in merge_size.x:
		for y in merge_size.y:
			grid[x+start_pos.x][y+start_pos.y] = merge_grid.get_cell(x, y)

func filter_neighbors(pos: Vector2, filter_id: int, bit_mask: int = PCG.ALL_DIR) -> Array: # Return an array with the cells (vector2) of the valid neighbors
	var neighbors: Array = [];
	for c_dir in PCG.DIRS.keys():
		if (PCG.DIRS[c_dir] & bit_mask) and get_cellv(pos+c_dir) == filter_id:
			neighbors.append(pos+c_dir);
	return neighbors;

func clear():
	grid.clear()
	for x in size.x:
		grid.append([])
		for y in size.y:
			grid[x].append(GRID_NULL)

func get_random_cell() -> Vector2:
	return Vector2(rng.randi_range(0, size.x-1), rng.randi_range(0, size.y-1));

func get_random_cell_filter(filter_val) -> Vector2:
	var cells: Array = filter_cells_by_val(filter_val);
	assert( cells.size() > 0 ); # Do we really want an assert here?
	return cells[rng.randi_range(0, cells.size()-1)];

func fill_with_random_vals(vals: Array, percent: float = 1.0):
	percent = clamp(percent, 0.0, 1.0)
	clear()
	var cells: Array = get_unused_cells();
	var to_place: int = int((cells.size()-1)*percent);
	var i: int = 0
	while (i < to_place):
		var cell_index: int = rng.randi_range(0, cells.size()-1)
		set_cellv(cells[cell_index], vals[rng.randi_range(0, vals.size()-1)])
		cells.remove(cell_index)
		i+=1

func replace(old_val: int, new_val: int):
	for x in size.x:
		for y in size.y:
			if grid[x][y] == old_val:
				grid[x][y] = new_val

func get_grid_array() -> Array:
	return grid.duplicate(true)

func set_grid_array(new_grid: Array):
	assert(new_grid.size() > 0)
	grid = new_grid.duplicate(true)
	size = Vector2(grid.size(), grid[0].size())

# split a grid in more pieces, like a 2x2 into a 4x4 while keeping data in a proportional way
func split_by(mult: int, duplicate: bool = true):
	assert(mult > 0)
	var new_grid: Array = []
	var new_size: Vector2 = size*mult
	var step: Vector2 = Vector2(size.x/new_size.x, size.y/new_size.y)
	for x in new_size.x:
		new_grid.append([])
		for y in new_size.y:
			if duplicate:
				new_grid[x].append(grid[int(floor(float(x)*step.x))][int(floor(float(y)*step.y))])
			else:
				if x % mult == 0 and y % mult == 0:
					new_grid[x].append(grid[int(float(x)*step.x)][int(float(y)*step.y)])
				else:
					new_grid[x].append(GRID_NULL)
	
	size = new_size
	grid = new_grid
