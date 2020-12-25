extends KinematicBody2D

const SPEED: float = 300.0;
const GRAVITY: float = 1200.0;
const UP = Vector2(0 , -1);
var motion: Vector2 = Vector2();
const JUMP_SPEED: float = -650.0;
const JUMP_BOOST: float = 1.6;

export var world_limit : int = 1700;

func _ready():
	Global.Player = self;

func _physics_process(delta):
	update_motion(delta);
	move_and_slide(motion, UP);

func update_motion(delta):
	fall(delta);
	run();
	jump();
	
func update_animation(motion):
	$AnimatedSprite.update_anim(motion);

func _process(delta):
	update_animation(motion);

func fall(delta):
	if is_on_floor() or (is_on_ceiling() && motion.y < 0.0):
		motion.y = 0.0;
	else:
		motion.y += GRAVITY*delta;
	
	if position.y > world_limit:
		Global.GameState.end_game();
	
func jump():
	if Input.is_action_pressed("ui_up") && is_on_floor():
		motion.y = JUMP_SPEED;
		Global.jump_sfx.play();

func boost():
	motion.y = JUMP_SPEED*JUMP_BOOST;
	move_and_slide(motion, UP);

func run():
	if Input.is_action_pressed("ui_right") and not Input.is_action_pressed("ui_left"):
		motion.x = SPEED;
	elif Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		motion.x = -SPEED;
	else:
		motion.x = 0;

func hurt():
	if motion.y >= 0:
		motion.y = JUMP_SPEED/1.25;
	else:
		motion.y = 0;
	move_and_slide(motion, UP);

func play_animation(anim_name: String) -> void:
		$AnimationPlayer.play(anim_name);
