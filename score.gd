extends Node2D

@onready var digits = [ $p0, $p1, $p2, $p3, $p4, $p5 ]

const speed = 300
const DIGIT_HEIGHT = 26
const DIGIT_DISPLAY_WIDTH = 12
const DIGIT_DISPLAY_HEIGHT = 16

var target_value = 0
var value = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_display_value(0)
# end func _ready

func add(score):
	target_value += score
# end func add

# set the value of the display
func set_display_value(new_value):
	value = new_value
	for i in range(digits.size()):
		digits[i].region_rect = Rect2(0, new_value % 10 * DIGIT_HEIGHT, DIGIT_DISPLAY_WIDTH, DIGIT_DISPLAY_HEIGHT)
		new_value /= 10
	# end for
# end func set_display_value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if value != target_value:
		animate(delta)
	# end if
# end func _process

func animate(delta):
	var tv = target_value
	var changed = false

	# for each digit, animate it to the next value
	for i in range(digits.size()):
		var digit = digits[i]
		var digit_value = floor(digit.region_rect.position.y / DIGIT_HEIGHT)
		if tv % 10 != digit_value:
			digit.region_rect.position.y += speed * delta
			if digit.region_rect.position.y >= 10 * DIGIT_HEIGHT:
				digit.region_rect.position.y -= 10 * DIGIT_HEIGHT
			# end if
			changed = true
		# end if
		tv /= 10
	# end for

	if not changed:
		set_display_value(target_value)
	# end if
# end func animate
