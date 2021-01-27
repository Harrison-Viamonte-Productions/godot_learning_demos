extends RigidBody2D

var screensize: Vector2 = Vector2.ZERO
var size: int
var radius: int
var scale_factor: float = 0.2

signal exploded(_size, _radius, _pos, _vel)

func _ready():
	add_to_group('rocks')
	$Explosion/AnimationPlayer.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished")
func start(pos, vel, _size):
	position = pos
	size = _size
	mass = 1.5*size
	$Sprite.scale = Vector2(1,1)*scale_factor*size
	radius = int(scale_factor*size*$Sprite.texture.get_size().x/2)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	linear_velocity = vel
	angular_velocity = rand_range(-1.5, 1.5)
	
	$Explosion.scale = Vector2(0.75, 0.75)*size

func explode():
	layers = 0
	$Sprite.hide()
	$Explosion/AnimationPlayer.play("explosion")
	emit_signal("exploded", size, radius, position, linear_velocity)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

func _on_AnimationPlayer_animation_finished( name ):
	queue_free()

func _integrate_forces(physics_state):
	var xform = physics_state.get_transform()
	if xform.origin.x > screensize.x + radius:
		xform.origin.x = 0 - radius
	if xform.origin.x < 0 - radius:
		xform.origin.x = screensize.x + radius
	if xform.origin.y > screensize.y + radius:
		xform.origin.y = 0 - radius
	if xform.origin.y < 0 - radius:
		xform.origin.y = screensize.y + radius
	
	physics_state.set_transform(xform)
