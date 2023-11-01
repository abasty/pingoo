extends Area2D

func _ready():
	$Sprite2D.frame = randi() % 16
# end func
