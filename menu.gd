extends Control

func _ready():
	_update_fullscreen_button_text()
# end func _ready

func _on_play_pressed():
	get_tree().change_scene_to_file("res://test.tscn")
# end func _on_play_pressed

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
		$VBoxContainer/FullscreenButton.text = "Quitter le plein ecran"
	else:
		$VBoxContainer/FullscreenButton.text = "Plein ecran"
	# end if
# end func _update_fullscreen_button_text
