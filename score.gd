extends Node2D

@onready var digits = [ $p0, $p1, $p2, $p3, $p4, $p5 ]

const speed = 100
const DIGIT_HEIGHT = 26

var target_value = 0

var value:
	set(new_value):
		value = new_value
		for i in range(digits.size()):
			digits[i].region_rect = Rect2(0, new_value % 10 * DIGIT_HEIGHT, 12, 16)
			new_value /= 10
		# end for
	# end set
	get:
		return value
	# end get

# Called when the node enters the scene tree for the first time.
func _ready():
	value = 0
	target_value = 123456
# end func

func _process(delta):
	if value != target_value:
		animate(delta)
	# end if
# end func

func animate(delta):
	var target_value_copy = target_value
	var changed = false
	# for each digit, animate it to the target value
	for i in range(digits.size()):
		var digit = digits[i]
		var digit_value = floor(digit.region_rect.position.y / DIGIT_HEIGHT)
		var target_digit_value = target_value_copy % 10
		if digit_value != target_digit_value:
			changed = true
			digit.region_rect.position.y += speed * delta
			if digit.region_rect.position.y >= 10 * DIGIT_HEIGHT:
				digit.region_rect.position.y -= 10 * DIGIT_HEIGHT
			# end if
		# end if
		target_value_copy /= 10
	# end for
	if !changed:
		value = target_value
	# end if
# end func
