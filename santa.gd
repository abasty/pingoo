extends Area2D

@export var speed = 240
var target = Vector2.ZERO

func _ready():
	target = position

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	var collider = null

	if target == position:
		velocity.y = Input.get_axis("ui_up", "ui_down")
		velocity.x = Input.get_axis("ui_left", "ui_right")
		if velocity.x != 0:
			velocity.y = 0
			if velocity.x < 0:
				$AnimatedSprite2D.animation = "move-left"
				collider = $LeftRay.get_collider()
			else:
				$AnimatedSprite2D.animation = "move-right"
				collider = $RightRay.get_collider()
			# end if
		# end if
		if velocity.y != 0:
			if velocity.y < 0:
				$AnimatedSprite2D.animation = "move-up"
				collider = $UpRay.get_collider()
			else:
				$AnimatedSprite2D.animation = "move-down"
				collider = $DownRay.get_collider()
			# end if
		# end if
		if collider == null:
			target = position + velocity * 40
		# end if
	# end if

	velocity = (target - position).normalized()

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play()
		position += (velocity * speed * delta).limit_length((target - position).length())
		if position.is_equal_approx(target):
			position = target
		# end if
	else:
		$AnimatedSprite2D.frame = 0
		$AnimatedSprite2D.stop()
	# end if

# end func _process
