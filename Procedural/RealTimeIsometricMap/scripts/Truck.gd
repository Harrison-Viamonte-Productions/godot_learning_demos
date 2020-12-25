extends Area2D

const EMPTY_SQUARE: int = -1;

const N: int = 0x1;
const E: int = 0x2;
const S: int = 0x4;
const W: int = 0x8;

var animations: Dictionary = {
	N: 'n',
	S: 's',
	E: 'e',
	W: 'w'
};

var moves: Dictionary = {
	N: Vector2(0, -1),
	S: Vector2(0, 1),
	E: Vector2(1, 0),
	W: Vector2(-1, 0)
};

var map: TileMap = null;
var map_pos: Vector2 = Vector2();
var speed: int = 1;
var moving: bool = false;

func can_move(dir) -> bool:
	var t = map.get_cellv(map_pos);
	if t & dir:
		return false;
	else:
		return true;

func _input(event):
	if moving:
		return;
	if event.is_action_pressed("ui_up"):
		move(N);
	if event.is_action_pressed("ui_down"):
		move(S);
	if event.is_action_pressed("ui_right"):
		move(E);
	if event.is_action_pressed("ui_left"):
		move(W);

func move(dir):
	if not can_move(dir):
		return;
	moving = true;
	$AnimatedSprite.play(animations[dir]);
	map_pos += moves[dir];
	if map.get_cellv(map_pos) == EMPTY_SQUARE: #if moving towards empty square
		get_parent().generate_tile(map_pos);
	var destination = map.map_to_world(map_pos) + Vector2(0, 20);
	$Tween.interpolate_property(self, 'position', position, destination, 1.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT);
	$Tween.start();

func _on_Tween_tween_completed(object, key):
	moving = false;

func _ready():
	$Tween.connect("tween_completed", self, "_on_Tween_tween_completed");
