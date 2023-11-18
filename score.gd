extends Node2D

@onready var digits = [ $p0, $p1, $p2, $p3, $p4, $p5 ]
@onready var rollings = [ false, false, false, false, false, false ]

const speed = 200
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
	target_value = 123
# end func _ready

func _process(delta):
	if value != target_value:
		animate(delta)
	# end if
# end func _process

func animate(delta):
	rollings[0] = true

	# for each digit, animate it to the next value
	for i in range(digits.size()):
		if !rollings[i]:
			continue
		# end if

		var digit = digits[i]
		var digit_value = floor(digit.region_rect.position.y / DIGIT_HEIGHT)

		digit.region_rect.position.y += speed * delta

		if digit.region_rect.position.y >= 10 * DIGIT_HEIGHT:
			digit.region_rect.position.y -= 10 * DIGIT_HEIGHT
			if i < digits.size() - 1: rollings[i + 1] = true
		# end if

		# if the digit is not the first digit, and it has reached its target value, stop rolling
		var new_digit_value = floor(digit.region_rect.position.y / DIGIT_HEIGHT)
		if i != 0 and new_digit_value != digit_value:
			rollings[i] = false
			digit.region_rect.position.y = new_digit_value * DIGIT_HEIGHT
		# end if
	# end for
# end func animate
