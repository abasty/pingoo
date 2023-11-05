extends Area2D

enum State { IDLE, BLING }

@onready var speed = 600
@onready var state = State.IDLE
@onready var target = position
@onready var sprite = $Sprite2D

func _ready():
	sprite.frame = randi() % 16
# end func _ready

func move(delta):
	if target == position:
		# If position.y is 0 and position.x is not 760, move right by 40 pixels
		if position.y == 0 and position.x < 760:
			target = position + Vector2(40, 0)
		# If position.x is 760 and position.y is not 760, move down by 40 pixels
		elif position.x == 760 and position.y < 760:
			target = position + Vector2(0, 40)
		# If position.y is 760 and position.x is not 0, move left by 40 pixels
		elif position.y == 760 and position.x > 0:
			target = position + Vector2(-40, 0)
		# If position.x is 0 and position.y is not 0, move up by 40 pixels
		elif position.x == 0 and position.y > 0:
			target = position + Vector2(0, -40)
		# end if
	# end if

	var velocity = (target - position).normalized()

	if velocity != Vector2.ZERO:
		position += (velocity * speed * delta).limit_length((target - position).length())
		if position.is_equal_approx(target):
			position = target
		# end if
	# end if
# end func move

func _process(delta):
	if state == State.BLING:
		move(delta)
	# end if
# end func _process

func bling():
	state = State.BLING
# end func _bling
