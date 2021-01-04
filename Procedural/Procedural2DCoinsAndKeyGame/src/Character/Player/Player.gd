extends "res://src/Character/Character.gd"

signal moved
signal dead
signal grabbed_key
signal win

func _ready():
	$Sprite.scale = Vector2(1, 1)
	$Sprite.rotation_degrees = 0
	connect("area_entered", self, "_on_Player_area_entered")

func _process(delta):
	if can_move:
		for dir in moves.keys():
			if Input.is_action_pressed(dir):
				if move(dir):
					$Footsteps.play()
					emit_signal('moved')

func _on_Player_area_entered( area ):
	if area.is_in_group('enemies'):
		area.hide()
		set_process(false)
		$CollisionShape2D.set_deferred('disabled', true)
		$Lose.play()
		$AnimationPlayer.play("die")
		yield($Lose, 'finished')
		emit_signal('dead')
		return
	if area.has_method('pickup'):
		area.pickup()
	if area.type == 'key_red':
		emit_signal('grabbed_key')
	if area.type == 'star':
		$Win.play()
		$CollisionShape2D.set_deferred('disabled', true)
		yield($Win, "finished")
		emit_signal('win')
