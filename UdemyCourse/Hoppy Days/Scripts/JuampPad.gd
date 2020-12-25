extends Area2D


func _ready():
	self.connect("body_entered", self, "_on_JumpPad_body_entered");
	$Timer.connect("timeout", self, "_on_Timer_timeout");

func _on_JumpPad_body_entered(body):
	$AnimatedSprite.play("spring");
	$Timer.start();
	Global.jump_sfx.play();
	Global.Player.boost();

func _on_Timer_timeout():
	$AnimatedSprite.play("idle");
