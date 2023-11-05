extends Area2D

signal level_ended

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
		# Get all gifts
		var gifts = get_tree().get_nodes_in_group("gifts")
		var coords = [7, 5, 9]
		var first = gifts[0].global_position
		# Test if all gifts are on the same line
		if gifts.all(func(gift): return gift.global_position.y == first.y):
			# Map gifts to their x position
			coords = gifts.map(func(gift): return gift.global_position.x / 40)
		# Test if all gifts are on the same column
		elif gifts.all(func(gift): return gift.global_position.x == first.x):
			# Map gifts to their y position
			coords = gifts.map(func(gift): return gift.global_position.y / 40)
		# end if
		# Test if all gifts join together in alignment
		coords.sort()
		first = coords[0]
		# Compute delta between each element and the first one
		coords = coords.map(func(coord): return coord - first)
		# Test if the elements are sequential
		if coords.all(func(coord): return coord == coords.find(coord)):
			print("**** ALIGNED ****")
			emit_signal("level_ended")
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
		emit_signal("level_ended")
	# end if
# end func push
