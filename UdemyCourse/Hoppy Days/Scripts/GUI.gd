extends CanvasLayer

func _ready() -> void:
	Global.GUI = self;

func update_GUI(coins: int, lives: int) -> void:
	$banner/HBoxContainer/CoinCount.text = str(coins);
	$banner/HBoxContainer/LifeCount.text = str(lives);

func animate(anim_name: String) -> void:
	$AnimationPlayer.play(anim_name);
