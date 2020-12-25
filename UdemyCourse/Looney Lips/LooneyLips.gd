extends Node2D

var player_words = []; # the words the player chooses
var current_story;
var strings; # All the text that's displayed to the player

var game_initialized: bool = false;

func _ready():
	#signals connections
	$Blackboard/TextBox.connect("text_entered", self, "_on_TextBox_text_entered");
	$Blackboard/TextureButton.connect("pressed", self, "_on_TextureButton_pressed");
	
	#game logic
	set_random_story();
	strings = get_from_json("other_strings.json");
	$Blackboard/StoryText.text = strings['intro_text'];

	#$Blackboard/StoryText.bbcode_text = (story%prompt);
	#prompt_player();

func set_random_story():
	var stories = get_from_json("stories.json");
	randomize(); #avoid equal values while using random at ready
	current_story = stories[randi() % stories.size()];

func get_from_json(filename):
	var file: File = File.new();
	file.open(filename, File.READ); #Assumes the file exists
	var text = file.get_as_text();
	var data = parse_json(text);
	file.close();
	return data;
	

func _on_TextureButton_pressed():
	if is_story_done():
		get_tree().reload_current_scene();
	else:
		var new_text = $Blackboard/TextBox.get_text();
		_on_TextBox_text_entered(new_text);

func _on_TextBox_text_entered(new_text):
	#$Blackboard/StoryText.bbcode_text = new_text;
	if (game_initialized):
		player_words.append(new_text);
	$Blackboard/TextBox.set_text("");
	check_player_word_length();
	game_initialized = true;

func is_story_done() -> bool:
	return player_words.size() == current_story.prompt.size();

func prompt_player():
	var next_prompt: String = current_story.prompt[player_words.size()];
	$Blackboard/StoryText.text = (strings["prompt"] % next_prompt);
func check_player_word_length():
	if is_story_done():
		tell_story();
	else:
		prompt_player();

func tell_story():
	$Blackboard/StoryText.text = current_story.story % player_words;
	end_game();
	
func end_game():
	$Blackboard/TextBox.queue_free();
	$Blackboard/TextureButton/ButtonLabel.text = strings['again'];
