extends Node2D

var tree_scene = preload("res://tree.tscn")

func _ready():
	var tree
	for i in range(20):
		tree = tree_scene.instantiate()
		tree.position = Vector2(i * 40, 0)
		add_child(tree)
		tree = tree_scene.instantiate()
		tree.position = Vector2(i * 40, 40 * 19)
		add_child(tree)
	for i in range(1, 19):
		tree = tree_scene.instantiate()
		tree.position = Vector2(0, i * 40)
		add_child(tree)
		tree = tree_scene.instantiate()
		tree.position = Vector2(40 * 19, i * 40)
		add_child(tree)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
