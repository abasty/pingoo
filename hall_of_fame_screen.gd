extends Control

const COL_RANK_WIDTH = 60
const COL_NAME_WIDTH = 240
const COL_SCORE_WIDTH = 140
const COL_LEVEL_WIDTH = 90

func _ready():
	var clear_button = get_node_or_null("CenterContainer/Card/MarginContainer/VBoxContainer/ClearButton") as Button
	if clear_button != null:
		clear_button.visible = OS.is_debug_build()
	# end if
	_refresh_scores()
	_apply_style()
# end func _ready

func _refresh_scores():
	var hall_of_fame = get_node("/root/HallOfFame")
	var scores = hall_of_fame.get_top_scores()
	var rows = $CenterContainer/Card/MarginContainer/VBoxContainer/Rows as VBoxContainer

	for child in rows.get_children():
		child.queue_free()
	# end for

	rows.add_child(_build_table_header())

	if scores.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Aucun score pour le moment"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(0, 42)
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows.add_child(empty_label)
		return
	# end if

	for i in range(scores.size()):
		var entry: Dictionary = scores[i]
		rows.add_child(_build_score_row(i + 1, str(entry.get("name", "Player")), int(entry.get("score", 0)), int(entry.get("level", 1)), i))
	# end for
# end func _refresh_scores

func _build_table_header() -> Control:
	var header = PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.custom_minimum_size = Vector2(0, 34)

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.12, 0.23, 0.37, 0.95)
	header_style.corner_radius_top_left = 5
	header_style.corner_radius_top_right = 5
	header_style.corner_radius_bottom_left = 5
	header_style.corner_radius_bottom_right = 5
	header.add_theme_stylebox_override("panel", header_style)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 10)
	header.add_child(hbox)

	hbox.add_child(_build_column_label("Rang", COL_RANK_WIDTH, HORIZONTAL_ALIGNMENT_LEFT, true))
	hbox.add_child(_build_column_label("Pseudo", COL_NAME_WIDTH, HORIZONTAL_ALIGNMENT_LEFT, true))
	hbox.add_child(_build_column_label("Score", COL_SCORE_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, true))
	hbox.add_child(_build_column_label("Niveau", COL_LEVEL_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, true))

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	return header
# end func _build_table_header

func _build_score_row(rank: int, player_name: String, score: int, level: int, index: int) -> Control:
	var row_panel = PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size = Vector2(0, 36)

	var row_style = StyleBoxFlat.new()
	row_style.bg_color = _get_row_background_color(index)
	row_style.border_width_bottom = 1
	row_style.border_color = _get_row_border_color(index)
	row_style.corner_radius_top_left = 3
	row_style.corner_radius_top_right = 3
	row_style.corner_radius_bottom_left = 3
	row_style.corner_radius_bottom_right = 3
	row_panel.add_theme_stylebox_override("panel", row_style)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 10)
	row_panel.add_child(hbox)

	var rank_label = _build_column_label("#%d" % rank, COL_RANK_WIDTH, HORIZONTAL_ALIGNMENT_LEFT, false)
	var name_label = _build_column_label(player_name, COL_NAME_WIDTH, HORIZONTAL_ALIGNMENT_LEFT, false)
	var score_label = _build_column_label("%d" % score, COL_SCORE_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, false)
	var level_label = _build_column_label("%d" % level, COL_LEVEL_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, false)

	var rank_color = _get_rank_text_color(index)
	rank_label.modulate = rank_color
	if index <= 2:
		name_label.modulate = Color(0.97, 0.98, 1.0)
		score_label.modulate = Color(0.97, 0.98, 1.0)
		level_label.modulate = Color(0.97, 0.98, 1.0)
	# end if

	hbox.add_child(rank_label)
	hbox.add_child(name_label)
	hbox.add_child(score_label)
	hbox.add_child(level_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	return row_panel
# end func _build_score_row

func _get_row_background_color(index: int) -> Color:
	if index == 0:
		return Color(0.42, 0.34, 0.14, 0.42)
	# end if
	if index == 1:
		return Color(0.34, 0.38, 0.42, 0.4)
	# end if
	if index == 2:
		return Color(0.39, 0.28, 0.22, 0.38)
	# end if
	return Color(0.2, 0.3, 0.42, 0.4) if index % 2 == 0 else Color(0.16, 0.25, 0.36, 0.3)
# end func _get_row_background_color

func _get_row_border_color(index: int) -> Color:
	if index <= 2:
		return Color(0.96, 0.86, 0.56, 0.45)
	# end if
	return Color(0.46, 0.68, 0.85, 0.25)
# end func _get_row_border_color

func _get_rank_text_color(index: int) -> Color:
	if index == 0:
		return Color(1.0, 0.88, 0.38)
	# end if
	if index == 1:
		return Color(0.84, 0.89, 0.96)
	# end if
	if index == 2:
		return Color(0.9, 0.67, 0.5)
	# end if
	return Color(0.89, 0.95, 1.0)
# end func _get_rank_text_color

func _build_column_label(text_value: String, width: int, alignment: HorizontalAlignment, is_header: bool) -> Label:
	var label = Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.custom_minimum_size = Vector2(width, 0)
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
		label.modulate = Color(0.91, 0.97, 1.0)
	else:
		label.add_theme_font_size_override("font_size", 15)
		label.modulate = Color(0.89, 0.95, 1.0)
	# end if
	return label
# end func _build_column_label

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")
# end func _on_back_button_pressed

func _on_clear_button_pressed():
	if not OS.is_debug_build():
		return
	# end if
	var hall_of_fame = get_node("/root/HallOfFame")
	hall_of_fame.clear_all_scores()
	_refresh_scores()
# end func _on_clear_button_pressed

func _apply_style():
	$TopBar/Title.add_theme_font_size_override("font_size", 24)
	$CenterContainer/Card/MarginContainer/VBoxContainer/Rows.add_theme_constant_override("separation", 8)
	$CenterContainer/Card/MarginContainer/VBoxContainer/BackButton.custom_minimum_size = Vector2(260, 44)
	var clear_button = get_node_or_null("CenterContainer/Card/MarginContainer/VBoxContainer/ClearButton") as Button
	if clear_button != null:
		clear_button.custom_minimum_size = Vector2(260, 40)
	# end if
# end func _apply_style

func _input(event):
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	# end if

	if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		var viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		# end if
		_on_back_button_pressed()
	# end if
# end func _input
