class_name Walker
extends Object

# Cardinal bitflags, really useful.
const N: int = 1;
const NE: int = 2;
const E: int = 4;
const SE: int = 8;
const S: int = 16;
const SW: int = 32;
const W: int = 64;
const NW: int = 128;

# Shorthand for getting Neighbors
const ALL_DIR: int = N | NE | E | SE | S | SW | W | NW; # All 8 directions
const DIAG_DIR: int = NE | SE | SW | NW; # Diagonal directions only
const HOR_AND_VER_DIR: int = ALL_DIR - DIAG_DIR; # Horizontal and vertical directions

var cell_dirs: Dictionary = { # The keys are vectors 2D, which is awesome and handy
	Vector2(0, -1): N,
	Vector2(1, -1): NE,
	Vector2(1, 0): E,
	Vector2(1, 1): SE,
	Vector2(0, 1): S,
	Vector2(-1, 1): SW,
	Vector2(-1, 0): W,
	Vector2(-1, -1): NW
};


var path: Array = []
var dir: Vector2 = Vector2.ZERO

func _init(_dir: Vector2, _pos: Vector2):
	dir = _dir
	path.push_front(_pos)

func get_next_pos() -> Vector2:
	return path[0]+dir

func get_current_pos() -> Vector2:
	return path[0]
	
func get_prev_pos() -> Vector2:
	if path.size() > 1:
		return path[1]
	else:
		return path[0]

func move():
	path.push_front(path[0]+dir)

func set_dir(_dir: Vector2):
	dir = _dir

func change_to_next_dir(bit_mask: int = ALL_DIR):
	var new_dir: Vector2 = Vector2.ZERO
	var is_next_dir: bool = false
	for c_dir in cell_dirs.keys():
		if (cell_dirs[c_dir] & bit_mask):
			if is_next_dir:
				set_dir(c_dir)
				return
			if dir == c_dir:
				is_next_dir = true

	for c_dir in cell_dirs.keys():
		if (cell_dirs[c_dir] & bit_mask):
			set_dir(c_dir)
			return

func move_back() -> bool:
	if path.size() <= 1:
		return false
	path.pop_front()
	return true

func get_same_dir_count() -> int:
	var count: int = 0
	for i in (path.size()-1):
		var t_dir: Vector2 = path[i]-path[i+1]
		if t_dir == self.dir:
			count+=1
	
	return count

func get_neighbors(bit_mask: int = ALL_DIR) -> Array: # Return an array with the cells (vector2) of the valid neighbors, sanitazed taking in account dimension bounds
	var neighbors: Array = [];
	for c_dir in cell_dirs.keys():
		if (cell_dirs[c_dir] & bit_mask):
			neighbors.append(path[0]+c_dir);
	return neighbors;
