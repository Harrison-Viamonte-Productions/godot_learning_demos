extends CanvasLayer

signal start_game

onready var lives_counter: Array = [
	$MarginContainer/HBoxContainer/LivesCounter/L1,
	$MarginContainer/HBoxContainer/LivesCounter/L2,
	$MarginContainer/HBoxContainer/LivesCounter/L3
]

func _ready():
	$StartButton.connect("pressed", self, "_on_StartButton_pressed")
	$MessageTimer.connect("timeout", self, "_on_MessageTimer_timeout")

func show_message(message: String) -> void:
	$MessageLabel.text = message
	$MessageLabel.show()
	$MessageTimer.start()

func update_score(value: int) -> void:
	$MarginContainer/HBoxContainer/ScoreLabel.text = str(value)

func update_lives(value: int) -> void:
	for item in range(3):
		lives_counter[item].visible = value > item

func game_over():
	show_message("Game Over")
	yield($MessageTimer, "timeout")
	$StartButton.show()

func _on_StartButton_pressed():
	$StartButton.hide()
	emit_signal("start_game")

func _on_MessageTimer_timeout():
	$MessageLabel.hide()
	$MessageLabel.text = ''
