extends Node2D

const N: int = 1; # bit 1
const E: int = 2; # bit 2
const S: int = 4; # bit 3
const W: int = 8; # bit 4

var map_seed: int = 0; # PERFECT FOR SAVING MAPS!!!!! AND SHARING MAP INFO VIA NETCODE!!!!!
#var rng: RandomNumberGenerator = RandomNumberGenerator.new();

var cell_walls: Dictionary = {
	Vector2(0, -2): N,
	Vector2(2, 0): E,
	Vector2(0, 2): S,
	Vector2(-2, 0): W
};

var tile_size: Vector2 = Vector2(64, 64); # tile size (in pixels)
var width: int = 40; # width of map (in tiles)
var height: int = 22; # height of map (in tiles)

# get a reference of the tile map for convenience

# Fraction of walls to remove

var erase_fraction: float = 0.25;

onready var Map: TileMap = $TileMap;

func check_neighbors(cell: Vector2, unvisited: Array) -> Array:
	# Returns an array of cell's unvisited neighbors
	var list: Array = [];
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell+n);
	return list;

func make_maze() -> void:
	var unvisited: Array = []; # array of unvisited tiles
	var stack: Array = [];
	#fill the map with solid tiles
	Map.clear();
	for x in range(width):
		for y in range(height):
			#unvisited.append(Vector2(x, y));
			Map.set_cellv(Vector2(x, y), N|E|S|W); #0001|0010|0100|1000 = 1111
	for x in range(0, width, 2):
		for y in range(0, height, 2):
			unvisited.append(Vector2(x, y));
	var current: Vector2 = Vector2(0, 0);
	unvisited.erase(current);
	
	#Execute recursive backtracker algorithm
	
	while !unvisited.empty():
		var neighbors: Array = check_neighbors(current, unvisited);
		if neighbors.size() > 0:
			var next: Vector2 = neighbors[randi() % neighbors.size()];
			stack.append(current);
			# Remove walls from *both* cells
			var dir: Vector2 = next - current;
			var current_walls = Map.get_cellv(current) - cell_walls[dir];
			var next_walls = Map.get_cellv(next) - cell_walls[-dir];
			Map.set_cellv(current, current_walls);
			Map.set_cellv(next, next_walls);
			# insert intermediate cell 
			if dir.x != 0:
				Map.set_cellv(current + dir/2, 5);
			else:
				Map.set_cellv(current + dir/2, 10);
			current = next;
			unvisited.erase(current);
			yield(get_tree(), 'idle_frame'); # Remove this!
		elif stack:
			current = stack.pop_back();
		#yield(get_tree(), 'idle_frame'); # Remove this!
	erase_walls(); # Post process

func erase_walls():
	# Randomly remove a number of the map's walls.
	for i in range(int(width*height*erase_fraction)):
		var x = int(rand_range(2, width/2-2))*2; # even number
		var y = int(rand_range(2, height/2-2))*2; # even number
		var cell = Vector2(x, y);
		# Pick random neighbor
		var neighbor: Vector2 = cell_walls.keys()[randi()%cell_walls.size()];
		# if there's a wall betwen them, remove it.
		if Map.get_cellv(cell) & cell_walls[neighbor]:
			var walls = Map.get_cellv(cell)-cell_walls[neighbor];
			var n_walls = Map.get_cellv(cell+neighbor) - cell_walls[-neighbor];
			Map.set_cellv(cell, walls);
			Map.set_cellv(cell+neighbor, n_walls);
			#Insert intermediate cell
			if neighbor.x != 0:
				Map.set_cellv(cell+neighbor/2, 5);
			else:
				Map.set_cellv(cell+neighbor/2, 10);
		yield(get_tree(), 'idle_frame');

func generate_maze():
	Map.set_scale(Vector2(0.5, 0.5));
	#rng.randomize();
	randomize();
	if !map_seed:
		map_seed = randi();
	seed(map_seed);
	print("Seed: ", map_seed);
	tile_size = Map.cell_size;
	make_maze();

func _ready():
	generate_maze();

func _input(event):
	var is_just_pressed = event.is_pressed() && !event.is_echo();
	if Input.is_key_pressed(KEY_SPACE) && is_just_pressed:
		map_seed = 0;
		generate_maze();
