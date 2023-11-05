extends Node2D

var tree_scene = preload("res://tree.tscn")
var block_scene = preload("res://ice_block.tscn")
var gift_scene = preload("res://gift.tscn")

var blocks = []
var gifts = []

func add_scene_child(scene, c: int, l: int):
	var instance = scene.instantiate()
	instance.position = Vector2(c * 40, l * 40)
	add_child(instance)
	return instance
# end func add_scene_child

func add_tree_child(c: int, l: int):
	add_scene_child(tree_scene, c, l)
# end func add_tree_child

func add_gift_child(c: int, l: int):
	var instance = add_scene_child(gift_scene, c, l)
	# Connect the gift_moved signal to the _on_gift_moved function
	instance.connect("gift_moved", Callable(self, "_on_gift_moved"))
	gifts.append(instance)
# end func add_gift_child

func add_block_child(c: int, l: int):
	var block = add_scene_child(block_scene, c, l)
	# Append the block to the list of blocks if it is not on the border
	if c > 1 and l > 1 and c < 19 and l < 19:
		blocks.append(block)
	# end if
# end func add_block_child

func _ready():
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
# end func _ready

func _on_gift_moved():
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
	# end if
# end func _on_gift_moved
