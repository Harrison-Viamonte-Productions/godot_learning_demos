extends Sprite

onready var tilemap = get_node("/root/Arena/TileMap");
onready var animation: AnimationPlayer = $AnimationPlayer;

var _owner = null;
var direction = null;

#Explosion animation depends on this
enum{
	CENTER,
	SIDE,
	SIDE_BORDER
};
var type = CENTER;

func _ready():
	if type == CENTER:
		animation.play("explosion_center");
	elif type == SIDE:
		animation.play("explosion_side");
	else:
		animation.play("explosion_side_border");
	
	#Only center explosion is symetric, others must be rotated
	# according to their direction
	
	if direction:
		rotation = atan2(direction.y, direction.x);
	
	# Retrieve the tile hit by the explosion and flatten it to the ground
	var tile_pos = tilemap.world_to_map(position);
	var tile_background_id = tilemap.tile_set.find_tile_by_name("BackgroundBrick");
	tilemap.set_cellv(tile_pos, tile_background_id);

	$AnimationPlayer.connect("animation_finished", self, "_on_AnimationPlayer_anim_finished");
	
	if !is_network_master():
		return;
	
	for player in get_tree().get_nodes_in_group('players'):
		var playerpos = tilemap.world_to_map(player.position);
		if playerpos == tile_pos:
			player.rpc("damage", _owner.id);

func _on_AnimationPlayer_anim_finished( name ):
	# Explosion finished, remove the node
	queue_free();
