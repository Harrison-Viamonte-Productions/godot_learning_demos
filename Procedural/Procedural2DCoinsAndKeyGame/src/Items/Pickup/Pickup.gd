extends Area2D

var textures = {
	'coin': 'res://assets/coin.png',
	'key_red': 'res://assets/keyRed.png',
	'star': 'res://assets/star.png'
}

signal coin_pickup

var type: String

func init(_type, pos):
	$Sprite.texture = load(textures[_type])
	type = _type
	position = pos

func _ready():
	$Tween.interpolate_property($Sprite, 'scale', Vector2(1, 1), Vector2(3, 3), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Sprite, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.connect("tween_completed", self, '_on_Tween_completed')

func pickup():
	match type:
		'coin':
			emit_signal("coin_pickup", 1)
			$CoinPickup.play()
		'key_red':
			$KeyPickup.play()
	$CollisionShape2D.set_deferred('disabled', true)
	$Tween.start()

func _on_Tween_completed(object, key):
	queue_free()
