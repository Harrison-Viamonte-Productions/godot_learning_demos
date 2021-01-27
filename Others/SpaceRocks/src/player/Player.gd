extends RigidBody2D

enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = null

export (int) var engine_power
export (int) var spin_power
export (PackedScene) var Bullet
export (float) var fire_rate

var can_shoot: bool = true

var thrust: Vector2 = Vector2.ZERO
var rotation_dir: int = 0
var screensize: Vector2 = Vector2.ZERO
var radius: int = 0

signal dead
signal shoot(bullet, pos, dir)
signal lives_changed(new_lives)
var lives: int = 0 setget set_lives

#Exists only to avoid bug related to CollisionShape2D disabled and set_applied_torque not working!
onready var init_collision_layer: int = self.collision_layer
onready var init_collision_mask: int = self.collision_mask

func set_lives(value):
	lives = value
	emit_signal("lives_changed", value)

func start():
	$Sprite.show()
	self.lives = 3 #self. is necessary in order to call the setget set_lives' function!!
	change_state(ALIVE)

func _ready() -> void:
	$GunTimer.connect("timeout", self, "_on_GunTimer_timeout")
	$InvulnerabilityTimer.connect("timeout", self, "_on_InvulnerabilityTimer_timeout")
	$Explosion/AnimationPlayer.connect("animation_finished", self, "_on_ExplosionAnim_finished")
	connect("body_entered", self, "_on_body_entered")
	screensize = get_viewport().get_visible_rect().size
	$GunTimer.wait_time = fire_rate
	radius = $CollisionShape2D.shape.radius
	change_state(INIT)

func change_state(new_state) -> void:
	match new_state:
		INIT:
			$Sprite.modulate.a = 0.5
			#$CollisionShape2D.set_deferred("disabled", true)
			disable_collision()
		ALIVE:
			$Sprite.modulate.a = 1.0
			#$CollisionShape2D.set_deferred("disabled", false)
			enable_collision()
		INVULNERABLE:
			$Sprite.modulate.a = 0.5
			#$CollisionShape2D.set_deferred("disabled", true)
			disable_collision()
			$InvulnerabilityTimer.start()
		DEAD:
			$Sprite.hide()
			#$CollisionShape2D.set_deferred("disabled", true)
			disable_collision()
			linear_velocity = Vector2.ZERO
			emit_signal("dead")
	
	state = new_state

func disable_collision() -> void:
	collision_layer = 0
	collision_mask = 0

func enable_collision() -> void:
	collision_layer = init_collision_layer
	collision_mask = init_collision_mask

func _process(delta) -> void:
	get_input()

func get_input() -> void:
	thrust = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thrust"):
		thrust = Vector2(engine_power, 0)
	rotation_dir = 0
	if Input.is_action_pressed("rotate_right"):
		rotation_dir+=1
	if Input.is_action_pressed("rotate_left"):
		rotation_dir-=1
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func shoot() -> void:
	if state == INVULNERABLE:
		return
	emit_signal("shoot", Bullet, $Muzzle.global_position, rotation) #Better approach than using get_parent()....
	can_shoot = false
	$GunTimer.start()

func _on_GunTimer_timeout():
	can_shoot = true

func _on_InvulnerabilityTimer_timeout():
	change_state(ALIVE)

func _on_ExplosionAnim_finished( anim_name ):
	$Explosion.hide()

func _on_body_entered( body ):
	if body.is_in_group('rocks'):
		body.explode()
		killed()

func killed():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	self.lives -= 1
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)

#In rigidbody, change physics stuff here instead of _physics_process
func _integrate_forces(physics_state):
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(spin_power*rotation_dir)
	var xform = physics_state.get_transform()
	if xform.origin.x > screensize.x+radius:
		xform.origin.x = 0-radius
	if xform.origin.x < 0-radius:
		xform.origin.x = screensize.x+radius
	if xform.origin.y > screensize.y+radius:
		xform.origin.y = 0-radius
	if xform.origin.y < 0-radius:
		xform.origin.y = screensize.y+radius
	
	physics_state.set_transform(xform)

