extends Node2D

@onready var digits = [ $p0, $p1, $p2, $p3, $p4, $p5 ]
const DIGIT_HEIGHT = 26

func set_value(value):
	for i in range(digits.size()):
		digits[i].region_rect = Rect2(0, value % 10 * DIGIT_HEIGHT, 12, DIGIT_HEIGHT)
		value /= 10
	# end for
# end func

# Called when the node enters the scene tree for the first time.
func _ready():
	set_value(0)
# end func
