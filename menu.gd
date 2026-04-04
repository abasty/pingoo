extends Control

func _ready():
	_apply_visual_style()
	_update_continue_section()
	_update_fullscreen_button_text()
	var pseudo_line_edit = get_node_or_null("PseudoDialog/PseudoLineEdit") as LineEdit
	if pseudo_line_edit != null and not pseudo_line_edit.text_submitted.is_connected(_on_pseudo_line_edit_text_submitted):
		pseudo_line_edit.text_submitted.connect(_on_pseudo_line_edit_text_submitted)
	# end if
	$IntroSnow.setup([
		$CenterContainer/VBoxContainer/NewGameButton,
		$CenterContainer/VBoxContainer/ContinueButton,
		$CenterContainer/VBoxContainer/FullscreenButton,
		$CenterContainer/VBoxContainer/HallOfFameButton,
		$CenterContainer/VBoxContainer/QuitButton
	])
# end func _ready

func _on_continue_pressed():
	var game_state = get_node("/root/GameState")
	if not game_state.has_started_game:
		return
	# end if
	get_tree().change_scene_to_file("res://test.tscn")
# end func _on_continue_pressed

func _on_new_game_pressed():
	var pseudo_line_edit = get_node_or_null("PseudoDialog/PseudoLineEdit") as LineEdit
	if pseudo_line_edit != null:
		pseudo_line_edit.text = ""
	# end if
	$PseudoDialog.popup_centered(Vector2(340, 130))
	if pseudo_line_edit != null:
		pseudo_line_edit.grab_focus()
	# end if
# end func _on_new_game_pressed

func _on_pseudo_dialog_confirmed():
	var game_state = get_node("/root/GameState")
	var player_name = ""
	var pseudo_line_edit = get_node_or_null("PseudoDialog/PseudoLineEdit") as LineEdit
	if pseudo_line_edit != null:
		player_name = pseudo_line_edit.text.strip_edges()
	# end if
	if player_name.is_empty():
		player_name = "Player"
	# end if
	game_state.reset_game()
	game_state.player_name = player_name
	_update_continue_section()
	get_tree().change_scene_to_file("res://test.tscn")
# end func _on_pseudo_dialog_confirmed

func _on_pseudo_line_edit_text_submitted(_new_text: String):
	if not $PseudoDialog.visible:
		return
	# end if
	_on_pseudo_dialog_confirmed()
	$PseudoDialog.hide()
# end func _on_pseudo_line_edit_text_submitted

func _on_hall_of_fame_button_pressed():
	get_tree().change_scene_to_file("res://hall_of_fame_screen.tscn")
# end func _on_hall_of_fame_button_pressed

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
	var fullscreen_button = get_node_or_null("CenterContainer/VBoxContainer/FullscreenButton") as Button
	if fullscreen_button == null:
		return
	# end if

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_button.text = "Quitter le plein ecran"
	else:
		fullscreen_button.text = "Plein ecran"
	# end if
# end func _update_fullscreen_button_text

func _update_continue_section():
	var game_state = get_node("/root/GameState")
	var can_continue = game_state.has_started_game
	var continue_button = get_node_or_null("CenterContainer/VBoxContainer/ContinueButton") as Button
	var continue_info_label = get_node_or_null("CenterContainer/VBoxContainer/ContinueInfoLabel") as Label
	if continue_button != null:
		continue_button.disabled = not can_continue
		continue_button.text = "Continuer"
	# end if
	if continue_info_label != null:
		continue_info_label.visible = can_continue
	# end if
	if can_continue:
		if continue_info_label != null:
			var player_name = game_state.player_name.strip_edges()
			if player_name.is_empty():
				player_name = "Player"
			# end if
			continue_info_label.text = "Pseudo: %s\nNiveau courant: %d\nScore: %d" % [player_name, game_state.current_level, game_state.current_score]
		# end if
	# end if
# end func _update_continue_section

func _apply_visual_style():
	var buttons = [
		$CenterContainer/VBoxContainer/NewGameButton,
		$CenterContainer/VBoxContainer/ContinueButton,
		$CenterContainer/VBoxContainer/FullscreenButton,
		$CenterContainer/VBoxContainer/HallOfFameButton,
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

	$CenterContainer/VBoxContainer/ContinueInfoLabel.add_theme_font_size_override("font_size", 18)
	$CenterContainer/VBoxContainer/ContinueInfoLabel.modulate = Color(0.9, 0.94, 1.0)

	$CenterContainer/VBoxContainer.add_theme_constant_override("separation", 14)
# end func _apply_visual_style
