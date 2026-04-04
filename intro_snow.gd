extends Control

const AMBIENT_FLAKE_TARGET = 180
const SPAWN_RATE = 42.0

var rng = RandomNumberGenerator.new()
var flakes = []
var spawn_accumulator = 0.0
var menu_buttons: Array[Button] = []
var button_piles := {}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
# end func _ready

func setup(_buttons: Array):
	menu_buttons.clear()
	button_piles.clear()
	for candidate in _buttons:
		if candidate is Button:
			menu_buttons.append(candidate)
		# end if
	# end for
	queue_redraw()
# end func setup

func _process(delta):
	spawn_accumulator += delta * SPAWN_RATE
	while spawn_accumulator >= 1.0 and _count_ambient_flakes() < AMBIENT_FLAKE_TARGET:
		spawn_accumulator -= 1.0
		_spawn_flake(Vector2(rng.randf_range(0.0, size.x), rng.randf_range(-24.0, 0.0)))
	# end while

	_update_flakes(delta)
	queue_redraw()
# end func _process

func _draw():
	for flake in flakes:
		draw_circle(flake.position, flake.radius, Color(1.0, 1.0, 1.0, flake.alpha))
	# end for
# end func _draw

func _spawn_flake(start_position: Vector2):
	flakes.append({
		"position": start_position,
		"velocity": Vector2(rng.randf_range(-26.0, 26.0), rng.randf_range(42.0, 96.0)),
		"radius": rng.randf_range(1.2, 3.8),
		"alpha": rng.randf_range(0.45, 0.98)
	})
# end func _spawn_flake

func _update_flakes(delta):
	var viewport_size = get_viewport_rect().size
	var alive_flakes = []
	for flake in flakes:
		var previous_position: Vector2 = flake.position
		flake.position += flake.velocity * delta
		flake.velocity.x += sin(flake.position.y * 0.02) * 3.5 * delta

		if _hit_button_top(previous_position, flake):
			continue
		# end if

		if flake.position.y <= viewport_size.y + 20.0 and flake.position.x >= -30.0 and flake.position.x <= viewport_size.x + 30.0:
			alive_flakes.append(flake)
		# end if
	# end for
	flakes = alive_flakes
# end func _update_flakes

func _hit_button_top(previous_position: Vector2, flake: Dictionary) -> bool:
	if menu_buttons.is_empty() or flake.velocity.y <= 0.0:
		return false
	# end if

	var old_center_global = global_position + previous_position
	var new_center_global = global_position + flake.position
	var radius: float = flake.radius

	for button in menu_buttons:
		if not is_instance_valid(button) or not button.is_visible_in_tree():
			continue
		# end if

		var button_rect: Rect2 = button.get_global_rect()
		var local_x = new_center_global.x - button_rect.position.x
		if local_x < 0.0 or local_x >= button_rect.size.x:
			continue
		# end if

		var columns: Dictionary = _get_button_columns(button)
		var x_column := int(clampf(floor(local_x), 0.0, maxf(0.0, button.size.x - 1.0)))
		var stack_height := int(columns.get(x_column, 0))
		var top_y = button_rect.position.y - float(stack_height)
		var old_bottom = old_center_global.y + radius
		var new_bottom = new_center_global.y + radius

		if old_bottom >= top_y or new_bottom < top_y:
			continue
		# end if

		_add_impact_pixels(button, x_column)
		return true
	# end for

	return false
# end func _hit_button_top

func _add_impact_pixels(button: Button, x_column: int):
	var columns: Dictionary = _get_button_columns(button)
	for offset in [-1, 0, 1]:
		var target_x: int = x_column + int(offset)
		if target_x < 0 or target_x >= int(button.size.x):
			continue
		# end if

		var current_height := int(columns.get(target_x, 0))
		columns[target_x] = current_height + 1

		var pixel = ColorRect.new()
		pixel.color = Color(0.95, 0.98, 1.0, 0.95)
		pixel.custom_minimum_size = Vector2.ONE
		pixel.size = Vector2.ONE
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pixel.position = Vector2(float(target_x), -float(current_height))
		button.add_child(pixel)
	# end for
	button_piles[button.get_instance_id()] = columns
# end func _add_impact_pixels

func _get_button_columns(button: Button) -> Dictionary:
	var button_id := button.get_instance_id()
	if not button_piles.has(button_id):
		button_piles[button_id] = {}
	# end if
	return button_piles[button_id]
# end func _get_button_columns

func _count_ambient_flakes() -> int:
	return flakes.size()
# end func _count_ambient_flakes
