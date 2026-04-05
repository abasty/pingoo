extends CanvasLayer

signal level_resumed

enum OverlayMode { PAUSE, WIN, FAIL, GAME_OVER }
enum FailureType { TIMEOUT, MONSTER_COLLISION }

var mode = OverlayMode.PAUSE
var current_failure_type: FailureType = FailureType.TIMEOUT

func _ready():
	_apply_visual_style()
	_resize_overlay()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
# end func _ready

func show_win():
	mode = OverlayMode.WIN
	var game_state = get_node("/root/GameState")
	var label = get_node_or_null("CenterContainer/VBoxContainer/Label") as Label
	var primary_button = get_node_or_null("CenterContainer/VBoxContainer/PrimaryButton") as Button
	var secondary_button = get_node_or_null("CenterContainer/VBoxContainer/SecondaryButton") as Button
	if label != null:
		label.show()
		label.text = "Niveau terminé !"
	# end if
	if primary_button != null:
		primary_button.text = "Continuer vers niveau %d" % game_state.current_level
	# end if
	if secondary_button != null:
		secondary_button.text = "Abandonner niveau"
	# end if
	show()
# end func show_win

func show_pause():
	mode = OverlayMode.PAUSE
	var label = get_node_or_null("CenterContainer/VBoxContainer/Label") as Label
	var primary_button = get_node_or_null("CenterContainer/VBoxContainer/PrimaryButton") as Button
	var secondary_button = get_node_or_null("CenterContainer/VBoxContainer/SecondaryButton") as Button
	if label != null:
		label.show()
		label.text = "Pause"
	# end if
	if primary_button != null:
		primary_button.text = "Revenir au jeu"
	# end if
	if secondary_button != null:
		secondary_button.show()
		secondary_button.text = "Abandonner niveau"
	# end if
	show()
# end func show_pause

func show_fail(lives_left: int, failure_type: FailureType = FailureType.TIMEOUT):
	current_failure_type = failure_type
	mode = OverlayMode.FAIL
	var label = get_node_or_null("CenterContainer/VBoxContainer/Label") as Label
	var primary_button = get_node_or_null("CenterContainer/VBoxContainer/PrimaryButton") as Button
	var secondary_button = get_node_or_null("CenterContainer/VBoxContainer/SecondaryButton") as Button
	if label != null:
		label.show()
		if failure_type == FailureType.MONSTER_COLLISION:
			label.text = "Monstre!\nVies restantes: %d" % lives_left
		else:
			label.text = "Temps ecoule !\nVies restantes: %d" % lives_left
		# end if
	# end if
	if primary_button != null:
		if failure_type == FailureType.MONSTER_COLLISION:
			primary_button.text = "Continuer"
		else:
			primary_button.text = "Reessayer le niveau"
		# end if
	# end if
	if secondary_button != null:
		secondary_button.show()
		secondary_button.text = "Abandonner niveau"
	# end if
	show()
# end func show_fail

func show_game_over():
	mode = OverlayMode.GAME_OVER
	var label = get_node_or_null("CenterContainer/VBoxContainer/Label") as Label
	var primary_button = get_node_or_null("CenterContainer/VBoxContainer/PrimaryButton") as Button
	var secondary_button = get_node_or_null("CenterContainer/VBoxContainer/SecondaryButton") as Button
	if label != null:
		label.show()
		label.text = "Plus de vies.\nPartie terminee."
	# end if
	if primary_button != null:
		primary_button.text = "Retour au menu"
	# end if
	if secondary_button != null:
		secondary_button.hide()
	# end if
	show()
# end func show_game_over

func _on_primary_button_pressed():
	if mode == OverlayMode.WIN:
		get_tree().change_scene_to_file("res://test.tscn")
	elif mode == OverlayMode.FAIL:
		if current_failure_type == FailureType.TIMEOUT:
			# Timeout: restart the level
			get_tree().change_scene_to_file("res://test.tscn")
		else:
			# Monster collision: resume from current state
			_resume_level()
		# end if
	elif mode == OverlayMode.GAME_OVER:
		var game_state = get_node("/root/GameState")
		game_state.reset_game()
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		hide()
	# end if
# end func _on_primary_button_pressed

func _resume_level() -> void:
	"""Resume level gameplay without restarting or resetting the board."""
	var game_state = get_node("/root/GameState")
	game_state.is_level_running = true
	# Monster was already removed during collision detection
	# Board state is preserved; just unpause
	mode = OverlayMode.PAUSE
	hide()
	level_resumed.emit()
# end func _resume_level

func _on_secondary_button_pressed():
	var game_state = get_node("/root/GameState")
	var hall_of_fame = get_node("/root/HallOfFame")
	hall_of_fame.update_level_highscore(game_state.current_level, game_state.current_level_score)

	if mode == OverlayMode.PAUSE:
		game_state.abandon_level()
	# end if
	if mode == OverlayMode.GAME_OVER:
		return
	# end if
	get_tree().change_scene_to_file("res://menu.tscn")
# end func _on_secondary_button_pressed

func _on_viewport_size_changed():
	_resize_overlay()
# end func _on_viewport_size_changed

func _resize_overlay():
	var viewport_size = get_viewport().get_visible_rect().size
	$Background.offset_right = viewport_size.x
	$Background.offset_bottom = viewport_size.y
	$CenterContainer.offset_right = viewport_size.x
	$CenterContainer.offset_bottom = viewport_size.y
# end func _resize_overlay

func _apply_visual_style():
	var label = $CenterContainer/VBoxContainer/Label
	var primary = $CenterContainer/VBoxContainer/PrimaryButton
	var secondary = $CenterContainer/VBoxContainer/SecondaryButton

	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1.0, 0.95, 0.78)

	primary.custom_minimum_size = Vector2(320, 46)
	primary.add_theme_color_override("font_color", Color(0.02, 0.07, 0.14))
	primary.add_theme_color_override("font_hover_color", Color(0.02, 0.07, 0.14))
	primary.add_theme_color_override("font_pressed_color", Color(0.02, 0.07, 0.14))

	var primary_normal = StyleBoxFlat.new()
	primary_normal.bg_color = Color(0.78, 0.92, 1.0)
	primary_normal.border_width_left = 2
	primary_normal.border_width_top = 2
	primary_normal.border_width_right = 2
	primary_normal.border_width_bottom = 2
	primary_normal.border_color = Color(0.18, 0.44, 0.62)
	primary_normal.corner_radius_top_left = 6
	primary_normal.corner_radius_top_right = 6
	primary_normal.corner_radius_bottom_right = 6
	primary_normal.corner_radius_bottom_left = 6

	var primary_hover = primary_normal.duplicate()
	primary_hover.bg_color = Color(0.88, 0.97, 1.0)

	var primary_pressed = primary_normal.duplicate()
	primary_pressed.bg_color = Color(0.62, 0.82, 0.95)

	primary.add_theme_stylebox_override("normal", primary_normal)
	primary.add_theme_stylebox_override("hover", primary_hover)
	primary.add_theme_stylebox_override("pressed", primary_pressed)
	primary.add_theme_stylebox_override("focus", primary_hover)

	secondary.custom_minimum_size = Vector2(320, 42)
	secondary.add_theme_color_override("font_color", Color(0.4, 0.06, 0.06))
	secondary.add_theme_color_override("font_hover_color", Color(0.4, 0.06, 0.06))
	secondary.add_theme_color_override("font_pressed_color", Color(0.4, 0.06, 0.06))

	var secondary_normal = StyleBoxFlat.new()
	secondary_normal.bg_color = Color(1.0, 0.86, 0.86)
	secondary_normal.border_width_left = 2
	secondary_normal.border_width_top = 2
	secondary_normal.border_width_right = 2
	secondary_normal.border_width_bottom = 2
	secondary_normal.border_color = Color(0.72, 0.26, 0.26)
	secondary_normal.corner_radius_top_left = 6
	secondary_normal.corner_radius_top_right = 6
	secondary_normal.corner_radius_bottom_right = 6
	secondary_normal.corner_radius_bottom_left = 6

	var secondary_hover = secondary_normal.duplicate()
	secondary_hover.bg_color = Color(1.0, 0.93, 0.93)

	var secondary_pressed = secondary_normal.duplicate()
	secondary_pressed.bg_color = Color(0.96, 0.74, 0.74)

	secondary.add_theme_stylebox_override("normal", secondary_normal)
	secondary.add_theme_stylebox_override("hover", secondary_hover)
	secondary.add_theme_stylebox_override("pressed", secondary_pressed)
	secondary.add_theme_stylebox_override("focus", secondary_hover)

	$CenterContainer/VBoxContainer.add_theme_constant_override("separation", 14)
# end func _apply_visual_style
