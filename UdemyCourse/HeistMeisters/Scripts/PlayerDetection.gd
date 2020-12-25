extends "res://Scripts/Character.gd"

const FOV_TOLERANCE: float = 21.0;
const MAX_DETECTION_RANGE: float = 320.0;

onready var Player = Global.Player
onready var base_Torch_Color: Color = $Torch.color;

func _ready():
	add_to_group("NPC");

func _process(delta):
	if Player_is_in_FOV_TOLERANCE() and Player_is_in_LOS():
		$Torch.color = Color.red;
	else:
		$Torch.color = base_Torch_Color;

func Player_is_in_FOV_TOLERANCE() -> bool:
	var NPC_facing_direction: Vector2 = Vector2(1,0).rotated(global_rotation);
	var direction_to_Player: Vector2 = (Player.global_position - global_position).normalized();
	if abs(direction_to_Player.angle_to(NPC_facing_direction)) < deg2rad(FOV_TOLERANCE):
		return true;
	else:
		return false;

func Player_is_in_LOS():
	var space = get_world_2d().direct_space_state;
	var LOS_obstacle = space.intersect_ray(global_position, Player.global_position, [self], collision_mask);
	var distance_to_player = Player.global_position.distance_to(global_position);
	var Player_in_range = distance_to_player < MAX_DETECTION_RANGE;
	
	if LOS_obstacle.collider == Player && Player_in_range:
		return true;
	else:
		return false;

func NightVision_mode():
	$Torch.enabled = false;

func DarkVision_mode():
	$Torch.enabled = true;
