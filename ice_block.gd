extends Area2D

enum State { IDLE, MOVING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var velocity = Vector2.ZERO
@onready var target = position

func move(delta):
	if target == position:
		if velocity.x < 0:
			$AnimatedSprite2D.animation = "move-left"
		elif velocity.x > 0:
			$AnimatedSprite2D.animation = "move-right"
		# end if
		if velocity.y < 0:
			$AnimatedSprite2D.animation = "move-up"
		elif velocity.y > 0:
			$AnimatedSprite2D.animation = "move-down"
		# end if

		var origin = global_position + Vector2(20, 20)
		var query = PhysicsRayQueryParameters2D.create(origin, origin + velocity * 40, -1, [self])
		query.collide_with_areas = true
		var collider = get_world_2d().direct_space_state.intersect_ray(query)

		if collider.is_empty():
			target = position + velocity * 40
		else:
			state = State.IDLE
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

func _process(delta):
	match state:
		State.IDLE: return
		State.MOVING: move(delta)

func push(v: Vector2):
	if state == State.IDLE:
		state = State.MOVING
		velocity = v
	# end if
