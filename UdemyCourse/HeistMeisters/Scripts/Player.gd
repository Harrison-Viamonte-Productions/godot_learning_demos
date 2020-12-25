extends "res://Scripts/Character.gd"

var motion: Vector2 = Vector2();
enum vision_modes {DARK, NIGHTVISION};
var vision_mode: int;

func _ready():
	Global.Player = self;
	$VisionTimer.connect("timeout", self, "on_VisionTimer_Timeout");
	vision_mode = vision_modes.DARK;

func _process(delta):
	update_motion(delta);
	move_and_slide(motion);

func _input(event):
	if !(event is InputEventKey):
		return;

	if event.is_action_pressed("ui_select"):
		toggle_torch();
	if event.is_action_pressed("ui_vision_mode_change") and $VisionTimer.is_stopped():
		cycle_vision_mode();

func cycle_vision_mode():
	if vision_mode == vision_modes.DARK:
		get_tree().call_group("interface", "NightVision_mode");
		vision_mode = vision_modes.NIGHTVISION;
	elif vision_mode == vision_modes.NIGHTVISION:
		get_tree().call_group("interface", "DarkVision_mode")
		vision_mode = vision_modes.DARK;
	$VisionTimer.start();

func on_VisionTimer_Timeout():
	$VisionTimer.stop();

func toggle_torch():
	$Torch.enabled = !$Torch.enabled;

func update_motion(delta):
	
	look_at(get_global_mouse_position());
	
	if Input.is_action_pressed("ui_up") and not Input.is_action_just_pressed("ui_down"):
		motion.y = clamp((motion.y-SPEED), -MAX_SPEED, 0);
	elif Input.is_action_pressed("ui_down") and not Input.is_action_just_pressed("ui_up"):
		motion.y = clamp((motion.y+SPEED), 0, MAX_SPEED);
	else:
		motion.y = lerp(motion.y, 0, FRICTION);
	
	if Input.is_action_pressed("ui_left") and not Input.is_action_just_pressed("ui_right"):
		motion.x = clamp((motion.x-SPEED), -MAX_SPEED, 0);
	elif Input.is_action_pressed("ui_right") and not Input.is_action_just_pressed("ui_left"):
		motion.x = clamp((motion.x+SPEED), 0, MAX_SPEED);
	else:
		motion.x = lerp(motion.x, 0, FRICTION);
