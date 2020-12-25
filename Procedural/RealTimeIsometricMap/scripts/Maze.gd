extends Node2D

const N: int = 0x1; # bit 1
const E: int = 0x2; # bit 2
const S: int = 0x4; # bit 3
const W: int = 0x8; # bit 4

var map_seed: int = 0; # PERFECT FOR SAVING MAPS!!!!! AND SHARING MAP INFO VIA NETCODE!!!!!
#var rng: RandomNumberGenerator = RandomNumberGenerator.new();

var cell_walls: Dictionary = {
	Vector2(0, -1): N,
	Vector2(1, 0): E,
	Vector2(0, 1): S,
	Vector2(-1, 0): W
};

onready var Map: TileMap = $TileMap;

func _ready():
	$Truck.map = Map;
	$Truck.map_pos = Vector2(0, 0);
	$Truck.position = Map.map_to_world($Truck.map_pos) + Vector2(0, 20);


func find_valid_tiles(cell: Vector2) -> Array:
	var valid_tiles: Array = [];
	#returns all valid tiles for a given cell
	for i in range(16): # all tiles from 1 to 15
		# check target space's neighbors (if they exist)
		var is_match: bool = false;
		for n in cell_walls.keys():
			var  neighbor_id = Map.get_cellv(cell+n);
			if neighbor_id >= 0: #Not an empty tile
				if (neighbor_id & cell_walls[-n])/cell_walls[-n] == (i & cell_walls[n])/cell_walls[n]:
					is_match = true;
				else:
					is_match = false; 
					break; #must match true with all neighbor tiles, otherwise breaks with false
		
		if is_match:
			valid_tiles.append(i);
	return valid_tiles;
func generate_tile(cell: Vector2):
	var cells: Array = find_valid_tiles(cell);
	Map.set_cellv(cell, cells[randi()%cells.size()]);
