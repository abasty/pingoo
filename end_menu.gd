extends CanvasLayer

func show_win():
	$CenterContainer/VBoxContainer/Label.show()
	show()
# end func show_win

func show_pause():
	$CenterContainer/VBoxContainer/Label.hide()
	show()
# end func show_pause

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")
# end func _on_menu_button_pressed
