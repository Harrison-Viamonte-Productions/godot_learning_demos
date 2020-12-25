extends KinematicBody2D

const WALK_SPEED: int = 200;
var dead: bool = false;
var direction: Vector2 = Vector2.ZERO;
var current_animation: String = "idle";
var can_drop_bomb: bool = true;
onready var tilemap: TileMap = get_node("/root/Arena/TileMap");
var bomb_scene: PackedScene = preload("res://scenes/Bomb.tscn");
onready var animation: AnimationPlayer = $AnimationPlayer;
var spawn_pos: Vector2 = Vector2.ZERO;
onready var sprite = $Sprite;

const textures = [
	preload("res://sprites/player1.png"),
	preload("res://sprites/player2.png"),
	preload("res://sprites/player3.png"),
	preload("res://sprites/player4.png")
];

var id = null;
var nickname = "";
var score = 0;
var color_index = 0;

func _ready():
	add_to_group("players");
	$BombCooldown.connect("timeout", self, "_on_dropbomb_cooldown");
	spawn_pos = position;
	sprite.texture = textures[color_index];

slave func _update_pos(new_pos, new_direction):
	position = new_pos;
	direction = new_direction;
	_update_rot_and_animation(direction);

func _update_rot_and_animation(dir):
	var new_animation = "idle";
	if dir:
		rotation = atan2(dir.y, dir.x);
		new_animation = "walking";
	if new_animation != current_animation:
		animation.play(new_animation);
		current_animation = new_animation;

func _on_dropbomb_cooldown():
	can_drop_bomb = true;

func _process(delta):
	if !is_network_master() or dead:
		return;
	if Input.is_action_just_pressed("ui_select") and can_drop_bomb:
		rpc('_dropbomb', tilemap.centered_world_pos(position));
		can_drop_bomb = false;
		$BombCooldown.start();

sync func _dropbomb(pos: Vector2):
	var bomb: Node2D = bomb_scene.instance();
	bomb.position = pos;
	bomb._owner = self;
	get_node("/root/Arena").add_child(bomb);

func _physics_process(delta):
	if !is_network_master():
		return;
	
	if !dead:
		if Input.is_action_pressed("ui_up"):
			direction.y = -WALK_SPEED;
		elif Input.is_action_pressed("ui_down"):
			direction.y = WALK_SPEED;
		else:
			direction.y = 0;

		if Input.is_action_pressed("ui_left"):
			direction.x = -WALK_SPEED;
		elif Input.is_action_pressed("ui_right"):
			direction.x = WALK_SPEED;
		else:
			direction.x = 0;

		move_and_slide(direction.normalized()*WALK_SPEED);
		_update_rot_and_animation(direction);
	
	# Send to other peers our player info
	# Note we use unreliable mode given we synchronize during every frame
	# so losing a packet is not an issue
	rpc_unreliable("_update_pos", position, direction);

sync func damage(killer_id):
	dead = true;
	gamestate.emit_signal("player_killed", id, killer_id);
	# Make the player respawn at it initial spawn point
	position = spawn_pos
	animation.play("respawn");
	animation.connect("animation_finished", self, "respawn", [], CONNECT_ONESHOT);

func respawn( anim_name ):
	dead = false;
