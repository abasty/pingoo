extends Area2D

signal gift_moved
signal add_score

enum State { IDLE, MOVING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var velocity = Vector2.ZERO
@onready var target = position
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
		gift_moved.emit()
	# end if
# end func move

func _process(delta):
	if state == State.MOVING:
		move(delta)
		_check_monster_crush()
	# end if
# end func _process

func _check_monster_crush() -> void:
	"""Check if this moving gift is overlapping any monsters' tiles and crush them."""
	var gift_tile = position / 40
	var monsters = get_tree().get_nodes_in_group("monsters")
	var crushed: Array = []
	for monster in monsters:
		if gift_tile.distance_to(monster.get_tile_position()) < 0.5:
			crushed.append(monster)
	# end for
	var multiplier: int = crushed.size()
	for monster in crushed:
		monster.queue_free()
		_crush_monster_award_bonus(multiplier)
	# end for
# end func _check_monster_crush

func _crush_monster_award_bonus(multiplier: int = 1) -> void:
	"""Award score bonus for crushing a monster with a gift."""
	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	# end if
	game_state.monsters_crushed += 1
	var bonus: int = 0
	match game_state.monsters_crushed:
		1: bonus = 200
		2: bonus = 300
		3: bonus = 500
		_: bonus = 0
	# end match
	bonus *= multiplier
	if bonus > 0:
		add_score.emit(bonus)
	# end if
# end func _crush_monster_award_bonus

func push(v: Vector2):
	if state == State.IDLE:
		state = State.MOVING
		velocity = v
	# end if
# end func push
