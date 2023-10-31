extends Area2D

enum State { IDLE, MOVING, BREAKING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var velocity = Vector2.ZERO
@onready var target = position
var ray

func _ready():
	ray = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, -1, [self])
	ray.collide_with_areas = true
	$AnimatedSprite2D.animation = "idle"
# end func _ready

func move(delta):
	if target == position:
		if velocity.x < 0:
			$AnimatedSprite2D.animation = "left"
		elif velocity.x > 0:
			$AnimatedSprite2D.animation = "right"
		# end if
		if velocity.y < 0:
			$AnimatedSprite2D.animation = "idle"
		elif velocity.y > 0:
			$AnimatedSprite2D.animation = "idle"
		# end if

		ray.from = global_position + Vector2(20, 20)
		ray.to = ray.from + velocity * 40
		var collider = get_world_2d().direct_space_state.intersect_ray(ray)

		if collider.is_empty():
			target = position + velocity * 40
		else:
			state = State.IDLE
			$AnimatedSprite2D.animation = "idle"
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
# end func move

func _process(delta):
	match state:
		State.IDLE: return
		State.MOVING: move(delta)
	# end match
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
			$AnimatedSprite2D.animation = "destroy"
			$AnimatedSprite2D.play()

		# end if
	# end if
# end func push


func _on_animated_sprite_2d_animation_finished():
	queue_free()
