extends Node

var start_screen = 'res://src/UI/StartScreen.tscn'
var end_screen = 'res://src/UI/EndScreen.tscn'
var level_scene = 'res://src/Levels/Level1.tscn'
var max_levels = 3
var current_level = 0
var score = 0
var highscore = 0
var score_file = "user://highscore.txt"

func _ready():
	setup()

func setup():
	var f = File.new()
	if f.file_exists(score_file):
		f.open(score_file, File.READ)
		var content = f.get_as_text()
		highscore = int(content)
		print(highscore)
		f.close()

func save_score():
	var f = File.new()
	f.open(score_file, File.WRITE) #Automatically creates the file
	f.store_string(str(highscore))
	f.close()

func new_game():
	score = 0
	current_level = -1
	next_level()

func game_over():
	if score > highscore:
		highscore = score
		save_score()
	get_tree().change_scene(end_screen)

func next_level():
	current_level += 1
	if current_level >= max_levels:
		game_over()
	else:
		get_tree().change_scene(level_scene)
