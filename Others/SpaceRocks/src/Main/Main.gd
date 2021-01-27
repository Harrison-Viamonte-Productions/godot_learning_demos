extends Node
const ROCK_DEFAULT_SIZE: int = 3

export (PackedScene) var Rock
var screensize: Vector2 = Vector2.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var level: int = 0
var score: int = 0
var playing: bool = false


func _ready():
	rng.randomize()
	screensize = get_viewport().get_visible_rect().size
	$Player.connect("shoot", self, "_on_Player_shoot")
	$Player.connect("lives_changed", self, "update_lives")
	$Player.connect("dead", self, "game_over")
	$HUD.connect("start_game", self, "new_game")
	$Player.screensize = screensize
	for i in range(3):
		spawn_rock(ROCK_DEFAULT_SIZE)

func update_lives(new_lives):
	$HUD.update_lives(new_lives)

func new_game():
	for rock in $Rocks.get_children():
		rock.queue_free()
	level = 0
	score = 0
	$HUD.update_score(score)
	$Player.start()
	$HUD.show_message("Get Ready!")
	yield($HUD/MessageTimer, "timeout")
	new_level()
	yield(get_tree().create_timer(0.5), "timeout") #Delay of 0.5 seconds because it is necessary to wait for asteroids to be added to the scene
	playing = true

func new_level():
	level += 1
	$HUD.show_message("Wave %s" % level)
	for i in range(level):
		spawn_rock(3)

func game_over():
	playing = false
	$HUD.game_over()

func _process(delta):
	if playing and $Rocks.get_child_count() == 0:
		new_level()

func spawn_rock(size, pos=null, vel=null):
	if !pos:
		$RockPath/RockSpawn.set_offset(rng.randi())
		pos = $RockPath/RockSpawn.position
	
	if !vel:
		vel = Vector2(1, 0).rotated(rng.randf_range(0.0, 2.0*PI)) * rng.randf_range(100.0, 150.0)
	
	var r = Rock.instance()
	r.screensize = screensize
	r.start(pos, vel, size)
	r.connect('exploded', self, '_on_Rock_exploded')
	$Rocks.call_deferred("add_child", r)

func _on_Rock_exploded(_size: int, _radius: int, _pos: Vector2, _vel:Vector2):
	if _size <= 1:
		return
	for offset in [-1 , 1]:
		var dir:Vector2 = (_pos - $Player.position).normalized().tangent()*offset
		var newpos: Vector2 = _pos + dir*_radius
		var newvel: Vector2 = dir*_vel.length()*1.1
		spawn_rock(_size-1, newpos, newvel)
func _on_Player_shoot(bullet, pos, dir):
	var b = bullet.instance()
	b.start(pos, dir)
	add_child(b)
