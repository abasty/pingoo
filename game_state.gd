extends Node

var current_level: int = 1
var current_score: int = 0
var has_started_game: bool = false

func reset_game():
	current_level = 1
	current_score = 0
	has_started_game = true
# end func reset_game

func next_level():
	current_level += 1
# end func next_level
