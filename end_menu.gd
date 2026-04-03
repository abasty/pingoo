extends CanvasLayer

enum OverlayMode { PAUSE, WIN }

var mode = OverlayMode.PAUSE

func _ready():
	_apply_visual_style()
	_resize_overlay()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
# end func _ready

func show_win():
	mode = OverlayMode.WIN
	var game_state = get_node("/root/GameState")
	$CenterContainer/VBoxContainer/Label.show()
	$CenterContainer/VBoxContainer/Label.text = "Niveau termine !"
	$CenterContainer/VBoxContainer/PrimaryButton.text = "Continuer vers niveau %d" % game_state.current_level
	$CenterContainer/VBoxContainer/SecondaryButton.text = "Abandonner niveau"
	show()
# end func show_win

func show_pause():
	mode = OverlayMode.PAUSE
	$CenterContainer/VBoxContainer/Label.show()
	$CenterContainer/VBoxContainer/Label.text = "Pause"
	$CenterContainer/VBoxContainer/PrimaryButton.text = "Revenir au jeu"
	$CenterContainer/VBoxContainer/SecondaryButton.text = "Abandonner niveau"
	show()
# end func show_pause

func _on_primary_button_pressed():
	if mode == OverlayMode.WIN:
		get_tree().change_scene_to_file("res://test.tscn")
	else:
		hide()
	# end if
# end func _on_primary_button_pressed

func _on_secondary_button_pressed():
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
