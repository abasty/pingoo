extends Node

const INITIAL_LIVES: int = 3
const LEVEL_TIME_SECONDS: float = 60.0

var current_level: int = 1
var current_score: int = 0
var current_level_score: int = 0
var has_started_game: bool = false
var player_name: String = "Player"
var lives: int = INITIAL_LIVES
var level_time_left: float = LEVEL_TIME_SECONDS

func reset_game():
	current_level = 1
	current_score = 0
	current_level_score = 0
	has_started_game = false
	lives = INITIAL_LIVES
	level_time_left = LEVEL_TIME_SECONDS
# end func reset_game

func next_level():
	current_level += 1
# end func next_level

func start_level():
	current_level_score = 0
	level_time_left = LEVEL_TIME_SECONDS
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

func lose_life():
	lives -= 1
	if lives < 0:
		lives = 0
	# end if
# end func lose_life

func is_game_over() -> bool:
	return lives <= 0
# end func is_game_over
