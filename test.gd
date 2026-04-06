extends Node2D

var tree_scene = preload("res://tree.tscn")
var block_scene = preload("res://ice_block.tscn")
var gift_scene = preload("res://gift.tscn")
var end_menu_scene = preload("res://end_menu.tscn")
var egg_indicator_scene = preload("res://egg_indicator.tscn")

var blocks = []
var gifts = []
var trees = []
var end_menu = null
var level_completed = false
var level_highscore_display = 0
var is_applying_time_bonus = false
var bonus_time_remaining = 0
var bonus_tick_accumulator = 0.0

const SCORE_DEFAULT_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const TIME_BONUS_TICK_SECONDS = 0.05
const RANK_COLORS = {
	1: Color(1.0, 0.85, 0.25, 1.0),
	2: Color(0.86, 0.9, 0.97, 1.0),
	3: Color(0.9, 0.62, 0.42, 1.0),
	4: Color(0.78, 0.9, 1.0, 1.0),
	5: Color(0.72, 0.88, 1.0, 1.0),
	6: Color(0.66, 0.86, 1.0, 1.0),
	7: Color(0.62, 0.84, 1.0, 1.0),
	8: Color(0.58, 0.82, 1.0, 1.0),
	9: Color(0.54, 0.8, 1.0, 1.0),
	10: Color(0.5, 0.78, 1.0, 1.0)
}

func add_scene_child(scene, c: int, l: int):
	var instance = scene.instantiate()
	instance.position = Vector2(c * 40, l * 40)
	$Board.add_child(instance)
	return instance
# end func add_scene_child

func add_tree_child(c: int, l: int):
	var tree_instance = add_scene_child(tree_scene, c, l)
	tree_instance.add_to_group("trees")
	trees.append(tree_instance)
# end func add_tree_child

func add_gift_child(c: int, l: int):
	var instance = add_scene_child(gift_scene, c, l)
	instance.add_to_group("gifts")
	# Connect the gift_moved signal to the _on_gift_moved function
	instance.connect("gift_moved", Callable(self, "_on_gift_moved"))
	gifts.append(instance)
# end func add_gift_child

func add_block_child(c: int, l: int):
	var block = add_scene_child(block_scene, c, l)
	block.add_to_group("ice_blocks")
	block.connect("add_score", $Hud/Score.add)
	# Append the block to the list of blocks if it is not on the border
	if c > 1 and l > 1 and c < 18 and l < 18:
		blocks.append(block)
	# end if
# end func add_block_child

func _ready():
	var game_state = get_node("/root/GameState")
	game_state.start_level()
	seed(game_state.current_level)
	$IntroSnow.setup([])
	var level_label = get_node_or_null("Hud/LevelLabel") as Label
	if level_label != null:
		level_label.text = "Niveau: %d" % game_state.current_level
	# end if
	_update_lives_label()
	_update_timer_label()
	level_highscore_display = _get_saved_level_highscore(game_state.current_level)
	_update_level_highscore_label()
	level_completed = false

	for i in range(20):
		add_tree_child(i, 0)
		add_tree_child(i, 19)
	# end for
	for i in range(1, 19):
		add_tree_child(0, i)
		add_tree_child(19, i)
	# end for
	for l in range(1, 19, 2):
		for c in range(1, 19, 2):
			add_block_child(c, l)
			match randi() % 5:
				0,1: if c != 1: add_block_child(c, l + 1)
				2,3: if l != 1: add_block_child(c + 1, l)
			# end match
		# end for
	# end for

	# Choose 3 blocks and change them into gifts
	for i in range(3):
		var block = blocks[randi() % blocks.size()]
		add_gift_child(block.position.x / 40, block.position.y / 40)
		block.queue_free()
		blocks.erase(block)
	# end for

	# Choose 5 blocks and change them into trees
	for i in range(5):
		var block = blocks[randi() % blocks.size()]
		add_tree_child(block.position.x / 40, block.position.y / 40)
		block.queue_free()
		blocks.erase(block)
	# end for

	# Select 3 blocks to contain eggs and spawn indicators
	_select_egg_containers()
	_spawn_egg_indicators()

	# Make sure the score is on top of everything
	$Hud/HudBar.set_z_index(1)
	$Hud/Score.set_z_index(1)
	$Hud/ScoreRankLabel.set_z_index(1)
	$Hud/LevelLabel.set_z_index(1)
	$Hud/LivesLabel.set_z_index(1)
	$Hud/LevelHighscoreScore.set_z_index(1)
	$Hud/TimerLabel.set_z_index(1)
	_update_live_hof_feedback()

	# Instantiate end-of-game overlay
	end_menu = end_menu_scene.instantiate()
	add_child(end_menu)
	end_menu.level_resumed.connect(_on_level_resumed)
# end func _ready

func _process(_delta):
	var game_state = get_node("/root/GameState")
	if is_applying_time_bonus:
		_process_time_bonus(_delta)
	elif not level_completed and not end_menu.visible:
		game_state.level_time_left = maxf(0.0, game_state.level_time_left - _delta)
		_update_timer_label()
		if game_state.level_time_left <= 0.0:
			_on_level_timeout()
		# end if
		# Update egg spawning
		_update_egg_spawning(_delta)
		# Check for monster collisions
		_check_monster_collisions()
	# end if

	if game_state.current_level_score > level_highscore_display:
		level_highscore_display = game_state.current_level_score
		_update_level_highscore_label()
	# end if
	_update_live_hof_feedback()
# end func _process

func _unhandled_input(event):
	if is_applying_time_bonus:
		return
	# end if

	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		_complete_level()
		return
	# end if

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_finish_run_and_return_to_menu()
		return
	# end if

	if event.is_action_pressed("ui_cancel") and not end_menu.visible:
		end_menu.show_pause()
	# end if
# end func _unhandled_input

func _complete_level():
	if level_completed:
		return
	# end if

	level_completed = true
	var game_state = get_node("/root/GameState")

	# Animate trees
	for tree in trees:
		tree.bling()
	# end for
	$Music.play()
	# Update score
	$Hud/Score.add(1000)
	bonus_time_remaining = maxi(0, int(floor(game_state.level_time_left)))
	game_state.level_time_left = float(bonus_time_remaining)
	_update_timer_label()
	if bonus_time_remaining > 0:
		is_applying_time_bonus = true
		bonus_tick_accumulator = 0.0
	else:
		_finalize_level_win()
	# end if
# end func _complete_level

func _process_time_bonus(delta):
	if not is_applying_time_bonus:
		return
	# end if

	bonus_tick_accumulator += delta
	while bonus_tick_accumulator >= TIME_BONUS_TICK_SECONDS and is_applying_time_bonus:
		bonus_tick_accumulator -= TIME_BONUS_TICK_SECONDS
		if bonus_time_remaining <= 0:
			_finalize_level_win()
			break
		# end if

		bonus_time_remaining -= 1
		var game_state = get_node("/root/GameState")
		game_state.level_time_left = float(bonus_time_remaining)
		$Hud/Score.add(10)
		_update_timer_label()

		if game_state.current_level_score > level_highscore_display:
			level_highscore_display = game_state.current_level_score
			_update_level_highscore_label()
		# end if

		if bonus_time_remaining <= 0:
			_finalize_level_win()
		# end if
	# end while
# end func _process_time_bonus

func _finalize_level_win():
	if not level_completed:
		return
	# end if
	is_applying_time_bonus = false
	bonus_tick_accumulator = 0.0

	var game_state = get_node("/root/GameState")
	if game_state.current_level_score > level_highscore_display:
		level_highscore_display = game_state.current_level_score
		_update_level_highscore_label()
	# end if
	_save_level_highscore(game_state.current_level)
	game_state.next_level()
	end_menu.show_win()
# end func _finalize_level_win

func _on_level_timeout():
	if level_completed:
		return
	# end if

	level_completed = true
	var game_state = get_node("/root/GameState")
	game_state.level_time_left = 0.0
	_update_timer_label()
	game_state.lose_life()
	_update_lives_label()
	game_state.abandon_level()
	_update_live_hof_feedback()

	if game_state.is_game_over():
		_submit_game_over_score_if_top10(game_state)
		end_menu.show_game_over()
	else:
		end_menu.show_fail(game_state.lives)
	# end if
# end func _on_level_timeout

func _on_gift_moved():
	if level_completed:
		return
	# end if

	var first = gifts[0].position
	# Test if all gifts are on the same row using local board coordinates.
	if gifts.all(func(gift): return is_equal_approx(gift.position.y, first.y)):
		var columns = gifts.map(func(gift): return int(round(gift.position.x / 40.0)))
		columns.sort()
		if columns[1] == columns[0] + 1 and columns[2] == columns[1] + 1:
			_complete_level()
		# end if
	# Test if all gifts are on the same column using local board coordinates.
	elif gifts.all(func(gift): return is_equal_approx(gift.position.x, first.x)):
		var rows = gifts.map(func(gift): return int(round(gift.position.y / 40.0)))
		rows.sort()
		if rows[1] == rows[0] + 1 and rows[2] == rows[1] + 1:
			_complete_level()
		# end if
	# end if
# end func _on_gift_moved

func _get_saved_level_highscore(level: int) -> int:
	var hall_of_fame = get_node("/root/HallOfFame")
	return hall_of_fame.get_level_highscore(level)
# end func _get_saved_level_highscore

func _update_level_highscore_label():
	var highscore_display = get_node_or_null("Hud/LevelHighscoreScore")
	if highscore_display != null and highscore_display.has_method("set_target_value"):
		highscore_display.set_target_value(level_highscore_display)
	# end if
# end func _update_level_highscore_label

func _update_lives_label():
	var game_state = get_node("/root/GameState")
	var lives_label = get_node_or_null("Hud/LivesLabel") as Label
	if lives_label != null:
		lives_label.text = "Vies: %d" % game_state.lives
	# end if
# end func _update_lives_label

func _update_timer_label():
	var game_state = get_node("/root/GameState")
	var timer_label = get_node_or_null("Hud/TimerLabel") as Label
	if timer_label == null:
		return
	# end if

	var seconds_left = maxi(0, int(ceil(game_state.level_time_left)))
	timer_label.text = "%3ds" % seconds_left
	if seconds_left <= 20:
		timer_label.modulate = Color(1.0, 0.55, 0.55)
	else:
		timer_label.modulate = Color(0.9, 0.95, 1.0)
	# end if
# end func _update_timer_label

func _save_level_highscore(level: int):
	var hall_of_fame = get_node("/root/HallOfFame")
	var game_state = get_node("/root/GameState")
	hall_of_fame.update_level_highscore(level, maxi(level_highscore_display, game_state.current_level_score))
# end func _save_level_highscore

func _finish_run_and_return_to_menu():
	var game_state = get_node("/root/GameState")
	_save_level_highscore(game_state.current_level)
	var hall_of_fame = get_node("/root/HallOfFame")
	hall_of_fame.submit_score(game_state.player_name, game_state.current_score, game_state.current_level)
	game_state.reset_game()
	get_tree().change_scene_to_file("res://menu.tscn")
# end func _finish_run_and_return_to_menu

func _update_live_hof_feedback():
	var game_state = get_node("/root/GameState")
	var hall_of_fame = get_node_or_null("/root/HallOfFame")
	if hall_of_fame == null:
		return
	# end if

	var rank := int(hall_of_fame.get_rank_for_score(game_state.current_score, game_state.current_level))
	var rank_label = get_node_or_null("Hud/ScoreRankLabel") as Label
	if rank_label != null:
		rank_label.text = "#%d" % rank if rank > 0 else ""
		rank_label.modulate = _get_color_for_rank(rank)
	# end if

	var score_display = get_node_or_null("Hud/Score")
	if score_display != null and score_display.has_method("set_tint_color"):
		score_display.set_tint_color(_get_color_for_rank(rank))
	# end if
# end func _update_live_hof_feedback

func _get_color_for_rank(rank: int) -> Color:
	if rank > 0 and RANK_COLORS.has(rank):
		return RANK_COLORS[rank]
	# end if
	return SCORE_DEFAULT_COLOR
# end func _get_color_for_rank

func _submit_game_over_score_if_top10(game_state):
	var hall_of_fame = get_node_or_null("/root/HallOfFame")
	if hall_of_fame == null:
		return
	# end if

	var rank := int(hall_of_fame.get_rank_for_score(game_state.current_score, game_state.current_level))
	if rank <= 0:
		return
	# end if

	hall_of_fame.submit_score(game_state.player_name, game_state.current_score, game_state.current_level)
# end func _submit_game_over_score_if_top10

func _select_egg_containers() -> void:
	"""Randomly select 3 ice blocks to contain eggs."""
	var game_state = get_node("/root/GameState")
	if blocks.size() < 3:
		return  # Safety check

	blocks.shuffle()
	game_state.egg_containers = [] as Array[Vector2]

	for i in range(3):
		var block = blocks[i]
		game_state.egg_containers.append(block.position)
		block.contains_egg = true
# end func _select_egg_containers

func _spawn_egg_indicators() -> void:
	"""Spawn visual egg indicator overlays for 3 seconds."""
	var game_state = get_node("/root/GameState")
	for pos in game_state.egg_containers:
		var indicator = egg_indicator_scene.instantiate()
		$Board.add_child(indicator)
		indicator.position = pos  # pos is already in Board-local coordinates
# end func _spawn_egg_indicators

func _update_egg_spawning(_delta) -> void:
	"""Check if the next egg should hatch and spawn a monster if so."""
	var game_state = get_node("/root/GameState")
	if not game_state.is_level_running:
		return

	var elapsed_time = game_state.LEVEL_TIME_SECONDS - game_state.level_time_left

	# Check if next egg should spawn
	if (elapsed_time >= game_state.next_egg_spawn_time and
		game_state.eggs_spawned < 3 - game_state.eggs_destroyed):

		# Spawn monster at the next egg container position
		_spawn_monster_at_egg()

		# Update counters
		game_state.last_hatch_time = elapsed_time
		game_state.eggs_spawned += 1

		# Schedule next egg
		if game_state.eggs_spawned < 3:
			game_state.next_egg_spawn_time += 10.0
# end func _update_egg_spawning

func _spawn_monster_at_egg() -> void:
	"""Instantiate a monster at the next available egg position."""
	var game_state = get_node("/root/GameState")
	if game_state.eggs_spawned >= game_state.egg_containers.size():
		return

	var monster_scene = load("res://monster.tscn")
	if monster_scene == null:
		push_error("Could not load monster.tscn")
		return

	var egg_pos = game_state.egg_containers[game_state.eggs_spawned]
	var monster = monster_scene.instantiate()
	monster.position = egg_pos  # set BEFORE add_child so _ready() sees correct position
	$Board.add_child(monster)
# end func _spawn_monster_at_egg

func _check_monster_collisions() -> void:
	"""Check if any monster occupies Santa's tile."""
	var game_state = get_node("/root/GameState")
	if not game_state.is_level_running:
		return

	var santa_tile = $Board/Santa.position / 40
	var monsters = get_tree().get_nodes_in_group("monsters")

	for monster in monsters:
		var monster_tile = monster.get_tile_position()
		if santa_tile.distance_to(monster_tile) < 0.5:
			# Collision!
			_on_monster_collision(monster)
			break
# end func _check_monster_collisions

func _on_level_resumed() -> void:
	"""Called when the player resumes after a monster collision."""
	level_completed = false
# end func _on_level_resumed

func _on_monster_collision(monster) -> void:
	"""Handle monster collision with Santa."""
	var game_state = get_node("/root/GameState")

	# Remove the monster
	monster.queue_free()

	# Lose a life
	game_state.lose_life()
	_update_lives_label()
	game_state.abandon_level()
	_update_live_hof_feedback()

	# Pause and show dialog
	game_state.is_level_running = false
	level_completed = true

	# If game is over, show game-over dialog
	if game_state.is_game_over():
		_submit_game_over_score_if_top10(game_state)
		end_menu.show_game_over()
	else:
		# Show fail dialog with monster-collision type
		end_menu.show_fail(game_state.lives, end_menu.FailureType.MONSTER_COLLISION)
	# end if
# end func _on_monster_collision

func _cleanup_level() -> void:
	"""Clear all dynamic objects (monsters, eggs) before loading a new level."""
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		monster.queue_free()
	# end for
# end func _cleanup_level
