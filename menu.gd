extends Control

func _ready():
	_apply_visual_style()
	_update_continue_button_text()
	_update_fullscreen_button_text()
# end func _ready

func _on_continue_pressed():
	var game_state = get_node("/root/GameState")
	if not game_state.has_started_game:
		return
	# end if
	get_tree().change_scene_to_file("res://test.tscn")
# end func _on_continue_pressed

func _on_new_game_pressed():
	var game_state = get_node("/root/GameState")
	game_state.reset_game()
	_update_continue_button_text()
	get_tree().change_scene_to_file("res://test.tscn")
# end func _on_new_game_pressed

func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	# end if
	_update_fullscreen_button_text()
# end func _on_fullscreen_pressed

func _on_quit_pressed():
	get_tree().quit()
# end func _on_quit_pressed

func _update_fullscreen_button_text():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		$CenterContainer/VBoxContainer/FullscreenButton.text = "Quitter le plein ecran"
	else:
		$CenterContainer/VBoxContainer/FullscreenButton.text = "Plein ecran"
	# end if
# end func _update_fullscreen_button_text

func _update_continue_button_text():
	var game_state = get_node("/root/GameState")
	$CenterContainer/VBoxContainer/ContinueButton.disabled = not game_state.has_started_game
	$CenterContainer/VBoxContainer/ContinueButton.text = "Continuer"
# end func _update_continue_button_text

func _apply_visual_style():
	var buttons = [
		$CenterContainer/VBoxContainer/NewGameButton,
		$CenterContainer/VBoxContainer/ContinueButton,
		$CenterContainer/VBoxContainer/FullscreenButton,
		$CenterContainer/VBoxContainer/QuitButton
	]
	var quit_button = $CenterContainer/VBoxContainer/QuitButton

	for button in buttons:
		button.custom_minimum_size = Vector2(300, 44)
		button.add_theme_color_override("font_color", Color(0.02, 0.07, 0.14))
		button.add_theme_color_override("font_hover_color", Color(0.02, 0.07, 0.14))
		button.add_theme_color_override("font_pressed_color", Color(0.02, 0.07, 0.14))

		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.78, 0.92, 1.0)
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_color = Color(0.18, 0.44, 0.62)
		normal.corner_radius_top_left = 6
		normal.corner_radius_top_right = 6
		normal.corner_radius_bottom_right = 6
		normal.corner_radius_bottom_left = 6

		var hover = normal.duplicate()
		hover.bg_color = Color(0.88, 0.97, 1.0)

		var pressed = normal.duplicate()
		pressed.bg_color = Color(0.62, 0.82, 0.95)

		var disabled = normal.duplicate()
		disabled.bg_color = Color(0.62, 0.7, 0.76)
		disabled.border_color = Color(0.31, 0.4, 0.47)

		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("disabled", disabled)
	# end for

	quit_button.add_theme_color_override("font_color", Color(0.4, 0.06, 0.06))
	quit_button.add_theme_color_override("font_hover_color", Color(0.4, 0.06, 0.06))
	quit_button.add_theme_color_override("font_pressed_color", Color(0.4, 0.06, 0.06))

	var quit_normal = StyleBoxFlat.new()
	quit_normal.bg_color = Color(1.0, 0.86, 0.86)
	quit_normal.border_width_left = 2
	quit_normal.border_width_top = 2
	quit_normal.border_width_right = 2
	quit_normal.border_width_bottom = 2
	quit_normal.border_color = Color(0.72, 0.26, 0.26)
	quit_normal.corner_radius_top_left = 6
	quit_normal.corner_radius_top_right = 6
	quit_normal.corner_radius_bottom_right = 6
	quit_normal.corner_radius_bottom_left = 6

	var quit_hover = quit_normal.duplicate()
	quit_hover.bg_color = Color(1.0, 0.93, 0.93)

	var quit_pressed = quit_normal.duplicate()
	quit_pressed.bg_color = Color(0.96, 0.74, 0.74)

	quit_button.add_theme_stylebox_override("normal", quit_normal)
	quit_button.add_theme_stylebox_override("hover", quit_hover)
	quit_button.add_theme_stylebox_override("pressed", quit_pressed)
	quit_button.add_theme_stylebox_override("focus", quit_hover)

	$CenterContainer/VBoxContainer.add_theme_constant_override("separation", 14)
# end func _apply_visual_style
