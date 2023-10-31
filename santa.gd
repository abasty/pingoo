extends Area2D

@export var speed = 240
@onready var target = position
var ray

func _ready():
	ray = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, -1, [self])
	ray.collide_with_areas = true

func _process(delta):
	var velocity = Vector2.ZERO

	if target == position:
		velocity.y = Input.get_axis("ui_up", "ui_down")
		velocity.x = Input.get_axis("ui_left", "ui_right")
		if velocity.x != 0:
			velocity.y = 0
			if velocity.x < 0:
				$AnimatedSprite2D.animation = "move-left"
			else:
				$AnimatedSprite2D.animation = "move-right"
			# end if
		# end if
		if velocity.y != 0:
			if velocity.y < 0:
				$AnimatedSprite2D.animation = "move-up"
			else:
				$AnimatedSprite2D.animation = "move-down"
			# end if
		# end if

		ray.from = global_position + Vector2(20, 20)
		ray.to = ray.from + velocity * 40
		var collider_dict = get_world_2d().direct_space_state.intersect_ray(ray)

		if collider_dict.is_empty():
			target = position + velocity * 40
		else:
			var collider = collider_dict.get("collider")
			if collider.has_method("push") and Input.is_key_pressed(KEY_SPACE):
				collider.push(velocity)
			# end if
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
