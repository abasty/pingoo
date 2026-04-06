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
		# Check for monsters on this tile and push them ahead
		_push_monsters_on_this_tile()

		# Normal raycast: advance if free, stop otherwise.
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

func _push_monsters_on_this_tile() -> void:
	"""Push any monster on this tile one tile ahead in the gift's movement direction."""
	if velocity == Vector2.ZERO:
		return
	# end if

	var push_target: Vector2 = position + velocity * 40

	for monster in get_tree().get_nodes_in_group("monsters"):
		if monster.position.distance_to(position) < 20.0:
			# Monster is on this tile. Push it one tile ahead.
			if _is_position_free_for_monster(push_target):
				# Free space ahead — move the monster there
				monster.position = push_target
			else:
				# Obstacle ahead — crush the monster
				monster.queue_free()
				_crush_monster_award_bonus(1)
			# end if
		# end if
	# end for
# end func _push_monsters_on_this_tile

func _is_position_free_for_monster(world_pos: Vector2) -> bool:
	"""Check if a position is free for a monster (no trees, ice blocks, or gifts)."""
	# Check for trees
	for tree in get_tree().get_nodes_in_group("trees"):
		if tree.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for

	# Check for ice blocks
	for block in get_tree().get_nodes_in_group("ice_blocks"):
		if block.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for

	# Check for other gifts
	for other_gift in get_tree().get_nodes_in_group("gifts"):
		if other_gift != self and other_gift.position.distance_to(world_pos) < 1.0:
			return false
		# end if
	# end for

	return true
# end func _is_position_free_for_monster

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
