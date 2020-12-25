extends Node2D

var timeout: bool = false;

func _ready():
	$Timer.connect("timeout", self, "_on_Timer_timeout");

func _process(delta):
	if $Sprite/RayCast2D.is_colliding():
		fire();

func _on_Timer_timeout():
	timeout = false;

func fire():
	if not timeout: 
		$Sprite/RayCast2D.add_child(load(Global.Lightning).instance());
		$Timer.start();
		timeout = true;
		
