extends Area2D

enum State { IDLE, MOVING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var velocity = Vector2.ZERO
@onready var target = position
@onready var sprite = $AnimatedSprite2D
@onready var ray = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, -1, [self])

func _ready():
	ray.collide_with_areas = true
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
		position += (velocity * speed * delta).limit_length((target - position).length())
		if position.is_equal_approx(target):
			position = target
		# end if
	else:
		# Test if all gifts are on the same line using the "all" method
		var gifts = get_tree().get_nodes_in_group("gifts")
		var first = gifts[0].global_position
		if gifts.all(func(gift): return gift.global_position.y == first.y):
			# Sort gifts by x position
			gifts.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
			# Test if each gift is 40 pixels away from the previous one
			var aligned = true
			for i in range(1, gifts.size()):
				if gifts[i].global_position.x - gifts[i - 1].global_position.x != 40:
					aligned = false
					break
				# end if
			# end for
			print(aligned)
			if aligned:
				print("WIN !")
			# end if
		elif gifts.all(func(gift): return gift.global_position.x == first.x):
			# Sort gifts by y position
			gifts.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
			# Test if each gift is 40 pixels away from the previous one
			var aligned = true
			for i in range(1, gifts.size()):
				if gifts[i].global_position.y - gifts[i - 1].global_position.y != 40:
					aligned = false
					break
				# end if
			# end for
			print(aligned)
			if aligned:
				print("WIN !")
			# end if
		# end if
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
	# end if
# end func push
