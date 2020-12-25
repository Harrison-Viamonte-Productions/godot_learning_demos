extends KinematicBody2D

const WALK_SPEED: float = 64.0;
var direction: Vector2 = Vector2.ZERO;

func _physics_process(delta):
	direction = Vector2.ZERO;
	if Input.is_action_pressed("ui_left"):
		direction.x = -1.0;
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1.0;
	elif Input.is_action_pressed("ui_up"):
		direction.y = -1.0;
	elif Input.is_action_pressed("ui_down"):
		direction.y = 1.0;
	
	if !direction && $AnimationPlayer.get_current_animation() != "idle":
		$AnimationPlayer.play("idle");
	move_and_slide(direction.normalized()*WALK_SPEED);

func _input(event):
	if Input.is_action_pressed("ui_left"):
		$AnimationPlayer.play("walk_left");
	elif Input.is_action_pressed("ui_right"):
		$AnimationPlayer.play("walk_right");
	elif Input.is_action_pressed("ui_up"):
		$AnimationPlayer.play("walk_up");
	elif Input.is_action_pressed("ui_down"):
		$AnimationPlayer.play("walk_down");
