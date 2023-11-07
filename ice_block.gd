extends Area2D

enum State { IDLE, MOVING, BREAKING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var velocity = Vector2.ZERO
@onready var target = position
@onready var sprite = $AnimatedSprite2D
@onready var ray = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, -1, [self])

func _ready():
	ray.collide_with_areas = true
	sprite.animation = "idle"
# end func _ready

func move(delta):
	if target == position:
		ray.from = global_position + Vector2(20, 20)
		ray.to = ray.from + velocity * 40
		var collider = get_world_2d().direct_space_state.intersect_ray(ray)

		if collider.is_empty():
			target = position + velocity * 40
		else:
			state = State.IDLE
		# end if
	# end if

	velocity = (target - position).normalized()

	if velocity != Vector2.ZERO:
		if velocity.x < 0:
			sprite.animation = "left"
			sprite.play()
		elif velocity.x > 0:
			sprite.animation = "right"
			sprite.play()
		# end if
		position += (velocity * speed * delta).limit_length((target - position).length())
		if position.is_equal_approx(target):
			position = target
		# end if
	else:
		sprite.pause()
		$Moving.stop()
	# end if
# end func move

func _process(delta):
	if state == State.MOVING:
		move(delta)
	# end if
# end func _process

func push(v: Vector2):
	if state == State.IDLE:
		state = State.MOVING
		velocity = v
		ray.from = global_position + Vector2(20, 20)
		ray.to = ray.from + velocity * 40
		var collider = get_world_2d().direct_space_state.intersect_ray(ray)
		if not collider.is_empty():
			state = State.BREAKING
			sprite.animation = "destroy"
			sprite.play()
			$Breaking.play()
		else:
			$Moving.play()
		# end if
	# end if
# end func push

func _on_animated_sprite_2d_animation_finished():
	queue_free()
# end func _on_animated_sprite_2d_animation_finished
