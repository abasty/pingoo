extends Node2D

@onready var digits = [ $p0, $p1, $p2, $p3, $p4, $p5 ]

const speed = 600
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
# end func _ready

func _process(delta):
	if value != target_value:
		animate(delta)
	# end if
# end func _process

func animate(delta):
	# Set rolling for all digits
	var rolling = []
	for i in range(digits.size()):
		rolling.append(i == 0)
	# end for

	# Get digit values
	var digit_values = []
	for i in range(digits.size()):
		digit_values.append(floor((digits[i].region_rect.position.y / DIGIT_HEIGHT)))
	# end for

	# for each digit, animate it to the next value
	for i in range(digits.size()):
		if !rolling[i]:
			continue
		# end if
		var digit = digits[i]
		digit.region_rect.position.y += speed * delta

		# If digit has rolled over, reset it and roll the next digit
		if digit.region_rect.position.y >= 10 * DIGIT_HEIGHT:
			digit.region_rect.position.y -= 10 * DIGIT_HEIGHT
			if i < digits.size() - 1: rolling[i + 1] = true
		# end if

		# If digit is not the first digit, compute rolling
		if i != 0:
			var digit_value = floor((digit.region_rect.position.y / DIGIT_HEIGHT))
			# If digit value has changed, stop rolling
			if digit_value != digit_values[i]:
				rolling[i] = false
				digit.region_rect.position.y = digit_value * DIGIT_HEIGHT
			# end if
		# end if
	# end for
# end func animate
