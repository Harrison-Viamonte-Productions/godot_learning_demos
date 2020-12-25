extends Area2D

var can_click: bool = false;

func _ready():
	self.connect("body_entered", self, "_on_body_entered");
	self.connect("body_exited", self, "_on_body_exit");

func _on_body_entered(body):
	if not body == Global.Player:
		if (not $AnimationPlayer.is_playing()):
			open();
	else:
		can_click = true;

func _on_body_exit(body):
	if body == Global.Player:
		can_click = false;

func open():
	$AnimationPlayer.play("open");

func _input_event(viewport, event, shape_idx):
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and can_click:
		open();
