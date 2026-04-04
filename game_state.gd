extends Node

var current_level: int = 1
var current_score: int = 0
var current_level_score: int = 0
var has_started_game: bool = false
var player_name: String = "Player"

func reset_game():
	current_level = 1
	current_score = 0
	current_level_score = 0
	has_started_game = false
# end func reset_game

func next_level():
	current_level += 1
# end func next_level

func start_level():
	current_level_score = 0
	has_started_game = true
# end func start_level

func add_score(score: int):
	current_score += score
	current_level_score += score
# end func add_score

func abandon_level():
	current_score -= current_level_score
	if current_score < 0:
		current_score = 0
	# end if
	current_level_score = 0
# end func abandon_level
