extends Area2D

@export var speed = 240 # How fast the player will move (pixels/sec).
var target = Vector2.ZERO
var entred_zones = [[], [], [], [], []] # Try to get them from childs

func _ready():
	target = position

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.

	if target == position:
		velocity.y = Input.get_axis("ui_up", "ui_down")
		velocity.x = Input.get_axis("ui_left", "ui_right")
		if velocity.x != 0:
			velocity.y = 0
			if velocity.x < 0:
				$AnimatedSprite2D.animation = "move-left"
			else:
				$AnimatedSprite2D.animation = "move-right"
			# end if
		else:
			if velocity.y < 0:
				$AnimatedSprite2D.animation = "move-up"
			else:
				$AnimatedSprite2D.animation = "move-down"
			# end if
		# edn if
		target = position + velocity * 40
	# end if

	velocity = (target - position).normalized()

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play()
		position += (velocity * speed * delta).limit_length((target - position).length())
		if position.is_equal_approx(target):
			position = target
		# end if
	else:
		$AnimatedSprite2D.frame = 0
		$AnimatedSprite2D.stop()
	# end if

# end func _process

func _on_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	print(area, " + ", local_shape_index)
# end func _on_area_shape_entered


func _on_area_shape_exited(area_rid, area, area_shape_index, local_shape_index):
	print(area, " - ", local_shape_index)
