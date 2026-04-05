extends Node2D

@onready var digits = [ $p0, $p1, $p2, $p3, $p4, $p5 ]

@export var initialize_from_game_state = true
@export var write_to_game_state_on_add = true
@export var initial_value = 0

const speed = 300
const DIGIT_HEIGHT = 26
const DIGIT_DISPLAY_WIDTH = 12
const DIGIT_DISPLAY_HEIGHT = 16

var target_value = 0
var value = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if material is ShaderMaterial:
		material = material.duplicate()
	# end if

	if initialize_from_game_state:
		var game_state = get_node_or_null("/root/GameState")
		if game_state != null:
			target_value = game_state.current_score
			set_display_value(game_state.current_score)
			return
		# end if
	# end if

	set_value(initial_value)
# end func _ready

func add(score):
	target_value += score
	if write_to_game_state_on_add:
		var game_state = get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.add_score(score)
		# end if
	# end if
# end func add

func set_target_value(new_value):
	target_value = maxi(0, new_value)
# end func set_target_value

func set_value(new_value):
	target_value = maxi(0, new_value)
	set_display_value(target_value)
# end func set_value

func set_tint_color(tint: Color):
	if material is ShaderMaterial:
		material.set_shader_parameter("tint_color", tint)
	else:
		modulate = tint
	# end if
# end func set_tint_color

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
