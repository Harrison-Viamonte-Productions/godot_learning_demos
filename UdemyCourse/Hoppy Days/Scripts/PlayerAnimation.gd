extends AnimatedSprite

func update_anim(motion):
	if motion.x > 0:
		play("run");
		flip_h = false;
	elif motion.x < 0:
		play("run");
		flip_h = true;
	elif motion.y < 0:
		play("jump");
	else:
		play("idle");
		flip_h = false;
