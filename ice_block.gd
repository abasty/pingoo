extends Area2D

enum State { IDLE, MOVING, BREAKING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var velocity = Vector2.ZERO
@onready var target = position
@onready var sprite = $AnimatedSprite2D
@onready var ray = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO, -1, [self])

var contains_egg: bool = false

signal add_score

func _ready():
	add_to_group("ice_blocks")
	ray.collide_with_areas = true
	sprite.animation = "idle"
	# Check if this block contains an egg at level start
	var game_state = get_node_or_null("/root/GameState")
	if game_state != null:
		contains_egg = position in game_state.egg_containers
	# end if
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
		_check_monster_crush()
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
			add_score.emit(10)
			_handle_egg_destruction()
		else:
			$Moving.play()
		# end if
	# end if
# end func push

func _on_animated_sprite_2d_animation_finished():
	queue_free()
# end func _on_animated_sprite_2d_animation_finished

func hatch() -> void:
	"""Destroy this block when its egg hatches (animation + sound, no score penalty)."""
	if state == State.BREAKING:
		return
	# end if
	state = State.BREAKING
	sprite.animation = "destroy"
	sprite.play()
	$Breaking.play()
# end func hatch

func _handle_egg_destruction() -> void:
	"""Award bonus when an egg-containing block is destroyed."""
	if not contains_egg:
		return
	# end if

	var game_state = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	# end if

	game_state.eggs_destroyed += 1

	# Award bonus based on destruction tier
	var bonus: int = 0
	match game_state.eggs_destroyed:
		1: bonus = 200
		2: bonus = 300
		3: bonus = 500
		_: bonus = 0
	# end match

	if bonus > 0:
		add_score.emit(bonus)
	# end if
# end func _handle_egg_destruction

func _check_monster_crush() -> void:
	"""Check if this moving block is occupying any monsters' tiles and crush them all."""
	var block_tile = position / 40
	var monsters = get_tree().get_nodes_in_group("monsters")
	var crushed_in_this_frame: Array = []

	# Find all monsters on the block's tile
	for monster in monsters:
		var monster_tile = monster.get_tile_position()
		if block_tile.distance_to(monster_tile) < 0.5:
			crushed_in_this_frame.append(monster)
	# end for

	# Calculate crush multiplier based on count in this frame
	var crush_multiplier: int = crushed_in_this_frame.size()

	# Crush all found monsters and award bonuses (multiplied by crush count)
	for monster in crushed_in_this_frame:
		monster.queue_free()
		_crush_monster_award_bonus(crush_multiplier)
	# end for
# end func _check_monster_crush

func _crush_monster_award_bonus(multiplier: int = 1) -> void:
	"""Award score bonus for crushing a monster, multiplied by crush count in this push."""
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

	# Apply multiplier based on number of monsters crushed in this push
	bonus *= multiplier

	if bonus > 0:
		add_score.emit(bonus)
	# end if
# end func _crush_monster_award_bonus
