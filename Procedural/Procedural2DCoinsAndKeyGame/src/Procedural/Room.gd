class_name RoomObj
extends Object

#All grids must have the same since... mostly for make it easy for me to code
var ground: GridObj
var walls: GridObj
var items: GridObj
var position: Vector2

func _init(_size: Vector2):
	ground = GridObj.new(_size)
	walls = GridObj.new(_size)
	items = GridObj.new(_size)

func set_pos(_pos: Vector2):
	position = _pos
	ground.set_pos(_pos)
	walls.set_pos(_pos)
	items.set_pos(_pos)

func is_in_bounds(x: int, y: int) -> bool:
	return ground.is_in_bounds(x, y)

func get_pos() -> Vector2:
	return position

func get_size() -> Rect2:
	return ground.get_size() #or any other map

func get_cells_to_fit_room(fit_room, margin: int = 0, allow_id: int = -1) -> Array:
	return ground.get_cells_to_fit_grid(fit_room.ground, margin, allow_id) #works only if all grids have the same size

func split_by(mult: int):
	ground.split_by(mult)
	walls.split_by(mult)
	items.split_by(mult, false)

func merge_with(merge_room):
	ground.merge_with_grid(merge_room.ground)
	walls.merge_with_grid(merge_room.walls)
	items.merge_with_grid(merge_room.items)

func clear():
	ground.clear()
	walls.clear()
	items.clear()
