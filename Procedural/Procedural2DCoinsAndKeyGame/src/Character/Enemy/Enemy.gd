extends "res://src/Character/Character.gd"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	can_move = false
	facing = moves.keys()[rng.randi()%4]
	yield(get_tree().create_timer(0.5), 'timeout')
	can_move = true
	add_to_group("enemies")

func _process(delta):
	if can_move:
		if !move(facing) or rng.randi()%10 > 5:
			facing = moves.keys()[rng.randi()%4]
