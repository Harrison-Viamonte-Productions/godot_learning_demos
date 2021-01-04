extends Node2D

const MIN_LEVEL_SIZE: int = 16
const MAX_LEVEL_SIZE: int = 50
const MIN_ROOM_SIZE: int = 4
const MAX_ROOM_SIZE: int = 9

export (PackedScene) var Enemy
export (PackedScene) var Pickup

onready var items = $Items
var doors = []
var map_grid: RoomObj #roomObj
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var walkers: Array = []
var map_bounds: Vector2 = Vector2.ZERO
onready var player_spawn_id: int = $Items.tile_set.find_tile_by_name('player_spawn')
onready var coin_spawn_id: int = $Items.tile_set.find_tile_by_name('coin')
onready var slime_spawn_id: int = $Items.tile_set.find_tile_by_name('slime_spawn')
onready var star_spawn_id: int = $Items.tile_set.find_tile_by_name('star')
onready var key_spawn_id: int = $Items.tile_set.find_tile_by_name('key_red')
onready var door_spawn_id: int = $Items.tile_set.find_tile_by_name('door_red')

func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		generate_map()

func _ready():
	generate_map()
	$Player.connect("dead", self, 'game_over')
	$Player.connect("grabbed_key", self, '_on_Player_grabbed_key')
	$Player.connect('win', self, '_on_Player_win')

func clear_entities():
	var entities: Array = $Entities.get_children()
	for entity in entities:
		entity.call_deferred("queue_free") 

func generate_map():
	rng.randomize()
	clear_entities()
	init_walkers()
	init_map_bounds()
	clear_tiles()

	#Initialize level
	map_grid = RoomObj.new(map_bounds)
	
	#Create room with key
	var key_room: RoomObj = generate_room(true) #Generate room with key
	var door_entrance_pos: Vector2 = get_door_entrance_pos(key_room, door_spawn_id) #Obtain the tile pos that it's in front of the door
	#Get all the possible cells, with margin of 2, that this room can use to spawn in the map
	var cells_to_fit: Array = map_grid.get_cells_to_fit_room(key_room, 2) 
	key_room.set_pos(cells_to_fit[rng.randi()%cells_to_fit.size()])  #Pick any of these random cells and place the room in the map
	door_entrance_pos += key_room.get_pos()
	map_grid.merge_with(key_room)
	
	#Generate path and walls in the level taking in account the exit room, starting from the exit's door entrance, to make sure
	#that you can always reach the exit
	init_walkers()
	map_grid.ground.set_grid_array(PCG.generate_path_with_walkers(map_grid.ground.get_grid_array(), 2000, $Ground.tile_set.find_tile_by_name('ground_green'), 0.5, rng, door_entrance_pos, map_grid.walls.get_grid_array()))
	generate_walls($Walls.tile_set.find_tile_by_name('wall_brick'), map_grid)

	#Spawn other random rooms
	var available_items_cells: Array = map_grid.ground.get_used_cells() # Array of cells available to spawn items
	available_items_cells = key_room.ground.substract_from_cells(available_items_cells)
	var t_room: RoomObj #Generate extra rooms to add more variety
	var extra_rooms: int = rng.randi_range(0, 2)
	for i in range(extra_rooms):
		t_room = generate_room()
		var to_fit: Array = map_grid.get_cells_to_fit_room(t_room, 2, $Ground.tile_set.find_tile_by_name('ground_green')) # margin 2 to avoid having the room in a border of the map
		if to_fit.size() == 0:
			break
		t_room.set_pos(to_fit[rng.randi()%to_fit.size()])
		available_items_cells = t_room.ground.substract_from_cells(available_items_cells) # 
		map_grid.merge_with(t_room)

	available_items_cells = map_grid.walls.substract_from_cells(available_items_cells)

	#spawn player 
	var player_cell = generate_items(map_grid, available_items_cells, player_spawn_id, 1)[0]
	#make a safe area for the player
	available_items_cells = PCG.substract_cells_from_rec2(available_items_cells, Rect2(player_cell-Vector2(3, 3), Vector2(6, 6)), 1)

	var coins: int = int(available_items_cells.size()*rng.randf_range(0.05, 0.1))
	var slimes: int = int(available_items_cells.size()*rng.randf_range(0.0125, 0.025))
	generate_items(map_grid, available_items_cells, coin_spawn_id, coins)
	generate_items(map_grid, available_items_cells, slime_spawn_id, slimes)
	
	var key_margin_dist: Vector2 = Vector2(int(map_bounds.x/2.0)-key_room.get_size().size.x, int(map_bounds.y/2.0)-key_room.get_size().size.y)
	available_items_cells = PCG.substract_cells_from_rec2(available_items_cells, Rect2(player_cell-Vector2(int(key_margin_dist.x/2), int(key_margin_dist.y/2)), key_margin_dist), 1) # 10 of radius protection
	available_items_cells = PCG.substract_cells_from_rec2(available_items_cells, Rect2(key_room.get_size().position-Vector2(int(key_margin_dist.x/2), int(key_margin_dist.y/2)), key_room.get_size().size+key_margin_dist), 1)
	print("Key spawned at: " + str(generate_items(map_grid, available_items_cells, key_spawn_id, 1)[0]))

	map_grid.ground.replace(-1, $Ground.tile_set.find_tile_by_name('ground_green'))
	clean_walls(map_grid, $Walls.tile_set.find_tile_by_name('wall_brick'), $Walls.tile_set.find_tile_by_name('crate_blue'))

	map_grid.ground.map_to_tilemap($Ground)
	map_grid.walls.map_to_tilemap($Walls)
	map_grid.items.map_to_tilemap($Items)
	$Items.hide()
	set_camera_limits()
	var door_id = $Walls.tile_set.find_tile_by_name('door_red')
	for cell in $Walls.get_used_cells_by_id(door_id):
		doors.append(cell)
	spawn_items()

func init_map_bounds():
	map_bounds = Vector2(rng.randi_range(MIN_LEVEL_SIZE, MAX_LEVEL_SIZE), rng.randi_range(MIN_LEVEL_SIZE, MAX_LEVEL_SIZE))

func init_walkers():
	walkers.clear()

func clear_tiles():
	$Ground.clear()
	$Walls.clear()
	$Items.clear()

# Generates a room and returns a vector2 with the position next to a door
func generate_room(spawn_key: bool = false) -> RoomObj: # RoomObj
	var room_bounds: Vector2 = Vector2(rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE), rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE))
	var g_room = RoomObj.new(room_bounds)
	while !generate_doors(g_room, door_spawn_id):
		init_walkers()
		g_room.clear()
		g_room.ground.set_grid_array(PCG.generate_path_with_walkers(g_room.ground.get_grid_array(), 1000, $Ground.tile_set.find_tile_by_name('ground_grey'), 0.35, rng, Vector2(int(room_bounds.x/2), int(room_bounds.y/2))))
		generate_walls($Walls.tile_set.find_tile_by_name('wall_grey'), g_room)
	
	var available_cells: Array = g_room.ground.get_used_cells()
	if spawn_key:
		generate_items(g_room, available_cells, star_spawn_id, 1) # spawning exit
	
	var coins: int = int(available_cells.size()*rng.randf_range(0.1, 0.2))
	var slimes: int = int(available_cells.size()*rng.randf_range(0.075, 0.125))
	generate_items(g_room, available_cells, coin_spawn_id, coins)
	generate_items(g_room, available_cells, slime_spawn_id, slimes)
	g_room.ground.replace(-1, $Ground.tile_set.find_tile_by_name('ground_grey'))
	return g_room

func can_place_door(tile_pos: Vector2, grid: GridObj, wall_tile_id: int) -> bool:
	if (grid.filter_neighbors(tile_pos, wall_tile_id, PCG.N | PCG.S).size() == 2) and (grid.filter_neighbors(tile_pos, wall_tile_id, PCG.E | PCG.W).size() == 0):
		return true
	elif (grid.filter_neighbors(tile_pos, wall_tile_id, PCG.N | PCG.S).size() == 0) and (grid.filter_neighbors(tile_pos, wall_tile_id, PCG.E | PCG.W).size() == 2):
		return true
	return false

func generate_doors(room: RoomObj, door_id: int) -> bool:
	var room_bounds: Vector2 = room.get_size().size
	var door_candidates: Array = []
	var wall_tile_id: int = room.walls.get_cell(0, 0)
	for x in range(room_bounds.x):
		for y in range (room_bounds.y):
			if x == 0 or y == 0 or x == room_bounds.x-1 or y == room_bounds.y-1:
				if can_place_door(Vector2(x, y), room.walls, wall_tile_id):
					door_candidates.append(Vector2(x, y))
	if door_candidates.size() == 0:
		return false
	room.walls.set_cellv(door_candidates[rng.randi()%door_candidates.size()], door_id)
	return true

func get_door_entrance_pos(room: RoomObj, door_id: int) -> Vector2:
	var room_bounds: Vector2 = room.get_size().size
	for x in range(room_bounds.x):
		for y in range (room_bounds.y):
			if room.walls.get_cell(x, y) == door_id:
				return room.ground.filter_neighbors(Vector2(x, y), -1, PCG.HOR_AND_VER_DIR)[0]
	assert(0) #This place should never be reached
	return Vector2.ZERO #ERROR

func generate_walls(tile_id: int, room: RoomObj):
	var ground_cells: Array = room.ground.get_used_cells()
	var room_bounds: Vector2 = room.get_size().size
	for x in range(room_bounds.x):
		for y in range (room_bounds.y):
			if ground_cells.find(Vector2(x, y)) == -1:
				room.walls.set_cell(x, y, tile_id)

func clean_walls(room: RoomObj, wall_tile_id: int, crate_tile_id: int):
	var walls_cells: Array = room.walls.get_used_cells()
	for i in range(walls_cells.size()):
		var tile_id: int = room.walls.get_cellv(walls_cells[i])
		if tile_id == wall_tile_id and room.walls.filter_neighbors(walls_cells[i], wall_tile_id, PCG.HOR_AND_VER_DIR).size() == 0:
			room.walls.set_cellv(walls_cells[i], crate_tile_id)

func generate_items(room: RoomObj, cells: Array, type_id: int, count: int) -> Array:
	var cells_used: Array = []
	while count > 0 and cells.size() > 0:
		var i = rng.randi()%cells.size()
		room.items.set_cellv(cells[i], type_id)
		cells_used.append(cells[i])
		cells.remove(i)
		count-=1
	return cells_used

func set_camera_limits():
	var map_size: Rect2 = $Ground.get_used_rect()
	var cell_size: Vector2 = $Ground.cell_size
	$Player/Camera2D.limit_left = map_size.position.x*cell_size.x
	$Player/Camera2D.limit_top = map_size.position.y*cell_size.x
	$Player/Camera2D.limit_right = map_size.end.x*cell_size.x
	$Player/Camera2D.limit_bottom = map_size.end.y*cell_size.y

func spawn_items():
	for cell in items.get_used_cells():
		var id = items.get_cellv(cell)
		var type = items.tile_set.tile_get_name(id)
		var pos = items.map_to_world(cell) + items.cell_size/2
		match type:
			'slime_spawn':
				var s: Node2D = Enemy.instance()
				s.position = pos
				s.tile_size = items.cell_size
				$Entities.add_child(s)
			'player_spawn':
				$Player.position = pos
				$Player.tile_size = items.cell_size
			'coin', 'key_red', 'star':
				var p = Pickup.instance()
				p.init(type, pos)
				$Entities.add_child(p)
				p.connect('coin_pickup', $HUD, 'update_score')

func game_over():
	Global.game_over()

func _on_Player_win():
	Global.next_level()

func _on_Player_grabbed_key():
	for cell in doors:
		$Walls.set_cellv(cell, -1)
