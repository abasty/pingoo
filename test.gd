extends Node2D

var tree_scene = preload("res://tree.tscn")
var block_scene = preload("res://ice_block.tscn")
var gift_scene = preload("res://gift.tscn")
var end_menu_scene = preload("res://end_menu.tscn")

var blocks = []
var gifts = []
var trees = []
var end_menu = null
var level_completed = false

func add_scene_child(scene, c: int, l: int):
	var instance = scene.instantiate()
	instance.position = Vector2(c * 40, l * 40)
	$Board.add_child(instance)
	return instance
# end func add_scene_child

func add_tree_child(c: int, l: int):
	trees.append(add_scene_child(tree_scene, c, l))
# end func add_tree_child

func add_gift_child(c: int, l: int):
	var instance = add_scene_child(gift_scene, c, l)
	# Connect the gift_moved signal to the _on_gift_moved function
	instance.connect("gift_moved", Callable(self, "_on_gift_moved"))
	gifts.append(instance)
# end func add_gift_child

func add_block_child(c: int, l: int):
	var block = add_scene_child(block_scene, c, l)
	block.connect("add_score", $Hud/Score.add)
	# Append the block to the list of blocks if it is not on the border
	if c > 1 and l > 1 and c < 18 and l < 18:
		blocks.append(block)
	# end if
# end func add_block_child

func _ready():
	var game_state = get_node("/root/GameState")
	game_state.has_started_game = true
	seed(game_state.current_level)
	$Hud/LevelLabel.text = "Niveau: %d" % game_state.current_level
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

	# Make sure the score is on top of everything
	$Hud/HudBar.set_z_index(1)
	$Hud/Score.set_z_index(1)
	$Hud/LevelLabel.set_z_index(1)

	# Instantiate end-of-game overlay
	end_menu = end_menu_scene.instantiate()
	add_child(end_menu)
# end func _ready

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if end_menu.visible:
			end_menu.hide()
		else:
			end_menu.show_pause()
	# end if
# end func _unhandled_input

func _on_gift_moved():
	if level_completed:
		return
	# end if

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
		level_completed = true
		var game_state = get_node("/root/GameState")
		game_state.next_level()

		# Animate trees
		for tree in trees:
			tree.bling()
		# end for
		$JingleBells.stop()
		$Music.play()
		# Update score
		$Hud/Score.add(1000)
		end_menu.show_win()
	# end if
# end func _on_gift_moved
