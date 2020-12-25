extends Node

onready var player_scene: PackedScene = preload("res://src/scenes/Player.tscn");

onready var dirt_tilemap = $DirtTileMap;
onready var wall_tilemap = $WallTileMap;

const BIG_BFS_NUM: int = 60000;

var rng: RandomNumberGenerator = RandomNumberGenerator.new();

var CellSize: Vector2 = Vector2(32, 32);
var width: int = 1024/CellSize.x; #Tile pos instead of pixels
var height: int = 1024/CellSize.y; #Tile pos instead of pixels
var grid: Array = [];
var walkers: Array = [];
var player_spawned: bool = false;
var Player: Node2D = null;
var neighbors4: Array = [[1, 0], [-1,0],[0,1],[0,-1]];
var neighbors8: Array = [[1, 0], [-1,0],[0,1],[0,-1], [1, 1], [-1,-1],[1,-1],[-1,1]];

class Walker:
	var same_dir_count: int;
	var dir: Vector2;
	var pos: Vector2;
	
	func _init(n_dir: Vector2, n_pos: Vector2):
		dir = n_dir;
		pos = n_pos;
		same_dir_count = 0;

var Tiles = {
	"Empty": -1,
	"Wall": 0,
	"Floor": 1,
	"Dirt": 2
};

func _init_walkers(ammount: int):
	walkers = [];
	for i in range(ammount):
		var walker = Walker.new(GetRandomDirection(), Vector2(width/2, height/2));
		walkers.append(walker);

func _init_grid():
	grid = [];
	for x in width:
		grid.append([]);
		for y in height:
			grid[x].append(Tiles.Empty);
	#creates bi-dimensional array, grid, filled with -1 (aka Tiles.Empty)

func GetRandomDirection() -> Vector2:
	var directions: Array = [[-1, 0], [1, 0], [0, 1], [0,-1]];
	var direction: Array = directions[rng.randi()%4]; # A random value between 0 and 3
	return Vector2(direction[0], direction[1]);

func is_dir_in_bounds(dir: Vector2, bound_start: Vector2, bound_end: Vector2) -> bool:
	if (dir.x >= bound_start.x and dir.x < bound_end.x
		and dir.y >= bound_start.y and dir.y < bound_end.y):
		return true;
	else:
		return false;

func _create_random_path(max_iterations: int):
	var walker_max_count = 3;
	var walker_spawn_chance = 0.25;
	var walker_direction_chance = 0.4;
	var walker_destroy_chance = 0.2;
	var max_same_dir = 5;
	var fill_percent = 0.3;
	var itr: int = 0;
	var n_tiles: int = 0;
	while itr < max_iterations:
		#Perform random walk
		#1- Choose random direction
		#2- Check that direction is in bounds
		#3- move in that direction
		
		#Change direction, with chance
		for i in range(walkers.size()):
			if rng.randf() < walker_direction_chance or walkers[i].same_dir_count >= max_same_dir:
				var old_dir: Vector2 = walkers[i].dir;
				var d_itr: int = 0;
				while old_dir == walkers[i].dir:
					walkers[i].dir = GetRandomDirection();
					d_itr += 1;
					if d_itr > 10:
						break; #to avoid breaking performance
				walkers[i].same_dir_count = 0;

		#Random: Maybe destroy walker?
		for i in range(walkers.size()):
			if rng.randf() < walker_destroy_chance && walkers.size() > 1:
				walkers.remove(i);
				break; # Destroy only one walker per iteration

		# Spawn new walkers, with chance
		for i in range(walkers.size()):
			if rng.randf() < walker_spawn_chance && walkers.size() < walker_max_count:
				walkers.append(Walker.new(GetRandomDirection(), walkers[i].pos));
		
		#Advance walkers 
		for i in range(walkers.size()):
			if is_dir_in_bounds(walkers[i].pos + walkers[i].dir, Vector2(1, 1), Vector2(width-1, height-1)):
				walkers[i].pos += walkers[i].dir;
				walkers[i].same_dir_count += 1;
				if grid[walkers[i].pos.x][walkers[i].pos.y]  == Tiles.Empty:
					grid[walkers[i].pos.x][walkers[i].pos.y] = Tiles.Floor;
					n_tiles += 1;
					if float(n_tiles)/float(width*height) >= fill_percent:
						return;
		itr+=1;

func _create_walls():
	for x in width:
		for y in height:
			if x==0 or y == 0 or x == width-1 or y == width-1:
				grid[x][y] = Tiles.Wall; #Borders with walls always
			elif grid[x][y] == Tiles.Floor:
				for neighbor in neighbors4:
					if check_bounds(x, y, neighbor) && grid[x+neighbor[0]][y+neighbor[1]] == Tiles.Empty:
						grid[x+neighbor[0]][y+neighbor[1]] = Tiles.Wall;

func check_bounds(x: int, y: int, neighbor: Array) -> bool:
	return is_dir_in_bounds(Vector2(x, y) + Vector2(neighbor[0], neighbor[1]), Vector2(1, 1), Vector2(width-1, height-1));

# Function to make all tiles that are distance 2 or more from walls, to have a dirt tile texture
func _pad_dirt():
	var bfs = [];
	var visited: Array = [];
	
	for x in width:
		visited.append(Array());
		for y in height:
			if grid[x][y] == Tiles.Wall:
				bfs.append(Vector2(x, y));
				visited[x].append(0);
			else:
				visited[x].append(BIG_BFS_NUM); #Big number
	
	while !bfs.empty():
		var pos = bfs.pop_front();
		for i in range(neighbors8.size()):
			var next = Vector2(pos.x + neighbors8[i][0], pos.y + neighbors8[i][1]);
			if is_dir_in_bounds(next, Vector2(1,1), Vector2(width-1, height-1)) and (visited[next.x][next.y] == BIG_BFS_NUM):
				visited[next.x][next.y] = visited[pos.x][pos.y]+1;
				bfs.append(next);
	
	for x in width:
		for y in height:
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				continue;
			if grid[x][y] == Tiles.Floor and visited[x][y] >=2:
				grid[x][y] = Tiles.Dirt;

func _remove_diagonals(tile_index):
	for x in width:
		for y in height:
			# Check if on edges
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				continue;
			# If not on edges, make sure all surrounding tiles are floor and this is wall
			var position = Vector2(x, y);
			if grid[position.x][position.y] == tile_index:
				if (grid[position.x-1][position.y] == Tiles.Floor and grid[position.x+1][position.y] == Tiles.Floor and
					grid[position.x][position.y-1] == Tiles.Floor and grid[position.x][position.y+1] == Tiles.Floor):
					grid[position.x][position.y] = Tiles.Floor; #Remove individual isolated tiles
					
				# Check if diagonal tile
				if (grid[position.x - 1][position.y] == Tiles.Floor and grid[position.x][position.y-1] == Tiles.Floor and
					grid[position.x - 1][position.y-1] == tile_index) or (grid[position.x + 1][position.y] == Tiles.Floor and grid[position.x][position.y+1] == Tiles.Floor and
					grid[position.x + 1][position.y+1] == tile_index) or (grid[position.x + 1][position.y] == Tiles.Floor and grid[position.x][position.y-1] == Tiles.Floor and
					grid[position.x + 1][position.y-1] == tile_index) or (grid[position.x - 1][position.y] == Tiles.Floor and grid[position.x][position.y+1] == Tiles.Floor and
					grid[position.x - 1][position.y+1] == tile_index):
						grid[position.x][position.y] = Tiles.Floor

func _remove_singletons():
	for x in width:
		for y in height:
			if grid[x][y] == Tiles.Wall:
				var single_tile: bool = true;
				for neighbor in neighbors4:
					if check_bounds(x, y, neighbor) && grid[x+neighbor[0]][y+neighbor[1]] == Tiles.Wall:
						single_tile = false;
						break;
				if single_tile:
					grid[x][y] = Tiles.Floor;

func _spawn_tiles():
	for x in width:
		for y in height:
			match grid[x][y]:
				Tiles.Empty:
					wall_tilemap.set_cellv(Vector2(x, y), 0);
				Tiles.Floor:
					pass;
				Tiles.Dirt:
					if !player_spawned:
						var spawnPos: Vector2 = dirt_tilemap.map_to_world(Vector2(x*2, y*2))+CellSize*0.5;
						if !Player or typeof(Player) == TYPE_NIL:
							Player = player_scene.instance();
							call_deferred("add_child", Player);
						Player.position = spawnPos;
						player_spawned = true;
					#Spawn 4 because these tiles are 16x16, but CellSize it's 32x32
					
					dirt_tilemap.set_cellv(Vector2(x*2, y*2), 0);
					dirt_tilemap.set_cellv(Vector2(x*2+1, y*2), 0);
					dirt_tilemap.set_cellv(Vector2(x*2, y*2+1), 0);
					dirt_tilemap.set_cellv(Vector2(x*2+1, y*2+1), 0);
				Tiles.Wall:
					wall_tilemap.set_cellv(Vector2(x, y), 0);
	# The update_bitmask_region it's necessary to make the
	# Autotile work with autogenerated maps
	dirt_tilemap.update_bitmask_region();
	wall_tilemap.update_bitmask_region();

func _clear_tilemaps():
	for x in width:
		for y in height:
			dirt_tilemap.clear();
			wall_tilemap.clear();
	
	dirt_tilemap.update_bitmask_region();
	wall_tilemap.update_bitmask_region();

func _remove_player():
	player_spawned = false;

func _ready():
	_generate_map();

func _generate_map():
	rng.randomize();
	_init_walkers(1);
	_init_grid();
	_remove_player();
	_clear_tilemaps();
	_create_random_path(1000);
	_create_walls(); #post-proc
	_pad_dirt(); #post-proc
	_remove_diagonals(Tiles.Dirt);
	_spawn_tiles();

func _input(event):
	var just_pressed: bool = event.is_pressed() && !event.is_echo();
	if Input.is_key_pressed(KEY_1) && just_pressed:
		_generate_map();
