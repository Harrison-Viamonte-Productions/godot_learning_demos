extends AnimatedSprite

var taken: bool = false;

func _ready():
	self.play("default");
	$Area2D.connect("body_entered", self, "_on_Area2D_body_entered");

func _on_Area2D_body_entered(body):
	if taken:
		return;
	Global.GameState.coin_up();
	$AnimationPlayer.play("die");
	$coin_sfx.play();
	taken = true;

func die():
	queue_free();
