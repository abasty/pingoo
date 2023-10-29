extends Node2D

var tree_scene = preload("res://tree.tscn")
var block_scene = preload("res://ice_block.tscn")

func add_scene_child(scene, c: int, l: int):
	var instance = scene.instantiate()
	instance.position = Vector2(c * 40, l * 40)
	add_child(instance)

func add_tree_child(c: int, l: int):
	add_scene_child(tree_scene, c, l)

func add_block_child(c: int, l: int):
	add_scene_child(block_scene, c, l)

func _ready():
	for i in range(20):
		add_tree_child(i, 0)
		add_tree_child(i, 19)
	for i in range(1, 19):
		add_tree_child(0, i)
		add_tree_child(19, i)
	for l in range(1, 19, 2):
		for c in range(1, 19, 2):
			add_block_child(c, l)
			match randi() % 5:
				0,1: if c != 1: add_block_child(c, l + 1)
				2,3: if l != 1: add_block_child(c + 1, l)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
