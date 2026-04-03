extends Control

func _on_play_pressed():
	get_tree().change_scene_to_file("res://test.tscn")
# end func _on_play_pressed

func _on_quit_pressed():
	get_tree().quit()
# end func _on_quit_pressed
