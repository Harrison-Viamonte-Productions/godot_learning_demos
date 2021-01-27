extends Area2D

export (int) var speed
var velocity = Vector2.ZERO

func _ready():
	$VisibilityNotifier2D.connect("screen_exited", self, "_on_screen_exited")
	connect("body_entered", self, "_on_body_entered")

func start(pos, dir):
	position = pos
	rotation = dir
	velocity = Vector2(speed, 0).rotated(dir)

func _process(delta):
	position+= velocity*delta

func _on_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group('rocks'):
		body.explode()
		queue_free()
