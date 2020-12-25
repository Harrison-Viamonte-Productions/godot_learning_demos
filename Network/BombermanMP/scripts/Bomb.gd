extends StaticBody2D

const EXPLOSION_RADIUS: int = 2;
onready var explosion_scene = preload("res://scenes/Explosion.tscn");
onready var tilemap: TileMap = get_node("/root/Arena/TileMap");
onready var tile_solid_id = tilemap.tile_set.find_tile_by_name("SolidBrick");
onready var tile_brekeable_id = tilemap.tile_set.find_tile_by_name("BrekeableBrick");

var _owner = null;

func _ready():
	$EnableCollisionTimer.connect("timeout", self, "_on_EnableCollisionTimer_timeout");
	$AnimationPlayer.connect("animation_finished", self, "_on_AnimationPlayer_anim_finished");

func _on_EnableCollisionTimer_timeout():
	get_node("CollisionShape2D").disabled = false;

func propagate_explosion(centerpos, propagation):
	var border_explosion = null;
	var center_tile_pos = tilemap.world_to_map(centerpos);
	var explosions = [];
	for i in range(1, EXPLOSION_RADIUS+1):
		var tilepos = center_tile_pos + propagation*i;
		if tilemap.get_cellv(tilepos) != tile_solid_id:
			#boom
			var explosion = explosion_scene.instance();
			explosion._owner = _owner;
			explosion.position = tilemap.centered_world_pos_from_tilepos(tilepos);
			explosion.direction = propagation;
			#bY DEFAULT SIDE, but could be also SIDE_BORDER
			explosion.type = explosion.SIDE;
			border_explosion = explosion;
			
			#Don't add the explosion to the scene now given
			# we don't know yet it type
			
			explosions.append(explosion);
			if tilemap.get_cellv(tilepos) == tile_brekeable_id:
				break; #break just one
		else:
			#Explosion was stopped by a solid block
			break;
	
	if border_explosion:
		border_explosion.type = border_explosion.SIDE_BORDER;
	
	#All explosions are ready, add them to the scene
	
	for explosion in explosions:
		get_parent().add_child(explosion);

func _on_AnimationPlayer_anim_finished(anim_name: String):
	#Make the bomb blow up at the end of the animation.
	#First, set a center explosion at the bomb position
	
	var center_explosion = explosion_scene.instance();
	center_explosion._owner = _owner;
	center_explosion.position = position;
	center_explosion.type = center_explosion.CENTER;
	get_parent().add_child(center_explosion);
	
	# Propagate the explosion by starting where the bomb was
	# and go away from it in straight vertical and horizontal lines
	propagate_explosion(position, Vector2(0, 1));
	propagate_explosion(position, Vector2(0, -1));
	propagate_explosion(position, Vector2(1, 0));
	propagate_explosion(position, Vector2(-1, 0));
	
	#Finally destroy the bomb node
	call_deferred("queue_free");
