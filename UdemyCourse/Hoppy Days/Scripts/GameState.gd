extends Node2D

export var starting_lives: int = 3;
export var coin_target: int = 20; #How many coins for an extra life

var lives: int;
var coins: int = 0;

onready var GUI: Node = Global.GUI;

func _ready():
	
	Engine.set_target_fps(Engine.get_iterations_per_second()); # Fix for higher HZ
	
	Global.GameState = self;
	lives = starting_lives;
	update_GUI();

func update_GUI():
	GUI.update_GUI(coins, lives);

func animate(animation):
	GUI.animate(animation);

func hurt():
	lives -= 1;
	animate("Hurt");
	Global.pain_sfx.play();
	Global.Player.play_animation("hurt");
	#Global.
	if lives < 0:
		end_game();
	update_GUI();

func coin_up():
	coins += 1;
	animate("CoinPulse");
	var multiple_of_coin_target = (coins % coin_target) == 0;
	if multiple_of_coin_target:
		life_up();
	update_GUI();

func life_up():
	lives += 1;
	animate("LifePulse");
	update_GUI();

func end_game():
	get_tree().change_scene(Global.GameOver);

func win_game():
	get_tree().change_scene(Global.Victory);

func _on_Portal_body_entered(body):
	win_game();
