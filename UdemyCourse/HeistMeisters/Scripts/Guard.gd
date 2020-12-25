extends "res://Scripts/PlayerDetection.gd"

var motion = Vector2();
var possible_destinations = [];
var path = [];
var destination = Vector2();
var destination_interpolated = Vector2();

const TURN_SPEED = 2.0; #2 seconds for 2*PI complete turn

var on_wall_time = 1.0; #How many time on wall before changing path
export var walk_slowdown: float = 0.5;
export var nav_stop_threshold: int = 5;
onready var navigation = Global.navigation;
onready var available_destinations = Global.destinations;

func _ready():
	$Timer.connect("timeout", self, "on_Timeout");
	destination_interpolated = self.global_position;	
	possible_destinations = available_destinations.get_children();
	make_path();
	
func _physics_process(delta):
	navigate(delta);
	
func navigate(delta):
	var distance_to_destination = position.distance_to(path[0]);
	destination = path[0];

	if distance_to_destination > nav_stop_threshold:
		move(delta);
	else:
		update_path();

func move(delta):
	#var tmp = destination_interpolated.linear_interpolate(destination, delta*0.4);
	look_at_interpolated(destination, TURN_SPEED, delta);
	
	motion = (destination-position).normalized()*MAX_SPEED*walk_slowdown;
	
	if is_on_wall():
		if on_wall_time > 0.0:
			on_wall_time -= delta;
		else:
			make_path();
	else:
		if on_wall_time < 1.0:
			on_wall_time += delta/4.0;
	
	move_and_slide(motion);

func make_path():
	randomize();
	on_wall_time = 1.0;
	var next_destination: Node2D = possible_destinations[randi() % possible_destinations.size()];
	path = navigation.get_simple_path(global_position, next_destination.global_position, false);

func update_path():
	if path.size() == 1:
		if $Timer.is_stopped():
			$Timer.start();
	else:
		path.remove(0);

func on_Timeout():
	$Timer.stop();
	make_path();

func look_at_interpolated(look_pos: Vector2, look_speed: float, time_step: float = 1.0):
	var deg_step: float = (360.0/look_speed)*time_step;
	var angle_to_point = rad2deg(self.global_position.angle_to_point(look_pos)+PI);
	
	angle_to_point = fmod(angle_to_point, 360.0);
	if (angle_to_point > 180.0):
		angle_to_point -= 360.0;
	self.global_rotation_degrees = fmod(self.global_rotation_degrees, 360.0);
	
	if (self.global_rotation_degrees > (angle_to_point+deg_step)):
		if abs(self.global_rotation_degrees-angle_to_point) <= 180.0: #Ensure shortest angle
			self.global_rotation_degrees -= deg_step;
		else:
			self.global_rotation_degrees += deg_step;
	elif self.global_rotation_degrees < (angle_to_point-deg_step):
		if abs(self.global_rotation_degrees-angle_to_point) <= 180.0:  #Ensure shortest angle
			self.global_rotation_degrees += deg_step;
		else:
			self.global_rotation_degrees -= deg_step;
	else:
		self.global_rotation_degrees = angle_to_point;
