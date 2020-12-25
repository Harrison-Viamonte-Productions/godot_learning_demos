extends Node

var Player: Node2D;
var navigation;
var destinations;

#func angle_between_points(start: Vector2, end: Vector2):
#	var angle = Vector2(abs(start.x - end.x), abs(start.y - end.y)).normalized().angle_to();

# Asset Links - MUST BE CHANGED MANUALLY

var nightvision_on_sfx = "res://SFX/nightvision.wav";
var nightvision_off_sfx = "res://SFX/nightvision_off.wav";
